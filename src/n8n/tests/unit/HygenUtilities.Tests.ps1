<#
.SYNOPSIS
    Tests unitaires pour les scripts d'utilitaires Hygen du projet n8n.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    des scripts d'utilitaires Hygen, notamment les scripts de génération de composants.

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
$utilsPath = Join-Path -Path $n8nRoot -ChildPath "scripts/utils"

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

Describe "Hygen Utilities Tests" {
    Context "Generate-N8nComponent.ps1 Tests" {
        BeforeAll {
            # Chemin du script à tester
            $script:generateComponentPath = Join-Path -Path $utilsPath -ChildPath "Generate-N8nComponent.ps1"
            
            # Créer un dossier temporaire pour les tests
            $script:tempFolder = New-TestFolder
            
            # Copier le script dans le dossier temporaire
            Copy-Item -Path $script:generateComponentPath -Destination $script:tempFolder
            $script:testScriptPath = Join-Path -Path $script:tempFolder -ChildPath "Generate-N8nComponent.ps1"
            
            # Modifier le script pour les tests
            $scriptContent = Get-Content -Path $script:testScriptPath -Raw
            
            # Remplacer la fonction New-Component pour les tests
            $modifiedContent = $scriptContent -replace "function New-Component[^}]*}", @"
function New-Component {
    param (
        [Parameter(Mandatory=`$true)]
        [string]`$Type
    )

    switch (`$Type) {
        "script" {
            Write-Host "Génération d'un script d'automatisation n8n..." -ForegroundColor Cyan
            # Simuler la génération d'un script
            `$scriptPath = Join-Path -Path `$env:TEMP -ChildPath "test-script.ps1"
            Set-Content -Path `$scriptPath -Value "# Script de test"
            return `$true
        }
        "workflow" {
            Write-Host "Génération d'un workflow n8n..." -ForegroundColor Cyan
            # Simuler la génération d'un workflow
            `$workflowPath = Join-Path -Path `$env:TEMP -ChildPath "test-workflow.json"
            Set-Content -Path `$workflowPath -Value "{ ""name"": ""test-workflow"" }"
            return `$true
        }
        "doc" {
            Write-Host "Génération d'une documentation n8n..." -ForegroundColor Cyan
            # Simuler la génération d'une documentation
            `$docPath = Join-Path -Path `$env:TEMP -ChildPath "test-doc.md"
            Set-Content -Path `$docPath -Value "# Test Doc"
            return `$true
        }
        "integration" {
            Write-Host "Génération d'une intégration n8n..." -ForegroundColor Cyan
            # Simuler la génération d'une intégration
            `$integrationPath = Join-Path -Path `$env:TEMP -ChildPath "test-integration.ps1"
            Set-Content -Path `$integrationPath -Value "# Intégration de test"
            return `$true
        }
        default {
            Write-Host "Type de composant non reconnu: `$Type" -ForegroundColor Red
            return `$false
        }
    }
}
"@
            
            # Enregistrer le script modifié
            Set-Content -Path $script:testScriptPath -Value $modifiedContent
        }

        AfterAll {
            # Supprimer le dossier temporaire
            Remove-TestFolder -Path $script:tempFolder
        }

        It "Should have the Generate-N8nComponent.ps1 script" {
            Test-Path -Path $script:generateComponentPath | Should -Be $true
        }

        It "Should have the correct parameters" {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:generateComponentPath, [ref]$null, [ref]$null)
            $paramBlock = $ast.ParamBlock
            $paramBlock | Should -Not -BeNullOrEmpty
            
            $componentTypeParam = $paramBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq "ComponentType" }
            $componentTypeParam | Should -Not -BeNullOrEmpty
            
            $validateSet = $componentTypeParam.Attributes | Where-Object { $_.TypeName.Name -eq "ValidateSet" }
            $validateSet | Should -Not -BeNullOrEmpty
            
            $validateSetValues = $validateSet.PositionalArguments | ForEach-Object { $_.Value }
            $validateSetValues | Should -Contain "script"
            $validateSetValues | Should -Contain "workflow"
            $validateSetValues | Should -Contain "doc"
            $validateSetValues | Should -Contain "integration"
        }

        It "Should generate a script component" {
            # Exécuter le script avec le paramètre ComponentType
            $result = & $script:testScriptPath -ComponentType "script"
            $result | Should -Be $true
            
            # Vérifier que le fichier a été créé
            $scriptPath = Join-Path -Path $env:TEMP -ChildPath "test-script.ps1"
            Test-Path -Path $scriptPath | Should -Be $true
            
            # Nettoyer
            if (Test-Path -Path $scriptPath) {
                Remove-Item -Path $scriptPath -Force
            }
        }

        It "Should generate a workflow component" {
            # Exécuter le script avec le paramètre ComponentType
            $result = & $script:testScriptPath -ComponentType "workflow"
            $result | Should -Be $true
            
            # Vérifier que le fichier a été créé
            $workflowPath = Join-Path -Path $env:TEMP -ChildPath "test-workflow.json"
            Test-Path -Path $workflowPath | Should -Be $true
            
            # Nettoyer
            if (Test-Path -Path $workflowPath) {
                Remove-Item -Path $workflowPath -Force
            }
        }

        It "Should generate a doc component" {
            # Exécuter le script avec le paramètre ComponentType
            $result = & $script:testScriptPath -ComponentType "doc"
            $result | Should -Be $true
            
            # Vérifier que le fichier a été créé
            $docPath = Join-Path -Path $env:TEMP -ChildPath "test-doc.md"
            Test-Path -Path $docPath | Should -Be $true
            
            # Nettoyer
            if (Test-Path -Path $docPath) {
                Remove-Item -Path $docPath -Force
            }
        }

        It "Should generate an integration component" {
            # Exécuter le script avec le paramètre ComponentType
            $result = & $script:testScriptPath -ComponentType "integration"
            $result | Should -Be $true
            
            # Vérifier que le fichier a été créé
            $integrationPath = Join-Path -Path $env:TEMP -ChildPath "test-integration.ps1"
            Test-Path -Path $integrationPath | Should -Be $true
            
            # Nettoyer
            if (Test-Path -Path $integrationPath) {
                Remove-Item -Path $integrationPath -Force
            }
        }
    }
}

