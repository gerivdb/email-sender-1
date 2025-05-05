﻿<#
.SYNOPSIS
    Tests unitaires pour le module d'export PDF.
.DESCRIPTION
    Ce script contient des tests unitaires pour vÃƒÂ©rifier le bon fonctionnement
    du module pdf_exporter.ps1.
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Le module Pester n'est pas installÃƒÂ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin vers le module ÃƒÂ  tester
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "pdf_exporter.ps1"

# CrÃƒÂ©er des donnÃƒÂ©es de test
function New-TestPdfOptions {
    param (
        [string]$OutputPath
    )
    
    # CrÃƒÂ©er le rÃƒÂ©pertoire de configuration de test
    $ConfigDir = Join-Path -Path $OutputPath -ChildPath "projet/config/reporting"
    New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null
    
    # CrÃƒÂ©er un fichier d'options PDF de test
    $OptionsPath = Join-Path -Path $ConfigDir -ChildPath "test_pdf_options.json"
    
    $Options = @{
        global = @{
            margin_top = "20mm"
            margin_bottom = "20mm"
            margin_left = "20mm"
            margin_right = "20mm"
            page_size = "A4"
            orientation = "Portrait"
            dpi = 300
            image_quality = 100
            enable_javascript = $true
            javascript_delay = 1000
        }
        toc = @{
            enable = $true
            header_text = "Table des matiÃƒÂ¨res"
            level_indentation = 10
            disable_dotted_lines = $false
            disable_links = $false
        }
        outline = @{
            enable = $true
            depth = 3
        }
        header = @{
            enable = $true
            html = "<div style='text-align: right; font-size: 10px; color: #777;'>Page [page] sur [topage]</div>"
            spacing = "5mm"
        }
        footer = @{
            enable = $true
            html = "<div style='text-align: center; font-size: 10px; color: #777;'>Rapport gÃƒÂ©nÃƒÂ©rÃƒÂ© le [date] ÃƒÂ  [time]</div>"
            spacing = "5mm"
        }
    }
    
    $Options | ConvertTo-Json -Depth 10 | Out-File -FilePath $OptionsPath -Encoding UTF8
    
    return $OptionsPath
}

# CrÃƒÂ©er des donnÃƒÂ©es de rapport de test
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
                title = "RÃƒÂ©sumÃƒÂ©"
                type = "texte"
                content = "Ceci est un rÃƒÂ©sumÃƒÂ© du rapport de test."
            },
            @{
                id = "metrics"
                title = "MÃƒÂ©triques clÃƒÂ©s"
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
                        name = "MÃƒÂ©moire maximale"
                        value = 78.6
                        formatted_value = "78.6%"
                        trend = -1.3
                    }
                )
            }
        )
    }
}

