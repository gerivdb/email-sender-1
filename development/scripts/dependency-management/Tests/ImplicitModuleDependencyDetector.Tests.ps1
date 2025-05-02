#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires Pester pour le module ImplicitModuleDependencyDetector.

.DESCRIPTION
    Ce script contient des tests unitaires Pester pour le module ImplicitModuleDependencyDetector
    qui détecte les modules requis implicitement dans les scripts PowerShell.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-12-15
#>

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ImplicitModuleDependencyDetector.psm1"
Write-Host "Module path: $modulePath"

Describe "ImplicitModuleDependencyDetector" {
    BeforeAll {

        # Créer un script PowerShell de test avec différentes références
        $script:sampleCode = @'
# Script avec des références à différents modules

# Import explicite du module ActiveDirectory
Import-Module ActiveDirectory

# Références à Active Directory
$user = [Microsoft.ActiveDirectory.Management.ADUser]::new()
$group = Get-ADGroup -Identity "Domain Admins"
$settings = $ADServerSettings

# Références à Azure sans import
$vm = [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]::new()
$network = [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]::new()
Get-AzVM -Name "MyVM"
Start-AzVM -Name "MyVM" -ResourceGroupName "MyRG"
$context = $AzContext

# Références à Pester sans import
Describe "Test Suite" {
    Context "Test Context" {
        It "Should pass" {
            $true | Should -Be $true
        }
    }
}
$config = $PesterPreference

# Références à dbatools sans import (une seule référence)
$backupHistory = [Sqlcollaborative.Dbatools.Database.BackupHistory]::new()

# Références à PSScriptAnalyzer sans import (une seule référence)
Invoke-ScriptAnalyzer -Path "C:\Scripts\MyScript.ps1"
'@

        # Créer un fichier temporaire pour les tests
        $script:tempDir = Join-Path -Path $env:TEMP -ChildPath "ImplicitModuleDependencyTests_$(Get-Random)"
        New-Item -Path $script:tempDir -ItemType Directory -Force | Out-Null
        $script:tempFile = Join-Path -Path $script:tempDir -ChildPath "TestScript.ps1"
        Set-Content -Path $script:tempFile -Value $script:sampleCode -Force
    }

    AfterAll {
        # Supprimer le répertoire temporaire et son contenu
        if (Test-Path -Path $script:tempDir) {
            Remove-Item -Path $script:tempDir -Recurse -Force
        }
    }

    Context "Find-CmdletWithoutExplicitImport" {
        It "Devrait détecter les cmdlets sans import explicite" {
            $results = Find-CmdletWithoutExplicitImport -ScriptContent $script:sampleCode
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
        }

        It "Devrait détecter les cmdlets Azure sans import" {
            $results = Find-CmdletWithoutExplicitImport -ScriptContent $script:sampleCode
            $azCmdlets = $results | Where-Object { $_.ModuleName -like "Az.*" }
            $azCmdlets | Should -Not -BeNullOrEmpty
            $azCmdlets.Count | Should -BeGreaterThan 0
            $azCmdlets.CmdletName | Should -Contain "Get-AzVM"
            $azCmdlets.CmdletName | Should -Contain "Start-AzVM"
        }

        It "Ne devrait pas détecter les cmdlets ActiveDirectory comme non importées" {
            $results = Find-CmdletWithoutExplicitImport -ScriptContent $script:sampleCode
            $adCmdlets = $results | Where-Object { $_.ModuleName -eq "ActiveDirectory" }
            $adCmdlets | Should -BeNullOrEmpty
        }

        It "Devrait détecter les cmdlets Pester sans import" {
            $results = Find-CmdletWithoutExplicitImport -ScriptContent $script:sampleCode
            $pesterCmdlets = $results | Where-Object { $_.ModuleName -eq "Pester" }
            $pesterCmdlets | Should -Not -BeNullOrEmpty
            $pesterCmdlets.Count | Should -BeGreaterThan 0
            $pesterCmdlets.CmdletName | Should -Contain "Describe"
            $pesterCmdlets.CmdletName | Should -Contain "Context"
            $pesterCmdlets.CmdletName | Should -Contain "It"
            $pesterCmdlets.CmdletName | Should -Contain "Should"
        }

        It "Devrait détecter les cmdlets PSScriptAnalyzer sans import" {
            $results = Find-CmdletWithoutExplicitImport -ScriptContent $script:sampleCode
            $psaCmdlets = $results | Where-Object { $_.ModuleName -eq "PSScriptAnalyzer" }
            $psaCmdlets | Should -Not -BeNullOrEmpty
            $psaCmdlets.Count | Should -BeGreaterThan 0
            $psaCmdlets.CmdletName | Should -Contain "Invoke-ScriptAnalyzer"
        }

        It "Devrait détecter toutes les cmdlets avec le paramètre IncludeImportedModules" {
            $results = Find-CmdletWithoutExplicitImport -ScriptContent $script:sampleCode -IncludeImportedModules
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0

            # Vérifier que les cmdlets des modules importés sont incluses
            $adCmdlets = $results | Where-Object { $_.ModuleName -eq "ActiveDirectory" }
            $adCmdlets | Should -Not -BeNullOrEmpty
            $adCmdlets.IsImported | Should -Be $true
            $adCmdlets.CmdletName | Should -Contain "Get-ADGroup"
        }

        It "Devrait fonctionner avec un fichier comme entrée" {
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
        It "Devrait détecter les types .NET sans import explicite" {
            $results = Find-DotNetTypeWithoutExplicitImport -ScriptContent $script:sampleCode
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
        }

        It "Devrait détecter les types Azure sans import" {
            $results = Find-DotNetTypeWithoutExplicitImport -ScriptContent $script:sampleCode
            $azTypes = $results | Where-Object { $_.ModuleName -like "Az.*" }
            $azTypes | Should -Not -BeNullOrEmpty
            $azTypes.Count | Should -BeGreaterThan 0
            $azTypes.TypeName | Should -Contain "Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine"
            $azTypes.TypeName | Should -Contain "Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork"
        }

        It "Ne devrait pas détecter les types ActiveDirectory comme non importés" {
            $results = Find-DotNetTypeWithoutExplicitImport -ScriptContent $script:sampleCode
            $adTypes = $results | Where-Object { $_.ModuleName -eq "ActiveDirectory" }
            $adTypes | Should -BeNullOrEmpty
        }

        It "Devrait détecter les types dbatools sans import" {
            $results = Find-DotNetTypeWithoutExplicitImport -ScriptContent $script:sampleCode
            $dbaTypes = $results | Where-Object { $_.ModuleName -eq "dbatools" }
            $dbaTypes | Should -Not -BeNullOrEmpty
            $dbaTypes.Count | Should -BeGreaterThan 0
            $dbaTypes.TypeName | Should -Contain "Sqlcollaborative.Dbatools.Database.BackupHistory"
        }

        It "Devrait détecter tous les types avec le paramètre IncludeImportedModules" {
            $results = Find-DotNetTypeWithoutExplicitImport -ScriptContent $script:sampleCode -IncludeImportedModules
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0

            # Vérifier que les types des modules importés sont inclus
            $adTypes = $results | Where-Object { $_.ModuleName -eq "ActiveDirectory" }
            $adTypes | Should -Not -BeNullOrEmpty
            $adTypes.IsImported | Should -Be $true
            $adTypes.TypeName | Should -Contain "Microsoft.ActiveDirectory.Management.ADUser"
        }

        It "Devrait fonctionner avec un fichier comme entrée" {
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
        It "Devrait détecter les variables globales sans import explicite" {
            $results = Find-GlobalVariableWithoutExplicitImport -ScriptContent $script:sampleCode
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
        }

        It "Devrait détecter les variables Azure sans import" {
            $results = Find-GlobalVariableWithoutExplicitImport -ScriptContent $script:sampleCode
            $azVariables = $results | Where-Object { $_.ModuleName -like "Az.*" }
            $azVariables | Should -Not -BeNullOrEmpty
            $azVariables.Count | Should -BeGreaterThan 0
            $azVariables.VariableName | Should -Contain "AzContext"
        }

        It "Ne devrait pas détecter les variables ActiveDirectory comme non importées" {
            $results = Find-GlobalVariableWithoutExplicitImport -ScriptContent $script:sampleCode
            $adVariables = $results | Where-Object { $_.ModuleName -eq "ActiveDirectory" }
            $adVariables | Should -BeNullOrEmpty
        }

        It "Devrait détecter les variables Pester sans import" {
            $results = Find-GlobalVariableWithoutExplicitImport -ScriptContent $script:sampleCode
            $pesterVariables = $results | Where-Object { $_.ModuleName -eq "Pester" }
            $pesterVariables | Should -Not -BeNullOrEmpty
            $pesterVariables.Count | Should -BeGreaterThan 0
            $pesterVariables.VariableName | Should -Contain "PesterPreference"
        }

        It "Devrait détecter toutes les variables avec le paramètre IncludeImportedModules" {
            $results = Find-GlobalVariableWithoutExplicitImport -ScriptContent $script:sampleCode -IncludeImportedModules
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0

            # Vérifier que les variables des modules importés sont incluses
            $adVariables = $results | Where-Object { $_.ModuleName -eq "ActiveDirectory" }
            $adVariables | Should -Not -BeNullOrEmpty
            $adVariables.IsImported | Should -Be $true
            $adVariables.VariableName | Should -Contain "ADServerSettings"
        }

        It "Devrait fonctionner avec un fichier comme entrée" {
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
            # Préparer les données pour les tests
            $script:cmdletReferences = Find-CmdletWithoutExplicitImport -ScriptContent $script:sampleCode -IncludeImportedModules
            $script:typeReferences = Find-DotNetTypeWithoutExplicitImport -ScriptContent $script:sampleCode -IncludeImportedModules
            $script:variableReferences = Find-GlobalVariableWithoutExplicitImport -ScriptContent $script:sampleCode -IncludeImportedModules
        }

        It "Devrait calculer des scores pour les modules détectés" {
            $results = Get-ModuleDependencyScore -CmdletReferences $script:cmdletReferences -TypeReferences $script:typeReferences -VariableReferences $script:variableReferences
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
            $results[0].Score | Should -BeGreaterThan 0
        }

        It "Devrait trier les résultats par score décroissant" {
            $results = Get-ModuleDependencyScore -CmdletReferences $script:cmdletReferences -TypeReferences $script:typeReferences -VariableReferences $script:variableReferences
            $scores = $results | Select-Object -ExpandProperty Score
            $sortedScores = $scores | Sort-Object -Descending
            $scores | Should -Be $sortedScores
        }

        It "Devrait marquer les modules avec un score supérieur au seuil comme probablement requis" {
            $threshold = 0.5
            $results = Get-ModuleDependencyScore -CmdletReferences $script:cmdletReferences -TypeReferences $script:typeReferences -VariableReferences $script:variableReferences -ScoreThreshold $threshold
            $requiredModules = $results | Where-Object { $_.IsProbablyRequired }
            $requiredModules | Should -Not -BeNullOrEmpty
            $requiredModules | ForEach-Object { $_.Score | Should -BeGreaterOrEqual $threshold }
        }

        It "Devrait inclure les détails du calcul du score si demandé" {
            $results = Get-ModuleDependencyScore -CmdletReferences $script:cmdletReferences -TypeReferences $script:typeReferences -VariableReferences $script:variableReferences -IncludeDetails
            $results | Should -Not -BeNullOrEmpty
            $results[0].PSObject.Properties.Name | Should -Contain "BaseScore"
            $results[0].PSObject.Properties.Name | Should -Contain "WeightedScore"
            $results[0].PSObject.Properties.Name | Should -Contain "DiversityScore"
        }

        It "Devrait retourner un tableau vide si aucune référence n'est fournie" {
            $results = Get-ModuleDependencyScore -ErrorAction SilentlyContinue
            $results | Should -BeNullOrEmpty
        }
    }

    Context "Find-ImplicitModuleDependency" {
        It "Devrait détecter les dépendances implicites dans un script" {
            $results = Find-ImplicitModuleDependency -ScriptContent $script:sampleCode
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
        }

        It "Devrait détecter les modules Azure comme dépendances" {
            $results = Find-ImplicitModuleDependency -ScriptContent $script:sampleCode
            $azModules = $results | Where-Object { $_.ModuleName -like "Az.*" }
            $azModules | Should -Not -BeNullOrEmpty
            $azModules.Count | Should -BeGreaterThan 0
        }

        It "Devrait détecter Pester comme dépendance" {
            $results = Find-ImplicitModuleDependency -ScriptContent $script:sampleCode
            $pesterModule = $results | Where-Object { $_.ModuleName -eq "Pester" }
            $pesterModule | Should -Not -BeNullOrEmpty
            $pesterModule.Count | Should -Be 1
        }

        It "Devrait fonctionner avec un fichier comme entrée" {
            $results = Find-ImplicitModuleDependency -FilePath $script:tempFile
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
        }

        It "Devrait retourner un tableau vide pour un fichier inexistant" {
            $results = Find-ImplicitModuleDependency -FilePath "C:\NonExistentFile.ps1" -ErrorAction SilentlyContinue
            $results | Should -BeNullOrEmpty
        }

        It "Devrait inclure les détails du calcul du score si demandé" {
            $results = Find-ImplicitModuleDependency -ScriptContent $script:sampleCode -IncludeDetails
            $results | Should -Not -BeNullOrEmpty
            $results[0].PSObject.Properties.Name | Should -Contain "BaseScore"
            $results[0].PSObject.Properties.Name | Should -Contain "WeightedScore"
            $results[0].PSObject.Properties.Name | Should -Contain "DiversityScore"
        }

        It "Devrait appliquer le seuil de score spécifié" {
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
            # Créer un répertoire temporaire pour les tests
            $script:tempDir = Join-Path -Path $env:TEMP -ChildPath "ModuleMappingTests_$(Get-Random)"
            New-Item -Path $script:tempDir -ItemType Directory -Force | Out-Null

            # Définir les chemins des fichiers de test
            $script:databasePath = Join-Path -Path $script:tempDir -ChildPath "ModuleMapping.psd1"
            $script:updatedDatabasePath = Join-Path -Path $script:tempDir -ChildPath "ModuleMapping_Updated.psd1"
        }

        AfterAll {
            # Nettoyer
            if (Test-Path -Path $script:tempDir) {
                Remove-Item -Path $script:tempDir -Recurse -Force
            }
        }

        It "New-ModuleMappingDatabase devrait créer une base de données de correspondance" {
            $moduleNames = @("Microsoft.PowerShell.Management", "Microsoft.PowerShell.Utility")
            New-ModuleMappingDatabase -ModuleNames $moduleNames -OutputPath $script:databasePath -IncludeCmdlets -IncludeTypes:$false -IncludeVariables:$false | Out-Null

            Test-Path -Path $script:databasePath | Should -Be $true
            $content = Get-Content -Path $script:databasePath -Raw
            $content | Should -Match "CmdletToModuleMapping"
            $content | Should -Match "TypeToModuleMapping"
            $content | Should -Match "VariableToModuleMapping"
        }

        It "Update-ModuleMappingDatabase devrait mettre à jour une base de données existante" {
            $additionalModules = @("Microsoft.PowerShell.Security")
            Update-ModuleMappingDatabase -DatabasePath $script:databasePath -ModuleNames $additionalModules -OutputPath $script:updatedDatabasePath | Out-Null

            Test-Path -Path $script:updatedDatabasePath | Should -Be $true
            $content = Get-Content -Path $script:updatedDatabasePath -Raw
            $content | Should -Match "Microsoft.PowerShell.Security"
        }

        It "Import-ModuleMappingDatabase devrait importer une base de données" {
            # Cette fonction est difficile à tester car elle modifie des variables de script
            # Nous vérifions simplement qu'elle ne génère pas d'erreur
            { Import-ModuleMappingDatabase -DatabasePath $script:updatedDatabasePath -UpdateGlobalMappings:$false } | Should -Not -Throw
        }
    }
}
