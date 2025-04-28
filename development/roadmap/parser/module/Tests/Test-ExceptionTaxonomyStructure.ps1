<#
.SYNOPSIS
    Tests pour la structure de taxonomie des exceptions PowerShell.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider la structure de taxonomie
    des exceptions PowerShell dÃ©finie dans ExceptionTaxonomyStructure.ps1.

.NOTES
    Version:        1.0
    Author:         Augment Code
    Creation Date:  2023-06-15
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer le module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\Functions\Private\Debugging\ExceptionTaxonomyStructure.ps1"
. $modulePath

# DÃ©finir les tests
Describe "Tests de la structure de taxonomie des exceptions" {
    Context "CrÃ©ation d'une taxonomie vide" {
        It "Devrait crÃ©er une nouvelle taxonomie vide" {
            $taxonomy = New-ExceptionTaxonomy
            $taxonomy | Should -Not -BeNullOrEmpty
            $taxonomy.Exceptions.Count | Should -Be 0
            $taxonomy.Categories.Count | Should -Be 0
            $taxonomy.Tags.Count | Should -Be 0
            $taxonomy.Modules.Count | Should -Be 0
            $taxonomy.Cmdlets.Count | Should -Be 0
        }
    }
    
    Context "CrÃ©ation d'une entrÃ©e d'exception" {
        It "Devrait crÃ©er une nouvelle entrÃ©e d'exception avec le constructeur minimal" {
            $exception = [ExceptionInfo]::new("System.Exception")
            $exception | Should -Not -BeNullOrEmpty
            $exception.TypeName | Should -Be "System.Exception"
            $exception.ShortName | Should -Be "Exception"
            $exception.Namespace | Should -Be "System"
            $exception.Id | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait crÃ©er une nouvelle entrÃ©e d'exception avec le constructeur complet" {
            $exception = New-ExceptionInfo -TypeName "System.ArgumentException" `
                -Category "Argument" -Severity "Error" `
                -Tags @("Argument", "Validation") -IsPowerShellSpecific $false `
                -ParentType "System.Exception" `
                -DefaultMessage "La valeur fournie pour l'argument n'est pas valide." `
                -ErrorCategory "InvalidArgument" `
                -PossibleCauses @("Valeur d'argument invalide", "Format d'argument incorrect") `
                -ResolutionSteps @("VÃ©rifier la valeur de l'argument", "Consulter la documentation pour les valeurs acceptÃ©es")
            
            $exception | Should -Not -BeNullOrEmpty
            $exception.TypeName | Should -Be "System.ArgumentException"
            $exception.ShortName | Should -Be "ArgumentException"
            $exception.Namespace | Should -Be "System"
            $exception.Category | Should -Be "Argument"
            $exception.Severity | Should -Be "Error"
            $exception.Tags.Count | Should -Be 2
            $exception.Tags[0] | Should -Be "Argument"
            $exception.IsPowerShellSpecific | Should -Be $false
            $exception.ParentType | Should -Be "System.Exception"
            $exception.DefaultMessage | Should -Be "La valeur fournie pour l'argument n'est pas valide."
            $exception.ErrorCategory | Should -Be "InvalidArgument"
            $exception.PossibleCauses.Count | Should -Be 2
            $exception.ResolutionSteps.Count | Should -Be 2
        }
    }
    
    Context "Ajout d'exceptions Ã  la taxonomie" {
        BeforeAll {
            $taxonomy = New-ExceptionTaxonomy
            
            $baseException = New-ExceptionInfo -TypeName "System.Exception" -Category "General" -Severity "Error" `
                -Tags @("Base", "Common") -IsPowerShellSpecific $false `
                -DefaultMessage "Une exception s'est produite." `
                -ErrorCategory "NotSpecified" `
                -PossibleCauses @("Erreur gÃ©nÃ©rique", "Exception non gÃ©rÃ©e") `
                -ResolutionSteps @("VÃ©rifier le message d'erreur pour plus de dÃ©tails", "Consulter la stack trace")
            
            $argumentException = New-ExceptionInfo -TypeName "System.ArgumentException" -Category "Argument" -Severity "Error" `
                -Tags @("Argument", "Validation") -IsPowerShellSpecific $false `
                -ParentType "System.Exception" `
                -DefaultMessage "La valeur fournie pour l'argument n'est pas valide." `
                -ErrorCategory "InvalidArgument" `
                -PossibleCauses @("Valeur d'argument invalide", "Format d'argument incorrect") `
                -ResolutionSteps @("VÃ©rifier la valeur de l'argument", "Consulter la documentation pour les valeurs acceptÃ©es")
            
            Add-ExceptionToTaxonomy -Taxonomy $taxonomy -Exception $baseException
            Add-ExceptionToTaxonomy -Taxonomy $taxonomy -Exception $argumentException
            
            # Mettre Ã  jour les relations parent-enfant
            $baseException.ChildTypes = @("System.ArgumentException")
            $baseException.HierarchyLevel = 0
            $argumentException.HierarchyLevel = 1
        }
        
        It "Devrait ajouter des exceptions Ã  la taxonomie" {
            $taxonomy.Exceptions.Count | Should -Be 2
            $taxonomy.Exceptions.ContainsKey("System.Exception") | Should -Be $true
            $taxonomy.Exceptions.ContainsKey("System.ArgumentException") | Should -Be $true
        }
        
        It "Devrait organiser les exceptions par catÃ©gorie" {
            $taxonomy.Categories.Count | Should -Be 2
            $taxonomy.Categories.ContainsKey("General") | Should -Be $true
            $taxonomy.Categories.ContainsKey("Argument") | Should -Be $true
            $taxonomy.Categories["General"].Count | Should -Be 1
            $taxonomy.Categories["Argument"].Count | Should -Be 1
        }
        
        It "Devrait organiser les exceptions par tag" {
            $taxonomy.Tags.Count | Should -Be 3
            $taxonomy.Tags.ContainsKey("Base") | Should -Be $true
            $taxonomy.Tags.ContainsKey("Common") | Should -Be $true
            $taxonomy.Tags.ContainsKey("Argument") | Should -Be $true
            $taxonomy.Tags["Base"].Count | Should -Be 1
            $taxonomy.Tags["Argument"].Count | Should -Be 1
        }
        
        It "Devrait rÃ©cupÃ©rer une exception par son type" {
            $exception = $taxonomy.GetExceptionByType("System.Exception")
            $exception | Should -Not -BeNullOrEmpty
            $exception.TypeName | Should -Be "System.Exception"
        }
        
        It "Devrait rÃ©cupÃ©rer des exceptions par catÃ©gorie" {
            $exceptions = $taxonomy.GetExceptionsByCategory("Argument")
            $exceptions | Should -Not -BeNullOrEmpty
            $exceptions.Count | Should -Be 1
            $exceptions[0].TypeName | Should -Be "System.ArgumentException"
        }
        
        It "Devrait rÃ©cupÃ©rer des exceptions par tag" {
            $exceptions = $taxonomy.GetExceptionsByTag("Base")
            $exceptions | Should -Not -BeNullOrEmpty
            $exceptions.Count | Should -Be 1
            $exceptions[0].TypeName | Should -Be "System.Exception"
        }
        
        It "Devrait rÃ©cupÃ©rer des exceptions par sÃ©vÃ©ritÃ©" {
            $exceptions = $taxonomy.GetExceptionsBySeverity("Error")
            $exceptions | Should -Not -BeNullOrEmpty
            $exceptions.Count | Should -Be 2
        }
        
        It "Devrait rÃ©cupÃ©rer la hiÃ©rarchie d'une exception" {
            $hierarchy = $taxonomy.GetExceptionHierarchy("System.ArgumentException")
            $hierarchy | Should -Not -BeNullOrEmpty
            $hierarchy.Parent | Should -Not -BeNullOrEmpty
            $hierarchy.Parent.TypeName | Should -Be "System.Exception"
            $hierarchy.Current | Should -Not -BeNullOrEmpty
            $hierarchy.Current.TypeName | Should -Be "System.ArgumentException"
            $hierarchy.Children.Count | Should -Be 0
        }
    }
    
    Context "Exemple de taxonomie" {
        It "Devrait crÃ©er un exemple de taxonomie avec des exceptions de base" {
            $taxonomy = Get-ExampleExceptionTaxonomy
            $taxonomy | Should -Not -BeNullOrEmpty
            $taxonomy.Exceptions.Count | Should -Be 4
            $taxonomy.Categories.Count | Should -Be 3
            $taxonomy.Tags.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier la prÃ©sence des exceptions de base
            $taxonomy.Exceptions.ContainsKey("System.Exception") | Should -Be $true
            $taxonomy.Exceptions.ContainsKey("System.ArgumentException") | Should -Be $true
            $taxonomy.Exceptions.ContainsKey("System.ArgumentNullException") | Should -Be $true
            $taxonomy.Exceptions.ContainsKey("System.IO.IOException") | Should -Be $true
            
            # VÃ©rifier la hiÃ©rarchie
            $baseException = $taxonomy.GetExceptionByType("System.Exception")
            $baseException.ChildTypes.Count | Should -Be 3
            
            $argException = $taxonomy.GetExceptionByType("System.ArgumentException")
            $argException.ParentType | Should -Be "System.Exception"
            $argException.ChildTypes.Count | Should -Be 1
            
            $argNullException = $taxonomy.GetExceptionByType("System.ArgumentNullException")
            $argNullException.ParentType | Should -Be "System.ArgumentException"
        }
    }
    
    Context "Exportation et importation" {
        It "Devrait exporter et importer une taxonomie au format JSON" {
            # CrÃ©er une taxonomie
            $taxonomy = Get-ExampleExceptionTaxonomy
            
            # Exporter vers JSON
            $jsonContent = $taxonomy.ExportToJson()
            $jsonContent | Should -Not -BeNullOrEmpty
            
            # CrÃ©er une nouvelle taxonomie et importer le JSON
            $newTaxonomy = New-ExceptionTaxonomy
            $newTaxonomy.ImportFromJson($jsonContent)
            
            # VÃ©rifier que l'importation a fonctionnÃ©
            $newTaxonomy.Exceptions.Count | Should -Be $taxonomy.Exceptions.Count
            $newTaxonomy.Categories.Count | Should -Be $taxonomy.Categories.Count
            $newTaxonomy.Tags.Count | Should -Be $taxonomy.Tags.Count
            
            # VÃ©rifier la prÃ©sence des exceptions
            $newTaxonomy.Exceptions.ContainsKey("System.Exception") | Should -Be $true
            $newTaxonomy.Exceptions.ContainsKey("System.ArgumentException") | Should -Be $true
            $newTaxonomy.Exceptions.ContainsKey("System.ArgumentNullException") | Should -Be $true
            $newTaxonomy.Exceptions.ContainsKey("System.IO.IOException") | Should -Be $true
        }
        
        It "Devrait exporter et importer une taxonomie vers/depuis un fichier" {
            # CrÃ©er une taxonomie
            $taxonomy = Get-ExampleExceptionTaxonomy
            
            # CrÃ©er un fichier temporaire
            $tempFile = [System.IO.Path]::GetTempFileName()
            
            try {
                # Exporter vers le fichier
                Export-ExceptionTaxonomy -Taxonomy $taxonomy -FilePath $tempFile
                
                # VÃ©rifier que le fichier existe
                Test-Path -Path $tempFile | Should -Be $true
                
                # Importer depuis le fichier
                $importedTaxonomy = Import-ExceptionTaxonomy -FilePath $tempFile
                
                # VÃ©rifier que l'importation a fonctionnÃ©
                $importedTaxonomy.Exceptions.Count | Should -Be $taxonomy.Exceptions.Count
                $importedTaxonomy.Categories.Count | Should -Be $taxonomy.Categories.Count
                $importedTaxonomy.Tags.Count | Should -Be $taxonomy.Tags.Count
                
                # VÃ©rifier la prÃ©sence des exceptions
                $importedTaxonomy.Exceptions.ContainsKey("System.Exception") | Should -Be $true
                $importedTaxonomy.Exceptions.ContainsKey("System.ArgumentException") | Should -Be $true
                $importedTaxonomy.Exceptions.ContainsKey("System.ArgumentNullException") | Should -Be $true
                $importedTaxonomy.Exceptions.ContainsKey("System.IO.IOException") | Should -Be $true
            }
            finally {
                # Supprimer le fichier temporaire
                if (Test-Path -Path $tempFile) {
                    Remove-Item -Path $tempFile -Force
                }
            }
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
