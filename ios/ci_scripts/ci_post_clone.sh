#!/bin/bash
# Xcode Cloud bootstrap only. Xcode Cloud owns archive/signing; no upload here.
set -euo pipefail
fail() { echo "error: $*" >&2; exit 1; }
[[ "${CI_XCODE_CLOUD:-}" == TRUE ]] || fail 'Run only inside Xcode Cloud, not on a personal Mac.'
[[ "${CI_BRANCH:-}" == integration/cross-platform-2026-11-09 ]] || fail 'Unexpected branch; this signing workflow is branch-scoped.'
[[ -z "${CI_PULL_REQUEST_NUMBER:-}" ]] || fail 'Pull-request builds must not use this signing workflow.'
[[ "${CI_BUILD_NUMBER:-}" =~ ^[1-9][0-9]{0,3}$ ]] || fail 'CI_BUILD_NUMBER must be an integer from 15 to 9999.'
(( CI_BUILD_NUMBER > 14 )) || fail 'Set Xcode Cloud Next Build Number above 14 and above every Apple-uploaded build.'
[[ -n "${CI_PRIMARY_REPOSITORY_PATH:-}" ]] || fail 'Missing repository path.'
cd "$CI_PRIMARY_REPOSITORY_PATH"
[[ "$(git rev-parse --show-toplevel)" == "$(pwd -P)" ]] || fail 'Expected repository root.'
[[ "$(uname -s)" == Darwin ]] || fail 'Requires macOS.'
[[ "$(xcodebuild -version | head -1)" == 'Xcode 26.6' ]] || fail 'Pin Xcode Cloud to validated Xcode 26.6, not Latest Release.'
# The personal Mac profile is never copied into the cloud or used by this script.
[[ -z "${PROVISIONING_PROFILE_SPECIFIER:-}${PROVISIONING_PROFILE:-}${LYVA_PROFILE_Runner:-}" ]] || fail 'Manual profile environment must not be inherited.'
if grep -Eq 'PROVISIONING_PROFILE|CODE_SIGN_STYLE[[:space:]]*=[[:space:]]*Manual' ios/Runner.xcodeproj/project.pbxproj; then
  fail 'Project contains manual provisioning; review before cloud signing.'
fi

TOOLS="$(mktemp -d "${TMPDIR:-/tmp}/lyva-cloud-tools.XXXXXX")"
# Leave tools available for subsequent native archive phases in this ephemeral VM.
export FLUTTER_ROOT="$TOOLS/flutter"
git clone --depth 1 --branch 3.38.9 https://github.com/flutter/flutter.git "$FLUTTER_ROOT"
[[ "$(git -C "$FLUTTER_ROOT" rev-parse HEAD)" == 67323de285b00232883f53b84095eb72be97d35c ]] || fail 'Flutter tag does not match reviewed commit.'
export PATH="$FLUTTER_ROOT/bin:$PATH"
flutter config --no-analytics
flutter precache --ios

# Avoid macOS system Ruby 2.6 and do not silently select a newer CocoaPods.
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1
brew list --versions ruby@3.4 >/dev/null 2>&1 || brew install ruby@3.4
export PATH="$(brew --prefix ruby@3.4)/bin:$PATH"
export GEM_HOME="$TOOLS/gems"
export GEM_PATH="$GEM_HOME"
gem install cocoapods --version 1.16.2 --no-document
mkdir -p "$TOOLS/bin"
cat > "$TOOLS/bin/pod" <<'POD'
#!/bin/bash
exec ruby -r rubygems -e 'gem "cocoapods", "=1.16.2"; load Gem.bin_path("cocoapods", "pod", "=1.16.2")' -- "$@"
POD
chmod +x "$TOOLS/bin/pod"
export PATH="$TOOLS/bin:$PATH"
[[ "$(pod --version)" == 1.16.2 ]] || fail 'Unexpected CocoaPods version.'

flutter pub get --enforce-lockfile
# Existing warnings/info remain visible; analyzer errors and test failures block archive.
flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings
flutter test --no-pub
flutter build ios --release --config-only --no-codesign --no-pub \
  --build-name=1.0.0 --build-number="$CI_BUILD_NUMBER"
(cd ios && pod install --deployment)
git diff --exit-code -- pubspec.lock ios/Podfile.lock
# Xcode reads Flutter's generated absolute SDK path during its later build phase.
grep -Fx "FLUTTER_BUILD_NUMBER=$CI_BUILD_NUMBER" ios/Flutter/Generated.xcconfig >/dev/null || fail 'Generated Flutter build number mismatch.'
echo "Lyva cloud bootstrap passed for $(git rev-parse HEAD), version 1.0.0 ($CI_BUILD_NUMBER)."
echo 'Archive/signing and any upload remain controlled by the separately reviewed Xcode Cloud workflow.'
