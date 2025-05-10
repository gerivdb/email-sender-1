@echo off
REM CustomViewManager.bat - Script pour gérer les vues personnalisées
REM Version: 1.0
REM Date: 2025-05-15

echo ===== GESTIONNAIRE DE VUES PERSONNALISEES =====
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
echo ===== GESTIONNAIRE DE VUES PERSONNALISEES =====
echo.
echo 1. Créer une nouvelle vue
echo 2. Afficher les vues existantes
echo 3. Afficher une vue spécifique
echo 4. Modifier une vue
echo 5. Supprimer une vue
echo 6. Exporter une vue
echo 7. Importer une vue
echo 8. Quitter
echo.
echo Choisissez une option (1-8) :

set /p option=

if "%option%"=="1" goto :create
if "%option%"=="2" goto :list
if "%option%"=="3" goto :show
if "%option%"=="4" goto :edit
if "%option%"=="5" goto :delete
if "%option%"=="6" goto :export
if "%option%"=="7" goto :import
if "%option%"=="8" goto :EOF

echo Option invalide. Veuillez réessayer.
pause
goto :menu

:create
cls
echo ===== CREATION D'UNE NOUVELLE VUE =====
echo.
echo Chemin du fichier de roadmap (laissez vide pour utiliser un exemple) :
set /p roadmap_path=

echo.
echo Type d'interface (Console, GUI, Web) [défaut: Console] :
set /p interface_type=
if "%interface_type%"=="" set interface_type=Console

echo.
echo Mode de combinaison par défaut (AND, OR, CUSTOM) [défaut: AND] :
set /p combination_mode=
if "%combination_mode%"=="" set combination_mode=AND

echo.
echo Format de prévisualisation (Console, HTML, Markdown) [défaut: Console] :
set /p preview_format=
if "%preview_format%"=="" set preview_format=Console

echo.
echo Sauter la prévisualisation ? (O/N) [défaut: N] :
set /p skip_preview=
if /i "%skip_preview%"=="O" (
    set skip_preview=-SkipPreview
) else (
    set skip_preview=
)

echo.
echo Répertoire de sortie (laissez vide pour utiliser le répertoire par défaut) :
set /p output_dir=

echo.
echo Création de la vue en cours...
echo.

set ps_command=.\New-CustomView.ps1
if not "%roadmap_path%"=="" set ps_command=%ps_command% -RoadmapPath "%roadmap_path%"
if not "%output_dir%"=="" set ps_command=%ps_command% -OutputDir "%output_dir%"
set ps_command=%ps_command% -InterfaceType %interface_type% -DefaultCombinationMode %combination_mode% -PreviewFormat %preview_format% %skip_preview% -SaveConfiguration

powershell -ExecutionPolicy Bypass -Command "%ps_command%"

echo.
pause
goto :menu

:list
cls
echo ===== LISTE DES VUES EXISTANTES =====
echo.
echo Répertoire des vues (laissez vide pour utiliser le répertoire par défaut) :
set /p views_dir=

echo.
echo Affichage des vues en cours...
echo.

set ps_command=.\Invoke-CustomViewManager.ps1 -Action List
if not "%views_dir%"=="" set ps_command=%ps_command% -ViewsDir "%views_dir%"

powershell -ExecutionPolicy Bypass -Command "%ps_command%"

echo.
pause
goto :menu

:show
cls
echo ===== AFFICHAGE D'UNE VUE =====
echo.
echo Répertoire des vues (laissez vide pour utiliser le répertoire par défaut) :
set /p views_dir=

echo.
echo Nom de la vue (laissez vide pour choisir dans la liste) :
set /p view_name=

echo.
echo Chemin du fichier de roadmap (laissez vide pour utiliser un exemple) :
set /p roadmap_path=

echo.
echo Format de sortie (Console, HTML, Markdown) [défaut: Console] :
set /p output_format=
if "%output_format%"=="" set output_format=Console

echo.
echo Chemin de sortie (uniquement pour HTML et Markdown, laissez vide pour générer automatiquement) :
set /p output_path=

