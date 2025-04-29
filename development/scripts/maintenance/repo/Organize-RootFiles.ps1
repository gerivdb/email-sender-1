#Requires -Version 5.1
<#
.SYNOPSIS
    Organise les fichiers en vrac ÃƒÂ  la racine du dÃƒÂ©pÃƒÂ´t dans les sous-dossiers appropriÃƒÂ©s.
.DESCRIPTION
    Ce script identifie les fichiers en vrac ÃƒÂ  la racine du dÃƒÂ©pÃƒÂ´t et les dÃƒÂ©place
    dans les sous-dossiers appropriÃƒÂ©s selon leur type et leur fonction.
.PARAMETER DryRun
    Si spÃƒÂ©cifiÃƒÂ©, simule les opÃƒÂ©rations sans effectuer de dÃƒÂ©placements rÃƒÂ©els.
.EXAMPLE
    .\Organize-RootFiles.ps1
    # Organise les fichiers ÃƒÂ  la racine du dÃƒÂ©pÃƒÂ´t.
.EXAMPLE
    .\Organize-RootFiles.ps1 -DryRun
    # Simule l'organisation des fichiers sans effectuer de dÃƒÂ©placements rÃƒÂ©els.
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

# Fonction pour dÃƒÂ©placer un fichier
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
        
        # CrÃƒÂ©er le dossier de destination s'il n'existe pas
        if (-not (Test-Path -Path $DestinationFolder)) {
            if ($DryRun) {
                Write-Log -Message "CrÃƒÂ©ation du dossier: $DestinationFolder (simulation)" -Level "INFO"
            } else {
                New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
                Write-Log -Message "Dossier crÃƒÂ©ÃƒÂ©: $DestinationFolder" -Level "SUCCESS"
            }
        }
        
        # VÃƒÂ©rifier si le fichier existe dÃƒÂ©jÃƒÂ  ÃƒÂ  destination
        if (Test-Path -Path $destinationPath) {
            Write-Log -Message "Le fichier $fileName existe dÃƒÂ©jÃƒÂ  dans $DestinationFolder" -Level "WARNING"
            return
        }
        
        # DÃƒÂ©placer le fichier
        if ($DryRun) {
            Write-Log -Message "DÃƒÂ©placement de $fileName vers $DestinationFolder (simulation)" -Level "INFO"
        } else {
            Move-Item -Path $SourcePath -Destination $destinationPath -Force
            Write-Log -Message "Fichier dÃƒÂ©placÃƒÂ©: $fileName -> $DestinationFolder" -Level "SUCCESS"
        }
    } catch {
        Write-Log -Message "Erreur lors du dÃƒÂ©placement de $SourcePath vers $DestinationFolder : $_" -Level "ERROR"
    }
}

# Fichiers ÃƒÂ  conserver ÃƒÂ  la racine
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

# RÃƒÂ¨gles d'organisation des fichiers
$organizationRules = @(
    # Format: [pattern, destination, description]
    # Tests
    @("*.Tests.ps1", "tests", "Fichiers de tests PowerShell"),
    
    # Fichiers de sauvegarde
    @("*.bak", "backups", "Fichiers de sauvegarde"),
    
    # Scripts Python
    @("*.py", "development/scripts/python", "Scripts Python"),
    @("fix_roadmap.py", "development/scripts/python/roadmap", "Scripts Python pour roadmap"),
    @("format_roadmap_*.py", "development/scripts/python/roadmap", "Scripts Python pour roadmap"),
    @("test_format_roadmap_*.py", "development/scripts/python/roadmap", "Tests Python pour roadmap"),
    @("mcp_*.py", "development/scripts/python/mcp", "Scripts Python pour MCP"),
    
    # Scripts PowerShell
    @("*.ps1", "scripts", "Scripts PowerShell"),
    @("Run-FunctionalTests.ps1", "development/scripts/tests", "Scripts de tests fonctionnels"),
    @("mcp-manager.ps1", "development/scripts/mcp", "Scripts MCP"),
    @("TestOmnibus-*.ps1", "development/scripts/tests", "Scripts TestOmnibus"),
    @("test_extension*.ps1", "development/scripts/tests", "Scripts de tests d'extension"),
    
    # Modules PowerShell
    @("*.psm1", "modules", "Modules PowerShell"),
    
    # Fichiers de documentation
    @("OPTIMIZATIONS.md", "docs", "Documentation d'optimisation"),
    @("journal.md", "journal", "Fichiers de journal"),
    @("journal_de_bord_*.md", "journal", "Fichiers de journal"),
    @("output_roadmap.md", "Roadmap", "Fichiers de roadmap"),
    @("README_*.md", "docs", "Documentation README"),
    
    # Fichiers de configuration
    @("*.json.improved", "config", "Fichiers de configuration amÃƒÂ©liorÃƒÂ©s"),
    
    # Fichiers de journalisation
    @("*.log", "logs", "Fichiers de journalisation"),
    
    # Fichiers de donnÃƒÂ©es
    @("*.txt", "data", "Fichiers texte"),
    @("test_results.json", "data", "Fichiers de rÃƒÂ©sultats de tests")
)

