<#
.SYNOPSIS
    Organise la structure du dépôt selon une hiérarchie optimisée.

.DESCRIPTION
    Ce script réorganise le dépôt en une structure hiérarchique optimisée
    avec un nombre minimal de dossiers à la racine. Il crée une structure
    logique et déplace les fichiers vers leurs emplacements appropriés.

.PARAMETER DryRun
    Si spécifié, le script affiche les actions qui seraient effectuées sans les exécuter.

.PARAMETER Force
    Si spécifié, le script écrase les fichiers existants sans demander de confirmation.

.PARAMETER LogFile
    Chemin vers un fichier de log pour enregistrer les actions effectuées.

.EXAMPLE
    .\organize-repository-v2.ps1 -DryRun

.EXAMPLE
    .\organize-repository-v2.ps1 -Force -LogFile "organize-v2.log"

.NOTES
    Auteur: Maintenance Team
    Version: 2.0
    Date de création: 2023-08-15
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$LogFile
)

# Définir le répertoire racine du dépôt
$repoRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\"
$repoRoot = [System.IO.Path]::GetFullPath($repoRoot)

# Vérifier que le répertoire racine existe
if (-not (Test-Path -Path $repoRoot -PathType Container)) {
    throw "Le répertoire racine n'existe pas : $repoRoot"
}

Write-Host "Organisation du dépôt : $repoRoot" -ForegroundColor Cyan

# Fonction pour journaliser les actions
function Write-Log {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    
    Write-Host $Message -ForegroundColor $Color
    
    if ($LogFile) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp - $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
}

