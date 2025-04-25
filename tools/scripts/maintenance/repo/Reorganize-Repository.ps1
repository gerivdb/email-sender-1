#Requires -Version 5.1
<#
.SYNOPSIS
    Réorganise le dépôt selon le standard défini
.DESCRIPTION
    Ce script réorganise les fichiers du dépôt selon la structure standardisée
    définie dans le document RepoStructureStandard.md. Il crée la structure de
    dossiers, migre les fichiers et génère un journal des déplacements.
.PARAMETER Path
    Chemin du dépôt à réorganiser
.PARAMETER LogPath
    Chemin où générer le journal des déplacements
.PARAMETER DryRun
    Indique si le script doit simuler les déplacements sans les effectuer
.PARAMETER Force
    Indique si le script doit forcer la réorganisation même en cas de conflits
.EXAMPLE
    .\Reorganize-Repository.ps1 -Path "D:\Repos\EMAIL_SENDER_1" -DryRun
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2025-04-26
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "logs\reorganization-$(Get-Date -Format 'yyyyMMdd-HHmmss').log",
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour écrire dans le journal
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Ajouter au fichier journal
    Add-Content -Path $logFilePath -Value $logMessage -Encoding UTF8
    
    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logMessage -ForegroundColor Gray }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
    }
}

# Définition des règles de migration
$migrationRules = @(
    # Scripts PowerShell
    @{
        Pattern = "*.ps1"
        Rules = @(
            # Scripts d'analyse
            @{ 
                Regex = "^(Analyze|Get|Find|Test|Measure).*\.ps1$"
                Destination = "scripts\analysis" 
            },
            # Scripts d'automatisation
            @{ 
                Regex = "^(Start|Stop|Register|Unregister|Schedule|Watch|Monitor).*\.ps1$"
                Destination = "scripts\automation" 
            },
            # Scripts GUI
            @{ 
                Regex = "^(Show|Display|New-.*Form|New-.*Window).*\.ps1$"
                Destination = "scripts\gui" 
            },
            # Scripts d'intégration
            @{ 
                Regex = "^(Connect|Sync|Import|Export|Push|Pull).*\.ps1$"
                Destination = "scripts\integration" 
            },
            # Scripts de maintenance
            @{ 
                Regex = "^(Update|Clean|Repair|Fix|Optimize).*\.ps1$"
                Destination = "scripts\maintenance" 
            },
            # Scripts d'installation
            @{ 
                Regex = "^(Install|Uninstall|Setup|Configure|Initialize).*\.ps1$"
                Destination = "scripts\setup" 
            },
            # Scripts utilitaires (par défaut)
            @{ 
                Regex = ".*\.ps1$"
                Destination = "scripts\utils" 
            }
        )
    },
    
    # Scripts Python
    @{
        Pattern = "*.py"
        Rules = @(
            # Scripts d'analyse
            @{ 
                Regex = "^(analyze|get|find|test|measure).*\.py$"
                Destination = "scripts\analysis" 
            },
            # Scripts d'automatisation
            @{ 
                Regex = "^(start|stop|register|unregister|schedule|watch|monitor).*\.py$"
                Destination = "scripts\automation" 
            },
            # Scripts GUI
            @{ 
                Regex = "^(show|display|gui|window|form).*\.py$"
                Destination = "scripts\gui" 
            },
            # Scripts d'intégration
            @{ 
                Regex = "^(connect|sync|import|export|push|pull).*\.py$"
                Destination = "scripts\integration" 
            },
            # Scripts de maintenance
            @{ 
                Regex = "^(update|clean|repair|fix|optimize).*\.py$"
                Destination = "scripts\maintenance" 
            },
            # Scripts d'installation
            @{ 
                Regex = "^(install|uninstall|setup|configure|initialize).*\.py$"
                Destination = "scripts\setup" 
            },
            # Scripts utilitaires (par défaut)
            @{ 
                Regex = ".*\.py$"
                Destination = "scripts\utils" 
            }
        )
    },
    
    # Scripts Batch
    @{
        Pattern = "*.cmd,*.bat"
        Rules = @(
            # Scripts d'installation
            @{ 
                Regex = "^(install|setup|configure).*\.(cmd|bat)$"
                Destination = "scripts\setup" 
            },
            # Scripts utilitaires (par défaut)
            @{ 
                Regex = ".*\.(cmd|bat)$"
                Destination = "scripts\utils" 
            }
        )
    },
    
    # Modules PowerShell
    @{
        Pattern = "*.psm1"
        Rules = @(
            @{ 
                Regex = ".*\.psm1$"
                Destination = "modules\PowerShell" 
            }
        )
    },
    
    # Documentation
    @{
        Pattern = "*.md"
        Rules = @(
            # Guides
            @{ 
                Regex = "^(Guide|How|Tutorial).*\.md$"
                Destination = "docs\guides" 
            },
            # API
            @{ 
                Regex = "^(API|Reference).*\.md$"
                Destination = "docs\api" 
            },
            # Architecture
            @{ 
                Regex = "^(Architecture|Design).*\.md$"
                Destination = "docs\architecture" 
            },
            # Développement (par défaut)
            @{ 
                Regex = ".*\.md$"
                Destination = "docs\development" 
            }
        )
    },
    
    # Fichiers de configuration
    @{
        Pattern = "*.json,*.yaml,*.yml,*.xml,*.config"
        Rules = @(
            @{ 
                Regex = ".*\.(json|yaml|yml|xml|config)$"
                Destination = "config" 
            }
        )
    },
    
    # Tests
    @{
        Pattern = "*Test*.ps1,*Tests*.ps1,test_*.py,*_test.py"
        Rules = @(
            # Tests unitaires
            @{ 
                Regex = "^(Unit|Test-Unit).*\.ps1$|^test_unit.*\.py$|^unit_test.*\.py$"
                Destination = "tests\unit" 
            },
            # Tests d'intégration
            @{ 
                Regex = "^(Integration|Test-Integration).*\.ps1$|^test_integration.*\.py$|^integration_test.*\.py$"
                Destination = "tests\integration" 
            },
            # Tests de performance
            @{ 
                Regex = "^(Performance|Test-Performance).*\.ps1$|^test_performance.*\.py$|^performance_test.*\.py$"
                Destination = "tests\performance" 
            },
            # Tests (par défaut)
            @{ 
                Regex = ".*Test.*\.ps1$|.*Tests.*\.ps1$|test_.*\.py$|.*_test\.py$"
                Destination = "tests\unit" 
            }
        )
    }
)

