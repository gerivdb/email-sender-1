@echo off
setlocal enabledelayedexpansion

echo ===================================
echo Installation du node Augment Client
echo ===================================

:: Vérifier si npm est installé
where npm >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Erreur: npm n'est pas installé ou n'est pas dans le PATH.
    echo Veuillez installer Node.js et npm avant de continuer.
    exit /b 1
)

:: Vérifier si n8n est installé
where n8n >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Erreur: n8n n'est pas installé ou n'est pas dans le PATH.
    echo Veuillez installer n8n avant de continuer.
    exit /b 1
)

:: Obtenir le chemin du répertoire courant
set CURRENT_DIR=%~dp0
cd %CURRENT_DIR%

:: Installer les dépendances
echo Installation des dépendances...
call npm install
if %ERRORLEVEL% neq 0 (
    echo Erreur lors de l'installation des dépendances.
    exit /b 1
)

:: Compiler le code TypeScript
echo Compilation du code TypeScript...
call npx tsc
if %ERRORLEVEL% neq 0 (
    echo Erreur lors de la compilation du code TypeScript.
    exit /b 1
)

:: Créer le répertoire dist/nodes si nécessaire
if not exist "dist\nodes" mkdir dist\nodes
if not exist "dist\credentials" mkdir dist\credentials

:: Copier l'icône SVG
echo Copie de l'icône SVG...
copy augment.svg dist\nodes\augment.svg

:: Obtenir le répertoire des custom nodes de n8n
for /f "tokens=*" %%a in ('n8n --help ^| findstr "custom"') do (
    set HELP_TEXT=%%a
)

set N8N_CUSTOM_PATH=
for /f "tokens=*" %%a in ("!HELP_TEXT!") do (
    set LINE=%%a
    set LINE=!LINE:*custom-extensions-path=!
    if "!LINE!" neq "!HELP_TEXT!" (
        for /f "tokens=1 delims= " %%b in ("!LINE!") do (
            set N8N_CUSTOM_PATH=%%b
        )
    )
)

if "!N8N_CUSTOM_PATH!" == "" (
    :: Chemin par défaut si non trouvé
    set N8N_CUSTOM_PATH=%APPDATA%\n8n\custom
)

:: Créer le répertoire des custom nodes si nécessaire
if not exist "!N8N_CUSTOM_PATH!" mkdir "!N8N_CUSTOM_PATH!"

:: Créer le répertoire pour le node
set NODE_PATH=!N8N_CUSTOM_PATH!\nodes\n8n-nodes-augment-client
if not exist "!NODE_PATH!" mkdir "!NODE_PATH!"

:: Copier les fichiers
echo Copie des fichiers vers !NODE_PATH!...
xcopy /E /Y dist "!NODE_PATH!\dist\"
copy /Y package.json "!NODE_PATH!\"
copy /Y index.js "!NODE_PATH!\"

:: Installer le module AugmentIntegration
echo Installation du module AugmentIntegration...
powershell -ExecutionPolicy Bypass -File "%CURRENT_DIR%install-augment-integration.ps1"
if %ERRORLEVEL% neq 0 (
    echo Avertissement: L'installation du module AugmentIntegration a échoué.
    echo Vous devrez peut-être l'installer manuellement.
)

echo.
echo Installation terminée avec succès!
echo.
echo Pour utiliser le node Augment Client:
echo 1. Redémarrez n8n
echo 2. Recherchez "Augment Client" dans la liste des nodes
echo 3. Configurez les credentials si nécessaire
echo.
echo Exemples de workflows disponibles dans:
echo src/n8n/workflows/examples/
echo.

endlocal
