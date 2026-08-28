#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# NOTE: This is a dev-only script, intended for use by maintainers of this repo.
# It is not a supported installer. Modifications to it, or requests for
# modifications, will not be approved.
#
# Links all skills in the repository into the local skill directories used by
# each agent harness:
#   - ~/.claude/skills  - Claude Code
#   - ~/.agents/skills  - Codex and other Agent Skills-compatible harnesses
# Each entry is a junction into this repo, so a `git pull` is all that's needed
# to keep installed skills up to date. Pass -WhatIf to preflight and preview
# changes without applying them.

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'scripts/link-skills.ps1 can only run on Windows.'
}

function Get-NormalizedPath {
    param([Parameter(Mandatory = $true)][string] $Path)

    $fullPath = [IO.Path]::GetFullPath($Path)
    $root = [IO.Path]::GetPathRoot($fullPath)

    while ($fullPath.Length -gt $root.Length -and
        ($fullPath.EndsWith([IO.Path]::DirectorySeparatorChar) -or
            $fullPath.EndsWith([IO.Path]::AltDirectorySeparatorChar))) {
        $fullPath = $fullPath.Substring(0, $fullPath.Length - 1)
    }

    return $fullPath
}

function Test-PathWithin {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $Root
    )

    $normalizedPath = Get-NormalizedPath $Path
    $normalizedRoot = Get-NormalizedPath $Root

    if ($normalizedPath.Equals($normalizedRoot, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    $rootPrefix = $normalizedRoot + [IO.Path]::DirectorySeparatorChar
    return $normalizedPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
}

function Get-PathItem {
    param([Parameter(Mandatory = $true)][string] $Path)

    try {
        return Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    }
    catch [Management.Automation.ItemNotFoundException] {
        return $null
    }
}

function Test-ReparsePoint {
    param([Parameter(Mandatory = $true)] $Item)

    return [bool]($Item.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

function Test-SkillLink {
    param([Parameter(Mandatory = $true)] $Item)

    if (-not (Test-ReparsePoint $Item)) {
        return $false
    }

    $linkTypeProperty = $Item.PSObject.Properties['LinkType']
    if ($null -eq $linkTypeProperty) {
        return $false
    }

    return $linkTypeProperty.Value -in @('Junction', 'SymbolicLink')
}

function Get-ImmediateLinkTarget {
    param([Parameter(Mandatory = $true)] $Item)

    $targetProperty = $Item.PSObject.Properties['Target']
    if ($null -eq $targetProperty -or $null -eq $targetProperty.Value) {
        throw "Cannot determine the target of link '$($Item.FullName)'."
    }

    $target = @($targetProperty.Value)[0]
    if ([string]::IsNullOrWhiteSpace([string] $target)) {
        throw "Cannot determine the target of link '$($Item.FullName)'."
    }

    if (-not [IO.Path]::IsPathRooted($target)) {
        $target = Join-Path $Item.Parent.FullName $target
    }

    return Get-NormalizedPath $target
}

function Resolve-LinkTarget {
    param([Parameter(Mandatory = $true)] $Item)

    $visited = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $currentItem = $Item

    while ($true) {
        $target = Get-ImmediateLinkTarget $currentItem
        if (-not $visited.Add($target)) {
            throw "Link cycle detected while resolving '$($Item.FullName)'."
        }

        $targetItem = Get-PathItem $target
        if ($null -eq $targetItem -or -not (Test-SkillLink $targetItem)) {
            return $target
        }

        $currentItem = $targetItem
    }
}

function Remove-SkillLink {
    param([Parameter(Mandatory = $true)] $Item)

    if (-not (Test-SkillLink $Item)) {
        throw "Refusing to remove non-link path '$($Item.FullName)'."
    }

    if ($Item.PSIsContainer) {
        [IO.Directory]::Delete($Item.FullName)
    }
    else {
        [IO.File]::Delete($Item.FullName)
    }
}

$repo = Get-NormalizedPath (Join-Path $PSScriptRoot '..')
$skillsRoot = Join-Path $repo 'skills'
$destinations = @(
    (Join-Path $HOME '.claude\skills'),
    (Join-Path $HOME '.agents\skills')
)

$skills = @(
    Get-ChildItem -LiteralPath $skillsRoot -Filter 'SKILL.md' -File -Recurse -Force |
        Where-Object {
            $relativePath = $_.FullName.Substring($skillsRoot.Length)
            $segments = $relativePath.Split(
                [char[]] @([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar),
                [StringSplitOptions]::RemoveEmptyEntries
            )

            $segments -notcontains 'node_modules' -and $segments -notcontains 'deprecated'
        } |
        ForEach-Object {
            [pscustomobject] @{
                Name = $_.Directory.Name
                Source = Get-NormalizedPath $_.Directory.FullName
            }
        } |
        Sort-Object Name, Source
)

$preflightErrors = New-Object 'Collections.Generic.List[string]'
$duplicateNames = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)

foreach ($group in @($skills | Group-Object Name)) {
    if ($group.Count -le 1) {
        continue
    }

    [void] $duplicateNames.Add($group.Name)
    $sources = @($group.Group | ForEach-Object Source)
    $preflightErrors.Add(
        "Duplicate skill name '$($group.Name)': $($sources -join ', ')"
    )
}

$uniqueSkills = @($skills | Where-Object { -not $duplicateNames.Contains($_.Name) })
$plans = New-Object 'Collections.Generic.List[object]'

foreach ($destination in $destinations) {
    $destinationItem = Get-PathItem $destination
    $destinationIsValid = $true

    if ($null -eq $destinationItem) {
        $plans.Add([pscustomobject] @{
                Kind = 'CreateDestination'
                Path = $destination
                Source = $null
                Name = $null
            })
    }
    elseif (-not $destinationItem.PSIsContainer) {
        $preflightErrors.Add("Destination '$destination' is not a directory.")
        $destinationIsValid = $false
    }
    elseif (Test-ReparsePoint $destinationItem) {
        try {
            $resolvedDestination = Resolve-LinkTarget $destinationItem
            if (Test-PathWithin -Path $resolvedDestination -Root $repo) {
                $preflightErrors.Add(
                    "Destination '$destination' is a link into this repo ($resolvedDestination)."
                )
                $destinationIsValid = $false
            }
        }
        catch {
            $preflightErrors.Add($_.Exception.Message)
            $destinationIsValid = $false
        }
    }

    if (-not $destinationIsValid) {
        continue
    }

    foreach ($skill in $uniqueSkills) {
        $target = Join-Path $destination $skill.Name
        $targetItem = Get-PathItem $target

        if ($null -eq $targetItem) {
            $plans.Add([pscustomobject] @{
                    Kind = 'CreateLink'
                    Path = $target
                    Source = $skill.Source
                    Name = $skill.Name
                })
            continue
        }

        if (-not (Test-SkillLink $targetItem)) {
            $preflightErrors.Add(
                "Skill '$($skill.Name)' collides with existing non-link path '$target'."
            )
            continue
        }

        try {
            $resolvedTarget = Resolve-LinkTarget $targetItem
            if ($resolvedTarget.Equals($skill.Source, [StringComparison]::OrdinalIgnoreCase)) {
                $plans.Add([pscustomobject] @{
                        Kind = 'KeepLink'
                        Path = $target
                        Source = $skill.Source
                        Name = $skill.Name
                    })
            }
            else {
                $plans.Add([pscustomobject] @{
                        Kind = 'ReplaceLink'
                        Path = $target
                        Source = $skill.Source
                        Name = $skill.Name
                    })
            }
        }
        catch {
            $preflightErrors.Add($_.Exception.Message)
        }
    }
}

if ($preflightErrors.Count -gt 0) {
    foreach ($message in $preflightErrors) {
        [Console]::Error.WriteLine("error: $message")
    }
    [Console]::Error.WriteLine('Preflight failed; no changes were made.')
    exit 1
}

try {
    foreach ($plan in $plans) {
        switch ($plan.Kind) {
            'CreateDestination' {
                if ($PSCmdlet.ShouldProcess($plan.Path, 'Create destination directory')) {
                    [void] (New-Item -ItemType Directory -Path $plan.Path -Force)
                }
            }
            'KeepLink' {
                Write-Output "already linked $($plan.Name) -> $($plan.Source)"
            }
            'CreateLink' {
                if ($PSCmdlet.ShouldProcess($plan.Path, "Create junction to '$($plan.Source)'")) {
                    [void] (New-Item -ItemType Junction -Path $plan.Path -Target $plan.Source)
                    Write-Output "linked $($plan.Name) -> $($plan.Source)"
                }
            }
            'ReplaceLink' {
                if ($PSCmdlet.ShouldProcess($plan.Path, "Replace skill link with junction to '$($plan.Source)'")) {
                    $existingItem = Get-PathItem $plan.Path
                    Remove-SkillLink $existingItem
                    [void] (New-Item -ItemType Junction -Path $plan.Path -Target $plan.Source)
                    Write-Output "linked $($plan.Name) -> $($plan.Source)"
                }
            }
        }
    }
}
catch {
    [Console]::Error.WriteLine("error: $($_.Exception.Message)")
    [Console]::Error.WriteLine('Apply failed; changes made earlier in this run may remain.')
    exit 1
}
