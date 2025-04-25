<#
.SYNOPSIS
    Script pour créer un workflow de test.

.DESCRIPTION
    Ce script crée un workflow de test dans n8n.
    Il utilise l'API n8n pour créer le workflow.

.PARAMETER Environment
    Environnement cible : "local" (par défaut) ou "ide".

.EXAMPLE
    .\create-test-workflow.ps1
    .\create-test-workflow.ps1 -Environment "ide"
#>

param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("local", "ide")]
    [string]$Environment = "local"
)

# Définir les chemins
$rootPath = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$configPath = Join-Path -Path $rootPath -ChildPath "config"
$n8nConfigPath = Join-Path -Path $configPath -ChildPath "n8n-config.json"
$apiKeyPath = Join-Path -Path $configPath -ChildPath "api-key.json"
$workflowsPath = Join-Path -Path $rootPath -ChildPath "workflows"
$environmentPath = Join-Path -Path $workflowsPath -ChildPath $Environment

# Importer les utilitaires
$utilsPath = Join-Path -Path $rootPath -ChildPath "scripts\utils"
$n8nApiPath = Join-Path -Path $utilsPath -ChildPath "n8n-api.ps1"
$workflowUtilsPath = Join-Path -Path $utilsPath -ChildPath "workflow-utils.ps1"

if (Test-Path -Path $n8nApiPath) {
    . $n8nApiPath
} else {
    Write-Error "Le fichier d'utilitaires n8n-api.ps1 n'existe pas."
    exit 1
}

if (Test-Path -Path $workflowUtilsPath) {
    . $workflowUtilsPath
} else {
    Write-Error "Le fichier d'utilitaires workflow-utils.ps1 n'existe pas."
    exit 1
}

# Vérifier si le fichier de configuration existe
if (-not (Test-Path -Path $n8nConfigPath)) {
    Write-Error "Le fichier de configuration n8n-config.json n'existe pas. Veuillez exécuter .\scripts\setup\install-n8n-local.ps1 d'abord."
    exit 1
}

# Lire la configuration
$config = Get-Content -Path $n8nConfigPath -Raw | ConvertFrom-Json

# Charger le jeton d'API si disponible
$apiKey = $null
if (Test-Path -Path $apiKeyPath) {
    $apiKeyObject = Get-Content -Path $apiKeyPath -Raw | ConvertFrom-Json
    $apiKey = $apiKeyObject.apiKey
    Write-Host "Jeton d'API chargé : $apiKey"
} else {
    Write-Warning "Aucun jeton d'API trouvé. Créez-en un avec .\scripts\setup\create-api-key.ps1"
}

# Vérifier si n8n est en cours d'exécution
if (-not (Test-N8nRunning -Port $config.port -Hostname "localhost")) {
    Write-Warning "n8n n'est pas en cours d'exécution. Veuillez démarrer n8n avec .\scripts\start-n8n.ps1"
    exit 1
}

# Créer un workflow de test
$workflowName = "Test Workflow - $Environment"
$workflowId = [guid]::NewGuid().ToString()
$versionId = [guid]::NewGuid().ToString()
$now = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"

$workflow = @{
    id = $workflowId
    name = $workflowName
    active = $false
    createdAt = $now
    updatedAt = $now
    versionId = $versionId
    nodes = @(
        @{
            id = [guid]::NewGuid().ToString()
            name = "Start"
            type = "n8n-nodes-base.start"
            typeVersion = 1
            position = @{
                x = 240
                y = 300
            }
        },
        @{
            id = [guid]::NewGuid().ToString()
            name = "Set"
            type = "n8n-nodes-base.set"
            typeVersion = 1
            position = @{
                x = 460
                y = 300
            }
            parameters = @{
                values = @{
                    number = @(
                        @{
                            name = "data"
                            value = 1
                        }
                    )
                    string = @(
                        @{
                            name = "message"
                            value = "Hello from $Environment environment!"
                        }
                    )
                }
                options = @{}
            }
        }
    )
    connections = @{
        Start = @(
            @{
                node = "Set"
                type = "main"
                index = 0
            }
        )
    }
    settings = @{
        executionOrder = "v1"
        saveManualExecutions = $true
        callerPolicy = "workflowsFromSameOwner"
        errorWorkflow = ""
    }
    staticData = $null
    pinData = @{}
    tags = @(
        @{
            id = [guid]::NewGuid().ToString()
            name = $Environment
        }
    )
    triggerCount = 0
}

# Enregistrer le workflow dans le dossier approprié
$workflowFileName = "$($workflowName -replace '[^\w\-\.]', '_').json"
$workflowFilePath = Join-Path -Path $environmentPath -ChildPath $workflowFileName
$workflowIdFilePath = Join-Path -Path $environmentPath -ChildPath "$workflowId.json"

# Vérifier si le dossier existe, sinon le créer
if (-not (Test-Path -Path $environmentPath)) {
    New-Item -Path $environmentPath -ItemType Directory -Force | Out-Null
    Write-Host "Dossier créé: $environmentPath"
}

# Enregistrer le workflow
$workflowJson = $workflow | ConvertTo-Json -Depth 10
Set-Content -Path $workflowFilePath -Value $workflowJson -Encoding UTF8
Set-Content -Path $workflowIdFilePath -Value $workflowJson -Encoding UTF8

Write-Host "Workflow de test créé: $workflowFilePath"
Write-Host "Workflow de test créé: $workflowIdFilePath"

# Créer le workflow dans n8n
$result = New-N8nWorkflow -Workflow $workflow -Port $config.port -ApiKey $apiKey

if ($result) {
    Write-Host "Workflow de test créé dans n8n avec l'ID: $($result.id)"
    Write-Host "Vous pouvez accéder au workflow à l'adresse: http://localhost:$($config.port)/workflow/$($result.id)"
} else {
    Write-Warning "Échec de la création du workflow dans n8n. Vérifiez les erreurs ci-dessus."
}
