# Script PowerShell pour sauvegarder le fichier de test d’authentification (chemin corrigé)
$src = "tests/authentification/authentification_test.go"
$dst = "tests/authentification/authentification_test.go.bak"
Copy-Item -Path $src -Destination $dst -Force
Write-Output "Backup PowerShell réalisé avec succès: $dst"