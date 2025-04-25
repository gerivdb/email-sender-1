# Script pour remplacer toutes les occurrences de "Detect-FileFormatWithConfirmation" par "Test-FileFormatWithConfirmation"
$filePath = ".\Test-FileFormatWithConfirmation.Tests.ps1"
$content = Get-Content -Path $filePath -Raw
$newContent = $content -replace "Detect-FileFormatWithConfirmation", "Test-FileFormatWithConfirmation"
$newContent | Set-Content -Path $filePath -Encoding UTF8
Write-Host "Remplacement terminé."
