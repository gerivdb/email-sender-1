# Script de configuration pour BifrostMCP dans n8n

Write-Host "=== Configuration de BifrostMCP pour n8n ===" -ForegroundColor Cyan

# Verifier si le fichier bifrost.config.json existe
$bifrostConfigPath = ".\bifrost.config.json"
if (-not (Test-Path $bifrostConfigPath)) {
    Write-Host "❌ Le fichier bifrost.config.json n'existe pas" -ForegroundColor Red
    Write-Host "Creez d'abord le fichier bifrost.config.json a la racine du projet" -ForegroundColor Yellow
    exit 1
}

# Verifier si le fichier batch existe
$mcpBifrostPath = "..\..\D"
if (-not (Test-Path $mcpBifrostPath)) {
    Write-Host "❌ Le fichier $mcpBifrostPath n'existe pas" -ForegroundColor Red
    Write-Host "Creez d'abord le fichier mcp-bifrost.cmd dans le dossier src\mcp\batch" -ForegroundColor Yellow
    exit 1
}

# Verifier si le dossier .n8n existe
$n8nDir = ".\.n8n"
if (-not (Test-Path $n8nDir)) {
    New-Item -ItemType Directory -Path $n8nDir | Out-Null
    Write-Host "✅ Repertoire .n8n cree" -ForegroundColor Green
} else {
    Write-Host "✅ Repertoire .n8n existe deja" -ForegroundColor Green
}

# Creer le repertoire .n8n/credentials s'il n'existe pas
$credentialsDir = "$n8nDir\credentials"
if (-not (Test-Path $credentialsDir)) {
    New-Item -ItemType Directory -Path $credentialsDir | Out-Null
    Write-Host "✅ Repertoire .n8n/credentials cree" -ForegroundColor Green
} else {
    Write-Host "✅ Repertoire .n8n/credentials existe deja" -ForegroundColor Green
}

# Generer un identifiant unique
$mcpBifrostId = [guid]::NewGuid().ToString("N")

# Creer le fichier d'identifiants
$mcpBifrostCredPath = "$credentialsDir\$mcpBifrostId.json"
$mcpBifrostCredContent = @"
{
  "name": "MCP Bifrost",
  "type": "mcpClientApi",
  "data": {
    "command": "$(Resolve-Path $mcpBifrostPath)",
    "args": "",
    "environments": "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true"
  }
}
"@

Set-Content -Path $mcpBifrostCredPath -Value $mcpBifrostCredContent
Write-Host "✅ Fichier d'identifiants pour BifrostMCP cree" -ForegroundColor Green

# Mettre a jour le fichier credentials.db s'il existe
$credentialsDbPath = "$n8nDir\credentials.db"
if (Test-Path $credentialsDbPath) {
    $credentialsDb = Get-Content -Path $credentialsDbPath -Raw
    
    # Verifier si le fichier est au format JSON valide
    try {
        $credentialsDbJson = $credentialsDb | ConvertFrom-Json
        
        # Ajouter le nouvel identifiant
        $credentialsDbJson | Add-Member -MemberType NoteProperty -Name $mcpBifrostId -Value @{
            "name" = "MCP Bifrost"
            "type" = "mcpClientApi"
            "nodesAccess" = @(
                @{
                    "nodeType" = "n8n-nodes-base.mcpClient"
                }
            )
        }
        
        # Convertir en JSON et enregistrer
        $credentialsDbJson | ConvertTo-Json -Depth 10 -Compress | Set-Content -Path $credentialsDbPath
        Write-Host "✅ Fichier credentials.db mis a jour" -ForegroundColor Green
    } catch {
        Write-Host "❌ Erreur lors de la mise a jour du fichier credentials.db" -ForegroundColor Red
        Write-Host "Le fichier n'est pas au format JSON valide" -ForegroundColor Yellow
        Write-Host "Vous devrez ajouter manuellement l'identifiant dans n8n" -ForegroundColor Yellow
    }
} else {
    # Creer le fichier credentials.db
    $credentialsDbContent = @"
{"$mcpBifrostId":{"name":"MCP Bifrost","type":"mcpClientApi","nodesAccess":[{"nodeType":"n8n-nodes-base.mcpClient"}]}}
"@
    Set-Content -Path $credentialsDbPath -Value $credentialsDbContent
    Write-Host "✅ Fichier credentials.db cree" -ForegroundColor Green
}

Write-Host "`n=== Configuration terminee ===" -ForegroundColor Cyan
Write-Host "BifrostMCP a ete configure pour n8n."
Write-Host "Pour l'utiliser :"
Write-Host "1. Installez l'extension BifrostMCP dans VSCode"
Write-Host "2. Demarrez le serveur BifrostMCP dans VSCode avec la commande 'Bifrost MCP: Start Server'"
Write-Host "3. Utilisez le MCP dans n8n avec le noeud MCP Client et l'identifiant 'MCP Bifrost'"
Write-Host "4. Vous pouvez egalement utiliser le script src\mcp\use-mcp.ps1 bifrost pour demarrer BifrostMCP"

