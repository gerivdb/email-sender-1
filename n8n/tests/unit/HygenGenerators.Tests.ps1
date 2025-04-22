<#
.SYNOPSIS
    Tests unitaires pour les générateurs Hygen du projet n8n.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    des générateurs Hygen, en testant la génération de fichiers à partir des templates.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-01
#>

# Importer le module Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Définir les chemins
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Get-Item $scriptPath).Parent.Parent.Parent.FullName
$n8nRoot = Join-Path -Path $projectRoot -ChildPath "n8n"
$templatesRoot = Join-Path -Path $projectRoot -ChildPath "_templates"

# Fonction pour créer un dossier temporaire pour les tests
function New-TestFolder {
    $tempFolder = Join-Path -Path $env:TEMP -ChildPath "n8n-hygen-tests-$(Get-Random)"
    New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null
    return $tempFolder
}

# Fonction pour supprimer un dossier temporaire
function Remove-TestFolder {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    if (Test-Path -Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
    }
}

# Fonction pour simuler la génération d'un fichier à partir d'un template
function Test-TemplateGeneration {
    param (
        [Parameter(Mandatory=$true)]
        [string]$TemplatePath,
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        [Parameter(Mandatory=$true)]
        [hashtable]$Variables
    )
    
    # Lire le contenu du template
    $templateContent = Get-Content -Path $TemplatePath -Raw
    
    # Extraire le chemin de destination du template
    if ($templateContent -match "---\s*to:\s*([^\s]+)\s*---") {
        $destinationPath = $Matches[1]
        
        # Remplacer les variables dans le chemin de destination
        foreach ($key in $Variables.Keys) {
            $destinationPath = $destinationPath -replace "<%= $key %>", $Variables[$key]
        }
        
        # Créer le chemin complet de destination
        $fullDestinationPath = Join-Path -Path $OutputPath -ChildPath $destinationPath
        
        # Créer le dossier parent si nécessaire
        $parentFolder = Split-Path -Parent $fullDestinationPath
        if (-not (Test-Path -Path $parentFolder)) {
            New-Item -Path $parentFolder -ItemType Directory -Force | Out-Null
        }
        
        # Extraire le contenu du template (après le deuxième ---)
        $contentStart = $templateContent.IndexOf("---", $templateContent.IndexOf("---") + 3) + 3
        $content = $templateContent.Substring($contentStart)
        
        # Remplacer les variables dans le contenu
        foreach ($key in $Variables.Keys) {
            $content = $content -replace "<%= $key %>", $Variables[$key]
        }
        
        # Écrire le contenu dans le fichier de destination
        Set-Content -Path $fullDestinationPath -Value $content
        
        return $fullDestinationPath
    }
    
    return $null
}

