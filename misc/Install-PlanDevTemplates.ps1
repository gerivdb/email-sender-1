# 🚀 Script PowerShell d'Installation des Templates Plan-Dev
# Auteur: gerivdb
# Date: 2025-05-28

Write-Host "🚀 Installation des Templates Plan-Dev Hygen..." -ForegroundColor Cyan

# Création de la structure des dossiers
$folders = @(
    "_templates/plan-dev/new",
    "_templates/plan-dev/update",
    "_templates/plan-dev/report",
    "_templates/plan-dev/config",
    "_templates/plan-dev/usage"
)

Write-Host "📁 Création de la structure des dossiers..." -ForegroundColor Blue
foreach ($folder in $folders) {
    $folder = $folder.Replace('/', '\')
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "  ✓ Créé: $folder" -ForegroundColor Green
    } else {
        Write-Host "  ℹ️ Existe déjà: $folder" -ForegroundColor Yellow
    }
}# Création des fichiers de template
Write-Host "`n📝 Création des templates..." -ForegroundColor Blue

# Variables pour la création des dossiers de tracking
$trackingFolders = @(
    "roadmaps/plans/consolidated",
    "tracking/scripts",
    "tracking/reports"
)

foreach ($folder in $trackingFolders) {
    $folder = $folder.Replace('/', '\')
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "  ✓ Créé: $folder" -ForegroundColor Green
    }
}

# Installation de chalk si non présent
if (-not (Test-Path "node_modules/chalk")) {
    Write-Host "`n📦 Installation des dépendances..." -ForegroundColor Blue
    npm install chalk --save-dev
}

# Création du fichier package.json s'il n'existe pas
if (-not (Test-Path "package.json")) {
    Write-Host "  📄 Création du package.json..." -ForegroundColor Blue
    @{
        name = "plan-dev-templates"
        version = "1.0.0"
        description = "Templates pour le suivi de développement"
        dependencies = @{
            chalk = "^4.1.2"
        }
    } | ConvertTo-Json | Out-File -FilePath "package.json" -Encoding UTF8
}# Guide d'utilisation
$readmeContent = @"
# 🚀 Guide Plan-Dev Templates

## 📖 Comment utiliser les templates

### 1️⃣ Création d'un nouveau plan
\`\`\`powershell
hygen plan-dev new
\`\`\`

### 2️⃣ Mise à jour d'un script
\`\`\`powershell
hygen plan-dev update add-script
\`\`\`

### 3️⃣ Génération d'un rapport
\`\`\`powershell
hygen plan-dev report weekly
\`\`\`

## 📝 Structure des fichiers

\`\`\`
_templates/plan-dev/
├── new/
│   ├── index.ejs.t    # Template principal
│   ├── warnings.ejs.t # Gestion des alertes
│   └── prompt.js      # Questions interactives
├── update/
│   ├── add-script.ejs.t
│   └── prompt.js
├── report/
│   ├── weekly.ejs.t
│   └── prompt.js
└── usage/
    └── README.md
\`\`\`

## ⚠️ Points de vigilance

Les warnings peuvent être ajoutés avec la structure suivante :

\`\`\`javascript
{
    warnings: [
        { message: "Message d'alerte", severity: "HAUTE" },
        { message: "Autre alerte", severity: "MOYENNE" }
    ]
}
\`\`\`

## 🆘 Support

En cas de problème :
1. Vérifiez que vous êtes dans le bon dossier
2. Exécutez \`hygen plan-dev new --help\`
3. Consultez la documentation Hygen

*Installation réalisée le $(Get-Date -Format "yyyy-MM-dd")*
"@

$readmeContent | Out-File -FilePath "_templates/plan-dev/usage/README.md" -Encoding UTF8

Write-Host "`n✅ Installation terminée avec succès !" -ForegroundColor Green
Write-Host "`n🎯 Prochaines étapes :" -ForegroundColor Yellow
Write-Host "1. Créez un nouveau plan :        hygen plan-dev new" -ForegroundColor Cyan
Write-Host "2. Ajoutez un script au suivi :   hygen plan-dev update add-script" -ForegroundColor Cyan
Write-Host "3. Générez un rapport :           hygen plan-dev report weekly" -ForegroundColor Cyan
Write-Host "`n📚 Guide complet disponible dans : _templates/plan-dev/usage/README.md" -ForegroundColor Magenta