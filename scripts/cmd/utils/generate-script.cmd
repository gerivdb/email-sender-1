@echo off
setlocal

echo ===================================
echo Generation de scripts
echo ===================================
echo.

set SCRIPT_PATH=%~dp0..\..\utils\Generate-Script.ps1

echo Options disponibles:
echo 1. Generer un script d'automatisation
echo 2. Generer un script d'analyse
echo 3. Generer un script de test
echo 4. Generer un script d'integration
echo Q. Quitter
echo.

set /p choice="Votre choix (1-4, Q): "

if "%choice%"=="1" (
    echo.
    echo Generation d'un script d'automatisation...
    set /p name="Nom du script (sans extension): "
    set /p description="Description: "
    set /p additional="Description additionnelle (optionnel): "
    set /p author="Auteur (laisser vide pour 'EMAIL_SENDER_1'): "
    set /p tags="Tags (separes par des virgules, optionnel): "
    
    echo.
    echo Generation du script d'automatisation...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -Type automation -Name "%name%" -Description "%description%" -AdditionalDescription "%additional%" -Author "%author%" -Tags "%tags%"
) else if "%choice%"=="2" (
    echo.
    echo Generation d'un script d'analyse...
    set /p name="Nom du script (sans extension): "
    set /p description="Description: "
    set /p additional="Description additionnelle (optionnel): "
    set /p subfolder="Sous-dossier (optionnel): "
    set /p author="Auteur (laisser vide pour 'EMAIL_SENDER_1'): "
    set /p tags="Tags (separes par des virgules, optionnel): "
    
    echo.
    echo Generation du script d'analyse...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -Type analysis -Name "%name%" -Description "%description%" -AdditionalDescription "%additional%" -SubFolder "%subfolder%" -Author "%author%" -Tags "%tags%"
) else if "%choice%"=="3" (
    echo.
    echo Generation d'un script de test...
    set /p name="Nom du script (sans extension et sans .Tests): "
    set /p description="Description: "
    set /p additional="Description additionnelle (optionnel): "
    set /p scripttotest="Chemin relatif du script a tester (ex: automation/Example-Script.ps1): "
    set /p functionname="Nom de la fonction principale a tester (sans le prefixe 'Start-'): "
    set /p author="Auteur (laisser vide pour 'EMAIL_SENDER_1'): "
    set /p tags="Tags (separes par des virgules, optionnel): "
    
    echo.
    echo Generation du script de test...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -Type test -Name "%name%" -Description "%description%" -AdditionalDescription "%additional%" -ScriptToTest "%scripttotest%" -FunctionName "%functionname%" -Author "%author%" -Tags "%tags%"
) else if "%choice%"=="4" (
    echo.
    echo Generation d'un script d'integration...
    set /p name="Nom du script (sans extension): "
    set /p description="Description: "
    set /p additional="Description additionnelle (optionnel): "
    set /p author="Auteur (laisser vide pour 'EMAIL_SENDER_1'): "
    set /p tags="Tags (separes par des virgules, optionnel): "
    
    echo.
    echo Generation du script d'integration...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -Type integration -Name "%name%" -Description "%description%" -AdditionalDescription "%additional%" -Author "%author%" -Tags "%tags%"
) else if /i "%choice%"=="Q" (
    echo.
    echo Operation annulee.
    exit /b 0
) else (
    echo.
    echo Choix invalide.
    exit /b 1
)

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Generation echouee!
    exit /b 1
) else (
    echo.
    echo Generation terminee.
    echo.
    echo Appuyez sur une touche pour continuer...
    pause > nul
    exit /b 0
)

endlocal
