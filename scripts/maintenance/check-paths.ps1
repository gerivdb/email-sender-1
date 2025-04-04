# Script pour verifier les chemins dans les fichiers de configuration
# Ce script recherche les anciens chemins dans les fichiers de configuration et les signale

Write-Host "=== Verification des chemins dans les fichiers de configuration ===" -ForegroundColor Cyan

# Ancien chemin (avec espaces et accents)
$oldPath = "D:\\DO\\WEB\\N8N tests\\scripts json à tester\\EMAIL SENDER 1"
$oldPathVariants = @(
    "D:\\DO\\WEB\\N8N tests\\scripts json à tester\\EMAIL SENDER 1",
    "D:/DO/WEB/N8N tests/scripts json à tester/EMAIL SENDER 1",
    "D:\DO\WEB\N8N tests\scripts json à tester\EMAIL SENDER 1"
)

# Nouveau chemin (avec underscores)
$newPath = "D:\\DO\\WEB\\N8N_tests\\scripts_ json_a_ tester\\EMAIL_SENDER_1"

# Types de fichiers à vérifier
$fileTypes = @("*.json", "*.cmd", "*.ps1", "*.yaml", "*.md")

# Fonction pour vérifier un fichier
function Check-File {
    param (
        [string]$filePath
    )

    $content = Get-Content -Path $filePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        return $false
    }

    $foundOldPath = $false
    foreach ($variant in $oldPathVariants) {
        if ($content -match [regex]::Escape($variant)) {
            $foundOldPath = $true
            break
        }
    }

    return $foundOldPath
}

# Rechercher les fichiers contenant les anciens chemins
$filesWithOldPaths = @()

foreach ($fileType in $fileTypes) {
    $files = Get-ChildItem -Path . -Recurse -File -Filter $fileType
    foreach ($file in $files) {
        if (Check-File -filePath $file.FullName) {
            $filesWithOldPaths += $file.FullName
        }
    }
}

# Afficher les résultats
if ($filesWithOldPaths.Count -eq 0) {
    Write-Host "✅ Aucun fichier contenant les anciens chemins n'a été trouvé." -ForegroundColor Green
} else {
    Write-Host "❌ Les fichiers suivants contiennent encore des références aux anciens chemins :" -ForegroundColor Red
    foreach ($file in $filesWithOldPaths) {
        Write-Host "   - $file" -ForegroundColor Yellow
    }

    Write-Host "`nPour corriger ces fichiers, vous pouvez :"
    Write-Host "1. Ouvrir chaque fichier et remplacer manuellement les anciens chemins par le nouveau chemin."
    Write-Host "2. Utiliser le script suivant pour remplacer automatiquement les chemins (à exécuter avec précaution) :"
    Write-Host "   .\scripts\maintenance\fix-paths.ps1"
}

Write-Host "`n=== Verification terminee ===" -ForegroundColor Cyan
