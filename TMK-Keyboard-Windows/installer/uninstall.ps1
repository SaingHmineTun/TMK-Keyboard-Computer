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

Assert-Administrator

Add-Type @'
using System.Runtime.InteropServices;
public static class KeyboardLayoutUninstaller {
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern bool InstallLayoutOrTip(string layout, uint flags);
}
'@
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
Set-WinUserLanguageList $languages -Force

Remove-Item -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\$layoutId" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $nativeSystemDirectory $layoutFile) -Force -ErrorAction SilentlyContinue
if ($is64BitOs) {
    Remove-Item -LiteralPath (Join-Path $env:WINDIR "SysWOW64\$layoutFile") -Force -ErrorAction SilentlyContinue
}

Write-Host 'TMK Keyboard was uninstalled successfully.'
