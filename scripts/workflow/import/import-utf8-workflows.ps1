# Script pour importer les workflows corrigÃ©s dans n8n

# Configuration
$n8nUrl = "http://localhost:5678"
$apiToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmNzI5MDhiZC0wYmViLTQ3YzQtOTgzMy0zOGM1ZmRmNjZlZGQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzQzNzkzMzA0fQ.EfYMSbUmk6OLDw70wXNYPl0B-ont0B1WbAnowIQdJbw" # Jeton API AUGMENT
$workflowsDir = "workflows-utf8"

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
        
        # PrÃ©parer les donnÃ©es pour l'API
        $apiData = @{
            name = $workflowJson.name
            nodes = $workflowJson.nodes
            connections = $workflowJson.connections
            settings = @{
                executionOrder = "v1"
            }
        } | ConvertTo-Json -Depth 20
        
        # Envoyer la requÃªte Ã  l'API n8n
        $headers = @{
            "Content-Type" = "application/json"
            "X-N8N-API-KEY" = $token
        }
        
        $response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Post -Body $apiData -Headers $headers
        Write-Host " - SuccÃ¨s!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host " - Ã‰chec!" -ForegroundColor Red
        Write-Host "  Erreur: $($_.Exception.Message)" -ForegroundColor Red
        
        # Afficher plus de dÃ©tails sur l'erreur
        if ($_.ErrorDetails.Message) {
            try {
                $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
                Write-Host "  DÃ©tails: $($errorJson.message)" -ForegroundColor Red
            }
            catch {
                Write-Host "  DÃ©tails: $($_.ErrorDetails.Message)" -ForegroundColor Red
            }
        }
        return $false
    }
}

# VÃ©rifier la connexion Ã  n8n
Write-Host "VÃ©rification de la connexion Ã  n8n ($n8nUrl)..." -NoNewline
try {
    $headers = @{
        "X-N8N-API-KEY" = $apiToken
    }
    $response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers $headers
    Write-Host " ConnectÃ©!" -ForegroundColor Green
}
catch {
    Write-Host " Ã‰chec de connexion!" -ForegroundColor Red
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# Importer tous les workflows du rÃ©pertoire
Write-Host "`nRecherche des workflows dans le rÃ©pertoire '$workflowsDir'..."
$workflowFiles = Get-ChildItem -Path $workflowsDir -Filter "*.json"

if ($workflowFiles.Count -eq 0) {
    Write-Host "Aucun fichier workflow trouvÃ© dans le rÃ©pertoire '$workflowsDir'." -ForegroundColor Yellow
    exit
}

Write-Host "TrouvÃ© $($workflowFiles.Count) fichiers workflow.`n"

$successCount = 0
foreach ($file in $workflowFiles) {
    $result = Import-Workflow -filePath $file.FullName -token $apiToken
    if ($result) {
        $successCount++
    }
}

Write-Host "`nImportation terminÃ©e: $successCount/$($workflowFiles.Count) workflows importÃ©s avec succÃ¨s."
Write-Host "Vous pouvez maintenant visualiser les workflows Ã  l'adresse: $n8nUrl/home/workflows"
