@echo off
:: Wrapper pour le hook pre-commit qui appelle le script PowerShell
:: Ce fichier doit être copié dans .git/hooks/pre-commit

echo Exécution du hook pre-commit...

:: Obtenir le chemin du répertoire Git
for /f "delims=" %%i in ('git rev-parse --git-dir') do set GIT_DIR=%%i
for /f "delims=" %%i in ('git rev-parse --show-toplevel') do set PROJECT_ROOT=%%i

:: Définir le chemin du script PowerShell
set SCRIPT_PATH=%PROJECT_ROOT%\scripts\utils\git\hooks\pre-commit.ps1

:: Vérifier si le script existe
if exist "%SCRIPT_PATH%" (
    :: Exécuter le script PowerShell
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
    
    :: Vérifier le code de sortie
    if %ERRORLEVEL% neq 0 (
        echo Erreur lors de l'exécution du hook pre-commit
        exit /b %ERRORLEVEL%
    )
) else (
    echo Avertissement: Script pre-commit non trouvé à %SCRIPT_PATH%
    echo Le commit continuera sans vérification
)

exit /b 0
