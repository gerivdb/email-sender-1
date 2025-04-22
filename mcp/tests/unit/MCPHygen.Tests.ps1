#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour les templates Hygen MCP.

.DESCRIPTION
    Ce script contient des tests unitaires pour les templates Hygen MCP.
    Il vérifie que les templates sont correctement installés et fonctionnent comme prévu.

.NOTES
    Version: 1.0.0
    Auteur: MCP Team
    Date de création: 2023-05-15
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}
Import-Module -Name Pester -Force

# Obtenir le chemin du projet
function Get-ProjectPath {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.Parent.FullName
    return $projectRoot
}

# Créer un dossier temporaire pour les tests
function New-TempFolder {
    $tempFolder = Join-Path -Path $env:TEMP -ChildPath "MCPHygenTests-$(Get-Random)"
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

Describe "MCPHygen" {
    BeforeAll {
        $projectRoot = Get-ProjectPath
        $templatesRoot = Join-Path -Path $projectRoot -ChildPath "mcp/_templates"
        $tempFolder = New-TempFolder
    }
    
    Context "Installation" {
        It "Should have the mcp/_templates directory" {
            Test-Path -Path $templatesRoot | Should -Be $true
        }
        
        It "Should have the mcp-server generator" {
            Test-Path -Path (Join-Path -Path $templatesRoot -ChildPath "mcp-server") | Should -Be $true
        }
        
        It "Should have the mcp-client generator" {
            Test-Path -Path (Join-Path -Path $templatesRoot -ChildPath "mcp-client") | Should -Be $true
        }
        
        It "Should have the mcp-module generator" {
            Test-Path -Path (Join-Path -Path $templatesRoot -ChildPath "mcp-module") | Should -Be $true
        }
        
        It "Should have the mcp-doc generator" {
            Test-Path -Path (Join-Path -Path $templatesRoot -ChildPath "mcp-doc") | Should -Be $true
        }
    }
    
    Context "Generator Structure" {
        It "Should have the correct structure for mcp-server" {
            $serverNewFolder = Join-Path -Path $templatesRoot -ChildPath "mcp-server/new"
            Test-Path -Path $serverNewFolder | Should -Be $true
            Test-Path -Path (Join-Path -Path $serverNewFolder -ChildPath "hello.ejs.t") | Should -Be $true
            Test-Path -Path (Join-Path -Path $serverNewFolder -ChildPath "prompt.js") | Should -Be $true
        }
        
        It "Should have the correct structure for mcp-client" {
            $clientNewFolder = Join-Path -Path $templatesRoot -ChildPath "mcp-client/new"
            Test-Path -Path $clientNewFolder | Should -Be $true
            Test-Path -Path (Join-Path -Path $clientNewFolder -ChildPath "hello.ejs.t") | Should -Be $true
            Test-Path -Path (Join-Path -Path $clientNewFolder -ChildPath "prompt.js") | Should -Be $true
        }
        
        It "Should have the correct structure for mcp-module" {
            $moduleNewFolder = Join-Path -Path $templatesRoot -ChildPath "mcp-module/new"
            Test-Path -Path $moduleNewFolder | Should -Be $true
            Test-Path -Path (Join-Path -Path $moduleNewFolder -ChildPath "hello.ejs.t") | Should -Be $true
            Test-Path -Path (Join-Path -Path $moduleNewFolder -ChildPath "prompt.js") | Should -Be $true
        }
        
        It "Should have the correct structure for mcp-doc" {
            $docNewFolder = Join-Path -Path $templatesRoot -ChildPath "mcp-doc/new"
            Test-Path -Path $docNewFolder | Should -Be $true
            Test-Path -Path (Join-Path -Path $docNewFolder -ChildPath "hello.ejs.t") | Should -Be $true
            Test-Path -Path (Join-Path -Path $docNewFolder -ChildPath "prompt.js") | Should -Be $true
        }
    }
    
    Context "Generate-MCPComponent Script" {
        It "Should have the Generate-MCPComponent.ps1 script" {
            $scriptPath = Join-Path -Path $projectRoot -ChildPath "mcp/scripts/utils/Generate-MCPComponent.ps1"
            Test-Path -Path $scriptPath | Should -Be $true
        }
        
        It "Should have the generate-component.cmd script" {
            $cmdPath = Join-Path -Path $projectRoot -ChildPath "mcp/cmd/utils/generate-component.cmd"
            Test-Path -Path $cmdPath | Should -Be $true
        }
    }
    
    Context "Documentation" {
        It "Should have the hygen-guide.md document" {
            $guidePath = Join-Path -Path $projectRoot -ChildPath "mcp/docs/hygen-guide.md"
            Test-Path -Path $guidePath | Should -Be $true
        }
        
        It "Should have the hygen-analysis.md document" {
            $analysisPath = Join-Path -Path $projectRoot -ChildPath "mcp/docs/hygen-analysis.md"
            Test-Path -Path $analysisPath | Should -Be $true
        }
        
        It "Should have the hygen-templates-plan.md document" {
            $planPath = Join-Path -Path $projectRoot -ChildPath "mcp/docs/hygen-templates-plan.md"
            Test-Path -Path $planPath | Should -Be $true
        }
        
        It "Should have the hygen-integration-plan.md document" {
            $integrationPath = Join-Path -Path $projectRoot -ChildPath "mcp/docs/hygen-integration-plan.md"
            Test-Path -Path $integrationPath | Should -Be $true
        }
    }
    
    Context "Generation" {
        BeforeAll {
            # Sauvegarder le répertoire courant
            $currentLocation = Get-Location
            # Changer le répertoire courant pour le répertoire du projet
            Set-Location -Path $projectRoot
        }
        
        AfterAll {
            # Restaurer le répertoire courant
            Set-Location -Path $currentLocation
        }
        
        It "Should generate a server script" {
            # Générer un script serveur
            $serverName = "test-server"
            $serverDescription = "Test server script"
            $serverAuthor = "Test Author"
            $outputFolder = $tempFolder
            
            $scriptPath = Join-Path -Path $projectRoot -ChildPath "mcp/scripts/utils/Generate-MCPComponent.ps1"
            & $scriptPath -Type server -Name $serverName -Description $serverDescription -Author $serverAuthor -OutputFolder $outputFolder
            
            # Vérifier que le script a été généré
            $serverPath = Join-Path -Path $outputFolder -ChildPath "mcp/core/server/$serverName.ps1"
            Test-Path -Path $serverPath | Should -Be $true
            
            # Vérifier le contenu du script
            $serverContent = Get-Content -Path $serverPath -Raw
            $serverContent | Should -Match $serverDescription
            $serverContent | Should -Match $serverAuthor
        }
        
        It "Should generate a client script" {
            # Générer un script client
            $clientName = "test-client"
            $clientDescription = "Test client script"
            $clientAuthor = "Test Author"
            $outputFolder = $tempFolder
            
            $scriptPath = Join-Path -Path $projectRoot -ChildPath "mcp/scripts/utils/Generate-MCPComponent.ps1"
            & $scriptPath -Type client -Name $clientName -Description $clientDescription -Author $clientAuthor -OutputFolder $outputFolder
            
            # Vérifier que le script a été généré
            $clientPath = Join-Path -Path $outputFolder -ChildPath "mcp/core/client/$clientName.ps1"
            Test-Path -Path $clientPath | Should -Be $true
            
            # Vérifier le contenu du script
            $clientContent = Get-Content -Path $clientPath -Raw
            $clientContent | Should -Match $clientDescription
            $clientContent | Should -Match $clientAuthor
        }
        
        It "Should generate a module" {
            # Générer un module
            $moduleName = "TestModule"
            $moduleDescription = "Test module"
            $moduleAuthor = "Test Author"
            $outputFolder = $tempFolder
            
            $scriptPath = Join-Path -Path $projectRoot -ChildPath "mcp/scripts/utils/Generate-MCPComponent.ps1"
            & $scriptPath -Type module -Name $moduleName -Description $moduleDescription -Author $moduleAuthor -OutputFolder $outputFolder
            
            # Vérifier que le module a été généré
            $modulePath = Join-Path -Path $outputFolder -ChildPath "mcp/modules/$moduleName.psm1"
            Test-Path -Path $modulePath | Should -Be $true
            
            # Vérifier le contenu du module
            $moduleContent = Get-Content -Path $modulePath -Raw
            $moduleContent | Should -Match $moduleDescription
            $moduleContent | Should -Match $moduleAuthor
        }
        
        It "Should generate a document" {
            # Générer un document
            $docName = "test-doc"
            $docDescription = "Test document"
            $docCategory = "guides"
            $docAuthor = "Test Author"
            $outputFolder = $tempFolder
            
            $scriptPath = Join-Path -Path $projectRoot -ChildPath "mcp/scripts/utils/Generate-MCPComponent.ps1"
            & $scriptPath -Type doc -Name $docName -Category $docCategory -Description $docDescription -Author $docAuthor -OutputFolder $outputFolder
            
            # Vérifier que le document a été généré
            $docPath = Join-Path -Path $outputFolder -ChildPath "mcp/docs/$docCategory/$docName.md"
            Test-Path -Path $docPath | Should -Be $true
            
            # Vérifier le contenu du document
            $docContent = Get-Content -Path $docPath -Raw
            $docContent | Should -Match $docDescription
            $docContent | Should -Match $docAuthor
        }
    }
    
    AfterAll {
        # Nettoyer le dossier temporaire
        Remove-TempFolder -TempFolder $tempFolder
    }
}
