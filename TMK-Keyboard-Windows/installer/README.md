# Installer Package

Run `setup.exe` and approve the Windows administrator prompt. The branded installer remains responsive and shows progress while Windows is updated. Use `uninstall.exe` to remove the keyboard through the same interface.

The installer:

- copies the x64 keyboard DLL to System32;
- copies the x86 keyboard DLL to SysWOW64;
- registers **Shan (TMK)** as layout `A0000409`;
- adds it to the current user's English input methods for reliable Win+Space switching.

Use `build_installer.ps1` from the repository root to rebuild the DLLs and setup executable.
