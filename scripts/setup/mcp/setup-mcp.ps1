# Script de configuration pour MCP (Model Context Protocol)

# Definir les variables d'environnement necessaires
$env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "true"

# Utiliser la cle OpenRouter existante (ID: GWgrj7r9bN07NdOc)
# Vous devrez entrer votre cle OpenRouter ici
$env:OPENROUTER_API_KEY = "sk-or-v1-..." # Remplacez par votre cle API OpenRouter

# Verifier si n8n-nodes-mcp est installe
$mcpInstalled = npm list n8n-nodes-mcp
if ($mcpInstalled -match "n8n-nodes-mcp@") {
    Write-Host "n8n-nodes-mcp est deja installe."
} else {
    Write-Host "Installation de n8n-nodes-mcp..."
    npm install n8n-nodes-mcp
}

# Verifier les dependances MCP
Write-Host "Installation des dependances MCP..."
npm install -g @modelcontextprotocol/server-openai
npm install -g @modelcontextprotocol/client

# Definir la variable d'environnement pour n8n
Write-Host "Configuration des variables d'environnement pour n8n..."
[System.Environment]::SetEnvironmentVariable("N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE", "true", "User")

Write-Host "Configuration MCP terminee. Vous pouvez maintenant utiliser le MCP dans n8n."
Write-Host "N'oubliez pas de configurer les identifiants MCP dans n8n avec les informations suivantes :"
Write-Host "- Type de connexion : Command Line (STDIO)"
Write-Host "- Commande : npx"
Write-Host "- Arguments : -y @modelcontextprotocol/server-openai"
Write-Host "- Variables d'environnement : OPENROUTER_API_KEY=sk-or-v1-..."

