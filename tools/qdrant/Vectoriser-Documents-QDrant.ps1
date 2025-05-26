# Vectoriser-Documents-QDrant.ps1
# Script simple pour vectoriser des documents avec QDrant standalone

param(
    [Parameter(Mandatory = $true)]
    [string]$CheminDocument,
    
    [Parameter(Mandatory = $false)]
    [string]$NomCollection = "documents",
    
    [Parameter(Mandatory = $false)]
    [string]$UrlQdrant = "http://localhost:6333",
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

function Write-Log {
    param([string]$Message, [string]$Niveau = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Niveau] $Message" -ForegroundColor $(
        switch($Niveau) {
            "INFO" { "Cyan" }
            "SUCCESS" { "Green" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
        }
    )
}

function Creer-Collection-QDrant {
    param([string]$Nom, [string]$Url)
    
    $body = @{
        vectors = @{
            size = 1536
            distance = "Cosine"
        }
    } | ConvertTo-Json -Depth 3
    
    try {
        $response = Invoke-RestMethod -Uri "$Url/collections/$Nom" -Method Put -Body $body -ContentType "application/json"
        Write-Log "Collection '$Nom' créée avec succès" "SUCCESS"
        return $true
    } catch {
        if ($_.Exception.Response.StatusCode -eq 409) {
            Write-Log "Collection '$Nom' existe déjà" "INFO"
            return $true
        } else {
            Write-Log "Erreur lors de la création de la collection: $_" "ERROR"
            return $false
        }
    }
}

function Vectoriser-Texte {
    param([string]$Texte)
    
    # Simulation d'embeddings (remplacer par un vrai service d'embeddings)
    # En production, utiliser OpenAI, Hugging Face, ou un modèle local
    $vectors = @()
    for ($i = 0; $i -lt 1536; $i++) {
        $vectors += [math]::Round((Get-Random -Minimum -1.0 -Maximum 1.0), 6)
    }
    
    return $vectors
}

function Ajouter-Document-QDrant {
    param([string]$Url, [string]$Collection, [hashtable]$Document)
    
    $body = @{
        points = @(
            @{
                id = $Document.id
                vector = $Document.vector
                payload = $Document.payload
            }
        )
    } | ConvertTo-Json -Depth 4
    
    try {
        $response = Invoke-RestMethod -Uri "$Url/collections/$Collection/points" -Method Put -Body $body -ContentType "application/json"
        Write-Log "Document ajouté avec ID: $($Document.id)" "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de l'ajout du document: $_" "ERROR"
        return $false
    }
}

# Script principal
Write-Log "=== Vectorisation de documents avec QDrant ===" "INFO"

# Vérifier que le fichier existe
if (-not (Test-Path $CheminDocument)) {
    Write-Log "Fichier non trouvé: $CheminDocument" "ERROR"
    exit 1
}

# Vérifier la connexion à QDrant
try {
    $healthCheck = Invoke-RestMethod -Uri "$UrlQdrant/" -Method Get -TimeoutSec 5
    Write-Log "QDrant accessible - Version: $($healthCheck.version)" "SUCCESS"
} catch {
    Write-Log "QDrant non accessible sur $UrlQdrant" "ERROR"
    exit 1
}

# Créer la collection si nécessaire
if (-not (Creer-Collection-QDrant -Nom $NomCollection -Url $UrlQdrant)) {
    exit 1
}

# Lire et traiter le document
Write-Log "Lecture du document: $CheminDocument" "INFO"
$contenu = Get-Content -Path $CheminDocument -Encoding UTF8 -Raw

if ([string]::IsNullOrWhiteSpace($contenu)) {
    Write-Log "Le document est vide" "WARNING"
    exit 0
}

# Découper le document en chunks (simplifié)
$chunks = @()
$lignes = $contenu -split "`n"
$chunkSize = 10  # 10 lignes par chunk
$chunkId = 1

for ($i = 0; $i -lt $lignes.Count; $i += $chunkSize) {
    $chunk = $lignes[$i..([math]::Min($i + $chunkSize - 1, $lignes.Count - 1))] -join "`n"
    
    if (-not [string]::IsNullOrWhiteSpace($chunk.Trim())) {
        $chunks += @{
            id = $chunkId
            texte = $chunk.Trim()
            source = $CheminDocument
            ligne_debut = $i + 1
            ligne_fin = [math]::Min($i + $chunkSize, $lignes.Count)
        }
        $chunkId++
    }
}

Write-Log "Document découpé en $($chunks.Count) chunks" "INFO"

# Vectoriser et ajouter chaque chunk
$compteur = 0
foreach ($chunk in $chunks) {
    $compteur++
    
    if ($Verbose) {
        Write-Log "Traitement chunk $compteur/$($chunks.Count)" "INFO"
    }
    
    # Vectoriser le texte
    $vector = Vectoriser-Texte -Texte $chunk.texte
    
    # Préparer le document pour QDrant
    $document = @{
        id = $chunk.id
        vector = $vector
        payload = @{
            texte = $chunk.texte
            source = $chunk.source
            ligne_debut = $chunk.ligne_debut
            ligne_fin = $chunk.ligne_fin
            timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
    }
    
    # Ajouter à QDrant
    Ajouter-Document-QDrant -Url $UrlQdrant -Collection $NomCollection -Document $document
    
    Start-Sleep -Milliseconds 100  # Éviter de surcharger QDrant
}

Write-Log "Vectorisation terminée: $compteur documents ajoutés à la collection '$NomCollection'" "SUCCESS"
Write-Log "Collection accessible via: $UrlQdrant/collections/$NomCollection" "INFO"
