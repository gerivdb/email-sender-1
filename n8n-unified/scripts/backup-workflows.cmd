@echo off
cd /d "%~dp0"

echo ===================================================
echo Sauvegarde des workflows n8n
echo ===================================================

set BACKUP_DIR=..\backups
set TIMESTAMP=%date:~6,4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BACKUP_FILE=%BACKUP_DIR%\n8n_backup_%TIMESTAMP%.zip

if not exist %BACKUP_DIR% mkdir %BACKUP_DIR%

echo Création de la sauvegarde dans %BACKUP_FILE%...

powershell -Command "Compress-Archive -Path '..\data\*' -DestinationPath '%BACKUP_FILE%' -Force"

if %errorlevel% equ 0 (
    echo Sauvegarde créée avec succès.
    echo Emplacement: %BACKUP_FILE%
) else (
    echo Erreur lors de la création de la sauvegarde.
)

echo ===================================================
