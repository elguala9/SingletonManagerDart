# Contributing to Singleton Manager

Thank you for your interest in contributing! We welcome contributions.

## Before You Start

- Check [GitHub Issues](https://github.com/elguala9/SingletonManagerDart/issues)
  for similar reports or discussions
- For large changes, open an issue first to discuss approach

## Development Workflow

### 1. Setup

```bash
git clone https://github.com/elguala9/SingletonManagerDart.git
cd SingletonManagerDart
dart pub global activate melos
melos bootstrap
```

### 2. Create Branch

```bash
# Branch from develop for features
git checkout -b feature/my-feature develop

# Branch from main for hotfixes
git checkout -b hotfix/my-fix main
```

### 3. Make Changes

- Write clear, focused code
- Add/update tests for changes
- Update documentation
- Follow code style

### 4. Validation

```bash
# Code quality checks
melos run analyze

# Format code
melos run format

# Run all tests
melos run test

# Full CI pipeline
melos run ci
```

### 5. Commit & Push

```bash
git add .
git commit -m "feat: description of changes"
git push origin feature/my-feature
```

### 6. Create Pull Request

- Clear title and description
- Reference related issues (#123)
- Ensure CI passes
- Request review from maintainers

## Code Standards

### Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `dart format` (enforced by CI)
- Run `dart analyze` (strict mode)

### Testing
- All public APIs must have tests
- Aim for >90% code coverage
- Use descriptive test names
- Test both success and error cases

### Documentation
- Document all public APIs with dartdoc comments
- Include usage examples in comments
- Keep README.md updated
- Add architectural decisions to doc/

### Commit Messages
```
type(scope): subject

body

footer
```

**Types**: feat, fix, docs, style, refactor, perf, test, chore
**Example**:
```
feat(manager): add scope isolation for singletons

Implements SingletonScope class to manage scoped instances.
Allows creating isolated singleton contexts for request-level
or component-level lifecycle management.

Fixes #42
```

## Testing

### Test Organization
```
test/
├── unit/              # Isolated unit tests
├── functional/        # Feature-level tests
└── integration/       # End-to-end tests
```

### Running Tests
```bash
melos run test:unit        # Unit only
melos run test:functional  # Functional only
melos run test:coverage    # With coverage
```

## Documentation

- Update `CHANGELOG.md` when making changes (under "Unreleased" section)
- Update `packages/singleton_manager/README.md` for user-facing changes
- Add architectural docs to `packages/singleton_manager/doc/`

## Questions?

- Open a GitHub Discussion
- Check existing issues
- Ask in PR reviews

## Code of Conduct

Be respectful and inclusive. We're building great software together!

## License

Contributions are licensed under MIT License.
