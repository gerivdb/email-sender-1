# Script de gestion complète du système RAG
# Permet d'indexer, rechercher et gérer les documents

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("index", "search", "status", "clear")]
    [string]$Action,
    
    [string]$DocumentPath,
    [string]$Query,
    [string]$CollectionName = "documents",
    [string]$QdrantUrl = "http://localhost:6333"
)

function Test-QdrantConnection {
    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/" -Method GET
        Write-Host "✓ QDrant connecté" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "✗ QDrant non accessible sur $QdrantUrl"
        return $false
    }
}

function Get-CollectionStatus {
    param([string]$Collection)
    
    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections/$Collection" -Method GET
        Write-Host "Collection '$Collection':" -ForegroundColor Cyan
        Write-Host "  - Points: $($response.result.points_count)" -ForegroundColor White
        Write-Host "  - Vecteurs: $($response.result.vectors_count)" -ForegroundColor White
        Write-Host "  - Statut: $($response.result.status)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Warning "Collection '$Collection' n'existe pas ou n'est pas accessible"
        return $false
    }
}

function Clear-Collection {
    param([string]$Collection)
    
    $confirm = Read-Host "Êtes-vous sûr de vouloir vider la collection '$Collection'? (oui/non)"
    if ($confirm -eq "oui") {
        try {
            Invoke-RestMethod -Uri "$QdrantUrl/collections/$Collection" -Method DELETE
            Write-Host "✓ Collection '$Collection' supprimée" -ForegroundColor Green
        }
        catch {
            Write-Error "Erreur lors de la suppression: $($_.Exception.Message)"
        }
    }
}

function Start-Indexing {
    param([string]$Path)
    
    if (-not $Path) {
        Write-Error "Chemin du document requis pour l'indexation"
        return
    }
    
    if (-not (Test-Path $Path)) {
        Write-Error "Le fichier/dossier '$Path' n'existe pas"
        return
    }
    
    Write-Host "Lancement de l'indexation..." -ForegroundColor Yellow
    
    $vectorizerScript = Join-Path $PSScriptRoot "Vectoriser-RAG.ps1"
    if (Test-Path $vectorizerScript) {
        & $vectorizerScript -DocumentPath $Path -CollectionName $CollectionName
    } else {
        Write-Error "Script de vectorisation non trouvé: $vectorizerScript"
    }
}

function Start-Search {
    param([string]$SearchQuery)
    
    if (-not $SearchQuery) {
        Write-Error "Requête de recherche requise"
        return
    }
    
    Write-Host "Lancement de la recherche RAG..." -ForegroundColor Yellow
    
    $searchScript = Join-Path $PSScriptRoot "RAG-Search.ps1"
    if (Test-Path $searchScript) {
        & $searchScript -Query $SearchQuery -CollectionName $CollectionName
    } else {
        Write-Error "Script de recherche non trouvé: $searchScript"
    }
}

# Script principal
Write-Host "=== GESTIONNAIRE RAG QDRANT ===" -ForegroundColor Green
Write-Host "Action: $Action" -ForegroundColor Cyan

if (-not (Test-QdrantConnection)) {
    exit 1
}

switch ($Action) {
    "status" {
        Write-Host "`nStatut du système RAG:" -ForegroundColor Yellow
        Get-CollectionStatus -Collection $CollectionName
    }
    
    "index" {
        Start-Indexing -Path $DocumentPath
    }
    
    "search" {
        Start-Search -SearchQuery $Query
    }
    
    "clear" {
        Clear-Collection -Collection $CollectionName
    }
}

Write-Host "`n=== TERMINÉ ===" -ForegroundColor Green