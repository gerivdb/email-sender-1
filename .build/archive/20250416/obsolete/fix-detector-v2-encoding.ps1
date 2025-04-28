# Script pour corriger l'encodage du fichier de détection v2
$filePath = ".\development\scripts\maintenance\encoding\Detect-VariableReferencesInAccentedStrings-v2.ps1"
$content = Get-Content -Path $filePath -Raw
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($filePath, $content, $utf8WithBom)
Write-Host "Encodage corrige en UTF-8 avec BOM" -ForegroundColor Green
