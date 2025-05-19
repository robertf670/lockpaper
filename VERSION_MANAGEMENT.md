# Version Management Guide for Lockpaper

## Version Update Checklist

When releasing a new version of Lockpaper, follow these steps to ensure proper version management:

1. **Update version numbers**:
   - In `pubspec.yaml`: 
     - Increment version (format: `major.minor.patch+buildNumber`)
     - Example: `version: 1.1.0+2`
   
   - In `android/app/build.gradle.kts`:
     - Increment `versionCode` by 1
     - Update `versionName` to match semantic version from pubspec.yaml
     - Example: 
       ```kotlin
       versionCode = 3
       versionName = "1.1.0"
       ```

2. **Update version service**:
   - In `lib/core/services/version_service.dart`:
     - Update `currentAppVersion` constant to match new version
     - Example: `const String currentAppVersion = '1.1.0';`
     
   - Add a new entry to the `versionHistory` list at the TOP:
     ```dart
     ReleaseInfo(
       version: '1.1.0',  // New version
       releaseDate: DateTime(2024, 5, 30),  // Release date
       changes: [
         // List all changes with categories
         ReleaseChange(
           category: 'Feature',
           description: 'Description of new feature',
         ),
         // Add more changes...
       ],
     ),
     ```

3. **Commit version changes**:
   - Use descriptive commit message:
     ```
     git add .
     git commit -m "Version X.Y.Z: Brief summary of main changes"
     git push
     ```

4. **Build release**:
   - After CI checks pass, build release:
     ```
     flutter build appbundle --release
     ```

5. **Update Google Play listing**:
   - Upload new AAB file
   - Add release notes (can use your version history entries)
   - Review and publish

## Version Number Format

- **Semantic Versioning**: `MAJOR.MINOR.PATCH`
  - **MAJOR**: Incompatible API changes
  - **MINOR**: New features (backward compatible)
  - **PATCH**: Bug fixes (backward compatible)

- **Build Number**: Incremental integer that increases with each release
  - Used as `versionCode` in Android

## What's New Feature

The app automatically displays the "What's New" screen after updates, showing changes since the user's last version. This relies on properly maintaining the version history data.

## Notes for AI Assistants

When helping with code changes that constitute a new version:
1. Remind the user to update version numbers
2. Suggest appropriate version increments based on the nature of changes
3. Help create correctly formatted version history entries
4. Ensure all three version locations are updated consistently

## Common Mistakes to Avoid

- Forgetting to update all three version locations
- Inconsistent version numbers across different files
- Not adding entry to version history
- Using incorrect semantic versioning increments 