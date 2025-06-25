# Phase 3 & 2.4 – Automatisation architecture cible et reporting (PowerShell)
# Respecte granularité, validation croisée, rollback, CI/CD

param(
   [string]$OutputDir = "core/docmanager/outputs",
   [string]$DocsDir = "docs/technical"
)

Write-Host "=== [Phase 3] Génération architecture cible et outputs ==="

# 1. Extraction des dépendances (Node.js)
Write-Host "Extraction des dépendances (dependency-analyzer.js)..."
node scripts/dependency-analyzer.js --scan-all > "$OutputDir/dependencies.json"

# 2. Génération du graphe (Go)
Write-Host "Génération du graphe (graphgen.go)..."
go run core/docmanager/graphgen.go --input "$OutputDir/dependencies.json" --output "$DocsDir/graph.svg"

# 3. Génération de la documentation technique (Python)
Write-Host "Génération documentation technique (docgen.py)..."
python scripts/docgen.py --source "$OutputDir/dependencies.json" --output "$DocsDir/ARCHITECTURE.md"

# 4. Synchronisation documentaire (Node.js)
Write-Host "Synchronisation documentaire (sync.js)..."
node scripts/sync.js --docs docs/ --output "$DocsDir/ARCHITECTURE.md"

# 5. Validation croisée et reporting
Write-Host "Validation croisée des livrables..."
if (Test-Path "$OutputDir/dependencies.json" -and Test-Path "$DocsDir/graph.svg" -and Test-Path "$DocsDir/ARCHITECTURE.md") {
   Write-Host "Tous les livrables générés avec succès."
   # Reporting dans ANALYSE_DIFFICULTS_PHASE1.md
   Add-Content ANALYSE_DIFFICULTS_PHASE1.md "`n[Phase 3] Génération et validation automatique réussie le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}
else {
   Write-Error "Erreur : Un ou plusieurs livrables manquent. Rollback conseillé."
   # Rollback
   if (Test-Path "$DocsDir/ARCHITECTURE.bak.md") {
      Copy-Item "$DocsDir/ARCHITECTURE.bak.md" "$DocsDir/ARCHITECTURE.md" -Force
      Write-Host "Rollback effectué sur la documentation technique."
   }
}

Write-Host "=== Fin Phase 3 & 2.4 ==="
