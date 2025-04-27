# Script pour remplacer toutes les occurrences de "Detect-FileFormat" par "Test-FileFormat"
$filePath = "..\Detectors\Detect-FileFormatWithConfirmation.ps1"
$content = Get-Content -Path $filePath -Raw
$newContent = $content -replace "Detect-FileFormat", "Test-FileFormat"
$newContent | Set-Content -Path $filePath -Encoding UTF8
Write-Host "Remplacement terminÃ©."
