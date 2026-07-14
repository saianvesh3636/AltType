#!/bin/bash

# Reset AltType to a first-run state: permissions, settings, and app data.
# Useful for verifying the full onboarding flow from scratch.
#
# Note: `defaults delete` alone is NOT enough — the app flushes cached settings
# on exit and cfprefsd caches the domain, so the plist must be removed and the
# daemon restarted for the wipe to stick.

set -e

BUNDLE_ID="com.thetypealternative.app"

echo "🔄 Resetting AltType to fresh-install state..."

echo "1️⃣  Stopping app..."
pkill -f "AltType.app/Contents/MacOS" 2>/dev/null || true
for _ in $(seq 1 20); do
    pgrep -f "AltType.app/Contents/MacOS" >/dev/null || break
    sleep 0.5
done
if pgrep -f "AltType.app/Contents/MacOS" >/dev/null; then
    echo "   ⚠️  App still running (Xcode debugger attached?). Stop it in Xcode and re-run."
    exit 1
fi
echo "   ✓ App stopped"

echo "2️⃣  Resetting permissions..."
tccutil reset Microphone "$BUNDLE_ID" >/dev/null
tccutil reset Accessibility "$BUNDLE_ID" >/dev/null
tccutil reset ListenEvent "$BUNDLE_ID" >/dev/null
echo "   ✓ Microphone, Accessibility, Input Monitoring reset"

echo "3️⃣  Wiping settings..."
defaults delete "$BUNDLE_ID" 2>/dev/null || true
rm -f ~/Library/Preferences/"$BUNDLE_ID".plist
killall cfprefsd 2>/dev/null || true
echo "   ✓ Settings wiped"

echo "4️⃣  Wiping app data..."
rm -rf ~/Library/Application\ Support/TheTypeAlternative
echo "   ✓ App data wiped"

sleep 1
if defaults read "$BUNDLE_ID" >/dev/null 2>&1; then
    echo "❌ Settings domain still exists — re-run this script"
    exit 1
fi

echo ""
echo "✅ Done. Launch AltType to walk through onboarding fresh."
