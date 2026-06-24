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
- `installer/README.md` - where to place the MKLC-generated setup package.

## Layout

The keyboard has exactly two typing layers:

- Normal
- Shift

## Build

Follow [BUILD.md](BUILD.md) on a Windows machine with Microsoft Keyboard Layout Creator.

The actual `setup.exe` and installer package must be generated on Windows with MKLC. This repository was prepared on macOS, where the Microsoft keyboard compiler and setup package generator are not available.

## Compatibility

- Windows 10
- Windows 11
- Unicode-aware Windows applications including Notepad, Word, Chrome, VS Code, and other standard desktop apps

## Version

Current keyboard source version: `1.0`.
