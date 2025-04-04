# Script pour organiser le repo selon les bonnes pratiques
# Cree une structure de dossiers logique et deplace les fichiers dans les bons repertoires

Write-Host "=== Reorganisation du repo selon les bonnes pratiques ===" -ForegroundColor Cyan

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

# Regles de deplacement des fichiers
$fileRules = @(
    # Format: [pattern, destination, description]
    @("*.json", "src/workflows", "Workflows n8n"),
    @("*.workflow.json", "src/workflows", "Workflows n8n"),
    @("mcp-*.cmd", "src/mcp/batch", "Fichiers batch MCP"),
    @("gateway.exe.cmd", "src/mcp/batch", "Fichier batch Gateway"),
    @("*.yaml", "src/mcp/config", "Fichiers config YAML"),
    @("mcp-config*.json", "src/mcp/config", "Fichiers config MCP"),
    @("*.ps1", "scripts", "Scripts PowerShell"),
    @("configure-*.ps1", "scripts/setup", "Scripts de configuration"),
    @("setup-*.ps1", "scripts/setup", "Scripts d'installation"),
    @("update-*.ps1", "scripts/maintenance", "Scripts de mise a jour"),
    @("cleanup-*.ps1", "scripts/maintenance", "Scripts de nettoyage"),
    @("check-*.ps1", "scripts/maintenance", "Scripts de verification"),
    @("organize-*.ps1", "scripts/maintenance", "Scripts d'organisation"),
    @("*.md", "docs", "Documentation Markdown"),
    @("GUIDE_*.md", "docs/guides", "Guides d'utilisation"),
    @("README.md", ".", "Fichier README principal"),
    @("*.log", "logs", "Fichiers de logs"),
    @("*.env", "config", "Fichiers d'environnement"),
    @("*.config", "config", "Fichiers de configuration"),
    @("start-*.cmd", "tools", "Scripts de demarrage"),
    @("*.py", "src", "Scripts Python")
)

# Fonction pour deplacer un fichier avec confirmation si necessaire
function Move-FileWithConfirmation {
    param (
        [string]$SourcePath,
        [string]$DestinationFolder,
        [string]$Description,
        [switch]$Force
    )
    
    $fileName = Split-Path $SourcePath -Leaf
    $destinationPath = Join-Path $DestinationFolder $fileName
    
    # Verifier si le fichier existe deja a destination
    if (Test-Path $destinationPath) {
        if ($Force) {
            Move-Item -Path $SourcePath -Destination $destinationPath -Force
            Write-Host "  ✅ $fileName deplace vers $DestinationFolder (remplace)" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️ $fileName existe deja dans $DestinationFolder" -ForegroundColor Yellow
            Write-Host "  Voulez-vous le remplacer ? (O/N)" -ForegroundColor Yellow
            $confirmation = Read-Host
            
            if ($confirmation -eq "O" -or $confirmation -eq "o") {
                Move-Item -Path $SourcePath -Destination $destinationPath -Force
                Write-Host "  ✅ $fileName deplace vers $DestinationFolder (remplace)" -ForegroundColor Green
            } else {
                Write-Host "  ❌ $fileName conserve a son emplacement actuel" -ForegroundColor Red
            }
        }
    } else {
        Move-Item -Path $SourcePath -Destination $destinationPath
        Write-Host "  ✅ $fileName deplace vers $DestinationFolder" -ForegroundColor Green
    }
}

# Deplacer les fichiers selon les regles
Write-Host "`nDeplacement des fichiers selon les regles definies..." -ForegroundColor Yellow

foreach ($rule in $fileRules) {
    $pattern = $rule[0]
    $destination = $rule[1]
    $description = $rule[2]
    
    Write-Host "`nTraitement des fichiers $description ($pattern)..." -ForegroundColor Cyan
    
    # Trouver les fichiers correspondant au pattern a la racine
    $files = Get-ChildItem -Path "." -Filter $pattern -File | Where-Object { $_.DirectoryName -eq (Get-Location).Path }
    
    if ($files.Count -eq 0) {
        Write-Host "  Aucun fichier $pattern trouve a la racine" -ForegroundColor Yellow
    } else {
        Write-Host "  $($files.Count) fichier(s) trouve(s)" -ForegroundColor Yellow
        
        foreach ($file in $files) {
            # Ne pas deplacer le README.md principal s'il est a la racine et que la destination n'est pas la racine
            if ($file.Name -eq "README.md" -and $destination -ne ".") {
                Write-Host "  ℹ️ README.md conserve a la racine" -ForegroundColor Blue
                continue
            }
            
            Move-FileWithConfirmation -SourcePath $file.FullName -DestinationFolder $destination -Description $description
        }
    }
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
    Write-Host "`n✅ Fichier .gitignore cree" -ForegroundColor Green
} else {
    Write-Host "`n✅ Fichier .gitignore existe deja" -ForegroundColor Green
}

