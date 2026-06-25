#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
BUNDLE_NAME="TMK Keyboard.bundle"
BUNDLE_SOURCE="$PROJECT_DIR/$BUNDLE_NAME"
BUILD_ROOT=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/tmk-keyboard-pkg.XXXXXX")
PAYLOAD_ROOT="$BUILD_ROOT/payload"
PAYLOAD_KEYBOARD_DIR="$PAYLOAD_ROOT/Library/Keyboard Layouts"
COMPONENT_PACKAGE_NAME="tmk-keyboard-layout.pkg"
COMPONENT_PACKAGE_PATH="$BUILD_ROOT/$COMPONENT_PACKAGE_NAME"
PACKAGE_PATH="$SCRIPT_DIR/TMK Keyboard Installer.pkg"
ZIP_PATH="$SCRIPT_DIR/TMK Keyboard Installer.zip"
PACKAGE_ID="org.tmk.keyboardlayout.tmk-keyboard.pkg"
PACKAGE_VERSION="1.0"
PRODUCT_ID="org.tmk.keyboardlayout.tmk-keyboard.installer"
DISTRIBUTION_PATH="$SCRIPT_DIR/Distribution.xml"
RESOURCES_DIR="$SCRIPT_DIR/resources"
ICON_PNG="$RESOURCES_DIR/tmk-keyboard-installer.png"
ICON_ICNS="$RESOURCES_DIR/tmk-keyboard-installer.icns"

export COPYFILE_DISABLE=1

cleanup() {
  /bin/rm -rf "$BUILD_ROOT"
}

trap cleanup EXIT HUP INT TERM

if [ ! -d "$BUNDLE_SOURCE" ]; then
  echo "Missing keyboard bundle: $BUNDLE_SOURCE" >&2
  exit 1
fi

if [ ! -f "$DISTRIBUTION_PATH" ]; then
  echo "Missing installer distribution: $DISTRIBUTION_PATH" >&2
  exit 1
fi

if [ ! -f "$ICON_PNG" ]; then
  echo "Missing installer icon: $ICON_PNG" >&2
  exit 1
fi

make_iconset() {
  ICONSET_DIR="$BUILD_ROOT/tmk-keyboard-installer.iconset"

  /bin/mkdir -p "$ICONSET_DIR"
  /usr/bin/sips -z 16 16 "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
  /usr/bin/sips -z 32 32 "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
  /usr/bin/sips -z 32 32 "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
  /usr/bin/sips -z 64 64 "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
  /usr/bin/sips -z 128 128 "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
  /usr/bin/sips -z 256 256 "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
  /usr/bin/sips -z 256 256 "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
  /usr/bin/sips -z 512 512 "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
  /usr/bin/sips -z 512 512 "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
  /usr/bin/sips -z 1024 1024 "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null
  /usr/bin/iconutil -c icns "$ICONSET_DIR" -o "$ICON_ICNS"
}

apply_package_icon() {
  ICON_WORK="$BUILD_ROOT/pkg-icon.png"
  ICON_RSRC="$BUILD_ROOT/pkg-icon.rsrc"

  /bin/cp "$ICON_PNG" "$ICON_WORK"
  /usr/bin/sips -i "$ICON_WORK" >/dev/null

  if /usr/bin/DeRez -only icns "$ICON_WORK" > "$ICON_RSRC" 2>/dev/null; then
    /usr/bin/Rez -append "$ICON_RSRC" -o "$PACKAGE_PATH"
    /usr/bin/SetFile -a C "$PACKAGE_PATH"
  else
    echo "Warning: could not attach a custom Finder icon to $PACKAGE_PATH" >&2
  fi
}

make_iconset

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
  "$COMPONENT_PACKAGE_PATH"

/usr/bin/productbuild \
  --distribution "$DISTRIBUTION_PATH" \
  --resources "$RESOURCES_DIR" \
  --package-path "$BUILD_ROOT" \
  --identifier "$PRODUCT_ID" \
  --version "$PACKAGE_VERSION" \
  "$PACKAGE_PATH"

apply_package_icon

PACKAGE_FILE=$(basename "$PACKAGE_PATH")
/bin/rm -f "$ZIP_PATH"
(
  cd "$SCRIPT_DIR"
  /usr/bin/ditto -c -k --sequesterRsrc --rsrc "$PACKAGE_FILE" "$ZIP_PATH"
)

echo "Built: $PACKAGE_PATH"
echo "Built: $ZIP_PATH"
