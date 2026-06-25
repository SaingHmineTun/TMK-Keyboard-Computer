# TMK Keyboard macOS Installer

This folder contains the generated macOS installer package, branded Installer.app resources, and the script used to rebuild it.

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

The script also creates a sharing archive:

```text
TMK-Keyboard-Mac/installer/TMK Keyboard Installer.zip
```

The package uses `resources/tmk-keyboard-installer.png` for the Installer.app welcome screen and attempts to attach the same image as the Finder icon for the `.pkg`. The Finder icon is stored as macOS file metadata, so share the generated `.zip` when you want users to see the custom `.pkg` icon after downloading.

This package is not signed or notarized. For public distribution outside your own Mac, sign and notarize the package with an Apple Developer account.
