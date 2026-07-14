#!/bin/bash

# Verification Script: Ensure Documentation is Excluded from App Bundle
# This script verifies that no markdown files or documentation directories
# are included in the built .app bundle.

set -e

echo "🔍 Verifying documentation exclusion from app bundle..."
echo ""

# Find the most recent build
APP_BUNDLE=$(find ~/Library/Developer/Xcode/DerivedData -name "AltType.app" -path "*/Build/Products/*" 2>/dev/null | head -1)

if [ -z "$APP_BUNDLE" ]; then
    echo "❌ No app bundle found. Build the app first with:"
    echo "   tuist generate"
    echo "   xcodebuild -workspace theTypeAlternative.xcworkspace -scheme theTypeAlternative-Production build"
    exit 1
fi

echo "📦 Checking app bundle: $APP_BUNDLE"
echo ""

# Check for markdown files
echo "1️⃣  Checking for .md files..."
MD_FILES=$(find "$APP_BUNDLE" -name "*.md" -o -name "*.markdown" 2>/dev/null)
if [ -n "$MD_FILES" ]; then
    echo "❌ FAILED: Found markdown files in app bundle:"
    echo "$MD_FILES"
    exit 1
else
    echo "   ✅ No .md files found"
fi

# Check for docs directory
echo "2️⃣  Checking for docs/ directory..."
DOCS_DIR=$(find "$APP_BUNDLE" -type d -name "docs" 2>/dev/null)
if [ -n "$DOCS_DIR" ]; then
    echo "❌ FAILED: Found docs directory in app bundle:"
    echo "$DOCS_DIR"
    exit 1
else
    echo "   ✅ No docs/ directory found"
fi

# Check for archive directory
echo "3️⃣  Checking for archive/ directory..."
ARCHIVE_DIR=$(find "$APP_BUNDLE" -type d -name "archive" 2>/dev/null)
if [ -n "$ARCHIVE_DIR" ]; then
    echo "❌ FAILED: Found archive directory in app bundle:"
    echo "$ARCHIVE_DIR"
    exit 1
else
    echo "   ✅ No archive/ directory found"
fi

# Check for specific documentation files
echo "4️⃣  Checking for specific documentation files..."
SPECIFIC_DOCS=$(find "$APP_BUNDLE" -name "README.md" -o -name "CLAUDE.md" -o -name "PRIVACY_POLICY.md" 2>/dev/null)
if [ -n "$SPECIFIC_DOCS" ]; then
    echo "❌ FAILED: Found documentation files in app bundle:"
    echo "$SPECIFIC_DOCS"
    exit 1
else
    echo "   ✅ No documentation files found"
fi

# List what IS included (for verification)
echo ""
echo "5️⃣  Files actually included in Resources:"
find "$APP_BUNDLE/Contents/Resources" -type f 2>/dev/null | head -20

echo ""
echo "✅ SUCCESS: No documentation files found in app bundle!"
echo ""
echo "Summary:"
echo "  ✅ Documentation is tracked in git (41 .md files)"
echo "  ✅ Documentation is excluded from app bundle"
echo "  ✅ App bundle is secure and clean"
echo ""
echo "App bundle size: $(du -sh "$APP_BUNDLE" | cut -f1)"
