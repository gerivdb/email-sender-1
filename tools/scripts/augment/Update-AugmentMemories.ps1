<#
.SYNOPSIS
    Script pour mettre Ã  jour les MEMORIES d'Augment avec une version optimisÃ©e.

.DESCRIPTION
    Ce script utilise le module AugmentMemoriesManager pour gÃ©nÃ©rer et mettre Ã  jour
    les MEMORIES d'Augment dans l'emplacement utilisÃ© par VS Code.

.NOTES
    Version: 1.0
    Date: 2025-04-20
    Auteur: Augment Agent
#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$RunTests,
    
    [Parameter()]
    [string]$OutputPath,
    
    [Parameter()]
    [switch]$ExportToVSCode
)

# Importer le module AugmentMemoriesManager
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "AugmentMemoriesManager.ps1"
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module AugmentMemoriesManager.ps1 non trouvÃ© Ã  l'emplacement: $modulePath"
    exit 1
}

# Importer le module
. $modulePath

# ExÃ©cuter les tests si demandÃ©
if ($RunTests) {
    Write-Host "ExÃ©cution des tests TDD pour le gestionnaire de MEMORIES..." -ForegroundColor Cyan
    
    # VÃ©rifier si Pester est installÃ©
    if (-not (Get-Module -ListAvailable -Name Pester)) {
        Write-Warning "Module Pester non trouvÃ©. Installation en cours..."
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    
    # Importer Pester
    Import-Module Pester
    
    # ExÃ©cuter les tests
    Invoke-MemoriesManagerTests
    
    Write-Host "Tests terminÃ©s." -ForegroundColor Green
}

# Mettre Ã  jour les MEMORIES
if ($PSBoundParameters.ContainsKey('OutputPath')) {
    Write-Host "Mise Ã  jour des MEMORIES d'Augment dans le fichier: $OutputPath" -ForegroundColor Cyan
    Update-AugmentMemories -OutputPath $OutputPath
}
elseif ($ExportToVSCode) {
    Write-Host "Exportation des MEMORIES d'Augment vers VS Code..." -ForegroundColor Cyan
    Export-MemoriesToVSCode
}
else {
    # Par dÃ©faut, gÃ©nÃ©rer dans le dossier courant
    $defaultOutput = Join-Path -Path $PSScriptRoot -ChildPath "augment_memories.json"
    Write-Host "Mise Ã  jour des MEMORIES d'Augment dans le fichier par dÃ©faut: $defaultOutput" -ForegroundColor Cyan
    Update-AugmentMemories -OutputPath $defaultOutput
}

Write-Host "OpÃ©ration terminÃ©e avec succÃ¨s." -ForegroundColor Green
