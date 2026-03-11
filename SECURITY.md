# Security Policy

## Supported Versions

| Version | Status | Support Until |
|---------|--------|----------------|
| 0.1.x   | Stable | Jan 2027       |
| 0.0.x   | Legacy | Ended          |

## Reporting Vulnerabilities

**Please DO NOT open a public issue** for security vulnerabilities.

Instead, email: luca.gualandi@example.com with:
- Type of vulnerability
- Location (file, package)
- Severity assessment
- Proof of concept (if applicable)
- Suggested fix (if applicable)

We will:
1. Acknowledge receipt within 48 hours
2. Investigate and validate
3. Develop fix
4. Prepare security release
5. Notify you before publication
6. Credit you (if desired) in release notes

## Security Best Practices

When using `singleton_manager`:

1. **Scope Isolation**
   - Use scopes for request/session lifecycle
   - Call `scope.clear()` when done
   - Never share scopes between isolated contexts

2. **Sensitive Data**
   - Avoid storing credentials in singletons
   - Use secure storage for secrets
   - Clear singletons containing sensitive data

3. **Dependency Injection**
   - Validate dependencies before singleton creation
   - Use factories for runtime verification
   - Implement access controls if needed

## Dependencies

- **Zero production dependencies**
- **Dev dependencies**: test, lints (both maintained by Dart team)

Updates checked monthly via `dart pub outdated`

## Compliance

This package adheres to:
- [Dart Package Guidelines](https://dart.dev/tools/pub/package-layout)
- [Dart Code of Conduct](https://dart.dev/community/code-of-conduct)

## Security Disclosure Timeline

- **Day 0**: Vulnerability reported
- **Day 1-2**: Acknowledgment and investigation
- **Day 3-7**: Fix development and testing
- **Day 8**: Security release published
- **Day 9**: Public disclosure (coordinated)

## Changelog Security

All security fixes are marked in CHANGELOG.md:

```markdown
### Security
- Fixed potential issue with singleton access from multiple threads
```
