# TMK Keyboard macOS Installer

This folder contains the generated macOS installer package and the script used to rebuild it.

## Use The Installer

Double-click `TMK Keyboard Installer.pkg` and follow the macOS Installer prompts.

The package installs `TMK Keyboard.bundle` into:

```text
/Library/Keyboard Layouts/TMK Keyboard.bundle
```

After installing, sign out and sign back in, or restart the Mac. Then open `System Settings > Keyboard > Text Input > Edit...`, press `+`, and add **TMK Keyboard**.

## Rebuild The Installer

Run this from the repository root:

```sh
sh "TMK-Keyboard-Mac/installer/build-macos-installer.sh"
```

The generated package is:

```text
TMK-Keyboard-Mac/installer/TMK Keyboard Installer.pkg
```

This package is not signed or notarized. For public distribution outside your own Mac, sign and notarize the package with an Apple Developer account.
