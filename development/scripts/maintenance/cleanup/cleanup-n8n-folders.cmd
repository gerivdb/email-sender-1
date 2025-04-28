@echo off
cd /d "%~dp0"

echo Nettoyage final des dossiers n8n...
echo.

echo Vérification du contenu des dossiers...
if not exist "n8n" (
    echo ERREUR: Le dossier n8n n'existe pas!
    pause
    exit /b 1
)

echo.
echo Suppression des dossiers redondants...

if exist "n8n-final" (
    echo Suppression de n8n-final...
    rmdir /s /q "n8n-final"
)

if exist "n8n-source" (
    echo Suppression de n8n-source...
    rmdir /s /q "n8n-source"
)

if exist "n8n-source-old" (
    echo Suppression de n8n-source-old...
    rmdir /s /q "n8n-source-old"
)

echo.
echo Vérification finale...
if exist "n8n-final" echo AVERTISSEMENT: n8n-final existe toujours!
if exist "n8n-source" echo AVERTISSEMENT: n8n-source existe toujours!
if exist "n8n-source-old" echo AVERTISSEMENT: n8n-source-old existe toujours!

echo.
echo Nettoyage terminé.
echo Il ne devrait plus y avoir qu'un seul dossier n8n.
echo.
echo Ce fichier sera automatiquement déplacé dans le dossier scripts\cleanup.
echo.
pause

move "%~f0" "scripts\cleanup\cleanup-n8n-folders.cmd" >nul 2>&1
