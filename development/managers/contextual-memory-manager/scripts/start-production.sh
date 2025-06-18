#!/bin/bash
# scripts/start-production.sh
# Script de démarrage pour l'environnement de production

set -e

CONFIG_FILE=${1:-hybrid_production.yaml}
LOG_FILE=${2:-/var/log/contextual-memory-manager.log}

echo "🚀 Starting Contextual Memory Manager in Production Mode"
echo "Config: $CONFIG_FILE"
echo "Logs: $LOG_FILE"

# Vérifications de sécurité
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Création du répertoire de logs
mkdir -p "$(dirname "$LOG_FILE")"

# Vérification des permissions
if [ ! -w "$(dirname "$LOG_FILE")" ]; then
    echo "❌ Cannot write to log directory: $(dirname "$LOG_FILE")"
    exit 1
fi

# Démarrage avec supervision
echo "✅ Starting service..."
nohup ./contextual-memory-manager \
    --config="$CONFIG_FILE" \
    --env=production \
    --log-file="$LOG_FILE" \
    > "$LOG_FILE" 2>&1 &

PID=$!
echo "📋 Service started with PID: $PID"

# Sauvegarder le PID
echo $PID > /var/run/contextual-memory-manager.pid

# Vérification de démarrage
sleep 5
if kill -0 $PID 2>/dev/null; then
    echo "✅ Service is running successfully"
    echo "📋 Health check: curl http://localhost:8091/health"
    echo "📊 Dashboard: http://localhost:8090/dashboard"
else
    echo "❌ Service failed to start"
    echo "📋 Check logs: tail -f $LOG_FILE"
    exit 1
fi
