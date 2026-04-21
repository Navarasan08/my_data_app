#!/usr/bin/env bash
# Build a release APK and upload it to Firebase App Distribution.
# Usage:
#   scripts/distribute_android.sh "Release notes text" "group1,group2"
#
# Requires: firebase CLI logged in (`firebase login`).

set -euo pipefail

APP_ID="1:446250056140:android:24cf269eaae717ca754569"
NOTES="${1:-Manual build from $(git rev-parse --short HEAD)}"
GROUPS="${2:-testers}"

echo "→ Building release APK"
flutter build apk --release

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK_PATH" ]; then
  echo "APK not found at $APK_PATH" >&2
  exit 1
fi

echo "→ Uploading $APK_PATH to Firebase App Distribution"
echo "   App: $APP_ID"
echo "   Groups: $GROUPS"
echo

firebase appdistribution:distribute "$APK_PATH" \
  --app "$APP_ID" \
  --groups "$GROUPS" \
  --release-notes "$NOTES"

echo
echo "✓ Done — testers will get an email shortly"
