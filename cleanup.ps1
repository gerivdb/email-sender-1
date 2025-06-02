Write-Host "Recherche du fichier types_backup.go..."
$backupFiles = Get-ChildItem -Path "." -Recurse -Name "types_backup.go" -Force -ErrorAction SilentlyContinue
if ($backupFiles) {
    Write-Host "Fichiers trouves:"
    foreach ($file in $backupFiles) {
        Write-Host "  - $file"
        $fullPath = Join-Path $PWD $file
        Remove-Item $fullPath -Force
        Write-Host "    Supprime"
    }
} else {
    Write-Host "Aucun fichier types_backup.go trouve."
}
Write-Host "Nettoyage du cache Go..."
go clean -cache
Write-Host "Termine."