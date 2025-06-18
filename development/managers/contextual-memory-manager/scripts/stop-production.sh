#!/bin/bash
# scripts/stop-production.sh
# Script d'arrêt pour l'environnement de production

set -e

PID_FILE=${1:-/var/run/contextual-memory-manager.pid}
TIMEOUT=${2:-30}

echo "🛑 Stopping Contextual Memory Manager"

# Vérifier si le fichier PID existe
if [ ! -f "$PID_FILE" ]; then
    echo "❌ PID file not found: $PID_FILE"
    echo "🔍 Searching for running processes..."
    
    PIDS=$(pgrep -f "contextual-memory-manager" || true)
    if [ -n "$PIDS" ]; then
        echo "📋 Found running processes: $PIDS"
        for pid in $PIDS; do
            echo "🛑 Stopping process: $pid"
            kill -TERM $pid
        done
    else
        echo "ℹ️ No running processes found"
        exit 0
    fi
else
    PID=$(cat "$PID_FILE")
    echo "📋 Found PID: $PID"
    
    # Vérifier si le processus existe
    if ! kill -0 $PID 2>/dev/null; then
        echo "ℹ️ Process $PID is not running"
        rm -f "$PID_FILE"
        exit 0
    fi
    
    # Arrêt gracieux
    echo "🛑 Sending TERM signal to PID: $PID"
    kill -TERM $PID
    
    # Attendre l'arrêt gracieux
    echo "⏳ Waiting for graceful shutdown (timeout: ${TIMEOUT}s)..."
    for i in $(seq 1 $TIMEOUT); do
        if ! kill -0 $PID 2>/dev/null; then
            echo "✅ Process stopped gracefully"
            rm -f "$PID_FILE"
            exit 0
        fi
        sleep 1
        echo -n "."
    done
    
    # Forcer l'arrêt si nécessaire
    echo ""
    echo "⚠️ Graceful shutdown timeout, forcing termination..."
    kill -KILL $PID 2>/dev/null || true
    
    # Vérifier que le processus est arrêté
    sleep 2
    if kill -0 $PID 2>/dev/null; then
        echo "❌ Failed to stop process $PID"
        exit 1
    else
        echo "✅ Process forcefully terminated"
        rm -f "$PID_FILE"
    fi
fi

echo "✅ Contextual Memory Manager stopped successfully"
