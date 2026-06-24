# TMK Keyboard for Linux

TMK Keyboard for Linux provides Shan Unicode input using the same Normal and Shift mapping as the Windows and macOS projects.

## Recommended Option: IBus m17n

Use `m17n/shn-tmk.mim` when you need the exact TMK mapping. This input method supports all keys, including the three Shift-layer outputs that contain two Unicode codepoints:

- Shift+F: `U+1082 U+103A`
- Shift+K: `U+102D U+102F`
- Shift+L: `U+102D U+1030`

### Requirements

Install IBus, the IBus m17n engine, and the m17n database package for your distribution.

Common package names:

```sh
sudo apt install ibus ibus-m17n m17n-db
sudo dnf install ibus ibus-m17n m17n-db
sudo pacman -S ibus ibus-m17n m17n-db
```

### Install

Run these commands from the repository root:

```sh
sudo install -m 0644 "TMK-Keyboard-Linux/m17n/shn-tmk.mim" /usr/share/m17n/shn-tmk.mim
ibus restart
```

Sign out and sign back in if the input method does not appear immediately.

Then open your desktop input settings, add an IBus/m17n input method, and choose **TMK** under Shan or Myanmar, depending on the desktop environment.

## Optional Native XKB Layout

The native XKB symbols file lives at `xkb/symbols/tmk`.

This is useful if you want a system keyboard layout that can be selected with `setxkbmap` or desktop keyboard settings. Plain XKB layouts can only emit one keysym per key press, so this file cannot exactly represent the three two-codepoint Shift-layer outputs listed above. For exact typing, use the IBus m17n file.

### Test On X11

```sh
sudo install -m 0644 "TMK-Keyboard-Linux/xkb/symbols/tmk" /usr/share/X11/xkb/symbols/tmk
setxkbmap tmk
```

Restore a US layout with:

```sh
setxkbmap us
```

### Desktop Integration

To make the XKB layout appear in graphical keyboard settings, add a layout entry to `/usr/share/X11/xkb/rules/evdev.xml` after installing `xkb/symbols/tmk`.

```xml
<layout>
  <configItem>
    <name>tmk</name>
    <shortDescription>tmk</shortDescription>
    <description>Shan (TMK Keyboard)</description>
    <languageList>
      <iso639Id>shn</iso639Id>
    </languageList>
  </configItem>
  <variantList/>
</layout>
```

Restart the desktop session after editing XKB rules.

## Files

- `m17n/shn-tmk.mim` - exact IBus m17n input method.
- `xkb/symbols/tmk` - native XKB symbols layout with documented sequence limitations.
- `docs/key-mapping.md` - Normal and Shift key mapping.
- `docs/tmk-keyboard-map.png` - visual keyboard map.

## Notes

- The layout assumes a US/QWERTY physical keyboard.
- The m17n input method maps shifted punctuation from a US base layout, for example `!` for Shift+1, `_` for Shift+Minus, `+` for Shift+Equal, and `{` for Shift+Left Bracket.
- The layout emits Unicode Shan/Myanmar characters directly.
