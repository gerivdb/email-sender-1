# Script pour corriger l'encodage du fichier de dÃ©tection
$filePath = ".\scripts\maintenance\encoding\Detect-VariableReferencesInAccentedStrings.ps1"
$content = Get-Content -Path $filePath -Raw
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($filePath, $content, $utf8WithBom)
Write-Host "Encodage corrige en UTF-8 avec BOM" -ForegroundColor Green
