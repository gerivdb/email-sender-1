# Script d'analyse rapide des contributions Jules
Write-Host "ANALYSE CONTRIBUTIONS JULES" -ForegroundColor Cyan

# Compter les branches Jules
$julesBranches = @()
git branch -a | ForEach-Object {
   if ($_ -match "jules") {
      $julesBranches += $_.Trim()
   }
}

Write-Host "Branches Jules detectees: $($julesBranches.Count)" -ForegroundColor Green
$julesBranches | ForEach-Object { Write-Host "  - $_" }

# Analyser la qualité des commits
Write-Host "`nAnalyse qualite des commits:" -ForegroundColor Yellow
$qualityPatterns = @("SOLID", "DRY", "KISS", "refactor", "optimize", "clean", "fix", "improve")

foreach ($pattern in $qualityPatterns) {
   $count = (git log --all --grep="$pattern" --oneline | Measure-Object).Count
   if ($count -gt 0) {
      Write-Host "  $pattern : $count commits" -ForegroundColor Green
   }
}

Write-Host "`nAnalyse terminee." -ForegroundColor Cyan
