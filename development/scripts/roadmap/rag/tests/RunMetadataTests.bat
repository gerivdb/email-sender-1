@echo off
REM RunMetadataTests.bat - Script pour exécuter les tests d'extraction et d'inférence de métadonnées
REM Version: 1.0
REM Date: 2025-05-15

echo ===== TESTS D'EXTRACTION ET D'INFERENCE DE METADONNEES =====
echo.

REM Vérifier si PowerShell est disponible
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERREUR] PowerShell n'est pas disponible. Veuillez l'installer.
    goto :EOF
)

REM Exécuter le script PowerShell pour les métadonnées inline
echo [INFO] Exécution du test d'extraction des métadonnées inline...
echo.

powershell -ExecutionPolicy Bypass -Command ".\Invoke-HierarchyTests.ps1 -TestType InlineMetadata -GenerateReport"

REM Exécuter le script PowerShell pour les blocs de métadonnées
echo.
echo [INFO] Exécution du test d'extraction des blocs de métadonnées...
echo.

powershell -ExecutionPolicy Bypass -Command ".\Invoke-HierarchyTests.ps1 -TestType MetadataBlocks -GenerateReport"

REM Exécuter le script PowerShell pour l'inférence de métadonnées
echo.
echo [INFO] Exécution du test d'inférence de métadonnées...
echo.

powershell -ExecutionPolicy Bypass -Command ".\Invoke-HierarchyTests.ps1 -TestType TaskMetadata -GenerateReport"

echo.
echo [INFO] Tests de métadonnées terminés.
echo.
echo Appuyez sur une touche pour quitter...
pause >nul
