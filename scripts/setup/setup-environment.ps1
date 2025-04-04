# Script d'installation et de configuration de l'environnement

Write-Host "=== Installation et configuration de l'environnement ===" -ForegroundColor Cyan

# Verifier les prerequis
Write-Host "`n[1] Verification des prerequis..." -ForegroundColor Yellow

# Verifier Node.js
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js $nodeVersion est installe" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js n'est pas installe ou n'est pas accessible" -ForegroundColor Red
    Write-Host "Veuillez installer Node.js depuis https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# Verifier npm
try {
    $npmVersion = npm --version
    Write-Host "✅ npm $npmVersion est installe" -ForegroundColor Green
} catch {
    Write-Host "❌ npm n'est pas installe ou n'est pas accessible" -ForegroundColor Red
    Write-Host "Veuillez reinstaller Node.js depuis https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# Verifier n8n
try {
    $n8nVersion = npx n8n --version
    Write-Host "✅ n8n $n8nVersion est installe" -ForegroundColor Green
} catch {
    Write-Host "⚠️ n8n n'est pas installe ou n'est pas accessible" -ForegroundColor Yellow
    Write-Host "Installation de n8n..." -ForegroundColor Yellow
    npm install n8n
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erreur lors de l'installation de n8n" -ForegroundColor Red
        exit 1
    }
    $n8nVersion = npx n8n --version
    Write-Host "✅ n8n $n8nVersion a ete installe" -ForegroundColor Green
}

# Verifier Python
try {
    $pythonVersion = python --version
    Write-Host "✅ $pythonVersion est installe" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Python n'est pas installe ou n'est pas accessible" -ForegroundColor Yellow
    Write-Host "Certaines fonctionnalites peuvent ne pas fonctionner correctement" -ForegroundColor Yellow
}

# Creer la structure de dossiers
Write-Host "`n[2] Creation de la structure de dossiers..." -ForegroundColor Yellow

# Structure de dossiers a creer
$folders = @(
    "src",                  # Code source principal
    "src/workflows",        # Workflows n8n
    "src/mcp",              # Fichiers MCP
    "src/mcp/batch",        # Fichiers batch pour MCP
    "src/mcp/config",       # Configurations MCP
    "scripts",              # Scripts utilitaires
    "scripts/setup",        # Scripts d'installation
    "scripts/maintenance",  # Scripts de maintenance
    "config",               # Fichiers de configuration
    "logs",                 # Fichiers de logs
    "docs",                 # Documentation
    "docs/guides",          # Guides d'utilisation
    "docs/api",             # Documentation API
    "tests",                # Tests
    "tools",                # Outils divers
    "assets"                # Ressources statiques
)

# Creer les dossiers s'ils n'existent pas
foreach ($folder in $folders) {
    if (-not (Test-Path ".\$folder")) {
        New-Item -ItemType Directory -Path ".\$folder" | Out-Null
        Write-Host "✅ Dossier $folder cree" -ForegroundColor Green
    } else {
        Write-Host "✅ Dossier $folder existe deja" -ForegroundColor Green
    }
}

# Installer les dependances
Write-Host "`n[3] Installation des dependances..." -ForegroundColor Yellow

# Creer package.json s'il n'existe pas
if (-not (Test-Path ".\package.json")) {
    $packageJsonContent = @"
{
  "name": "email-sender-n8n",
  "version": "1.0.0",
  "description": "Workflows n8n pour l'automatisation de l'envoi d'emails et la gestion des processus de booking",
  "main": "index.js",
  "scripts": {
    "start": "n8n start",
    "dev": "n8n start --tunnel",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [
    "n8n",
    "workflow",
    "automation",
    "email",
    "booking"
  ],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "n8n": "^1.0.0"
  }
}
"@
    Set-Content -Path ".\package.json" -Value $packageJsonContent
    Write-Host "✅ Fichier package.json cree" -ForegroundColor Green
} else {
    Write-Host "✅ Fichier package.json existe deja" -ForegroundColor Green
}

