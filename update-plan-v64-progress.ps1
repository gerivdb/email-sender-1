#!/usr/bin/env powershell

# Script pour mettre à jour le plan v64 avec les tâches terminées
# Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

$planFile = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\plans\consolidated\plan-dev-v64-correlation-avec-manager-go-existant.md"

Write-Host "🔄 Mise à jour du plan v64 avec les tâches terminées..." -ForegroundColor Yellow

# Lire le contenu du fichier
$content = Get-Content $planFile -Raw -Encoding UTF8

# Mettre à jour la progression globale
$content = $content -replace '****Phase 2:**** 🔄 11% \(3/28 tâches - 023, 024, 025 terminées\)', '****Phase 2:**** 🔄 25% (7/28 tâches - 023-029 terminées)'

# Ajouter les nouvelles tâches terminées dans la liste
$oldCompletedSection = @"
- \[x\] \*\*Tâche 023\*\* - Structure API REST N8N→Go ✅
- \[x\] \*\*Tâche 024\*\* - Middleware Authentification ✅  
- \[x\] \*\*Tâche 025\*\* - Serialization JSON Workflow ✅
- \[x\] \*\*Tâche 051\*\* - Configuration Docker Compose Blue ✅ \(anticipée\)
- \[x\] \*\*Tâche 052\*\* - Configuration Docker Compose Green ✅ \(anticipée\)
"@

$newCompletedSection = @"
- [x] **Tâche 023** - Structure API REST N8N→Go ✅
- [x] **Tâche 024** - Middleware Authentification ✅  
- [x] **Tâche 025** - Serialization JSON Workflow ✅
- [x] **Tâche 026** - HTTP Client Go→N8N ✅
- [x] **Tâche 027** - Webhook Handler Callbacks ✅
- [x] **Tâche 028** - Event Bus Interne ✅
- [x] **Tâche 029** - Status Tracking System ✅
- [x] **Tâche 051** - Configuration Docker Compose Blue ✅ (anticipée)
- [x] **Tâche 052** - Configuration Docker Compose Green ✅ (anticipée)
"@

$content = $content -replace [regex]::Escape($oldCompletedSection), $newCompletedSection

# Mettre à jour la prochaine étape
$content = $content -replace '\*\*\*\*Prochaine étape:\*\*\*\* Tâche 026 - HTTP Client Go→N8N \(20 min max\)', '****Prochaine étape:**** Tâche 030 - Convertisseur N8N→Go Data Format (30 min max)'

# Marquer les tâches individuelles
$taskUpdates = @{
   '- \*\*🎯 Action Atomique 027\*\*: Implémenter Webhook Handler Callbacks' = '- [x] **🎯 Action Atomique 027**: Implémenter Webhook Handler Callbacks ✅'
   '- \*\*🎯 Action Atomique 028\*\*: Développer Event Bus Interne'          = '- [x] **🎯 Action Atomique 028**: Développer Event Bus Interne ✅'
   '- \*\*🎯 Action Atomique 029\*\*: Créer Status Tracking System'          = '- [x] **🎯 Action Atomique 029**: Créer Status Tracking System ✅'
}

foreach ($pattern in $taskUpdates.Keys) {
   $replacement = $taskUpdates[$pattern]
   $content = $content -replace [regex]::Escape($pattern), $replacement
}

# Sauvegarder le fichier mis à jour
$content | Set-Content $planFile -Encoding UTF8

Write-Host "✅ Plan v64 mis à jour avec succès!" -ForegroundColor Green
Write-Host "📊 Tâches terminées mises à jour:" -ForegroundColor Cyan
Write-Host "   • Phase 2: 7/28 tâches (25%)" -ForegroundColor Green
Write-Host "   • Tâches 026-029 marquées comme terminées" -ForegroundColor Green
Write-Host "   • Prochaine étape: Tâche 030" -ForegroundColor Yellow

# Vérifier les changements
Write-Host "🔍 Vérification des changements..." -ForegroundColor Blue

$verifyContent = Get-Content $planFile -Raw -Encoding UTF8
if ($verifyContent -match "025% \(7/28 tâches - 023-029 terminées\)") {
   Write-Host "✅ Progression mise à jour correctement" -ForegroundColor Green
}
else {
   Write-Host "❌ Erreur dans la mise à jour de la progression" -ForegroundColor Red
}

if ($verifyContent -match "Tâche 026.*✅" -and $verifyContent -match "Tâche 027.*✅" -and $verifyContent -match "Tâche 028.*✅" -and $verifyContent -match "Tâche 029.*✅") {
   Write-Host "✅ Toutes les nouvelles tâches marquées" -ForegroundColor Green
}
else {
   Write-Host "❌ Certaines tâches ne sont pas marquées correctement" -ForegroundColor Red
}

Write-Host "🎯 Mise à jour terminée!" -ForegroundColor Magenta
