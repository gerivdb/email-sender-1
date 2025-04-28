#Requires -Version 5.1
<#
.SYNOPSIS
    Organise les fichiers en vrac Ã  la racine du dÃ©pÃ´t dans les sous-dossiers appropriÃ©s.
.DESCRIPTION
    Ce script identifie les fichiers en vrac Ã  la racine du dÃ©pÃ´t et les dÃ©place
    dans les sous-dossiers appropriÃ©s selon leur type et leur fonction.
.PARAMETER DryRun
    Si spÃ©cifiÃ©, simule les opÃ©rations sans effectuer de dÃ©placements rÃ©els.
.EXAMPLE
    .\Organize-RootFiles.ps1
    # Organise les fichiers Ã  la racine du dÃ©pÃ´t.
.EXAMPLE
    .\Organize-RootFiles.ps1 -DryRun
    # Simule l'organisation des fichiers sans effectuer de dÃ©placements rÃ©els.
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

# Fonction pour dÃ©placer un fichier
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
        
        # CrÃ©er le dossier de destination s'il n'existe pas
        if (-not (Test-Path -Path $DestinationFolder)) {
            if ($DryRun) {
                Write-Log -Message "CrÃ©ation du dossier: $DestinationFolder (simulation)" -Level "INFO"
            } else {
                New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
                Write-Log -Message "Dossier crÃ©Ã©: $DestinationFolder" -Level "SUCCESS"
            }
        }
        
        # VÃ©rifier si le fichier existe dÃ©jÃ  Ã  destination
        if (Test-Path -Path $destinationPath) {
            Write-Log -Message "Le fichier $fileName existe dÃ©jÃ  dans $DestinationFolder" -Level "WARNING"
            return
        }
        
        # DÃ©placer le fichier
        if ($DryRun) {
            Write-Log -Message "DÃ©placement de $fileName vers $DestinationFolder (simulation)" -Level "INFO"
        } else {
            Move-Item -Path $SourcePath -Destination $destinationPath -Force
            Write-Log -Message "Fichier dÃ©placÃ©: $fileName -> $DestinationFolder" -Level "SUCCESS"
        }
    } catch {
        Write-Log -Message "Erreur lors du dÃ©placement de $SourcePath vers $DestinationFolder : $_" -Level "ERROR"
    }
}

# Fichiers Ã  conserver Ã  la racine
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

# RÃ¨gles d'organisation des fichiers
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
    @("Start-MCPManager.ps1", "development/scripts/mcp", "Scripts MCP"),
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
    @("*.json.improved", "config", "Fichiers de configuration amÃ©liorÃ©s"),
    
    # Fichiers de journalisation
    @("*.log", "logs", "Fichiers de journalisation"),
    
    # Fichiers de donnÃ©es
    @("*.txt", "data", "Fichiers texte"),
    @("test_results.json", "data", "Fichiers de rÃ©sultats de tests")
)

# DÃ©but du script principal
Write-Log -Message "=== Organisation des fichiers Ã  la racine du dÃ©pÃ´t ===" -Level "INFO"

if ($DryRun) {
    Write-Log -Message "Mode simulation activÃ© - aucun fichier ne sera dÃ©placÃ©" -Level "WARNING"
}

# Obtenir tous les fichiers Ã  la racine
$rootFiles = Get-ChildItem -Path . -File

Write-Log -Message "Nombre de fichiers Ã  la racine: $($rootFiles.Count)" -Level "INFO"

# Compteurs pour le rapport
$processedCount = 0
$skippedCount = 0
$movedCount = 0

foreach ($file in $rootFiles) {
    $processedCount++
    $fileName = $file.Name
    
    # VÃ©rifier si le fichier doit Ãªtre conservÃ© Ã  la racine
    if ($keepFiles -contains $fileName) {
        Write-Log -Message "Conservation Ã  la racine: $fileName" -Level "INFO"
        $skippedCount++
        continue
    }
    
    $moved = $false
    
    # Appliquer les rÃ¨gles d'organisation
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
    
    # Si aucune rÃ¨gle ne correspond, dÃ©placer dans un dossier par dÃ©faut selon l'extension
    if (-not $moved) {
        $extension = $file.Extension
        
        switch ($extension) {
            ".ps1" { 
                Move-FileToDestination -SourcePath $file.FullName -DestinationFolder "scripts" -Description "Scripts PowerShell (par dÃ©faut)" -DryRun:$DryRun
                $movedCount++
            }
            ".py" { 
                Move-FileToDestination -SourcePath $file.FullName -DestinationFolder "development/scripts/python" -Description "Scripts Python (par dÃ©faut)" -DryRun:$DryRun
                $movedCount++
            }
            ".md" { 
                Move-FileToDestination -SourcePath $file.FullName -DestinationFolder "docs" -Description "Documentation (par dÃ©faut)" -DryRun:$DryRun
                $movedCount++
            }
            ".json" { 
                Move-FileToDestination -SourcePath $file.FullName -DestinationFolder "config" -Description "Configuration (par dÃ©faut)" -DryRun:$DryRun
                $movedCount++
            }
            default {
                Write-Log -Message "Aucune rÃ¨gle pour $fileName (extension: $extension)" -Level "WARNING"
                $skippedCount++
            }
        }
    }
}

# Rapport final
Write-Log -Message "=== Rapport d'organisation ===" -Level "INFO"
Write-Log -Message "Fichiers traitÃ©s: $processedCount" -Level "INFO"
Write-Log -Message "Fichiers dÃ©placÃ©s: $movedCount" -Level "SUCCESS"
Write-Log -Message "Fichiers conservÃ©s/ignorÃ©s: $skippedCount" -Level "INFO"

if ($DryRun) {
    Write-Log -Message "Mode simulation - Aucun fichier n'a Ã©tÃ© rÃ©ellement dÃ©placÃ©" -Level "WARNING"
    Write-Log -Message "Pour effectuer les dÃ©placements, exÃ©cutez le script sans le paramÃ¨tre -DryRun" -Level "INFO"
} else {
    Write-Log -Message "Organisation terminÃ©e avec succÃ¨s" -Level "SUCCESS"
}
