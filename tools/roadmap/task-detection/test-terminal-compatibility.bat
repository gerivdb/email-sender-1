@echo off
REM Script batch pour tester la compatibilité multi-terminaux

setlocal enabledelayedexpansion

set "detailed="

REM Traitement des arguments
:parse_args
if "%~1"=="" goto execute
if /i "%~1"=="-verbose" (
    set "detailed=-DetailedOutput"
) else if /i "%~1"=="-help" (
    goto show_help
)
shift
goto parse_args

:show_help
echo Utilisation du script test-terminal-compatibility.bat:
echo   test-terminal-compatibility [options]
echo.
echo Options:
echo   -verbose                : Afficher des informations détaillées
echo   -help                   : Afficher cette aide
echo.
echo Exemples:
echo   test-terminal-compatibility           : Exécuter les tests de compatibilité
echo   test-terminal-compatibility -verbose  : Exécuter les tests avec des informations détaillées
goto end

:execute
powershell -ExecutionPolicy Bypass -File "%~dp0tests\Test-TerminalCompatibility.ps1" %detailed%

:end
endlocal
