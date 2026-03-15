#!/bin/bash
# Generate Xcode project for MedCare iOS app
# Requires: xcodegen (brew install xcodegen)

set -e

cd "$(dirname "$0")/.."

# Check if xcodegen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "xcodegen not found. Installing via Homebrew..."
    brew install xcodegen
fi

echo "Generating Xcode project..."
xcodegen generate

echo "Opening in Xcode..."
open MedCare.xcodeproj
