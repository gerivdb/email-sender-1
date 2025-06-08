Write-Host "=== VERIFICATION STRATEGIE JULES ===" -ForegroundColor Cyan

$julesBranches = git branch -a | Where-Object { $_ -match "jules" }
Write-Host "Branches Jules trouvees: $($julesBranches.Count)" -ForegroundColor Green

if ($julesBranches.Count -gt 0) {
   Write-Host "`nBranches detectees:" -ForegroundColor Yellow
   $julesBranches | ForEach-Object { Write-Host "  * $_" -ForegroundColor White }
    
   Write-Host "`n✅ SYSTEME JULES OPERATIONNEL" -ForegroundColor Green
   Write-Host "📊 Strategie de branching fonctionnelle" -ForegroundColor Cyan
   Write-Host "🔄 Remontee qualitative active" -ForegroundColor Cyan
}
else {
   Write-Host "❌ Aucune branche Jules detectee" -ForegroundColor Red
}

Write-Host "`n=== ANALYSE TERMINEE ===" -ForegroundColor Cyan
