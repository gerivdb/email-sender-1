@echo off
cd /d "%~dp0"

echo ===================================================
echo Restauration des workflows n8n
echo ===================================================

set BACKUP_DIR=..\backups

if not exist %BACKUP_DIR% (
    echo Le répertoire de sauvegarde n'existe pas.
    exit /b 1
)

echo Sauvegardes disponibles:
echo.

set /a counter=0
for %%f in (%BACKUP_DIR%\n8n_backup_*.zip) do (
    set /a counter+=1
    echo !counter!. %%~nxf
)

if %counter% equ 0 (
    echo Aucune sauvegarde trouvée.
    exit /b 1
)

echo.
set /p choice=Entrez le numéro de la sauvegarde à restaurer (ou 'q' pour quitter): 

if "%choice%"=="q" exit /b 0

set /a counter=0
for %%f in (%BACKUP_DIR%\n8n_backup_*.zip) do (
    set /a counter+=1
    if !counter! equ %choice% (
        set BACKUP_FILE=%%f
        goto :restore
    )
)

echo Choix invalide.
exit /b 1

:restore
echo.
echo Vous êtes sur le point de restaurer la sauvegarde: %BACKUP_FILE%
echo ATTENTION: Cette opération écrasera les données actuelles.
set /p confirm=Êtes-vous sûr de vouloir continuer? (o/n): 

if /i not "%confirm%"=="o" exit /b 0

echo.
echo Arrêt de n8n...
call stop-n8n-docker.cmd

echo.
echo Restauration des données...
powershell -Command "Expand-Archive -Path '%BACKUP_FILE%' -DestinationPath '..\data' -Force"

if %errorlevel% equ 0 (
    echo Restauration terminée avec succès.
    echo Redémarrage de n8n...
    call start-n8n-docker.cmd
) else (
    echo Erreur lors de la restauration.
)

echo ===================================================
