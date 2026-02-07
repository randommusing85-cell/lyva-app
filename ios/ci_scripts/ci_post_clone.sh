#!/bin/sh

# ci_post_clone.sh
# Xcode Cloud post-clone script for Flutter projects.
# This script installs Flutter and runs 'flutter pub get' to generate
# the Generated.xcconfig file that Xcode needs during the build.

set -e

echo "=== Installing Flutter ==="

# Clone Flutter SDK
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"

echo "=== Flutter version ==="
flutter --version

echo "=== Installing CocoaPods ==="
# Xcode Cloud images have Ruby, but may not have CocoaPods
gem install cocoapods

echo "=== Running flutter pub get ==="
cd "$CI_PRIMARY_REPOSITORY_PATH"
flutter pub get

echo "=== Installing Pods ==="
cd "$CI_PRIMARY_REPOSITORY_PATH/ios"
pod install

echo "=== Generated.xcconfig created ==="
cat "$CI_PRIMARY_REPOSITORY_PATH/ios/Flutter/Generated.xcconfig"
