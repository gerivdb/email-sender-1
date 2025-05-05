#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires Pester pour le module ImplicitModuleDependencyDetector.

.DESCRIPTION
    Ce script contient des tests unitaires Pester pour le module ImplicitModuleDependencyDetector
    qui dÃ©tecte les modules requis implicitement dans les scripts PowerShell.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-12-15
#>

# Importer le module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ImplicitModuleDependencyDetector.psm1"
Write-Host "Module path: $modulePath"

Describe "ImplicitModuleDependencyDetector" {
    BeforeAll {

        # CrÃ©er un script PowerShell de test avec diffÃ©rentes rÃ©fÃ©rences
        $script:sampleCode = @'
# Script avec des rÃ©fÃ©rences Ã  diffÃ©rents modules

# Import explicite du module ActiveDirectory
Import-Module ActiveDirectory

# RÃ©fÃ©rences Ã  Active Directory
$user = [Microsoft.ActiveDirectory.Management.ADUser]::new()
$group = Get-ADGroup -Identity "Domain Admins"
$settings = $ADServerSettings

# RÃ©fÃ©rences Ã  Azure sans import
$vm = [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]::new()
$network = [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]::new()
Get-AzVM -Name "MyVM"
Start-AzVM -Name "MyVM" -ResourceGroupName "MyRG"
$context = $AzContext

# RÃ©fÃ©rences Ã  Pester sans import
Describe "Test Suite" {
    Context "Test Context" {
        It "Should pass" {
            $true | Should -Be $true
        }
    }
}
$config = $PesterPreference

# RÃ©fÃ©rences Ã  dbatools sans import (une seule rÃ©fÃ©rence)
$backupHistory = [Sqlcollaborative.Dbatools.Database.BackupHistory]::new()

# RÃ©fÃ©rences Ã  PSScriptAnalyzer sans import (une seule rÃ©fÃ©rence)
Invoke-ScriptAnalyzer -Path "C:\Scripts\MyScript.ps1"
'@

        # CrÃ©er un fichier temporaire pour les tests
        $script:tempDir = Join-Path -Path $env:TEMP -ChildPath "ImplicitModuleDependencyTests_$(Get-Random)"
        New-Item -Path $script:tempDir -ItemType Directory -Force | Out-Null
        $script:tempFile = Join-Path -Path $script:tempDir -ChildPath "TestScript.ps1"
        Set-Content -Path $script:tempFile -Value $script:sampleCode -Force
    }

    AfterAll {
        # Supprimer le rÃ©pertoire temporaire et son contenu
        if (Test-Path -Path $script:tempDir) {
            Remove-Item -Path $script:tempDir -Recurse -Force
        }
    }

    Context "Find-CmdletWithoutExplicitImport" {
        It "Devrait dÃ©tecter les cmdlets sans import explicite" {
            $results = Find-CmdletWithoutExplicitImport -ScriptContent $script:sampleCode
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
        }

        It "Devrait dÃ©tecter les cmdlets Azure sans import" {
            $results = Find-CmdletWithoutExplicitImport -ScriptContent $script:sampleCode
            $azCmdlets = $results | Where-Object { $_.ModuleName -like "Az.*" }
            $azCmdlets | Should -Not -BeNullOrEmpty
            $azCmdlets.Count | Should -BeGreaterThan 0
            $azCmdlets.CmdletName | Should -Contain "Get-AzVM"
            $azCmdlets.CmdletName | Should -Contain "Start-AzVM"
        }

        It "Ne devrait pas dÃ©tecter les cmdlets ActiveDirectory comme non importÃ©es" {
            $results = Find-CmdletWithoutExplicitImport -ScriptContent $script:sampleCode
            $adCmdlets = $results | Where-Object { $_.ModuleName -eq "ActiveDirectory" }
            $adCmdlets | Should -BeNullOrEmpty
        }

        It "Devrait dÃ©tecter les cmdlets Pester sans import" {
            $results = Find-CmdletWithoutExplicitImport -ScriptContent $script:sampleCode
            $pesterCmdlets = $results | Where-Object { $_.ModuleName -eq "Pester" }
            $pesterCmdlets | Should -Not -BeNullOrEmpty
            $pesterCmdlets.Count | Should -BeGreaterThan 0
            $pesterCmdlets.CmdletName | Should -Contain "Describe"
            $pesterCmdlets.CmdletName | Should -Contain "Context"
            $pesterCmdlets.CmdletName | Should -Contain "It"
            $pesterCmdlets.CmdletName | Should -Contain "Should"
        }

        It "Devrait dÃ©tecter les cmdlets PSScriptAnalyzer sans import" {
            $results = Find-CmdletWithoutExplicitImport -ScriptContent $script:sampleCode
            $psaCmdlets = $results | Where-Object { $_.ModuleName -eq "PSScriptAnalyzer" }
            $psaCmdlets | Should -Not -BeNullOrEmpty
            $psaCmdlets.Count | Should -BeGreaterThan 0
            $psaCmdlets.CmdletName | Should -Contain "Invoke-ScriptAnalyzer"
        }

        It "Devrait dÃ©tecter toutes les cmdlets avec le paramÃ¨tre IncludeImportedModules" {
            $results = Find-CmdletWithoutExplicitImport -ScriptContent $script:sampleCode -IncludeImportedModules
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0

            # VÃ©rifier que les cmdlets des modules importÃ©s sont incluses
            $adCmdlets = $results | Where-Object { $_.ModuleName -eq "ActiveDirectory" }
            $adCmdlets | Should -Not -BeNullOrEmpty
            $adCmdlets.IsImported | Should -Be $true
            $adCmdlets.CmdletName | Should -Contain "Get-ADGroup"
        }

        It "Devrait fonctionner avec un fichier comme entrÃ©e" {
            $results = Find-CmdletWithoutExplicitImport -FilePath $script:tempFile
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
        }

        It "Devrait retourner un tableau vide pour un fichier inexistant" {
            $results = Find-CmdletWithoutExplicitImport -FilePath "C:\NonExistentFile.ps1" -ErrorAction SilentlyContinue
            $results | Should -BeNullOrEmpty
        }
    }

    Context "Find-DotNetTypeWithoutExplicitImport" {
        It "Devrait dÃ©tecter les types .NET sans import explicite" {
            $results = Find-DotNetTypeWithoutExplicitImport -ScriptContent $script:sampleCode
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
        }

        It "Devrait dÃ©tecter les types Azure sans import" {
            $results = Find-DotNetTypeWithoutExplicitImport -ScriptContent $script:sampleCode
            $azTypes = $results | Where-Object { $_.ModuleName -like "Az.*" }
            $azTypes | Should -Not -BeNullOrEmpty
            $azTypes.Count | Should -BeGreaterThan 0
            $azTypes.TypeName | Should -Contain "Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine"
            $azTypes.TypeName | Should -Contain "Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork"
        }

        It "Ne devrait pas dÃ©tecter les types ActiveDirectory comme non importÃ©s" {
            $results = Find-DotNetTypeWithoutExplicitImport -ScriptContent $script:sampleCode
            $adTypes = $results | Where-Object { $_.ModuleName -eq "ActiveDirectory" }
            $adTypes | Should -BeNullOrEmpty
        }

        It "Devrait dÃ©tecter les types dbatools sans import" {
            $results = Find-DotNetTypeWithoutExplicitImport -ScriptContent $script:sampleCode
            $dbaTypes = $results | Where-Object { $_.ModuleName -eq "dbatools" }
            $dbaTypes | Should -Not -BeNullOrEmpty
            $dbaTypes.Count | Should -BeGreaterThan 0
            $dbaTypes.TypeName | Should -Contain "Sqlcollaborative.Dbatools.Database.BackupHistory"
        }

        It "Devrait dÃ©tecter tous les types avec le paramÃ¨tre IncludeImportedModules" {
            $results = Find-DotNetTypeWithoutExplicitImport -ScriptContent $script:sampleCode -IncludeImportedModules
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0

            # VÃ©rifier que les types des modules importÃ©s sont inclus
            $adTypes = $results | Where-Object { $_.ModuleName -eq "ActiveDirectory" }
            $adTypes | Should -Not -BeNullOrEmpty
            $adTypes.IsImported | Should -Be $true
            $adTypes.TypeName | Should -Contain "Microsoft.ActiveDirectory.Management.ADUser"
        }

        It "Devrait fonctionner avec un fichier comme entrÃ©e" {
            $results = Find-DotNetTypeWithoutExplicitImport -FilePath $script:tempFile
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
        }

        It "Devrait retourner un tableau vide pour un fichier inexistant" {
            $results = Find-DotNetTypeWithoutExplicitImport -FilePath "C:\NonExistentFile.ps1" -ErrorAction SilentlyContinue
            $results | Should -BeNullOrEmpty
        }
    }

    Context "Find-GlobalVariableWithoutExplicitImport" {
        It "Devrait dÃ©tecter les variables globales sans import explicite" {
            $results = Find-GlobalVariableWithoutExplicitImport -ScriptContent $script:sampleCode
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
        }

        It "Devrait dÃ©tecter les variables Azure sans import" {
            $results = Find-GlobalVariableWithoutExplicitImport -ScriptContent $script:sampleCode
            $azVariables = $results | Where-Object { $_.ModuleName -like "Az.*" }
            $azVariables | Should -Not -BeNullOrEmpty
            $azVariables.Count | Should -BeGreaterThan 0
            $azVariables.VariableName | Should -Contain "AzContext"
        }

        It "Ne devrait pas dÃ©tecter les variables ActiveDirectory comme non importÃ©es" {
            $results = Find-GlobalVariableWithoutExplicitImport -ScriptContent $script:sampleCode
            $adVariables = $results | Where-Object { $_.ModuleName -eq "ActiveDirectory" }
            $adVariables | Should -BeNullOrEmpty
        }

        It "Devrait dÃ©tecter les variables Pester sans import" {
            $results = Find-GlobalVariableWithoutExplicitImport -ScriptContent $script:sampleCode
            $pesterVariables = $results | Where-Object { $_.ModuleName -eq "Pester" }
            $pesterVariables | Should -Not -BeNullOrEmpty
            $pesterVariables.Count | Should -BeGreaterThan 0
            $pesterVariables.VariableName | Should -Contain "PesterPreference"
        }

        It "Devrait dÃ©tecter toutes les variables avec le paramÃ¨tre IncludeImportedModules" {
            $results = Find-GlobalVariableWithoutExplicitImport -ScriptContent $script:sampleCode -IncludeImportedModules
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0

            # VÃ©rifier que les variables des modules importÃ©s sont incluses
            $adVariables = $results | Where-Object { $_.ModuleName -eq "ActiveDirectory" }
            $adVariables | Should -Not -BeNullOrEmpty
            $adVariables.IsImported | Should -Be $true
            $adVariables.VariableName | Should -Contain "ADServerSettings"
        }

        It "Devrait fonctionner avec un fichier comme entrÃ©e" {
            $results = Find-GlobalVariableWithoutExplicitImport -FilePath $script:tempFile
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
        }

        It "Devrait retourner un tableau vide pour un fichier inexistant" {
            $results = Find-GlobalVariableWithoutExplicitImport -FilePath "C:\NonExistentFile.ps1" -ErrorAction SilentlyContinue
            $results | Should -BeNullOrEmpty
        }
    }

    Context "Get-ModuleDependencyScore" {
        BeforeAll {
            # PrÃ©parer les donnÃ©es pour les tests
            $script:cmdletReferences = Find-CmdletWithoutExplicitImport -ScriptContent $script:sampleCode -IncludeImportedModules
            $script:typeReferences = Find-DotNetTypeWithoutExplicitImport -ScriptContent $script:sampleCode -IncludeImportedModules
            $script:variableReferences = Find-GlobalVariableWithoutExplicitImport -ScriptContent $script:sampleCode -IncludeImportedModules
        }

        It "Devrait calculer des scores pour les modules dÃ©tectÃ©s" {
            $results = Get-ModuleDependencyScore -CmdletReferences $script:cmdletReferences -TypeReferences $script:typeReferences -VariableReferences $script:variableReferences
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
            $results[0].Score | Should -BeGreaterThan 0
        }

        It "Devrait trier les rÃ©sultats par score dÃ©croissant" {
            $results = Get-ModuleDependencyScore -CmdletReferences $script:cmdletReferences -TypeReferences $script:typeReferences -VariableReferences $script:variableReferences
            $scores = $results | Select-Object -ExpandProperty Score
            $sortedScores = $scores | Sort-Object -Descending
            $scores | Should -Be $sortedScores
        }

        It "Devrait marquer les modules avec un score supÃ©rieur au seuil comme probablement requis" {
            $threshold = 0.5
            $results = Get-ModuleDependencyScore -CmdletReferences $script:cmdletReferences -TypeReferences $script:typeReferences -VariableReferences $script:variableReferences -ScoreThreshold $threshold
            $requiredModules = $results | Where-Object { $_.IsProbablyRequired }
            $requiredModules | Should -Not -BeNullOrEmpty
            $requiredModules | ForEach-Object { $_.Score | Should -BeGreaterOrEqual $threshold }
        }

        It "Devrait inclure les dÃ©tails du calcul du score si demandÃ©" {
            $results = Get-ModuleDependencyScore -CmdletReferences $script:cmdletReferences -TypeReferences $script:typeReferences -VariableReferences $script:variableReferences -IncludeDetails
            $results | Should -Not -BeNullOrEmpty
            $results[0].PSObject.Properties.Name | Should -Contain "BaseScore"
            $results[0].PSObject.Properties.Name | Should -Contain "WeightedScore"
            $results[0].PSObject.Properties.Name | Should -Contain "DiversityScore"
        }

        It "Devrait retourner un tableau vide si aucune rÃ©fÃ©rence n'est fournie" {
            $results = Get-ModuleDependencyScore -ErrorAction SilentlyContinue
            $results | Should -BeNullOrEmpty
        }
    }

    Context "Find-ImplicitModuleDependency" {
        It "Devrait dÃ©tecter les dÃ©pendances implicites dans un script" {
            $results = Find-ImplicitModuleDependency -ScriptContent $script:sampleCode
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
        }

        It "Devrait dÃ©tecter les modules Azure comme dÃ©pendances" {
            $results = Find-ImplicitModuleDependency -ScriptContent $script:sampleCode
            $azModules = $results | Where-Object { $_.ModuleName -like "Az.*" }
            $azModules | Should -Not -BeNullOrEmpty
            $azModules.Count | Should -BeGreaterThan 0
        }

        It "Devrait dÃ©tecter Pester comme dÃ©pendance" {
            $results = Find-ImplicitModuleDependency -ScriptContent $script:sampleCode
            $pesterModule = $results | Where-Object { $_.ModuleName -eq "Pester" }
            $pesterModule | Should -Not -BeNullOrEmpty
            $pesterModule.Count | Should -Be 1
        }

        It "Devrait fonctionner avec un fichier comme entrÃ©e" {
            $results = Find-ImplicitModuleDependency -FilePath $script:tempFile
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
        }

        It "Devrait retourner un tableau vide pour un fichier inexistant" {
            $results = Find-ImplicitModuleDependency -FilePath "C:\NonExistentFile.ps1" -ErrorAction SilentlyContinue
            $results | Should -BeNullOrEmpty
        }

        It "Devrait inclure les dÃ©tails du calcul du score si demandÃ©" {
            $results = Find-ImplicitModuleDependency -ScriptContent $script:sampleCode -IncludeDetails
            $results | Should -Not -BeNullOrEmpty
            $results[0].PSObject.Properties.Name | Should -Contain "BaseScore"
            $results[0].PSObject.Properties.Name | Should -Contain "WeightedScore"
            $results[0].PSObject.Properties.Name | Should -Contain "DiversityScore"
        }

        It "Devrait appliquer le seuil de score spÃ©cifiÃ©" {
            $threshold = 0.7
            $results = Find-ImplicitModuleDependency -ScriptContent $script:sampleCode -ScoreThreshold $threshold
            $requiredModules = $results | Where-Object { $_.IsProbablyRequired }
            if ($requiredModules) {
                $requiredModules | ForEach-Object { $_.Score | Should -BeGreaterOrEqual $threshold }
            }
        }
    }

    Context "Module Mapping Database Functions" {
        BeforeAll {
            # CrÃ©er un rÃ©pertoire temporaire pour les tests
            $script:tempDir = Join-Path -Path $env:TEMP -ChildPath "ModuleMappingTests_$(Get-Random)"
            New-Item -Path $script:tempDir -ItemType Directory -Force | Out-Null

            # DÃ©finir les chemins des fichiers de test
            $script:databasePath = Join-Path -Path $script:tempDir -ChildPath "ModuleMapping.psd1"
            $script:updatedDatabasePath = Join-Path -Path $script:tempDir -ChildPath "ModuleMapping_Updated.psd1"
        }

        AfterAll {
            # Nettoyer
            if (Test-Path -Path $script:tempDir) {
                Remove-Item -Path $script:tempDir -Recurse -Force
            }
        }

        It "New-ModuleMappingDatabase devrait crÃ©er une base de donnÃ©es de correspondance" {
            $moduleNames = @("Microsoft.PowerShell.Management", "Microsoft.PowerShell.Utility")
            New-ModuleMappingDatabase -ModuleNames $moduleNames -OutputPath $script:databasePath -IncludeCmdlets -IncludeTypes:$false -IncludeVariables:$false | Out-Null

            Test-Path -Path $script:databasePath | Should -Be $true
            $content = Get-Content -Path $script:databasePath -Raw
            $content | Should -Match "CmdletToModuleMapping"
            $content | Should -Match "TypeToModuleMapping"
            $content | Should -Match "VariableToModuleMapping"
        }

        It "Update-ModuleMappingDatabase devrait mettre Ã  jour une base de donnÃ©es existante" {
            $additionalModules = @("Microsoft.PowerShell.Security")
            Update-ModuleMappingDatabase -DatabasePath $script:databasePath -ModuleNames $additionalModules -OutputPath $script:updatedDatabasePath | Out-Null

            Test-Path -Path $script:updatedDatabasePath | Should -Be $true
            $content = Get-Content -Path $script:updatedDatabasePath -Raw
            $content | Should -Match "Microsoft.PowerShell.Security"
        }

        It "Import-ModuleMappingDatabase devrait importer une base de donnÃ©es" {
            # Cette fonction est difficile Ã  tester car elle modifie des variables de script
            # Nous vÃ©rifions simplement qu'elle ne gÃ©nÃ¨re pas d'erreur
            { Import-ModuleMappingDatabase -DatabasePath $script:updatedDatabasePath -UpdateGlobalMappings:$false } | Should -Not -Throw
        }
    }
}
