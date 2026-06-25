@echo off
setlocal

set "POWERSHELL=%windir%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%windir%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "POWERSHELL=%windir%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"

net session >nul 2>&1
if errorlevel 1 (
    "%POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

"%POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
if errorlevel 1 (
    echo.
    echo TMK Keyboard installation failed.
    pause
    exit /b 1
)

echo.
echo TMK Keyboard installation completed.
timeout /t 5 >nul