# Installer les packages npm
Write-Host "Installation des packages npm..." -ForegroundColor Yellow
npm install n8n-nodes-mcp @suekou/mcp-notion-server
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ Certains packages n'ont pas pu etre installes" -ForegroundColor Yellow
} else {
    Write-Host "✅ Packages npm installes" -ForegroundColor Green
}

# Installer les packages Python si Python est installe
if ($pythonVersion) {
    Write-Host "Installation des packages Python..." -ForegroundColor Yellow
    try {
        pip install uvx==1.0.0
        pip install git+https://github.com/adhikasp/mcp-git-ingest
        Write-Host "✅ Packages Python installes" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Certains packages Python n'ont pas pu etre installes" -ForegroundColor Yellow
    }
}

# Configurer les variables d'environnement
Write-Host "`n[4] Configuration des variables d'environnement..." -ForegroundColor Yellow

# Creer le fichier .env s'il n'existe pas
$envPath = ".\config\.env"
if (-not (Test-Path $envPath)) {
    $envContent = @"
# Variables d'environnement pour le projet Email Sender

# Configuration n8n
N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_HOST=localhost

# Cles API
OPENROUTER_API_KEY=sk-or-v1-...
NOTION_API_TOKEN=secret_...

# Configuration MCP
MCP_ENABLED=true
"@
    Set-Content -Path $envPath -Value $envContent
    Write-Host "✅ Fichier .env cree dans le dossier config" -ForegroundColor Green
} else {
    Write-Host "✅ Fichier .env existe deja dans le dossier config" -ForegroundColor Green
}

# Definir la variable d'environnement pour n8n
[Environment]::SetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'true', 'User')
[Environment]::SetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'true', 'Process')
Write-Host "✅ Variable d'environnement N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE definie" -ForegroundColor Green

# Creer un script de demarrage n8n
$startScriptPath = ".\tools\start-n8n.cmd"
$startScriptContent = @"
@echo off
echo ===================================
echo Demarrage de n8n avec configuration
echo ===================================
echo.

echo [1] Chargement des variables d'environnement...
for /f "tokens=*" %%a in ('type ".\config\.env" ^| findstr /v "^#" ^| findstr /v "^$"') do (
    set "%%a"
)
echo Variables d'environnement chargees.
echo.

echo [2] Verification des dossiers MCP...
if exist src\mcp\batch (
    echo - Dossier MCP : OK
) else (
    echo - Dossier MCP : MANQUANT
    echo Executez le script setup-environment.ps1 pour configurer l'environnement.
)
echo.

echo [3] Demarrage de n8n...
echo Une fois n8n demarre, accedez a http://localhost:5678 dans votre navigateur
echo.
echo Appuyez sur Ctrl+C pour arreter n8n
echo.
npx n8n start
"@

if (-not (Test-Path $startScriptPath)) {
    New-Item -ItemType Directory -Path ".\tools" -Force | Out-Null
    Set-Content -Path $startScriptPath -Value $startScriptContent
    Write-Host "✅ Script de demarrage n8n cree" -ForegroundColor Green
} else {
    Write-Host "✅ Script de demarrage n8n existe deja" -ForegroundColor Green
}

# Creer un .gitignore s'il n'existe pas
$gitignorePath = ".\.gitignore"
if (-not (Test-Path $gitignorePath)) {
    $gitignoreContent = @"
# Logs
logs/
*.log
npm-debug.log*

# Runtime data
.n8n/
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Dependency directories
node_modules/

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Output of 'npm pack'
*.tgz

# dotenv environment variable files
.env
config/.env

# IDE files
.idea/
.vscode/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db
"@
    Set-Content -Path $gitignorePath -Value $gitignoreContent
    Write-Host "✅ Fichier .gitignore cree" -ForegroundColor Green
} else {
    Write-Host "✅ Fichier .gitignore existe deja" -ForegroundColor Green
}

Write-Host "`n=== Installation et configuration terminees ===" -ForegroundColor Cyan
Write-Host "L'environnement a ete configure avec succes."
Write-Host "Pour demarrer n8n, executez: .\tools\start-n8n.cmd"
Write-Host "Pour configurer les MCP, executez: .\scripts\setup\configure-n8n-mcp.ps1"

