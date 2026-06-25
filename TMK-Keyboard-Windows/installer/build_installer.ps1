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

$iexpress = Join-Path $env:WINDIR 'System32\iexpress.exe'

function New-IExpressPackage {
    param(
        [string]$Name,
        [string]$Target,
        [string]$Command,
        [string]$FinishMessage,
        [hashtable]$Files
    )

    $stage = Join-Path $PSScriptRoot "$Name-payload"
    $sed = Join-Path $PSScriptRoot "$Name.sed"
    New-Item -ItemType Directory -Force -Path $stage | Out-Null

    $index = 0
    $sourceEntries = New-Object System.Collections.Generic.List[string]
    $stringEntries = New-Object System.Collections.Generic.List[string]
    foreach ($destinationName in ($Files.Keys | Sort-Object)) {
        Copy-Item -LiteralPath $Files[$destinationName] -Destination (Join-Path $stage $destinationName) -Force
        $sourceEntries.Add("%FILE$index%=")
        $stringEntries.Add("FILE$index=$destinationName")
        $index++
    }

    $sedContent = @"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=0
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=
DisplayLicense=
FinishMessage=$FinishMessage
TargetName=$Target
FriendlyName=TMK Keyboard $Name
AppLaunched=$Command
PostInstallCmd=<None>
AdminQuietInstCmd=$Command
UserQuietInstCmd=$Command
SourceFiles=SourceFiles
[SourceFiles]
SourceFiles0=$stage\
[SourceFiles0]
$($sourceEntries -join "`r`n")
[Strings]
$($stringEntries -join "`r`n")
"@
    Set-Content -LiteralPath $sed -Value $sedContent -Encoding ASCII
    Remove-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    $iexpressProcess = Start-Process -FilePath $iexpress -ArgumentList @('/N', '/Q', $sed) -Wait -PassThru
    if ($iexpressProcess.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $Target)) {
        throw "IExpress $Name build failed."
    }
    Remove-Item -LiteralPath $stage -Recurse -Force
    Remove-Item -LiteralPath $sed -Force
}

$setupExe = Join-Path $PSScriptRoot 'setup.exe'
New-IExpressPackage `
    -Name 'Setup' `
    -Target $setupExe `
    -Command 'setup.cmd' `
    -FinishMessage 'TMK Keyboard installation completed.' `
    -Files @{
        'install.ps1' = (Join-Path $PSScriptRoot 'install.ps1')
        'setup.cmd' = (Join-Path $PSScriptRoot 'setup.cmd')
        'TMKSHAN-amd64.dll' = (Join-Path $output 'amd64\TMKSHAN.dll')
        'TMKSHAN-i386.dll' = (Join-Path $output 'i386\TMKSHAN.dll')
        'TMKSHAN-wow64.dll' = (Join-Path $output 'wow64\TMKSHAN.dll')
    }

$uninstallExe = Join-Path $PSScriptRoot 'uninstall.exe'
New-IExpressPackage `
    -Name 'Uninstall' `
    -Target $uninstallExe `
    -Command 'uninstall.cmd' `
    -FinishMessage 'TMK Keyboard uninstall completed.' `
    -Files @{
        'uninstall.cmd' = (Join-Path $PSScriptRoot 'uninstall.cmd')
        'uninstall.ps1' = (Join-Path $PSScriptRoot 'uninstall.ps1')
    }

Write-Host "Keyboard binaries built in $output"
Write-Host "Setup executable built at $setupExe"
Write-Host "Uninstall executable built at $uninstallExe"