# Fonction pour déterminer la destination d'un fichier
function Get-FileDestination {
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )
    
    foreach ($patternRule in $migrationRules) {
        $patterns = $patternRule.Pattern -split ','
        $matched = $false
        
        foreach ($pattern in $patterns) {
            if ($File.Name -like $pattern) {
                $matched = $true
                break
            }
        }
        
        if ($matched) {
            foreach ($rule in $patternRule.Rules) {
                if ($File.Name -match $rule.Regex) {
                    return $rule.Destination
                }
            }
        }
    }
    
    # Si aucune règle ne correspond, retourner null
    return $null
}

# Fonction pour créer la structure de dossiers
function Create-FolderStructure {
    # Définition des dossiers principaux
    $mainFolders = @(
        "scripts",
        "modules",
        "docs",
        "tests",
        "config",
        "assets",
        "tools",
        "logs",
        "reports",
        ".github",
        ".vscode",
        "Roadmap"
    )
    
    # Définition des sous-dossiers
    $subFolders = @{
        "scripts" = @(
            "scripts\analysis",
            "scripts\automation",
            "scripts\gui",
            "scripts\integration",
            "scripts\maintenance",
            "scripts\setup",
            "scripts\utils"
        )
        "modules" = @(
            "modules\PowerShell",
            "modules\Python",
            "modules\Common"
        )
        "docs" = @(
            "docs\guides",
            "docs\api",
            "docs\development",
            "docs\architecture"
        )
        "tests" = @(
            "tests\unit",
            "tests\integration",
            "tests\performance",
            "tests\fixtures"
        )
    }
    
    # Créer les dossiers principaux
    foreach ($folder in $mainFolders) {
        $folderPath = Join-Path -Path $Path -ChildPath $folder
        if (-not (Test-Path -Path $folderPath -PathType Container)) {
            if (-not $DryRun) {
                New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
            }
            Write-Log -Message "Dossier créé: $folder" -Level "SUCCESS"
        }
    }
    
    # Créer les sous-dossiers
    foreach ($mainFolder in $subFolders.Keys) {
        foreach ($subFolder in $subFolders[$mainFolder]) {
            $folderPath = Join-Path -Path $Path -ChildPath $subFolder
            if (-not (Test-Path -Path $folderPath -PathType Container)) {
                if (-not $DryRun) {
                    New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
                }
                Write-Log -Message "Sous-dossier créé: $subFolder" -Level "SUCCESS"
            }
        }
    }
}

