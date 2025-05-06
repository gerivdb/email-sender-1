# Script pour configurer l'intégration avec OpenRouter

param (
    [Parameter(Mandatory = $false)]
    [string]$ApiKey = "",
    
    [Parameter(Mandatory = $false)]
    [string]$DefaultModel = "qwen/qwen3-235b-a22b",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force = $false
)

# Importer les modules nécessaires
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$ScriptPath\CredentialManager.psm1" -Force

# Fonction pour configurer la clé API
function Set-OpenRouterApiKey {
    param (
        [string]$ApiKey,
        [switch]$Force
    )
    
    # Vérifier si la clé API existe déjà
    $existingKey = $null
    try {
        $existingKey = Get-StoredCredential -Target "openrouter_api_key" -AsPlainText
    }
    catch {
        # Ignorer l'erreur si la clé n'existe pas
    }
    
    if (-not [string]::IsNullOrEmpty($existingKey) -and -not $Force) {
        $overwrite = Read-Host "Une clé API OpenRouter existe déjà. Voulez-vous la remplacer? (O/N)"
        if ($overwrite -ne "O" -and $overwrite -ne "o") {
            Write-Host "Configuration annulée" -ForegroundColor Yellow
            return $false
        }
    }
    
    # Si aucune clé n'est fournie, demander à l'utilisateur
    if ([string]::IsNullOrEmpty($ApiKey)) {
        $secureApiKey = Read-Host -Prompt "Entrez votre clé API OpenRouter" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureApiKey)
        $ApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }
    
    # Stocker la clé API
    Set-StoredCredential -Target "openrouter_api_key" -UserName "api" -Password $ApiKey
    
    Write-Host "Clé API OpenRouter configurée avec succès" -ForegroundColor Green
    return $true
}

# Fonction pour configurer le modèle par défaut
function Set-DefaultOpenRouterModel {
    param (
        [string]$DefaultModel
    )
    
    # Chemin du fichier de configuration
    $configPath = "$PSScriptRoot\..\..\projet\config"
    $configFile = "$configPath\openrouter_config.json"
    
    # Créer le dossier de configuration s'il n'existe pas
    if (-not (Test-Path $configPath)) {
        New-Item -ItemType Directory -Path $configPath -Force | Out-Null
    }
    
    # Charger la configuration existante ou créer une nouvelle
    $config = @{}
    if (Test-Path $configFile) {
        $config = Get-Content $configFile -Raw | ConvertFrom-Json
    }
    
    # Mettre à jour le modèle par défaut
    $config.default_model = $DefaultModel
    
    # Enregistrer la configuration
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configFile -Encoding utf8
    
    Write-Host "Modèle par défaut configuré: $DefaultModel" -ForegroundColor Green
    return $true
}

# Fonction pour tester la configuration
function Test-OpenRouterConfiguration {
    # Exécuter le script de test
    $testScript = "$PSScriptRoot\..\maintenance\tests\Test-Qwen3Integration.ps1"
    if (Test-Path $testScript) {
        Write-Host "Test de la configuration OpenRouter..." -ForegroundColor Yellow
        $result = & $testScript
        return $result
    }
    else {
        Write-Warning "Script de test non trouvé: $testScript"
        return $false
    }
}

# Fonction principale
function Invoke-OpenRouterConfiguration {
    param (
        [string]$ApiKey,
        [string]$DefaultModel,
        [switch]$Force
    )
    
    # Configurer la clé API
    $apiKeyResult = Set-OpenRouterApiKey -ApiKey $ApiKey -Force:$Force
    
    # Configurer le modèle par défaut
    $modelResult = Set-DefaultOpenRouterModel -DefaultModel $DefaultModel
    
    # Tester la configuration
    if ($apiKeyResult -and $modelResult) {
        $testResult = Test-OpenRouterConfiguration
        
        if ($testResult) {
            Write-Host "Configuration OpenRouter terminée avec succès" -ForegroundColor Green
        }
        else {
            Write-Warning "Configuration OpenRouter terminée, mais le test a échoué"
        }
    }
    else {
        Write-Warning "Configuration OpenRouter incomplète"
    }
}

# Exécuter la configuration
Invoke-OpenRouterConfiguration -ApiKey $ApiKey -DefaultModel $DefaultModel -Force:$Force
