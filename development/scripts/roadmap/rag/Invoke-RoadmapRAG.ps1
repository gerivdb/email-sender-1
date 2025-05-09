# Invoke-RoadmapRAG.ps1
# Script pour interagir avec le système RAG de roadmaps
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet(
        "Vectorize", "Search", "Status", "Reset",
        "Help"
    )]
    [string]$Action = "Help",
    
    [Parameter(Mandatory = $false)]
    [string]$Query,
    
    [Parameter(Mandatory = $false)]
    [string]$InventoryPath = "projet/roadmaps/analysis/inventory.json",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("text", "json", "markdown")]
    [string]$OutputFormat = "text",
    
    [Parameter(Mandatory = $false)]
    [int]$Limit = 10,
    
    [Parameter(Mandatory = $false)]
    [string]$FilterPath,
    
    [Parameter(Mandatory = $false)]
    [string]$Model = "all-MiniLM-L6-v2",
    
    [Parameter(Mandatory = $false)]
    [string]$Collection = "roadmaps",
    
    [Parameter(Mandatory = $false)]
    [string]$Host = "localhost",
    
    [Parameter(Mandatory = $false)]
    [int]$Port = 6333,
    
    [Parameter(Mandatory = $false)]
    [int]$ChunkSize = 512,
    
    [Parameter(Mandatory = $false)]
    [int]$ChunkOverlap = 128,
    
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
    Write-Host "Invoke-RoadmapRAG.ps1 - Interface pour le système RAG de roadmaps"
    Write-Host ""
    Write-Host "SYNTAXE:"
    Write-Host "    .\Invoke-RoadmapRAG.ps1 -Action <Action> [options]"
    Write-Host ""
    Write-Host "ACTIONS:"
    Write-Host "    Vectorize     : Vectorise les roadmaps et les stocke dans Qdrant"
    Write-Host "    Search        : Recherche dans les roadmaps vectorisées"
    Write-Host "    Status        : Affiche le statut du système RAG"
    Write-Host "    Reset         : Réinitialise la collection Qdrant"
    Write-Host "    Help          : Affiche cette aide"
    Write-Host ""
    Write-Host "OPTIONS COMMUNES:"
    Write-Host "    -Model        : Nom du modèle SentenceTransformer (défaut: all-MiniLM-L6-v2)"
    Write-Host "    -Collection   : Nom de la collection Qdrant (défaut: roadmaps)"
    Write-Host "    -Host         : Hôte du serveur Qdrant (défaut: localhost)"
    Write-Host "    -Port         : Port du serveur Qdrant (défaut: 6333)"
    Write-Host ""
    Write-Host "OPTIONS POUR VECTORIZE:"
    Write-Host "    -InventoryPath: Chemin vers le fichier d'inventaire JSON (défaut: projet/roadmaps/analysis/inventory.json)"
    Write-Host "    -ChunkSize    : Taille maximale des chunks (défaut: 512)"
    Write-Host "    -ChunkOverlap : Chevauchement entre les chunks (défaut: 128)"
    Write-Host "    -Force        : Force la réindexation même si la collection existe déjà"
    Write-Host ""
    Write-Host "OPTIONS POUR SEARCH:"
    Write-Host "    -Query        : Requête de recherche"
    Write-Host "    -Limit        : Nombre maximum de résultats (défaut: 10)"
    Write-Host "    -OutputFormat : Format de sortie (text, json, markdown) (défaut: text)"
    Write-Host "    -OutputPath   : Fichier de sortie (si non spécifié, affiche sur la sortie standard)"
    Write-Host "    -FilterPath   : Fichier JSON contenant les filtres à appliquer"
    Write-Host ""
    Write-Host "EXEMPLES:"
    Write-Host "    # Vectoriser les roadmaps"
    Write-Host "    .\Invoke-RoadmapRAG.ps1 -Action Vectorize -InventoryPath 'projet/roadmaps/analysis/inventory.json'"
    Write-Host ""
    Write-Host "    # Rechercher dans les roadmaps"
    Write-Host "    .\Invoke-RoadmapRAG.ps1 -Action Search -Query 'implémentation du backend' -Limit 5 -OutputFormat markdown"
    Write-Host ""
    Write-Host "    # Afficher le statut du système RAG"
    Write-Host "    .\Invoke-RoadmapRAG.ps1 -Action Status"
    Write-Host ""
    Write-Host "    # Réinitialiser la collection Qdrant"
    Write-Host "    .\Invoke-RoadmapRAG.ps1 -Action Reset -Collection roadmaps -Force"
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
        $output = python -c "import sentence_transformers, qdrant_client" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Dépendances Python trouvées." -Level "Info"
            return $true
        }
        else {
            Write-Log "Dépendances Python manquantes." -Level "Error"
            Write-Log "Installez-les avec: pip install sentence-transformers qdrant-client" -Level "Info"
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

# Fonction pour vectoriser les roadmaps
function Invoke-Vectorize {
    param (
        [string]$InventoryPath,
        [string]$Model,
        [string]$Collection,
        [string]$Host,
        [int]$Port,
        [int]$ChunkSize,
        [int]$ChunkOverlap,
        [switch]$Force
    )
    
    Write-Log "Vectorisation des roadmaps..." -Level "Info"
    
    # Vérifier si le fichier d'inventaire existe
    if (-not (Test-Path -Path $InventoryPath)) {
        Write-Log "Le fichier d'inventaire $InventoryPath n'existe pas." -Level "Error"
        Write-Log "Exécutez d'abord Invoke-RoadmapAnalysis.ps1 pour créer l'inventaire." -Level "Info"
        return $false
    }
    
    # Vérifier si Python est installé
    if (-not (Test-PythonInstalled)) {
        return $false
    }
    
    # Vérifier si les dépendances Python sont installées
    if (-not (Test-PythonDependencies)) {
        return $false
    }
    
    # Vérifier si Qdrant est en cours d'exécution
    if (-not (Test-QdrantRunning -Host $Host -Port $Port)) {
        return $false
    }
    
    # Construire la commande Python
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "vectorize_roadmaps.py"
    $command = "python `"$scriptPath`" --inventory `"$InventoryPath`" --model `"$Model`" --collection `"$Collection`" --host `"$Host`" --port $Port --chunk-size $ChunkSize --chunk-overlap $ChunkOverlap"
    
    # Exécuter la commande
    Write-Log "Exécution de la commande: $command" -Level "Info"
    Invoke-Expression $command
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Vectorisation terminée avec succès." -Level "Success"
        return $true
    }
    else {
        Write-Log "Erreur lors de la vectorisation." -Level "Error"
        return $false
    }
}

