# PowerShell diagnostic script for SOTA+++ structure creation

$PROJECT_ROOT = "2025-0807-visu-interactiv-orch-mode"

Write-Host "Chemin d'exécution du script : $(Get-Location)"
Write-Host "Vérification de la présence du dossier cible : $PROJECT_ROOT"

if (Test-Path $PROJECT_ROOT) {
   Write-Host "Le dossier $PROJECT_ROOT existe."
   Write-Host "Contenu du dossier $PROJECT_ROOT :"
   Get-ChildItem -Path $PROJECT_ROOT -Recurse | Select-Object FullName
}
else {
   Write-Host "Le dossier $PROJECT_ROOT n'existe PAS."
}

Write-Host "Vérification des droits d'écriture dans le dossier courant..."
$testfile = "test_write_access.txt"
try {
   New-Item -ItemType File -Path $testfile -Force | Out-Null
   Write-Host "Droit d'écriture OK."
   Remove-Item $testfile
}
catch {
   Write-Host "ERREUR : Impossible d'écrire dans le dossier courant."
}

Write-Host "Fin du diagnostic."
