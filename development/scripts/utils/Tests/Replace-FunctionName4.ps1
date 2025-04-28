# Script pour remplacer toutes les occurrences de "Detect-FileFormat" par "Test-FileFormat"
$filePath = "..\Integrations\FormatDetection-Integration.ps1"
if (Test-Path -Path $filePath) {
    $content = Get-Content -Path $filePath -Raw
    $newContent = $content -replace "Detect-FileFormat", "Test-FileFormat"
    $newContent | Set-Content -Path $filePath -Encoding UTF8
    Write-Host "Remplacement terminÃ©."
} else {
    Write-Host "Le fichier $filePath n'existe pas."
}
