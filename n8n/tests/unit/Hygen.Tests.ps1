<#
.SYNOPSIS
    Tests unitaires pour l'implémentation de Hygen dans le projet n8n.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    de l'implémentation de Hygen, y compris les scripts d'installation,
    la structure de dossiers et les générateurs.

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

Describe "Hygen Implementation Tests" {
    Context "Template Structure Tests" {
        It "Should have the _templates directory" {
            Test-Path -Path $templatesRoot | Should -Be $true
        }

        It "Should have the n8n-script generator" {
            Test-Path -Path (Join-Path -Path $templatesRoot -ChildPath "n8n-script") | Should -Be $true
        }

        It "Should have the n8n-workflow generator" {
            Test-Path -Path (Join-Path -Path $templatesRoot -ChildPath "n8n-workflow") | Should -Be $true
        }

        It "Should have the n8n-doc generator" {
            Test-Path -Path (Join-Path -Path $templatesRoot -ChildPath "n8n-doc") | Should -Be $true
        }

        It "Should have the n8n-integration generator" {
            Test-Path -Path (Join-Path -Path $templatesRoot -ChildPath "n8n-integration") | Should -Be $true
        }
    }

    Context "Template Content Tests" {
        It "n8n-script template should have the correct content" {
            $templatePath = Join-Path -Path $templatesRoot -ChildPath "n8n-script/new/hello.ejs.t"
            $content = Get-Content -Path $templatePath -Raw
            $content | Should -Match "to: n8n/automation/<%= category %>/<%= name %>.ps1"
            $content | Should -Match "\[CmdletBinding\(SupportsShouldProcess=\$true\)\]"
            $content | Should -Match "Start-MainProcess"
        }

        It "n8n-workflow template should have the correct content" {
            $templatePath = Join-Path -Path $templatesRoot -ChildPath "n8n-workflow/new/hello.ejs.t"
            $content = Get-Content -Path $templatePath -Raw
            $content | Should -Match "to: n8n/core/workflows/<%= environment %>/<%= name %>.json"
            $content | Should -Match '"name": "<%= name %>"'
            $content | Should -Match '"tags": <%= JSON.stringify\(tags\) %>'
        }

        It "n8n-doc template should have the correct content" {
            $templatePath = Join-Path -Path $templatesRoot -ChildPath "n8n-doc/new/hello.ejs.t"
            $content = Get-Content -Path $templatePath -Raw
            $content | Should -Match "to: n8n/docs/<%= category %>/<%= name %>.md"
            $content | Should -Match "# <%= h.changeCase.title\(name\) %>"
            $content | Should -Match "<%= description %>"
        }

        It "n8n-integration template should have the correct content" {
            $templatePath = Join-Path -Path $templatesRoot -ChildPath "n8n-integration/new/hello.ejs.t"
            $content = Get-Content -Path $templatePath -Raw
            $content | Should -Match "to: n8n/integrations/<%= system %>/<%= name %>.ps1"
            $content | Should -Match "Script d'intégration <%= system %> - <%= name %>"
            $content | Should -Match "Start-Integration"
        }
    }

    Context "Prompt Files Tests" {
        It "n8n-script should have a prompt.js file" {
            $promptPath = Join-Path -Path $templatesRoot -ChildPath "n8n-script/new/prompt.js"
            Test-Path -Path $promptPath | Should -Be $true
            $content = Get-Content -Path $promptPath -Raw
            $content | Should -Match "name: 'name'"
            $content | Should -Match "name: 'category'"
            $content | Should -Match "name: 'description'"
            $content | Should -Match "name: 'author'"
        }

        It "n8n-workflow should have a prompt.js file" {
            $promptPath = Join-Path -Path $templatesRoot -ChildPath "n8n-workflow/new/prompt.js"
            Test-Path -Path $promptPath | Should -Be $true
            $content = Get-Content -Path $promptPath -Raw
            $content | Should -Match "name: 'name'"
            $content | Should -Match "name: 'environment'"
            $content | Should -Match "name: 'tags'"
        }

        It "n8n-doc should have a prompt.js file" {
            $promptPath = Join-Path -Path $templatesRoot -ChildPath "n8n-doc/new/prompt.js"
            Test-Path -Path $promptPath | Should -Be $true
            $content = Get-Content -Path $promptPath -Raw
            $content | Should -Match "name: 'name'"
            $content | Should -Match "name: 'category'"
            $content | Should -Match "name: 'description'"
            $content | Should -Match "name: 'author'"
        }

        It "n8n-integration should have a prompt.js file" {
            $promptPath = Join-Path -Path $templatesRoot -ChildPath "n8n-integration/new/prompt.js"
            Test-Path -Path $promptPath | Should -Be $true
            $content = Get-Content -Path $promptPath -Raw
            $content | Should -Match "name: 'name'"
            $content | Should -Match "name: 'system'"
            $content | Should -Match "name: 'description'"
            $content | Should -Match "name: 'author'"
        }
    }

    Context "Installation Scripts Tests" {
        It "Should have the install-hygen.ps1 script" {
            $scriptPath = Join-Path -Path $n8nRoot -ChildPath "scripts/setup/install-hygen.ps1"
            Test-Path -Path $scriptPath | Should -Be $true
            $content = Get-Content -Path $scriptPath -Raw
            $content | Should -Match "Installation de Hygen pour n8n"
            $content | Should -Match "npm install --save-dev hygen"
            $content | Should -Match "npx hygen init self"
        }

        It "Should have the ensure-hygen-structure.ps1 script" {
            $scriptPath = Join-Path -Path $n8nRoot -ChildPath "scripts/setup/ensure-hygen-structure.ps1"
            Test-Path -Path $scriptPath | Should -Be $true
            $content = Get-Content -Path $scriptPath -Raw
            $content | Should -Match "\$requiredFolders = @\("
            $content | Should -Match "n8n/automation"
            $content | Should -Match "n8n/core/workflows"
            $content | Should -Match "n8n/integrations"
            $content | Should -Match "n8n/docs"
        }
    }

    Context "Utility Scripts Tests" {
        It "Should have the Generate-N8nComponent.ps1 script" {
            $scriptPath = Join-Path -Path $n8nRoot -ChildPath "scripts/utils/Generate-N8nComponent.ps1"
            Test-Path -Path $scriptPath | Should -Be $true
            $content = Get-Content -Path $scriptPath -Raw
            $content | Should -Match "function Show-Menu"
            $content | Should -Match "function Generate-Component"
            $content | Should -Match "npx hygen n8n-script new"
            $content | Should -Match "npx hygen n8n-workflow new"
            $content | Should -Match "npx hygen n8n-doc new"
            $content | Should -Match "npx hygen n8n-integration new"
        }
    }

    Context "Command Scripts Tests" {
        It "Should have the install-hygen.cmd script" {
            $scriptPath = Join-Path -Path $n8nRoot -ChildPath "cmd/utils/install-hygen.cmd"
            Test-Path -Path $scriptPath | Should -Be $true
            $content = Get-Content -Path $scriptPath -Raw
            $content | Should -Match "Installation de Hygen pour n8n"
            $content | Should -Match "powershell -ExecutionPolicy Bypass -File"
        }

        It "Should have the generate-component.cmd script" {
            $scriptPath = Join-Path -Path $n8nRoot -ChildPath "cmd/utils/generate-component.cmd"
            Test-Path -Path $scriptPath | Should -Be $true
            $content = Get-Content -Path $scriptPath -Raw
            $content | Should -Match "Generateur de composants n8n"
            $content | Should -Match "powershell -ExecutionPolicy Bypass -File"
        }
    }

    Context "Documentation Tests" {
        It "Should have the hygen-guide.md documentation" {
            $docPath = Join-Path -Path $n8nRoot -ChildPath "docs/hygen-guide.md"
            Test-Path -Path $docPath | Should -Be $true
            $content = Get-Content -Path $docPath -Raw
            $content | Should -Match "Guide d'utilisation de Hygen pour le projet n8n"
            $content | Should -Match "npx hygen n8n-script new"
            $content | Should -Match "npx hygen n8n-workflow new"
            $content | Should -Match "npx hygen n8n-doc new"
            $content | Should -Match "npx hygen n8n-integration new"
        }
    }

    Context "Structure Verification Tests" {
        BeforeAll {
            # Créer un dossier temporaire pour les tests
            $script:tempFolder = New-TestFolder
            
            # Copier le script ensure-hygen-structure.ps1 dans le dossier temporaire
            $sourcePath = Join-Path -Path $n8nRoot -ChildPath "scripts/setup/ensure-hygen-structure.ps1"
            $destPath = Join-Path -Path $script:tempFolder -ChildPath "ensure-hygen-structure.ps1"
            Copy-Item -Path $sourcePath -Destination $destPath
        }

        AfterAll {
            # Supprimer le dossier temporaire
            Remove-TestFolder -Path $script:tempFolder
        }

        It "ensure-hygen-structure.ps1 should create the required folders" {
            # Exécuter le script dans le dossier temporaire
            $currentLocation = Get-Location
            Set-Location -Path $script:tempFolder
            
            # Modifier le script pour qu'il crée les dossiers dans le dossier temporaire
            $scriptContent = Get-Content -Path "ensure-hygen-structure.ps1" -Raw
            $scriptContent = $scriptContent -replace "n8n/", "$script:tempFolder/n8n/"
            Set-Content -Path "ensure-hygen-structure-modified.ps1" -Value $scriptContent
            
            # Exécuter le script modifié
            & "$script:tempFolder/ensure-hygen-structure-modified.ps1"
            
            # Vérifier que les dossiers ont été créés
            Test-Path -Path "$script:tempFolder/n8n/automation" | Should -Be $true
            Test-Path -Path "$script:tempFolder/n8n/core/workflows/local" | Should -Be $true
            Test-Path -Path "$script:tempFolder/n8n/integrations/mcp" | Should -Be $true
            Test-Path -Path "$script:tempFolder/n8n/docs/architecture" | Should -Be $true
            
            # Revenir à l'emplacement d'origine
            Set-Location -Path $currentLocation
        }
    }
}