# Creer un README.md principal s'il n'existe pas ou le mettre a jour
$readmePath = ".\README.md"
$readmeContent = @"
# Projet Email Sender pour n8n

Ce projet contient des workflows n8n et des outils pour automatiser l'envoi d'emails et la gestion des processus de booking pour le groupe Gribitch.

## Structure du projet

\`\`\`
├── src/                  # Code source principal
│   ├── workflows/        # Workflows n8n
│   └── mcp/              # Fichiers MCP (Model Context Protocol)
│       ├── batch/        # Fichiers batch pour MCP
│       └── config/       # Configurations MCP
├── scripts/              # Scripts utilitaires
│   ├── setup/            # Scripts d'installation
│   └── maintenance/      # Scripts de maintenance
├── config/               # Fichiers de configuration
├── logs/                 # Fichiers de logs
├── docs/                 # Documentation
│   ├── guides/           # Guides d'utilisation
│   └── api/              # Documentation API
├── tests/                # Tests
├── tools/                # Outils divers
└── assets/               # Ressources statiques
\`\`\`

## Installation

1. Clonez ce depot
2. Executez le script d'installation:
   \`\`\`
   .\scripts\setup\setup-environment.ps1
   \`\`\`
3. Configurez les MCP:
   \`\`\`
   .\scripts\setup\configure-n8n-mcp.ps1
   \`\`\`

## Utilisation

Pour demarrer n8n avec tous les MCP configures:
\`\`\`
.\tools\start-n8n-mcp.cmd
\`\`\`

## MCP disponibles

- **MCP Standard**: Pour interagir avec OpenRouter et les modeles d'IA
- **MCP Notion**: Pour interagir avec vos bases de donnees Notion
- **MCP Gateway**: Pour interagir avec vos bases de donnees SQL
- **MCP Git Ingest**: Pour explorer et lire les depots GitHub

## Documentation

Consultez le dossier \`docs/\` pour la documentation complete du projet.

## Maintenance

Des scripts de maintenance sont disponibles dans le dossier \`scripts/maintenance/\`:
- Mise a jour des MCP: \`update-mcp.ps1\`
- Nettoyage des fichiers: \`cleanup-mcp-files.ps1\`
- Organisation du repo: \`organize-repo.ps1\`
"@

if (-not (Test-Path $readmePath)) {
    Set-Content -Path $readmePath -Value $readmeContent
    Write-Host "✅ Fichier README.md cree" -ForegroundColor Green
} else {
    Write-Host "⚠️ Un fichier README.md existe deja" -ForegroundColor Yellow
    Write-Host "Voulez-vous le remplacer par un README standardise ? (O/N)" -ForegroundColor Yellow
    $confirmation = Read-Host
    
    if ($confirmation -eq "O" -or $confirmation -eq "o") {
        Set-Content -Path $readmePath -Value $readmeContent
        Write-Host "✅ Fichier README.md mis a jour" -ForegroundColor Green
    } else {
        Write-Host "❌ README.md conserve tel quel" -ForegroundColor Red
    }
}

# Creer un script pour generer automatiquement les nouveaux fichiers dans les bons dossiers
$newFilePath = ".\scripts\maintenance\new-file.ps1"
$newFileContent = @"
# Script pour creer de nouveaux fichiers dans les bons dossiers
# Usage: .\scripts\maintenance\new-file.ps1 -Type <type> -Name <nom>

param (
    [Parameter(Mandatory=`$true)]
    [ValidateSet("workflow", "script", "doc", "config", "mcp", "test")]
    [string]`$Type,
    
    [Parameter(Mandatory=`$true)]
    [string]`$Name
)

function Create-File {
    param (
        [string]`$Path,
        [string]`$Content
    )
    
    if (Test-Path `$Path) {
        Write-Host "⚠️ Le fichier `$Path existe deja" -ForegroundColor Yellow
        Write-Host "Voulez-vous le remplacer ? (O/N)" -ForegroundColor Yellow
        `$confirmation = Read-Host
        
        if (`$confirmation -eq "O" -or `$confirmation -eq "o") {
            Set-Content -Path `$Path -Value `$Content
            Write-Host "✅ Fichier `$Path cree (remplace)" -ForegroundColor Green
        } else {
            Write-Host "❌ Operation annulee" -ForegroundColor Red
        }
    } else {
        # Creer le dossier parent s'il n'existe pas
        `$folder = Split-Path `$Path -Parent
        if (-not (Test-Path `$folder)) {
            New-Item -ItemType Directory -Path `$folder | Out-Null
            Write-Host "✅ Dossier `$folder cree" -ForegroundColor Green
        }
        
        Set-Content -Path `$Path -Value `$Content
        Write-Host "✅ Fichier `$Path cree" -ForegroundColor Green
    }
}

