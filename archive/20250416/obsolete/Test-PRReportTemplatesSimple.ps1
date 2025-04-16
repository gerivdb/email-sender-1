#Requires -Version 5.1
<#
.SYNOPSIS
    Test simplifié pour le module PRReportTemplates.
.DESCRIPTION
    Ce script teste la fonction New-PRReport du module PRReportTemplates.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

# Chemin du module à tester
$moduleToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRReportTemplates.psm1"

# Vérifier que le module existe
if (-not (Test-Path -Path $moduleToTest)) {
    throw "Module PRReportTemplates non trouvé à l'emplacement: $moduleToTest"
}

# Importer le module à tester
Import-Module $moduleToTest -Force

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PRReportTemplatesSimple_$(Get-Random)"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
Write-Host "Répertoire de test créé: $testDir"

# Créer un template HTML
$htmlTemplate = @'
<!DOCTYPE html>
<html>
<head>
    <title>{{title}}</title>
</head>
<body>
    <h1>{{title}}</h1>
    <p>{{description}}</p>

    <ul>
        {{#each items}}
        <li>{{this.name}}: {{this.value}}</li>
        {{/each}}
    </ul>
</body>
</html>
'@

# Créer le fichier de template
$templatePath = Join-Path -Path $testDir -ChildPath "template.html"
Set-Content -Path $templatePath -Value $htmlTemplate -Encoding UTF8
Write-Host "Template créé: $templatePath"

# Enregistrer le template
Register-PRReportTemplate -Name "TestTemplate" -Format "HTML" -TemplatePath $templatePath -Force
Write-Host "Template enregistré"

# Créer des données de test
$testData = [PSCustomObject]@{
    title       = "Test Report"
    description = "This is a test report"
    items       = @(
        [PSCustomObject]@{
            name  = "Item 1"
            value = "Value 1"
        },
        [PSCustomObject]@{
            name  = "Item 2"
            value = "Value 2"
        }
    )
}

# Générer un rapport
$outputPath = Join-Path -Path $testDir -ChildPath "report.html"
New-PRReport -TemplateName "TestTemplate" -Format "HTML" -Data $testData -OutputPath $outputPath | Out-Null
Write-Host "Rapport généré"

# Afficher le rapport
Write-Host "Contenu du rapport:"
Write-Host "-------------------"
Get-Content -Path $outputPath -Raw
Write-Host "-------------------"

# Vérifier si les variables ont été remplacées
$reportContent = Get-Content -Path $outputPath -Raw
$success = $true

if ($reportContent -notlike "*<title>Test Report</title>*") {
    Write-Host "ERREUR: Le titre n'a pas été remplacé" -ForegroundColor Red
    $success = $false
}

if ($reportContent -notlike "*<h1>Test Report</h1>*") {
    Write-Host "ERREUR: Le titre H1 n'a pas été remplacé" -ForegroundColor Red
    $success = $false
}

if ($reportContent -notlike "*<p>This is a test report</p>*") {
    Write-Host "ERREUR: La description n'a pas été remplacée" -ForegroundColor Red
    $success = $false
}

if ($reportContent -notlike "*<li>Item 1: Value 1</li>*") {
    Write-Host "ERREUR: L'item 1 n'a pas été remplacé" -ForegroundColor Red
    $success = $false
}

if ($reportContent -notlike "*<li>Item 2: Value 2</li>*") {
    Write-Host "ERREUR: L'item 2 n'a pas été remplacé" -ForegroundColor Red
    $success = $false
}

if ($success) {
    Write-Host "SUCCÈS: Toutes les variables ont été correctement remplacées" -ForegroundColor Green
} else {
    Write-Host "ÉCHEC: Certaines variables n'ont pas été remplacées" -ForegroundColor Red
}

# Nettoyer les fichiers de test
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Répertoire de test supprimé: $testDir"
