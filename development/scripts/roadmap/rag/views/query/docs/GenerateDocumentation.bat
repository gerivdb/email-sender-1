@echo off
REM GenerateDocumentation.bat - Script pour générer la documentation du langage de requête
REM Version: 1.0
REM Date: 2025-05-15

echo ===== GENERATION DE LA DOCUMENTATION DU LANGAGE DE REQUETE =====
echo.

REM Vérifier si PowerShell est disponible
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERREUR] PowerShell n'est pas disponible. Veuillez l'installer.
    goto :EOF
)

REM Afficher le menu principal
:menu
cls
echo ===== GENERATION DE LA DOCUMENTATION DU LANGAGE DE REQUETE =====
echo.
echo 1. Générer la documentation complète
echo 2. Générer uniquement la documentation des opérateurs
echo 3. Générer uniquement la documentation des exemples
echo 4. Générer uniquement la documentation des bonnes pratiques
echo 5. Quitter
echo.
echo Choisissez une option (1-5) :

set /p option=

if "%option%"=="1" goto :full
if "%option%"=="2" goto :operators
if "%option%"=="3" goto :examples
if "%option%"=="4" goto :bestpractices
if "%option%"=="5" goto :EOF

echo Option invalide. Veuillez réessayer.
pause
goto :menu

:full
cls
echo ===== GENERATION DE LA DOCUMENTATION COMPLETE =====
echo.
echo Format de sortie (Markdown, HTML, PDF) [défaut: Markdown] :
set /p output_format=
if "%output_format%"=="" set output_format=Markdown

echo.
echo Répertoire de sortie (laissez vide pour utiliser le répertoire par défaut) :
set /p output_dir=

echo.
echo Génération de la documentation complète en cours...
echo.

set ps_command=.\Generate-QueryLanguageDocumentation.ps1 -GenerateFullDocumentation
if not "%output_dir%"=="" set ps_command=%ps_command% -OutputDir "%output_dir%"
set ps_command=%ps_command% -OutputFormat %output_format%

powershell -ExecutionPolicy Bypass -Command "%ps_command%"

echo.
pause
goto :menu

:operators
cls
echo ===== GENERATION DE LA DOCUMENTATION DES OPERATEURS =====
echo.
echo Format de sortie (Markdown, HTML, PDF) [défaut: Markdown] :
set /p output_format=
if "%output_format%"=="" set output_format=Markdown

echo.
echo Répertoire de sortie (laissez vide pour utiliser le répertoire par défaut) :
set /p output_dir=

echo.
echo Génération de la documentation des opérateurs en cours...
echo.

set ps_command=.\Generate-QueryLanguageDocumentation.ps1 -GenerateOperatorsDoc
if not "%output_dir%"=="" set ps_command=%ps_command% -OutputDir "%output_dir%"
set ps_command=%ps_command% -OutputFormat %output_format%

powershell -ExecutionPolicy Bypass -Command "%ps_command%"

echo.
pause
goto :menu

:examples
cls
echo ===== GENERATION DE LA DOCUMENTATION DES EXEMPLES =====
echo.
echo Format de sortie (Markdown, HTML, PDF) [défaut: Markdown] :
set /p output_format=
if "%output_format%"=="" set output_format=Markdown

echo.
echo Répertoire de sortie (laissez vide pour utiliser le répertoire par défaut) :
set /p output_dir=

echo.
echo Génération de la documentation des exemples en cours...
echo.

set ps_command=.\Generate-QueryLanguageDocumentation.ps1 -GenerateExamplesDoc
if not "%output_dir%"=="" set ps_command=%ps_command% -OutputDir "%output_dir%"
set ps_command=%ps_command% -OutputFormat %output_format%

powershell -ExecutionPolicy Bypass -Command "%ps_command%"

echo.
pause
goto :menu

:bestpractices
cls
echo ===== GENERATION DE LA DOCUMENTATION DES BONNES PRATIQUES =====
echo.
echo Format de sortie (Markdown, HTML, PDF) [défaut: Markdown] :
set /p output_format=
if "%output_format%"=="" set output_format=Markdown

echo.
echo Répertoire de sortie (laissez vide pour utiliser le répertoire par défaut) :
set /p output_dir=

echo.
echo Génération de la documentation des bonnes pratiques en cours...
echo.

set ps_command=.\Generate-QueryLanguageDocumentation.ps1 -GenerateBestPracticesDoc
if not "%output_dir%"=="" set ps_command=%ps_command% -OutputDir "%output_dir%"
set ps_command=%ps_command% -OutputFormat %output_format%

powershell -ExecutionPolicy Bypass -Command "%ps_command%"

echo.
pause
goto :menu
