# Script pour marquer les tâches terminées avec des cases à cocher
$filePath = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\plans\consolidated\plan-dev-v64-correlation-avec-manager-go-existant.md"

Write-Host "🔄 Mise à jour des tâches terminées..." -ForegroundColor Cyan

# Lire le contenu du fichier
$content = Get-Content $filePath -Raw

# Remplacements pour les tâches Phase 2 (023, 024, 025)
$content = $content -replace '- \*\*🎯 Action Atomique 023\*\*: Créer Structure API REST N8N→Go', '- [x] **🎯 Action Atomique 023**: Créer Structure API REST N8N→Go ✅'
$content = $content -replace '- \*\*🎯 Action Atomique 024\*\*: Implémenter Middleware Authentification', '- [x] **🎯 Action Atomique 024**: Implémenter Middleware Authentification ✅'
$content = $content -replace '- \*\*🎯 Action Atomique 025\*\*: Développer Serialization JSON Workflow', '- [x] **🎯 Action Atomique 025**: Développer Serialization JSON Workflow ✅'

# Remplacements pour les tâches Phase 4 (051, 052)
$content = $content -replace '- \*\*🎯 Action Atomique 051\*\*: Créer Configuration Docker Compose Blue', '- [x] **🎯 Action Atomique 051**: Créer Configuration Docker Compose Blue ✅'
$content = $content -replace '- \*\*🎯 Action Atomique 052\*\*: Créer Configuration Docker Compose Green', '- [x] **🎯 Action Atomique 052**: Créer Configuration Docker Compose Green ✅'

# Sauvegarder le fichier modifié
$content | Set-Content $filePath -Encoding UTF8

Write-Host "✅ Tâches marquées comme terminées :" -ForegroundColor Green
Write-Host "  - Tâche 023 (Phase 2) ✅" -ForegroundColor White
Write-Host "  - Tâche 024 (Phase 2) ✅" -ForegroundColor White  
Write-Host "  - Tâche 025 (Phase 2) ✅" -ForegroundColor White
Write-Host "  - Tâche 051 (Phase 4) ✅" -ForegroundColor White
Write-Host "  - Tâche 052 (Phase 4) ✅" -ForegroundColor White

Write-Host "`n🎯 Fichier mis à jour avec succès!" -ForegroundColor Magenta
