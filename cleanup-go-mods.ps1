# Nettoyage automatique des fichiers go.mod et go.work parasites toutes les heures (PowerShell)
# À lancer en administrateur ou en tâche de fond

while ($true) {
   Write-Host "Nettoyage automatique des fichiers go.mod et go.work parasites - $(Get-Date)"
   $rootMod = Resolve-Path .\go.mod
   Get-ChildItem -Path . -Recurse -Include go.mod, go.work | Where-Object { $_.FullName -ne $rootMod } | ForEach-Object {
      Write-Host "Suppression de $($_.FullName)"
      Remove-Item $_.FullName -Force
   }
   Start-Sleep -Seconds 3600
}
