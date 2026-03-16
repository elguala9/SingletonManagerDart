# Release Checklist

## Packages to Publish

### 1. singleton_manager_generator v0.1.4
**Priority**: 🔴 CRITICAL (Bug fix)

```bash
cd packages/singleton_manager_generator
flutter pub publish
```

**What's being fixed**:
- Critical bug in source_parser.dart: undefined getter 'name2'
- Generator was crashing when extracting field types from class declarations
- Fix: Changed `typeAnnotation.name2.lexeme` to `typeAnnotation.name.lexeme`

**Version**: 0.1.3 → 0.1.4
**Release Date**: 2026-03-16

---

### 2. singleton_manager v0.3.5
**Priority**: 🟡 PATCH (Code quality)

```bash
cd packages/singleton_manager
flutter pub publish
```

**What's being improved**:
- Code quality optimization: Cascade operators in singleton_di_ext.dart
- No functional changes, purely cosmetic improvements

**Version**: 0.3.4 → 0.3.5
**Release Date**: 2026-03-16

---

## Pre-Publication Checks

- [x] All dart analyze issues resolved (0 errors, 0 warnings)
- [x] All tests passing
- [x] CHANGELOG.md updated with release notes
- [x] pubspec.yaml version bumped
- [x] Git commit created: `5a59123`
- [x] Git tags created:
  - `singleton_manager_generator-0.1.4`
  - `singleton_manager-0.3.5`

---

## Publication Steps

1. **Authenticate with pub.dev** (if not already authenticated):
   ```bash
   flutter pub login
   ```

2. **Publish singleton_manager_generator first** (it's a dependency for end users):
   ```bash
   cd packages/singleton_manager_generator
   flutter pub publish --dry-run  # Optional: Preview changes
   flutter pub publish
   ```

3. **Publish singleton_manager** (main package):
   ```bash
   cd packages/singleton_manager
   flutter pub publish --dry-run  # Optional: Preview changes
   flutter pub publish
   ```

4. **Verify on pub.dev**:
   - https://pub.dev/packages/singleton_manager_generator/versions
   - https://pub.dev/packages/singleton_manager/versions

---

## Post-Publication

- [ ] Verify both packages appear on pub.dev with correct versions
- [ ] Check GitHub releases are created (if using GitHub Actions)
- [ ] Update project announcements/documentation if needed

---

## Git Commands

```bash
# View the release commit
git show 5a59123

# View the tags
git tag -l | grep -E "(singleton_manager_generator-0.1.4|singleton_manager-0.3.5)"

# Push tags to remote (if using remote)
git push origin singleton_manager_generator-0.1.4
git push origin singleton_manager-0.3.5
```

