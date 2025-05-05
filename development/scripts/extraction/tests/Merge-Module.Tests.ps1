#Requires -Version 5.1
<#
.SYNOPSIS
Tests unitaires basiques pour les fonctions de fusion en utilisant le module complet.

.DESCRIPTION
Ce script contient des tests unitaires basiques pour les fonctions de fusion
en important le module complet.

.NOTES
Date de création : 2025-05-15
#>

# Importer le module complet
Import-Module "$PSScriptRoot\..\ExtractedInfoModuleV2.psm1" -Force

Describe "Test-ExtractedInfoCompatibility" {
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

Describe "Merge-ExtractedInfoMetadata" {
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

Describe "Get-MergedConfidenceScore" {
    It "Devrait calculer un score de confiance fusionné" {
        $scores = @(80, 90)
        $result = Get-MergedConfidenceScore -ConfidenceScores $scores -Method "Average"
        $result | Should -Be 85
    }
}

Describe "Merge-ExtractedInfo" {
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
