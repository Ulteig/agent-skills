# Security Checklist for PR Reviews

## Input and Injection
- Flag: SQL/NoSQL/command injection from string interpolation
- Flag: Path traversal (`../`) in file operations
- Flag: Unsafe deserialization of untrusted input
- Flag: Regex patterns vulnerable to ReDoS

## Web and API Security
- Flag: XSS via unescaped rendering or unsafe HTML insertion
- Flag: CSRF gaps for state-changing operations
- Flag: Missing authentication or weak auth checks
- Flag: Missing authorization/tenant ownership checks (IDOR)
- Flag: Authorization removed or not carried over when a controller or endpoint is added, moved, or rewritten (`[Authorize]`, base-class auth)
- Flag: Auth tokens not passed on calls to a secured API
- Flag: `dangerouslySetInnerHTML` or raw HTML built from data

## Secrets and Sensitive Data
- Flag: API keys/tokens/passwords committed in code/config
- Flag: Sensitive data logged in plaintext
- Flag: A new key or credential with a wider scope than needed (ask what it can reach)
- Flag: Config defaults that point at prod, or hard-coded hosts and environments
- Flag: Overexposed error details to clients

## Data Integrity and Concurrency
- Flag: Race conditions (check-then-act / TOCTOU)
- Flag: Missing transactions for multi-step writes
- Flag: Lost updates from concurrent edits
- Flag: Missing idempotency for retryable operations

## Dependency and Platform Risk
- Flag: Outdated/vulnerable dependencies
- Flag: Insecure defaults (permissive CORS, weak crypto)
- Flag: Missing timeouts/retries/rate limits on outbound calls

## Reporting
For each security issue include:
1. Exploit path
2. Likely impact
3. Concrete fix recommendation
