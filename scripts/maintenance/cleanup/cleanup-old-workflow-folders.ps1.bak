# Script pour supprimer les anciens dossiers workflows aprÃ¨s la rÃ©organisation

Write-Host "=== Suppression des anciens dossiers workflows ===" -ForegroundColor Cyan

# Liste des anciens dossiers workflows Ã  supprimer
$oldWorkflowFolders = @(
    "workflows",
    "workflows-fixed",
    "workflows-fixed-all",
    "workflows-fixed-encoding",
    "workflows-fixed-names-py",
    "workflows-no-accents-py",
    "workflows-utf8"
)

# VÃ©rifier si les dossiers sont vides avant de les supprimer
foreach ($folder in $oldWorkflowFolders) {
    if (Test-Path $folder) {
        $files = Get-ChildItem -Path $folder -File
        if ($files.Count -eq 0) {
            # Le dossier est vide, on peut le supprimer
            Remove-Item -Path $folder -Force
            Write-Host "  Dossier $folder supprimÃ© (vide)" -ForegroundColor Green
        } else {
            Write-Host "  Dossier $folder contient encore $($files.Count) fichier(s), impossible de le supprimer" -ForegroundColor Yellow
            Write-Host "  Voulez-vous forcer la suppression du dossier $folder et de son contenu ? (O/N)" -ForegroundColor Yellow
            $confirmation = Read-Host
            
            if ($confirmation -eq "O" -or $confirmation -eq "o") {
                Remove-Item -Path $folder -Recurse -Force
                Write-Host "  Dossier $folder et son contenu supprimÃ©s" -ForegroundColor Green
            } else {
                Write-Host "  Dossier $folder conservÃ©" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "  Dossier $folder n'existe pas" -ForegroundColor Gray
    }
}

Write-Host "`n=== Suppression terminÃ©e ===" -ForegroundColor Cyan
