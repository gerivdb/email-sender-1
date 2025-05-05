#Requires -Version 5.1
<#
.SYNOPSIS
Tests unitaires pour les fonctions auxiliaires de fusion.

.DESCRIPTION
Ce script contient les tests unitaires pour les fonctions auxiliaires utilisées
par la fonction Merge-ExtractedInfo.

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

# Démarrer les tests Pester
Describe "Test-ExtractedInfoCompatibility" {
    BeforeAll {
        # Créer des objets de test
        $text1 = New-TextExtractedInfo -Source "document.txt" -Text "Texte 1" -Language "fr"
        $text2 = New-TextExtractedInfo -Source "document.txt" -Text "Texte 2" -Language "fr"
        $text3 = New-TextExtractedInfo -Source "autre.txt" -Text "Texte 3" -Language "en"
        $data = New-StructuredDataExtractedInfo -Source "data.json" -Data @{ Key = "Value" } -DataFormat "Hashtable"
        $geo1 = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France"
        $geo2 = New-GeoLocationExtractedInfo -Latitude 40.7128 -Longitude -74.0060 -City "New York" -Country "USA"
        
        $testObjects = @{
            Text1 = $text1
            Text2 = $text2
            Text3 = $text3
            Data = $data
            Geo1 = $geo1
            Geo2 = $geo2
        }
    }
    
    Context "Compatibilité de base" {
        It "Devrait identifier deux objets du même type comme compatibles" {
            $result = Test-ExtractedInfoCompatibility -Info1 $testObjects.Text1 -Info2 $testObjects.Text2
            $result.IsCompatible | Should -Be $true
            $result.CompatibilityLevel | Should -Be 100
        }
        
        It "Devrait identifier deux objets de types différents comme incompatibles" {
            $result = Test-ExtractedInfoCompatibility -Info1 $testObjects.Text1 -Info2 $testObjects.Data
            $result.IsCompatible | Should -Be $false
            $result.CompatibilityLevel | Should -Be 0
        }
        
        It "Devrait permettre la compatibilité forcée entre types différents" {
            $result = Test-ExtractedInfoCompatibility -Info1 $testObjects.Text1 -Info2 $testObjects.Data -Force
            $result.IsCompatible | Should -Be $true
            $result.CompatibilityLevel | Should -BeLessThan 100
        }
    }
    
    Context "Compatibilité des sources" {
        It "Devrait réduire le niveau de compatibilité pour des sources différentes" {
            $result = Test-ExtractedInfoCompatibility -Info1 $testObjects.Text1 -Info2 $testObjects.Text3
            $result.CompatibilityLevel | Should -BeLessThan 100
            $result.Reasons.Count | Should -BeGreaterThan 0
        }
    }
    
    Context "Compatibilité spécifique au type" {
        It "Devrait vérifier la compatibilité des langues pour TextExtractedInfo" {
            $result = Test-ExtractedInfoCompatibility -Info1 $testObjects.Text1 -Info2 $testObjects.Text3
            $result.Reasons | Should -Contain "*langues différentes*"
        }
        
        It "Devrait vérifier la proximité des coordonnées pour GeoLocationExtractedInfo" {
            $result = Test-ExtractedInfoCompatibility -Info1 $testObjects.Geo1 -Info2 $testObjects.Geo2
            $result.Reasons | Should -Contain "*coordonnées géographiques*"
        }
    }
}

