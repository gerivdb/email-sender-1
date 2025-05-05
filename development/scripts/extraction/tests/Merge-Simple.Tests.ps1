#Requires -Version 5.1
<#
.SYNOPSIS
Tests unitaires simplifiés pour la fonction Merge-ExtractedInfo.

.DESCRIPTION
Ce script contient des tests unitaires simplifiés pour la fonction Merge-ExtractedInfo
qui permet de fusionner deux ou plusieurs objets d'information extraite.

.NOTES
Date de création : 2025-05-15
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Les tests ne peuvent pas être exécutés."
    return
}

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force

# Importer les fonctions auxiliaires directement
$mergePath = Join-Path -Path $PSScriptRoot -ChildPath "..\Public\Merge"
. (Join-Path -Path $mergePath -ChildPath "Test-ExtractedInfoCompatibility.ps1")
. (Join-Path -Path $mergePath -ChildPath "Merge-ExtractedInfoMetadata.ps1")
. (Join-Path -Path $mergePath -ChildPath "Get-MergedConfidenceScore.ps1")
. (Join-Path -Path $mergePath -ChildPath "Merge-ExtractedInfo.ps1")

# Démarrer les tests Pester
Describe "Merge-ExtractedInfo-Simple" {
    Context "Test-ExtractedInfoCompatibility" {
        It "Devrait vérifier la compatibilité de deux objets" {
            # Créer deux objets simples
            $info1 = @{
                _Type = "TestExtractedInfo"
                Id = "1"
                Source = "test.txt"
            }
            
            $info2 = @{
                _Type = "TestExtractedInfo"
                Id = "2"
                Source = "test.txt"
            }
            
            $result = Test-ExtractedInfoCompatibility -Info1 $info1 -Info2 $info2
            $result.IsCompatible | Should -Be $true
        }
    }
    
    Context "Merge-ExtractedInfoMetadata" {
        It "Devrait fusionner deux ensembles de métadonnées" {
            $metadata1 = @{
                Author = "John"
                Category = "Test"
            }
            
            $metadata2 = @{
                Author = "Jane"
                Tags = @("test")
            }
            
            $result = Merge-ExtractedInfoMetadata -Metadata1 $metadata1 -Metadata2 $metadata2 -MergeStrategy "LastWins"
            $result.Author | Should -Be "Jane"
            $result.Category | Should -Be "Test"
            $result.Tags | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-MergedConfidenceScore" {
        It "Devrait calculer un score de confiance fusionné" {
            $scores = @(80, 90)
            $result = Get-MergedConfidenceScore -ConfidenceScores $scores -Method "Average"
            $result | Should -Be 85
        }
    }
    
    Context "Merge-ExtractedInfo" {
        It "Devrait fusionner deux objets simples" {
            # Créer deux objets simples
            $info1 = @{
                _Type = "TestExtractedInfo"
                Id = "1"
                Source = "test.txt"
                Text = "Texte 1"
                ConfidenceScore = 80
                Metadata = @{
                    Author = "John"
                }
            }
            
            $info2 = @{
                _Type = "TestExtractedInfo"
                Id = "2"
                Source = "test.txt"
                Text = "Texte 2"
                ConfidenceScore = 90
                Metadata = @{
                    Author = "Jane"
                }
            }
            
            $result = Merge-ExtractedInfo -PrimaryInfo $info1 -SecondaryInfo $info2 -MergeStrategy "LastWins"
            $result._Type | Should -Be "TestExtractedInfo"
            $result.Text | Should -Be "Texte 2"
            $result.ConfidenceScore | Should -BeGreaterThan 80
        }
    }
}
