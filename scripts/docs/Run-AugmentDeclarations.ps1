# Script pour exécuter les déclarations d'Augment

# Importer le module d'intégration
$integrationPath = Join-Path -Path $PSScriptRoot -ChildPath "Augment-RoadmapIntegration.ps1"
if (Test-Path -Path $integrationPath) {
    . $integrationPath
}
else {
    Write-Error "Le module d'intégration est introuvable: $integrationPath"
    exit 1
}

# Chemin du fichier de déclarations
$declarationsFile = Join-Path -Path $PSScriptRoot -ChildPath "augment-declarations.txt"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $declarationsFile)) {
    Write-Error "Le fichier de déclarations n'existe pas: $declarationsFile"
    exit 1
}

# Lire les déclarations
$declarations = Get-Content -Path $declarationsFile

# Traiter chaque déclaration
foreach ($declaration in $declarations) {
    if (-not [string]::IsNullOrWhiteSpace($declaration)) {
        Write-Host "Traitement de la déclaration: $declaration"
        
        # Analyser la déclaration
        if ($declaration -match "(?i)phase\s+(.+?)\s+terminée") {
            $phaseTitle = $Matches[1].Trim()
            Write-Host "Phase identifiée: $phaseTitle"
            
            # Marquer la phase comme terminée
            $result = Complete-AugmentPhase -PhaseTitle $phaseTitle -Comment "Déclaration automatique par Augment"
            
            if ($result) {
                Write-Host "Phase marquée comme terminée avec succès."
            }
            else {
                Write-Host "Échec du marquage de la phase comme terminée."
            }
        }
        else {
            Write-Host "Format de déclaration non reconnu."
        }
        
        Write-Host ""
    }
}

# Mettre à jour la roadmap
Write-Host "Mise à jour finale de la roadmap..."
$updaterPath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapUpdater.ps1"
if (Test-Path -Path $updaterPath) {
    . $updaterPath
    Update-Roadmap
}
else {
    Write-Host "Module de mise à jour de la roadmap introuvable: $updaterPath"
}

Write-Host "Traitement des déclarations terminé."
