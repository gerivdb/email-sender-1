#Requires -Version 5.1
<#
.SYNOPSIS
    Script d'indexation des PRD et tâches dans Qdrant pour le roadmapper.
.DESCRIPTION
    Ce script analyse les PRD et les tâches dans le projet, génère des embeddings
    et les indexe dans Qdrant pour permettre la recherche sémantique.
.NOTES
    Nom: index-documents.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-05-14
.EXAMPLE
    .\index-documents.ps1 -DocumentType PRD -Path "projet\guides\prd"
    Indexe tous les PRD dans le dossier spécifié.
.EXAMPLE
    .\index-documents.ps1 -DocumentType Task -Path "projet\tasks" -ForceReindex
    Réindexe toutes les tâches, même celles déjà indexées.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("PRD", "Task", "Roadmap", "All")]
    [string]$DocumentType,
    
    [Parameter(Mandatory = $false)]
    [string]$Path,
    
    [Parameter(Mandatory = $false)]
    [switch]$ForceReindex,
    
    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",
    
    [Parameter(Mandatory = $false)]
    [string]$OpenAIApiKey,
    
    [Parameter(Mandatory = $false)]
    [string]$OpenRouterApiKey
)

# Importer les modules nécessaires
Import-Module -Name "$PSScriptRoot\QdrantClient.psm1" -Force
Import-Module -Name "$PSScriptRoot\EmbeddingGenerator.psm1" -Force
Import-Module -Name "$PSScriptRoot\MarkdownParser.psm1" -Force

# Initialiser le client Qdrant
$qdrantClient = New-QdrantClient -Url $QdrantUrl

# Initialiser le générateur d'embeddings
if ($OpenAIApiKey) {
    $embeddingGenerator = New-EmbeddingGenerator -Provider "OpenAI" -ApiKey $OpenAIApiKey
} elseif ($OpenRouterApiKey) {
    $embeddingGenerator = New-EmbeddingGenerator -Provider "OpenRouter" -ApiKey $OpenRouterApiKey
} else {
    Write-Error "Aucune clé API fournie pour la génération d'embeddings."
    exit 1
}

# Fonction pour indexer un PRD
function Index-PRD {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    try {
        # Vérifier si le PRD existe déjà dans Qdrant
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        $prdId = "prd-$fileName"
        
        $exists = Test-QdrantPoint -CollectionName "prds" -PointId $prdId
        
        if ($exists -and -not $Force) {
            Write-Verbose "PRD $prdId déjà indexé. Utilisez -Force pour réindexer."
            return
        }
        
        # Parser le fichier Markdown
        $prdContent = Get-Content -Path $FilePath -Raw
        $prdData = ConvertFrom-Markdown -Content $prdContent
        
        # Extraire les métadonnées
        $title = $prdData.Title
        $description = $prdData.Description
        $sections = $prdData.Sections | ForEach-Object { $_.Title }
        $tags = @()
        
        # Détecter les tags dans le contenu
        if ($prdContent -match "module") { $tags += "module" }
        if ($prdContent -match "workflow") { $tags += "workflow" }
        if ($prdContent -match "integration") { $tags += "integration" }
        if ($prdContent -match "v14") { $tags += "v14" }
        
        # Générer l'embedding
        $embedding = $embeddingGenerator.GenerateEmbedding($prdContent)
        
        # Créer le payload
        $payload = @{
            title = $title
            description = $description
            sections = $sections
            path = $FilePath
            created_at = (Get-Item $FilePath).CreationTime.ToString("o")
            updated_at = (Get-Item $FilePath).LastWriteTime.ToString("o")
            status = "active"
            tags = $tags
        }
        
        # Indexer dans Qdrant
        $result = Add-QdrantPoint -CollectionName "prds" -PointId $prdId -Vector $embedding -Payload $payload
        
        if ($result.Status -eq "success") {
            Write-Host "PRD $prdId indexé avec succès." -ForegroundColor Green
        } else {
            Write-Error "Erreur lors de l'indexation du PRD $prdId: $($result.Message)"
        }
    } catch {
        Write-Error "Erreur lors de l'indexation du PRD $FilePath : $_"
    }
}

