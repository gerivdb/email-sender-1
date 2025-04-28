<#
.SYNOPSIS
    Organise la structure du dÃ©pÃ´t selon une hiÃ©rarchie optimisÃ©e.

.DESCRIPTION
    Ce script rÃ©organise le dÃ©pÃ´t en une structure hiÃ©rarchique optimisÃ©e
    avec un nombre minimal de dossiers Ã  la racine. Il crÃ©e une structure
    logique et dÃ©place les fichiers vers leurs emplacements appropriÃ©s.

.PARAMETER DryRun
    Si spÃ©cifiÃ©, le script affiche les actions qui seraient effectuÃ©es sans les exÃ©cuter.

.PARAMETER Force
    Si spÃ©cifiÃ©, le script Ã©crase les fichiers existants sans demander de confirmation.

.PARAMETER LogFile
    Chemin vers un fichier de log pour enregistrer les actions effectuÃ©es.

.EXAMPLE
    .\organize-repository-v2.ps1 -DryRun

.EXAMPLE
    .\organize-repository-v2.ps1 -Force -LogFile "organize-v2.log"

.NOTES
    Auteur: Maintenance Team
    Version: 2.0
    Date de crÃ©ation: 2023-08-15
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

# DÃ©finir le rÃ©pertoire racine du dÃ©pÃ´t
$repoRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\"
$repoRoot = [System.IO.Path]::GetFullPath($repoRoot)

# VÃ©rifier que le rÃ©pertoire racine existe
if (-not (Test-Path -Path $repoRoot -PathType Container)) {
    throw "Le rÃ©pertoire racine n'existe pas : $repoRoot"
}

Write-Host "Organisation du dÃ©pÃ´t : $repoRoot" -ForegroundColor Cyan

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
    "=== Organisation dÃ©marrÃ©e le $timestamp ===" | Out-File -FilePath $LogFile -Encoding UTF8
    "RÃ©pertoire racine: $repoRoot" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# DÃ©finir la nouvelle structure hiÃ©rarchique
$rootFolders = @(
    "src",           # Code source principal
    "tools",         # Outils et scripts
    "docs",          # Documentation
    "tests",         # Tests
    "config",        # Configuration
    "assets",        # Ressources statiques
    ".build"         # Fichiers de build et CI/CD
)

Write-Log "CrÃ©ation de la structure principale..." -Color Cyan

# CrÃ©er les dossiers racine
foreach ($folder in $rootFolders) {
    $folderPath = Join-Path -Path $repoRoot -ChildPath $folder
    
    if (-not (Test-Path -Path $folderPath)) {
        if ($DryRun) {
            Write-Log "[DRYRUN] CrÃ©ation du dossier racine : $folderPath" -Color Yellow
        } else {
            if ($PSCmdlet.ShouldProcess($folderPath, "CrÃ©er le dossier racine")) {
                New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
                Write-Log "Dossier racine crÃ©Ã© : $folderPath" -Color Green
            }
        }
    } else {
        Write-Log "Le dossier racine existe dÃ©jÃ  : $folderPath" -Color Gray
    }
}

