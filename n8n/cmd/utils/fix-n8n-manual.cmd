@echo off
cd /d "%~dp0"

echo Correction manuelle des dossiers n8n...
echo.

echo Étape 1: Arrêt des processus qui pourraient bloquer les dossiers...
taskkill /F /IM node.exe 2>nul
taskkill /F /IM powershell.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo Étape 2: Création des dossiers temporaires...
if exist "n8n-source" rmdir /s /q "n8n-source"
if exist "n8n-final" rmdir /s /q "n8n-final"
mkdir "n8n-source"
mkdir "n8n-final"
timeout /t 1 /nobreak >nul

echo.
echo Étape 3: Copie des fichiers...
echo Copie de n8n vers n8n-source...
xcopy "n8n\*" "n8n-source\" /E /H /C /I /Y
echo Copie de n8n-new vers n8n-final...
xcopy "n8n-new\*" "n8n-final\" /E /H /C /I /Y
timeout /t 1 /nobreak >nul

echo.
echo Étape 4: Suppression des dossiers originaux...
rmdir /s /q "n8n"
rmdir /s /q "n8n-new"
timeout /t 1 /nobreak >nul

echo.
echo Étape 5: Renommage du dossier final...
ren "n8n-final" "n8n"

echo.
echo Opération terminée avec succès.
echo Le dossier n8n contient maintenant la nouvelle structure organisée.
echo Le dossier n8n-source contient le code source original de n8n.
echo.
echo Ce fichier sera automatiquement déplacé dans le dossier scripts\cleanup.
echo.
pause

move "%~f0" "scripts\cleanup\fix-n8n-manual.cmd" >nul 2>&1
