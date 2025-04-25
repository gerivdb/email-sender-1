#Requires -Version 5.1
<#
.SYNOPSIS
    Organise les fichiers en vrac à la racine du dépôt dans les sous-dossiers appropriés.
.DESCRIPTION
    Ce script identifie les fichiers en vrac à la racine du dépôt et les déplace
    dans les sous-dossiers appropriés selon leur type et leur fonction.
.PARAMETER DryRun
    Si spécifié, simule les opérations sans effectuer de déplacements réels.
.EXAMPLE
    .\Organize-RootFiles.ps1
    # Organise les fichiers à la racine du dépôt.
.EXAMPLE
    .\Organize-RootFiles.ps1 -DryRun
    # Simule l'organisation des fichiers sans effectuer de déplacements réels.
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2023-05-15
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

# Fonction pour journaliser les messages
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colorMap[$Level]
}

# Fonction pour déplacer un fichier
function Move-FileToDestination {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory = $true)]
        [string]$DestinationFolder,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )
    
    try {
        $fileName = Split-Path $SourcePath -Leaf
        $destinationPath = Join-Path $DestinationFolder $fileName
        
        # Créer le dossier de destination s'il n'existe pas
        if (-not (Test-Path -Path $DestinationFolder)) {
            if ($DryRun) {
                Write-Log -Message "Création du dossier: $DestinationFolder (simulation)" -Level "INFO"
            } else {
                New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
                Write-Log -Message "Dossier créé: $DestinationFolder" -Level "SUCCESS"
            }
        }
        
        # Vérifier si le fichier existe déjà à destination
        if (Test-Path -Path $destinationPath) {
            Write-Log -Message "Le fichier $fileName existe déjà dans $DestinationFolder" -Level "WARNING"
            return
        }
        
        # Déplacer le fichier
        if ($DryRun) {
            Write-Log -Message "Déplacement de $fileName vers $DestinationFolder (simulation)" -Level "INFO"
        } else {
            Move-Item -Path $SourcePath -Destination $destinationPath -Force
            Write-Log -Message "Fichier déplacé: $fileName -> $DestinationFolder" -Level "SUCCESS"
        }
    } catch {
        Write-Log -Message "Erreur lors du déplacement de $SourcePath vers $DestinationFolder : $_" -Level "ERROR"
    }
}

# Fichiers à conserver à la racine
$keepFiles = @(
    "README.md",
    ".gitignore",
    ".gitattributes",
    "package.json",
    "package-lock.json",
    "CHANGELOG.md",
    "LICENSE",
    "CONTRIBUTING.md",
    "CODE_OF_CONDUCT.md"
)

# Règles d'organisation des fichiers
$organizationRules = @(
    # Format: [pattern, destination, description]
    # Tests
    @("*.Tests.ps1", "tests", "Fichiers de tests PowerShell"),
    
    # Fichiers de sauvegarde
    @("*.bak", "backups", "Fichiers de sauvegarde"),
    
    # Scripts Python
    @("*.py", "scripts/python", "Scripts Python"),
    @("fix_roadmap.py", "scripts/python/roadmap", "Scripts Python pour roadmap"),
    @("format_roadmap_*.py", "scripts/python/roadmap", "Scripts Python pour roadmap"),
    @("test_format_roadmap_*.py", "scripts/python/roadmap", "Tests Python pour roadmap"),
    @("mcp_*.py", "scripts/python/mcp", "Scripts Python pour MCP"),
    
    # Scripts PowerShell
    @("*.ps1", "scripts", "Scripts PowerShell"),
    @("Run-FunctionalTests.ps1", "scripts/tests", "Scripts de tests fonctionnels"),
    @("Start-MCPManager.ps1", "scripts/mcp", "Scripts MCP"),
    @("TestOmnibus-*.ps1", "scripts/tests", "Scripts TestOmnibus"),
    @("test_extension*.ps1", "scripts/tests", "Scripts de tests d'extension"),
    
    # Modules PowerShell
    @("*.psm1", "modules", "Modules PowerShell"),
    
    # Fichiers de documentation
    @("OPTIMIZATIONS.md", "docs", "Documentation d'optimisation"),
    @("journal.md", "journal", "Fichiers de journal"),
    @("journal_de_bord_*.md", "journal", "Fichiers de journal"),
    @("output_roadmap.md", "Roadmap", "Fichiers de roadmap"),
    @("README_*.md", "docs", "Documentation README"),
    
    # Fichiers de configuration
    @("*.json.improved", "config", "Fichiers de configuration améliorés"),
    
    # Fichiers de journalisation
    @("*.log", "logs", "Fichiers de journalisation"),
    
    # Fichiers de données
    @("*.txt", "data", "Fichiers texte"),
    @("test_results.json", "data", "Fichiers de résultats de tests")
)

