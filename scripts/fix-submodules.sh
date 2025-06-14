#!/bin/bash

# Script pour corriger les problèmes de sous-modules lors du clonage
# Utilisation: ./scripts/fix-submodules.sh

echo "🔧 Fixing submodule issues..."

# Synchroniser la configuration des sous-modules
echo "📝 Synchronizing submodule configuration..."
git submodule sync

# Initialiser et mettre à jour les sous-modules
echo "🔄 Initializing and updating submodules..."
git submodule update --init --recursive

# Vérifier le statut des sous-modules
echo "✅ Checking submodule status..."
git submodule status

echo "🎉 Submodule fix completed!"
