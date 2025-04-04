# Définir les variables d'environnement essentielles
$env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = 'true'

# Afficher les variables d'environnement
Write-Host "Variables d'environnement définies :"
Write-Host "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = $env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE"

# Démarrer n8n
Write-Host "`nDémarrage de n8n..."
Write-Host "Une fois n8n démarré, accédez à http://localhost:5678/workflow dans votre navigateur"
Write-Host "Appuyez sur Ctrl+C pour arrêter n8n`n"

npx n8n start
