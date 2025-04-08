# Script pour permettre à Augment de déclarer des tâches terminées

param (
    [Parameter(Mandatory = $true)]
    [string]$Declaration
)

# Importer le module d'intégration
$integrationPath = Join-Path -Path $PSScriptRoot -ChildPath "Augment-RoadmapIntegration.ps1"
if (Test-Path -Path $integrationPath) {
    . $integrationPath
}
else {
    Write-Error "Le module d'intégration est introuvable: $integrationPath"
    exit 1
}

# Initialiser l'intégration
Initialize-AugmentRoadmapIntegration

# Traiter la déclaration
$result = Invoke-AugmentDeclaration -Declaration $Declaration

if ($result) {
    Write-Host "La déclaration a été traitée avec succès."
    Write-Host "La roadmap a été mise à jour."
}
else {
    Write-Host "La déclaration n'a pas pu être traitée."
    Write-Host "Formats acceptés:"
    Write-Host "- 'Phase [nom de la phase] terminée'"
    Write-Host "- 'Tâche [nom de la tâche] dans la phase [nom de la phase] terminée'"
    Write-Host "- 'Sous-tâche [nom de la sous-tâche] dans la tâche [nom de la tâche] de la phase [nom de la phase] terminée'"
}
