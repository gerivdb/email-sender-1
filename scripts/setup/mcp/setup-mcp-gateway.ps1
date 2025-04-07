# Script de configuration pour MCP Gateway (centralmind/gateway)

# Definir les variables d'environnement necessaires
$env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "true"

# Creer le repertoire pour Gateway si necessaire
$gatewayDir = ".\gateway"
if (-not (Test-Path $gatewayDir)) {
    New-Item -ItemType Directory -Path $gatewayDir | Out-Null
    Write-Host "Repertoire Gateway cree."
}

# Telecharger le binaire Gateway depuis GitHub
$gatewayVersion = "v0.2.10"
$gatewayUrl = "https://github.com/centralmind/gateway/releases/download/$gatewayVersion/gateway_$($gatewayVersion.Substring(1))_windows_amd64.zip"
$gatewayZip = "$gatewayDir\gateway.zip"

Write-Host "Telechargement du binaire Gateway depuis GitHub..."
try {
    Invoke-WebRequest -Uri $gatewayUrl -OutFile $gatewayZip -ErrorAction Stop
    Write-Host "Telechargement reussi."
} catch {
    Write-Host "Erreur lors du telechargement du binaire Gateway : $_"
    Write-Host "Veuillez telecharger manuellement le binaire depuis https://github.com/centralmind/gateway/releases"
    Write-Host "et le placer dans le repertoire $gatewayDir"
}

# Extraire le binaire si le telechargement a reussi
if (Test-Path $gatewayZip) {
    Write-Host "Extraction du binaire Gateway..."
    try {
        Expand-Archive -Path $gatewayZip -DestinationPath $gatewayDir -Force
        Write-Host "Extraction reussie."
    } catch {
        Write-Host "Erreur lors de l'extraction du binaire Gateway : $_"
    }
}

# Creer un fichier de configuration Gateway minimal
$gatewayConfigPath = "$gatewayDir\gateway.yaml"
$gatewayConfig = @"
api:
  name: Gateway API
  description: API generee par Gateway
  version: '1.0'
database:
  type: postgres
  connection: "postgres://user:password@localhost:5432/database?sslmode=disable"
  tables: []
"@

if (-not (Test-Path $gatewayConfigPath)) {
    Write-Host "Creation du fichier de configuration Gateway..."
    Set-Content -Path $gatewayConfigPath -Value $gatewayConfig
    Write-Host "Fichier de configuration Gateway cree. Veuillez le modifier avec vos informations de connexion a la base de donnees."
}

# Definir la variable d'environnement pour n8n de facon permanente
Write-Host "Configuration des variables d'environnement pour n8n..."
[System.Environment]::SetEnvironmentVariable("N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE", "true", "User")

# Mettre a jour le fichier .env pour n8n
$envPath = ".env"
if (Test-Path $envPath) {
    $envContent = Get-Content $envPath
    if (-not ($envContent -match "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE")) {
        Add-Content -Path $envPath -Value "`nN8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true"
        Write-Host "Variable N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE ajoutee au fichier .env"
    } else {
        Write-Host "Variable N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE deja presente dans le fichier .env"
    }
} else {
    $envContent = @"
N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
"@
    Set-Content -Path $envPath -Value $envContent
    Write-Host "Fichier .env cree avec les variables necessaires"
}

# Verifier si le binaire Gateway existe
$gatewayExe = "$gatewayDir\gateway.exe"
if (Test-Path $gatewayExe) {
    Write-Host "Configuration MCP Gateway terminee. Vous pouvez maintenant utiliser le MCP Gateway dans n8n."
    Write-Host "N'oubliez pas de configurer les identifiants MCP dans n8n avec les informations suivantes :"
    Write-Host "- Type de connexion : Command Line (STDIO)"
    Write-Host "- Commande : $((Resolve-Path $gatewayExe).Path)"
    Write-Host "- Arguments : start --config $((Resolve-Path $gatewayConfigPath).Path) mcp-stdio"
    Write-Host "- Variables d'environnement : N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true"
} else {
    Write-Host "Le binaire Gateway n'a pas ete trouve. Veuillez telecharger manuellement le binaire depuis https://github.com/centralmind/gateway/releases"
    Write-Host "et le placer dans le repertoire $gatewayDir"
}

Write-Host ""
Write-Host "Redemarrez n8n pour appliquer les changements."

