#!/bin/bash

# build-and-run-dashboard.sh
# Script pour compiler et lancer le dashboard de synchronisation

set -e

echo "🎯 Phase 6.1.1 - Build et lancement du Dashboard de Synchronisation"
echo "================================================================"

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
DASHBOARD_BINARY="${BUILD_DIR}/dashboard"
LOG_DIR="${PROJECT_ROOT}/logs"
DB_PATH="${LOG_DIR}/sync_logs.db"

# Couleurs pour l'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction de nettoyage
cleanup() {
    if [[ -n $DASHBOARD_PID && -d /proc/$DASHBOARD_PID ]]; then
        print_status "Arrêt du dashboard (PID: $DASHBOARD_PID)..."
        kill $DASHBOARD_PID
        wait $DASHBOARD_PID 2>/dev/null || true
        print_success "Dashboard arrêté proprement"
    fi
}

# Gestionnaire de signal pour nettoyage
trap cleanup EXIT INT TERM

# Étape 1: Vérification de l'environnement
print_status "Vérification de l'environnement Go..."
if ! command -v go &> /dev/null; then
    print_error "Go n'est pas installé ou pas dans le PATH"
    exit 1
fi

GO_VERSION=$(go version | awk '{print $3}')
print_success "Go détecté: $GO_VERSION"

# Étape 2: Création des répertoires
print_status "Création des répertoires nécessaires..."
mkdir -p "$BUILD_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "${PROJECT_ROOT}/web/static/css"
mkdir -p "${PROJECT_ROOT}/web/static/js"
mkdir -p "${PROJECT_ROOT}/web/templates"

# Étape 3: Vérification des fichiers requis
print_status "Vérification des fichiers du projet..."
REQUIRED_FILES=(
    "web/dashboard/sync_dashboard.go"
    "web/templates/dashboard.html"
    "web/static/js/conflict-resolution.js"
    "web/static/css/dashboard.css"
    "tools/sync-logger.go"
    "cmd/dashboard/main.go"
)

missing_files=()
for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "${PROJECT_ROOT}/$file" ]]; then
        missing_files+=("$file")
    fi
done

if [[ ${#missing_files[@]} -gt 0 ]]; then
    print_error "Fichiers manquants:"
    for file in "${missing_files[@]}"; do
        echo "  - $file"
    done
    exit 1
fi

print_success "Tous les fichiers requis sont présents"

# Étape 4: Installation des dépendances
print_status "Installation des dépendances Go..."
cd "$PROJECT_ROOT"

if [[ ! -f "go.mod" ]]; then
    print_status "Initialisation du module Go..."
    go mod init sync-dashboard
fi

# Ajout des dépendances nécessaires
go mod edit -require github.com/gin-gonic/gin@v1.9.1
go mod edit -require github.com/gorilla/websocket@v1.5.0
go mod edit -require github.com/mattn/go-sqlite3@v1.14.17

print_status "Téléchargement des dépendances..."
go mod download
go mod tidy

print_success "Dépendances installées"

# Étape 5: Compilation
print_status "Compilation du dashboard..."
cd "$PROJECT_ROOT"

# Configuration de build
export CGO_ENABLED=1  # Requis pour SQLite
export GOOS="$(go env GOOS)"
export GOARCH="$(go env GOARCH)"

# Build avec optimisations
go build -v \
    -ldflags="-s -w" \
    -o "$DASHBOARD_BINARY" \
    ./cmd/dashboard

if [[ $? -eq 0 ]]; then
    print_success "Compilation réussie: $DASHBOARD_BINARY"
else
    print_error "Échec de la compilation"
    exit 1
fi

# Vérification du binaire
if [[ -x "$DASHBOARD_BINARY" ]]; then
    BINARY_SIZE=$(du -h "$DASHBOARD_BINARY" | cut -f1)
    print_success "Binaire créé: $BINARY_SIZE"
else
    print_error "Binaire non exécutable"
    exit 1
fi

# Étape 6: Configuration de lancement
print_status "Préparation du lancement..."

# Configuration par défaut
DEFAULT_PORT="8080"
DEFAULT_HOST="localhost"
DEFAULT_CLEANUP_DAYS="30"

# Lecture des variables d'environnement ou utilisation des valeurs par défaut
DASHBOARD_PORT="${DASHBOARD_PORT:-$DEFAULT_PORT}"
DASHBOARD_HOST="${DASHBOARD_HOST:-$DEFAULT_HOST}"
DASHBOARD_CLEANUP_DAYS="${DASHBOARD_CLEANUP_DAYS:-$DEFAULT_CLEANUP_DAYS}"

print_status "Configuration:"
echo "  - Port: $DASHBOARD_PORT"
echo "  - Host: $DASHBOARD_HOST"
echo "  - Base de données: $DB_PATH"
echo "  - Logs: $LOG_DIR"
echo "  - Rétention: $DASHBOARD_CLEANUP_DAYS jours"

# Étape 7: Lancement du dashboard
print_status "Lancement du dashboard..."

"$DASHBOARD_BINARY" \
    -port "$DASHBOARD_PORT" \
    -host "$DASHBOARD_HOST" \
    -db "$DB_PATH" \
    -log "${LOG_DIR}/dashboard.log" \
    -cleanup-days "$DASHBOARD_CLEANUP_DAYS" \
    &

DASHBOARD_PID=$!

# Attente du démarrage
sleep 2

if kill -0 $DASHBOARD_PID 2>/dev/null; then
    print_success "Dashboard démarré avec succès (PID: $DASHBOARD_PID)"
    echo ""
    echo "🌐 Accès au dashboard:"
    echo "   http://$DASHBOARD_HOST:$DASHBOARD_PORT"
    echo ""
    echo "📊 API Endpoints:"
    echo "   - Status: http://$DASHBOARD_HOST:$DASHBOARD_PORT/api/sync/status"
    echo "   - Conflits: http://$DASHBOARD_HOST:$DASHBOARD_PORT/api/sync/conflicts"
    echo "   - Health: http://$DASHBOARD_HOST:$DASHBOARD_PORT/health"
    echo ""
    echo "📝 Logs en temps réel:"
    echo "   tail -f ${LOG_DIR}/dashboard.log"
    echo ""
    print_warning "Appuyez sur Ctrl+C pour arrêter le dashboard"
    
    # Attente infinie jusqu'à signal d'arrêt
    wait $DASHBOARD_PID
else
    print_error "Échec du démarrage du dashboard"
    exit 1
fi
