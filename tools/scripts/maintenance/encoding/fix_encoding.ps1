# Script pour corriger l'encodage des fichiers PowerShell
# Sauvegarde les fichiers en UTF-8 with BOM

$files = @(
    "src/script_manager.ps1",
    "src/script_config.ps1"
)

foreach ($file in $files) {
    $content = Get-Content -Path $file -Raw
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($file, $content, $utf8WithBom)
    Write-Host "Encodage corrigé pour $file"
}
