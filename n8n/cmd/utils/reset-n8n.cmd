@echo off
cd /d "%~dp0\..\..\"

echo Réinitialisation de n8n...
echo Cette opération va supprimer toutes les données de n8n.
echo Assurez-vous d'avoir sauvegardé vos workflows avant de continuer.
echo.

set /p confirm=Êtes-vous sûr de vouloir réinitialiser n8n ? (O/N) : 

if /i "%confirm%" neq "O" (
    echo Opération annulée.
    exit /b
)

echo.
echo Arrêt de n8n...
call "%~dp0\..\stop\stop-n8n.cmd"

echo.
echo Suppression des données...
powershell -ExecutionPolicy Bypass -Command "Remove-Item -Path 'data\database\*' -Force -Recurse"

echo.
echo Réinitialisation terminée.
echo Pour redémarrer n8n, exécutez: .\cmd\start\start-n8n-local.cmd
