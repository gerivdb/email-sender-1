# Génération du formulaire de feedback utilisateur pour Gapanalyzer

$mdFile = "archive/gapanalyzer/feedback_form.md"
$csvFile = "archive/gapanalyzer/feedback_form.csv"

$questions = @(
   "Le rapport généré est-il clair et complet ?",
   "Les corrections proposées sont-elles pertinentes ?",
   "La procédure d’archivage est-elle conforme ?",
   "Des points d’amélioration à signaler ?"
)

# Markdown
$mdContent = "# Formulaire de feedback utilisateur\n\n"
foreach ($q in $questions) {
   $mdContent += "- [ ] $q`n"
}
Set-Content -Path $mdFile -Value $mdContent

# CSV
$csvContent = "Question,Réponse`n"
foreach ($q in $questions) {
   $csvContent += "$q,`n"
}
Set-Content -Path $csvFile -Value $csvContent

Write-Output "Formulaire de feedback généré dans $mdFile et $csvFile"