# Début du script principal
Write-Log -Message "=== Organisation des fichiers à la racine du dépôt ===" -Level "INFO"

if ($DryRun) {
    Write-Log -Message "Mode simulation activé - aucun fichier ne sera déplacé" -Level "WARNING"
}

# Obtenir tous les fichiers à la racine
$rootFiles = Get-ChildItem -Path . -File

Write-Log -Message "Nombre de fichiers à la racine: $($rootFiles.Count)" -Level "INFO"

# Compteurs pour le rapport
$processedCount = 0
$skippedCount = 0
$movedCount = 0

foreach ($file in $rootFiles) {
    $processedCount++
    $fileName = $file.Name
    
    # Vérifier si le fichier doit être conservé à la racine
    if ($keepFiles -contains $fileName) {
        Write-Log -Message "Conservation à la racine: $fileName" -Level "INFO"
        $skippedCount++
        continue
    }
    
    $moved = $false
    
    # Appliquer les règles d'organisation
    foreach ($rule in $organizationRules) {
        $pattern = $rule[0]
        $destination = $rule[1]
        $description = $rule[2]
        
        if ($fileName -like $pattern) {
            Move-FileToDestination -SourcePath $file.FullName -DestinationFolder $destination -Description $description -DryRun:$DryRun
            $moved = $true
            $movedCount++
            break
        }
    }
    
    # Si aucune règle ne correspond, déplacer dans un dossier par défaut selon l'extension
    if (-not $moved) {
        $extension = $file.Extension
        
        switch ($extension) {
            ".ps1" { 
                Move-FileToDestination -SourcePath $file.FullName -DestinationFolder "scripts" -Description "Scripts PowerShell (par défaut)" -DryRun:$DryRun
                $movedCount++
            }
            ".py" { 
                Move-FileToDestination -SourcePath $file.FullName -DestinationFolder "scripts/python" -Description "Scripts Python (par défaut)" -DryRun:$DryRun
                $movedCount++
            }
            ".md" { 
                Move-FileToDestination -SourcePath $file.FullName -DestinationFolder "docs" -Description "Documentation (par défaut)" -DryRun:$DryRun
                $movedCount++
            }
            ".json" { 
                Move-FileToDestination -SourcePath $file.FullName -DestinationFolder "config" -Description "Configuration (par défaut)" -DryRun:$DryRun
                $movedCount++
            }
            default {
                Write-Log -Message "Aucune règle pour $fileName (extension: $extension)" -Level "WARNING"
                $skippedCount++
            }
        }
    }
}

# Rapport final
Write-Log -Message "=== Rapport d'organisation ===" -Level "INFO"
Write-Log -Message "Fichiers traités: $processedCount" -Level "INFO"
Write-Log -Message "Fichiers déplacés: $movedCount" -Level "SUCCESS"
Write-Log -Message "Fichiers conservés/ignorés: $skippedCount" -Level "INFO"

if ($DryRun) {
    Write-Log -Message "Mode simulation - Aucun fichier n'a été réellement déplacé" -Level "WARNING"
    Write-Log -Message "Pour effectuer les déplacements, exécutez le script sans le paramètre -DryRun" -Level "INFO"
} else {
    Write-Log -Message "Organisation terminée avec succès" -Level "SUCCESS"
}
