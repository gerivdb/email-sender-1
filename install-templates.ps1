# 🚀 Script d'Installation Automatique des Templates Plan-Dev
# Auteur: gerivdb
# Date: 2025-05-28

Write-Host "🚀 Installation des Templates Plan-Dev Hygen..."

# Créer la structure des dossiers
Write-Host "📁 Création de la structure des dossiers..."
$templateDirs = @(
    "_templates/plan-dev/new",
    "_templates/plan-dev/update",
    "_templates/plan-dev/report",
    "_templates/plan-dev/config",
    "_templates/plan-dev/usage"
)

foreach ($dir in $templateDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force
        Write-Host "✅ Créé: $dir"
    }
    else {
        Write-Host "ℹ️ Existe déjà: $dir"
    }
}

Write-Host "`n✨ Installation terminée avec succès!"