# TMK Keyboard for macOS

This is a standalone macOS keyboard layout project for typing Shan Unicode text.
It is separate from the original Windows MKLC keyboard project in the repository root.

## Files

- `TMK Keyboard.bundle` - macOS keyboard layout bundle.
- `docs/key-mapping.md` - Normal and Shift mapping used by the bundle.
- `assets/tmk-keyboard-mapping.html` - Browser-rendered keyboard mapping artwork source.
- `assets/tmk-keyboard-mapping.png` - Shareable keyboard mapping image.

## Install For Current User

Run this from the repository root:

```sh
mkdir -p ~/Library/Keyboard\ Layouts
cp -R "TMK Keyboard macOS/TMK Keyboard.bundle" ~/Library/Keyboard\ Layouts/
```

Then sign out and sign back in, or restart the Mac.

Open `System Settings > Keyboard > Text Input > Edit...`, press `+`, and add **TMK Keyboard**. It should appear under Shan or Other, depending on the macOS version.

## Install For All Users

Copy the bundle into `/Library/Keyboard Layouts/` instead:

```sh
sudo cp -R "TMK Keyboard macOS/TMK Keyboard.bundle" /Library/Keyboard\ Layouts/
```

Then sign out and sign back in, or restart the Mac.

## Regenerate Mapping Artwork

Run this from the repository root after editing the mapping:

```sh
node "TMK Keyboard macOS/tools/generate-keymap-artwork.js"
```

The script regenerates `assets/tmk-keyboard-mapping.svg`. The current shareable PNG is rendered from `assets/tmk-keyboard-mapping.html`, matching the Windows keyboard image style.

## Notes

- The layout emits Unicode Shan/Myanmar characters directly.
- Command, Control, and Option key combinations use QWERTY output so common shortcuts such as `Command-C`, `Command-V`, and `Command-Z` keep working.
- The pasted source mapping included invisible zero-width spaces before `ေ` and `ဵ`. This layout intentionally emits only `U+1031` and `U+1035` for those keys.
