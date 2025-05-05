# Script pour corriger l'encodage du hook d'intÃ©gration

# Lire le contenu du fichier
$filePath = Join-Path -Path $PSScriptRoot -ChildPath "TestOmnibus\hooks\ErrorPatternAnalyzer.ps1"
$content = Get-Content -Path $filePath -Raw

# Supprimer les espaces en fin de ligne
$content = $content -replace '\s+$', ''

# CrÃ©er un encodeur UTF-8 avec BOM
$utf8WithBom = New-Object System.Text.UTF8Encoding $true

# Ã‰crire le contenu avec le nouvel encodage
[System.IO.File]::WriteAllText($filePath, $content, $utf8WithBom)

Write-Host "Encodage corrigÃ© en UTF-8 avec BOM et espaces en fin de ligne supprimÃ©s" -ForegroundColor Green