# DÃ©finir la structure dÃ©taillÃ©e
$folderStructure = @{
    # Structure src (code source)
    "src" = @(
        "core",                  # FonctionnalitÃ©s de base
        "modules",               # Modules fonctionnels
        "api",                   # API et interfaces
        "services",              # Services
        "utils",                 # Utilitaires
        "models",                # ModÃ¨les de donnÃ©es
        "n8n",                   # Workflows n8n
        "frontend"               # Interface utilisateur
    )
    
    # Structure tools (outils et scripts)
    "tools" = @(
        "scripts",               # Scripts divers
        "development/roadmap/scripts",       # Scripts de roadmap
        "development/scripts/maintenance",   # Scripts de maintenance
        "development/scripts/deployment",    # Scripts de dÃ©ploiement
        "development/scripts/automation",    # Scripts d'automatisation
        "generators",            # GÃ©nÃ©rateurs de code
        "analyzers",             # Outils d'analyse
        "converters",            # Outils de conversion
        "templates",             # Templates
        "templates/reports",     # Templates de rapports
        "templates/code",        # Templates de code
        "development/templates",            # Templates Hygen
        "development/templates/roadmap",    # Templates Hygen pour roadmap
        "development/templates/maintenance" # Templates Hygen pour maintenance
    )
    
    # Structure docs (documentation)
    "docs" = @(
        "guides",                # Guides d'utilisation
        "guides/user",           # Guides utilisateur
        "guides/developer",      # Guides dÃ©veloppeur
        "guides/admin",          # Guides administrateur
        "guides/methodologies",  # MÃ©thodologies
        "api",                   # Documentation API
        "architecture",          # Documentation architecture
        "roadmap",               # Roadmap du projet
        "roadmap/plans",         # Plans de roadmap
        "examples",              # Exemples
        "references"             # RÃ©fÃ©rences
    )
    
    # Structure tests (tests)
    "tests" = @(
        "unit",                  # Tests unitaires
        "integration",           # Tests d'intÃ©gration
        "performance",           # Tests de performance
        "e2e",                   # Tests end-to-end
        "fixtures",              # DonnÃ©es de test
        "mocks"                  # Mocks et stubs
    )
    
    # Structure config (configuration)
    "config" = @(
        "environments",          # Configurations d'environnement
        "settings",              # ParamÃ¨tres gÃ©nÃ©raux
        "schemas",               # SchÃ©mas de configuration
        "templates"              # Templates de configuration
    )
    
    # Structure assets (ressources)
    "assets" = @(
        "images",                # Images
        "styles",                # Styles
        "fonts",                 # Polices
        "data",                  # DonnÃ©es statiques
        "media"                  # MÃ©dias
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

# CrÃ©er la structure dÃ©taillÃ©e
foreach ($rootFolder in $folderStructure.Keys) {
    foreach ($subFolder in $folderStructure[$rootFolder]) {
        $folderPath = Join-Path -Path $repoRoot -ChildPath "$rootFolder/$subFolder"
        
        if (-not (Test-Path -Path $folderPath)) {
            if ($DryRun) {
                Write-Log "[DRYRUN] CrÃ©ation du dossier : $folderPath" -Color Yellow
            } else {
                if ($PSCmdlet.ShouldProcess($folderPath, "CrÃ©er le dossier")) {
                    New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
                    Write-Log "Dossier crÃ©Ã© : $folderPath" -Color Green
                }
            }
        } else {
            Write-Log "Le dossier existe dÃ©jÃ  : $folderPath" -Color Gray
        }
    }
}

# DÃ©finir les mappages de dossiers (dÃ©placer des dossiers entiers)
$directoryMappings = @{
    # DÃ©placer les dossiers existants vers la nouvelle structure
    "scripts"                    = "development/scripts"
    "development/roadmap/scripts"            = "development/tools/development/roadmap/scripts"
    "development/roadmap/scripts-parser"     = "development/tools/development/roadmap/scripts/parser"
    "development/scripts/maintenance"        = "development/tools/development/scripts/maintenance"
    "development/templates"                 = "development/tools/development/templates"
    "templates"                  = "development/templates"
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
    "dashboards"                 = "development/tools/dashboards-tools"
    "reports"                    = "development/tools/reports-tools"
    "tools"                      = "tools"
    "mcp"                        = "src/mcp"
    "data"                       = "projet/assets/data"
    "journal"                    = "docs/journal"
    "backups"                    = ".build/backups"
    "extensions"                 = "src/extensions"
    "git-hooks"                  = ".build/ci/git-hooks"
    "ProjectManagement"          = "docs/project-management"
    "ErrorManagement"            = "src/error-management"
    "FormatSupport"              = "src/format-support"
    "Insights"                   = "development/tools/insights-tools"
    "output"                     = ".build/output"
    "SWE-bench"                  = "development/tools/swe-bench-tools"
    "cmd"                        = "development/tools/cmd-tools"
    "md"                         = "docs/md"
    "archive"                    = ".build/archive"
}

Write-Log "DÃ©placement des dossiers existants vers la nouvelle structure..." -Color Cyan

# Fonction pour dÃ©placer un dossier entier
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
            Write-Log "[DRYRUN] CrÃ©ation du dossier parent : $destinationParent" -Color Yellow
        } else {
            if ($PSCmdlet.ShouldProcess($destinationParent, "CrÃ©er le dossier parent")) {
                New-Item -Path $destinationParent -ItemType Directory -Force | Out-Null
                Write-Log "Dossier parent crÃ©Ã© : $destinationParent" -Color Green
            }
        }
    }
    
    if (Test-Path -Path $destinationPath) {
        # Le dossier de destination existe dÃ©jÃ , on doit fusionner le contenu
        $sourceItems = Get-ChildItem -Path $sourcePath -Recurse
        
        foreach ($item in $sourceItems) {
            $relativePath = $item.FullName.Substring($sourcePath.Length).TrimStart('\')
            $targetPath = Join-Path -Path $destinationPath -ChildPath $relativePath
            
            if ($item.PSIsContainer) {
                # C'est un dossier
                if (-not (Test-Path -Path $targetPath)) {
                    if ($DryRun) {
                        Write-Log "[DRYRUN] CrÃ©ation du dossier : $targetPath" -Color Yellow
                    } else {
                        if ($PSCmdlet.ShouldProcess($targetPath, "CrÃ©er le dossier")) {
                            New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
                            Write-Log "Dossier crÃ©Ã© : $targetPath" -Color Green
                        }
                    }
                }
            } else {
                # C'est un fichier
                $targetDir = Split-Path -Path $targetPath -Parent
                if (-not (Test-Path -Path $targetDir)) {
                    if ($DryRun) {
                        Write-Log "[DRYRUN] CrÃ©ation du dossier : $targetDir" -Color Yellow
                    } else {
                        if ($PSCmdlet.ShouldProcess($targetDir, "CrÃ©er le dossier")) {
                            New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
                            Write-Log "Dossier crÃ©Ã© : $targetDir" -Color Green
                        }
                    }
                }
                
                if (Test-Path -Path $targetPath) {
                    if ($Force) {
                        $shouldContinue = $true
                    } else {
                        $shouldContinue = $PSCmdlet.ShouldContinue("Le fichier existe dÃ©jÃ  : $targetPath. Voulez-vous le remplacer ?", "Confirmation")
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
                            Write-Log "Fichier copiÃ© : $($item.FullName) -> $targetPath" -Color Green
                        }
                    }
                } else {
                    Write-Log "Copie ignorÃ©e : $($item.FullName)" -Color Gray
                }
            }
        }
        
        Write-Log "Contenu fusionnÃ© : $sourcePath -> $destinationPath" -Color Cyan
    } else {
        # Le dossier de destination n'existe pas, on peut simplement dÃ©placer le dossier source
        if ($DryRun) {
            Write-Log "[DRYRUN] DÃ©placement du dossier : $sourcePath -> $destinationPath" -Color Yellow
        } else {
            if ($PSCmdlet.ShouldProcess($sourcePath, "DÃ©placer vers $destinationPath")) {
                # Utiliser Copy-Item puis Remove-Item pour simuler un Move-Item avec crÃ©ation de dossiers parents
                Copy-Item -Path $sourcePath -Destination $destinationPath -Recurse -Force
                Write-Log "Dossier copiÃ© : $sourcePath -> $destinationPath" -Color Green
                
                # Ne pas supprimer le dossier source pour l'instant, on le fera dans une phase de nettoyage ultÃ©rieure
                # si le dÃ©placement est confirmÃ© comme rÃ©ussi
            }
        }
    }
}

