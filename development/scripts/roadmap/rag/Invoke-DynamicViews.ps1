# Invoke-DynamicViews.ps1
# Script pour générer des vues dynamiques à partir des données vectorisées
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet(
        "TaskList", "Kanban", "Timeline",
        "Help"
    )]
    [string]$ViewType = "Help",
    
    [Parameter(Mandatory = $false)]
    [string]$Query,
    
    [Parameter(Mandatory = $false)]
    [string]$FilterPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [string]$Title,
    
    [Parameter(Mandatory = $false)]
    [string]$Description,
    
    [Parameter(Mandatory = $false)]
    [string]$Model = "all-MiniLM-L6-v2",
    
    [Parameter(Mandatory = $false)]
    [string]$Collection = "roadmaps",
    
    [Parameter(Mandatory = $false)]
    [string]$Host = "localhost",
    
    [Parameter(Mandatory = $false)]
    [int]$Port = 6333,
    
    [Parameter(Mandatory = $false)]
    [string]$TemplatesDir = "projet/roadmaps/templates",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "projet/roadmaps/views",
    
    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction de journalisation simplifiée
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
    }
    
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message" -ForegroundColor $color
}

# Fonction pour afficher l'aide
function Show-Help {
    Write-Host "Invoke-DynamicViews.ps1 - Script pour générer des vues dynamiques à partir des données vectorisées"
    Write-Host ""
    Write-Host "SYNTAXE:"
    Write-Host "    .\Invoke-DynamicViews.ps1 -ViewType <ViewType> [options]"
    Write-Host ""
    Write-Host "TYPES DE VUES:"
    Write-Host "    TaskList     : Liste des tâches"
    Write-Host "    Kanban       : Tableau Kanban"
    Write-Host "    Timeline     : Chronologie"
    Write-Host "    Help         : Affiche cette aide"
    Write-Host ""
    Write-Host "OPTIONS:"
    Write-Host "    -Query        : Requête de recherche"
    Write-Host "    -FilterPath   : Fichier JSON contenant les filtres à appliquer"
    Write-Host "    -OutputPath   : Chemin vers le fichier de sortie"
    Write-Host "    -Title        : Titre de la vue"
    Write-Host "    -Description  : Description de la vue"
    Write-Host "    -Model        : Nom du modèle SentenceTransformer (défaut: all-MiniLM-L6-v2)"
    Write-Host "    -Collection   : Nom de la collection Qdrant (défaut: roadmaps)"
    Write-Host "    -Host         : Hôte du serveur Qdrant (défaut: localhost)"
    Write-Host "    -Port         : Port du serveur Qdrant (défaut: 6333)"
    Write-Host "    -TemplatesDir : Dossier contenant les templates (défaut: projet/roadmaps/templates)"
    Write-Host "    -OutputDir    : Dossier de sortie pour les vues générées (défaut: projet/roadmaps/views)"
    Write-Host "    -OpenInEditor : Ouvre la vue générée dans l'éditeur par défaut"
    Write-Host "    -Force        : Force l'écrasement des fichiers existants"
    Write-Host ""
    Write-Host "EXEMPLES:"
    Write-Host "    # Générer une liste de tâches"
    Write-Host "    .\Invoke-DynamicViews.ps1 -ViewType TaskList -Query 'implémentation du backend' -OutputPath 'projet/roadmaps/views/backend_tasks.md'"
    Write-Host ""
    Write-Host "    # Générer un tableau Kanban"
    Write-Host "    .\Invoke-DynamicViews.ps1 -ViewType Kanban -Title 'Tâches prioritaires' -Description 'Tâches à haute priorité' -OutputPath 'projet/roadmaps/views/priority_kanban.md'"
    Write-Host ""
    Write-Host "    # Générer une chronologie"
    Write-Host "    .\Invoke-DynamicViews.ps1 -ViewType Timeline -OutputPath 'projet/roadmaps/views/roadmap_timeline.md'"
}

# Fonction pour vérifier si Python est installé
function Test-PythonInstalled {
    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python (\d+\.\d+\.\d+)") {
            Write-Log "Python $($Matches[1]) trouvé." -Level "Info"
            return $true
        }
        else {
            Write-Log "Python non trouvé." -Level "Error"
            return $false
        }
    }
    catch {
        Write-Log "Python non trouvé." -Level "Error"
        return $false
    }
}

# Fonction pour vérifier si les dépendances Python sont installées
function Test-PythonDependencies {
    try {
        $output = python -c "import sentence_transformers, qdrant_client, jinja2" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Dépendances Python trouvées." -Level "Info"
            return $true
        }
        else {
            Write-Log "Dépendances Python manquantes." -Level "Error"
            Write-Log "Installez-les avec: pip install sentence-transformers qdrant-client jinja2" -Level "Info"
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors de la vérification des dépendances Python: $_" -Level "Error"
        return $false
    }
}

# Fonction pour vérifier si Qdrant est en cours d'exécution
function Test-QdrantRunning {
    param (
        [string]$Host,
        [int]$Port
    )
    
    try {
        $response = Invoke-WebRequest -Uri "http://$Host:$Port/collections" -Method GET -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Log "Qdrant est en cours d'exécution sur $Host:$Port." -Level "Info"
            return $true
        }
        else {
            Write-Log "Qdrant n'est pas accessible sur $Host:$Port." -Level "Error"
            return $false
        }
    }
    catch {
        Write-Log "Qdrant n'est pas accessible sur $Host:$Port." -Level "Error"
        Write-Log "Assurez-vous que Qdrant est en cours d'exécution." -Level "Info"
        return $false
    }
}