switch (`$Type) {
    "workflow" {
        `$path = ".\src\workflows\`$Name.json"
        `$content = @"
{
  "name": "`$Name",
  "nodes": [
    {
      "parameters": {},
      "name": "Start",
      "type": "n8n-nodes-base.start",
      "typeVersion": 1,
      "position": [
        240,
        300
      ]
    }
  ],
  "connections": {}
}
"@
        Create-File -Path `$path -Content `$content
    }
    "script" {
        `$path = ".\scripts\`$Name.ps1"
        `$content = @"
# Script `$Name
# Description: [Ajoutez une description ici]

Write-Host "=== `$Name ===" -ForegroundColor Cyan

# Votre code ici

Write-Host "`n=== Termine ===" -ForegroundColor Cyan
"@
        Create-File -Path `$path -Content `$content
    }
    "doc" {
        `$path = ".\docs\`$Name.md"
        `$content = @"
# `$Name

## Introduction

[Ajoutez une introduction ici]

## Contenu

[Ajoutez le contenu ici]

## Utilisation

[Ajoutez des instructions d'utilisation ici]
"@
        Create-File -Path `$path -Content `$content
    }
    "config" {
        `$path = ".\config\`$Name.json"
        `$content = @"
{
  "name": "`$Name",
  "version": "1.0.0",
  "description": "[Ajoutez une description ici]",
  "config": {
    // Ajoutez votre configuration ici
  }
}
"@
        Create-File -Path `$path -Content `$content
    }
    "mcp" {
        `$path = ".\src\mcp\batch\mcp-`$Name.cmd"
        `$content = @"
@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
REM Ajoutez vos commandes ici
"@
        Create-File -Path `$path -Content `$content
    }
    "test" {
        `$path = ".\tests\`$Name.ps1"
        `$content = @"
# Test `$Name
# Description: [Ajoutez une description ici]

Write-Host "=== Test `$Name ===" -ForegroundColor Cyan

# Votre code de test ici

Write-Host "`n=== Test termine ===" -ForegroundColor Cyan
"@
        Create-File -Path `$path -Content `$content
    }
}
"@

if (-not (Test-Path $newFilePath)) {
    # Creer le dossier parent s'il n'existe pas
    $newFileFolder = Split-Path $newFilePath -Parent
    if (-not (Test-Path $newFileFolder)) {
        New-Item -ItemType Directory -Path $newFileFolder | Out-Null
    }
    
    Set-Content -Path $newFilePath -Value $newFileContent
    Write-Host "✅ Script new-file.ps1 cree" -ForegroundColor Green
} else {
    Write-Host "✅ Script new-file.ps1 existe deja" -ForegroundColor Green
}

Write-Host "`n=== Reorganisation terminee ===" -ForegroundColor Cyan
Write-Host "Le repo a ete reorganise selon les bonnes pratiques."
Write-Host "Pour creer de nouveaux fichiers dans les bons dossiers, utilisez:"
Write-Host "  .\scripts\maintenance\new-file.ps1 -Type <type> -Name <nom>"
Write-Host "Types disponibles: workflow, script, doc, config, mcp, test"

