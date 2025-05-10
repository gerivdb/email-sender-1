@echo off
REM RunVersioningTests.bat - Script pour exécuter les tests de versionnage des embeddings
REM Version: 1.0
REM Date: 2025-05-15

echo ===== SYSTÈME RAG DE ROADMAPS - TESTS DE VERSIONNAGE DES EMBEDDINGS =====
echo.

REM Vérifier si PowerShell est disponible
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERREUR] PowerShell n'est pas disponible. Veuillez l'installer.
    goto :EOF
)

REM Exécuter le script PowerShell avec les paramètres spécifiques
echo [INFO] Exécution des tests de versionnage des embeddings...
echo [INFO] Cela peut prendre quelques minutes...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0Run-CompleteTestSuite.ps1" -TestType Versioning -Force

echo.
if %ERRORLEVEL% equ 0 (
    echo [SUCCÈS] Tests terminés avec succès.
) else (
    echo [ERREUR] Erreur lors de l'exécution des tests.
)

echo.
echo Appuyez sur une touche pour quitter...
pause >nul