# DÃƒÂ©but du script principal
Write-Log -Message "=== Organisation des fichiers ÃƒÂ  la racine du dÃƒÂ©pÃƒÂ´t ===" -Level "INFO"

if ($DryRun) {
    Write-Log -Message "Mode simulation activÃƒÂ© - aucun fichier ne sera dÃƒÂ©placÃƒÂ©" -Level "WARNING"
}

# Obtenir tous les fichiers ÃƒÂ  la racine
$rootFiles = Get-ChildItem -Path . -File

Write-Log -Message "Nombre de fichiers ÃƒÂ  la racine: $($rootFiles.Count)" -Level "INFO"

# Compteurs pour le rapport
$processedCount = 0
$skippedCount = 0
$movedCount = 0

foreach ($file in $rootFiles) {
    $processedCount++
    $fileName = $file.Name
    
    # VÃƒÂ©rifier si le fichier doit ÃƒÂªtre conservÃƒÂ© ÃƒÂ  la racine
    if ($keepFiles -contains $fileName) {
        Write-Log -Message "Conservation ÃƒÂ  la racine: $fileName" -Level "INFO"
        $skippedCount++
        continue
    }
    
    $moved = $false
    
    # Appliquer les rÃƒÂ¨gles d'organisation
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
    
    # Si aucune rÃƒÂ¨gle ne correspond, dÃƒÂ©placer dans un dossier par dÃƒÂ©faut selon l'extension
    if (-not $moved) {
        $extension = $file.Extension
        
        switch ($extension) {
            ".ps1" { 
                Move-FileToDestination -SourcePath $file.FullName -DestinationFolder "scripts" -Description "Scripts PowerShell (par dÃƒÂ©faut)" -DryRun:$DryRun
                $movedCount++
            }
            ".py" { 
                Move-FileToDestination -SourcePath $file.FullName -DestinationFolder "development/scripts/python" -Description "Scripts Python (par dÃƒÂ©faut)" -DryRun:$DryRun
                $movedCount++
            }
            ".md" { 
                Move-FileToDestination -SourcePath $file.FullName -DestinationFolder "docs" -Description "Documentation (par dÃƒÂ©faut)" -DryRun:$DryRun
                $movedCount++
            }
            ".json" { 
                Move-FileToDestination -SourcePath $file.FullName -DestinationFolder "config" -Description "Configuration (par dÃƒÂ©faut)" -DryRun:$DryRun
                $movedCount++
            }
            default {
                Write-Log -Message "Aucune rÃƒÂ¨gle pour $fileName (extension: $extension)" -Level "WARNING"
                $skippedCount++
            }
        }
    }
}

# Rapport final
Write-Log -Message "=== Rapport d'organisation ===" -Level "INFO"
Write-Log -Message "Fichiers traitÃƒÂ©s: $processedCount" -Level "INFO"
Write-Log -Message "Fichiers dÃƒÂ©placÃƒÂ©s: $movedCount" -Level "SUCCESS"
Write-Log -Message "Fichiers conservÃƒÂ©s/ignorÃƒÂ©s: $skippedCount" -Level "INFO"

if ($DryRun) {
    Write-Log -Message "Mode simulation - Aucun fichier n'a ÃƒÂ©tÃƒÂ© rÃƒÂ©ellement dÃƒÂ©placÃƒÂ©" -Level "WARNING"
    Write-Log -Message "Pour effectuer les dÃƒÂ©placements, exÃƒÂ©cutez le script sans le paramÃƒÂ¨tre -DryRun" -Level "INFO"
} else {
    Write-Log -Message "Organisation terminÃƒÂ©e avec succÃƒÂ¨s" -Level "SUCCESS"
}

