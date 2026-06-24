# Build Instructions

These steps must be performed on Windows because Microsoft Keyboard Layout Creator generates the keyboard DLLs, MSI package, and `setup.exe`.

## Requirements

- Windows 10 or Windows 11
- Microsoft Keyboard Layout Creator 1.4
- Administrator access for installation testing

## Build

1. Open Microsoft Keyboard Layout Creator.
2. Select `File > Load Source File...`.
3. Open `TMK Keyboard.klc`.
4. Verify the project metadata:
   - Keyboard name: `TMKSHAN`
   - Display name: `TMK Keyboard`
   - Locale: `my-MM`
   - Version: `1.0`
5. Select `Project > Validate Layout`.
6. Select `Project > Test Keyboard Layout...` and type sample Shan text.
7. Select `Project > Build DLL and Setup Package`.
8. Copy the generated output folder into `installer/`.

MKLC normally creates architecture-specific keyboard DLLs, MSI files, and a `setup.exe` bootstrapper in the generated package folder.

## Install Test

1. Run the generated `setup.exe`.
2. Restart Windows or sign out and sign back in if Windows does not immediately show the layout.
3. Open `Settings > Time & language > Language & region`.
4. Add or open the Myanmar language entry if needed.
5. Confirm **TMK Keyboard** appears as an installed keyboard.
6. Press `Win + Space`.
7. Select **TMK Keyboard**.
8. Test typing in:
   - Notepad
   - Microsoft Word
   - Chrome
   - VS Code

## Packaging Checklist

- `installer/setup.exe` exists.
- Installer includes uninstall support.
- Installed keyboard display name is **TMK Keyboard**.
- Normal and Shift layers match `docs/key-mapping.md`.

## Important MKLC Check

Shift+F, Shift+K, and Shift+L output two-codepoint sequences through the `.klc` ligature table. If MKLC reports a ligature import warning, open those keys in MKLC and configure the ligatures manually as:

```text
Shift+F: 1082 103A
Shift+K: 102D 102F
Shift+L: 102D 1030
```

Then rebuild the DLL and setup package.
