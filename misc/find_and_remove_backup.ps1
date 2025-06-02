# Script pour trouver et supprimer le fichier types_backup.go
Write-Host "Recherche du fichier types_backup.go..."

# Recherche dans tout le projet
$backupFiles = Get-ChildItem -Path "." -Recurse -Name "types_backup.go" -Force -ErrorAction SilentlyContinue

if ($backupFiles) {
    Write-Host "Fichiers trouvés:"
    foreach ($file in $backupFiles) {
        Write-Host "  - $file"
        $fullPath = Join-Path $PWD $file
        try {
            Remove-Item $fullPath -Force
            Write-Host "    ✓ Supprimé avec succès"
        }
        catch {
            Write-Host "    ✗ Erreur lors de la suppression: $_"
        }
    }
} else {
    Write-Host "Aucun fichier types_backup.go trouvé."
}

# Vérification des fichiers cachés ou verrouillés
Write-Host "`nRecherche de fichiers cachés ou temporaires..."
$tempFiles = Get-ChildItem -Path "." -Recurse -Name "*backup*" -Force -ErrorAction SilentlyContinue | Where-Object { $_ -like "*types*" }

if ($tempFiles) {
    Write-Host "Fichiers suspects trouvés:"
    foreach ($file in $tempFiles) {
        Write-Host "  - $file"
    }
} else {
    Write-Host "Aucun fichier suspect trouvé."
}

Write-Host "`nNettoyage du cache Go..."
go clean -cache
go clean -modcache

Write-Host "Nettoyage terminé."