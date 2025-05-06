# Script pour implémenter une tâche spécifique avec Qwen3

param (
    [Parameter(Mandatory = $true)]
    [string]$TaskId,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = $null,
    
    [Parameter(Mandatory = $false)]
    [string]$Model = $null,
    
    [Parameter(Mandatory = $false)]
    [switch]$AutoImplement = $false,
    
    [Parameter(Mandatory = $false)]
    [switch]$AutoMarkComplete = $false
)

# Importer les modules nécessaires
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootPath = (Get-Item $ScriptPath).Parent.Parent.FullName

# Vérifier si le modèle est spécifié
if ([string]::IsNullOrEmpty($Model)) {
    # Essayer de charger le modèle par défaut depuis la configuration
    $configFile = "$RootPath\projet\config\openrouter_config.json"
    if (Test-Path $configFile) {
        $config = Get-Content $configFile -Raw | ConvertFrom-Json
        $Model = $config.default_model
    }
    
    # Si toujours pas de modèle, utiliser la valeur par défaut
    if ([string]::IsNullOrEmpty($Model)) {
        $Model = "qwen/qwen3-235b-a22b"
    }
}

# Exécuter le script Qwen3 DEV-R
$qwen3Script = "$ScriptPath\Use-Qwen3DevR.ps1"
if (-not (Test-Path $qwen3Script)) {
    Write-Error "Script Use-Qwen3DevR.ps1 non trouvé à l'emplacement: $qwen3Script"
    exit 1
}

# Préparer les paramètres
$params = @{
    TaskId = $TaskId
    Model = $Model
}

if (-not [string]::IsNullOrEmpty($OutputPath)) {
    $params.OutputPath = $OutputPath
}

# Exécuter le script
Write-Host "Implémentation de la tâche $TaskId avec le modèle $Model..." -ForegroundColor Yellow
& $qwen3Script @params

Write-Host "Opération terminée" -ForegroundColor Green
