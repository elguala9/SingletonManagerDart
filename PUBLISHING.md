# Publishing Singleton Manager to pub.dev

## Prerequisites

1. **Pub.dev Account**
   - Create account at https://pub.dev
   - Verify email

2. **Dart SDK**
   ```bash
   dart --version  # Should be >=3.0.0
   ```

3. **Authentication**
   ```bash
   dart pub login
   # Opens browser for authentication
   # Credentials saved to ~/.dart-tool/pub-credentials.json
   ```

## Pre-Publication Checklist

### 1. Version Management

**Update version** in `packages/singleton_manager/pubspec.yaml`:

```yaml
version: 0.2.0  # Use semantic versioning
```

**Update** `CHANGELOG.md`:

```markdown
## [0.2.0] - 2026-03-11

### Added
- Feature description

### Changed
- Change description

### Fixed
- Fix description
```

### 2. Code Quality

```bash
# Full CI validation
melos run ci

# Should pass:
# ✓ Clean build
# ✓ Dependencies resolved
# ✓ Strict analysis
# ✓ Format check
# ✓ All tests passing
```

### 3. Documentation

- [ ] README.md updated with new features
- [ ] Examples updated
- [ ] CHANGELOG.md complete
- [ ] All public APIs have dartdoc comments
- [ ] doc/architecture.md up-to-date

### 4. Metadata

Verify `packages/singleton_manager/pubspec.yaml`:

```yaml
name: singleton_manager
version: 0.2.0
publish_to: # OMITTED (defaults to pub.dev)

# Required:
repository: https://github.com/elguala9/SingletonManagerDart
homepage: https://github.com/elguala9/SingletonManagerDart
issue_tracker: https://github.com/elguala9/SingletonManagerDart/issues
documentation: https://pub.dev/documentation/singleton_manager/latest/

# Recommended:
topics:
  - singleton
  - pattern
  - dependency-injection

platforms:
  android:
  ios:
  linux:
  macos:
  web:
  windows:
```

## Publication Process

### Dry Run (Recommended)

Always test publication first:

```bash
cd packages/singleton_manager
dart pub publish --dry-run
```

This validates:
- pubspec.yaml correctness
- All required files present (LICENSE, README.md)
- Documentation generation possible
- No analysis errors

Expected output:
```
Package has 0 warnings.
```

### Actual Publication

```bash
cd packages/singleton_manager
dart pub publish
```

Prompt will ask:
```
Publish singleton_manager 0.2.0 to pub.dev (y/n)?
```

Type `y` and confirm.

### Verification

1. Check pub.dev: https://pub.dev/packages/singleton_manager
2. Verify version appears
3. Check documentation renders correctly
4. Test installation:
   ```bash
   dart pub cache clean singleton_manager
   dart pub add singleton_manager
   ```

## Post-Publication

### 1. Git Tag

```bash
git tag v0.2.0
git push origin v0.2.0
```

### 2. GitHub Release

Create release at https://github.com/elguala9/SingletonManagerDart/releases

Include:
- Version number (v0.2.0)
- Changelog excerpt
- Link to pub.dev package
- Link to documentation

### 3. Announce

- Twitter/social media (optional)
- GitHub Discussions
- Dart/Flutter communities

## Troubleshooting

### "Missing README.md"
```bash
cd packages/singleton_manager
# Ensure README.md exists in root
```

### "Publish_to specifies 'none'"
```yaml
# In pubspec.yaml, remove or comment:
# publish_to: none
```

### "Lower constraint violation"
Check platform versions in pubspec.yaml environment section.

### "Field 'topics' must have valid values"
Use lowercase, kebab-case (e.g., `singleton-pattern`).

## Reference

- [Publishing Packages](https://dart.dev/tools/pub/publishing)
- [Package Layout Conventions](https://dart.dev/tools/pub/package-layout)
- [Pubspec Format](https://dart.dev/tools/pub/pubspec)

## Questions?

Check:
- Existing pub.dev documentation
- GitHub Issues
- Dart community forums
