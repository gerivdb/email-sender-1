# Invoke-RoadmapVisualization.ps1
# Script pour générer des visualisations graphiques des roadmaps
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "projet/roadmaps/active/roadmap_active.md",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "projet/roadmaps/analysis/visualizations",
    
    [Parameter(Mandatory = $false)]
    [switch]$OpenInBrowser,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction de journalisation simplifiée
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
    }
    
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message" -ForegroundColor $color
}

# Fonction pour vérifier si Python est installé
function Test-PythonInstalled {
    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python (\d+\.\d+\.\d+)") {
            Write-Log "Python $($Matches[1]) trouvé." -Level "Info"
            return $true
        }
        else {
            Write-Log "Python non trouvé." -Level "Error"
            return $false
        }
    }
    catch {
        Write-Log "Python non trouvé." -Level "Error"
        return $false
    }
}

# Fonction pour vérifier si les dépendances Python sont installées
function Test-PythonDependencies {
    try {
        $output = python -c "import matplotlib, networkx, pyvis" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Dépendances Python trouvées." -Level "Info"
            return $true
        }
        else {
            Write-Log "Dépendances Python manquantes." -Level "Error"
            Write-Log "Installez-les avec: pip install matplotlib networkx pyvis" -Level "Info"
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors de la vérification des dépendances Python: $_" -Level "Error"
        return $false
    }
}

# Fonction pour générer les visualisations
function Invoke-Visualization {
    param (
        [string]$RoadmapPath,
        [string]$OutputDirectory,
        [switch]$Force
    )
    
    Write-Log "Génération des visualisations pour $RoadmapPath..." -Level "Info"
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Log "Le fichier $RoadmapPath n'existe pas." -Level "Error"
        return $null
    }
    
    # Vérifier si Python est installé
    if (-not (Test-PythonInstalled)) {
        return $null
    }
    
    # Vérifier si les dépendances Python sont installées
    if (-not (Test-PythonDependencies)) {
        return $null
    }
    
    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputDirectory)) {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    }
    
    # Construire la commande Python
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Generate-RoadmapVisualization.py"
    $command = "python `"$scriptPath`" --file `"$RoadmapPath`" --output-dir `"$OutputDirectory`""
    
    # Exécuter la commande
    Write-Log "Exécution de la commande: $command" -Level "Info"
    Invoke-Expression $command
    
    if ($LASTEXITCODE -eq 0) {
        # Déterminer le chemin vers le fichier index.html
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($RoadmapPath)
        $indexPath = Join-Path -Path $OutputDirectory -ChildPath "$fileName/index.html"
        
        Write-Log "Visualisations générées avec succès." -Level "Success"
        Write-Log "Visualisations disponibles dans $indexPath" -Level "Info"
        
        return $indexPath
    }
    else {
        Write-Log "Erreur lors de la génération des visualisations." -Level "Error"
        return $null
    }
}

# Fonction principale
function Invoke-RoadmapVisualization {
    param (
        [string]$RoadmapPath,
        [string]$OutputDirectory,
        [switch]$OpenInBrowser,
        [switch]$Force
    )
    
    # Générer les visualisations
    $indexPath = Invoke-Visualization -RoadmapPath $RoadmapPath -OutputDirectory $OutputDirectory -Force:$Force
    
    # Ouvrir dans le navigateur si demandé
    if ($indexPath -and $OpenInBrowser) {
        Write-Log "Ouverture des visualisations dans le navigateur..." -Level "Info"
        Start-Process $indexPath
    }
    
    return $indexPath
}

# Exécution principale
try {
    $result = Invoke-RoadmapVisualization -RoadmapPath $RoadmapPath -OutputDirectory $OutputDirectory -OpenInBrowser:$OpenInBrowser -Force:$Force
    
    # Retourner le résultat
    return $result
}
catch {
    Write-Log "Erreur lors de la génération des visualisations : $_" -Level "Error"
    throw $_
}
