# Script PowerShell pour corriger les problèmes de sous-modules lors du clonage
# Utilisation: .\scripts\fix-submodules.ps1

Write-Host "🔧 Fixing submodule issues..." -ForegroundColor Yellow

# Synchroniser la configuration des sous-modules
Write-Host "📝 Synchronizing submodule configuration..." -ForegroundColor Blue
git submodule sync

# Initialiser et mettre à jour les sous-modules
Write-Host "🔄 Initializing and updating submodules..." -ForegroundColor Blue
git submodule update --init --recursive

# Vérifier le statut des sous-modules
Write-Host "✅ Checking submodule status..." -ForegroundColor Green
git submodule status

Write-Host "🎉 Submodule fix completed!" -ForegroundColor Green
