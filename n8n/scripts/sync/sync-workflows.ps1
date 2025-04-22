<#
.SYNOPSIS
    Script de synchronisation des workflows entre l'IDE et n8n local.

.DESCRIPTION
    Ce script synchronise les workflows entre l'IDE et n8n local de manière bidirectionnelle.
    Il prend en charge différents dossiers de workflows pour différents environnements.

.PARAMETER Direction
    Direction de la synchronisation : "to-n8n", "from-n8n" ou "both" (par défaut).

.PARAMETER Environment
    Environnement cible : "local" (par défaut), "ide" ou "all".

.EXAMPLE
    .\sync-workflows.ps1
    .\sync-workflows.ps1 -Direction "to-n8n" -Environment "local"
    .\sync-workflows.ps1 -Direction "from-n8n" -Environment "ide"
    .\sync-workflows.ps1 -Direction "both" -Environment "all"
#>

param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("to-n8n", "from-n8n", "both")]
    [string]$Direction = "both",

    [Parameter(Mandatory = $false)]
    [ValidateSet("local", "ide", "all")]
    [string]$Environment = "local"
)

# Définir les chemins
$rootPath = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$configPath = Join-Path -Path $rootPath -ChildPath "config"
$n8nConfigPath = Join-Path -Path $configPath -ChildPath "n8n-config.json"
$apiKeyPath = Join-Path -Path $configPath -ChildPath "api-key.json"

# Définir les chemins des workflows selon l'environnement
$workflowsRootPath = Join-Path -Path $rootPath -ChildPath "workflows"
$localWorkflowsPath = Join-Path -Path $workflowsRootPath -ChildPath "local"
$ideWorkflowsPath = Join-Path -Path $workflowsRootPath -ChildPath "ide"

# Déterminer les chemins à utiliser en fonction de l'environnement
$workflowsPaths = @()
if ($Environment -eq "local" -or $Environment -eq "all") {
    $workflowsPaths += $localWorkflowsPath
}
if ($Environment -eq "ide" -or $Environment -eq "all") {
    $workflowsPaths += $ideWorkflowsPath
}

# Vérifier si les dossiers existent, sinon les créer
foreach ($path in $workflowsPaths) {
    if (-not (Test-Path -Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
        Write-Host "Dossier créé: $path"
    }
}

# Charger le jeton d'API si disponible
$apiKey = $null
if (Test-Path -Path $apiKeyPath) {
    $apiKeyObject = Get-Content -Path $apiKeyPath -Raw | ConvertFrom-Json
    $apiKey = $apiKeyObject.apiKey
    Write-Host "Jeton d'API chargé : $apiKey"
} else {
    Write-Warning "Aucun jeton d'API trouvé. Créez-en un avec .\scripts\setup\create-api-key.ps1"
}

# Vérifier si le fichier de configuration existe
if (-not (Test-Path -Path $n8nConfigPath)) {
    Write-Error "Le fichier de configuration n8n-config.json n'existe pas. Veuillez exécuter .\scripts\setup\install.ps1 d'abord."
    exit 1
}

# Lire la configuration
$config = Get-Content -Path $n8nConfigPath -Raw | ConvertFrom-Json

# Fonction pour vérifier si n8n est en cours d'exécution
function Test-N8nRunning {
    param (
        [Parameter(Mandatory = $true)]
        [int]$Port,
        
        [Parameter(Mandatory = $false)]
        [string]$Hostname = "localhost"
    )
    
    try {
        $response = Invoke-WebRequest -Uri "http://$Hostname:$Port/healthz" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
        return ($response.StatusCode -eq 200)
    } catch {
        return $false
    }
}

# Fonction pour corriger un workflow
function Fix-Workflow {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Workflow
    )

    # Vérifier si le workflow a un ID
    if (-not $Workflow.id) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "id" -Value ([guid]::NewGuid().ToString()) -Force
    }

    # Vérifier si le workflow a une date de création
    if (-not $Workflow.createdAt) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "createdAt" -Value (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ") -Force
    }

    # Vérifier si le workflow a une date de mise à jour
    if (-not $Workflow.updatedAt) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "updatedAt" -Value (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ") -Force
    }

    # Vérifier si le workflow a un ID de version
    if (-not $Workflow.versionId) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "versionId" -Value ([guid]::NewGuid().ToString()) -Force
    }

    # Vérifier si le workflow a un état d'activation
    if ($null -eq $Workflow.active) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "active" -Value $false -Force
    }

    # Vérifier si le workflow a des paramètres
    if (-not $Workflow.settings) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "settings" -Value @{
            executionOrder       = "v1"
            saveManualExecutions = $true
            callerPolicy         = "workflowsFromSameOwner"
            errorWorkflow        = ""
        } -Force
    }

    # Vérifier si le workflow a des données statiques
    if ($null -eq $Workflow.staticData) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "staticData" -Value $null -Force
    }

    # Vérifier si le workflow a un compteur de déclenchements
    if ($null -eq $Workflow.triggerCount) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "triggerCount" -Value 0 -Force
    }

    # Vérifier si le workflow a des données épinglées
    if ($null -eq $Workflow.pinData) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "pinData" -Value @{} -Force
    }

    # Vérifier si le workflow a des tags
    if ($null -eq $Workflow.tags) {
        $Workflow | Add-Member -MemberType NoteProperty -Name "tags" -Value @() -Force
    }

    return $Workflow
}

