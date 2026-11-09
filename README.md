# Cross-platform candidate

See [development and CI status](docs/CROSS_PLATFORM_DEVELOPMENT.md) before running or releasing this branch.

# Lyva development snapshot

Standalone private source snapshot for Mac development. This is not a release or TestFlight approval.

Use the Flutter version in `.flutter-version`. Restore Dart dependencies with `flutter pub get --enforce-lockfile`. On a Mac with existing Xcode and CocoaPods, review `pod install` changes in `ios/` and open `ios/Runner.xcworkspace`. The tracked Pod lockfile predates new auth dependencies; iOS restore, compilation, signing and capabilities have not been verified. Do not silently upgrade dependencies or enable auth-review flags.

The original Windows source passed 306 Flutter tests, the analyzer baseline gate (313 existing findings, zero new) and an Android debug build. Native Isar test-library loading and platform plugins still need Mac validation. No iOS archive, IPA or TestFlight upload was produced.

Basic local tracking remains available; known postpartum profile states cannot enable personalized generation. Clinical rules and actual postpartum personalization remain disabled. Source checks are not server protection: Firebase client configuration still targets the existing project, whose generation services require containment and verified authorization before release or live AI testing. No paid/live test is authorized by this snapshot.

No CI workflows, Xcode Cloud post-clone script, Firebase deployment configuration, signing material, task logs, user databases or internal operational handoffs are included. Do not connect automated distribution without explicit review and approval. Historical source contents and prior commits were not imported as Git history.
