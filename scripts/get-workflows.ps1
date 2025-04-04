# Script pour lister les workflows existants dans n8n

# Configuration
$n8nUrl = "http://localhost:5678"
$apiToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmNzI5MDhiZC0wYmViLTQ3YzQtOTgzMy0zOGM1ZmRmNjZlZGQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzQzNzkzMzA0fQ.EfYMSbUmk6OLDw70wXNYPl0B-ont0B1WbAnowIQdJbw" # Jeton API AUGMENT

# Vérifier la connexion à n8n
Write-Host "Verification de la connexion a n8n ($n8nUrl)..." -NoNewline
try {
    $headers = @{
        "X-N8N-API-KEY" = $apiToken
    }
    $response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers $headers
    Write-Host " Connecte!" -ForegroundColor Green
    
    # Afficher la réponse brute pour le débogage
    Write-Host "`nReponse brute de l'API:"
    $response | ConvertTo-Json -Depth 1
    
    # Afficher le type de la réponse
    Write-Host "`nType de la reponse: $($response.GetType().FullName)"
    
    # Essayer d'accéder aux propriétés de la réponse
    if ($response -is [array]) {
        Write-Host "`nLa reponse est un tableau avec $($response.Count) elements."
        
        if ($response.Count -gt 0) {
            Write-Host "`nPremier element:"
            $response[0] | ConvertTo-Json
        }
    }
    elseif ($response -is [System.Management.Automation.PSCustomObject]) {
        Write-Host "`nLa reponse est un objet PSCustomObject."
        Write-Host "Proprietes disponibles:"
        $response.PSObject.Properties | ForEach-Object { Write-Host "- $($_.Name)" }
    }
    else {
        Write-Host "`nLa reponse est de type inconnu."
    }
}
catch {
    Write-Host " Echec de connexion!" -ForegroundColor Red
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
    exit
}
