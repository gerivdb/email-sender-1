# Script pour tester les MCP

Write-Host "=== Test des MCP ===" -ForegroundColor Cyan

# Tester le MCP Standard
Write-Host "`n[1] Test du MCP Standard" -ForegroundColor Yellow
try {
    $output = & .\mcp-standard.cmd 2>&1
    Write-Host "Sortie: $output"
    Write-Host "✅ Le MCP Standard semble fonctionner" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors du test du MCP Standard: $_" -ForegroundColor Red
}

# Tester le MCP Notion
Write-Host "`n[2] Test du MCP Notion" -ForegroundColor Yellow
try {
    $output = & .\mcp-notion.cmd 2>&1
    Write-Host "Sortie: $output"
    Write-Host "✅ Le MCP Notion semble fonctionner" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors du test du MCP Notion: $_" -ForegroundColor Red
}

# Tester le MCP Gateway
Write-Host "`n[3] Test du MCP Gateway" -ForegroundColor Yellow
try {
    $output = & .\gateway.exe.cmd help 2>&1
    Write-Host "Sortie: $output"
    Write-Host "✅ Le MCP Gateway semble fonctionner" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors du test du MCP Gateway: $_" -ForegroundColor Red
}

Write-Host "`n=== Fin des tests ===" -ForegroundColor Cyan
Write-Host "Si tous les tests sont passes, les MCP devraient fonctionner correctement dans n8n."
Write-Host "Suivez les instructions du fichier CONFIGURATION_MCP_MISE_A_JOUR.md pour configurer les identifiants MCP dans n8n."