# Fonction pour migrer les fichiers
function Migrate-Files {
    # Obtenir tous les fichiers à la racine et dans les dossiers non standards
    $excludedDirs = @(
        "scripts",
        "modules",
        "docs",
        "tests",
        "config",
        "assets",
        "tools",
        "logs",
        "reports",
        ".github",
        ".vscode",
        "Roadmap",
        ".git",
        "node_modules"
    )
    
    $excludedDirsPattern = ($excludedDirs | ForEach-Object { [regex]::Escape($_) }) -join "|"
    $excludeRegex = "^($excludedDirsPattern)\\.*"
    
    $allFiles = Get-ChildItem -Path $Path -File -Recurse | Where-Object {
        $relativePath = $_.FullName.Substring($Path.Length + 1)
        -not ($relativePath -match $excludeRegex) -and -not ($_.FullName -eq $logFilePath)
    }
    
    $totalFiles = $allFiles.Count
    $processedFiles = 0
    $migratedFiles = 0
    $skippedFiles = 0
    
    Write-Log -Message "Début de la migration de $totalFiles fichiers..." -Level "INFO"
    
    foreach ($file in $allFiles) {
        $processedFiles++
        $destination = Get-FileDestination -File $file
        
        if ($null -eq $destination) {
            Write-Log -Message "Aucune règle de migration pour: $($file.FullName)" -Level "WARNING"
            $skippedFiles++
            continue
        }
        
        $destinationPath = Join-Path -Path $Path -ChildPath $destination
        $destinationFile = Join-Path -Path $destinationPath -ChildPath $file.Name
        
        # Vérifier si le fichier existe déjà à la destination
        if (Test-Path -Path $destinationFile) {
            if (-not $Force) {
                Write-Log -Message "Le fichier existe déjà à la destination: $destinationFile" -Level "WARNING"
                $skippedFiles++
                continue
            }
            
            # Comparer les fichiers
            $sourceHash = Get-FileHash -Path $file.FullName -Algorithm SHA256
            $destHash = Get-FileHash -Path $destinationFile -Algorithm SHA256
            
            if ($sourceHash.Hash -eq $destHash.Hash) {
                Write-Log -Message "Le fichier est identique à la destination, suppression de la source: $($file.FullName)" -Level "INFO"
                
                if (-not $DryRun) {
                    Remove-Item -Path $file.FullName -Force
                }
                
                $migratedFiles++
                continue
            }
            
            # Renommer le fichier de destination avec un suffixe
            $newName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) + "_old" + $file.Extension
            $renamedDestination = Join-Path -Path $destinationPath -ChildPath $newName
            
            Write-Log -Message "Conflit détecté, renommage du fichier de destination: $destinationFile -> $renamedDestination" -Level "WARNING"
            
            if (-not $DryRun) {
                Rename-Item -Path $destinationFile -NewName $newName -Force
            }
        }
        
        # Déplacer le fichier
        Write-Log -Message "Migration: $($file.FullName) -> $destinationFile" -Level "INFO"
        
        if (-not $DryRun) {
            # Créer le dossier de destination s'il n'existe pas
            if (-not (Test-Path -Path $destinationPath -PathType Container)) {
                New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null
            }
            
            # Déplacer le fichier
            Move-Item -Path $file.FullName -Destination $destinationFile -Force
        }
        
        $migratedFiles++
        
        # Afficher la progression
        $progress = [math]::Round(($processedFiles / $totalFiles) * 100)
        Write-Progress -Activity "Migration des fichiers" -Status "$processedFiles / $totalFiles fichiers traités ($progress%)" -PercentComplete $progress
    }
    
    Write-Progress -Activity "Migration des fichiers" -Completed
    
    Write-Log -Message "Migration terminée: $migratedFiles fichiers migrés, $skippedFiles fichiers ignorés" -Level "SUCCESS"
}

