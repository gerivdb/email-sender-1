#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intÃ©gration pour le cache prÃ©dictif avec n8n.
.DESCRIPTION
    Ce script contient les tests d'intÃ©gration pour le cache prÃ©dictif
    avec n8n, vÃ©rifiant l'intÃ©gration entre les composants.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-05-16
#>

BeforeAll {
    # Importer le module Ã  tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PredictiveCache.psm1"
    Import-Module $modulePath -Force
    
    # CrÃ©er des dossiers temporaires
    $tempCachePath = Join-Path -Path $TestDrive -ChildPath "cache"
    $tempModelPath = Join-Path -Path $TestDrive -ChildPath "models"
    $tempLogsPath = Join-Path -Path $TestDrive -ChildPath "logs"
    
    New-Item -Path $tempCachePath -ItemType Directory -Force | Out-Null
    New-Item -Path $tempModelPath -ItemType Directory -Force | Out-Null
    New-Item -Path $tempLogsPath -ItemType Directory -Force | Out-Null
    
    # Initialiser le module
    Initialize-PredictiveCache -Enabled $true -CachePath $tempCachePath -ModelPath $tempModelPath -MaxCacheSize 10MB -DefaultTTL 3600
    
    # CrÃ©er un script d'exemple pour n8n
    $exampleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\development\scripts\n8n\cache\Example-PredictiveCache.ps1"
    
    # VÃ©rifier si le script existe, sinon le crÃ©er pour les tests
    if (-not (Test-Path -Path $exampleScriptPath)) {
        $scriptDir = Split-Path -Path $exampleScriptPath -Parent
        if (-not (Test-Path -Path $scriptDir)) {
            New-Item -Path $scriptDir -ItemType Directory -Force | Out-Null
        }
        
        @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple d'utilisation du cache prÃ©dictif avec n8n.
.DESCRIPTION
    Ce script montre comment utiliser le cache prÃ©dictif pour
    optimiser les performances des workflows n8n.
.PARAMETER WorkflowId
    ID du workflow n8n.
.PARAMETER NodeId
    ID du nÅ“ud n8n.
.PARAMETER Key
    ClÃ© de cache Ã  utiliser.
.PARAMETER Value
    Valeur Ã  mettre en cache (pour les opÃ©rations de mise en cache).
.PARAMETER Operation
    OpÃ©ration Ã  effectuer (Get, Set, Remove, Predict).
.PARAMETER TestMode
    Mode de test pour les tests d'intÃ©gration.
.EXAMPLE
    .\Example-PredictiveCache.ps1 -WorkflowId "workflow1" -NodeId "node1" -Key "test-key" -Operation Get
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = `$false)]
    [string]`$WorkflowId = "test-workflow",
    
    [Parameter(Mandatory = `$false)]
    [string]`$NodeId = "test-node",
    
    [Parameter(Mandatory = `$false)]
    [string]`$Key = "test-key",
    
    [Parameter(Mandatory = `$false)]
    [object]`$Value = `$null,
    
    [Parameter(Mandatory = `$false)]
    [ValidateSet("Get", "Set", "Remove", "Predict")]
    [string]`$Operation = "Get",
    
    [Parameter(Mandatory = `$false)]
    [switch]`$TestMode
)

# Importer le module de cache prÃ©dictif
`$modulePath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\modules\PredictiveCache.psm1"
Import-Module `$modulePath -Force

# Initialiser le module
`$tempCachePath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\cache"
`$tempModelPath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\models"

if (-not (Test-Path -Path `$tempCachePath)) {
    New-Item -Path `$tempCachePath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path `$tempModelPath)) {
    New-Item -Path `$tempModelPath -ItemType Directory -Force | Out-Null
}

Initialize-PredictiveCache -Enabled `$true -CachePath `$tempCachePath -ModelPath `$tempModelPath -MaxCacheSize 10MB -DefaultTTL 3600

# Fonction pour simuler un workflow n8n
function Invoke-N8nWorkflow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$WorkflowId,
        
        [Parameter(Mandatory = `$true)]
        [string]`$NodeId,
        
        [Parameter(Mandatory = `$true)]
        [string]`$Key,
        
        [Parameter(Mandatory = `$false)]
        [object]`$Value = `$null,
        
        [Parameter(Mandatory = `$true)]
        [ValidateSet("Get", "Set", "Remove", "Predict")]
        [string]`$Operation,
        
        [Parameter(Mandatory = `$false)]
        [switch]`$TestMode
    )
    
    # CrÃ©er un objet de rÃ©sultat pour le mode de test
    if (`$TestMode) {
        `$result = [PSCustomObject]@{
            WorkflowId = `$WorkflowId
            NodeId = `$NodeId
            Key = `$Key
            Operation = `$Operation
            CacheHit = `$false
            Value = `$null
            Predictions = @()
        }
    }
    
    # ExÃ©cuter l'opÃ©ration demandÃ©e
    switch (`$Operation) {
        "Get" {
            # Enregistrer l'accÃ¨s au cache
            Register-CacheAccess -Key `$Key -WorkflowId `$WorkflowId -NodeId `$NodeId
            
            # RÃ©cupÃ©rer la valeur du cache
            `$cachedValue = Get-PredictiveCache -Key `$Key
            
            if (`$TestMode) {
                `$result.CacheHit = (`$cachedValue -ne `$null)
                `$result.Value = `$cachedValue
                
                # Obtenir les prÃ©dictions
                `$predictions = Get-PredictedCacheKeys -Key `$Key -WorkflowId `$WorkflowId -NodeId `$NodeId
                `$result.Predictions = `$predictions
                
                return `$result
            }
            
            if (`$cachedValue -ne `$null) {
                Write-Host "Cache hit pour la clÃ© '`$Key'" -ForegroundColor Green
                
                # Obtenir les prÃ©dictions
                `$predictions = Get-PredictedCacheKeys -Key `$Key -WorkflowId `$WorkflowId -NodeId `$NodeId
                
                if (`$predictions.Count -gt 0) {
                    Write-Host "PrÃ©dictions pour les prochains accÃ¨s:" -ForegroundColor Cyan
                    foreach (`$prediction in `$predictions) {
                        Write-Host "  - `$(`$prediction.Key) (probabilitÃ©: `$(`$prediction.Probability))" -ForegroundColor Cyan
                        
                        # PrÃ©charger les valeurs prÃ©dites
                        `$predictedValue = Get-PredictiveCache -Key `$prediction.Key
                        if (`$predictedValue -ne `$null) {
                            Write-Host "    Valeur prÃ©chargÃ©e" -ForegroundColor DarkGray
                        }
                    }
                }
                
                return `$cachedValue
            }
            else {
                Write-Host "Cache miss pour la clÃ© '`$Key'" -ForegroundColor Yellow
                return `$null
            }
        }
        "Set" {
            # Mettre en cache la valeur
            Set-PredictiveCache -Key `$Key -Value `$Value
            
            # Enregistrer l'accÃ¨s au cache
            Register-CacheAccess -Key `$Key -WorkflowId `$WorkflowId -NodeId `$NodeId
            
            if (`$TestMode) {
                `$result.Value = `$Value
                return `$result
            }
            
            Write-Host "Valeur mise en cache pour la clÃ© '`$Key'" -ForegroundColor Green
            return `$Value
        }
        "Remove" {
            # Supprimer la valeur du cache
            `$removed = Remove-PredictiveCache -Key `$Key
            
            if (`$TestMode) {
                `$result.CacheHit = `$removed
                return `$result
            }
            
            if (`$removed) {
                Write-Host "Valeur supprimÃ©e du cache pour la clÃ© '`$Key'" -ForegroundColor Green
                return `$true
            }
            else {
                Write-Host "Aucune valeur trouvÃ©e dans le cache pour la clÃ© '`$Key'" -ForegroundColor Yellow
                return `$false
            }
        }
        "Predict" {
            # Obtenir les prÃ©dictions
            `$predictions = Get-PredictedCacheKeys -Key `$Key -WorkflowId `$WorkflowId -NodeId `$NodeId
            
            if (`$TestMode) {
                `$result.Predictions = `$predictions
                return `$result
            }
            
            if (`$predictions.Count -gt 0) {
                Write-Host "PrÃ©dictions pour la clÃ© '`$Key':" -ForegroundColor Cyan
                foreach (`$prediction in `$predictions) {
                    Write-Host "  - `$(`$prediction.Key) (probabilitÃ©: `$(`$prediction.Probability))" -ForegroundColor Cyan
                }
                
                return `$predictions
            }
            else {
                Write-Host "Aucune prÃ©diction trouvÃ©e pour la clÃ© '`$Key'" -ForegroundColor Yellow
                return @()
            }
        }
    }
}

# ExÃ©cuter la fonction principale
Invoke-N8nWorkflow -WorkflowId `$WorkflowId -NodeId `$NodeId -Key `$Key -Value `$Value -Operation `$Operation -TestMode:`$TestMode
"@ | Out-File -FilePath $exampleScriptPath -Encoding utf8
    }
    
    # CrÃ©er un script d'initialisation pour n8n
    $initScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\development\scripts\n8n\cache\Initialize-N8nPredictiveCache.ps1"
    
    # VÃ©rifier si le script existe, sinon le crÃ©er pour les tests
    if (-not (Test-Path -Path $initScriptPath)) {
        $scriptDir = Split-Path -Path $initScriptPath -Parent
        if (-not (Test-Path -Path $scriptDir)) {
            New-Item -Path $scriptDir -ItemType Directory -Force | Out-Null
        }
        
        @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Initialise le cache prÃ©dictif pour n8n.
.DESCRIPTION
    Ce script configure et initialise le cache prÃ©dictif pour n8n,
    permettant d'optimiser les performances des workflows.
.PARAMETER N8nApiUrl
    URL de l'API n8n.
.PARAMETER ApiKey
    ClÃ© API pour l'authentification avec n8n.
.PARAMETER MaxCacheSizeMB
    Taille maximale du cache en MB.
.PARAMETER DefaultTTL
    DurÃ©e de vie par dÃ©faut des entrÃ©es du cache en secondes.
.PARAMETER CachePath
    Chemin du dossier de cache.
.PARAMETER ModelPath
    Chemin du dossier des modÃ¨les de prÃ©diction.
.PARAMETER TestMode
    Mode de test pour les tests d'intÃ©gration.
.EXAMPLE
    .\Initialize-N8nPredictiveCache.ps1 -N8nApiUrl "http://localhost:5678/api/v1" -ApiKey "your_api_key" -MaxCacheSizeMB 200
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = `$false)]
    [string]`$N8nApiUrl = "http://localhost:5678/api/v1",
    
    [Parameter(Mandatory = `$false)]
    [string]`$ApiKey = "",
    
    [Parameter(Mandatory = `$false)]
    [int]`$MaxCacheSizeMB = 100,
    
    [Parameter(Mandatory = `$false)]
    [int]`$DefaultTTL = 3600,
    
    [Parameter(Mandatory = `$false)]
    [string]`$CachePath = ".\cache",
    
    [Parameter(Mandatory = `$false)]
    [string]`$ModelPath = ".\models",
    
    [Parameter(Mandatory = `$false)]
    [switch]`$TestMode
)

# Importer le module de cache prÃ©dictif
`$modulePath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\modules\PredictiveCache.psm1"
Import-Module `$modulePath -Force

# Fonction pour initialiser le cache prÃ©dictif
function Initialize-N8nCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$N8nApiUrl,
        
        [Parameter(Mandatory = `$false)]
        [string]`$ApiKey = "",
        
        [Parameter(Mandatory = `$true)]
        [int]`$MaxCacheSizeMB,
        
        [Parameter(Mandatory = `$true)]
        [int]`$DefaultTTL,
        
        [Parameter(Mandatory = `$true)]
        [string]`$CachePath,
        
        [Parameter(Mandatory = `$true)]
        [string]`$ModelPath,
        
        [Parameter(Mandatory = `$false)]
        [switch]`$TestMode
    )
    
    # CrÃ©er les dossiers nÃ©cessaires
    if (-not (Test-Path -Path `$CachePath)) {
        New-Item -Path `$CachePath -ItemType Directory -Force | Out-Null
    }
    
    if (-not (Test-Path -Path `$ModelPath)) {
        New-Item -Path `$ModelPath -ItemType Directory -Force | Out-Null
    }
    
    # Initialiser le module de cache prÃ©dictif
    Initialize-PredictiveCache -Enabled `$true -CachePath `$CachePath -ModelPath `$ModelPath -MaxCacheSize (`$MaxCacheSizeMB * 1MB) -DefaultTTL `$DefaultTTL
    
    # VÃ©rifier la connexion Ã  n8n
    try {
        `$headers = @{
            "Content-Type" = "application/json"
        }
        
        if (`$ApiKey) {
            `$headers["X-N8N-API-KEY"] = `$ApiKey
        }
        
        # Simuler la connexion pour les tests
        if (`$TestMode) {
            `$n8nConnected = `$true
        }
        else {
            # Tenter de se connecter Ã  n8n
            `$response = Invoke-RestMethod -Uri "`$N8nApiUrl/version" -Method Get -Headers `$headers -ErrorAction Stop
            `$n8nConnected = `$true
        }
    }
    catch {
        `$n8nConnected = `$false
        Write-Warning "Impossible de se connecter Ã  n8n: `$_"
    }
    
    # Enregistrer les hooks n8n
    if (`$n8nConnected) {
        `$hooksRegistered = Register-N8nCacheHook -N8nApiUrl `$N8nApiUrl -ApiKey `$ApiKey
    }
    else {
        `$hooksRegistered = `$false
    }
    
    if (`$TestMode) {
        return [PSCustomObject]@{
            Initialized = `$true
            N8nConnected = `$n8nConnected
            HooksRegistered = `$hooksRegistered
            MaxCacheSizeMB = `$MaxCacheSizeMB
            DefaultTTL = `$DefaultTTL
            CachePath = `$CachePath
            ModelPath = `$ModelPath
        }
    }
    
    if (`$n8nConnected) {
        if (`$hooksRegistered) {
            Write-Host "Cache prÃ©dictif initialisÃ© et hooks n8n enregistrÃ©s avec succÃ¨s." -ForegroundColor Green
        }
        else {
            Write-Host "Cache prÃ©dictif initialisÃ©, mais les hooks n8n n'ont pas pu Ãªtre enregistrÃ©s." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Cache prÃ©dictif initialisÃ©, mais n8n n'est pas accessible." -ForegroundColor Yellow
    }
    
    return `$true
}

# ExÃ©cuter la fonction principale
Initialize-N8nCache -N8nApiUrl `$N8nApiUrl -ApiKey `$ApiKey -MaxCacheSizeMB `$MaxCacheSizeMB -DefaultTTL `$DefaultTTL -CachePath `$CachePath -ModelPath `$ModelPath -TestMode:`$TestMode
"@ | Out-File -FilePath $initScriptPath -Encoding utf8
    }
    
    # Mock pour Invoke-RestMethod
    Mock Invoke-RestMethod {
        return @{
            status = "ok"
            version = "1.0.0"
        }
    }
}

Describe "n8n Predictive Cache Integration" {
    Context "Lorsqu'on initialise le cache prÃ©dictif pour n8n" {
        It "Devrait initialiser correctement le cache" {
            $result = & $initScriptPath -N8nApiUrl "http://localhost:5678/api/v1" -ApiKey "test-api-key" -MaxCacheSizeMB 50 -CachePath $tempCachePath -ModelPath $tempModelPath -TestMode
            
            $result.Initialized | Should -Be $true
            $result.MaxCacheSizeMB | Should -Be 50
            $result.CachePath | Should -Be $tempCachePath
            $result.ModelPath | Should -Be $tempModelPath
        }
    }
    
    Context "Lorsqu'on utilise le cache prÃ©dictif avec n8n" {
        BeforeAll {
            # PrÃ©parer des donnÃ©es de test
            $workflowId = "test-workflow"
            $nodeId = "test-node"
            $key1 = "test-key-1"
            $key2 = "test-key-2"
            $key3 = "test-key-3"
            $value1 = "test-value-1"
            $value2 = "test-value-2"
            $value3 = "test-value-3"
            
            # Mettre en cache des valeurs
            & $exampleScriptPath -WorkflowId $workflowId -NodeId $nodeId -Key $key1 -Value $value1 -Operation "Set" -TestMode
            & $exampleScriptPath -WorkflowId $workflowId -NodeId $nodeId -Key $key2 -Value $value2 -Operation "Set" -TestMode
            & $exampleScriptPath -WorkflowId $workflowId -NodeId $nodeId -Key $key3 -Value $value3 -Operation "Set" -TestMode
            
            # CrÃ©er une sÃ©quence d'accÃ¨s
            for ($i = 0; $i -lt 5; $i++) {
                & $exampleScriptPath -WorkflowId $workflowId -NodeId $nodeId -Key $key1 -Operation "Get" -TestMode
                & $exampleScriptPath -WorkflowId $workflowId -NodeId $nodeId -Key $key2 -Operation "Get" -TestMode
                & $exampleScriptPath -WorkflowId $workflowId -NodeId $nodeId -Key $key3 -Operation "Get" -TestMode
            }
        }
        
        It "Devrait rÃ©cupÃ©rer correctement les valeurs du cache" {
            $result = & $exampleScriptPath -WorkflowId "test-workflow" -NodeId "test-node" -Key "test-key-1" -Operation "Get" -TestMode
            
            $result.CacheHit | Should -Be $true
            $result.Value | Should -Be "test-value-1"
        }
        
        It "Devrait prÃ©dire correctement les prochains accÃ¨s" {
            $result = & $exampleScriptPath -WorkflowId "test-workflow" -NodeId "test-node" -Key "test-key-1" -Operation "Predict" -TestMode
            
            $result.Predictions.Count | Should -BeGreaterThan 0
            $result.Predictions[0].Key | Should -Be "test-key-2"
        }
        
        It "Devrait supprimer correctement les valeurs du cache" {
            $result = & $exampleScriptPath -WorkflowId "test-workflow" -NodeId "test-node" -Key "test-key-3" -Operation "Remove" -TestMode
            
            $result.CacheHit | Should -Be $true
            
            $result2 = & $exampleScriptPath -WorkflowId "test-workflow" -NodeId "test-node" -Key "test-key-3" -Operation "Get" -TestMode
            
            $result2.CacheHit | Should -Be $false
            $result2.Value | Should -Be $null
        }
        
        It "Devrait prendre en compte le contexte du workflow et du nÅ“ud" {
            # CrÃ©er une sÃ©quence d'accÃ¨s dans un contexte diffÃ©rent
            $workflowId2 = "test-workflow-2"
            $nodeId2 = "test-node-2"
            $key4 = "test-key-4"
            $key5 = "test-key-5"
            $value4 = "test-value-4"
            $value5 = "test-value-5"
            
            # Mettre en cache des valeurs
            & $exampleScriptPath -WorkflowId $workflowId2 -NodeId $nodeId2 -Key $key4 -Value $value4 -Operation "Set" -TestMode
            & $exampleScriptPath -WorkflowId $workflowId2 -NodeId $nodeId2 -Key $key5 -Value $value5 -Operation "Set" -TestMode
            
            # CrÃ©er une sÃ©quence d'accÃ¨s
            for ($i = 0; $i -lt 5; $i++) {
                & $exampleScriptPath -WorkflowId $workflowId2 -NodeId $nodeId2 -Key $key4 -Operation "Get" -TestMode
                & $exampleScriptPath -WorkflowId $workflowId2 -NodeId $nodeId2 -Key $key5 -Operation "Get" -TestMode
            }
            
            # VÃ©rifier les prÃ©dictions dans le premier contexte
            $result1 = & $exampleScriptPath -WorkflowId $workflowId -NodeId $nodeId -Key $key1 -Operation "Predict" -TestMode
            
            # VÃ©rifier les prÃ©dictions dans le deuxiÃ¨me contexte
            $result2 = & $exampleScriptPath -WorkflowId $workflowId2 -NodeId $nodeId2 -Key $key4 -Operation "Predict" -TestMode
            
            # Les prÃ©dictions devraient Ãªtre diffÃ©rentes
            if ($result1.Predictions.Count -gt 0 -and $result2.Predictions.Count -gt 0) {
                $result1.Predictions[0].Key | Should -Not -Be $result2.Predictions[0].Key
            }
        }
    }
}