Describe "Hygen Generators Tests" {
    BeforeAll {
        # Créer un dossier temporaire pour les tests
        $script:tempFolder = New-TestFolder
    }

    AfterAll {
        # Supprimer le dossier temporaire
        Remove-TestFolder -Path $script:tempFolder
    }

    Context "n8n-script Generator Tests" {
        BeforeAll {
            # Définir les variables pour le template
            $script:scriptVariables = @{
                name = "test-script"
                category = "deployment"
                description = "Script de test pour les tests unitaires"
                author = "Équipe de test"
                "h.now()" = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            }
            
            # Générer le fichier à partir du template
            $templatePath = Join-Path -Path $templatesRoot -ChildPath "n8n-script/new/hello.ejs.t"
            $script:generatedScriptPath = Test-TemplateGeneration -TemplatePath $templatePath -OutputPath $script:tempFolder -Variables $script:scriptVariables
        }

        It "Should generate a script file" {
            $script:generatedScriptPath | Should -Not -BeNullOrEmpty
            Test-Path -Path $script:generatedScriptPath | Should -Be $true
        }

        It "Should generate a script with the correct name and path" {
            $script:generatedScriptPath | Should -BeLike "*n8n/automation/deployment/test-script.ps1"
        }

        It "Should include the description in the script" {
            $content = Get-Content -Path $script:generatedScriptPath -Raw
            $content | Should -Match "Script de test pour les tests unitaires"
        }

        It "Should include the author in the script" {
            $content = Get-Content -Path $script:generatedScriptPath -Raw
            $content | Should -Match "Auteur: Équipe de test"
        }

        It "Should include the CmdletBinding attribute" {
            $content = Get-Content -Path $script:generatedScriptPath -Raw
            $content | Should -Match "\[CmdletBinding\(SupportsShouldProcess=\$true\)\]"
        }

        It "Should include the Start-MainProcess function" {
            $content = Get-Content -Path $script:generatedScriptPath -Raw
            $content | Should -Match "function Start-MainProcess"
        }
    }

    Context "n8n-workflow Generator Tests" {
        BeforeAll {
            # Définir les variables pour le template
            $script:workflowVariables = @{
                name = "test-workflow"
                environment = "local"
                "JSON.stringify(tags)" = '["email", "test"]'
                "h.uuid()" = [guid]::NewGuid().ToString()
                "new Date().toISOString()" = (Get-Date).ToUniversalTime().ToString("o")
            }
            
            # Générer le fichier à partir du template
            $templatePath = Join-Path -Path $templatesRoot -ChildPath "n8n-workflow/new/hello.ejs.t"
            $script:generatedWorkflowPath = Test-TemplateGeneration -TemplatePath $templatePath -OutputPath $script:tempFolder -Variables $script:workflowVariables
        }

        It "Should generate a workflow file" {
            $script:generatedWorkflowPath | Should -Not -BeNullOrEmpty
            Test-Path -Path $script:generatedWorkflowPath | Should -Be $true
        }

        It "Should generate a workflow with the correct name and path" {
            $script:generatedWorkflowPath | Should -BeLike "*n8n/core/workflows/local/test-workflow.json"
        }

        It "Should include the workflow name in the JSON" {
            $content = Get-Content -Path $script:generatedWorkflowPath -Raw
            $content | Should -Match '"name": "test-workflow"'
        }

        It "Should include the tags in the JSON" {
            $content = Get-Content -Path $script:generatedWorkflowPath -Raw
            $content | Should -Match '"tags": \["email", "test"\]'
        }

        It "Should be valid JSON" {
            { Get-Content -Path $script:generatedWorkflowPath -Raw | ConvertFrom-Json } | Should -Not -Throw
        }
    }

    Context "n8n-doc Generator Tests" {
        BeforeAll {
            # Définir les variables pour le template
            $script:docVariables = @{
                name = "test-doc"
                category = "architecture"
                description = "Documentation de test pour les tests unitaires"
                author = "Équipe de test"
                "h.changeCase.title(name)" = "Test Doc"
                "h.now()" = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            }
            
            # Générer le fichier à partir du template
            $templatePath = Join-Path -Path $templatesRoot -ChildPath "n8n-doc/new/hello.ejs.t"
            $script:generatedDocPath = Test-TemplateGeneration -TemplatePath $templatePath -OutputPath $script:tempFolder -Variables $script:docVariables
        }

        It "Should generate a documentation file" {
            $script:generatedDocPath | Should -Not -BeNullOrEmpty
            Test-Path -Path $script:generatedDocPath | Should -Be $true
        }

        It "Should generate a documentation with the correct name and path" {
            $script:generatedDocPath | Should -BeLike "*n8n/docs/architecture/test-doc.md"
        }

        It "Should include the title in the documentation" {
            $content = Get-Content -Path $script:generatedDocPath -Raw
            $content | Should -Match "# Test Doc"
        }

        It "Should include the description in the documentation" {
            $content = Get-Content -Path $script:generatedDocPath -Raw
            $content | Should -Match "Documentation de test pour les tests unitaires"
        }

        It "Should include the author in the documentation" {
            $content = Get-Content -Path $script:generatedDocPath -Raw
            $content | Should -Match "Équipe de test"
        }

        It "Should include the standard sections" {
            $content = Get-Content -Path $script:generatedDocPath -Raw
            $content | Should -Match "## Fonctionnalités"
            $content | Should -Match "## Prérequis"
            $content | Should -Match "## Installation"
            $content | Should -Match "## Utilisation"
            $content | Should -Match "## Configuration"
            $content | Should -Match "## Dépannage"
            $content | Should -Match "## Références"
        }
    }

    Context "n8n-integration Generator Tests" {
        BeforeAll {
            # Définir les variables pour le template
            $script:integrationVariables = @{
                name = "test-integration"
                system = "mcp"
                description = "Intégration de test pour les tests unitaires"
                author = "Équipe de test"
                "h.now()" = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            }
            
            # Générer le fichier à partir du template
            $templatePath = Join-Path -Path $templatesRoot -ChildPath "n8n-integration/new/hello.ejs.t"
            $script:generatedIntegrationPath = Test-TemplateGeneration -TemplatePath $templatePath -OutputPath $script:tempFolder -Variables $script:integrationVariables
        }

        It "Should generate an integration script file" {
            $script:generatedIntegrationPath | Should -Not -BeNullOrEmpty
            Test-Path -Path $script:generatedIntegrationPath | Should -Be $true
        }

        It "Should generate an integration script with the correct name and path" {
            $script:generatedIntegrationPath | Should -BeLike "*n8n/integrations/mcp/test-integration.ps1"
        }

        It "Should include the description in the script" {
            $content = Get-Content -Path $script:generatedIntegrationPath -Raw
            $content | Should -Match "Intégration de test pour les tests unitaires"
        }

        It "Should include the author in the script" {
            $content = Get-Content -Path $script:generatedIntegrationPath -Raw
            $content | Should -Match "Auteur: Équipe de test"
        }

        It "Should include the CmdletBinding attribute" {
            $content = Get-Content -Path $script:generatedIntegrationPath -Raw
            $content | Should -Match "\[CmdletBinding\(SupportsShouldProcess=\$true\)\]"
        }

        It "Should include the Get-Configuration function" {
            $content = Get-Content -Path $script:generatedIntegrationPath -Raw
            $content | Should -Match "function Get-Configuration"
        }

        It "Should include the Start-Integration function" {
            $content = Get-Content -Path $script:generatedIntegrationPath -Raw
            $content | Should -Match "function Start-Integration"
        }

        It "Should include the system name in the script" {
            $content = Get-Content -Path $script:generatedIntegrationPath -Raw
            $content | Should -Match "Démarrage de l'intégration mcp - test-integration"
        }
    }
}