# Fonction pour nettoyer les dossiers vides
function Clean-EmptyFolders {
    $emptyFolders = @()
    $foldersToExclude = @(".git", "node_modules")
    
    # Obtenir tous les dossiers
    $allFolders = Get-ChildItem -Path $Path -Directory -Recurse | Where-Object {
        $foldersToExclude -notcontains $_.Name
    } | Sort-Object -Property FullName -Descending
    
    foreach ($folder in $allFolders) {
        $items = Get-ChildItem -Path $folder.FullName -Force
        
        if ($null -eq $items -or $items.Count -eq 0) {
            $emptyFolders += $folder.FullName
            
            Write-Log -Message "Dossier vide détecté: $($folder.FullName)" -Level "INFO"
            
            if (-not $DryRun) {
                Remove-Item -Path $folder.FullName -Force
            }
        }
    }
    
    Write-Log -Message "Nettoyage terminé: $($emptyFolders.Count) dossiers vides supprimés" -Level "SUCCESS"
}

# Fonction principale
function Main {
    # Vérifier si le chemin existe
    if (-not (Test-Path -Path $Path -PathType Container)) {
        Write-Error "Le chemin spécifié n'existe pas: $Path"
        exit 1
    }
    
    # Créer le dossier de logs s'il n'existe pas
    $logDir = Split-Path -Path $LogPath -Parent
    $logDirPath = Join-Path -Path $Path -ChildPath $logDir
    
    if (-not (Test-Path -Path $logDirPath -PathType Container)) {
        New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
    }
    
    # Chemin complet du fichier journal
    $script:logFilePath = Join-Path -Path $Path -ChildPath $LogPath
    
    # Afficher le mode d'exécution
    if ($DryRun) {
        Write-Log -Message "Mode simulation activé. Aucune modification ne sera effectuée." -Level "WARNING"
    }
    
    # Créer la structure de dossiers
    Write-Log -Message "Création de la structure de dossiers..." -Level "INFO"
    Create-FolderStructure
    
    # Migrer les fichiers
    Write-Log -Message "Migration des fichiers..." -Level "INFO"
    Migrate-Files
    
    # Nettoyer les dossiers vides
    Write-Log -Message "Nettoyage des dossiers vides..." -Level "INFO"
    Clean-EmptyFolders
    
    # Afficher le résumé
    Write-Log -Message "Réorganisation du dépôt terminée." -Level "SUCCESS"
    Write-Log -Message "Journal des opérations: $logFilePath" -Level "INFO"
}

# Exécuter la fonction principale
try {
    Main
} catch {
    Write-Log -Message "Erreur lors de la réorganisation du dépôt: $_" -Level "ERROR"
    exit 1
}
