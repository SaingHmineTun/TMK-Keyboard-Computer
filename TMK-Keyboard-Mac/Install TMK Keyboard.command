#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BUNDLE_NAME="TMK Keyboard.bundle"
SOURCE_BUNDLE="$SCRIPT_DIR/$BUNDLE_NAME"
DEST_DIR="$HOME/Library/Keyboard Layouts"
DEST_BUNDLE="$DEST_DIR/$BUNDLE_NAME"

fail() {
  MESSAGE=$1
  /usr/bin/osascript -e "display dialog \"$MESSAGE\" buttons {\"OK\"} default button \"OK\" with title \"TMK Keyboard Installer\"" >/dev/null 2>&1 || true
  echo "$MESSAGE" >&2
  exit 1
}

if [ ! -d "$SOURCE_BUNDLE" ]; then
  fail "TMK Keyboard.bundle was not found beside this installer."
fi

/bin/mkdir -p "$DEST_DIR"
/bin/rm -rf "$DEST_BUNDLE"
/usr/bin/ditto --norsrc "$SOURCE_BUNDLE" "$DEST_BUNDLE"

SUCCESS_MESSAGE="TMK Keyboard has been installed. Sign out and sign back in, or restart your Mac, then add TMK Keyboard in System Settings > Keyboard > Text Input."

CHOICE=$(/usr/bin/osascript -e "display dialog \"$SUCCESS_MESSAGE\" buttons {\"Open Keyboard Settings\", \"OK\"} default button \"Open Keyboard Settings\" with title \"TMK Keyboard Installer\"" 2>/dev/null || true)

case "$CHOICE" in
*"Open Keyboard Settings"*)
  /usr/bin/open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension" >/dev/null 2>&1 || true
  ;;
esac

echo "$SUCCESS_MESSAGE"
exit 0
