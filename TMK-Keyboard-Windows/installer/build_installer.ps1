[CmdletBinding()]
param(
    [string]$MsklcRoot,
    [string]$WixRoot
)

$ErrorActionPreference = 'Stop'

if (-not $MsklcRoot) {
    $MsklcRoot = Join-Path $PSScriptRoot '..\..\tools\MSKLC-portable'
}
if (-not $WixRoot) {
    $WixRoot = Join-Path $PSScriptRoot '..\..\tools\wix314'
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$source = Join-Path $projectRoot 'TMK Keyboard.klc'
$output = Join-Path $PSScriptRoot 'TMK-Keyboard-1.0'
$kbdTool = Join-Path $MsklcRoot 'bin\i386\kbdutool.exe'
$toolBin = Join-Path $MsklcRoot 'bin\i386'

if (-not (Test-Path -LiteralPath $kbdTool)) {
    throw "MSKLC compiler not found: $kbdTool"
}

if (Test-Path -LiteralPath $output) {
    $resolvedOutput = (Resolve-Path -LiteralPath $output).Path
    if ((Split-Path -Parent $resolvedOutput) -ne $PSScriptRoot -or (Split-Path -Leaf $resolvedOutput) -ne 'TMK-Keyboard-1.0') {
        throw "Refusing to clear unexpected output directory: $resolvedOutput"
    }
    Remove-Item -LiteralPath $resolvedOutput -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $output | Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $output 'TMKSHAN.klc') -Force

$oldPath = $env:PATH
$oldInclude = $env:INCLUDE
$oldLib = $env:LIB
$env:PATH = "$toolBin;$toolBin\amd64;$oldPath"
$env:INCLUDE = Join-Path $MsklcRoot 'inc'

try {
    Push-Location $output
    foreach ($arch in @('i386', 'amd64', 'wow64')) {
        New-Item -ItemType Directory -Force -Path $arch | Out-Null
    }

    $env:LIB = Join-Path $MsklcRoot 'lib\i386'
    & $kbdTool -n -a -x TMKSHAN.klc
    if ($LASTEXITCODE) { throw 'x86 keyboard compilation failed.' }
    Copy-Item TMKSHAN.dll i386\TMKSHAN.dll -Force

    $env:LIB = Join-Path $MsklcRoot 'lib\amd64'
    & $kbdTool -n -a -m TMKSHAN.klc
    if ($LASTEXITCODE) { throw 'x64 keyboard compilation failed.' }
    Copy-Item TMKSHAN.dll amd64\TMKSHAN.dll -Force

    $env:LIB = Join-Path $MsklcRoot 'lib\i386'
    & $kbdTool -n -a -o TMKSHAN.klc
    if ($LASTEXITCODE) { throw 'WOW64 keyboard compilation failed.' }
    Copy-Item TMKSHAN.dll wow64\TMKSHAN.dll -Force
    Remove-Item TMKSHAN.dll -Force
    Pop-Location
} finally {
    $env:PATH = $oldPath
    $env:INCLUDE = $oldInclude
    $env:LIB = $oldLib
}

$cscCandidates = @(
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'),
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe')
)
$csc = $cscCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $csc) {
    throw 'The Windows .NET Framework C# compiler was not found.'
}

$guiSource = Join-Path $PSScriptRoot 'InstallerGui.cs'
$guiManifest = Join-Path $PSScriptRoot 'InstallerGui.manifest'
$guiIcon = Join-Path $PSScriptRoot 'assets\tmk-keyboard-icon.ico'
$guiImage = Join-Path $PSScriptRoot 'assets\tmk-keyboard-icon.png'

function Build-GuiExecutable {
    param(
        [string]$Target,
        [string]$Define,
        [string[]]$Resources
    )

    $arguments = @(
        '/nologo',
        '/target:winexe',
        '/platform:anycpu',
        '/optimize+',
        '/reference:System.dll',
        '/reference:System.Drawing.dll',
        '/reference:System.Windows.Forms.dll',
        "/win32icon:$guiIcon",
        "/win32manifest:$guiManifest"
    )
    if ($Define) {
        $arguments += "/define:$Define"
    }
    foreach ($resource in $Resources) {
        $arguments += "/resource:$resource"
    }
    $arguments += "/out:$Target"
    $arguments += $guiSource

    Remove-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    & $csc @arguments
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Target)) {
        throw "The responsive installer GUI failed to compile: $Target"
    }
}

$candle = Join-Path $WixRoot 'candle.exe'
$light = Join-Path $WixRoot 'light.exe'
if ((Test-Path -LiteralPath $candle) -and (Test-Path -LiteralPath $light)) {
    $wixObject = Join-Path $PSScriptRoot 'Product.wixobj'
    $msi = Join-Path $PSScriptRoot 'TMK-Keyboard-1.0-x64.msi'
    Push-Location $PSScriptRoot
    try {
        & $candle -nologo -arch x64 -out $wixObject (Join-Path $PSScriptRoot 'Product.wxs')
        if ($LASTEXITCODE) { throw 'WiX compilation failed.' }
        & $light -nologo -out $msi $wixObject
        if ($LASTEXITCODE) { throw 'MSI linking failed.' }
    } finally {
        Pop-Location
    }
}

$setupExe = Join-Path $PSScriptRoot 'setup.exe'
Build-GuiExecutable `
    -Target $setupExe `
    -Resources @(
        "$guiImage,TMK.Icon",
        "$(Join-Path $PSScriptRoot 'install.ps1'),TMK.InstallScript",
        "$(Join-Path $output 'amd64\TMKSHAN.dll'),TMK.NativeAmd64",
        "$(Join-Path $output 'i386\TMKSHAN.dll'),TMK.NativeI386",
        "$(Join-Path $output 'wow64\TMKSHAN.dll'),TMK.Wow64"
    )

$uninstallExe = Join-Path $PSScriptRoot 'uninstall.exe'
Build-GuiExecutable `
    -Target $uninstallExe `
    -Define 'UNINSTALLER' `
    -Resources @(
        "$guiImage,TMK.Icon",
        "$(Join-Path $PSScriptRoot 'uninstall.ps1'),TMK.UninstallScript"
    )

Write-Host "Keyboard binaries built in $output"
Write-Host "Setup executable built at $setupExe"
Write-Host "Uninstall executable built at $uninstallExe"
