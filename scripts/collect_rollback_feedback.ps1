# PowerShell script to collect rollback feedback
$docsDir = "docs"
$outputFile = Join-Path $docsDir "rollback_feedback.md"

# Ensure the docs directory exists
if (-not (Test-Path $docsDir)) {
   New-Item -ItemType Directory -Path $docsDir | Out-Null
}

Write-Host "# Feedback rollback" | Out-File -FilePath $outputFile -Encoding utf8
$user = Read-Host "Nom utilisateur"
$feedback = Read-Host "Feedback"

Add-Content -Path $outputFile -Value "- Utilisateur : $user" -Encoding utf8
Add-Content -Path $outputFile -Value "- Feedback : $feedback" -Encoding utf8

Write-Host "Feedback collecté et enregistré dans $outputFile"
