# Script pour importer les workflows n8n via l'API

# Fonction pour importer un workflow
function Import-Workflow {
    param (
        [string]$filePath
    )
    
    Write-Host "Importation du workflow: $filePath"
    
    # Lire le contenu du fichier JSON
    $workflowData = Get-Content -Path $filePath -Raw
    
    # Envoyer la requÃªte Ã  l'API n8n
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:5678/rest/workflows" -Method Post -Body $workflowData -Headers $headers
        Write-Host "Workflow importÃ© avec succÃ¨s: $($response.name)" -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de l'importation du workflow: $_" -ForegroundColor Red
    }
}

# Importer tous les workflows du rÃ©pertoire
$workflowFiles = Get-ChildItem -Path "workflows" -Filter "*.json"

foreach ($file in $workflowFiles) {
    Import-Workflow -filePath $file.FullName
}

Write-Host "`nTous les workflows ont Ã©tÃ© importÃ©s. Vous pouvez maintenant les visualiser dans l'interface n8n."
