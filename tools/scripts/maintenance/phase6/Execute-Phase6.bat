@echo off
echo Exécution de la Phase 6...
echo.

echo 1. Vérification des prérequis...
powershell -ExecutionPolicy Bypass -File "scripts\maintenance\phase6\Test-Phase6Prerequisites.ps1" -Verbose
if %ERRORLEVEL% NEQ 0 (
    echo Erreur lors de la vérification des prérequis.
    echo Voulez-vous continuer quand même ? (O/N)
    set /p continue=
    if /i "%continue%" NEQ "O" (
        echo Opération annulée par l'utilisateur.
        goto :end
    )
)

echo.
echo 2. Exécution du script principal...
powershell -ExecutionPolicy Bypass -File "scripts\maintenance\phase6\Start-Phase6.ps1" -CreateBackup -Verbose
if %ERRORLEVEL% NEQ 0 (
    echo Erreur lors de l'exécution du script principal.
    echo Voulez-vous continuer quand même ? (O/N)
    set /p continue=
    if /i "%continue%" NEQ "O" (
        echo Opération annulée par l'utilisateur.
        goto :end
    )
)

echo.
echo 3. Test des améliorations...
powershell -ExecutionPolicy Bypass -File "scripts\maintenance\phase6\Test-Phase6Implementation.ps1" -Verbose
if %ERRORLEVEL% NEQ 0 (
    echo Erreur lors du test des améliorations.
    echo Voulez-vous continuer quand même ? (O/N)
    set /p continue=
    if /i "%continue%" NEQ "O" (
        echo Opération annulée par l'utilisateur.
        goto :end
    )
)

echo.
echo 4. Implémentation du système de journalisation centralisé...
powershell -ExecutionPolicy Bypass -File "scripts\maintenance\phase6\Implement-CentralizedLogging.ps1" -CreateBackup -Verbose
if %ERRORLEVEL% NEQ 0 (
    echo Erreur lors de l'implémentation du système de journalisation centralisé.
    echo Voulez-vous continuer quand même ? (O/N)
    set /p continue=
    if /i "%continue%" NEQ "O" (
        echo Opération annulée par l'utilisateur.
        goto :end
    )
)

echo.
echo 5. Test de la compatibilité entre environnements...
powershell -ExecutionPolicy Bypass -File "scripts\maintenance\phase6\Test-EnvironmentCompatibility.ps1" -Verbose
if %ERRORLEVEL% NEQ 0 (
    echo Erreur lors du test de la compatibilité entre environnements.
    echo Voulez-vous continuer quand même ? (O/N)
    set /p continue=
    if /i "%continue%" NEQ "O" (
        echo Opération annulée par l'utilisateur.
        goto :end
    )
)

echo.
echo Phase 6 terminée avec succès !

:end
echo.
echo Appuyez sur une touche pour quitter...
pause > nul
