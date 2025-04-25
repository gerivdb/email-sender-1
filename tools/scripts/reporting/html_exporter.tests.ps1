<#
.SYNOPSIS
    Tests unitaires pour le module d'export HTML.
.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    du module html_exporter.ps1.
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin vers le module à tester
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "html_exporter.ps1"

# Créer des données de test
function New-TestTemplates {
    param (
        [string]$OutputPath
    )
    
    # Créer le répertoire de templates de test
    $TemplatesDir = Join-Path -Path $OutputPath -ChildPath "templates/reports/html"
    New-Item -Path $TemplatesDir -ItemType Directory -Force | Out-Null
    
    # Créer un template de base de test
    $BaseTemplatePath = Join-Path -Path $TemplatesDir -ChildPath "test_base_template.html"
    
    $BaseTemplate = @"
<!DOCTYPE html>
<html>
<head>
    <title>{{report_title}}</title>
</head>
<body>
    <h1>{{report_title}}</h1>
    <p>{{report_description}}</p>
    <p>Période: {{report_period_start}} - {{report_period_end}}</p>
    <p>Généré le: {{report_generated_at}}</p>
    
    <div class="toc">
        <h2>Table des matières</h2>
        <ul>
            {{toc_items}}
        </ul>
    </div>
    
    <div class="content">
        {{report_sections}}
    </div>
    
    <script>
        {{chart_initialization}}
    </script>
</body>
</html>
"@
    
    $BaseTemplate | Out-File -FilePath $BaseTemplatePath -Encoding UTF8
    
    # Créer un template de sections de test
    $SectionTemplatesPath = Join-Path -Path $TemplatesDir -ChildPath "test_section_templates.html"
    
    $SectionTemplates = @"
<!-- Template pour une section de texte -->
<section id="{{section_id}}">
    <h2>{{section_title}}</h2>
    <div>{{section_content}}</div>
</section>

<!-- Template pour une section de metrics_summary -->
<section id="{{section_id}}">
    <h2>{{section_title}}</h2>
    <div>{{metrics}}</div>
</section>

<!-- Template pour une section de chart -->
<section id="{{section_id}}">
    <h2>{{section_title}}</h2>
    <canvas id="chart-{{section_id}}"></canvas>
    <div>{{chart_description}}</div>
</section>

<!-- Template pour une section de table -->
<section id="{{section_id}}">
    <h2>{{section_title}}</h2>
    <table>
        <thead>
            <tr>{{columns}}</tr>
        </thead>
        <tbody>
            {{rows}}
        </tbody>
    </table>
</section>

<!-- Template pour une section de anomalies -->
<section id="{{section_id}}">
    <h2>{{section_title}}</h2>
    <ul>{{anomalies}}</ul>
</section>

<!-- Template pour une section de recommendations -->
<section id="{{section_id}}">
    <h2>{{section_title}}</h2>
    <ul>{{recommendations}}</ul>
</section>

<!-- Template pour un élément de la table des matières -->
<li><a href="#{{section_id}}">{{section_title}}</a></li>
"@
    
    $SectionTemplates | Out-File -FilePath $SectionTemplatesPath -Encoding UTF8
    
    return @{
        BaseTemplatePath = $BaseTemplatePath
        SectionTemplatesPath = $SectionTemplatesPath
    }
}

# Créer des données de rapport de test
function New-TestReportData {
    return @{
        id = "test_report"
        name = "Rapport de test"
        description = "Ceci est un rapport de test"
        type = "system"
        generated_at = "2025-04-23 10:00:00"
        period = @{
            start_date = "2025-04-22 00:00:00"
            end_date = "2025-04-22 23:59:59"
        }
        sections = @(
            @{
                id = "summary"
                title = "Résumé"
                type = "texte"
                content = "Ceci est un résumé du rapport de test."
            },
            @{
                id = "metrics"
                title = "Métriques clés"
                type = "metrics_summary"
                metrics = @(
                    @{
                        id = "cpu_avg"
                        name = "CPU moyen"
                        value = 45.2
                        formatted_value = "45.2%"
                        trend = 2.5
                    },
                    @{
                        id = "memory_max"
                        name = "Mémoire maximale"
                        value = 78.6
                        formatted_value = "78.6%"
                        trend = -1.3
                    }
                )
            },
            @{
                id = "cpu_chart"
                title = "Utilisation CPU"
                type = "chart"
                chart_type = "line"
                chart_data = @(
                    @{
                        name = "CPU"
                        data = @(
                            @{
                                x = "2025-04-22 00:00:00"
                                y = 42.5
                            },
                            @{
                                x = "2025-04-22 01:00:00"
                                y = 45.8
                            }
                        )
                    }
                )
                options = @{
                    title = "Utilisation CPU"
                    scales = @{
                        y = @{
                            beginAtZero = $true
                        }
                    }
                }
                chart_description = "Évolution de l'utilisation CPU sur la période."
            },
            @{
                id = "anomalies"
                title = "Anomalies détectées"
                type = "anomalies"
                anomalies = @(
                    @{
                        metric = "CPU"
                        description = "Pic d'utilisation CPU anormal"
                        datetime = "2025-04-22 15:30:00"
                    }
                )
            }
        )
    }
}

