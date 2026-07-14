#!/bin/bash

# Build, sign, notarize, and package AltType as a distributable DMG.
#
# One-time prerequisites:
#   1. A "Developer ID Application" certificate in your keychain
#      (Xcode → Settings → Accounts → Manage Certificates → + → Developer ID Application)
#   2. Stored notarization credentials:
#      xcrun notarytool store-credentials "AltType" \
#        --apple-id <your-apple-id> --team-id WGJDQSJR57 --password <app-specific-password>
#      (app-specific password: https://account.apple.com → Sign-In and Security)
#
# Usage: ./scripts/make-release-dmg.sh [version]
#   e.g. ./scripts/make-release-dmg.sh 1.1.0

set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-1.1.0}"
NOTARY_PROFILE="AltType"
BUILD_DIR="$(pwd)/.release-build"
DMG_NAME="AltType-${VERSION}.dmg"
ENTITLEMENTS="theTypeAlternative/theTypeAlternative.entitlements"

IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)"/\1/')
if [ -z "$IDENTITY" ]; then
    echo "❌ No 'Developer ID Application' certificate found — see prerequisites at the top of this script."
    exit 1
fi
echo "🔏 Signing identity: $IDENTITY"

echo "🔨 Building Release..."
tuist generate >/dev/null
xcodebuild -workspace theTypeAlternative.xcworkspace \
    -scheme theTypeAlternative \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGNING_ALLOWED=NO \
    build | grep -E "BUILD (SUCCEEDED|FAILED)"

APP="$BUILD_DIR/Build/Products/Release/AltType.app"
[ -d "$APP" ] || { echo "❌ Build product not found at $APP"; exit 1; }

echo "🔏 Signing frameworks..."
find "$APP/Contents/Frameworks" -maxdepth 1 \( -name "*.framework" -o -name "*.dylib" \) -print0 2>/dev/null | \
while IFS= read -r -d '' fw; do
    codesign --force --options runtime --timestamp --sign "$IDENTITY" "$fw"
done

echo "🔏 Signing app (hardened runtime + entitlements)..."
codesign --force --options runtime --timestamp \
    --entitlements "$ENTITLEMENTS" \
    --sign "$IDENTITY" "$APP"
codesign --verify --deep --strict "$APP" && echo "   ✓ signature verified"

echo "📦 Creating DMG..."
STAGING=$(mktemp -d)
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
rm -f "$DMG_NAME"
hdiutil create -volname "AltType" -srcfolder "$STAGING" -ov -format UDZO "$DMG_NAME" >/dev/null
rm -rf "$STAGING"
codesign --force --timestamp --sign "$IDENTITY" "$DMG_NAME"

echo "📤 Notarizing (this can take a few minutes)..."
xcrun notarytool submit "$DMG_NAME" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG_NAME"
echo "   ✓ notarized and stapled"

echo ""
echo "✅ $DMG_NAME is ready to ship. Publish it with:"
echo ""
echo "   gh release create v${VERSION} ${DMG_NAME} \\"
echo "     --repo saianvesh3636/AltType \\"
echo "     --title \"AltType ${VERSION}\" \\"
echo "     --generate-notes"
