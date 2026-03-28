#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

set -euo pipefail

cd "$(dirname "$0")"
cd ../

if [ -x "./.flutter/bin/flutter" ]; then
    FLUTTER="./.flutter/bin/flutter"
else
    FLUTTER="flutter"
fi

export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"

SHARE_EXTENSION_PLIST="ios/ShareExtension/Info.plist"
SHARE_EXTENSION_PLIST_BAK="$(mktemp /tmp/gitjournal-shareextension.XXXXXX.plist)"
cp "$SHARE_EXTENSION_PLIST" "$SHARE_EXTENSION_PLIST_BAK"

restore_share_extension_plist() {
    cp "$SHARE_EXTENSION_PLIST_BAK" "$SHARE_EXTENSION_PLIST"
    rm -f "$SHARE_EXTENSION_PLIST_BAK"
}

trap restore_share_extension_plist EXIT

BUILD_NUM=$(git rev-list --count HEAD)
echo "Build Number: $BUILD_NUM"

BUILD_NAME=$(grep '^version:' pubspec.yaml | awk '{ print $2 }' | awk -F "+" '{ print $1 }')
echo "Build Name: $BUILD_NAME"

LIBS_URL="https://github.com/GitJournal/ios-libraries/releases/download/v1.2/libs.zip"

normalize_ios_libs() {
    for lib in git2 ssh2 ssl crypto; do
        if [ -f "ios/libs/lib${lib}.framework" ]; then
            ln -sf "lib${lib}.framework" "ios/libs/lib${lib}.a"
        fi
    done
}

if [ ! -d "ios/libs/include" ]; then
    echo "Downloading iOS native libraries"
    rm -rf ios/libs
    mkdir -p ios/libs
    curl -L --fail "$LIBS_URL" -o /tmp/gitjournal-ios-libs.zip
    unzip -q /tmp/gitjournal-ios-libs.zip -d ios/libs

    if [ -d "ios/libs/libs" ]; then
        mv ios/libs/libs/* ios/libs/
        rmdir ios/libs/libs
    fi
fi

normalize_ios_libs

if [ ! -L "gj_common" ]; then
    echo "Setting up gj_common"
    if [ ! -d "git_bindings" ]; then
        git clone --depth 1 https://github.com/GitJournal/git_bindings.git
    fi
    ln -s git_bindings/gj_common gj_common
fi

$FLUTTER pub get
$FLUTTER precache --ios

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $BUILD_NAME" "$SHARE_EXTENSION_PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUM" "$SHARE_EXTENSION_PLIST"

cd ios
pod install
cd ../

$FLUTTER build ios --release --no-codesign --build-number="$BUILD_NUM" --build-name="$BUILD_NAME" --dart-define=INSTALL_SOURCE=appstore
