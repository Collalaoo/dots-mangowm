#!/usr/bin/env bash
# Batch-patches QML files to replace Quickshell.Hyprland imports with mangowm module
# Run from dots/.config/quickshell/ii/

set -e

MANGOWM_DIR="$(cd "$(dirname "$0")/../../quickshell/ii" && pwd)"
QML_FILES=$(find "$MANGOWM_DIR" -name "*.qml" -type f)

echo "Patching QML files to use MangoWM IPC..."

for f in $QML_FILES; do
    # Check if file imports Hyprland
    if grep -q "Quickshell.Hyprland" "$f" 2>/dev/null; then
        # Replace import
        sed -i 's/import Quickshell.Hyprland/import ..\/services\/mangowm 1.0/g' "$f"
        # Replace Hyprland singleton usage with MangoWMData
        sed -i 's/\bHyprland\./MangoWMData./g' "$f"
        sed -i 's/\bHyprlandFocusGrab\b/MangoWMFocusGrab/g' "$f"
        echo "  Patched: $f"
    fi
done

echo ""
echo "Done! Check for any remaining Hyprland references:"
grep -r "Quickshell.Hyprland\|Hyprland\b" "$MANGOWM_DIR" --include="*.qml" -l 2>/dev/null || echo "  (none found)"
