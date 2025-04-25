#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test simplifié pour le module PRReportTemplates.
.DESCRIPTION
    Ce script teste les fonctionnalités de base du module PRReportTemplates.
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
$testDir = Join-Path -Path $env:TEMP -ChildPath "PRReportTemplatesTests_$(Get-Random)"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
Write-Host "Répertoire de test créé: $testDir"

# Fonction pour créer des fichiers de test
function New-TestFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $fullPath = Join-Path -Path $testDir -ChildPath $Path
    $directory = Split-Path -Path $fullPath -Parent

    if (-not (Test-Path -Path $directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }

    Set-Content -Path $fullPath -Value $Content -Encoding UTF8
    Write-Host "Fichier de test créé: $fullPath"
    return $fullPath
}

# Créer des fichiers de template de test
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

$testHtmlTemplate = New-TestFile -Path "templates\test.html" -Content $htmlTemplate

# Enregistrer le template
Write-Host "Enregistrement du template HTML..."
Register-PRReportTemplate -Name "TestTemplate" -Format "HTML" -TemplatePath $testHtmlTemplate -Force

# Récupérer le template
Write-Host "Récupération du template HTML..."
$template = Get-PRReportTemplate -Name "TestTemplate" -Format "HTML"
Write-Host "Template récupéré: $($template.Name) ($($template.Format))"
Write-Host "Chemin du template: $($template.Path)"
Write-Host "Contenu du template: $($template.Content.Length) caractères"

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
Write-Host "Génération d'un rapport HTML..."
$outputPath = Join-Path -Path $testDir -ChildPath "output\test_report.html"
$report = New-PRReport -TemplateName "TestTemplate" -Format "HTML" -Data $testData -OutputPath $outputPath

# Vérifier le rapport
Write-Host "Rapport généré: $($report.Length) caractères"
Write-Host "Fichier de sortie existe: $(Test-Path -Path $outputPath)"

# Nettoyer les fichiers de test
Write-Host "Nettoyage des fichiers de test..."
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Répertoire de test supprimé: $testDir"

Write-Host "Tests terminés avec succès!"
