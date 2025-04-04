# Définir les variables d'environnement essentielles
$env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = 'true'
$env:N8N_DIAGNOSTICS_ENABLED = 'false'
$env:N8N_USER_FOLDER = './.n8n'
$env:N8N_EDITOR_BASE_URL = '/'

# Afficher les variables d'environnement
Write-Host "Variables d'environnement définies :"
Write-Host "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = $env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE"
Write-Host "N8N_DIAGNOSTICS_ENABLED = $env:N8N_DIAGNOSTICS_ENABLED"
Write-Host "N8N_USER_FOLDER = $env:N8N_USER_FOLDER"
Write-Host "N8N_EDITOR_BASE_URL = $env:N8N_EDITOR_BASE_URL"

# Démarrer n8n
Write-Host "`nDémarrage de n8n..."
Write-Host "Une fois n8n démarré, accédez à http://localhost:5678/ dans votre navigateur"
Write-Host "Appuyez sur Ctrl+C pour arrêter n8n`n"

npx n8n start
