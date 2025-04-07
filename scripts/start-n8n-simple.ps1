# DÃ©finir les variables d'environnement essentielles
$env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = 'true'

# Afficher les variables d'environnement
Write-Host "Variables d'environnement dÃ©finies :"
Write-Host "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = $env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE"

# DÃ©marrer n8n
Write-Host "`nDÃ©marrage de n8n..."
Write-Host "Une fois n8n dÃ©marrÃ©, accÃ©dez Ã  http://localhost:5678/workflow dans votre navigateur"
Write-Host "Appuyez sur Ctrl+C pour arrÃªter n8n`n"

npx n8n start
