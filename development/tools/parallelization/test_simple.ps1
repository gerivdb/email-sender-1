# Script de test simple
Write-Host "Test de script simple"
try {
    throw "Erreur de test"
} catch {
    Write-Host "Erreur capturée: $($_.Exception.Message)"
}
Write-Host "Test terminé"
