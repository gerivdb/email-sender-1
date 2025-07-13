# Script PowerShell pour corriger l'encodage et les fins de ligne des fichiers .ps1
# Génère un rapport dans ACTIONS_XXX_IMPLEMENTATION_REPORT.md

$root = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$report = Join-Path $root 'ACTIONS_XXX_IMPLEMENTATION_REPORT.md'
$ps1Files = Get-ChildItem -Path $root -Recurse -Filter *.ps1

Add-Content -Path $report -Value "# Rapport de correction d'encodage PowerShell - $(Get-Date)"

foreach ($file in $ps1Files) {
   $original = Get-Content $file.FullName -Raw
   $utf8Path = $file.FullName + ".utf8tmp"
   # Convertit en UTF-8 sans BOM
   [System.IO.File]::WriteAllText($utf8Path, $original, (New-Object System.Text.UTF8Encoding($false)))
   # Remplace les fins de ligne par CRLF
   $fixed = (Get-Content $utf8Path -Raw) -replace "(?<!\r)\n", "`r`n"
   Set-Content -Path $file.FullName -Value $fixed -Encoding UTF8
   Remove-Item $utf8Path
   Add-Content -Path $report -Value "- $($file.FullName) corrigé en UTF-8 (sans BOM) et CRLF."
}

Add-Content -Path $report -Value "\n## Fin du rapport."
Write-Host "Correction terminée. Rapport généré dans $report"
