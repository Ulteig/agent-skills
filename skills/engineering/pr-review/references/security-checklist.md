# Security Checklist for PR Reviews

## Input and Injection
- SQL/NoSQL/command injection from string interpolation
- Path traversal (`../`) in file operations
- Unsafe deserialization of untrusted input
- Regex patterns vulnerable to ReDoS

## Web and API Security
- XSS via unescaped rendering or unsafe HTML insertion
- CSRF gaps for state-changing operations
- Missing authentication or weak auth checks
- Missing authorization/tenant ownership checks (IDOR)

## Secrets and Sensitive Data
- API keys/tokens/passwords committed in code/config
- Sensitive data logged in plaintext
- Overexposed error details to clients

## Data Integrity and Concurrency
- Race conditions (check-then-act / TOCTOU)
- Missing transactions for multi-step writes
- Lost updates from concurrent edits
- Missing idempotency for retryable operations

## Dependency and Platform Risk
- Outdated/vulnerable dependencies
- Insecure defaults (permissive CORS, weak crypto)
- Missing timeouts/retries/rate limits on outbound calls

## Reporting
For each security issue include:
1. Exploit path
2. Likely impact
3. Concrete fix recommendation
