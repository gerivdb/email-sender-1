@echo off
setlocal

echo ===================================
echo Tests unitaires Hygen
echo ===================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0..\..\tests\Run-HygenTests.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Tests echoues!
    exit /b 1
) else (
    echo.
    echo Tests reussis!
    exit /b 0
)

endlocal