# Fonction pour synchroniser les workflows des dossiers locaux vers n8n
function Sync-WorkflowsToN8n {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$WorkflowsPaths
    )

    Write-Host "Synchronisation des workflows des dossiers locaux vers n8n..."
    
    foreach ($workflowsPath in $WorkflowsPaths) {
        Write-Host "Traitement du dossier: $workflowsPath"
        
        # Vérifier si le dossier des workflows existe
        if (-not (Test-Path -Path $workflowsPath)) {
            Write-Error "Le dossier des workflows n'existe pas: $workflowsPath"
            continue
        }
        
        # Obtenir la liste des fichiers de workflow
        $workflowFiles = Get-ChildItem -Path $workflowsPath -Filter "*.json" -File | Where-Object { $_.Name -notmatch "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.json$" }
        
        if ($workflowFiles.Count -eq 0) {
            Write-Host "Aucun workflow à synchroniser dans $workflowsPath."
            continue
        }
        
        # Traiter chaque fichier de workflow
        foreach ($file in $workflowFiles) {
            try {
                # Lire le contenu du fichier
                $workflowContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                
                # Corriger le workflow
                $fixedWorkflow = Fix-Workflow -Workflow $workflowContent
                
                # Enregistrer le workflow corrigé
                $fixedWorkflowJson = $fixedWorkflow | ConvertTo-Json -Depth 10
                Set-Content -Path $file.FullName -Value $fixedWorkflowJson -Encoding UTF8
                
                # Créer le fichier .n8n-workflow
                $n8nWorkflowFile = Join-Path -Path $workflowsPath -ChildPath "$($fixedWorkflow.id).json"
                
                # Vérifier si le fichier source et le fichier de destination sont différents
                if ($file.FullName -ne $n8nWorkflowFile) {
                    # Copier le contenu du fichier
                    Copy-Item -Path $file.FullName -Destination $n8nWorkflowFile -Force
                }
                
                Write-Host "Workflow '$($file.Name)' synchronisé avec ID: $($fixedWorkflow.id)"
            } catch {
                Write-Error "Erreur lors de la synchronisation du workflow '$($file.Name)' : $_"
            }
        }
    }
    
    Write-Host "Synchronisation vers n8n terminée."
}

# Fonction pour synchroniser les workflows de n8n vers les dossiers locaux
function Sync-WorkflowsFromN8n {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$WorkflowsPaths
    )

    Write-Host "Synchronisation des workflows de n8n vers les dossiers locaux..."
    
    # Vérifier si n8n est en cours d'exécution
    if (-not (Test-N8nRunning -Port $config.port -Hostname "localhost")) {
        Write-Warning "n8n n'est pas en cours d'exécution. Impossible de synchroniser depuis n8n."
        return
    }
    
    # Obtenir la liste des workflows depuis n8n
    try {
        $uri = "http://localhost:$($config.port)/rest/workflows"
        $headers = @{}
        if ($apiKey) {
            $headers.Add("X-N8N-API-KEY", $apiKey)
        }
        
        $workflows = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ErrorAction Stop
        
        if ($workflows.Count -eq 0) {
            Write-Host "Aucun workflow à synchroniser depuis n8n."
            return
        }
        
        # Traiter chaque workflow
        foreach ($workflow in $workflows) {
            try {
                # Obtenir les détails du workflow
                $workflowUri = "http://localhost:$($config.port)/rest/workflows/$($workflow.id)"
                $workflowDetails = Invoke-RestMethod -Uri $workflowUri -Method Get -Headers $headers -ErrorAction Stop
                
                # Déterminer le dossier de destination en fonction des tags
                $destinationPath = $WorkflowsPaths[0] # Par défaut, utiliser le premier dossier
                
                # Si le workflow a des tags, déterminer le dossier approprié
                if ($workflowDetails.tags -and $workflowDetails.tags.Count -gt 0) {
                    foreach ($tag in $workflowDetails.tags) {
                        if ($tag.name -eq "ide") {
                            $destinationPath = $ideWorkflowsPath
                            break
                        } elseif ($tag.name -eq "local") {
                            $destinationPath = $localWorkflowsPath
                            break
                        }
                    }
                }
                
                # Créer le nom de fichier basé sur le nom du workflow
                $workflowFileName = "$($workflowDetails.name -replace '[^\w\-\.]', '_').json"
                $workflowFilePath = Join-Path -Path $destinationPath -ChildPath $workflowFileName
                
                # Enregistrer le workflow
                $workflowJson = $workflowDetails | ConvertTo-Json -Depth 10
                Set-Content -Path $workflowFilePath -Value $workflowJson -Encoding UTF8
                
                Write-Host "Workflow '$($workflowDetails.name)' synchronisé depuis n8n vers $destinationPath."
            } catch {
                Write-Error "Erreur lors de la synchronisation du workflow '$($workflow.name)' depuis n8n : $_"
            }
        }
        
        Write-Host "Synchronisation depuis n8n terminée."
    } catch {
        Write-Error "Erreur lors de la récupération des workflows depuis n8n : $_"
    }
}

# Exécuter la synchronisation selon la direction spécifiée
if ($Direction -eq "to-n8n" -or $Direction -eq "both") {
    Sync-WorkflowsToN8n -WorkflowsPaths $workflowsPaths
}

if ($Direction -eq "from-n8n" -or $Direction -eq "both") {
    Sync-WorkflowsFromN8n -WorkflowsPaths $workflowsPaths
}

Write-Host "Synchronisation terminée pour l'environnement: $Environment"
