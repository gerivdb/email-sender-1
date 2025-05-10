@echo off
REM RunRelationsTest.bat - Script pour exécuter les tests d'analyse des relations contextuelles
REM Version: 1.0
REM Date: 2025-05-15

echo ===== TEST D'ANALYSE DES RELATIONS CONTEXTUELLES =====
echo.

REM Vérifier si PowerShell est disponible
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERREUR] PowerShell n'est pas disponible. Veuillez l'installer.
    goto :EOF
)

REM Exécuter le script PowerShell
echo [INFO] Exécution du test d'analyse des relations contextuelles...
echo.

powershell -ExecutionPolicy Bypass -Command ".\Invoke-HierarchyTests.ps1 -TestType Relations -GenerateReport"

echo.
if %ERRORLEVEL% equ 0 (
    echo [SUCCÈS] Test terminé avec succès.
) else (
    echo [ERREUR] Erreur lors de l'exécution du test.
)

echo.
echo Appuyez sur une touche pour quitter...
pause >nul
