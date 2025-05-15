# Script pour vérifier la synchronisation Git
Set-Location D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1

# Vérifier le statut
$status = git status
Write-Host "Statut Git:" -ForegroundColor Cyan
$status

# Vérifier les derniers commits
Write-Host "`nDerniers commits:" -ForegroundColor Cyan
git log --oneline -n 5

# Vérifier la synchronisation avec le dépôt distant
Write-Host "`nSynchronisation avec le dépôt distant:" -ForegroundColor Cyan
$ahead = git rev-list --count '@{u}..HEAD'
$behind = git rev-list --count 'HEAD..@{u}'

if ($ahead -eq 0 -and $behind -eq 0) {
    Write-Host "Le dépôt local est synchronisé avec le dépôt distant." -ForegroundColor Green
} elseif ($ahead -gt 0 -and $behind -eq 0) {
    Write-Host "Le dépôt local est en avance de $ahead commit(s) sur le dépôt distant." -ForegroundColor Yellow
} elseif ($ahead -eq 0 -and $behind -gt 0) {
    Write-Host "Le dépôt local est en retard de $behind commit(s) sur le dépôt distant." -ForegroundColor Red
} else {
    Write-Host "Le dépôt local est en avance de $ahead commit(s) et en retard de $behind commit(s) sur le dépôt distant." -ForegroundColor Red
}

# Vérifier les fichiers modifiés
$modified = git ls-files --modified
if ($modified) {
    Write-Host "`nFichiers modifiés:" -ForegroundColor Yellow
    $modified
} else {
    Write-Host "`nAucun fichier modifié." -ForegroundColor Green
}

# Vérifier les fichiers non suivis
$untracked = git ls-files --others --exclude-standard
if ($untracked) {
    Write-Host "`nFichiers non suivis:" -ForegroundColor Yellow
    $untracked
} else {
    Write-Host "`nAucun fichier non suivi." -ForegroundColor Green
}
