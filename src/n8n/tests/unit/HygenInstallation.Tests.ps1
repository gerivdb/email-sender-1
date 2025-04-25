<#
.SYNOPSIS
    Tests unitaires pour les scripts d'installation de Hygen du projet n8n.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    des scripts d'installation de Hygen, notamment ensure-hygen-structure.ps1 et install-hygen.ps1.

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
$setupPath = Join-Path -Path $n8nRoot -ChildPath "scripts/setup"

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

Describe "Hygen Installation Tests" {
    Context "ensure-hygen-structure.ps1 Tests" {
        BeforeAll {
            # Chemin du script à tester
            $script:ensureStructurePath = Join-Path -Path $setupPath -ChildPath "ensure-hygen-structure.ps1"
            
            # Créer un dossier temporaire pour les tests
            $script:tempFolder = New-TestFolder
            
            # Copier le script dans le dossier temporaire
            Copy-Item -Path $script:ensureStructurePath -Destination $script:tempFolder
            $script:testScriptPath = Join-Path -Path $script:tempFolder -ChildPath "ensure-hygen-structure.ps1"
            
            # Modifier le script pour les tests
            $scriptContent = Get-Content -Path $script:testScriptPath -Raw
            
            # Remplacer les chemins de dossiers pour les tests
            $modifiedContent = $scriptContent -replace "n8n/", "$($script:tempFolder -replace '\\', '/')/n8n/"
            
            # Enregistrer le script modifié
            Set-Content -Path $script:testScriptPath -Value $modifiedContent
        }

        AfterAll {
            # Supprimer le dossier temporaire
            Remove-TestFolder -Path $script:tempFolder
        }

        It "Should have the ensure-hygen-structure.ps1 script" {
            Test-Path -Path $script:ensureStructurePath | Should -Be $true
        }

        It "Should create the required folders" {
            # Exécuter le script
            & $script:testScriptPath -WhatIf
            
            # Vérifier que le script s'exécute sans erreur
            $LASTEXITCODE | Should -Be 0
        }

        It "Should create the automation folders" {
            # Exécuter le script
            & $script:testScriptPath
            
            # Vérifier que les dossiers ont été créés
            Test-Path -Path "$($script:tempFolder)/n8n/automation" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/automation/deployment" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/automation/monitoring" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/automation/diagnostics" | Should -Be $true
        }

        It "Should create the core folders" {
            # Vérifier que les dossiers ont été créés
            Test-Path -Path "$($script:tempFolder)/n8n/core" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/core/workflows" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/core/workflows/local" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/core/workflows/ide" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/core/workflows/archive" | Should -Be $true
        }

        It "Should create the integrations folders" {
            # Vérifier que les dossiers ont été créés
            Test-Path -Path "$($script:tempFolder)/n8n/integrations" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/integrations/mcp" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/integrations/ide" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/integrations/api" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/integrations/augment" | Should -Be $true
        }

        It "Should create the docs folders" {
            # Vérifier que les dossiers ont été créés
            Test-Path -Path "$($script:tempFolder)/n8n/docs" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/docs/architecture" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/docs/workflows" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/docs/api" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/docs/guides" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/docs/installation" | Should -Be $true
        }

        It "Should create the scripts folders" {
            # Vérifier que les dossiers ont été créés
            Test-Path -Path "$($script:tempFolder)/n8n/scripts" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/scripts/utils" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/scripts/setup" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/scripts/sync" | Should -Be $true
        }

        It "Should create the cmd folders" {
            # Vérifier que les dossiers ont été créés
            Test-Path -Path "$($script:tempFolder)/n8n/cmd" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/cmd/utils" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/cmd/start" | Should -Be $true
            Test-Path -Path "$($script:tempFolder)/n8n/cmd/stop" | Should -Be $true
        }
    }

    Context "install-hygen.ps1 Tests" {
        BeforeAll {
            # Chemin du script à tester
            $script:installHygenPath = Join-Path -Path $setupPath -ChildPath "install-hygen.ps1"
            
            # Créer un dossier temporaire pour les tests
            $script:tempFolder = New-TestFolder
            
            # Copier le script dans le dossier temporaire
            Copy-Item -Path $script:installHygenPath -Destination $script:tempFolder
            $script:testScriptPath = Join-Path -Path $script:tempFolder -ChildPath "install-hygen.ps1"
            
            # Copier le script ensure-hygen-structure.ps1 dans le dossier temporaire
            Copy-Item -Path $script:ensureStructurePath -Destination $script:tempFolder
            $script:testEnsureStructurePath = Join-Path -Path $script:tempFolder -ChildPath "ensure-hygen-structure.ps1"
            
            # Modifier le script pour les tests
            $scriptContent = Get-Content -Path $script:testScriptPath -Raw
            
            # Remplacer les appels à npm et npx pour les tests
            $modifiedContent = $scriptContent -replace "npm install --save-dev hygen", "Write-Host 'Simulation: npm install --save-dev hygen'"
            $modifiedContent = $modifiedContent -replace "npx hygen init self", "Write-Host 'Simulation: npx hygen init self'"
            
            # Remplacer l'appel à ensure-hygen-structure.ps1
            $modifiedContent = $modifiedContent -replace "& `"\$scriptPath\\ensure-hygen-structure.ps1`"", "& `"$($script:testEnsureStructurePath)`""
            
            # Enregistrer le script modifié
            Set-Content -Path $script:testScriptPath -Value $modifiedContent
            
            # Modifier le script ensure-hygen-structure.ps1 pour les tests
            $ensureStructureContent = Get-Content -Path $script:testEnsureStructurePath -Raw
            
            # Remplacer les chemins de dossiers pour les tests
            $modifiedEnsureStructureContent = $ensureStructureContent -replace "n8n/", "$($script:tempFolder -replace '\\', '/')/n8n/"
            
            # Enregistrer le script modifié
            Set-Content -Path $script:testEnsureStructurePath -Value $modifiedEnsureStructureContent
        }

        AfterAll {
            # Supprimer le dossier temporaire
            Remove-TestFolder -Path $script:tempFolder
        }

        It "Should have the install-hygen.ps1 script" {
            Test-Path -Path $script:installHygenPath | Should -Be $true
        }

        It "Should execute without errors" {
            # Exécuter le script avec WhatIf
            & $script:testScriptPath -WhatIf
            
            # Vérifier que le script s'exécute sans erreur
            $LASTEXITCODE | Should -Be 0
        }

        It "Should call ensure-hygen-structure.ps1" {
            # Exécuter le script
            $output = & $script:testScriptPath 2>&1
            
            # Vérifier que le script s'exécute sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # Vérifier que les dossiers ont été créés
            Test-Path -Path "$($script:tempFolder)/n8n/automation" | Should -Be $true
        }
    }
}
