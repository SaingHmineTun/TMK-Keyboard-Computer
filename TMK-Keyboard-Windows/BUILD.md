# Build Instructions

These steps must be performed on Windows because Microsoft Keyboard Layout Creator generates the keyboard DLLs.

## Requirements

- Windows 10 or Windows 11
- Microsoft Keyboard Layout Creator 1.4 extracted to `tools/MSKLC-portable`
- Administrator access for installation testing

## Build

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\TMK-Keyboard-Windows\installer\build_installer.ps1
```

The script compiles x86, x64, and WOW64 keyboard DLLs, then creates:

- `installer/setup.exe`
- `installer/uninstall.exe`
- `installer/TMK-Keyboard-1.0/i386/TMKSHAN.dll`
- `installer/TMK-Keyboard-1.0/amd64/TMKSHAN.dll`
- `installer/TMK-Keyboard-1.0/wow64/TMKSHAN.dll`

If WiX 3.14 portable binaries are available in `tools/wix314`, the script also builds `installer/TMK-Keyboard-1.0-x64.msi`.

## Install Test

1. Run `installer/setup.exe`.
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
- `installer/uninstall.exe` exists.
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
