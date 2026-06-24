#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
BUNDLE_NAME="TMK Keyboard.bundle"
BUNDLE_SOURCE="$PROJECT_DIR/$BUNDLE_NAME"
BUILD_ROOT=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/tmk-keyboard-pkg.XXXXXX")
PAYLOAD_ROOT="$BUILD_ROOT/payload"
PAYLOAD_KEYBOARD_DIR="$PAYLOAD_ROOT/Library/Keyboard Layouts"
PACKAGE_PATH="$SCRIPT_DIR/TMK Keyboard Installer.pkg"
PACKAGE_ID="org.tmk.keyboardlayout.tmk-keyboard.pkg"
PACKAGE_VERSION="1.0"

export COPYFILE_DISABLE=1

cleanup() {
  /bin/rm -rf "$BUILD_ROOT"
}

trap cleanup EXIT HUP INT TERM

if [ ! -d "$BUNDLE_SOURCE" ]; then
  echo "Missing keyboard bundle: $BUNDLE_SOURCE" >&2
  exit 1
fi

/bin/mkdir -p "$PAYLOAD_KEYBOARD_DIR"
/bin/cp -R -X "$BUNDLE_SOURCE" "$PAYLOAD_KEYBOARD_DIR/$BUNDLE_NAME"
/usr/bin/xattr -cr "$PAYLOAD_ROOT" 2>/dev/null || true

/usr/bin/pkgbuild \
  --root "$PAYLOAD_ROOT" \
  --scripts "$SCRIPT_DIR/scripts" \
  --identifier "$PACKAGE_ID" \
  --version "$PACKAGE_VERSION" \
  --install-location / \
  --ownership recommended \
  "$PACKAGE_PATH"

echo "Built: $PACKAGE_PATH"
