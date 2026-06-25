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

$layoutKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\$layoutId"
New-Item -Path $layoutKey -Force | Out-Null
New-ItemProperty -Path $layoutKey -Name 'Layout File' -Value $layoutFile -PropertyType String -Force | Out-Null
New-ItemProperty -Path $layoutKey -Name 'Layout Text' -Value $layoutText -PropertyType String -Force | Out-Null
New-ItemProperty -Path $layoutKey -Name 'Layout Display Name' -Value $layoutText -PropertyType String -Force | Out-Null
New-ItemProperty -Path $layoutKey -Name 'Layout Id' -Value '0A5B' -PropertyType String -Force | Out-Null

Add-Type @'
using System.Runtime.InteropServices;
public static class KeyboardLayoutInstaller {
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern bool InstallLayoutOrTip(string layout, uint flags);
}
'@
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
Set-WinUserLanguageList $languages -Force

Write-Host "TMK Keyboard was installed successfully as English - $layoutText."
Write-Host 'Use Win + Space to select it. Sign out and back in if it does not appear immediately.'
