#!/bin/bash
set -e

echo "🚀 Starting Prune Build..."

# Clean and Build
xcodebuild -project Prune/Prune.xcodeproj \
           -scheme Prune \
           -destination 'generic/platform=iOS' \
           clean build

echo "✅ Build Succeeded!"
echo "📱 To run on your device, open Prune/Prune.xcodeproj and press the Play button (Cmd+R)."
