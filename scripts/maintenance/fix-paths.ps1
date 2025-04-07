# Script pour corriger les chemins dans les fichiers de configuration
# Ce script remplace les anciens chemins par les nouveaux chemins dans les fichiers de configuration

Write-Host "=== Correction des chemins dans les fichiers de configuration ===" -ForegroundColor Cyan

# Ancien chemin (avec espaces et accents)
$oldPathVariants = @(
    "D:\\DO\\WEB\\N8N_tests\\scripts_ json_a_ tester\\EMAIL_SENDER_1",
    "D:\\DO\\WEB\\N8N_tests\\scripts_ json_a_ tester\\EMAIL_SENDER_1",
    "D:\\DO\\WEB\\N8N_tests\\scripts_ json_a_ tester\\EMAIL_SENDER_1"
)

# Nouveau chemin (avec underscores)
$newPath = "D:\\DO\\WEB\\N8N_tests\\scripts_ json_a_ tester\\EMAIL_SENDER_1"

# Types de fichiers Ã  corriger
$fileTypes = @("*.json", "*.cmd", "*.ps1", "*.yaml", "*.md")

# Fonction pour corriger un fichier
function Fix-File {
    param (
        [string]$filePath
    )
    
    $content = Get-Content -Path $filePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        return $false
    }
    
    $modified = $false
    foreach ($variant in $oldPathVariants) {
        if ($content -match [regex]::Escape($variant)) {
            $content = $content -replace [regex]::Escape($variant), $newPath
            $modified = $true
        }
    }
    
    if ($modified) {
        Set-Content -Path $filePath -Value $content -NoNewline
        return $true
    }
    
    return $false
}

# Rechercher et corriger les fichiers contenant les anciens chemins
$correctedFiles = @()

foreach ($fileType in $fileTypes) {
    $files = Get-ChildItem -Path . -Recurse -File -Filter $fileType
    foreach ($file in $files) {
        if (Fix-File -filePath $file.FullName) {
            $correctedFiles += $file.FullName
        }
    }
}

# Afficher les rÃ©sultats
if ($correctedFiles.Count -eq 0) {
    Write-Host "âœ… Aucun fichier n'a eu besoin d'Ãªtre corrigÃ©." -ForegroundColor Green
} else {
    Write-Host "âœ… Les fichiers suivants ont Ã©tÃ© corrigÃ©s :" -ForegroundColor Green
    foreach ($file in $correctedFiles) {
        Write-Host "   - $file" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Correction terminee ===" -ForegroundColor Cyan
Write-Host "Pour vÃ©rifier que tous les chemins ont Ã©tÃ© corrigÃ©s, exÃ©cutez :"
Write-Host "   .\scripts\maintenance\check-paths.ps1"
