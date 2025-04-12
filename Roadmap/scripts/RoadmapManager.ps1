# Script de gestion de la roadmap
# Ce script permet d'accéder à toutes les fonctionnalités de gestion de la roadmap

param (
    [string]$RoadmapPath = "Roadmap\roadmap_perso.md",
    [switch]$Organize = $false,
    [switch]$Execute = $false,
    [switch]$Analyze = $false,
    [switch]$GitUpdate = $false,
    [switch]$Cleanup = $false,
    [switch]$FixScripts = $false,
    [switch]$Help = $false,
    [string]$CommitMessage = "Update roadmap"
)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()

# Fonction pour gérer les opérations Git
function Invoke-GitOperations {
    param (
        [string]$CommitMessage
    )

    try {
        Write-Host "Exécution des opérations Git..."
        git add .
        git commit -m $CommitMessage --no-verify
        git push --no-verify
        Write-Host "Opérations Git terminées avec succès"
    } catch {
        Write-Error "Erreur lors des opérations Git: $_"
    }
}

# Fonction principale pour exécuter la roadmap
function Invoke-ExecuteRoadmap {
    Invoke-RoadmapScript -ScriptName "StartRoadmapExecution" -Description "Exécution de la roadmap" -Parameters @{
        RoadmapPath = $RoadmapPath
        AutoExecute = $Execute
        AutoUpdate  = $GitUpdate
    }

    if ($GitUpdate) {
        Invoke-GitOperations -CommitMessage $CommitMessage
    }
}

# [...] (le reste du fichier reste inchangé)