# DÃ©placer les dossiers selon les mappages
foreach ($sourceDir in $directoryMappings.Keys) {
    $destinationDir = $directoryMappings[$sourceDir]
    Move-DirectoryToNewLocation -SourceDir $sourceDir -DestinationDir $destinationDir
}

# DÃ©finir les mappages de fichiers spÃ©cifiques
$fileMappings = @{
    # Fichiers Ã  la racine
    "*.md"                      = "docs/readme/{0}"
    "*.txt"                     = "docs/readme/{0}"
    "*.json"                    = "projet/config/settings/{0}"
    "*.yaml"                    = "projet/config/settings/{0}"
    "*.yml"                     = "projet/config/settings/{0}"
    "*.ps1"                     = "development/tools/development/scripts/{0}"
    "*.py"                      = "development/tools/development/scripts/{0}"
    "*.js"                      = "src/development/scripts/{0}"
    "*.ts"                      = "src/development/scripts/{0}"
    "*.css"                     = "projet/assets/styles/{0}"
    "*.scss"                    = "projet/assets/styles/{0}"
    "*.html"                    = "src/frontend/{0}"
    
    # Scripts spÃ©cifiques
    "development/scripts/*-mode.ps1"        = "development/tools/development/roadmap/scripts/modes/{0}/{0}-mode.ps1"
    "development/scripts/Test-*.ps1"        = "development/tools/development/scripts/development/testing/tests/{0}"
    
    # Documentation
    "docs/guides/mode_*.md"     = "docs/guides/methodologies/modes/{0}"
    "docs/guides/programmation_*.md" = "docs/guides/methodologies/programming/{0}"
    
    # Templates
    "templates/*.ejs.t"         = "development/tools/development/templates/roadmap/{0}"
    "templates/roadmap-parser/*.ejs.t" = "development/tools/development/templates/roadmap-parser/{0}"
    "templates/maintenance/*.ejs.t" = "development/tools/development/templates/maintenance/{0}"
}

