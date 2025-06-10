# Script pour démarrer le stack d'infrastructure Docker
# Ce script a été créé pour implémenter la Phase 1.1.3 du Plan-dev-v54

# Afficher un message explicatif
Write-Host "🚀 Démarrage du stack d'infrastructure EMAIL_SENDER_1..." -ForegroundColor Cyan
Write-Host "📋 Services à démarrer: QDrant → Redis → PostgreSQL → Prometheus → Grafana → Applications" -ForegroundColor Cyan
Write-Host "=============================================================================" -ForegroundColor DarkCyan

# Définir le chemin du fichier docker-compose.yml
$DockerComposePath = Join-Path $PSScriptRoot "docker-compose.yml"

# Vérifier que le fichier existe
if (-Not (Test-Path $DockerComposePath)) {
    Write-Host "❌ ERREUR: Le fichier docker-compose.yml est introuvable à $DockerComposePath" -ForegroundColor Red
    exit 1
}

# Exécuter docker-compose
try {
    Write-Host "🔄 Démarrage des conteneurs avec docker-compose up -d..." -ForegroundColor Yellow
    docker-compose -f $DockerComposePath up -d
    
    # Attendre un peu pour que les conteneurs démarrent
    Start-Sleep -Seconds 5
    
    # Afficher l'état des conteneurs
    Write-Host "📊 État des conteneurs:" -ForegroundColor Green
    docker-compose -f $DockerComposePath ps
    
    Write-Host "✅ Infrastructure démarrée avec succès! L'orchestration séquentielle a été appliquée." -ForegroundColor Green
    Write-Host "   Phase 1.1.3 du Plan-dev-v54 complétée." -ForegroundColor Green
    
    # Afficher comment vérifier les logs
    Write-Host "`r`n📋 Pour vérifier les logs, exécutez:" -ForegroundColor Yellow
    Write-Host "docker-compose logs --follow" -ForegroundColor Gray
}
catch {
    Write-Host "❌ ERREUR lors du démarrage des conteneurs: $_" -ForegroundColor Red
    exit 1
}
