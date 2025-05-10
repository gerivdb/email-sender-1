@echo off
REM RunTests.bat - Script pour exécuter la suite complète de tests du système RAG de roadmaps
REM Version: 1.0
REM Date: 2025-05-15

echo ===== SYSTÈME RAG DE ROADMAPS - EXÉCUTION DES TESTS =====
echo.

REM Vérifier si PowerShell est disponible
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERREUR] PowerShell n'est pas disponible. Veuillez l'installer.
    goto :EOF
)

REM Exécuter le script PowerShell avec les paramètres par défaut
echo [INFO] Exécution de la suite complète de tests...
echo [INFO] Cela peut prendre quelques minutes...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0Run-CompleteTestSuite.ps1" -Force

echo.
if %ERRORLEVEL% equ 0 (
    echo [SUCCÈS] Tests terminés avec succès.
) else (
    echo [ERREUR] Erreur lors de l'exécution des tests.
)

echo.
echo Appuyez sur une touche pour quitter...
pause >nul
