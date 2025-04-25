<#
.SYNOPSIS
    Script pour mettre à jour les MEMORIES d'Augment avec une version optimisée.

.DESCRIPTION
    Ce script utilise le module AugmentMemoriesManager pour générer et mettre à jour
    les MEMORIES d'Augment dans l'emplacement utilisé par VS Code.

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
    Write-Error "Module AugmentMemoriesManager.ps1 non trouvé à l'emplacement: $modulePath"
    exit 1
}

# Importer le module
. $modulePath

# Exécuter les tests si demandé
if ($RunTests) {
    Write-Host "Exécution des tests TDD pour le gestionnaire de MEMORIES..." -ForegroundColor Cyan
    
    # Vérifier si Pester est installé
    if (-not (Get-Module -ListAvailable -Name Pester)) {
        Write-Warning "Module Pester non trouvé. Installation en cours..."
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    
    # Importer Pester
    Import-Module Pester
    
    # Exécuter les tests
    Invoke-MemoriesManagerTests
    
    Write-Host "Tests terminés." -ForegroundColor Green
}

# Mettre à jour les MEMORIES
if ($PSBoundParameters.ContainsKey('OutputPath')) {
    Write-Host "Mise à jour des MEMORIES d'Augment dans le fichier: $OutputPath" -ForegroundColor Cyan
    Update-AugmentMemories -OutputPath $OutputPath
}
elseif ($ExportToVSCode) {
    Write-Host "Exportation des MEMORIES d'Augment vers VS Code..." -ForegroundColor Cyan
    Export-MemoriesToVSCode
}
else {
    # Par défaut, générer dans le dossier courant
    $defaultOutput = Join-Path -Path $PSScriptRoot -ChildPath "augment_memories.json"
    Write-Host "Mise à jour des MEMORIES d'Augment dans le fichier par défaut: $defaultOutput" -ForegroundColor Cyan
    Update-AugmentMemories -OutputPath $defaultOutput
}

Write-Host "Opération terminée avec succès." -ForegroundColor Green
