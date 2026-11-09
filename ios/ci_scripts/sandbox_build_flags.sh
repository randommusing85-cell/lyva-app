#!/bin/bash
# Sourced by the reviewed Xcode Cloud bootstrap. No credentials or UID here.
LYVA_BUILD_FLAGS=()
case "${LYVA_PRIVATE_SANDBOX_BUILD:-}" in
  '') ;;
  apple-identity|apple-billing)
    LYVA_BUILD_FLAGS=(
      --dart-define=LYVA_SANDBOX_TEST_BUILD=true
      --dart-define=LYVA_AUTH_PROJECT_ID=primeform-app
      --dart-define=LYVA_APPLE_AUTH_REVIEWED=true
      --dart-define=LYVA_GOOGLE_AUTH_REVIEWED=false
    )
    if [[ "$LYVA_PRIVATE_SANDBOX_BUILD" == apple-billing ]]; then
      [[ "${LYVA_SANDBOX_IOS_PUBLIC_KEY:-}" =~ ^appl_[A-Za-z0-9]+$ ]] || {
        echo 'Supply the verified App Store public SDK key; never a RevenueCat secret key.' >&2
        exit 1
      }
      LYVA_BUILD_FLAGS+=(
        --dart-define=LYVA_ACCOUNT_BACKEND_REVIEWED=true
        --dart-define=LYVA_ACCOUNT_FUNCTIONS_REGION=us-central1
        --dart-define=LYVA_BILLING_POLICY_REVISION=ios-single-tester-sandbox-v1
        --dart-define=LYVA_BILLING_IDENTITY_REVIEWED=true
        "--dart-define=LYVA_REVENUECAT_IOS_KEY=$LYVA_SANDBOX_IOS_PUBLIC_KEY"
      )
    fi
    ;;
  *) echo 'Unsupported private sandbox build mode.' >&2; exit 1 ;;
esac
