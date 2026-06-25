[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$layoutId = 'A0000409'
$layoutFile = 'TMKSHAN.dll'
$inputMethodTip = "0409:$layoutId"

function Assert-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Administrator privileges are required.'
    }
}

Write-Output '[TMK_PROGRESS]5|Checking administrator permission.'
Assert-Administrator

Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class KeyboardLayoutUninstaller {
    [UnmanagedFunctionPointer(CallingConvention.Winapi, CharSet = CharSet.Unicode)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private delegate bool InstallLayoutOrTipDelegate(
        [MarshalAs(UnmanagedType.LPWStr)] string layout,
        uint flags);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr LoadLibraryEx(
        string fileName,
        IntPtr file,
        uint flags);

    [DllImport("kernel32.dll", CharSet = CharSet.Ansi, SetLastError = true)]
    private static extern IntPtr GetProcAddress(
        IntPtr module,
        string procedureName);

    [DllImport("kernel32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool FreeLibrary(IntPtr module);

    public static bool InstallLayoutOrTip(string layout, uint flags) {
        const uint LOAD_LIBRARY_SEARCH_SYSTEM32 = 0x00000800;
        IntPtr module = LoadLibraryEx("input.dll", IntPtr.Zero, LOAD_LIBRARY_SEARCH_SYSTEM32);
        if (module == IntPtr.Zero) {
            throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error(), "Unable to load input.dll.");
        }

        try {
            IntPtr address = GetProcAddress(module, "InstallLayoutOrTip");
            if (address == IntPtr.Zero) {
                throw new EntryPointNotFoundException("InstallLayoutOrTip was not found in input.dll.");
            }

            InstallLayoutOrTipDelegate function =
                (InstallLayoutOrTipDelegate)Marshal.GetDelegateForFunctionPointer(
                    address,
                    typeof(InstallLayoutOrTipDelegate));
            return function(layout, flags);
        } finally {
            FreeLibrary(module);
        }
    }
}
'@
Write-Output '[TMK_PROGRESS]25|Removing the English - Shan (TMK) input profile.'
[void][KeyboardLayoutUninstaller]::InstallLayoutOrTip($inputMethodTip, 1)

$is64BitOs = [Environment]::Is64BitOperatingSystem
$nativeSystemDirectory = if ($is64BitOs -and -not [Environment]::Is64BitProcess) {
    Join-Path $env:WINDIR 'Sysnative'
} else {
    Join-Path $env:WINDIR 'System32'
}

$languages = Get-WinUserLanguageList
foreach ($language in $languages) {
    if ($language.InputMethodTips.Contains($inputMethodTip)) {
        $language.InputMethodTips.Remove($inputMethodTip)
    }
}
Write-Output '[TMK_PROGRESS]55|Updating the current Windows language profile.'
Set-WinUserLanguageList $languages -Force

Write-Output '[TMK_PROGRESS]75|Removing the keyboard registration and files.'
Remove-Item -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\$layoutId" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $nativeSystemDirectory $layoutFile) -Force -ErrorAction SilentlyContinue
if ($is64BitOs) {
    Remove-Item -LiteralPath (Join-Path $env:WINDIR "SysWOW64\$layoutFile") -Force -ErrorAction SilentlyContinue
}

Write-Output '[TMK_PROGRESS]100|TMK Keyboard Pro was removed.'
Write-Host 'TMK Keyboard was uninstalled successfully.'
