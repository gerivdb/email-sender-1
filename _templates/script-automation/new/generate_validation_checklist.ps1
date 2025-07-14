# Génération de la checklist de validation croisée pour Gapanalyzer

$mdFile = "archive/gapanalyzer/checklist_validation.md"
$csvFile = "archive/gapanalyzer/checklist_validation.csv"

$checklist = @(
   "Vérification des tests Go",
   "Vérification du lint",
   "Audit de la structure",
   "Vérification des imports",
   "Backup effectué avant job critique",
   "Archivage des rapports (MD, CSV, PDF)",
   "Validation croisée par un second reviewer",
   "Feedback utilisateur collecté"
)

# Markdown
$mdContent = "# Checklist de validation croisée\n\n"
foreach ($item in $checklist) {
   $mdContent += "- [ ] $item`n"
}
Set-Content -Path $mdFile -Value $mdContent

# CSV
$csvContent = "Tâche,Statut`n"
foreach ($item in $checklist) {
   $csvContent += "$item,Non validé`n"
}
Set-Content -Path $csvFile -Value $csvContent

Write-Output "Checklist de validation générée dans $mdFile et $csvFile"