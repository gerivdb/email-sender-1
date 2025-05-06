# Script d'aide pour utiliser Qwen3 en mode DEV-R

param (
    [Parameter(Mandatory = $true)]
    [string]$TaskId,

    [Parameter(Mandatory = $false)]
    [string]$ApiKey = "",

    [Parameter(Mandatory = $false)]
    [string]$Model = "qwen/qwen3-235b-a22b",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = $null,

    [Parameter(Mandatory = $false)]
    [switch]$SaveConfig = $false
)

# Vérifier si le script principal existe
$scriptPath = Join-Path $PSScriptRoot "qwen3-dev-r.ps1"
if (-not (Test-Path $scriptPath)) {
    Write-Error "Script qwen3-dev-r.ps1 non trouvé à l'emplacement: $scriptPath"
    exit 1
}

# Préparer les paramètres
$params = @{
    TaskId = $TaskId
    Model  = $Model
}

if (-not [string]::IsNullOrEmpty($ApiKey)) {
    $params.ApiKey = $ApiKey
}

if (-not [string]::IsNullOrEmpty($OutputPath)) {
    $params.OutputPath = $OutputPath
}

if ($SaveConfig) {
    $params.SaveConfig = $true
}

# Exécuter le script principal
Write-Host "Exécution de Qwen3 en mode DEV-R pour la tâche $TaskId..." -ForegroundColor Yellow
& $scriptPath @params
