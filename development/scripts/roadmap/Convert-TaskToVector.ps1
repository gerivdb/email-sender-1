# Convert-TaskToVector.ps1
# Script pour convertir les tâches de la roadmap en vecteurs avec leurs métadonnées

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "projet\roadmaps\active\roadmap_active.md",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "projet\roadmaps\vectors\task_vectors.json",
    
    [Parameter(Mandatory = $false)]
    [string]$ModelEndpoint = "https://api.openrouter.ai/api/v1/embeddings",
    
    [Parameter(Mandatory = $false)]
    [string]$ApiKey = $env:OPENROUTER_API_KEY,
    
    [Parameter(Mandatory = $false)]
    [string]$ModelName = "qwen/qwen2-7b",
    
    [Parameter(Mandatory = $false)]
    [int]$VectorDimension = 1536,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour écrire des messages de log
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
    }
}

# Fonction pour extraire les tâches de la roadmap
function Get-RoadmapTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath
    )
    
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Log "Le fichier roadmap $RoadmapPath n'existe pas." -Level Error
        return $null
    }
    
    try {
        $content = Get-Content -Path $RoadmapPath -Encoding UTF8 -Raw
        $lines = $content -split "`r?`n"
        $tasks = @()
        $currentSection = ""
        $currentDate = Get-Date -Format "yyyy-MM-dd"
        
        foreach ($line in $lines) {
            # Détecter les sections (titres)
            if ($line -match "^#{1,6}\s+(.+)$") {
                $currentSection = $Matches[1]
                continue
            }
            
            # Détecter les tâches
            if ($line -match "^\s*-\s+\[([ xX])\]\s+\*\*([0-9.]+)\*\*\s+(.+)$") {
                $status = if ($Matches[1] -match "[xX]") { "Complete" } else { "Incomplete" }
                $taskId = $Matches[2]
                $description = $Matches[3]
                $indentLevel = ($line -match "^\s+") ? ($Matches[0].Length / 2) : 0
                
                $task = [PSCustomObject]@{
                    TaskId = $taskId
                    Description = $description
                    Status = $status
                    Section = $currentSection
                    IndentLevel = $indentLevel
                    LastUpdated = $currentDate
                    ParentId = if ($indentLevel -gt 0) { $taskId -replace "\.[0-9]+$", "" } else { "" }
                    Text = "$taskId - $description"
                }
                
                $tasks += $task
            }
        }
        
        return $tasks
    }
    catch {
        Write-Log "Erreur lors de l'extraction des tâches: $_" -Level Error
        return $null
    }
}

# Fonction pour générer un vecteur aléatoire (pour les tests sans API)
function Get-RandomVector {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Dimension = 1536
    )
    
    $vector = @()
    for ($i = 0; $i -lt $Dimension; $i++) {
        $vector += [math]::Round((Get-Random -Minimum -1.0 -Maximum 1.0), 6)
    }
    
    return $vector
}

# Fonction pour obtenir un vecteur d'embedding via l'API OpenRouter
function Get-Embedding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $false)]
        [string]$Endpoint,
        
        [Parameter(Mandatory = $false)]
        [string]$Model
    )
    
    # Si l'API key n'est pas fournie, générer un vecteur aléatoire
    if ([string]::IsNullOrEmpty($ApiKey)) {
        Write-Log "Clé API non fournie. Génération d'un vecteur aléatoire." -Level Warning
        return Get-RandomVector
    }
    
    try {
        $headers = @{
            "Content-Type" = "application/json"
            "Authorization" = "Bearer $ApiKey"
        }
        
        $body = @{
            model = $Model
            input = $Text
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $headers -Body $body
        
        if ($response.data -and $response.data.embedding) {
            return $response.data.embedding
        }
        else {
            Write-Log "Réponse API invalide. Génération d'un vecteur aléatoire." -Level Warning
            return Get-RandomVector
        }
    }
    catch {
        Write-Log "Erreur lors de l'appel à l'API d'embedding: $_" -Level Error
        return Get-RandomVector
    }
}

# Fonction pour convertir les tâches en vecteurs
function Convert-TasksToVectors {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Tasks,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $false)]
        [string]$Endpoint,
        
        [Parameter(Mandatory = $false)]
        [string]$Model,
        
        [Parameter(Mandatory = $false)]
        [int]$VectorDimension
    )
    
    $taskVectors = @()
    $totalTasks = $Tasks.Count
    $currentTask = 0
    
    foreach ($task in $Tasks) {
        $currentTask++
        Write-Progress -Activity "Conversion des tâches en vecteurs" -Status "Traitement de la tâche $($task.TaskId)" -PercentComplete (($currentTask / $totalTasks) * 100)
        
        # Créer un texte enrichi pour l'embedding
        $enrichedText = "ID: $($task.TaskId) | Description: $($task.Description) | Section: $($task.Section) | Status: $($task.Status)"
        
        # Obtenir le vecteur d'embedding
        $vector = Get-Embedding -Text $enrichedText -ApiKey $ApiKey -Endpoint $Endpoint -Model $Model
        
        # Créer l'objet tâche vectorisée
        $taskVector = [PSCustomObject]@{
            TaskId = $task.TaskId
            Description = $task.Description
            Status = $task.Status
            Section = $task.Section
            IndentLevel = $task.IndentLevel
            LastUpdated = $task.LastUpdated
            ParentId = $task.ParentId
            Vector = $vector
            Metadata = @{
                VectorDimension = $vector.Count
                VectorModel = $Model
                VectorCreated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            }
        }
        
        $taskVectors += $taskVector
    }
    
    Write-Progress -Activity "Conversion des tâches en vecteurs" -Completed
    return $taskVectors
}

# Fonction principale
function Main {
    # Vérifier si le fichier de sortie existe déjà
    if ((Test-Path -Path $OutputPath) -and -not $Force) {
        Write-Log "Le fichier de sortie $OutputPath existe déjà. Utilisez -Force pour l'écraser." -Level Warning
        return
    }
    
    # Créer le dossier de sortie s'il n'existe pas
    $outputFolder = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $outputFolder)) {
        New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
        Write-Log "Dossier créé: $outputFolder" -Level Info
    }
    
    # Extraire les tâches de la roadmap
    Write-Log "Extraction des tâches depuis $RoadmapPath..." -Level Info
    $tasks = Get-RoadmapTasks -RoadmapPath $RoadmapPath
    
    if ($null -eq $tasks -or $tasks.Count -eq 0) {
        Write-Log "Aucune tâche trouvée dans la roadmap." -Level Warning
        return
    }
    
    Write-Log "$($tasks.Count) tâches extraites." -Level Success
    
    # Convertir les tâches en vecteurs
    Write-Log "Conversion des tâches en vecteurs..." -Level Info
    $taskVectors = Convert-TasksToVectors -Tasks $tasks -ApiKey $ApiKey -Endpoint $ModelEndpoint -Model $ModelName -VectorDimension $VectorDimension
    
    # Sauvegarder les vecteurs dans un fichier JSON
    try {
        $output = @{
            metadata = @{
                created = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                source = $RoadmapPath
                taskCount = $taskVectors.Count
                vectorDimension = $VectorDimension
                model = $ModelName
            }
            tasks = $taskVectors
        }
        
        $output | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
        Write-Log "Vecteurs de tâches sauvegardés dans $OutputPath" -Level Success
    }
    catch {
        Write-Log "Erreur lors de la sauvegarde des vecteurs: $_" -Level Error
    }
}

# Exécuter la fonction principale
Main
