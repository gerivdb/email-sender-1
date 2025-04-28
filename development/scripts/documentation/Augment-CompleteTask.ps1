# Script pour permettre Ã  Augment de dÃ©clarer des tÃ¢ches terminÃ©es

param (
    [Parameter(Mandatory = $true)]
    [string]$Declaration
)

# Importer le module d'intÃ©gration
$integrationPath = Join-Path -Path $PSScriptRoot -ChildPath "Augment-RoadmapIntegration.ps1"
if (Test-Path -Path $integrationPath) {
    . $integrationPath
}
else {
    Write-Error "Le module d'intÃ©gration est introuvable: $integrationPath"
    exit 1
}

# Initialiser l'intÃ©gration
Initialize-AugmentRoadmapIntegration

# Traiter la dÃ©claration
$result = Invoke-AugmentDeclaration -Declaration $Declaration

if ($result) {
    Write-Host "La dÃ©claration a Ã©tÃ© traitÃ©e avec succÃ¨s."
    Write-Host "La roadmap a Ã©tÃ© mise Ã  jour."
}
else {
    Write-Host "La dÃ©claration n'a pas pu Ãªtre traitÃ©e."
    Write-Host "Formats acceptÃ©s:"
    Write-Host "- 'Phase [nom de la phase] terminÃ©e'"
    Write-Host "- 'TÃ¢che [nom de la tÃ¢che] dans la phase [nom de la phase] terminÃ©e'"
    Write-Host "- 'Sous-tÃ¢che [nom de la sous-tÃ¢che] dans la tÃ¢che [nom de la tÃ¢che] de la phase [nom de la phase] terminÃ©e'"
}
