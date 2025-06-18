# Marquage de la tâche 026 comme terminée
$filePath = "projet\roadmaps\plans\consolidated\plan-dev-v64-correlation-avec-manager-go-existant.md"

$content = Get-Content $filePath -Raw
$content = $content -replace '- \*\*🎯 Action Atomique 026\*\*: Créer HTTP Client Go→N8N', '- [x] **🎯 Action Atomique 026**: Créer HTTP Client Go→N8N ✅'
$content | Set-Content $filePath -Encoding UTF8

Write-Host "✅ Tâche 026 marquée comme terminée!" -ForegroundColor Green
