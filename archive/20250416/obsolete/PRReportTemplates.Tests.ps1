#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module PRReportTemplates.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module PRReportTemplates
    en utilisant le framework Pester.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation recommandée: Install-Module -Name Pester -Force -SkipPublisherCheck"
}

# Chemin du module à tester
$moduleToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRReportTemplates.psm1"

# Vérifier que le module existe
if (-not (Test-Path -Path $moduleToTest)) {
    throw "Module PRReportTemplates non trouvé à l'emplacement: $moduleToTest"
}

# Importer le module à tester
Import-Module $moduleToTest -Force

# Tests Pester
Describe "PRReportTemplates Module Tests" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:testDir = Join-Path -Path $env:TEMP -ChildPath "PRReportTemplatesTests_$(Get-Random)"
        New-Item -Path $script:testDir -ItemType Directory -Force | Out-Null

        # Fonction pour créer des fichiers de test
        function New-TestFile {
            param(
                [string]$Path,
                [string]$Content
            )

            $fullPath = Join-Path -Path $script:testDir -ChildPath $Path
            $directory = Split-Path -Path $fullPath -Parent

            if (-not (Test-Path -Path $directory)) {
                New-Item -Path $directory -ItemType Directory -Force | Out-Null
            }

            Set-Content -Path $fullPath -Value $Content -Encoding UTF8
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

        $markdownTemplate = @'
# {{title}}

{{description}}

## Items

{{#each items}}
- **{{this.name}}**: {{this.value}}
{{/each}}
'@

        $jsonTemplate = @'
{
    "title": "{{title}}",
    "description": "{{description}}",
    "items": [
        {{#each items}}
        {
            "name": "{{this.name}}",
            "value": "{{this.value}}"
        }{{#unless @last}},{{/unless}}
        {{/each}}
    ]
}
'@

        # Créer les fichiers de template
        $script:testHtmlTemplate = New-TestFile -Path "templates\test.html" -Content $htmlTemplate
        $script:testMarkdownTemplate = New-TestFile -Path "templates\test.md" -Content $markdownTemplate
        $script:testJsonTemplate = New-TestFile -Path "templates\test.json" -Content $jsonTemplate

        # Créer des données de test
        $script:testData = [PSCustomObject]@{
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
    }

    Context "Register-PRReportTemplate" {
        It "Enregistre un template HTML" {
            # Enregistrer le template
            Register-PRReportTemplate -name "TestTemplate" -Format "HTML" -TemplatePath $script:testHtmlTemplate -Force

            # Vérifier l'enregistrement
            $template = Get-PRReportTemplate -name "TestTemplate" -Format "HTML"
            $template | Should -Not -BeNullOrEmpty
            $template.Name | Should -Be "TestTemplate"
            $template.Format | Should -Be "HTML"
            $template.Path | Should -Be $script:testHtmlTemplate
            $template.Content | Should -Not -BeNullOrEmpty
        }

        It "Enregistre un template Markdown" {
            # Enregistrer le template
            Register-PRReportTemplate -name "TestTemplate" -Format "Markdown" -TemplatePath $script:testMarkdownTemplate -Force

            # Vérifier l'enregistrement
            $template = Get-PRReportTemplate -name "TestTemplate" -Format "Markdown"
            $template | Should -Not -BeNullOrEmpty
            $template.Name | Should -Be "TestTemplate"
            $template.Format | Should -Be "Markdown"
            $template.Path | Should -Be $script:testMarkdownTemplate
            $template.Content | Should -Not -BeNullOrEmpty
        }

        It "Enregistre un template JSON" {
            # Enregistrer le template
            Register-PRReportTemplate -name "TestTemplate" -Format "JSON" -TemplatePath $script:testJsonTemplate -Force

            # Vérifier l'enregistrement
            $template = Get-PRReportTemplate -name "TestTemplate" -Format "JSON"
            $template | Should -Not -BeNullOrEmpty
            $template.Name | Should -Be "TestTemplate"
            $template.Format | Should -Be "JSON"
            $template.Path | Should -Be $script:testJsonTemplate
            $template.Content | Should -Not -BeNullOrEmpty
        }

        It "Échoue si le fichier template n'existe pas sans Force" {
            { Register-PRReportTemplate -name "InvalidTemplate" -Format "HTML" -TemplatePath "invalid_path.html" } | Should -Throw
        }

        It "Réussit si le fichier template n'existe pas avec Force" {
            { Register-PRReportTemplate -name "InvalidTemplate" -Format "HTML" -TemplatePath "invalid_path.html" -Force } | Should -Not -Throw
        }
    }

    Context "Get-PRReportTemplate" {
        BeforeEach {
            # Enregistrer les templates avant chaque test
            Register-PRReportTemplate -Name "TestTemplate" -Format "HTML" -TemplatePath $script:testHtmlTemplate -Force
            Register-PRReportTemplate -Name "TestTemplate" -Format "Markdown" -TemplatePath $script:testMarkdownTemplate -Force
            Register-PRReportTemplate -Name "TestTemplate" -Format "JSON" -TemplatePath $script:testJsonTemplate -Force
        }

        It "Récupère un template enregistré" {
            $template = Get-PRReportTemplate -name "TestTemplate" -Format "HTML"
            $template | Should -Not -BeNullOrEmpty
            $template.Name | Should -Be "TestTemplate"
            $template.Format | Should -Be "HTML"
        }

        It "Échoue si le template n'existe pas" {
            { Get-PRReportTemplate -name "NonExistentTemplate" -Format "HTML" } | Should -Throw
        }
    }

    Context "New-PRReport" {
        BeforeEach {
            # Enregistrer les templates avant chaque test
            Register-PRReportTemplate -Name "TestTemplate" -Format "HTML" -TemplatePath $script:testHtmlTemplate -Force
            Register-PRReportTemplate -Name "TestTemplate" -Format "Markdown" -TemplatePath $script:testMarkdownTemplate -Force
            Register-PRReportTemplate -Name "TestTemplate" -Format "JSON" -TemplatePath $script:testJsonTemplate -Force
        }

        It "Génère un rapport HTML" {
            $outputPath = Join-Path -Path $script:testDir -ChildPath "output\test_report.html"
            $report = New-PRReport -TemplateName "TestTemplate" -Format "HTML" -Data $script:testData -OutputPath $outputPath

            $report | Should -Not -BeNullOrEmpty

            # Vérifier que le rapport existe
            Test-Path -Path $outputPath | Should -Be $true

            # Lire le contenu du fichier pour vérification
            $fileContent = Get-Content -Path $outputPath -Raw
            $fileContent | Should -Not -BeNullOrEmpty

            # Vérifier que les variables ont été remplacées
            $fileContent | Should -BeLike "*<title>Test Report</title>*"
            $fileContent | Should -BeLike "*<h1>Test Report</h1>*"
            $fileContent | Should -BeLike "*<p>This is a test report</p>*"
            $fileContent | Should -BeLike "*<li>Item 1: Value 1</li>*"
            $fileContent | Should -BeLike "*<li>Item 2: Value 2</li>*"
        }

        It "Génère un rapport Markdown" {
            $outputPath = Join-Path -Path $script:testDir -ChildPath "output\test_report.md"
            $report = New-PRReport -TemplateName "TestTemplate" -Format "Markdown" -Data $script:testData -OutputPath $outputPath

            $report | Should -Not -BeNullOrEmpty

            # Vérifier que le rapport existe
            Test-Path -Path $outputPath | Should -Be $true

            # Lire le contenu du fichier pour vérification
            $fileContent = Get-Content -Path $outputPath -Raw
            $fileContent | Should -Not -BeNullOrEmpty

            # Vérifier que les variables ont été remplacées
            $fileContent | Should -BeLike "# Test Report*"
            $fileContent | Should -BeLike "*This is a test report*"
            $fileContent | Should -BeLike "*- **Item 1**: Value 1*"
            $fileContent | Should -BeLike "*- **Item 2**: Value 2*"
        }

        It "Génère un rapport JSON" {
            $outputPath = Join-Path -Path $script:testDir -ChildPath "output\test_report.json"
            $report = New-PRReport -TemplateName "TestTemplate" -Format "JSON" -Data $script:testData -OutputPath $outputPath

            $report | Should -Not -BeNullOrEmpty

            # Vérifier que le rapport existe
            Test-Path -Path $outputPath | Should -Be $true

            # Lire le contenu du fichier pour vérification
            $fileContent = Get-Content -Path $outputPath -Raw
            $fileContent | Should -Not -BeNullOrEmpty

            # Vérifier que les variables ont été remplacées
            $fileContent | Should -BeLike '*"title": "Test Report"*'
            $fileContent | Should -BeLike '*"description": "This is a test report"*'
            $fileContent | Should -BeLike '*"name": "Item 1"*'
            $fileContent | Should -BeLike '*"value": "Value 1"*'
        }
    }

    Context "Import-PRReportTemplates" {
        It "Importe tous les templates d'un répertoire" {
            # Créer un répertoire de templates de test
            $templatesDir = Join-Path -Path $script:testDir -ChildPath "templates"

            # Importer les templates
            Import-PRReportTemplates -TemplatesDirectory $templatesDir

            # Vérifier que les templates ont été importés
            $htmlTemplate = Get-PRReportTemplate -name "test" -Format "HTML"
            $htmlTemplate | Should -Not -BeNullOrEmpty

            $markdownTemplate = Get-PRReportTemplate -name "test" -Format "Markdown"
            $markdownTemplate | Should -Not -BeNullOrEmpty

            $jsonTemplate = Get-PRReportTemplate -name "test" -Format "JSON"
            $jsonTemplate | Should -Not -BeNullOrEmpty
        }

        It "Échoue si le répertoire n'existe pas" {
            { Import-PRReportTemplates -TemplatesDirectory "invalid_directory" } | Should -Throw
        }
    }

    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $script:testDir) {
            Remove-Item -Path $script:testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Note: Ne pas exécuter les tests directement ici pour éviter une récursion infinie
# Utilisez plutôt: Invoke-Pester -Path $PSCommandPath
