# PowerShell script to collect user feedback
$docsDir = "docs"
$outputFile = Join-Path $docsDir "read_file_user_feedback.md"

# Ensure the docs directory exists
if (-not (Test-Path $docsDir)) {
   New-Item -ItemType Directory -Path $docsDir | Out-Null
}

Write-Host "# Recueil des besoins utilisateurs pour read_file" | Out-File -FilePath $outputFile -Encoding utf8
$user = Read-Host "Nom utilisateur"
$feedback = Read-Host "Feedback"

Add-Content -Path $outputFile -Value "- Utilisateur : $user" -Encoding utf8
Add-Content -Path $outputFile -Value "- Feedback : $feedback" -Encoding utf8

Write-Host "Feedback collecté et enregistré dans $outputFile"
