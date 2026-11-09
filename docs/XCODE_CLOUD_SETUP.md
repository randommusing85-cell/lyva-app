# Dedicated Lyva Xcode Cloud workflow (preparation)

`ios/ci_scripts/ci_post_clone.sh` prepares the Flutter workspace for Apple's native
archive/signing. Flutter documents this exact script location for an `ios` project.
This file alone does not create a workflow, upload an app, or distribute to testers.

## Workflow settings to verify in Apple

- Dedicated **Lyva AI**, app ID `6763887116`, bundle `ai.kineticiq.lyva`, team
  `553UWDXG8D`. Do not repurpose another app's product silently.
- Repository `randommusing85-cell/lyva-app`; workspace `ios/Runner.xcworkspace`,
  shared scheme `Runner`, iOS Archive with Release configuration.
- Draft UI pins **Xcode 26.6 (17F113)** and **macOS 26.5.1**, not floating latest aliases. Verify both again before saving/activation.
- Exact branch `integration/cross-platform-2026-11-09`, any file changes. Do not
  trigger signing on pull requests, forks or arbitrary branches.
- Set **Next Build Number** to at least 15 AND greater than all existing uploaded
  builds, including processing uploads. The bootstrap fails at 14 or below and
  propagates `CI_BUILD_NUMBER` to Flutter's generated build version. Coordinate
  other local/cloud pipelines so no one uploads the same number.
- Configure Apple-managed signing. Do not transfer the Mac's private key or manual
  provisioning profile, add signing secrets to GitHub, or create a personal-Mac
  self-hosted runner. Account/repository authorization changes require review.
- Verify included Xcode Cloud capacity and current usage before activation. No
  paid subscription/upgrade or unlimited spending is authorized by this file.
- Ken authorized automatic signed TestFlight delivery to **his own account only**.
  The existing `TE Testers` group was verified to have one member, Ken; recheck
  membership and every automatic-distribution destination before activation.
  Do not add testers, enable external/public testing, or broaden delivery.
- Keep the initial workflow **disabled** until Next Build Number is at least 15
  (and higher than all Apple uploads) and the own-account-only audience is verified.
  Final app/repository association is awaiting explicit approval; this preparation
  does not authorize that association or claim that a live workflow exists.
- Preserve the backend authorization, identity/billing, deletion/access and clinical
  release gates in `IOS_TESTFLIGHT_RELEASE.md`. Build success is not release approval.

## Bootstrap behavior and bounds

Fresh SDK from official Flutter repository, version 3.38.9 and exact commit
`67323de285b00232883f53b84095eb72be97d35c`; iOS cache; Ruby 3.4 from Homebrew;
CocoaPods exactly 1.16.2. Homebrew patch releases and Ruby gem transitive dependencies
are not fully locked, so this is not a byte-for-byte reproducible toolchain.
Dart and Pods lockfiles are enforced. Tests and analyzer errors block archive.
Existing analyzer warnings/info are reported but are not a baseline-delta gate.
The temporary Flutter install remains available for the native archive via generated
`FLUTTER_ROOT`; the script does not change global developer-tool selection.

The bootstrap refuses non-cloud/local invocation, unsupported branches, pull
requests, invalid build numbers, Xcode drift, and explicit manual-profile settings.
These are accidental-misconfiguration guards, not protection against a trusted
committer modifying CI code. Review source changes before permitting signed delivery.

## Verification status

Prepared only until a real Xcode Cloud run for the exact commit succeeds. Local
syntax/guard tests are not evidence that Apple's runner installed dependencies,
resolved signing, archived, uploaded, or processed a build. Confirm each separately.
The existing local signed build 14 does not prove this cloud workflow works.

References:
- https://docs.flutter.dev/deployment/cd#xcode-cloud
- https://developer.apple.com/documentation/xcode/writing-custom-build-scripts
- https://developer.apple.com/documentation/xcode/environment-variable-reference

## Cloud build 15 bootstrap correction

Build 15 stopped before app compilation: its arm64 host supplied x86_64 Homebrew
Ruby, but bigdecimal's native extension was built for arm64. The bootstrap now
reads Ruby's own `RbConfig::CONFIG["target_cpu"]` and sets architecture flags for
all native gem compilation (including bigdecimal and nkf) in an isolated subshell.
It explicitly loads bigdecimal, nkf, ffi and CocoaPods with the same selected Ruby
that the `pod` wrapper uses. Compiler flags do not leak into Flutter/iOS builds.
This corrects the observed mismatch; success still requires a fresh cloud run.

Build 16 showed environment flags alone do not override mkmf's RbConfig defaults.
The next revision passes explicit `--with-cflags`, `--with-cxxflags` and
`--with-ldflags` extconf arguments through RubyGems to native dependencies.
A real isolated C extension was compiled and loaded with local arm64 Ruby 4.0.0;
its generated Makefile and compiler/linker commands contained the explicit flags.
The environment-only control did not adopt the supplied CFLAGS. This verifies
mkmf argument handling locally, not cloud x86_64 Ruby 3.4 compatibility; the next
cloud run must verify that separately.
