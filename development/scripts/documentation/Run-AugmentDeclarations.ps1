# Script pour exÃ©cuter les dÃ©clarations d'Augment

# Importer le module d'intÃ©gration
$integrationPath = Join-Path -Path $PSScriptRoot -ChildPath "Augment-RoadmapIntegration.ps1"
if (Test-Path -Path $integrationPath) {
    . $integrationPath
}
else {
    Write-Error "Le module d'intÃ©gration est introuvable: $integrationPath"
    exit 1
}

# Chemin du fichier de dÃ©clarations
$declarationsFile = Join-Path -Path $PSScriptRoot -ChildPath "augment-declarations.txt"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $declarationsFile)) {
    Write-Error "Le fichier de dÃ©clarations n'existe pas: $declarationsFile"
    exit 1
}

# Lire les dÃ©clarations
$declarations = Get-Content -Path $declarationsFile

# Traiter chaque dÃ©claration
foreach ($declaration in $declarations) {
    if (-not [string]::IsNullOrWhiteSpace($declaration)) {
        Write-Host "Traitement de la dÃ©claration: $declaration"
        
        # Analyser la dÃ©claration
        if ($declaration -match "(?i)phase\s+(.+?)\s+terminÃ©e") {
            $phaseTitle = $Matches[1].Trim()
            Write-Host "Phase identifiÃ©e: $phaseTitle"
            
            # Marquer la phase comme terminÃ©e
            $result = Complete-AugmentPhase -PhaseTitle $phaseTitle -Comment "DÃ©claration automatique par Augment"
            
            if ($result) {
                Write-Host "Phase marquÃ©e comme terminÃ©e avec succÃ¨s."
            }
            else {
                Write-Host "Ã‰chec du marquage de la phase comme terminÃ©e."
            }
        }
        else {
            Write-Host "Format de dÃ©claration non reconnu."
        }
        
        Write-Host ""
    }
}

# Mettre Ã  jour la roadmap
Write-Host "Mise Ã  jour finale de la roadmap..."
$updaterPath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapUpdater.ps1"
if (Test-Path -Path $updaterPath) {
    . $updaterPath
    Update-Roadmap
}
else {
    Write-Host "Module de mise Ã  jour de la roadmap introuvable: $updaterPath"
}

Write-Host "Traitement des dÃ©clarations terminÃ©."
