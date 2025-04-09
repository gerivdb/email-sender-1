@echo off
echo Démarrage de la Phase 6 (via batch)...
echo.

if not exist "scripts\maintenance\phase6" (
    echo Création du répertoire scripts\maintenance\phase6...
    mkdir "scripts\maintenance\phase6"
)

echo Exécution du script PowerShell...
powershell -ExecutionPolicy Bypass -File "scripts\maintenance\phase6\Implement-Phase6-Simple.ps1"

echo.
echo Fin du script.
pause
