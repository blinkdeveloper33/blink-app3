#!/bin/bash
TEMP_DIR=$(mktemp -d)
echo "Created temp directory: $TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT
xcrun dsymutil -o "$TEMP_DIR/LinkKit.framework.dSYM" "Pods/Plaid/LinkKit.framework/LinkKit"
xcrun dsymutil -o "$TEMP_DIR/MapboxCommon.framework.dSYM" "Pods/MapboxCommon/MapboxCommon.framework/MapboxCommon"
xcrun dsymutil -o "$TEMP_DIR/MapboxCoreMaps.framework.dSYM" "Pods/MapboxCoreMaps/MapboxCoreMaps.framework/MapboxCoreMaps"
cp -R "$TEMP_DIR/"*.dSYM .
echo "dSYM extraction complete"
