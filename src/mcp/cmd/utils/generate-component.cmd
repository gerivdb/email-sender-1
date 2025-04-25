@echo off
setlocal

echo ===================================
echo Generation de composants MCP
echo ===================================
echo.

set SCRIPT_PATH=%~dp0..\..\scripts\utils\Generate-MCPComponent.ps1

echo Options disponibles:
echo 1. Generer un script serveur MCP
echo 2. Generer un script client MCP
echo 3. Generer un module MCP
echo 4. Generer une documentation MCP
echo Q. Quitter
echo.

set /p choice="Votre choix (1-4, Q): "

if "%choice%"=="1" (
    echo.
    echo Generation d'un script serveur MCP...
    set /p name="Nom du script (sans extension): "
    set /p description="Description: "
    set /p author="Auteur (laisser vide pour 'MCP Team'): "
    
    echo.
    echo Generation du script serveur...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -Type server -Name "%name%" -Description "%description%" -Author "%author%"
) else if "%choice%"=="2" (
    echo.
    echo Generation d'un script client MCP...
    set /p name="Nom du script (sans extension): "
    set /p description="Description: "
    set /p author="Auteur (laisser vide pour 'MCP Team'): "
    
    echo.
    echo Generation du script client...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -Type client -Name "%name%" -Description "%description%" -Author "%author%"
) else if "%choice%"=="3" (
    echo.
    echo Generation d'un module MCP...
    set /p name="Nom du module (sans extension): "
    set /p description="Description: "
    set /p author="Auteur (laisser vide pour 'MCP Team'): "
    
    echo.
    echo Generation du module...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -Type module -Name "%name%" -Description "%description%" -Author "%author%"
) else if "%choice%"=="4" (
    echo.
    echo Generation d'une documentation MCP...
    set /p name="Nom du document (sans extension): "
    set /p category="Categorie (architecture, api, guides, etc.): "
    set /p description="Description: "
    set /p author="Auteur (laisser vide pour 'MCP Team'): "
    
    echo.
    echo Generation de la documentation...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -Type doc -Name "%name%" -Category "%category%" -Description "%description%" -Author "%author%"
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