# Exécuter les tests
Describe "HTML Exporter Module Tests" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:TestDir = Join-Path -Path $TestDrive -ChildPath "html_exporter_tests"
        New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
        
        # Créer des templates de test
        $script:TestPaths = New-TestTemplates -OutputPath $script:TestDir
        
        # Importer le module à tester
        . $ModulePath
        
        # Redéfinir les chemins par défaut pour les tests
        $script:DefaultTemplatesPath = Join-Path -Path $script:TestDir -ChildPath "templates/reports/html"
        $script:BaseTemplatePath = $script:TestPaths.BaseTemplatePath
        $script:SectionTemplatesPath = $script:TestPaths.SectionTemplatesPath
    }
    
    Context "Get-HtmlTemplate function" {
        It "Should load a template correctly" {
            $Template = Get-HtmlTemplate -TemplatePath $script:TestPaths.BaseTemplatePath -TemplateKey "test_base"
            
            $Template | Should -Not -BeNullOrEmpty
            $Template | Should -BeLike "*{{report_title}}*"
        }
        
        It "Should use cache for repeated calls" {
            # Premier appel pour remplir le cache
            $Template1 = Get-HtmlTemplate -TemplatePath $script:TestPaths.BaseTemplatePath -TemplateKey "test_base_cache"
            
            # Deuxième appel qui devrait utiliser le cache
            $Template2 = Get-HtmlTemplate -TemplatePath $script:TestPaths.BaseTemplatePath -TemplateKey "test_base_cache"
            
            $Template1 | Should -Not -BeNullOrEmpty
            $Template2 | Should -Not -BeNullOrEmpty
            $Template1 | Should -BeExactly $Template2
        }
        
        It "Should force reload when specified" {
            # Premier appel pour remplir le cache
            $Template1 = Get-HtmlTemplate -TemplatePath $script:TestPaths.BaseTemplatePath -TemplateKey "test_base_force"
            
            # Modifier le fichier
            $ModifiedTemplate = "<!-- Modified template -->`n" + (Get-Content -Path $script:TestPaths.BaseTemplatePath -Raw)
            $ModifiedTemplate | Out-File -FilePath $script:TestPaths.BaseTemplatePath -Encoding UTF8
            
            # Deuxième appel avec ForceReload
            $Template2 = Get-HtmlTemplate -TemplatePath $script:TestPaths.BaseTemplatePath -TemplateKey "test_base_force" -ForceReload
            
            $Template1 | Should -Not -BeNullOrEmpty
            $Template2 | Should -Not -BeNullOrEmpty
            $Template1 | Should -Not -BeExactly $Template2
            $Template2 | Should -BeLike "<!-- Modified template -->*"
            
            # Restaurer le fichier original
            $Template1 | Out-File -FilePath $script:TestPaths.BaseTemplatePath -Encoding UTF8
        }
        
        It "Should return null for non-existent template file" {
            $Template = Get-HtmlTemplate -TemplatePath "non_existent_file.html" -TemplateKey "non_existent"
            
            $Template | Should -BeNullOrEmpty
        }
    }
    
    Context "Get-HtmlTemplateSection function" {
        It "Should extract a section correctly" {
            $SectionTemplates = Get-HtmlTemplate -TemplatePath $script:TestPaths.SectionTemplatesPath -TemplateKey "test_sections"
            $Section = Get-HtmlTemplateSection -TemplateContent $SectionTemplates -SectionName "texte"
            
            $Section | Should -Not -BeNullOrEmpty
            $Section | Should -BeLike "*<!-- Template pour une section de texte -->*"
            $Section | Should -BeLike "*{{section_id}}*"
            $Section | Should -BeLike "*{{section_title}}*"
            $Section | Should -BeLike "*{{section_content}}*"
        }
        
        It "Should return null for non-existent section" {
            $SectionTemplates = Get-HtmlTemplate -TemplatePath $script:TestPaths.SectionTemplatesPath -TemplateKey "test_sections"
            $Section = Get-HtmlTemplateSection -TemplateContent $SectionTemplates -SectionName "non_existent"
            
            $Section | Should -BeNullOrEmpty
        }
    }
    
    Context "Replace-HtmlTemplateVariables function" {
        It "Should replace variables correctly" {
            $Template = "<h1>{{title}}</h1><p>{{content}}</p>"
            $Variables = @{
                "title" = "Test Title"
                "content" = "Test Content"
            }
            
            $Result = Replace-HtmlTemplateVariables -TemplateContent $Template -Variables $Variables
            
            $Result | Should -Be "<h1>Test Title</h1><p>Test Content</p>"
        }
        
        It "Should handle missing variables" {
            $Template = "<h1>{{title}}</h1><p>{{content}}</p><span>{{missing}}</span>"
            $Variables = @{
                "title" = "Test Title"
                "content" = "Test Content"
            }
            
            $Result = Replace-HtmlTemplateVariables -TemplateContent $Template -Variables $Variables
            
            $Result | Should -Be "<h1>Test Title</h1><p>Test Content</p><span>{{missing}}</span>"
        }
    }
    
    Context "New-ChartInitializationScript function" {
        It "Should generate chart initialization script correctly" {
            $Charts = @(
                @{
                    id = "cpu_chart"
                    chart_type = "line"
                    chart_data = @(
                        @{
                            name = "CPU"
                            data = @(
                                @{
                                    x = "2025-04-22 00:00:00"
                                    y = 42.5
                                },
                                @{
                                    x = "2025-04-22 01:00:00"
                                    y = 45.8
                                }
                            )
                        }
                    )
                    options = @{
                        title = "Utilisation CPU"
                        scales = @{
                            y = @{
                                beginAtZero = $true
                            }
                        }
                    }
                }
            )
            
            $Script = New-ChartInitializationScript -Charts $Charts
            
            $Script | Should -Not -BeNullOrEmpty
            $Script | Should -BeLike "*// Initialisation du graphique cpu_chart*"
            $Script | Should -BeLike "*const ctx = document.getElementById('chart-cpu_chart').getContext('2d');*"
            $Script | Should -BeLike "*new Chart(ctx, {*"
            $Script | Should -BeLike "*type: 'line',*"
        }
    }
    
    Context "Export-ReportToHtml function" {
        It "Should export a report to HTML correctly" {
            $ReportData = New-TestReportData
            $OutputPath = Join-Path -Path $script:TestDir -ChildPath "output/test_report.html"
            
            $Result = Export-ReportToHtml -ReportData $ReportData -OutputPath $OutputPath -BaseTemplatePath $script:TestPaths.BaseTemplatePath -SectionTemplatesPath $script:TestPaths.SectionTemplatesPath
            
            $Result | Should -Be $true
            Test-Path -Path $OutputPath | Should -Be $true
            
            $Content = Get-Content -Path $OutputPath -Raw
            $Content | Should -Not -BeNullOrEmpty
            $Content | Should -BeLike "*Rapport de test*"
            $Content | Should -BeLike "*Ceci est un rapport de test*"
            $Content | Should -BeLike "*2025-04-22 00:00:00*"
            $Content | Should -BeLike "*2025-04-22 23:59:59*"
            $Content | Should -BeLike "*Résumé*"
            $Content | Should -BeLike "*Métriques clés*"
            $Content | Should -BeLike "*Utilisation CPU*"
            $Content | Should -BeLike "*Anomalies détectées*"
        }
    }
}

# Ne pas exécuter les tests automatiquement à la fin du script
# Pour exécuter les tests, utilisez la commande suivante :
# Invoke-Pester -Path .\html_exporter.tests.ps1 -Output Detailed
