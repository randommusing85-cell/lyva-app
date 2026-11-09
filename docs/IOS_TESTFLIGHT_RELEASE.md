# Signed iOS and TestFlight release gate

## Verified 2026-11-09

- Lyva AI: App Store Connect app 6763887116, bundle `ai.kineticiq.lyva`, team `553UWDXG8D`.
- Latest displayed TestFlight version 1.0.0 build 12 is expired. Recheck Build Uploads and all versions immediately before every upload; 13 is only a candidate, not a reservation.
- Internal group `TE Testers` exists. Automatic distribution could not be verified. No external groups displayed. **Do not upload until automatic distribution is checked and disabled or its audience is explicitly approved.** Do not equate upload with no tester distribution.
- Existing Mac distribution identities and Lyva App Store provisioning profile are present. Profile expires 2027-01-04 and includes Sign in with Apple. Private keys were not exported.
- Local Xcode 27.0 is incompatible with the locked RevenueCat native SDK. Hosted Xcode 26.6 passed the simulator build, not a signed device archive. No alternate local Xcode is installed; approximately 21 GiB free at inspection.
- Existing Xcode Cloud product is the different PrimeForm app/repository, main-only, floating latest Xcode, no distribution post-action. Do not repoint it as though it were Lyva.
- App Store Connect still requests Paid Applications Schedule review. Agreement not accepted; Account Holder must review. TestFlight's exact blocking behavior remains untested.

## Prepared local archive stage

`scripts/ios_signed_archive.sh NEXT_BUILD VERIFIED_APPLE_MAX [--check]` validates a clean integration branch, compatible pinned tools, existing unexpired profile and matching distribution identity. It then runs checks, archives and exports locally using manual signing. It never creates profiles, exports keys, uploads or distributes.

After installing/selecting an authorized Xcode 26.6, example (only after rechecking Apple's maximum):

```sh
DEVELOPER_DIR=/Applications/Xcode_26.6.app/Contents/Developer \
  bash scripts/ios_signed_archive.sh 13 12 --check
# Remove --check only when the preflight passes and a local archive is intended.
```

A new build number must exceed all previous uploaded numbers for the version. Use an explicit verified maximum and serialize uploads. Do not use GitHub run_number: workflows reset and different pipelines collide. Recheck immediately before upload; never retry an uncertain upload until its outcome is known. Export disables automatic build renumbering.

The script is prepared, not device-build validated: Xcode 26.6 is unavailable locally. Hosted signing would additionally require an expressly approved transfer of private signing material to GitHub's secret storage and isolated temporary-keychain lifecycle. No such transfer is currently authorized or configured. The lower-exposure alternative is a compatible local Xcode using the existing keys, but it does not alone provide unattended builds from Kei.

## Before connecting unattended delivery from Kei

Choose an authorized signing route: dedicated Lyva Xcode Cloud configuration (verify supported compiler and repository authorization), or GitHub hosted signing with approved credential storage. Keep secrets restricted to this repository and approved release branches; never expose them to pull-request code. Use a separately protected release stage and require review before upload. Do not install a persistent self-hosted runner on the personal Mac without explicit security approval. Preserve ordinary build-only push checks.

## Upload and tester-release gates

1. Verify archive bundle ID, entitlements, version, build number and expected commit; inspect export result and device install/sign-in/billing behavior.
2. Verify Paid Applications Schedule/account status; do not accept legal agreements automatically.
3. Verify internal-group automatic distribution. Obtain approval for exact tester audience and configure no automatic tester release before any upload.
4. Recheck backend AI endpoint authorization, Firebase/RevenueCat identity and entitlement linkage, community access rules and account deletion. Publicly callable AI endpoints and unverified deletion/access behavior block broader distribution.
5. Keep personalized postpartum exercise disabled pending clinical review. Do not revive phase/ovulation-driven exercise prescriptions.
6. Upload only after the preceding gates and explicit upload scope are resolved. Check Apple processing status before saying the build is available. TestFlight external testing may additionally require Apple's beta review.
7. No App Store review submission, public release, tester invites or production deployment is authorized by this preparation.

Official account: https://appstoreconnect.apple.com/apps/6763887116


## Signing preparation update, 2026-11-09

Xcode 26.6 (17F113) is now installed side-by-side at
`~/Applications/Xcode_26.6.app`. Its Apple-signed package and app signature passed
verification; first-launch status passed. Global Xcode 27 selection is unchanged.
Use `DEVELOPER_DIR="$HOME/Applications/Xcode_26.6.app/Contents/Developer"`.

The old Xcode-managed App Store profile referenced a different signing certificate.
With explicit user approval, created and installed manual profile
`Lyva App Store Local 2026-11-09`, UUID
`2f4b5c12-79b8-4a06-b054-b7fc44dfd178`, expiry 2027-09-01 05:31:03 UTC.
It matches the existing local distribution identity
`743100645AA175E182100BE6BCBBCE55A444880F`. No new key/certificate was created,
exported or revoked; the old profile remains untouched. Existing App ID capabilities
were retained, not modified. The script pins the new UUID.
