# Mode GRAN - Granularisation des tÃ¢ches
# Ce script permet de dÃ©composer une tÃ¢che de roadmap en sous-tÃ¢ches plus granulaires
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

# DÃ©terminer le chemin du projet
$projectRoot = $PSScriptRoot
while ($projectRoot -and -not (Test-Path -Path "$projectRoot\projet" -PathType Container)) {
    $projectRoot = Split-Path -Parent $projectRoot
}

if (-not $projectRoot) {
    $projectRoot = Split-Path -Parent $PSScriptRoot
}

# Afficher les paramÃ¨tres
Write-Host "Mode GRAN - DÃ©composition de tÃ¢ches en sous-tÃ¢ches" -ForegroundColor Cyan
Write-Host "Fichier de roadmap : $FilePath" -ForegroundColor Gray
if ($TaskIdentifier) {
    Write-Host "Identifiant de tÃ¢che : $TaskIdentifier" -ForegroundColor Gray
}
if ($SubTasksInput) {
    Write-Host "Sous-tÃ¢ches fournies via paramÃ¨tre SubTasksInput" -ForegroundColor Gray
} elseif ($SubTasksFile) {
    Write-Host "Fichier de sous-tÃ¢ches : $SubTasksFile" -ForegroundColor Gray
} else {
    Write-Host "Niveau de complexitÃ© : $ComplexityLevel" -ForegroundColor Gray
    if ($Domain -ne "None") {
        Write-Host "Domaine : $Domain" -ForegroundColor Gray
    } else {
        Write-Host "Domaine : Auto-dÃ©tection" -ForegroundColor Gray
    }
}

# VÃ©rifier que le fichier existe
if (-not (Test-Path -Path $FilePath)) {
    Write-Error "Le fichier spÃ©cifiÃ© n'existe pas : $FilePath"
    exit 1
}

# Charger la configuration des modÃ¨les de sous-tÃ¢ches
$templateConfig = $null
$templateConfigPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\config\subtasks-templates.json"
if (Test-Path -Path $templateConfigPath) {
    try {
        $templateConfig = Get-Content -Path $templateConfigPath -Raw | ConvertFrom-Json
    } catch {
        Write-Warning "Erreur lors du chargement de la configuration des modÃ¨les de sous-tÃ¢ches : $_"
    }
}

# Lire les sous-tÃ¢ches Ã  partir du fichier ou du paramÃ¨tre SubTasksInput
$subTasksInput = ""
if ($SubTasksInput) {
    # Utiliser directement les sous-tÃ¢ches fournies en paramÃ¨tre
    $subTasksInput = $SubTasksInput
    Write-Host "Sous-tÃ¢ches fournies via le paramÃ¨tre SubTasksInput" -ForegroundColor Green
} elseif ($SubTasksFile) {
    if (Test-Path -Path $SubTasksFile) {
        $subTasksInput = Get-Content -Path $SubTasksFile -Encoding UTF8 -Raw
        Write-Host "Sous-tÃ¢ches lues depuis le fichier : $SubTasksFile" -ForegroundColor Green
    } else {
        Write-Error "Le fichier de sous-tÃ¢ches spÃ©cifiÃ© n'existe pas : $SubTasksFile"
        exit 1
    }
} elseif ($templateConfig) {
    # Si aucun fichier de sous-tÃ¢ches n'est spÃ©cifiÃ©, utiliser un modÃ¨le basÃ© sur la complexitÃ©
    # (Code existant pour la dÃ©tection de complexitÃ© et domaine)
}

# IMPORTANT: Ce script modifie DIRECTEMENT le document spÃ©cifiÃ©.
# La granularisation est appliquÃ©e en Ã©crasant (overwriting) le contenu existant.
# Aucun rÃ©sultat intermÃ©diaire n'est affichÃ© dans le terminal, seul le document est modifiÃ©.
Write-Host "ATTENTION: Ce script va modifier directement le document spÃ©cifiÃ©." -ForegroundColor Yellow
Write-Host "La granularisation sera appliquÃ©e en Ã©crasant le contenu existant." -ForegroundColor Yellow
Write-Host "Aucun rÃ©sultat intermÃ©diaire ne sera affichÃ© dans le terminal, seul le document sera modifiÃ©." -ForegroundColor Yellow
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

# DÃ©terminer quelle fonction utiliser en fonction des paramÃ¨tres
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
        Write-Error "La fonction Split-RoadmapTask est introuvable. Assurez-vous que le fichier Split-RoadmapTask.ps1 ou Split-RoadmapTask-Fixed.ps1 est prÃ©sent dans le rÃ©pertoire development\roadmap\parser\module\Functions\Public\"
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
        Write-Error "La fonction Invoke-RoadmapGranularization est introuvable. Assurez-vous que le fichier Invoke-RoadmapGranularization.ps1 ou Invoke-RoadmapGranularization-Fixed.ps1 est prÃ©sent dans le rÃ©pertoire development\roadmap\parser\module\Functions\Public\"
        exit 1
    }
}

# Appliquer la granularisation
$result = Invoke-RoadmapGranularization @params

# Afficher un message de fin
Write-Host "`nExÃ©cution du mode GRAN terminÃ©e." -ForegroundColor Cyan
Write-Host "Le document a Ã©tÃ© modifiÃ© : $FilePath" -ForegroundColor Green

# Retourner le rÃ©sultat
return $result
