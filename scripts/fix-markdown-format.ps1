# Script de correction automatique du formatage Markdown
# Utilisation: .\scripts\fix-markdown-format.ps1

$filePath = "projet\roadmaps\plans\consolidated\plan-dev-v57-ecosystem-consolidation-go-native.md"

Write-Host "🔧 Correction du formatage Markdown..." -ForegroundColor Yellow

# Lire le contenu du fichier
$content = Get-Content -Path $filePath -Raw

# Corrections automatiques
Write-Host "📝 Application des corrections..." -ForegroundColor Blue

# Ajouter des lignes vides autour des listes
$content = $content -replace '(\n)(- \[)', "$1`n$2"
$content = $content -replace '(\n- \[.*?\n)(\n###)', "$1`n$2"

# Ajouter des lignes vides autour des titres
$content = $content -replace '(\n)(###[^\n]*?)(\n)', "$1`n$2$3`n"

# Corriger les blocs de code sans langage
$content = $content -replace '````\n```', '```bash'
$content = $content -replace '```\n````', '```'

# Sauvegarder le fichier corrigé
Set-Content -Path $filePath -Value $content -NoNewline

Write-Host "✅ Formatage Markdown corrigé!" -ForegroundColor Green
