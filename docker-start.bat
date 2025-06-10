@echo off
echo 🚀 Démarrage du stack d'infrastructure EMAIL_SENDER_1...
echo 📋 Services à démarrer: QDrant → Redis → PostgreSQL → Prometheus → Grafana → Applications
echo =============================================================================

cd /d "%~dp0"
echo 🔍 Répertoire actuel: %CD%

if not exist "docker-compose.yml" (
    echo ❌ ERREUR: Le fichier docker-compose.yml est introuvable!
    exit /b 1
)

echo 🔄 Démarrage des conteneurs avec docker-compose up -d...
docker-compose up -d

if %ERRORLEVEL% neq 0 (
    echo ❌ ERREUR lors du démarrage des conteneurs!
    exit /b %ERRORLEVEL%
)

timeout /t 5 /nobreak > nul

echo 📊 État des conteneurs:
docker-compose ps

echo.
echo ✅ Infrastructure démarrée avec succès! L'orchestration séquentielle a été appliquée.
echo    Phase 1.1.3 du Plan-dev-v54 complétée.
echo.
echo 📋 Pour vérifier les logs, exécutez:
echo docker-compose logs --follow

pause
