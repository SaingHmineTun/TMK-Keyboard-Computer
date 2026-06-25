# TMK Keyboard for Windows

TMK Keyboard for Windows is a native MKLC keyboard layout for typing Shan Unicode text.

After installation, the layout appears as **TMK Keyboard** in Windows language and keyboard settings and can be selected with `Win + Space`.

## Files

- `TMK Keyboard.klc` - MKLC source project.
- `BUILD.md` - Windows build and packaging instructions.
- `docs/key-mapping.md` - Normal and Shift key mapping.
- `docs/tmk-keyboard-map.png` - visual keyboard map.
- `docs/tmk-keyboard-map.html` - source used to render the keyboard map.
- `docs/fonts/shan_regular.ttf` - Shan font used for the keyboard map artwork.
- `installer/setup.exe` - ready-to-run Windows installer.
- `installer/uninstall.exe` - Windows uninstaller.
- `installer/build_installer.ps1` - repeatable compiler and installer build.

## Layout

The keyboard has exactly two typing layers:

- Normal
- Shift

## Build

Run `installer/setup.exe` as the Windows user who will use the keyboard. Approve the administrator prompt when Windows displays it.

To rebuild the installer, follow [BUILD.md](BUILD.md).

## Compatibility

- Windows 10
- Windows 11
- Unicode-aware Windows applications including Notepad, Word, Chrome, VS Code, and other standard desktop apps

## Version

Current keyboard source version: `1.0`.
