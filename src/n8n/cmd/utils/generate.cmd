@echo off
setlocal

echo ===================================
echo Generateur de composants n8n
echo ===================================
echo.

echo Choisissez le type de composant a generer:
echo 1. Script d'automatisation
echo 2. Workflow n8n
echo 3. Documentation
echo 4. Integration
echo.

set /p choice="Votre choix (1-4): "

if "%choice%"=="1" (
    npx hygen n8n-script new
) else if "%choice%"=="2" (
    npx hygen n8n-workflow new
) else if "%choice%"=="3" (
    npx hygen n8n-doc new
) else if "%choice%"=="4" (
    npx hygen n8n-integration new
) else (
    echo Choix invalide.
    exit /b 1
)

echo.
echo Generation terminee.
echo.

endlocal
