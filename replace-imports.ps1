# Script PowerShell pour remplacer tous les imports github.com/email-sender/ par github.com/gerivdb/email-sender-1/ dans tous les fichiers .go

Get-ChildItem -Path . -Recurse -Include *.go | ForEach-Object {
    (Get-Content $_.FullName) -replace 'github\.com/email-sender/', 'github.com/gerivdb/email-sender-1/' | Set-Content $_.FullName
}
Write-Host "Remplacement terminé dans tous les fichiers .go"
