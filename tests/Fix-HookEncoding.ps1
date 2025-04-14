# Script pour corriger l'encodage du hook d'intégration

# Lire le contenu du fichier
$filePath = Join-Path -Path $PSScriptRoot -ChildPath "TestOmnibus\hooks\ErrorPatternAnalyzer.ps1"
$content = Get-Content -Path $filePath -Raw

# Supprimer les espaces en fin de ligne
$content = $content -replace '\s+$', ''

# Créer un encodeur UTF-8 avec BOM
$utf8WithBom = New-Object System.Text.UTF8Encoding $true

# Écrire le contenu avec le nouvel encodage
[System.IO.File]::WriteAllText($filePath, $content, $utf8WithBom)

Write-Host "Encodage corrigé en UTF-8 avec BOM et espaces en fin de ligne supprimés" -ForegroundColor Green
