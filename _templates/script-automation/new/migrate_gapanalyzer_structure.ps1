# PowerShell
# Script de migration structure Go pour cmd/gapanalyzer/

$sourceDir = "cmd/gapanalyzer"
$backupDir = "backup/gapanalyzer"
$newPkgDir = "cmd/gapanalyzer/gapanalyzer"
$logFile = "_templates/script-automation/new/migrate_gapanalyzer_structure.log"

# 1. Backup
Write-Output "Backup en cours..." | Tee-Object -FilePath $logFile
Copy-Item $sourceDir $backupDir -Recurse -Force
Write-Output "Backup terminé dans $backupDir" | Tee-Object -FilePath $logFile -Append

# 2. Création du dossier package si absent
if (!(Test-Path $newPkgDir)) {
   New-Item -ItemType Directory -Path $newPkgDir
   Write-Output "Dossier package créé: $newPkgDir" | Tee-Object -FilePath $logFile -Append
}

# 3. Déplacement du fichier package
if (Test-Path "$sourceDir/gapanalyzer.go") {
   Move-Item "$sourceDir/gapanalyzer.go" "$newPkgDir/gapanalyzer.go"
   Write-Output "Fichier déplacé: gapanalyzer.go -> $newPkgDir" | Tee-Object -FilePath $logFile -Append
}
else {
   Write-Output "Fichier gapanalyzer.go introuvable." | Tee-Object -FilePath $logFile -Append
}

Write-Output "Migration terminée." | Tee-Object -FilePath $logFile -Append