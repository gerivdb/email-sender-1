# Script pour importer les workflows n8n via l'API avec un jeton d'authentification

# Remplacez cette valeur par votre jeton d'authentification
$apiToken = "VOTRE_JETON_ICI"

# Fonction pour importer un workflow
function Import-Workflow {
    param (
        [string]$filePath,
        [string]$token
    )
    
    Write-Host "Importation du workflow: $filePath"
    
    # Lire le contenu du fichier JSON
    $workflowData = Get-Content -Path $filePath -Raw
    
    # Envoyer la requÃªte Ã  l'API n8n
    $headers = @{
        "Content-Type" = "application/json"
        "X-N8N-API-KEY" = $token
    }
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows" -Method Post -Body $workflowData -Headers $headers
        Write-Host "Workflow importÃ© avec succÃ¨s: $($response.name)" -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de l'importation du workflow: $_" -ForegroundColor Red
    }
}

# VÃ©rifier si le jeton a Ã©tÃ© dÃ©fini
if ($apiToken -eq "VOTRE_JETON_ICI") {
    Write-Host "Veuillez remplacer 'VOTRE_JETON_ICI' par votre jeton d'authentification n8n dans le script." -ForegroundColor Red
    exit
}

# Importer tous les workflows du rÃ©pertoire
$workflowFiles = Get-ChildItem -Path "workflows" -Filter "*.json"

foreach ($file in $workflowFiles) {
    Import-Workflow -filePath $file.FullName -token $apiToken
}

Write-Host "`nTous les workflows ont Ã©tÃ© importÃ©s. Vous pouvez maintenant les visualiser dans l'interface n8n."