# ExÃƒÂ©cuter les tests
Describe "PDF Exporter Module Tests" {
    BeforeAll {
        # CrÃƒÂ©er un rÃƒÂ©pertoire temporaire pour les tests
        $script:TestDir = Join-Path -Path $TestDrive -ChildPath "pdf_exporter_tests"
        New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
        
        # CrÃƒÂ©er des options PDF de test
        $script:TestOptionsPath = New-TestPdfOptions -OutputPath $script:TestDir
        
        # Importer le module ÃƒÂ  tester
        . $ModulePath
        
        # RedÃƒÂ©finir les chemins par dÃƒÂ©faut pour les tests
        $script:DefaultPdfOptionsPath = $script:TestOptionsPath
    }
    
    Context "Get-PdfOptions function" {
        It "Should load PDF options correctly" {
            $Options = Get-PdfOptions -OptionsPath $script:TestOptionsPath
            
            $Options | Should -Not -BeNullOrEmpty
            $Options.global | Should -Not -BeNullOrEmpty
            $Options.global.page_size | Should -Be "A4"
            $Options.global.orientation | Should -Be "Portrait"
            $Options.toc | Should -Not -BeNullOrEmpty
            $Options.toc.enable | Should -Be $true
            $Options.outline | Should -Not -BeNullOrEmpty
            $Options.outline.enable | Should -Be $true
        }
        
        It "Should return default options for non-existent file" {
            $Options = Get-PdfOptions -OptionsPath "non_existent_file.json"
            
            $Options | Should -Not -BeNullOrEmpty
            $Options.global | Should -Not -BeNullOrEmpty
            $Options.global.page_size | Should -Be "A4"
            $Options.global.orientation | Should -Be "Portrait"
        }
    }
    
    Context "ConvertTo-WkhtmltopdfArguments function" {
        It "Should convert PDF options to wkhtmltopdf arguments correctly" {
            $Options = Get-PdfOptions -OptionsPath $script:TestOptionsPath
            $Arguments = ConvertTo-WkhtmltopdfArguments -Options $Options
            
            $Arguments | Should -Not -BeNullOrEmpty
            $Arguments | Should -Contain "--margin-top"
            $Arguments | Should -Contain "20mm"
            $Arguments | Should -Contain "--page-size"
            $Arguments | Should -Contain "A4"
            $Arguments | Should -Contain "--orientation"
            $Arguments | Should -Contain "Portrait"
            $Arguments | Should -Contain "--enable-javascript"
            $Arguments | Should -Contain "toc"
            $Arguments | Should -Contain "--toc-header-text"
            $Arguments | Should -Contain "--outline"
        }
        
        It "Should handle minimal options" {
            $MinimalOptions = @{
                global = @{
                    page_size = "A4"
                    orientation = "Portrait"
                }
            }
            
            $Arguments = ConvertTo-WkhtmltopdfArguments -Options $MinimalOptions
            
            $Arguments | Should -Not -BeNullOrEmpty
            $Arguments | Should -Contain "--page-size"
            $Arguments | Should -Contain "A4"
            $Arguments | Should -Contain "--orientation"
            $Arguments | Should -Contain "Portrait"
        }
    }
    
    Context "Test-WkhtmltopdfInstallation function" {
        It "Should detect wkhtmltopdf installation" {
            # Mock the Test-Path and Start-Process functions
            Mock Test-Path { return $true }
            Mock Start-Process { 
                $Global:LASTEXITCODE = 0
                return "wkhtmltopdf 0.12.6"
            }
            
            $Result = Test-WkhtmltopdfInstallation
            
            $Result | Should -Be $true
            
            # Restore original functions
            Remove-Item function:Test-Path
            Remove-Item function:Start-Process
        }
        
        It "Should detect missing wkhtmltopdf" {
            # Mock the Test-Path function
            Mock Test-Path { return $false }
            
            $Result = Test-WkhtmltopdfInstallation
            
            $Result | Should -Be $false
            
            # Restore original function
            Remove-Item function:Test-Path
        }
        
        It "Should detect non-functional wkhtmltopdf" {
            # Mock the Test-Path and Start-Process functions
            Mock Test-Path { return $true }
            Mock Start-Process { 
                $Global:LASTEXITCODE = 1
                return "Error: wkhtmltopdf not found"
            }
            
            $Result = Test-WkhtmltopdfInstallation
            
            $Result | Should -Be $false
            
            # Restore original functions
            Remove-Item function:Test-Path
            Remove-Item function:Start-Process
        }
    }
    
    Context "Export-ReportToPdf function" {
        It "Should export a report to PDF" -Skip {
            # This test is skipped because it requires wkhtmltopdf to be installed
            # and would actually generate a PDF file
            
            $ReportData = New-TestReportData
            $OutputPath = Join-Path -Path $script:TestDir -ChildPath "output/test_report.pdf"
            
            # Mock the necessary functions
            Mock Test-WkhtmltopdfInstallation { return $true }
            Mock Export-ReportToHtml { return $true }
            Mock Start-Process { 
                $Global:LASTEXITCODE = 0
                return [PSCustomObject]@{
                    ExitCode = 0
                }
            }
            
            $Result = Export-ReportToPdf -ReportData $ReportData -OutputPath $OutputPath -OptionsPath $script:TestOptionsPath
            
            $Result | Should -Be $true
            
            # Restore original functions
            Remove-Item function:Test-WkhtmltopdfInstallation
            Remove-Item function:Export-ReportToHtml
            Remove-Item function:Start-Process
        }
    }
}

# Ne pas exÃƒÂ©cuter les tests automatiquement ÃƒÂ  la fin du script
# Pour exÃƒÂ©cuter les tests, utilisez la commande suivante :
# Invoke-Pester -Path .\pdf_exporter.tests.ps1 -Output Detailed
