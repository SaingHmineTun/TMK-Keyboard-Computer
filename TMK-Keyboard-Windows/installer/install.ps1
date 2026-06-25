[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$layoutId = 'A0000409'
$layoutFile = 'TMKSHAN.dll'
$layoutText = 'Shan (TMK)'
$languageTag = 'en-US'
$inputMethodTip = "0409:$layoutId"
$packageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Assert-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Administrator privileges are required.'
    }
}

Write-Output '[TMK_PROGRESS]5|Checking administrator permission.'
Assert-Administrator

$is64BitOs = [Environment]::Is64BitOperatingSystem
$nativeSystemDirectory = if ($is64BitOs -and -not [Environment]::Is64BitProcess) {
    Join-Path $env:WINDIR 'Sysnative'
} else {
    Join-Path $env:WINDIR 'System32'
}
$nativeDll = if ($is64BitOs) {
    Join-Path $packageRoot 'amd64\TMKSHAN.dll'
} else {
    Join-Path $packageRoot 'i386\TMKSHAN.dll'
}
if (-not (Test-Path -LiteralPath $nativeDll)) {
    $nativeDll = if ($is64BitOs) {
        Join-Path $packageRoot 'TMKSHAN-amd64.dll'
    } else {
        Join-Path $packageRoot 'TMKSHAN-i386.dll'
    }
}

if (-not (Test-Path -LiteralPath $nativeDll)) {
    throw "Keyboard DLL not found: $nativeDll"
}

Write-Output '[TMK_PROGRESS]25|Copying the native keyboard files.'
Copy-Item -LiteralPath $nativeDll -Destination (Join-Path $nativeSystemDirectory $layoutFile) -Force

if ($is64BitOs) {
    $wow64Dll = Join-Path $packageRoot 'wow64\TMKSHAN.dll'
    if (-not (Test-Path -LiteralPath $wow64Dll)) {
        $wow64Dll = Join-Path $packageRoot 'TMKSHAN-wow64.dll'
    }
    if (-not (Test-Path -LiteralPath $wow64Dll)) {
        throw "WOW64 keyboard DLL not found: $wow64Dll"
    }
    Copy-Item -LiteralPath $wow64Dll -Destination (Join-Path $env:WINDIR "SysWOW64\$layoutFile") -Force
}

Write-Output '[TMK_PROGRESS]55|Registering Shan (TMK) with Windows.'
$layoutKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\$layoutId"
New-Item -Path $layoutKey -Force | Out-Null
New-ItemProperty -Path $layoutKey -Name 'Layout File' -Value $layoutFile -PropertyType String -Force | Out-Null
New-ItemProperty -Path $layoutKey -Name 'Layout Text' -Value $layoutText -PropertyType String -Force | Out-Null
New-ItemProperty -Path $layoutKey -Name 'Layout Display Name' -Value $layoutText -PropertyType String -Force | Out-Null
New-ItemProperty -Path $layoutKey -Name 'Layout Id' -Value '0A5B' -PropertyType String -Force | Out-Null

Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class KeyboardLayoutInstaller {
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
Write-Output '[TMK_PROGRESS]75|Enabling the English - Shan (TMK) input profile.'
if (-not [KeyboardLayoutInstaller]::InstallLayoutOrTip($inputMethodTip, 0)) {
    throw "Windows rejected input profile $inputMethodTip."
}

$languages = Get-WinUserLanguageList
$language = $languages | Where-Object LanguageTag -eq $languageTag | Select-Object -First 1
if (-not $language) {
    $languages.Add($languageTag)
    $language = $languages | Where-Object LanguageTag -eq $languageTag | Select-Object -First 1
}
if ($language -and -not $language.InputMethodTips.Contains($inputMethodTip)) {
    $language.InputMethodTips.Add($inputMethodTip)
}
Write-Output '[TMK_PROGRESS]90|Updating the current Windows language profile.'
Set-WinUserLanguageList $languages -Force

Write-Output '[TMK_PROGRESS]100|TMK Keyboard Pro is installed and ready.'
Write-Host "TMK Keyboard was installed successfully as English - $layoutText."
Write-Host 'Use Win + Space to select it. Sign out and back in if it does not appear immediately.'
