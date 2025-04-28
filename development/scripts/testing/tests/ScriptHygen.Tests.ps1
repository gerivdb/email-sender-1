#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour les templates Hygen scripts.

.DESCRIPTION
    Ce script contient des tests unitaires pour les templates Hygen scripts.
    Il vÃ©rifie que les templates sont correctement installÃ©s et fonctionnent comme prÃ©vu.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
    Date de crÃ©ation: 2023-05-15
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}
Import-Module -Name Pester -Force

# Obtenir le chemin du projet
function Get-ProjectPath {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.FullName
    return $projectRoot
}

# CrÃ©er un dossier temporaire pour les tests
function New-TempFolder {
    $tempFolder = Join-Path -Path $env:TEMP -ChildPath "ScriptHygenTests-$(Get-Random)"
    New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null
    return $tempFolder
}

# Supprimer un dossier temporaire
function Remove-TempFolder {
    param (
        [Parameter(Mandatory=$true)]
        [string]$TempFolder
    )
    
    if (Test-Path -Path $TempFolder) {
        Remove-Item -Path $TempFolder -Recurse -Force
    }
}

Describe "ScriptHygen" {
    BeforeAll {
        $projectRoot = Get-ProjectPath
        $templatesRoot = Join-Path -Path $projectRoot -ChildPath "development/scripts/development/templates"
        $tempFolder = New-TempFolder
    }
    
    Context "Installation" {
        It "Should have the development/scripts/development/templates directory" {
            Test-Path -Path $templatesRoot | Should -Be $true
        }
        
        It "Should have the script-automation generator" {
            Test-Path -Path (Join-Path -Path $templatesRoot -ChildPath "script-automation") | Should -Be $true
        }
        
        It "Should have the script-analysis generator" {
            Test-Path -Path (Join-Path -Path $templatesRoot -ChildPath "script-analysis") | Should -Be $true
        }
        
        It "Should have the script-test generator" {
            Test-Path -Path (Join-Path -Path $templatesRoot -ChildPath "script-test") | Should -Be $true
        }
        
        It "Should have the script-integration generator" {
            Test-Path -Path (Join-Path -Path $templatesRoot -ChildPath "script-integration") | Should -Be $true
        }
    }
    
    Context "Generator Structure" {
        It "Should have the correct structure for script-automation" {
            $automationNewFolder = Join-Path -Path $templatesRoot -ChildPath "script-automation/new"
            Test-Path -Path $automationNewFolder | Should -Be $true
            Test-Path -Path (Join-Path -Path $automationNewFolder -ChildPath "hello.ejs.t") | Should -Be $true
            Test-Path -Path (Join-Path -Path $automationNewFolder -ChildPath "prompt.js") | Should -Be $true
        }
        
        It "Should have the correct structure for script-analysis" {
            $analysisNewFolder = Join-Path -Path $templatesRoot -ChildPath "script-analysis/new"
            Test-Path -Path $analysisNewFolder | Should -Be $true
            Test-Path -Path (Join-Path -Path $analysisNewFolder -ChildPath "hello.ejs.t") | Should -Be $true
            Test-Path -Path (Join-Path -Path $analysisNewFolder -ChildPath "prompt.js") | Should -Be $true
        }
        
        It "Should have the correct structure for script-test" {
            $testNewFolder = Join-Path -Path $templatesRoot -ChildPath "script-test/new"
            Test-Path -Path $testNewFolder | Should -Be $true
            Test-Path -Path (Join-Path -Path $testNewFolder -ChildPath "hello.ejs.t") | Should -Be $true
            Test-Path -Path (Join-Path -Path $testNewFolder -ChildPath "prompt.js") | Should -Be $true
        }
        
        It "Should have the correct structure for script-integration" {
            $integrationNewFolder = Join-Path -Path $templatesRoot -ChildPath "script-integration/new"
            Test-Path -Path $integrationNewFolder | Should -Be $true
            Test-Path -Path (Join-Path -Path $integrationNewFolder -ChildPath "hello.ejs.t") | Should -Be $true
            Test-Path -Path (Join-Path -Path $integrationNewFolder -ChildPath "prompt.js") | Should -Be $true
        }
    }
    
    Context "Generate-Script Script" {
        It "Should have the Generate-Script.ps1 script" {
            $scriptPath = Join-Path -Path $projectRoot -ChildPath "development/scripts/utils/Generate-Script.ps1"
            Test-Path -Path $scriptPath | Should -Be $true
        }
        
        It "Should have the generate-script.cmd script" {
            $cmdPath = Join-Path -Path $projectRoot -ChildPath "development/scripts/cmd/utils/generate-script.cmd"
            Test-Path -Path $cmdPath | Should -Be $true
        }
    }
    
    Context "Documentation" {
        It "Should have the hygen-guide.md document" {
            $guidePath = Join-Path -Path $projectRoot -ChildPath "development/scripts/docs/hygen-guide.md"
            Test-Path -Path $guidePath | Should -Be $true
        }
        
        It "Should have the hygen-analysis.md document" {
            $analysisPath = Join-Path -Path $projectRoot -ChildPath "development/scripts/docs/hygen-analysis.md"
            Test-Path -Path $analysisPath | Should -Be $true
        }
        
        It "Should have the hygen-templates-plan.md document" {
            $planPath = Join-Path -Path $projectRoot -ChildPath "development/scripts/docs/hygen-templates-plan.md"
            Test-Path -Path $planPath | Should -Be $true
        }
        
        It "Should have the hygen-integration-plan.md document" {
            $integrationPath = Join-Path -Path $projectRoot -ChildPath "development/scripts/docs/hygen-integration-plan.md"
            Test-Path -Path $integrationPath | Should -Be $true
        }
    }
    
    Context "Generation" {
        BeforeAll {
            # Sauvegarder le rÃ©pertoire courant
            $currentLocation = Get-Location
            # Changer le rÃ©pertoire courant pour le rÃ©pertoire du projet
            Set-Location -Path $projectRoot
        }
        
        AfterAll {
            # Restaurer le rÃ©pertoire courant
            Set-Location -Path $currentLocation
        }
        
        It "Should generate an automation script" {
            # GÃ©nÃ©rer un script d'automatisation
            $automationName = "Test-Automation"
            $automationDescription = "Test automation script"
            $automationAuthor = "Test Author"
            $outputFolder = $tempFolder
            
            $scriptPath = Join-Path -Path $projectRoot -ChildPath "development/scripts/utils/Generate-Script.ps1"
            & $scriptPath -Type automation -Name $automationName -Description $automationDescription -Author $automationAuthor -OutputFolder $outputFolder
            
            # VÃ©rifier que le script a Ã©tÃ© gÃ©nÃ©rÃ©
            $automationPath = Join-Path -Path $outputFolder -ChildPath "development/scripts/automation/$automationName.ps1"
            Test-Path -Path $automationPath | Should -Be $true
            
            # VÃ©rifier le contenu du script
            $automationContent = Get-Content -Path $automationPath -Raw
            $automationContent | Should -Match $automationDescription
            $automationContent | Should -Match $automationAuthor
        }
        
        It "Should generate an analysis script" {
            # GÃ©nÃ©rer un script d'analyse
            $analysisName = "Test-Analysis"
            $analysisDescription = "Test analysis script"
            $analysisSubFolder = "plugins"
            $analysisAuthor = "Test Author"
            $outputFolder = $tempFolder
            
            $scriptPath = Join-Path -Path $projectRoot -ChildPath "development/scripts/utils/Generate-Script.ps1"
            & $scriptPath -Type analysis -Name $analysisName -Description $analysisDescription -SubFolder $analysisSubFolder -Author $analysisAuthor -OutputFolder $outputFolder
            
            # VÃ©rifier que le script a Ã©tÃ© gÃ©nÃ©rÃ©
            $analysisPath = Join-Path -Path $outputFolder -ChildPath "development/scripts/analysis/$analysisSubFolder/$analysisName.ps1"
            Test-Path -Path $analysisPath | Should -Be $true
            
            # VÃ©rifier le contenu du script
            $analysisContent = Get-Content -Path $analysisPath -Raw
            $analysisContent | Should -Match $analysisDescription
            $analysisContent | Should -Match $analysisAuthor
        }
        
        It "Should generate a test script" {
            # GÃ©nÃ©rer un script de test
            $testName = "Test-Script"
            $testDescription = "Test script tests"
            $testScriptToTest = "automation/Example-Script.ps1"
            $testFunctionName = "TestScript"
            $testAuthor = "Test Author"
            $outputFolder = $tempFolder
            
            $scriptPath = Join-Path -Path $projectRoot -ChildPath "development/scripts/utils/Generate-Script.ps1"
            & $scriptPath -Type test -Name $testName -Description $testDescription -ScriptToTest $testScriptToTest -FunctionName $testFunctionName -Author $testAuthor -OutputFolder $outputFolder
            
            # VÃ©rifier que le script a Ã©tÃ© gÃ©nÃ©rÃ©
            $testPath = Join-Path -Path $outputFolder -ChildPath "development/scripts/development/testing/tests/$testName.Tests.ps1"
            Test-Path -Path $testPath | Should -Be $true
            
            # VÃ©rifier le contenu du script
            $testContent = Get-Content -Path $testPath -Raw
            $testContent | Should -Match $testDescription
            $testContent | Should -Match $testAuthor
            $testContent | Should -Match $testScriptToTest
            $testContent | Should -Match $testFunctionName
        }
        
        It "Should generate an integration script" {
            # GÃ©nÃ©rer un script d'intÃ©gration
            $integrationName = "Test-Integration"
            $integrationDescription = "Test integration script"
            $integrationAuthor = "Test Author"
            $outputFolder = $tempFolder
            
            $scriptPath = Join-Path -Path $projectRoot -ChildPath "development/scripts/utils/Generate-Script.ps1"
            & $scriptPath -Type integration -Name $integrationName -Description $integrationDescription -Author $integrationAuthor -OutputFolder $outputFolder
            
            # VÃ©rifier que le script a Ã©tÃ© gÃ©nÃ©rÃ©
            $integrationPath = Join-Path -Path $outputFolder -ChildPath "development/scripts/integration/$integrationName.ps1"
            Test-Path -Path $integrationPath | Should -Be $true
            
            # VÃ©rifier le contenu du script
            $integrationContent = Get-Content -Path $integrationPath -Raw
            $integrationContent | Should -Match $integrationDescription
            $integrationContent | Should -Match $integrationAuthor
        }
    }
    
    AfterAll {
        # Nettoyer le dossier temporaire
        Remove-TempFolder -TempFolder $tempFolder
    }
}
