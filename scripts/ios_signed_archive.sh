#!/bin/bash
# Local-only signing. Never exports credentials, uploads, or distributes a build.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail() { echo "ERROR: $*" >&2; exit 1; }
[[ $# -ge 2 && $# -le 3 ]] || fail 'Usage: bash scripts/ios_signed_archive.sh NEXT_BUILD VERIFIED_APPLE_MAX [--check]'
NEXT="$1"; PREVIOUS="$2"; MODE="${3:-archive}"
[[ "$MODE" == archive || "$MODE" == --check ]] || fail 'Unknown mode'
# Explicit, recently verified Apple maximum; never derive from GitHub run_number.
[[ "$NEXT" =~ ^[1-9][0-9]{0,3}$ && "$PREVIOUS" =~ ^(0|[1-9][0-9]{0,3})$ ]] || fail 'Build numbers must be decimal integers from 0 to 9999; next must be positive'
(( NEXT > PREVIOUS && NEXT > 12 )) || fail 'Next build must exceed both the verified Apple maximum and historical build 12'
[[ "$(uname -s)" == Darwin ]] || fail 'Signing requires macOS'
[[ -z "$(git status --porcelain)" ]] || fail 'Use a clean committed checkout'
[[ "$(git branch --show-current)" == integration/cross-platform-2026-11-09 ]] || fail 'Unexpected source branch'
[[ "$(xcodebuild -version | head -1)" == 'Xcode 26.6' ]] || fail 'Select validated Xcode 26.6 via DEVELOPER_DIR; Xcode 27 conflicts with locked RevenueCat'
[[ "$(pod --version)" == 1.16.2 ]] || fail 'CocoaPods 1.16.2 required'
flutter --version | head -1 | grep -q '^Flutter 3.38.9 ' || fail 'Flutter 3.38.9 required'
PROFILE="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles/2f4b5c12-79b8-4a06-b054-b7fc44dfd178.mobileprovision"
[[ -f "$PROFILE" ]] || fail 'Reviewed Lyva App Store profile unavailable; revalidate signing instead of creating credentials automatically'
IDENTITY="$(python3 - "$PROFILE" <<'PY'
import datetime,hashlib,plistlib,subprocess,sys
p=plistlib.loads(subprocess.check_output(['security','cms','-D','-i',sys.argv[1]],stderr=subprocess.DEVNULL))
e=p['Entitlements']
assert p['ExpirationDate']>datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None),'Expired profile'
assert e['application-identifier']=='553UWDXG8D.ai.kineticiq.lyva'
assert not e.get('get-task-allow') and not p.get('ProvisionedDevices')
assert e.get('com.apple.developer.applesignin')==['Default']
identities=subprocess.check_output(['security','find-identity','-v','-p','codesigning'],text=True)
match=[hashlib.sha1(c).hexdigest().upper() for c in p['DeveloperCertificates'] if hashlib.sha1(c).hexdigest().upper() in identities]
assert match,'No valid matching distribution identity in keychain'
print(match[0])
PY
)"
echo "Signing preflight passed: 1.0.0 ($NEXT), source $(git rev-parse HEAD). No credentials exported."
[[ "$MODE" != --check ]] || exit 0
OUT="$ROOT/build/ios-signed/$NEXT"
[[ ! -e "$OUT" ]] || fail 'Build output exists; use a new number or inspect the previous result, never overwrite blindly'
mkdir -p "$OUT"
flutter pub get --enforce-lockfile
flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings
flutter test --no-pub
flutter build ios --release --config-only --no-codesign --no-pub --build-name=1.0.0 --build-number="$NEXT"
(cd ios && pod install --deployment)
git diff --exit-code -- pubspec.lock ios/Podfile.lock
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$OUT/Runner.xcarchive" \
  -derivedDataPath "$OUT/derived" CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM=553UWDXG8D CODE_SIGN_IDENTITY="$IDENTITY" \
  PROVISIONING_PROFILE_SPECIFIER=2f4b5c12-79b8-4a06-b054-b7fc44dfd178 archive
# No -allowProvisioningUpdates: must use existing, reviewed signing material.
python3 - "$OUT/ExportOptions.plist" "$IDENTITY" <<'PY'
import plistlib,sys
with open(sys.argv[1],'wb') as f:
 plistlib.dump({'method':'app-store-connect','destination':'export','teamID':'553UWDXG8D','signingStyle':'manual','signingCertificate':sys.argv[2],'provisioningProfiles':{'ai.kineticiq.lyva':'2f4b5c12-79b8-4a06-b054-b7fc44dfd178'},'manageAppVersionAndBuildNumber':False,'uploadSymbols':False},f)
PY
xcodebuild -exportArchive -archivePath "$OUT/Runner.xcarchive" \
  -exportOptionsPlist "$OUT/ExportOptions.plist" -exportPath "$OUT/export"
codesign --verify --deep --strict "$OUT/Runner.xcarchive/Products/Applications/Runner.app"
echo "LOCAL EXPORT ONLY: $OUT/export. No upload or tester distribution performed."
