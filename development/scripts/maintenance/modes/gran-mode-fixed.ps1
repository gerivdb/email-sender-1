# Mode GRAN - Granularisation des tâches
# Ce script permet de décomposer une tâche de roadmap en sous-tâches plus granulaires
# directement dans le document.

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Simple", "Medium", "Complex", "Auto")]
    [string]$ComplexityLevel = "Auto",

    [Parameter(Mandatory = $false)]
    [string]$Domain = "None",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Spaces2", "Spaces4", "Tab", "Auto")]
    [string]$IndentationStyle = "Auto",

    [Parameter(Mandatory = $false)]
    [ValidateSet("GitHub", "Custom", "Auto")]
    [string]$CheckboxStyle = "Auto",

    [Parameter(Mandatory = $false)]
    [switch]$AddTimeEstimation,

    [Parameter(Mandatory = $false)]
    [switch]$UseAI,

    [Parameter(Mandatory = $false)]
    [switch]$SimulateAI,

    [Parameter(Mandatory = $false)]
    [string]$SubTasksFile,
    
    [Parameter(Mandatory = $false)]
    [string]$SubTasksInput,

    [Parameter(Mandatory = $false)]
    [string]$OutputFile
)

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while ($projectRoot -and -not (Test-Path -Path "$projectRoot\projet" -PathType Container)) {
    $projectRoot = Split-Path -Parent $projectRoot
}

if (-not $projectRoot) {
    $projectRoot = Split-Path -Parent $PSScriptRoot
}

# Afficher les paramètres
Write-Host "Mode GRAN - Décomposition de tâches en sous-tâches" -ForegroundColor Cyan
Write-Host "Fichier de roadmap : $FilePath" -ForegroundColor Gray
if ($TaskIdentifier) {
    Write-Host "Identifiant de tâche : $TaskIdentifier" -ForegroundColor Gray
}
if ($SubTasksInput) {
    Write-Host "Sous-tâches fournies via paramètre SubTasksInput" -ForegroundColor Gray
} elseif ($SubTasksFile) {
    Write-Host "Fichier de sous-tâches : $SubTasksFile" -ForegroundColor Gray
} else {
    Write-Host "Niveau de complexité : $ComplexityLevel" -ForegroundColor Gray
    if ($Domain -ne "None") {
        Write-Host "Domaine : $Domain" -ForegroundColor Gray
    } else {
        Write-Host "Domaine : Auto-détection" -ForegroundColor Gray
    }
}

# Vérifier que le fichier existe
if (-not (Test-Path -Path $FilePath)) {
    Write-Error "Le fichier spécifié n'existe pas : $FilePath"
    exit 1
}

# Charger la configuration des modèles de sous-tâches
$templateConfig = $null
$templateConfigPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\config\subtasks-templates.json"
if (Test-Path -Path $templateConfigPath) {
    try {
        $templateConfig = Get-Content -Path $templateConfigPath -Raw | ConvertFrom-Json
    } catch {
        Write-Warning "Erreur lors du chargement de la configuration des modèles de sous-tâches : $_"
    }
}

# Lire les sous-tâches à partir du fichier ou du paramètre SubTasksInput
$subTasksInput = ""
if ($SubTasksInput) {
    # Utiliser directement les sous-tâches fournies en paramètre
    $subTasksInput = $SubTasksInput
    Write-Host "Sous-tâches fournies via le paramètre SubTasksInput" -ForegroundColor Green
} elseif ($SubTasksFile) {
    if (Test-Path -Path $SubTasksFile) {
        $subTasksInput = Get-Content -Path $SubTasksFile -Encoding UTF8 -Raw
        Write-Host "Sous-tâches lues depuis le fichier : $SubTasksFile" -ForegroundColor Green
    } else {
        Write-Error "Le fichier de sous-tâches spécifié n'existe pas : $SubTasksFile"
        exit 1
    }
} elseif ($templateConfig) {
    # Si aucun fichier de sous-tâches n'est spécifié, utiliser un modèle basé sur la complexité
    # (Code existant pour la détection de complexité et domaine)
}

# IMPORTANT: Ce script modifie DIRECTEMENT le document spécifié.
# La granularisation est appliquée en écrasant (overwriting) le contenu existant.
# Aucun résultat intermédiaire n'est affiché dans le terminal, seul le document est modifié.
Write-Host "ATTENTION: Ce script va modifier directement le document spécifié." -ForegroundColor Yellow
Write-Host "La granularisation sera appliquée en écrasant le contenu existant." -ForegroundColor Yellow
Write-Host "Aucun résultat intermédiaire ne sera affiché dans le terminal, seul le document sera modifié." -ForegroundColor Yellow
Write-Host ""

# Appeler la fonction Invoke-RoadmapGranularization
$params = @{
    FilePath         = $FilePath
    IndentationStyle = $IndentationStyle
    CheckboxStyle    = $CheckboxStyle
}

if ($TaskIdentifier) {
    $params.TaskIdentifier = $TaskIdentifier
}

if ($subTasksInput) {
    $params.SubTasksInput = $subTasksInput
}

# Déterminer quelle fonction utiliser en fonction des paramètres
$useTimeEstimation = $AddTimeEstimation

# Importer la fonction Split-RoadmapTask
$projectRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
$splitTaskPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Functions\Public\Split-RoadmapTask-Fixed.ps1"
if (Test-Path -Path $splitTaskPath) {
    . $splitTaskPath
    Write-Host "Chargement de la fonction Split-RoadmapTask depuis $splitTaskPath" -ForegroundColor Green
} else {
    $splitTaskPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Functions\Public\Split-RoadmapTask.ps1"
    if (Test-Path -Path $splitTaskPath) {
        . $splitTaskPath
        Write-Host "Chargement de la fonction Split-RoadmapTask depuis $splitTaskPath" -ForegroundColor Green
    } else {
        Write-Error "La fonction Split-RoadmapTask est introuvable. Assurez-vous que le fichier Split-RoadmapTask.ps1 ou Split-RoadmapTask-Fixed.ps1 est présent dans le répertoire development\roadmap\parser\module\Functions\Public\"
        exit 1
    }
}

# Importer la fonction Invoke-RoadmapGranularization
$granularizationPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Functions\Public\Invoke-RoadmapGranularization-Fixed.ps1"
if (Test-Path -Path $granularizationPath) {
    . $granularizationPath
    Write-Host "Chargement de la fonction Invoke-RoadmapGranularization depuis $granularizationPath" -ForegroundColor Green
} else {
    $granularizationPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Functions\Public\Invoke-RoadmapGranularization.ps1"
    if (Test-Path -Path $granularizationPath) {
        . $granularizationPath
        Write-Host "Chargement de la fonction Invoke-RoadmapGranularization depuis $granularizationPath" -ForegroundColor Green
    } else {
        Write-Error "La fonction Invoke-RoadmapGranularization est introuvable. Assurez-vous que le fichier Invoke-RoadmapGranularization.ps1 ou Invoke-RoadmapGranularization-Fixed.ps1 est présent dans le répertoire development\roadmap\parser\module\Functions\Public\"
        exit 1
    }
}

# Appliquer la granularisation
$result = Invoke-RoadmapGranularization @params

# Afficher un message de fin
Write-Host "`nExécution du mode GRAN terminée." -ForegroundColor Cyan
Write-Host "Le document a été modifié : $FilePath" -ForegroundColor Green

# Retourner le résultat
return $result
