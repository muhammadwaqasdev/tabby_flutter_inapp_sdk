#!/usr/bin/env bash

echo "Building Android 🛠️"

make pre_build

cd example

fvm flutter build apk --release
echo "✓ Built example/build/app/outputs/flutter-apk/app-release.apk"