# Fonction pour rechercher dans les roadmaps
function Invoke-Search {
    param (
        [string]$Query,
        [string]$Model,
        [string]$Collection,
        [string]$Host,
        [int]$Port,
        [int]$Limit,
        [string]$OutputFormat,
        [string]$OutputPath,
        [string]$FilterPath
    )
    
    Write-Log "Recherche dans les roadmaps..." -Level "Info"
    
    # Vérifier si la requête est spécifiée
    if ([string]::IsNullOrEmpty($Query)) {
        Write-Log "Aucune requête spécifiée." -Level "Error"
        return $false
    }
    
    # Vérifier si Python est installé
    if (-not (Test-PythonInstalled)) {
        return $false
    }
    
    # Vérifier si les dépendances Python sont installées
    if (-not (Test-PythonDependencies)) {
        return $false
    }
    
    # Vérifier si Qdrant est en cours d'exécution
    if (-not (Test-QdrantRunning -Host $Host -Port $Port)) {
        return $false
    }
    
    # Construire la commande Python
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "search_roadmaps.py"
    $command = "python `"$scriptPath`" `"$Query`" --model `"$Model`" --collection `"$Collection`" --host `"$Host`" --port $Port --limit $Limit --format $OutputFormat"
    
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $command += " --output `"$OutputPath`""
    }
    
    if (-not [string]::IsNullOrEmpty($FilterPath)) {
        $command += " --filter-file `"$FilterPath`""
    }
    
    # Exécuter la commande
    Write-Log "Exécution de la commande: $command" -Level "Info"
    Invoke-Expression $command
    
    if ($LASTEXITCODE -eq 0) {
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            Write-Log "Recherche terminée avec succès. Résultats enregistrés dans $OutputPath" -Level "Success"
        }
        else {
            Write-Log "Recherche terminée avec succès." -Level "Success"
        }
        return $true
    }
    else {
        Write-Log "Erreur lors de la recherche." -Level "Error"
        return $false
    }
}