# Fonction pour indexer une tâche
function Index-Task {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    try {
        # Vérifier si la tâche existe déjà dans Qdrant
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        $taskId = "task-$fileName"
        
        $exists = Test-QdrantPoint -CollectionName "tasks" -PointId $taskId
        
        if ($exists -and -not $Force) {
            Write-Verbose "Tâche $taskId déjà indexée. Utilisez -Force pour réindexer."
            return
        }
        
        # Parser le fichier Markdown
        $taskContent = Get-Content -Path $FilePath -Raw
        $taskData = ConvertFrom-Markdown -Content $taskContent
        
        # Extraire les métadonnées
        $title = $taskData.Title
        $description = $taskData.Description
        $status = "pending"
        $priority = "medium"
        $estimatedHours = 0
        $dependencies = @()
        $roadmapId = ""
        
        # Extraire les informations spécifiques
        if ($taskContent -match "Statut:\s*(\w+)") {
            $status = $Matches[1]
        }
        
        if ($taskContent -match "Priorité:\s*(\w+)") {
            $priority = $Matches[1]
        }
        
        if ($taskContent -match "Estimation:\s*(\d+)") {
            $estimatedHours = [int]$Matches[1]
        }
        
        if ($taskContent -match "Dépendances:(.*?)(?:\r?\n\r?\n|\z)") {
            $depsText = $Matches[1]
            $dependencies = [regex]::Matches($depsText, "-\s*([\w\-\.]+)") | ForEach-Object { $_.Groups[1].Value }
        }
        
        if ($taskContent -match "ID:\s*([\w\-\.]+)") {
            $roadmapId = $Matches[1]
        }
        
        # Déterminer le PRD associé
        $prdId = ""
        if ($taskContent -match "PRD:\s*([\w\-\.]+)") {
            $prdId = "prd-$($Matches[1])"
        }
        
        # Générer l'embedding
        $embedding = $embeddingGenerator.GenerateEmbedding($taskContent)
        
        # Créer le payload
        $payload = @{
            title = $title
            description = $description
            prd_id = $prdId
            path = $FilePath
            status = $status
            priority = $priority
            estimated_hours = $estimatedHours
            dependencies = $dependencies
            roadmap_id = $roadmapId
            created_at = (Get-Item $FilePath).CreationTime.ToString("o")
            updated_at = (Get-Item $FilePath).LastWriteTime.ToString("o")
        }
        
        # Indexer dans Qdrant
        $result = Add-QdrantPoint -CollectionName "tasks" -PointId $taskId -Vector $embedding -Payload $payload
        
        if ($result.Status -eq "success") {
            Write-Host "Tâche $taskId indexée avec succès." -ForegroundColor Green
        } else {
            Write-Error "Erreur lors de l'indexation de la tâche $taskId: $($result.Message)"
        }
    } catch {
        Write-Error "Erreur lors de l'indexation de la tâche $FilePath : $_"
    }
}

# Fonction pour indexer une roadmap
function Index-Roadmap {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    try {
        # Vérifier si la roadmap existe déjà dans Qdrant
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        $roadmapId = "roadmap-$fileName"
        
        $exists = Test-QdrantPoint -CollectionName "roadmaps" -PointId $roadmapId
        
        if ($exists -and -not $Force) {
            Write-Verbose "Roadmap $roadmapId déjà indexée. Utilisez -Force pour réindexer."
            return
        }
        
        # Parser le fichier Markdown
        $roadmapContent = Get-Content -Path $FilePath -Raw
        $roadmapData = ConvertFrom-Markdown -Content $roadmapContent
        
        # Extraire les métadonnées
        $title = $roadmapData.Title
        $description = $roadmapData.Description
        
        # Extraire les tâches de la roadmap
        $tasks = [regex]::Matches($roadmapContent, "- \[ \] \*\*([\d\.]+)\*\* (.+)") | ForEach-Object {
            @{
                id = $_.Groups[1].Value
                title = $_.Groups[2].Value
            }
        }
        
        # Générer l'embedding
        $embedding = $embeddingGenerator.GenerateEmbedding($roadmapContent)
        
        # Créer le payload
        $payload = @{
            title = $title
            description = $description
            path = $FilePath
            tasks = $tasks
            created_at = (Get-Item $FilePath).CreationTime.ToString("o")
            updated_at = (Get-Item $FilePath).LastWriteTime.ToString("o")
        }
        
        # Indexer dans Qdrant
        $result = Add-QdrantPoint -CollectionName "roadmaps" -PointId $roadmapId -Vector $embedding -Payload $payload
        
        if ($result.Status -eq "success") {
            Write-Host "Roadmap $roadmapId indexée avec succès." -ForegroundColor Green
        } else {
            Write-Error "Erreur lors de l'indexation de la roadmap $roadmapId: $($result.Message)"
        }
    } catch {
        Write-Error "Erreur lors de l'indexation de la roadmap $FilePath : $_"
    }
}

