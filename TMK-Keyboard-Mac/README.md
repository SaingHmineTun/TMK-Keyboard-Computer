# TMK Keyboard for macOS

This is a standalone macOS keyboard layout project for typing Shan Unicode text.

## Files

- `TMK Keyboard.bundle` - macOS keyboard layout bundle.
- `docs/key-mapping.md` - Normal and Shift mapping used by the bundle.
- `assets/tmk-keyboard-mapping.html` - Browser-rendered keyboard mapping artwork source.
- `assets/tmk-keyboard-mapping.png` - Shareable keyboard mapping image.
- `assets/tmk-keyboard-icon.svg` - Source artwork for the macOS input-source icon.
- `assets/tmk-keyboard-icon.png` - 1024px preview of the macOS input-source icon.

## Install For Current User

Run this from the repository root:

```sh
mkdir -p ~/Library/Keyboard\ Layouts
cp -R "TMK-Keyboard-Mac/TMK Keyboard.bundle" ~/Library/Keyboard\ Layouts/
```

Then sign out and sign back in, or restart the Mac.

If you previously installed an older copy, remove it before copying the new one so macOS refreshes the icon:

```sh
rm -rf ~/Library/Keyboard\ Layouts/TMK\ Keyboard.bundle
cp -R "TMK-Keyboard-Mac/TMK Keyboard.bundle" ~/Library/Keyboard\ Layouts/
```

Open `System Settings > Keyboard > Text Input > Edit...`, press `+`, and add **TMK Keyboard**. It should appear under Shan or Other, depending on the macOS version.

## Install For All Users

Copy the bundle into `/Library/Keyboard Layouts/` instead:

```sh
sudo cp -R "TMK-Keyboard-Mac/TMK Keyboard.bundle" /Library/Keyboard\ Layouts/
```

If you previously installed an older all-users copy, remove it before copying the new one:

```sh
sudo rm -rf /Library/Keyboard\ Layouts/TMK\ Keyboard.bundle
sudo cp -R "TMK-Keyboard-Mac/TMK Keyboard.bundle" /Library/Keyboard\ Layouts/
```

Then sign out and sign back in, or restart the Mac.

## Regenerate Mapping Artwork

Run this from the repository root after editing the mapping:

```sh
node "TMK-Keyboard-Mac/tools/generate-keymap-artwork.js"
```

The script regenerates `assets/tmk-keyboard-mapping.svg`. The current shareable PNG is rendered from `assets/tmk-keyboard-mapping.html`, matching the Windows keyboard image style.

## Notes

- The layout emits Unicode Shan/Myanmar characters directly.
- Command, Control, and Option key combinations use QWERTY output so common shortcuts such as `Command-C`, `Command-V`, and `Command-Z` keep working.
- The pasted source mapping included invisible zero-width spaces before `ေ` and `ဵ`. This layout intentionally emits only `U+1031` and `U+1035` for those keys.
