# Script pour marquer les tâches 027, 028, 029 comme complétées
$planFile = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\plans\consolidated\plan-dev-v64-correlation-avec-manager-go-existant.md"

# Lecture du contenu
$content = Get-Content $planFile -Raw

# Patterns à rechercher et remplacer
$patterns = @{
   '- \*\*🎯 Action Atomique 027\*\*: Implémenter Webhook Handler Callbacks' = '- [x] **🎯 Action Atomique 027**: Implémenter Webhook Handler Callbacks ✅'
   '- \*\*🎯 Action Atomique 028\*\*: Développer Event Bus Interne'          = '- [x] **🎯 Action Atomique 028**: Développer Event Bus Interne ✅'
   '- \*\*🎯 Action Atomique 029\*\*: Créer Status Tracking System'          = '- [x] **🎯 Action Atomique 029**: Créer Status Tracking System ✅'
}

# Application des remplacements
foreach ($pattern in $patterns.Keys) {
   $replacement = $patterns[$pattern]
   $content = $content -replace $pattern, $replacement
}

# Écriture du fichier modifié
$content | Set-Content $planFile -Encoding UTF8

Write-Host "✅ Tâches 027, 028, 029 marquées comme complétées dans le plan"
Write-Host "📁 Fichier modifié: $planFile"
