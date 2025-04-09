@echo off
echo Démarrage de la Phase 6...
echo.

if not exist "scripts\maintenance\phase6" (
    echo Création du répertoire scripts\maintenance\phase6...
    mkdir "scripts\maintenance\phase6"
)

echo Vérification des scripts existants...
dir "scripts\maintenance\phase6\*.ps1"

echo.
echo Fin du script.
pause
