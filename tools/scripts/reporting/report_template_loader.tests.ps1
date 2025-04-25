<#
.SYNOPSIS
    Tests unitaires pour le module de chargement des templates de rapports.
.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    du module report_template_loader.ps1.
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin vers le module à tester
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "report_template_loader.ps1"

# Créer des données de test
function New-TestTemplates {
    param (
        [string]$OutputPath
    )

    # Créer le répertoire de templates de test
    $TemplatesDir = Join-Path -Path $OutputPath -ChildPath "templates/reports"
    New-Item -Path $TemplatesDir -ItemType Directory -Force | Out-Null

    # Créer un fichier JSON de templates de test
    $JsonPath = Join-Path -Path $TemplatesDir -ChildPath "test_templates.json"

    $Templates = @{
        templates = @(
            @{
                id          = "test_system_report"
                name        = "Test System Report"
                description = "Test report for system metrics"
                type        = "system"
                format      = "html"
                sections    = @(
                    @{
                        id      = "summary"
                        title   = "Summary"
                        type    = "text"
                        content = "This is a test report."
                    },
                    @{
                        id      = "metrics"
                        title   = "Key Metrics"
                        type    = "metrics_summary"
                        metrics = @(
                            @{
                                id       = "cpu_avg"
                                name     = "CPU Average"
                                metric   = "CPU"
                                function = "avg"
                                format   = "{value}%"
                            },
                            @{
                                id       = "memory_max"
                                name     = "Memory Maximum"
                                metric   = "Memory"
                                function = "max"
                                format   = "{value}%"
                            }
                        )
                    },
                    @{
                        id         = "cpu_chart"
                        title      = "CPU Usage"
                        type       = "chart"
                        chart_type = "line"
                        metric     = "CPU"
                        options    = @{
                            title            = "CPU Usage"
                            x_axis_label     = "Time"
                            y_axis_label     = "Usage (%)"
                            include_avg_line = $true
                        }
                    }
                )
            },
            @{
                id          = "test_application_report"
                name        = "Test Application Report"
                description = "Test report for application metrics"
                type        = "application"
                format      = "pdf"
                sections    = @(
                    @{
                        id      = "summary"
                        title   = "Summary"
                        type    = "text"
                        content = "This is a test application report."
                    },
                    @{
                        id         = "response_time"
                        title      = "Response Time"
                        type       = "chart"
                        chart_type = "line"
                        metric     = "ResponseTime"
                        options    = @{
                            title        = "Response Time"
                            x_axis_label = "Time"
                            y_axis_label = "Response Time (ms)"
                        }
                    },
                    @{
                        id            = "anomalies"
                        title         = "Anomalies"
                        type          = "anomalies"
                        metrics       = @("ResponseTime", "ErrorRate")
                        threshold     = 2.0
                        max_anomalies = 5
                    }
                )
            }
        )
    }

    $Templates | ConvertTo-Json -Depth 100 | Out-File -FilePath $JsonPath -Encoding UTF8

    # Créer un fichier JSON de template invalide
    $InvalidJsonPath = Join-Path -Path $TemplatesDir -ChildPath "invalid_templates.json"

    $InvalidTemplates = @{
        templates = @(
            @{
                id          = "invalid_template"
                name        = "Invalid Template"
                description = "This template is missing required fields"
                type        = "unknown"
                format      = "html"
                sections    = @(
                    @{
                        id    = "invalid_section"
                        title = "Invalid Section"
                        type  = "unknown"
                    }
                )
            }
        )
    }

    $InvalidTemplates | ConvertTo-Json -Depth 100 | Out-File -FilePath $InvalidJsonPath -Encoding UTF8

    # Créer le répertoire pour le schéma
    $SchemaDir = Join-Path -Path $OutputPath -ChildPath "docs/reporting"
    New-Item -Path $SchemaDir -ItemType Directory -Force | Out-Null

    # Copier le schéma existant ou créer un schéma minimal
    $SchemaPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\docs\reporting\report_schema.json"
    $TestSchemaPath = Join-Path -Path $SchemaDir -ChildPath "report_schema.json"

    if (Test-Path -Path $SchemaPath) {
        Copy-Item -Path $SchemaPath -Destination $TestSchemaPath
    } else {
        $Schema = @{
            "$schema"   = "http://json-schema.org/draft-07/schema#"
            title       = "Report Template Schema"
            description = "Schema for defining report templates"
            type        = "object"
        }

        $Schema | ConvertTo-Json -Depth 100 | Out-File -FilePath $TestSchemaPath -Encoding UTF8
    }

    return @{
        TemplatesPath        = $JsonPath
        InvalidTemplatesPath = $InvalidJsonPath
        SchemaPath           = $TestSchemaPath
    }
}

