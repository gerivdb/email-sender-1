# DÃ©finir les variables d'environnement
$env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = 'true'
$env:N8N_WORKFLOW_IMPORT_PATH = './workflows'
$env:N8N_IMPORT_WORKFLOW_AUTO_ENABLE = 'true'
$env:N8N_IMPORT_WORKFLOW_AUTO_UPDATE = 'true'
$env:N8N_PATH = '/'

# Afficher les variables d'environnement
Write-Host "Variables d'environnement dÃ©finies :"
Write-Host "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = $env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE"
Write-Host "N8N_WORKFLOW_IMPORT_PATH = $env:N8N_WORKFLOW_IMPORT_PATH"
Write-Host "N8N_IMPORT_WORKFLOW_AUTO_ENABLE = $env:N8N_IMPORT_WORKFLOW_AUTO_ENABLE"
Write-Host "N8N_IMPORT_WORKFLOW_AUTO_UPDATE = $env:N8N_IMPORT_WORKFLOW_AUTO_UPDATE"
Write-Host "N8N_PATH = $env:N8N_PATH"

# DÃ©marrer n8n
Write-Host "`nDÃ©marrage de n8n..."
Write-Host "Une fois n8n dÃ©marrÃ©, accÃ©dez Ã  http://localhost:5678 dans votre navigateur"
Write-Host "Appuyez sur Ctrl+C pour arrÃªter n8n`n"

npx n8n start