Write-Log "DÃ©placement des fichiers spÃ©cifiques..." -Color Cyan

# Fonction pour dÃ©placer un fichier
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
            Write-Log "[DRYRUN] CrÃ©ation du rÃ©pertoire : $destinationDir" -Color Yellow
        } else {
            if ($PSCmdlet.ShouldProcess($destinationDir, "CrÃ©er le rÃ©pertoire")) {
                New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
                Write-Log "RÃ©pertoire crÃ©Ã© : $destinationDir" -Color Green
            }
        }
    }
    
    if (Test-Path -Path $DestinationPath) {
        if ($Force) {
            $shouldContinue = $true
        } else {
            $shouldContinue = $PSCmdlet.ShouldContinue("Le fichier existe dÃ©jÃ  : $DestinationPath. Voulez-vous le remplacer ?", "Confirmation")
        }
    } else {
        $shouldContinue = $true
    }
    
    if ($shouldContinue) {
        if ($DryRun) {
            Write-Log "[DRYRUN] DÃ©placement du fichier : $SourceFile -> $DestinationPath" -Color Yellow
        } else {
            if ($PSCmdlet.ShouldProcess($SourceFile, "DÃ©placer vers $DestinationPath")) {
                Copy-Item -Path $SourceFile -Destination $DestinationPath -Force
                Write-Log "Fichier dÃ©placÃ© : $SourceFile -> $DestinationPath" -Color Green
                
                # Ne pas supprimer le fichier source pour l'instant
            }
        }
    } else {
        Write-Log "DÃ©placement ignorÃ© : $SourceFile" -Color Gray
    }
}

# Parcourir les mappages de fichiers
foreach ($pattern in $fileMappings.Keys) {
    $files = Get-ChildItem -Path (Join-Path -Path $repoRoot -ChildPath $pattern) -File -ErrorAction SilentlyContinue
    
    foreach ($file in $files) {
        $fileName = $file.Name
        $baseName = $file.BaseName
        
        # Extraire le nom du mode Ã  partir du nom du fichier
        if ($fileName -match "^([a-zA-Z0-9-]+)-mode\.ps1$") {
            $modeName = $matches[1]
            $destinationPath = Join-Path -Path $repoRoot -ChildPath ($fileMappings[$pattern] -f $modeName)
        } else {
            $destinationPath = Join-Path -Path $repoRoot -ChildPath ($fileMappings[$pattern] -f $fileName)
        }
        
        Move-FileToNewLocation -SourceFile $file.FullName -DestinationPath $destinationPath
    }
}

