# Détection des imports cycliques dans le projet Go
$root = "d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1"
$pattern = 'import\s+"github\.com/gerivdb/email-sender-1/cmd/gapanalyzer/gapanalyzer"'
$report = "cmd/gapanalyzer/import_fix_report.md"
$results = @()

Get-ChildItem -Path $root -Recurse -Include *.go | ForEach-Object {
   $file = $_.FullName
   $lines = Get-Content $file
   foreach ($i in 0..($lines.Count - 1)) {
      if ($lines[$i] -match $pattern) {
         $results += "$file : ligne $($i+1)"
      }
   }
}

if ($results.Count -gt 0) {
   $header = "# Rapport de détection des imports cycliques`n"
   $body = $results -join "`n"
   Set-Content -Path $report -Value ($header + $body)
   Write-Output "Imports cycliques détectés. Rapport généré dans $report"
}
else {
   Set-Content -Path $report -Value "# Aucun import cyclique détecté"
   Write-Output "Aucun import cyclique détecté."
}