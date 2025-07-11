Push the code on git
then
flutter analyze
dart format .  # Should say "All files formatted."
flutter pub publish --dry-run  # Check for formatting issues
flutter pub publish
After Publish Revert Formatting