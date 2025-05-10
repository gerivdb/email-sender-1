@echo off
REM RunHierarchyTests.bat - Script pour exécuter les tests d'analyse de hiérarchie et de métadonnées
REM Version: 1.0
REM Date: 2025-05-15

echo ===== TESTS D'ANALYSE DE HIERARCHIE ET DE METADONNEES =====
echo.

REM Vérifier si PowerShell est disponible
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERREUR] PowerShell n'est pas disponible. Veuillez l'installer.
    goto :EOF
)

REM Récupérer les arguments
set TEST_TYPE=All
set GENERATE_REPORT=false
set CREATE_TEST_FILES=false

:parse_args
if "%~1"=="" goto :execute
if /i "%~1"=="-TestType" (
    set TEST_TYPE=%~2
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="-GenerateReport" (
    set GENERATE_REPORT=true
    shift
    goto :parse_args
)
if /i "%~1"=="-CreateTestFiles" (
    set CREATE_TEST_FILES=true
    shift
    goto :parse_args
)
shift
goto :parse_args

:execute
echo [INFO] Exécution des tests de type: %TEST_TYPE%
echo [INFO] Génération de rapport: %GENERATE_REPORT%
echo [INFO] Création de fichiers de test: %CREATE_TEST_FILES%
echo.

REM Construire la commande PowerShell
set PS_COMMAND=.\Invoke-HierarchyTests.ps1 -TestType %TEST_TYPE%
if "%GENERATE_REPORT%"=="true" set PS_COMMAND=%PS_COMMAND% -GenerateReport
if "%CREATE_TEST_FILES%"=="true" set PS_COMMAND=%PS_COMMAND% -CreateTestFiles

REM Exécuter la commande PowerShell
echo [INFO] Exécution de la commande: %PS_COMMAND%
echo.

powershell -ExecutionPolicy Bypass -Command "%PS_COMMAND%"

echo.
if %ERRORLEVEL% equ 0 (
    echo [SUCCÈS] Tests terminés avec succès.
) else (
    echo [ERREUR] Erreur lors de l'exécution des tests.
)

echo.
echo Appuyez sur une touche pour quitter...
pause >nul