# Fonction pour afficher le statut du système RAG
function Show-Status {
    param (
        [string]$Host,
        [int]$Port,
        [string]$Collection
    )
    
    Write-Log "Vérification du statut du système RAG..." -Level "Info"
    
    # Vérifier si Qdrant est en cours d'exécution
    if (-not (Test-QdrantRunning -Host $Host -Port $Port)) {
        return $false
    }
    
    # Récupérer les informations sur la collection
    try {
        $response = Invoke-WebRequest -Uri "http://$Host:$Port/collections/$Collection" -Method GET -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            $collectionInfo = $response.Content | ConvertFrom-Json
            
            Write-Host "Statut du système RAG:"
            Write-Host ""
            Write-Host "Qdrant:"
            Write-Host "  - Hôte: $Host"
            Write-Host "  - Port: $Port"
            Write-Host ""
            Write-Host "Collection:"
            Write-Host "  - Nom: $Collection"
            Write-Host "  - Vecteurs: $($collectionInfo.result.vectors_count)"
            Write-Host "  - Dimension: $($collectionInfo.result.config.params.vectors.size)"
            Write-Host "  - Distance: $($collectionInfo.result.config.params.vectors.distance)"
            Write-Host ""
            
            return $true
        }
        else {
            Write-Log "La collection $Collection n'existe pas." -Level "Error"
            return $false
        }
    }
    catch {
        Write-Log "La collection $Collection n'existe pas." -Level "Error"
        return $false
    }
}

# Fonction pour réinitialiser la collection Qdrant
function Reset-Collection {
    param (
        [string]$Host,
        [int]$Port,
        [string]$Collection,
        [switch]$Force
    )
    
    Write-Log "Réinitialisation de la collection $Collection..." -Level "Info"
    
    # Vérifier si Qdrant est en cours d'exécution
    if (-not (Test-QdrantRunning -Host $Host -Port $Port)) {
        return $false
    }
    
    # Demander confirmation si -Force n'est pas spécifié
    if (-not $Force) {
        $confirmation = Read-Host "Êtes-vous sûr de vouloir réinitialiser la collection $Collection ? (O/N)"
        if ($confirmation -ne "O") {
            Write-Log "Opération annulée." -Level "Info"
            return $false
        }
    }
    
    # Supprimer la collection
    try {
        $response = Invoke-WebRequest -Uri "http://$Host:$Port/collections/$Collection" -Method DELETE -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Log "Collection $Collection supprimée avec succès." -Level "Success"
            return $true
        }
        else {
            Write-Log "Erreur lors de la suppression de la collection $Collection." -Level "Error"
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors de la suppression de la collection $Collection: $_" -Level "Error"
        return $false
    }
}

# Fonction principale
function Invoke-RoadmapRAG {
    param (
        [string]$Action,
        [string]$Query,
        [string]$InventoryPath,
        [string]$OutputPath,
        [string]$OutputFormat,
        [int]$Limit,
        [string]$FilterPath,
        [string]$Model,
        [string]$Collection,
        [string]$Host,
        [int]$Port,
        [int]$ChunkSize,
        [int]$ChunkOverlap,
        [switch]$Force
    )
    
    # Exécuter l'action demandée
    switch ($Action) {
        "Vectorize" {
            return Invoke-Vectorize -InventoryPath $InventoryPath -Model $Model -Collection $Collection -Host $Host -Port $Port -ChunkSize $ChunkSize -ChunkOverlap $ChunkOverlap -Force:$Force
        }
        "Search" {
            return Invoke-Search -Query $Query -Model $Model -Collection $Collection -Host $Host -Port $Port -Limit $Limit -OutputFormat $OutputFormat -OutputPath $OutputPath -FilterPath $FilterPath
        }
        "Status" {
            return Show-Status -Host $Host -Port $Port -Collection $Collection
        }
        "Reset" {
            return Reset-Collection -Host $Host -Port $Port -Collection $Collection -Force:$Force
        }
        "Help" {
            Show-Help
            return $true
        }
        default {
            Write-Log "Action non reconnue : $Action" -Level "Error"
            Show-Help
            return $false
        }
    }
}

# Exécution principale
try {
    $result = Invoke-RoadmapRAG -Action $Action -Query $Query -InventoryPath $InventoryPath -OutputPath $OutputPath -OutputFormat $OutputFormat -Limit $Limit -FilterPath $FilterPath -Model $Model -Collection $Collection -Host $Host -Port $Port -ChunkSize $ChunkSize -ChunkOverlap $ChunkOverlap -Force:$Force
    
    # Retourner le résultat
    return $result
}
catch {
    Write-Log "Erreur lors de l'exécution de l'action $Action : $_" -Level "Error"
    throw $_
}