echo.
echo Affichage de la vue en cours...
echo.

set ps_command=.\Invoke-CustomViewManager.ps1 -Action Show
if not "%views_dir%"=="" set ps_command=%ps_command% -ViewsDir "%views_dir%"
if not "%view_name%"=="" set ps_command=%ps_command% -ViewName "%view_name%"
if not "%roadmap_path%"=="" set ps_command=%ps_command% -RoadmapPath "%roadmap_path%"
if not "%output_path%"=="" set ps_command=%ps_command% -OutputPath "%output_path%"
set ps_command=%ps_command% -OutputFormat %output_format%

powershell -ExecutionPolicy Bypass -Command "%ps_command%"

echo.
pause
goto :menu

:edit
cls
echo ===== MODIFICATION D'UNE VUE =====
echo.
echo Répertoire des vues (laissez vide pour utiliser le répertoire par défaut) :
set /p views_dir=

echo.
echo Nom de la vue (laissez vide pour choisir dans la liste) :
set /p view_name=

echo.
echo Chemin de sortie (laissez vide pour écraser le fichier existant) :
set /p output_path=

echo.
echo Modification de la vue en cours...
echo.

set ps_command=.\Invoke-CustomViewManager.ps1 -Action Edit
if not "%views_dir%"=="" set ps_command=%ps_command% -ViewsDir "%views_dir%"
if not "%view_name%"=="" set ps_command=%ps_command% -ViewName "%view_name%"
if not "%output_path%"=="" set ps_command=%ps_command% -OutputPath "%output_path%"

powershell -ExecutionPolicy Bypass -Command "%ps_command%"

echo.
pause
goto :menu

:delete
cls
echo ===== SUPPRESSION D'UNE VUE =====
echo.
echo Répertoire des vues (laissez vide pour utiliser le répertoire par défaut) :
set /p views_dir=

echo.
echo Nom de la vue (laissez vide pour choisir dans la liste) :
set /p view_name=

echo.
echo Suppression de la vue en cours...
echo.

set ps_command=.\Invoke-CustomViewManager.ps1 -Action Delete
if not "%views_dir%"=="" set ps_command=%ps_command% -ViewsDir "%views_dir%"
if not "%view_name%"=="" set ps_command=%ps_command% -ViewName "%view_name%"

powershell -ExecutionPolicy Bypass -Command "%ps_command%"

echo.
pause
goto :menu

:export
cls
echo ===== EXPORTATION D'UNE VUE =====
echo.
echo Répertoire des vues (laissez vide pour utiliser le répertoire par défaut) :
set /p views_dir=

echo.
echo Nom de la vue (laissez vide pour choisir dans la liste) :
set /p view_name=

echo.
echo Chemin d'exportation (laissez vide pour générer automatiquement) :
set /p output_path=

echo.
echo Exportation de la vue en cours...
echo.

set ps_command=.\Invoke-CustomViewManager.ps1 -Action Export
if not "%views_dir%"=="" set ps_command=%ps_command% -ViewsDir "%views_dir%"
if not "%view_name%"=="" set ps_command=%ps_command% -ViewName "%view_name%"
if not "%output_path%"=="" set ps_command=%ps_command% -OutputPath "%output_path%"

powershell -ExecutionPolicy Bypass -Command "%ps_command%"

echo.
pause
goto :menu

:import
cls
echo ===== IMPORTATION D'UNE VUE =====
echo.
echo Répertoire des vues (laissez vide pour utiliser le répertoire par défaut) :
set /p views_dir=

echo.
echo Chemin du fichier à importer :
set /p import_path=

if "%import_path%"=="" (
    echo Le chemin du fichier à importer est obligatoire.
    pause
    goto :import
)

echo.
echo Importation de la vue en cours...
echo.

set ps_command=.\Invoke-CustomViewManager.ps1 -Action Import
if not "%views_dir%"=="" set ps_command=%ps_command% -ViewsDir "%views_dir%"
set ps_command=%ps_command% -OutputPath "%import_path%"

powershell -ExecutionPolicy Bypass -Command "%ps_command%"

echo.
pause
goto :menu