# CrÃ©er des fichiers README.md pour chaque dossier racine
$readmeTemplates = @{
    "src" = @"
# Source Code

Ce rÃ©pertoire contient le code source principal du projet.

## Structure

- **core/** - FonctionnalitÃ©s de base
- **modules/** - Modules fonctionnels
- **api/** - API et interfaces
- **services/** - Services
- **utils/** - Utilitaires
- **models/** - ModÃ¨les de donnÃ©es
- **n8n/** - Workflows n8n
- **frontend/** - Interface utilisateur

## Conventions

- Suivre les conventions de nommage du projet
- Documenter les fonctions et classes
- Ã‰crire des tests unitaires pour chaque fonctionnalitÃ©
"@

    "tools" = @"
# Tools

Ce rÃ©pertoire contient les outils et scripts du projet.

## Structure

- **development/scripts/** - Scripts divers
  - **roadmap/** - Scripts de roadmap
  - **maintenance/** - Scripts de maintenance
  - **deployment/** - Scripts de dÃ©ploiement
  - **automation/** - Scripts d'automatisation
- **generators/** - GÃ©nÃ©rateurs de code
- **analyzers/** - Outils d'analyse
- **converters/** - Outils de conversion
- **templates/** - Templates
- **development/templates/** - Templates Hygen

## Utilisation

Consultez la documentation dans le dossier `docs/guides` pour plus d'informations sur l'utilisation de ces outils.
"@

    "docs" = @"
# Documentation

Ce rÃ©pertoire contient la documentation du projet.

## Structure

- **guides/** - Guides d'utilisation
  - **user/** - Guides utilisateur
  - **developer/** - Guides dÃ©veloppeur
  - **admin/** - Guides administrateur
  - **methodologies/** - MÃ©thodologies
- **api/** - Documentation API
- **architecture/** - Documentation architecture
- **roadmap/** - Roadmap du projet
- **examples/** - Exemples
- **references/** - RÃ©fÃ©rences

## Contribution

Pour contribuer Ã  la documentation, suivez les conventions dÃ©crites dans le guide du dÃ©veloppeur.
"@

    "tests" = @"
# Tests

Ce rÃ©pertoire contient les tests du projet.

## Structure

- **unit/** - Tests unitaires
- **integration/** - Tests d'intÃ©gration
- **performance/** - Tests de performance
- **e2e/** - Tests end-to-end
- **fixtures/** - DonnÃ©es de test
- **mocks/** - Mocks et stubs

## ExÃ©cution des tests

```powershell
# ExÃ©cuter tous les tests
Invoke-Pester

# ExÃ©cuter les tests unitaires
Invoke-Pester -Path ./unit

# ExÃ©cuter les tests d'intÃ©gration
Invoke-Pester -Path ./integration
```
"@

    "config" = @"
# Configuration

Ce rÃ©pertoire contient les fichiers de configuration du projet.

## Structure

- **environments/** - Configurations d'environnement
- **settings/** - ParamÃ¨tres gÃ©nÃ©raux
- **schemas/** - SchÃ©mas de configuration
- **templates/** - Templates de configuration

## Utilisation

Les fichiers de configuration sont chargÃ©s automatiquement par l'application en fonction de l'environnement.
"@

    "assets" = @"
# Assets

Ce rÃ©pertoire contient les ressources statiques du projet.

## Structure

- **images/** - Images
- **styles/** - Styles
- **fonts/** - Polices
- **data/** - DonnÃ©es statiques
- **media/** - MÃ©dias

## Utilisation

Ces ressources sont utilisÃ©es par l'application et la documentation.
"@

    ".build" = @"
# Build

Ce rÃ©pertoire contient les fichiers liÃ©s au build et au CI/CD.

## Structure

- **ci/** - Configuration CI
- **cd/** - Configuration CD
- **pipelines/** - Pipelines
- **development/scripts/** - Scripts de build
- **artifacts/** - Artefacts de build
- **cache/** - Cache de build
- **logs/** - Logs de build

## Utilisation

Ces fichiers sont utilisÃ©s par les systÃ¨mes de build et de CI/CD.
"@
}

Write-Log "CrÃ©ation des fichiers README.md pour chaque dossier racine..." -Color Cyan

# CrÃ©er les fichiers README.md
foreach ($rootFolder in $readmeTemplates.Keys) {
    $readmePath = Join-Path -Path $repoRoot -ChildPath "$rootFolder/README.md"
    
    if (-not (Test-Path -Path $readmePath) -or $Force) {
        if ($DryRun) {
            Write-Log "[DRYRUN] CrÃ©ation du fichier README.md : $readmePath" -Color Yellow
        } else {
            if ($PSCmdlet.ShouldProcess($readmePath, "CrÃ©er le fichier README.md")) {
                Set-Content -Path $readmePath -Value $readmeTemplates[$rootFolder] -Encoding UTF8
                Write-Log "Fichier README.md crÃ©Ã© : $readmePath" -Color Green
            }
        }
    } else {
        Write-Log "Le fichier README.md existe dÃ©jÃ  : $readmePath" -Color Gray
    }
}

# CrÃ©er un README.md Ã  la racine
$rootReadmePath = Join-Path -Path $repoRoot -ChildPath "README.md"
$rootReadmeContent = @"
# EMAIL_SENDER_1

## Structure du projet

- **src/** - Code source principal
- **development/tools/** - Outils et scripts
- **docs/** - Documentation
- **development/testing/tests/** - Tests
- **projet/config/** - Configuration
- **projet/assets/** - Ressources statiques
- **.build/** - Fichiers de build et CI/CD

## Installation

Consultez le guide d'installation dans `docs/guides/installation/`.

## Documentation

La documentation complÃ¨te est disponible dans le dossier `docs/`.

## DÃ©veloppement

Consultez le guide du dÃ©veloppeur dans `docs/guides/developer/`.

## Tests

Les tests sont disponibles dans le dossier `development/testing/tests/`.

## Licence

Ce projet est sous licence MIT.
"@

if (-not (Test-Path -Path $rootReadmePath) -or $Force) {
    if ($DryRun) {
        Write-Log "[DRYRUN] CrÃ©ation du fichier README.md Ã  la racine : $rootReadmePath" -Color Yellow
    } else {
        if ($PSCmdlet.ShouldProcess($rootReadmePath, "CrÃ©er le fichier README.md Ã  la racine")) {
            Set-Content -Path $rootReadmePath -Value $rootReadmeContent -Encoding UTF8
            Write-Log "Fichier README.md crÃ©Ã© Ã  la racine : $rootReadmePath" -Color Green
        }
    }
} else {
    Write-Log "Le fichier README.md existe dÃ©jÃ  Ã  la racine : $rootReadmePath" -Color Gray
}

# RÃ©sumÃ© de l'organisation
Write-Log "Organisation terminÃ©e." -Color Cyan
Write-Log "La structure du dÃ©pÃ´t a Ã©tÃ© rÃ©organisÃ©e selon une hiÃ©rarchie optimisÃ©e." -Color Cyan
Write-Log "Les dossiers racine sont maintenant : $($rootFolders -join ', ')" -Color Cyan

if ($LogFile) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== Organisation terminÃ©e le $timestamp ===" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "Dossiers racine : $($rootFolders -join ', ')" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    
    Write-Host "Log d'organisation enregistrÃ© dans : $LogFile" -ForegroundColor Cyan
}

# Avertissement final
Write-Log "IMPORTANT : Ce script a copiÃ© les fichiers vers la nouvelle structure, mais n'a pas supprimÃ© les fichiers originaux." -Color Yellow
Write-Log "Une fois que vous avez vÃ©rifiÃ© que tout fonctionne correctement, vous pouvez exÃ©cuter un script de nettoyage pour supprimer les fichiers originaux." -Color Yellow