Describe "Merge-ExtractedInfoMetadata" {
    BeforeAll {
        # Créer des métadonnées de test
        $metadata1 = @{
            Author = "John Doe"
            Category = "Tech"
            Tags = @("tag1", "tag2")
            Nested = @{
                Key1 = "Value1"
                Key2 = "Value2"
            }
            Count = 10
            IsActive = $true
            Date = [datetime]::Now.AddDays(-5)
        }
        
        $metadata2 = @{
            Author = "Jane Smith"
            Tags = @("tag2", "tag3")
            Nested = @{
                Key2 = "NewValue2"
                Key3 = "Value3"
            }
            Count = 20
            IsActive = $false
            Date = [datetime]::Now
            NewProperty = "New Value"
        }
    }
    
    Context "Stratégie FirstWins" {
        It "Devrait conserver les valeurs du premier objet en cas de conflit" {
            $result = Merge-ExtractedInfoMetadata -Metadata1 $metadata1 -Metadata2 $metadata2 -MergeStrategy "FirstWins"
            $result.Author | Should -Be $metadata1.Author
            $result.ContainsKey("NewProperty") | Should -Be $true
        }
    }
    
    Context "Stratégie LastWins" {
        It "Devrait conserver les valeurs du deuxième objet en cas de conflit" {
            $result = Merge-ExtractedInfoMetadata -Metadata1 $metadata1 -Metadata2 $metadata2 -MergeStrategy "LastWins"
            $result.Author | Should -Be $metadata2.Author
            $result.Category | Should -Be $metadata1.Category
        }
    }
    
    Context "Stratégie HighestConfidence" {
        It "Devrait utiliser les scores de confiance pour déterminer les valeurs à conserver" {
            $result = Merge-ExtractedInfoMetadata -Metadata1 $metadata1 -Metadata2 $metadata2 -MergeStrategy "HighestConfidence" -ConfidenceScore1 80 -ConfidenceScore2 60
            $result.Author | Should -Be $metadata1.Author
            
            $result2 = Merge-ExtractedInfoMetadata -Metadata1 $metadata1 -Metadata2 $metadata2 -MergeStrategy "HighestConfidence" -ConfidenceScore1 60 -ConfidenceScore2 80
            $result2.Author | Should -Be $metadata2.Author
        }
    }
    
    Context "Stratégie Combine" {
        It "Devrait combiner les chaînes de caractères" {
            $result = Merge-ExtractedInfoMetadata -Metadata1 @{ Text = "Hello" } -Metadata2 @{ Text = "World" } -MergeStrategy "Combine"
            $result.Text | Should -Be "Hello World"
        }
        
        It "Devrait combiner les tableaux" {
            $result = Merge-ExtractedInfoMetadata -Metadata1 $metadata1 -Metadata2 $metadata2 -MergeStrategy "Combine"
            $result.Tags.Count | Should -Be 3
            $result.Tags | Should -Contain "tag1"
            $result.Tags | Should -Contain "tag2"
            $result.Tags | Should -Contain "tag3"
        }
        
        It "Devrait fusionner les hashtables récursivement" {
            $result = Merge-ExtractedInfoMetadata -Metadata1 $metadata1 -Metadata2 $metadata2 -MergeStrategy "Combine"
            $result.Nested.Key1 | Should -Be $metadata1.Nested.Key1
            $result.Nested.Key2 | Should -Be $metadata2.Nested.Key2
            $result.Nested.Key3 | Should -Be $metadata2.Nested.Key3
        }
        
        It "Devrait calculer la moyenne des valeurs numériques" {
            $result = Merge-ExtractedInfoMetadata -Metadata1 $metadata1 -Metadata2 $metadata2 -MergeStrategy "Combine"
            $result.Count | Should -Be 15
        }
        
        It "Devrait utiliser l'opération OR pour les booléens" {
            $result = Merge-ExtractedInfoMetadata -Metadata1 $metadata1 -Metadata2 $metadata2 -MergeStrategy "Combine"
            $result.IsActive | Should -Be $true
        }
        
        It "Devrait utiliser la date la plus récente" {
            $result = Merge-ExtractedInfoMetadata -Metadata1 $metadata1 -Metadata2 $metadata2 -MergeStrategy "Combine"
            $result.Date | Should -Be $metadata2.Date
        }
    }
    
    Context "Cas particuliers" {
        It "Devrait gérer correctement les métadonnées vides" {
            $result = Merge-ExtractedInfoMetadata -Metadata1 $metadata1 -Metadata2 @{}
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be $metadata1.Count
            
            $result2 = Merge-ExtractedInfoMetadata -Metadata1 @{} -Metadata2 $metadata2
            $result2 | Should -Not -BeNullOrEmpty
            $result2.Count | Should -Be $metadata2.Count
        }
        
        It "Devrait gérer correctement les métadonnées nulles" {
            $result = Merge-ExtractedInfoMetadata -Metadata1 $metadata1 -Metadata2 $null
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be $metadata1.Count
            
            $result2 = Merge-ExtractedInfoMetadata -Metadata1 $null -Metadata2 $metadata2
            $result2 | Should -Not -BeNullOrEmpty
            $result2.Count | Should -Be $metadata2.Count
        }
    }
}

Describe "Get-MergedConfidenceScore" {
    Context "Méthode Average" {
        It "Devrait calculer la moyenne des scores de confiance" {
            $scores = @(80, 90, 70)
            $result = Get-MergedConfidenceScore -ConfidenceScores $scores -Method "Average"
            $result | Should -Be 80
        }
    }
    
    Context "Méthode Weighted" {
        It "Devrait calculer une moyenne pondérée des scores de confiance" {
            $scores = @(80, 90, 70)
            $weights = @(0.5, 0.3, 0.2)
            $result = Get-MergedConfidenceScore -ConfidenceScores $scores -Method "Weighted" -Weights $weights
            $result | Should -Be 81
        }
        
        It "Devrait utiliser des poids égaux si aucun poids n'est spécifié" {
            $scores = @(80, 90, 70)
            $result = Get-MergedConfidenceScore -ConfidenceScores $scores -Method "Weighted"
            $result | Should -Be 80
        }
        
        It "Devrait normaliser les poids si nécessaire" {
            $scores = @(80, 90, 70)
            $weights = @(5, 3, 2) # Non normalisés
            $result = Get-MergedConfidenceScore -ConfidenceScores $scores -Method "Weighted" -Weights $weights
            $result | Should -Be 81
        }
    }
    
    Context "Méthode Maximum" {
        It "Devrait retourner le score de confiance le plus élevé" {
            $scores = @(80, 90, 70)
            $result = Get-MergedConfidenceScore -ConfidenceScores $scores -Method "Maximum"
            $result | Should -Be 90
        }
    }
    
    Context "Méthode Minimum" {
        It "Devrait retourner le score de confiance le plus bas" {
            $scores = @(80, 90, 70)
            $result = Get-MergedConfidenceScore -ConfidenceScores $scores -Method "Minimum"
            $result | Should -Be 70
        }
    }
    
    Context "Méthode Product" {
        It "Devrait calculer le produit des scores de confiance normalisés" {
            $scores = @(80, 90, 70)
            $result = Get-MergedConfidenceScore -ConfidenceScores $scores -Method "Product"
            $expected = (0.8 * 0.9 * 0.7) * 100
            $result | Should -BeApproximately $expected 0.01
        }
    }
    
    Context "Cas particuliers" {
        It "Devrait gérer correctement un seul score" {
            $scores = @(80)
            $result = Get-MergedConfidenceScore -ConfidenceScores $scores -Method "Average"
            $result | Should -Be 80
        }
        
        It "Devrait gérer correctement aucun score" {
            $scores = @()
            $result = Get-MergedConfidenceScore -ConfidenceScores $scores -Method "Average"
            $result | Should -Be 50
        }
    }
}