# Fonction pour générer une vue
function Invoke-GenerateView {
    param (
        [string]$ViewType,
        [string]$Query,
        [string]$FilterPath,
        [string]$OutputPath,
        [string]$Title,
        [string]$Description,
        [string]$Model,
        [string]$Collection,
        [string]$Host,
        [int]$Port,
        [string]$TemplatesDir,
        [string]$OutputDir,
        [switch]$Force
    )
    
    Write-Log "Génération de la vue $ViewType..." -Level "Info"
    
    # Vérifier si Python est installé
    if (-not (Test-PythonInstalled)) {
        return $null
    }
    
    # Vérifier si les dépendances Python sont installées
    if (-not (Test-PythonDependencies)) {
        return $null
    }
    
    # Vérifier si Qdrant est en cours d'exécution
    if (-not (Test-QdrantRunning -Host $Host -Port $Port)) {
        return $null
    }
    
    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }
    
    # Construire la commande Python
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Generate-DynamicViews.py"
    
    # Convertir le type de vue
    $pythonViewType = switch ($ViewType) {
        "TaskList" { "task-list" }
        "Kanban" { "kanban" }
        "Timeline" { "timeline" }
        default { "task-list" }
    }
    
    $command = "python `"$scriptPath`" --view-type $pythonViewType"
    
    if ($Query) {
        $command += " --query `"$Query`""
    }
    
    if ($FilterPath) {
        $command += " --filter-file `"$FilterPath`""
    }
    
    if ($OutputPath) {
        $outputFileName = Split-Path -Path $OutputPath -Leaf
        $command += " --output `"$outputFileName`""
    }
    
    if ($Title) {
        $command += " --title `"$Title`""
    }
    
    if ($Description) {
        $command += " --description `"$Description`""
    }
    
    $command += " --model `"$Model`" --collection `"$Collection`" --host `"$Host`" --port $Port --templates-dir `"$TemplatesDir`" --output-dir `"$OutputDir`""
    
    # Exécuter la commande
    Write-Log "Exécution de la commande: $command" -Level "Info"
    Invoke-Expression $command
    
    if ($LASTEXITCODE -eq 0) {
        # Déterminer le chemin vers le fichier généré
        $outputFileName = if ($OutputPath) {
            Split-Path -Path $OutputPath -Leaf
        }
        else {
            switch ($ViewType) {
                "TaskList" { "task_list.md" }
                "Kanban" { "kanban.md" }
                "Timeline" { "timeline.md" }
                default { "task_list.md" }
            }
        }
        
        $generatedFilePath = Join-Path -Path $OutputDir -ChildPath $outputFileName
        
        Write-Log "Vue générée avec succès dans $generatedFilePath" -Level "Success"
        return $generatedFilePath
    }
    else {
        Write-Log "Erreur lors de la génération de la vue." -Level "Error"
        return $null
    }
}

# Fonction principale
function Invoke-DynamicViews {
    param (
        [string]$ViewType,
        [string]$Query,
        [string]$FilterPath,
        [string]$OutputPath,
        [string]$Title,
        [string]$Description,
        [string]$Model,
        [string]$Collection,
        [string]$Host,
        [int]$Port,
        [string]$TemplatesDir,
        [string]$OutputDir,
        [switch]$OpenInEditor,
        [switch]$Force
    )
    
    # Exécuter l'action demandée
    switch ($ViewType) {
        "TaskList" {
            $generatedFilePath = Invoke-GenerateView -ViewType $ViewType -Query $Query -FilterPath $FilterPath -OutputPath $OutputPath -Title $Title -Description $Description -Model $Model -Collection $Collection -Host $Host -Port $Port -TemplatesDir $TemplatesDir -OutputDir $OutputDir -Force:$Force
            break
        }
        "Kanban" {
            $generatedFilePath = Invoke-GenerateView -ViewType $ViewType -Query $Query -FilterPath $FilterPath -OutputPath $OutputPath -Title $Title -Description $Description -Model $Model -Collection $Collection -Host $Host -Port $Port -TemplatesDir $TemplatesDir -OutputDir $OutputDir -Force:$Force
            break
        }
        "Timeline" {
            $generatedFilePath = Invoke-GenerateView -ViewType $ViewType -Query $Query -FilterPath $FilterPath -OutputPath $OutputPath -Title $Title -Description $Description -Model $Model -Collection $Collection -Host $Host -Port $Port -TemplatesDir $TemplatesDir -OutputDir $OutputDir -Force:$Force
            break
        }
        "Help" {
            Show-Help
            return $null
        }
        default {
            Write-Log "Type de vue non reconnu : $ViewType" -Level "Error"
            Show-Help
            return $null
        }
    }
    
    # Ouvrir la vue générée dans l'éditeur si demandé
    if ($generatedFilePath -and $OpenInEditor) {
        Write-Log "Ouverture de la vue dans l'éditeur..." -Level "Info"
        Start-Process $generatedFilePath
    }
    
    return $generatedFilePath
}

# Exécution principale
try {
    $result = Invoke-DynamicViews -ViewType $ViewType -Query $Query -FilterPath $FilterPath -OutputPath $OutputPath -Title $Title -Description $Description -Model $Model -Collection $Collection -Host $Host -Port $Port -TemplatesDir $TemplatesDir -OutputDir $OutputDir -OpenInEditor:$OpenInEditor -Force:$Force
    
    # Retourner le résultat
    return $result
}
catch {
    Write-Log "Erreur lors de la génération de la vue : $_" -Level "Error"
    throw $_
}
