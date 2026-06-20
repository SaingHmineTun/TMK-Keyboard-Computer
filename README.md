# TMK Keyboard for Windows

TMK Keyboard is a native Windows keyboard layout for typing Shan Unicode text.
It is authored in Microsoft Keyboard Layout Creator (MKLC) project format and is intended to be distributed as the standard MKLC-generated Windows installer package.

After installation, the layout appears as **TMK Keyboard** in Windows language and keyboard settings and can be selected with `Win + Space`.

## Deliverables

- `TMK Keyboard.klc` - MKLC source project.
- `BUILD.md` - Windows build and packaging instructions.
- `docs/key-mapping.md` - Full normal, Shift, and AltGr mapping.
- `installer/README.md` - Where to place the MKLC-generated setup package.

The actual `setup.exe` and installer package must be generated on Windows with MKLC. This repository was prepared on macOS, where the Microsoft keyboard compiler and setup package generator are not available.

## Layout Summary

The keyboard has exactly three typing layers:

- Normal
- Shift
- AltGr / Right Alt

AltGr positions not assigned in the specification are left unmapped for future TMK expansion.

## Locale Note

The `.klc` uses the Windows Myanmar locale (`my-MM`, LCID `0455`) so MKLC can build a native Windows keyboard package for the Myanmar script family. The display name and language label are set to **TMK Keyboard** and **Shan**.

## Compatibility

- Windows 10
- Windows 11
- Unicode-aware Windows applications including Notepad, Word, Chrome, VS Code, and other standard desktop apps

## Version

Current keyboard source version: `1.0`.

## Uninstall

The MKLC-generated installer includes standard Windows uninstall support. After installation, remove it from:

`Settings > Apps > Installed apps` or `Control Panel > Programs and Features`.
