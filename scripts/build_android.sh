#!/usr/bin/env bash

echo "Building Android 🛠️"

cd example

fvm flutter build apk --release

cd ..

# Prepare version
fvm dart run scripts/prepare_version.dart

eval "$(
  cat ./scripts/.env_version | awk '!/^\s*#/' | awk '!/^\s*$/' | while IFS='' read -r line; do
    key=$(echo "$line" | cut -d '=' -f 1)
    value=$(echo "$line" | cut -d '=' -f 2-)
    echo "export $key=\"$value\""
  done
)"

echo "📦 got version $TABBY_APP_VERSION+$TABBY_APP_BUILD_NUMBER"

version_name="$TABBY_APP_VERSION($TABBY_APP_BUILD_NUMBER)"

echo "👉 Currently in dir: $(pwd)"

ls example/build/app/outputs/flutter-apk/*.apk

export ARTIFACT_PATH="$(pwd)/example/build/app/outputs/flutter-apk/app-release.apk"
echo "👉 ARTIFACT_PATH path: $ARTIFACT_PATH"

eval "$(
  cat .secure_files/.env | awk '!/^\s*#/' | awk '!/^\s*$/' | while IFS='' read -r line; do
    key=$(echo "$line" | cut -d '=' -f 1)
    value=$(echo "$line" | cut -d '=' -f 2-)
    echo "export $key=\"$value\""
  done
)"

cd example/android
fastlane init
fastlane distribute