# Initialiser le fichier de log
if ($LogFile) {
    if (-not [System.IO.Path]::IsPathRooted($LogFile)) {
        $LogFile = Join-Path -Path $PSScriptRoot -ChildPath $LogFile
    }
    
    $logDir = Split-Path -Path $LogFile -Parent
    if (-not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== Organisation démarrée le $timestamp ===" | Out-File -FilePath $LogFile -Encoding UTF8
    "Répertoire racine: $repoRoot" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# Définir la nouvelle structure hiérarchique
$rootFolders = @(
    "src",           # Code source principal
    "tools",         # Outils et scripts
    "docs",          # Documentation
    "tests",         # Tests
    "config",        # Configuration
    "assets",        # Ressources statiques
    ".build"         # Fichiers de build et CI/CD
)

Write-Log "Création de la structure principale..." -Color Cyan

# Créer les dossiers racine
foreach ($folder in $rootFolders) {
    $folderPath = Join-Path -Path $repoRoot -ChildPath $folder
    
    if (-not (Test-Path -Path $folderPath)) {
        if ($DryRun) {
            Write-Log "[DRYRUN] Création du dossier racine : $folderPath" -Color Yellow
        } else {
            if ($PSCmdlet.ShouldProcess($folderPath, "Créer le dossier racine")) {
                New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
                Write-Log "Dossier racine créé : $folderPath" -Color Green
            }
        }
    } else {
        Write-Log "Le dossier racine existe déjà : $folderPath" -Color Gray
    }
}

# Définir la structure détaillée
$folderStructure = @{
    # Structure src (code source)
    "src" = @(
        "core",                  # Fonctionnalités de base
        "modules",               # Modules fonctionnels
        "api",                   # API et interfaces
        "services",              # Services
        "utils",                 # Utilitaires
        "models",                # Modèles de données
        "n8n",                   # Workflows n8n
        "frontend"               # Interface utilisateur
    )
    
    # Structure tools (outils et scripts)
    "tools" = @(
        "scripts",               # Scripts divers
        "scripts/roadmap",       # Scripts de roadmap
        "scripts/maintenance",   # Scripts de maintenance
        "scripts/deployment",    # Scripts de déploiement
        "scripts/automation",    # Scripts d'automatisation
        "generators",            # Générateurs de code
        "analyzers",             # Outils d'analyse
        "converters",            # Outils de conversion
        "templates",             # Templates
        "templates/reports",     # Templates de rapports
        "templates/code",        # Templates de code
        "_templates",            # Templates Hygen
        "_templates/roadmap",    # Templates Hygen pour roadmap
        "_templates/maintenance" # Templates Hygen pour maintenance
    )
    
    # Structure docs (documentation)
    "docs" = @(
        "guides",                # Guides d'utilisation
        "guides/user",           # Guides utilisateur
        "guides/developer",      # Guides développeur
        "guides/admin",          # Guides administrateur
        "guides/methodologies",  # Méthodologies
        "api",                   # Documentation API
        "architecture",          # Documentation architecture
        "roadmap",               # Roadmap du projet
        "roadmap/plans",         # Plans de roadmap
        "examples",              # Exemples
        "references"             # Références
    )
    
    # Structure tests (tests)
    "tests" = @(
        "unit",                  # Tests unitaires
        "integration",           # Tests d'intégration
        "performance",           # Tests de performance
        "e2e",                   # Tests end-to-end
        "fixtures",              # Données de test
        "mocks"                  # Mocks et stubs
    )
    
    # Structure config (configuration)
    "config" = @(
        "environments",          # Configurations d'environnement
        "settings",              # Paramètres généraux
        "schemas",               # Schémas de configuration
        "templates"              # Templates de configuration
    )
    
    # Structure assets (ressources)
    "assets" = @(
        "images",                # Images
        "styles",                # Styles
        "fonts",                 # Polices
        "data",                  # Données statiques
        "media"                  # Médias
    )
    
    # Structure .build (build et CI/CD)
    ".build" = @(
        "ci",                    # Configuration CI
        "cd",                    # Configuration CD
        "pipelines",             # Pipelines
        "scripts",               # Scripts de build
        "artifacts",             # Artefacts de build
        "cache",                 # Cache de build
        "logs"                   # Logs de build
    )
}

# Créer la structure détaillée
foreach ($rootFolder in $folderStructure.Keys) {
    foreach ($subFolder in $folderStructure[$rootFolder]) {
        $folderPath = Join-Path -Path $repoRoot -ChildPath "$rootFolder/$subFolder"
        
        if (-not (Test-Path -Path $folderPath)) {
            if ($DryRun) {
                Write-Log "[DRYRUN] Création du dossier : $folderPath" -Color Yellow
            } else {
                if ($PSCmdlet.ShouldProcess($folderPath, "Créer le dossier")) {
                    New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
                    Write-Log "Dossier créé : $folderPath" -Color Green
                }
            }
        } else {
            Write-Log "Le dossier existe déjà : $folderPath" -Color Gray
        }
    }
}

# Définir les mappages de dossiers (déplacer des dossiers entiers)
$directoryMappings = @{
    # Déplacer les dossiers existants vers la nouvelle structure
    "scripts"                    = "tools/scripts"
    "scripts/roadmap"            = "tools/scripts/roadmap"
    "scripts/roadmap-parser"     = "tools/scripts/roadmap/parser"
    "scripts/maintenance"        = "tools/scripts/maintenance"
    "_templates"                 = "tools/_templates"
    "templates"                  = "tools/templates"
    "Roadmap"                    = "docs/roadmap"
    "Roadmap/mes-plans"          = "docs/roadmap/plans"
    "docs/guides"                = "docs/guides"
    "n8n"                        = "src/n8n"
    "frontend"                   = "src/frontend"
    "modules"                    = "src/modules"
    "tests"                      = "tests"
    "config"                     = "config"
    "assets"                     = "assets"
    "logs"                       = ".build/logs"
    "cache"                      = ".build/cache"
    "dashboards"                 = "tools/dashboards"
    "reports"                    = "tools/reports"
    "tools"                      = "tools"
    "mcp"                        = "src/mcp"
    "data"                       = "assets/data"
    "journal"                    = "docs/journal"
    "backups"                    = ".build/backups"
    "extensions"                 = "src/extensions"
    "git-hooks"                  = ".build/ci/git-hooks"
    "ProjectManagement"          = "docs/project-management"
    "ErrorManagement"            = "src/error-management"
    "FormatSupport"              = "src/format-support"
    "Insights"                   = "tools/insights"
    "output"                     = ".build/output"
    "SWE-bench"                  = "tools/swe-bench"
    "cmd"                        = "tools/cmd"
    "md"                         = "docs/md"
    "archive"                    = ".build/archive"
}

Write-Log "Déplacement des dossiers existants vers la nouvelle structure..." -Color Cyan

# Fonction pour déplacer un dossier entier
function Move-DirectoryToNewLocation {
    param (
        [string]$SourceDir,
        [string]$DestinationDir
    )
    
    $sourcePath = Join-Path -Path $repoRoot -ChildPath $SourceDir
    $destinationPath = Join-Path -Path $repoRoot -ChildPath $DestinationDir
    
    if (-not (Test-Path -Path $sourcePath -PathType Container)) {
        Write-Log "Le dossier source n'existe pas : $sourcePath" -Color Yellow
        return
    }
    
    $destinationParent = Split-Path -Path $destinationPath -Parent
    if (-not (Test-Path -Path $destinationParent)) {
        if ($DryRun) {
            Write-Log "[DRYRUN] Création du dossier parent : $destinationParent" -Color Yellow
        } else {
            if ($PSCmdlet.ShouldProcess($destinationParent, "Créer le dossier parent")) {
                New-Item -Path $destinationParent -ItemType Directory -Force | Out-Null
                Write-Log "Dossier parent créé : $destinationParent" -Color Green
            }
        }
    }
    
    if (Test-Path -Path $destinationPath) {
        # Le dossier de destination existe déjà, on doit fusionner le contenu
        $sourceItems = Get-ChildItem -Path $sourcePath -Recurse
        
        foreach ($item in $sourceItems) {
            $relativePath = $item.FullName.Substring($sourcePath.Length).TrimStart('\')
            $targetPath = Join-Path -Path $destinationPath -ChildPath $relativePath
            
            if ($item.PSIsContainer) {
                # C'est un dossier
                if (-not (Test-Path -Path $targetPath)) {
                    if ($DryRun) {
                        Write-Log "[DRYRUN] Création du dossier : $targetPath" -Color Yellow
                    } else {
                        if ($PSCmdlet.ShouldProcess($targetPath, "Créer le dossier")) {
                            New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
                            Write-Log "Dossier créé : $targetPath" -Color Green
                        }
                    }
                }
            } else {
                # C'est un fichier
                $targetDir = Split-Path -Path $targetPath -Parent
                if (-not (Test-Path -Path $targetDir)) {
                    if ($DryRun) {
                        Write-Log "[DRYRUN] Création du dossier : $targetDir" -Color Yellow
                    } else {
                        if ($PSCmdlet.ShouldProcess($targetDir, "Créer le dossier")) {
                            New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
                            Write-Log "Dossier créé : $targetDir" -Color Green
                        }
                    }
                }
                
                if (Test-Path -Path $targetPath) {
                    if ($Force) {
                        $shouldContinue = $true
                    } else {
                        $shouldContinue = $PSCmdlet.ShouldContinue("Le fichier existe déjà : $targetPath. Voulez-vous le remplacer ?", "Confirmation")
                    }
                } else {
                    $shouldContinue = $true
                }
                
                if ($shouldContinue) {
                    if ($DryRun) {
                        Write-Log "[DRYRUN] Copie du fichier : $($item.FullName) -> $targetPath" -Color Yellow
                    } else {
                        if ($PSCmdlet.ShouldProcess($item.FullName, "Copier vers $targetPath")) {
                            Copy-Item -Path $item.FullName -Destination $targetPath -Force
                            Write-Log "Fichier copié : $($item.FullName) -> $targetPath" -Color Green
                        }
                    }
                } else {
                    Write-Log "Copie ignorée : $($item.FullName)" -Color Gray
                }
            }
        }
        
        Write-Log "Contenu fusionné : $sourcePath -> $destinationPath" -Color Cyan
    } else {
        # Le dossier de destination n'existe pas, on peut simplement déplacer le dossier source
        if ($DryRun) {
            Write-Log "[DRYRUN] Déplacement du dossier : $sourcePath -> $destinationPath" -Color Yellow
        } else {
            if ($PSCmdlet.ShouldProcess($sourcePath, "Déplacer vers $destinationPath")) {
                # Utiliser Copy-Item puis Remove-Item pour simuler un Move-Item avec création de dossiers parents
                Copy-Item -Path $sourcePath -Destination $destinationPath -Recurse -Force
                Write-Log "Dossier copié : $sourcePath -> $destinationPath" -Color Green
                
                # Ne pas supprimer le dossier source pour l'instant, on le fera dans une phase de nettoyage ultérieure
                # si le déplacement est confirmé comme réussi
            }
        }
    }
}

# Déplacer les dossiers selon les mappages
foreach ($sourceDir in $directoryMappings.Keys) {
    $destinationDir = $directoryMappings[$sourceDir]
    Move-DirectoryToNewLocation -SourceDir $sourceDir -DestinationDir $destinationDir
}

# Définir les mappages de fichiers spécifiques
$fileMappings = @{
    # Fichiers à la racine
    "*.md"                      = "docs/readme/{0}"
    "*.txt"                     = "docs/readme/{0}"
    "*.json"                    = "config/settings/{0}"
    "*.yaml"                    = "config/settings/{0}"
    "*.yml"                     = "config/settings/{0}"
    "*.ps1"                     = "tools/scripts/{0}"
    "*.py"                      = "tools/scripts/{0}"
    "*.js"                      = "src/scripts/{0}"
    "*.ts"                      = "src/scripts/{0}"
    "*.css"                     = "assets/styles/{0}"
    "*.scss"                    = "assets/styles/{0}"
    "*.html"                    = "src/frontend/{0}"
    
    # Scripts spécifiques
    "scripts/*-mode.ps1"        = "tools/scripts/roadmap/modes/{0}/{0}-mode.ps1"
    "scripts/Test-*.ps1"        = "tools/scripts/tests/{0}"
    
    # Documentation
    "docs/guides/mode_*.md"     = "docs/guides/methodologies/modes/{0}"
    "docs/guides/programmation_*.md" = "docs/guides/methodologies/programming/{0}"
    
    # Templates
    "templates/*.ejs.t"         = "tools/_templates/roadmap/{0}"
    "templates/roadmap-parser/*.ejs.t" = "tools/_templates/roadmap-parser/{0}"
    "templates/maintenance/*.ejs.t" = "tools/_templates/maintenance/{0}"
}

Write-Log "Déplacement des fichiers spécifiques..." -Color Cyan

# Fonction pour déplacer un fichier
function Move-FileToNewLocation {
    param (
        [string]$SourceFile,
        [string]$DestinationPath
    )
    
    if (-not (Test-Path -Path $SourceFile)) {
        Write-Log "Le fichier source n'existe pas : $SourceFile" -Color Yellow
        return
    }
    
    $destinationDir = Split-Path -Path $DestinationPath -Parent
    if (-not (Test-Path -Path $destinationDir)) {
        if ($DryRun) {
            Write-Log "[DRYRUN] Création du répertoire : $destinationDir" -Color Yellow
        } else {
            if ($PSCmdlet.ShouldProcess($destinationDir, "Créer le répertoire")) {
                New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
                Write-Log "Répertoire créé : $destinationDir" -Color Green
            }
        }
    }
    
    if (Test-Path -Path $DestinationPath) {
        if ($Force) {
            $shouldContinue = $true
        } else {
            $shouldContinue = $PSCmdlet.ShouldContinue("Le fichier existe déjà : $DestinationPath. Voulez-vous le remplacer ?", "Confirmation")
        }
    } else {
        $shouldContinue = $true
    }
    
    if ($shouldContinue) {
        if ($DryRun) {
            Write-Log "[DRYRUN] Déplacement du fichier : $SourceFile -> $DestinationPath" -Color Yellow
        } else {
            if ($PSCmdlet.ShouldProcess($SourceFile, "Déplacer vers $DestinationPath")) {
                Copy-Item -Path $SourceFile -Destination $DestinationPath -Force
                Write-Log "Fichier déplacé : $SourceFile -> $DestinationPath" -Color Green
                
                # Ne pas supprimer le fichier source pour l'instant
            }
        }
    } else {
        Write-Log "Déplacement ignoré : $SourceFile" -Color Gray
    }
}

# Parcourir les mappages de fichiers
foreach ($pattern in $fileMappings.Keys) {
    $files = Get-ChildItem -Path (Join-Path -Path $repoRoot -ChildPath $pattern) -File -ErrorAction SilentlyContinue
    
    foreach ($file in $files) {
        $fileName = $file.Name
        $baseName = $file.BaseName
        
        # Extraire le nom du mode à partir du nom du fichier
        if ($fileName -match "^([a-zA-Z0-9-]+)-mode\.ps1$") {
            $modeName = $matches[1]
            $destinationPath = Join-Path -Path $repoRoot -ChildPath ($fileMappings[$pattern] -f $modeName)
        } else {
            $destinationPath = Join-Path -Path $repoRoot -ChildPath ($fileMappings[$pattern] -f $fileName)
        }
        
        Move-FileToNewLocation -SourceFile $file.FullName -DestinationPath $destinationPath
    }
}

# Créer des fichiers README.md pour chaque dossier racine
$readmeTemplates = @{
    "src" = @"
# Source Code

Ce répertoire contient le code source principal du projet.

## Structure

- **core/** - Fonctionnalités de base
- **modules/** - Modules fonctionnels
- **api/** - API et interfaces
- **services/** - Services
- **utils/** - Utilitaires
- **models/** - Modèles de données
- **n8n/** - Workflows n8n
- **frontend/** - Interface utilisateur

## Conventions

- Suivre les conventions de nommage du projet
- Documenter les fonctions et classes
- Écrire des tests unitaires pour chaque fonctionnalité
"@

    "tools" = @"
# Tools

Ce répertoire contient les outils et scripts du projet.

## Structure

- **scripts/** - Scripts divers
  - **roadmap/** - Scripts de roadmap
  - **maintenance/** - Scripts de maintenance
  - **deployment/** - Scripts de déploiement
  - **automation/** - Scripts d'automatisation
- **generators/** - Générateurs de code
- **analyzers/** - Outils d'analyse
- **converters/** - Outils de conversion
- **templates/** - Templates
- **_templates/** - Templates Hygen

## Utilisation

Consultez la documentation dans le dossier `docs/guides` pour plus d'informations sur l'utilisation de ces outils.
"@

    "docs" = @"
# Documentation

Ce répertoire contient la documentation du projet.

## Structure

- **guides/** - Guides d'utilisation
  - **user/** - Guides utilisateur
  - **developer/** - Guides développeur
  - **admin/** - Guides administrateur
  - **methodologies/** - Méthodologies
- **api/** - Documentation API
- **architecture/** - Documentation architecture
- **roadmap/** - Roadmap du projet
- **examples/** - Exemples
- **references/** - Références

## Contribution

Pour contribuer à la documentation, suivez les conventions décrites dans le guide du développeur.
"@

    "tests" = @"
# Tests

Ce répertoire contient les tests du projet.

## Structure

- **unit/** - Tests unitaires
- **integration/** - Tests d'intégration
- **performance/** - Tests de performance
- **e2e/** - Tests end-to-end
- **fixtures/** - Données de test
- **mocks/** - Mocks et stubs

## Exécution des tests

```powershell
# Exécuter tous les tests
Invoke-Pester

# Exécuter les tests unitaires
Invoke-Pester -Path ./unit

# Exécuter les tests d'intégration
Invoke-Pester -Path ./integration
```
"@

    "config" = @"
# Configuration

Ce répertoire contient les fichiers de configuration du projet.

## Structure

- **environments/** - Configurations d'environnement
- **settings/** - Paramètres généraux
- **schemas/** - Schémas de configuration
- **templates/** - Templates de configuration

## Utilisation

Les fichiers de configuration sont chargés automatiquement par l'application en fonction de l'environnement.
"@

    "assets" = @"
# Assets

Ce répertoire contient les ressources statiques du projet.

## Structure

- **images/** - Images
- **styles/** - Styles
- **fonts/** - Polices
- **data/** - Données statiques
- **media/** - Médias

## Utilisation

Ces ressources sont utilisées par l'application et la documentation.
"@

    ".build" = @"
# Build

Ce répertoire contient les fichiers liés au build et au CI/CD.

## Structure

- **ci/** - Configuration CI
- **cd/** - Configuration CD
- **pipelines/** - Pipelines
- **scripts/** - Scripts de build
- **artifacts/** - Artefacts de build
- **cache/** - Cache de build
- **logs/** - Logs de build

## Utilisation

Ces fichiers sont utilisés par les systèmes de build et de CI/CD.
"@
}

Write-Log "Création des fichiers README.md pour chaque dossier racine..." -Color Cyan

# Créer les fichiers README.md
foreach ($rootFolder in $readmeTemplates.Keys) {
    $readmePath = Join-Path -Path $repoRoot -ChildPath "$rootFolder/README.md"
    
    if (-not (Test-Path -Path $readmePath) -or $Force) {
        if ($DryRun) {
            Write-Log "[DRYRUN] Création du fichier README.md : $readmePath" -Color Yellow
        } else {
            if ($PSCmdlet.ShouldProcess($readmePath, "Créer le fichier README.md")) {
                Set-Content -Path $readmePath -Value $readmeTemplates[$rootFolder] -Encoding UTF8
                Write-Log "Fichier README.md créé : $readmePath" -Color Green
            }
        }
    } else {
        Write-Log "Le fichier README.md existe déjà : $readmePath" -Color Gray
    }
}

# Créer un README.md à la racine
$rootReadmePath = Join-Path -Path $repoRoot -ChildPath "README.md"
$rootReadmeContent = @"
# EMAIL_SENDER_1

## Structure du projet

- **src/** - Code source principal
- **tools/** - Outils et scripts
- **docs/** - Documentation
- **tests/** - Tests
- **config/** - Configuration
- **assets/** - Ressources statiques
- **.build/** - Fichiers de build et CI/CD

## Installation

Consultez le guide d'installation dans `docs/guides/installation/`.

## Documentation

La documentation complète est disponible dans le dossier `docs/`.

## Développement

Consultez le guide du développeur dans `docs/guides/developer/`.

## Tests

Les tests sont disponibles dans le dossier `tests/`.

## Licence

Ce projet est sous licence MIT.
"@

if (-not (Test-Path -Path $rootReadmePath) -or $Force) {
    if ($DryRun) {
        Write-Log "[DRYRUN] Création du fichier README.md à la racine : $rootReadmePath" -Color Yellow
    } else {
        if ($PSCmdlet.ShouldProcess($rootReadmePath, "Créer le fichier README.md à la racine")) {
            Set-Content -Path $rootReadmePath -Value $rootReadmeContent -Encoding UTF8
            Write-Log "Fichier README.md créé à la racine : $rootReadmePath" -Color Green
        }
    }
} else {
    Write-Log "Le fichier README.md existe déjà à la racine : $rootReadmePath" -Color Gray
}

# Résumé de l'organisation
Write-Log "Organisation terminée." -Color Cyan
Write-Log "La structure du dépôt a été réorganisée selon une hiérarchie optimisée." -Color Cyan
Write-Log "Les dossiers racine sont maintenant : $($rootFolders -join ', ')" -Color Cyan

if ($LogFile) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== Organisation terminée le $timestamp ===" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "Dossiers racine : $($rootFolders -join ', ')" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    
    Write-Host "Log d'organisation enregistré dans : $LogFile" -ForegroundColor Cyan
}

# Avertissement final
Write-Log "IMPORTANT : Ce script a copié les fichiers vers la nouvelle structure, mais n'a pas supprimé les fichiers originaux." -Color Yellow
Write-Log "Une fois que vous avez vérifié que tout fonctionne correctement, vous pouvez exécuter un script de nettoyage pour supprimer les fichiers originaux." -Color Yellow