# Vérifier si les collections existent, sinon les créer
$collections = @("prds", "tasks", "roadmaps")
foreach ($collection in $collections) {
    $exists = Test-QdrantCollection -CollectionName $collection
    
    if (-not $exists) {
        Write-Host "Création de la collection $collection..." -ForegroundColor Yellow
        $result = New-QdrantCollection -CollectionName $collection -VectorSize 1536
        
        if ($result.Status -ne "success") {
            Write-Error "Erreur lors de la création de la collection $collection: $($result.Message)"
            exit 1
        }
    }
}

# Indexer les documents selon le type spécifié
switch ($DocumentType) {
    "PRD" {
        if (-not $Path) {
            $Path = "projet\guides\prd"
        }
        
        Write-Host "Indexation des PRD dans $Path..." -ForegroundColor Cyan
        
        Get-ChildItem -Path $Path -Filter "*.md" -Recurse | ForEach-Object {
            Index-PRD -FilePath $_.FullName -Force:$ForceReindex
        }
    }
    "Task" {
        if (-not $Path) {
            $Path = "projet\tasks"
        }
        
        Write-Host "Indexation des tâches dans $Path..." -ForegroundColor Cyan
        
        Get-ChildItem -Path $Path -Filter "*.md" -Recurse | ForEach-Object {
            Index-Task -FilePath $_.FullName -Force:$ForceReindex
        }
    }
    "Roadmap" {
        if (-not $Path) {
            $Path = "projet\roadmaps\plans"
        }
        
        Write-Host "Indexation des roadmaps dans $Path..." -ForegroundColor Cyan
        
        Get-ChildItem -Path $Path -Filter "*.md" -Recurse | ForEach-Object {
            Index-Roadmap -FilePath $_.FullName -Force:$ForceReindex
        }
    }
    "All" {
        Write-Host "Indexation de tous les documents..." -ForegroundColor Cyan
        
        # Indexer les PRD
        $prdPath = "projet\guides\prd"
        Write-Host "Indexation des PRD dans $prdPath..." -ForegroundColor Cyan
        Get-ChildItem -Path $prdPath -Filter "*.md" -Recurse | ForEach-Object {
            Index-PRD -FilePath $_.FullName -Force:$ForceReindex
        }
        
        # Indexer les tâches
        $taskPath = "projet\tasks"
        Write-Host "Indexation des tâches dans $taskPath..." -ForegroundColor Cyan
        Get-ChildItem -Path $taskPath -Filter "*.md" -Recurse | ForEach-Object {
            Index-Task -FilePath $_.FullName -Force:$ForceReindex
        }
        
        # Indexer les roadmaps
        $roadmapPath = "projet\roadmaps\plans"
        Write-Host "Indexation des roadmaps dans $roadmapPath..." -ForegroundColor Cyan
        Get-ChildItem -Path $roadmapPath -Filter "*.md" -Recurse | ForEach-Object {
            Index-Roadmap -FilePath $_.FullName -Force:$ForceReindex
        }
    }
}

Write-Host "Indexation terminée." -ForegroundColor Green
