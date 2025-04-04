# Script pour importer les workflows corrigés dans n8n

# Configuration
$n8nUrl = "http://localhost:5678"
$apiToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmNzI5MDhiZC0wYmViLTQ3YzQtOTgzMy0zOGM1ZmRmNjZlZGQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzQzNzkzMzA0fQ.EfYMSbUmk6OLDw70wXNYPl0B-ont0B1WbAnowIQdJbw" # Jeton API AUGMENT
$workflowsDir = "workflows-fixed"

# Fonction pour importer un workflow
function Import-Workflow {
    param (
        [string]$filePath,
        [string]$token
    )
    
    $fileName = Split-Path $filePath -Leaf
    Write-Host "Importation du workflow: $fileName" -NoNewline
    
    try {
        # Lire le contenu du fichier
        $content = Get-Content -Path $filePath -Raw -Encoding UTF8
        
        # Convertir le contenu JSON en objet PowerShell
        $workflowJson = $content | ConvertFrom-Json
        
        # Préparer les données pour l'API
        $apiData = @{
            name = $workflowJson.name
            nodes = $workflowJson.nodes
            connections = $workflowJson.connections
            settings = @{
                executionOrder = "v1"
            }
        } | ConvertTo-Json -Depth 20
        
        # Envoyer la requête à l'API n8n
        $headers = @{
            "Content-Type" = "application/json"
            "X-N8N-API-KEY" = $token
        }
        
        $response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Post -Body $apiData -Headers $headers
        Write-Host " - Succès!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host " - Échec!" -ForegroundColor Red
        Write-Host "  Erreur: $($_.Exception.Message)" -ForegroundColor Red
        
        # Afficher plus de détails sur l'erreur
        if ($_.ErrorDetails.Message) {
            try {
                $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
                Write-Host "  Détails: $($errorJson.message)" -ForegroundColor Red
            }
            catch {
                Write-Host "  Détails: $($_.ErrorDetails.Message)" -ForegroundColor Red
            }
        }
        return $false
    }
}

# Vérifier la connexion à n8n
Write-Host "Vérification de la connexion à n8n ($n8nUrl)..." -NoNewline
try {
    $headers = @{
        "X-N8N-API-KEY" = $apiToken
    }
    $response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers $headers
    Write-Host " Connecté!" -ForegroundColor Green
}
catch {
    Write-Host " Échec de connexion!" -ForegroundColor Red
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# Importer tous les workflows du répertoire
Write-Host "`nRecherche des workflows dans le répertoire '$workflowsDir'..."
$workflowFiles = Get-ChildItem -Path $workflowsDir -Filter "*.json"

if ($workflowFiles.Count -eq 0) {
    Write-Host "Aucun fichier workflow trouvé dans le répertoire '$workflowsDir'." -ForegroundColor Yellow
    exit
}

Write-Host "Trouvé $($workflowFiles.Count) fichiers workflow.`n"

$successCount = 0
foreach ($file in $workflowFiles) {
    $result = Import-Workflow -filePath $file.FullName -token $apiToken
    if ($result) {
        $successCount++
    }
}

Write-Host "`nImportation terminée: $successCount/$($workflowFiles.Count) workflows importés avec succès."
Write-Host "Vous pouvez maintenant visualiser les workflows à l'adresse: $n8nUrl/home/workflows"