# Exécuter les tests
Describe "Report Template Loader Module Tests" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:TestDir = Join-Path -Path $TestDrive -ChildPath "template_loader_tests"
        New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null

        # Créer des templates de test
        $script:TestPaths = New-TestTemplates -OutputPath $script:TestDir

        # Importer le module à tester
        . $ModulePath

        # Redéfinir les chemins par défaut pour les tests
        $script:DefaultTemplatesPath = $script:TestPaths.TemplatesPath
        $script:DefaultSchemaPath = $script:TestPaths.SchemaPath
    }

    Context "Import-ReportTemplates function" {
        It "Should import templates correctly" {
            $Templates = Import-ReportTemplates -TemplatesPath $script:TestPaths.TemplatesPath

            $Templates | Should -Not -BeNullOrEmpty
            $Templates.Count | Should -Be 2
            $Templates[0].id | Should -Be "test_system_report"
            $Templates[1].id | Should -Be "test_application_report"
        }

        It "Should use cache for repeated calls" {
            # Premier appel pour remplir le cache
            $Templates1 = Import-ReportTemplates -TemplatesPath $script:TestPaths.TemplatesPath

            # Deuxième appel qui devrait utiliser le cache
            $Templates2 = Import-ReportTemplates -TemplatesPath $script:TestPaths.TemplatesPath

            $Templates1 | Should -Not -BeNullOrEmpty
            $Templates2 | Should -Not -BeNullOrEmpty
            $Templates1.Count | Should -Be $Templates2.Count

            # Vérifier que les objets sont les mêmes (référence)
            [System.Object]::ReferenceEquals($Templates1, $Templates2) | Should -Be $true
        }

        It "Should force reload when specified" {
            # Premier appel pour remplir le cache
            $Templates1 = Import-ReportTemplates -TemplatesPath $script:TestPaths.TemplatesPath

            # Deuxième appel avec ForceReload
            $Templates2 = Import-ReportTemplates -TemplatesPath $script:TestPaths.TemplatesPath -ForceReload

            $Templates1 | Should -Not -BeNullOrEmpty
            $Templates2 | Should -Not -BeNullOrEmpty
            $Templates1.Count | Should -Be $Templates2.Count

            # Vérifier que les objets sont différents (référence)
            [System.Object]::ReferenceEquals($Templates1, $Templates2) | Should -Be $false
        }

        It "Should return null for non-existent template file" {
            $Templates = Import-ReportTemplates -TemplatesPath "non_existent_file.json"

            $Templates | Should -BeNullOrEmpty
        }
    }

    Context "Test-ReportTemplate function" {
        It "Should validate a correct template" {
            $Templates = Import-ReportTemplates -TemplatesPath $script:TestPaths.TemplatesPath
            $Template = $Templates[0]

            $IsValid = Test-ReportTemplate -Template $Template -SchemaPath $script:TestPaths.SchemaPath

            $IsValid | Should -Be $true
        }

        It "Should reject an invalid template" {
            $InvalidTemplates = Import-ReportTemplates -TemplatesPath $script:TestPaths.InvalidTemplatesPath
            $InvalidTemplate = $InvalidTemplates[0]

            $IsValid = Test-ReportTemplate -Template $InvalidTemplate -SchemaPath $script:TestPaths.SchemaPath

            $IsValid | Should -Be $false
        }

        It "Should validate required fields" {
            $Templates = Import-ReportTemplates -TemplatesPath $script:TestPaths.TemplatesPath
            $Template = $Templates[0]

            # Créer une copie du template et supprimer un champ obligatoire
            $InvalidTemplate = $Template | ConvertTo-Json -Depth 100 | ConvertFrom-Json
            $InvalidTemplate.PSObject.Properties.Remove("description")

            $IsValid = Test-ReportTemplate -Template $InvalidTemplate -SchemaPath $script:TestPaths.SchemaPath

            $IsValid | Should -Be $false
        }

        It "Should validate section types" {
            $Templates = Import-ReportTemplates -TemplatesPath $script:TestPaths.TemplatesPath
            $Template = $Templates[0]

            # Créer une copie du template et modifier un type de section
            $InvalidTemplate = $Template | ConvertTo-Json -Depth 100 | ConvertFrom-Json
            $InvalidTemplate.sections[0].type = "invalid_type"

            $IsValid = Test-ReportTemplate -Template $InvalidTemplate -SchemaPath $script:TestPaths.SchemaPath

            $IsValid | Should -Be $false
        }
    }

    Context "Get-ReportTemplate function" {
        It "Should retrieve a template by ID" {
            $Template = Get-ReportTemplate -TemplateId "test_system_report" -TemplatesPath $script:TestPaths.TemplatesPath

            $Template | Should -Not -BeNullOrEmpty
            $Template.id | Should -Be "test_system_report"
            $Template.type | Should -Be "system"
        }

        It "Should return null for non-existent template ID" {
            $Template = Get-ReportTemplate -TemplateId "non_existent_id" -TemplatesPath $script:TestPaths.TemplatesPath

            $Template | Should -BeNullOrEmpty
        }

        It "Should validate the template before returning it" {
            # Mock Test-ReportTemplate to always return false
            Mock Test-ReportTemplate { return $false }

            $Template = Get-ReportTemplate -TemplateId "test_system_report" -TemplatesPath $script:TestPaths.TemplatesPath

            $Template | Should -BeNullOrEmpty

            # Restore original function
            Remove-Item function:Test-ReportTemplate
            . $ModulePath
        }
    }

    Context "Get-ReportTemplatesList function" {
        It "Should list all templates" {
            $TemplatesList = Get-ReportTemplatesList -TemplatesPath $script:TestPaths.TemplatesPath

            $TemplatesList | Should -Not -BeNullOrEmpty
            $TemplatesList.Count | Should -Be 2
            $TemplatesList[0].Id | Should -Be "test_system_report"
            $TemplatesList[1].Id | Should -Be "test_application_report"
        }

        It "Should filter templates by type" {
            $TemplatesList = Get-ReportTemplatesList -TemplatesPath $script:TestPaths.TemplatesPath -Type "system"

            $TemplatesList | Should -Not -BeNullOrEmpty
            $TemplatesList.Count | Should -Be 1
            $TemplatesList[0].Id | Should -Be "test_system_report"
            $TemplatesList[0].Type | Should -Be "system"
        }

        It "Should return simplified template information" {
            $TemplatesList = Get-ReportTemplatesList -TemplatesPath $script:TestPaths.TemplatesPath

            $TemplatesList[0].PSObject.Properties.Name | Should -Contain "Id"
            $TemplatesList[0].PSObject.Properties.Name | Should -Contain "Name"
            $TemplatesList[0].PSObject.Properties.Name | Should -Contain "Description"
            $TemplatesList[0].PSObject.Properties.Name | Should -Contain "Type"
            $TemplatesList[0].PSObject.Properties.Name | Should -Contain "Format"
            $TemplatesList[0].PSObject.Properties.Name | Should -Contain "SectionsCount"

            $TemplatesList[0].SectionsCount | Should -Be 3
        }
    }
}

# Ne pas exécuter les tests automatiquement à la fin du script
# Pour exécuter les tests, utilisez la commande suivante :
# Invoke-Pester -Path .\report_template_loader.tests.ps1 -Output Detailed
