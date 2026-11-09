# Cross-platform development candidate

This branch reconciles the reviewed Windows work with Mac additions. One Flutter
codebase builds Android and iOS; Windows can edit/test Android, while an Apple
runner compiles iOS. Flutter is pinned to3.38.9 in `.flutter-version` and CI.

## Local setup
Install the pinned Flutter SDK and use `flutter doctor -v`. Run `flutter pub get`,
`flutter test`, and `flutter analyze`. Android debug: `flutter build apk --debug`.
On macOS with Xcode/CocoaPods1.16.2: `flutter build ios --simulator --debug`.
Generate changed Isar models with `dart run build_runner build --delete-conflicting-outputs`.
Do not commit SDK paths, signing keys, device data, caches, or build outputs.

## Current evidence and limits
-324 tests passed on the reconciled source; Android debug APK built.
- Analyzer has300 existing diagnostics and zero errors. Compared by rule/file
  occurrence count, this adds no diagnostics to the reviewed Windows baseline.
- Earlier Mac-only source built on Xcode26.6. During reconciliation the installed
  Xcode changed to27.0. The integrated iOS build is currently blocked by the pinned
  RevenueCat5.59.2 compiler error in PaywallColor.init(stringRepresentation:).
- Pods are floored at the app's existing iOS15.5 minimum. No vendor payment SDK
  patch or unreviewed dependency upgrade was made.
- iOS CI requests Xcode26.6 explicitly. Its hosted run is not yet verified.
- Real-device identity/billing/notifications, backend authorization and complete
  community account-deletion behavior still need validation. This is not a release.

## Build-only workflow
`.github/workflows/lyva-build.yml` runs on pushes only to `integration/cross-platform-2026-11-09` and uses immutable Action SHAs.
It runs tests/analysis, builds a development Android APK and an Apple Silicon (arm64) iOS simulator ZIP,
and retains artifacts for7days. It has no store-upload, deployment, signing-secret,
credential-persistence or distribution steps. An iOS simulator ZIP is not an IPA
and cannot be installed on a physical iPhone.

Pushes to this exact integration branch trigger build checks without modifying main.
Manual `workflow_dispatch` still requires the workflow on the default branch; it is
not the activation mechanism used here. Do not broaden branch triggers or add release
actions silently. Standard GitHub-hosted runners are used for this public repository;
no larger/paid runner or third-party paid build service is configured.

Analysis errors fail; warnings/info are reported but not fatal, including future
warnings. This is not a baseline-delta CI gate. Dependency locks are enforced;
CocoaPods lockfile drift fails. Release tasks fail explicitly without separately
configured authorized release signing. No release credentials belong in this branch.

## Reconciliation boundaries
Kept reviewed safety, recoverable-account/billing verification, notification and
photo-deletion protections. Added community through shared verified account flow,
optional recovery/exertion tracking and exports, exact subscription product IDs,
adult18+ validation and native launch/sign-in configuration. Cycle estimation code
is retained internally but not connected to live recommendations; unsafe phase-based
training advice and expanded aspiration-photo requests were not restored.

Hosted build notes: SDK manager is resolved from the Android SDK root, not assumed on PATH. iOS CI uses locked Pods and an explicit workspace build with a single derived-data directory, unsigned for the arm64 simulator. The first hosted attempt passed checks but failed final Pods_Runner linking; this workflow revision is being validated.
