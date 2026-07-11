@echo off

>nul 2>&1 net session
if %errorLevel% neq 0 (
    powershell -command Start-Process "%~f0" -Verb RunAs
    exit /b
)

start "" powershell.exe -ExecutionPolicy Bypass -File "C:\prep\NewWindowsScripts\configure.ps1"