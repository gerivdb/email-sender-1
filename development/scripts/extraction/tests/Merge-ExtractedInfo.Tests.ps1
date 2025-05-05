#Requires -Version 5.1
<#
.SYNOPSIS
Tests unitaires pour la fonction Merge-ExtractedInfo.

.DESCRIPTION
Ce script contient les tests unitaires pour la fonction Merge-ExtractedInfo
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

# Créer des données de test
function New-TestData {
    # Créer des objets TextExtractedInfo
    $text1 = New-TextExtractedInfo -Source "document.txt" -Text "Première partie du texte." -Language "fr"
    $text1.ConfidenceScore = 80
    $text1.ExtractedAt = [datetime]::Now.AddDays(-5)
    $text1 = Add-ExtractedInfoMetadata -Info $text1 -Metadata @{
        Author   = "John Doe"
        Category = "Test"
    }

    $text2 = New-TextExtractedInfo -Source "document.txt" -Text "Seconde partie du texte." -Language "fr"
    $text2.ConfidenceScore = 90
    $text2.ExtractedAt = [datetime]::Now.AddDays(-2)
    $text2 = Add-ExtractedInfoMetadata -Info $text2 -Metadata @{
        Author   = "Jane Smith"
        Keywords = @("test", "exemple")
    }

    # Créer des objets StructuredDataExtractedInfo
    $data1 = New-StructuredDataExtractedInfo -Source "data.json" -Data @{
        Name = "John"
        Age  = 30
    } -DataFormat "Hashtable"
    $data1.ConfidenceScore = 70

    $data2 = New-StructuredDataExtractedInfo -Source "data.json" -Data @{
        Name  = "John Doe"
        Email = "john@example.com"
    } -DataFormat "Hashtable"
    $data2.ConfidenceScore = 85

    # Créer des objets GeoLocationExtractedInfo
    $geo1 = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France"
    $geo1.ConfidenceScore = 95

    $geo2 = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France" -Address "Tour Eiffel"
    $geo2.ConfidenceScore = 90

    return @{
        Text1 = $text1
        Text2 = $text2
        Data1 = $data1
        Data2 = $data2
        Geo1  = $geo1
        Geo2  = $geo2
    }
}

# Démarrer les tests Pester
Describe "Merge-ExtractedInfo" {
    BeforeAll {
        # Créer des données de test
        function New-TestData {
            # Créer des objets TextExtractedInfo
            $text1 = New-TextExtractedInfo -Source "document.txt" -Text "Première partie du texte." -Language "fr"
            $text1.ConfidenceScore = 80
            $text1.ExtractedAt = [datetime]::Now.AddDays(-5)
            $text1 = Add-ExtractedInfoMetadata -Info $text1 -Metadata @{
                Author   = "John Doe"
                Category = "Test"
            }

            $text2 = New-TextExtractedInfo -Source "document.txt" -Text "Seconde partie du texte." -Language "fr"
            $text2.ConfidenceScore = 90
            $text2.ExtractedAt = [datetime]::Now.AddDays(-2)
            $text2 = Add-ExtractedInfoMetadata -Info $text2 -Metadata @{
                Author   = "Jane Smith"
                Keywords = @("test", "exemple")
            }

            # Créer des objets StructuredDataExtractedInfo
            $data1 = New-StructuredDataExtractedInfo -Source "data.json" -Data @{
                Name = "John"
                Age  = 30
            } -DataFormat "Hashtable"
            $data1.ConfidenceScore = 70

            $data2 = New-StructuredDataExtractedInfo -Source "data.json" -Data @{
                Name  = "John Doe"
                Email = "john@example.com"
            } -DataFormat "Hashtable"
            $data2.ConfidenceScore = 85

            # Créer des objets GeoLocationExtractedInfo
            $geo1 = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France"
            $geo1.ConfidenceScore = 95

            $geo2 = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France" -Address "Tour Eiffel"
            $geo2.ConfidenceScore = 90

            return @{
                Text1 = $text1
                Text2 = $text2
                Data1 = $data1
                Data2 = $data2
                Geo1  = $geo1
                Geo2  = $geo2
            }
        }

        $testData = New-TestData
    }

    Context "Paramètres et validation" {
        It "Devrait accepter deux objets d'information extraite" {
            { Merge-ExtractedInfo -PrimaryInfo $testData.Text1 -SecondaryInfo $testData.Text2 } | Should -Not -Throw
        }

        It "Devrait accepter un tableau d'objets d'information extraite" {
            { Merge-ExtractedInfo -InfoArray @($testData.Text1, $testData.Text2) } | Should -Not -Throw
        }

        It "Devrait rejeter des objets de types différents sans l'option Force" {
            { Merge-ExtractedInfo -PrimaryInfo $testData.Text1 -SecondaryInfo $testData.Data1 } | Should -Throw
        }

        It "Devrait accepter des objets de types différents avec l'option Force" {
            { Merge-ExtractedInfo -PrimaryInfo $testData.Text1 -SecondaryInfo $testData.Data1 -Force } | Should -Not -Throw
        }

        It "Devrait accepter différentes stratégies de fusion" {
            { Merge-ExtractedInfo -PrimaryInfo $testData.Text1 -SecondaryInfo $testData.Text2 -MergeStrategy "FirstWins" } | Should -Not -Throw
            { Merge-ExtractedInfo -PrimaryInfo $testData.Text1 -SecondaryInfo $testData.Text2 -MergeStrategy "LastWins" } | Should -Not -Throw
            { Merge-ExtractedInfo -PrimaryInfo $testData.Text1 -SecondaryInfo $testData.Text2 -MergeStrategy "HighestConfidence" } | Should -Not -Throw
            { Merge-ExtractedInfo -PrimaryInfo $testData.Text1 -SecondaryInfo $testData.Text2 -MergeStrategy "Combine" } | Should -Not -Throw
        }
    }

    Context "Fusion de TextExtractedInfo" {
        It "Devrait fusionner deux objets TextExtractedInfo avec la stratégie FirstWins" {
            $result = Merge-ExtractedInfo -PrimaryInfo $testData.Text1 -SecondaryInfo $testData.Text2 -MergeStrategy "FirstWins"
            $result._Type | Should -Be "TextExtractedInfo"
            $result.Text | Should -Be $testData.Text1.Text
            $result.Language | Should -Be $testData.Text1.Language
        }

        It "Devrait fusionner deux objets TextExtractedInfo avec la stratégie LastWins" {
            $result = Merge-ExtractedInfo -PrimaryInfo $testData.Text1 -SecondaryInfo $testData.Text2 -MergeStrategy "LastWins"
            $result._Type | Should -Be "TextExtractedInfo"
            $result.Text | Should -Be $testData.Text2.Text
            $result.Language | Should -Be $testData.Text2.Language
        }

        It "Devrait fusionner deux objets TextExtractedInfo avec la stratégie HighestConfidence" {
            $result = Merge-ExtractedInfo -PrimaryInfo $testData.Text1 -SecondaryInfo $testData.Text2 -MergeStrategy "HighestConfidence"
            $result._Type | Should -Be "TextExtractedInfo"
            $result.Text | Should -Be $testData.Text2.Text # Text2 a un score de confiance plus élevé
            $result.Language | Should -Be $testData.Text2.Language
        }

        It "Devrait fusionner deux objets TextExtractedInfo avec la stratégie Combine" {
            $result = Merge-ExtractedInfo -PrimaryInfo $testData.Text1 -SecondaryInfo $testData.Text2 -MergeStrategy "Combine"
            $result._Type | Should -Be "TextExtractedInfo"
            $result.Text | Should -Match $testData.Text1.Text
            $result.Text | Should -Match $testData.Text2.Text
            $result.Language | Should -Be $testData.Text1.Language # Les langues sont identiques
        }
    }

    Context "Fusion de StructuredDataExtractedInfo" {
        It "Devrait fusionner deux objets StructuredDataExtractedInfo avec la stratégie FirstWins" {
            $result = Merge-ExtractedInfo -PrimaryInfo $testData.Data1 -SecondaryInfo $testData.Data2 -MergeStrategy "FirstWins"
            $result._Type | Should -Be "StructuredDataExtractedInfo"
            $result.Data.Name | Should -Be $testData.Data1.Data.Name
            $result.Data.Age | Should -Be $testData.Data1.Data.Age
            $result.Data.ContainsKey("Email") | Should -Be $true # Propriété unique du deuxième objet
        }

        It "Devrait fusionner deux objets StructuredDataExtractedInfo avec la stratégie LastWins" {
            $result = Merge-ExtractedInfo -PrimaryInfo $testData.Data1 -SecondaryInfo $testData.Data2 -MergeStrategy "LastWins"
            $result._Type | Should -Be "StructuredDataExtractedInfo"
            $result.Data.Name | Should -Be $testData.Data2.Data.Name
            $result.Data.ContainsKey("Age") | Should -Be $true # Propriété unique du premier objet
            $result.Data.Email | Should -Be $testData.Data2.Data.Email
        }

        It "Devrait fusionner deux objets StructuredDataExtractedInfo avec la stratégie Combine" {
            $result = Merge-ExtractedInfo -PrimaryInfo $testData.Data1 -SecondaryInfo $testData.Data2 -MergeStrategy "Combine"
            $result._Type | Should -Be "StructuredDataExtractedInfo"
            $result.Data.ContainsKey("Name") | Should -Be $true
            $result.Data.ContainsKey("Age") | Should -Be $true
            $result.Data.ContainsKey("Email") | Should -Be $true
        }
    }

    Context "Fusion de GeoLocationExtractedInfo" {
        It "Devrait fusionner deux objets GeoLocationExtractedInfo avec la stratégie FirstWins" {
            $result = Merge-ExtractedInfo -PrimaryInfo $testData.Geo1 -SecondaryInfo $testData.Geo2 -MergeStrategy "FirstWins"
            $result._Type | Should -Be "GeoLocationExtractedInfo"
            $result.Latitude | Should -Be $testData.Geo1.Latitude
            $result.Longitude | Should -Be $testData.Geo1.Longitude
            $result.City | Should -Be $testData.Geo1.City
            $result.Country | Should -Be $testData.Geo1.Country
            $result.ContainsKey("Address") | Should -Be $true # Propriété unique du deuxième objet
        }

        It "Devrait fusionner deux objets GeoLocationExtractedInfo avec la stratégie LastWins" {
            $result = Merge-ExtractedInfo -PrimaryInfo $testData.Geo1 -SecondaryInfo $testData.Geo2 -MergeStrategy "LastWins"
            $result._Type | Should -Be "GeoLocationExtractedInfo"
            $result.Latitude | Should -Be $testData.Geo2.Latitude
            $result.Longitude | Should -Be $testData.Geo2.Longitude
            $result.City | Should -Be $testData.Geo2.City
            $result.Country | Should -Be $testData.Geo2.Country
            $result.Address | Should -Be $testData.Geo2.Address
        }
    }

    Context "Fusion des métadonnées" {
        It "Devrait fusionner les métadonnées avec la stratégie FirstWins" {
            $result = Merge-ExtractedInfo -PrimaryInfo $testData.Text1 -SecondaryInfo $testData.Text2 -MergeStrategy "FirstWins"
            $result.Metadata.Author | Should -Be $testData.Text1.Metadata.Author
            $result.Metadata.ContainsKey("Keywords") | Should -Be $true # Propriété unique du deuxième objet
        }

        It "Devrait fusionner les métadonnées avec la stratégie LastWins" {
            $result = Merge-ExtractedInfo -PrimaryInfo $testData.Text1 -SecondaryInfo $testData.Text2 -MergeStrategy "LastWins"
            $result.Metadata.Author | Should -Be $testData.Text2.Metadata.Author
            $result.Metadata.ContainsKey("Category") | Should -Be $true # Propriété unique du premier objet
            $result.Metadata.Keywords | Should -Be $testData.Text2.Metadata.Keywords
        }

        It "Devrait fusionner les métadonnées avec la stratégie Combine" {
            $result = Merge-ExtractedInfo -PrimaryInfo $testData.Text1 -SecondaryInfo $testData.Text2 -MergeStrategy "Combine"
            $result.Metadata.ContainsKey("Author") | Should -Be $true
            $result.Metadata.ContainsKey("Category") | Should -Be $true
            $result.Metadata.ContainsKey("Keywords") | Should -Be $true
        }

        It "Devrait utiliser une stratégie de fusion de métadonnées différente si spécifiée" {
            $result = Merge-ExtractedInfo -PrimaryInfo $testData.Text1 -SecondaryInfo $testData.Text2 -MergeStrategy "LastWins" -MetadataMergeStrategy "FirstWins"
            $result.Text | Should -Be $testData.Text2.Text # LastWins pour le contenu
            $result.Metadata.Author | Should -Be $testData.Text1.Metadata.Author # FirstWins pour les métadonnées
        }
    }

    Context "Fusion des scores de confiance" {
        It "Devrait calculer un score de confiance fusionné" {
            $result = Merge-ExtractedInfo -PrimaryInfo $testData.Text1 -SecondaryInfo $testData.Text2 -MergeStrategy "Combine"
            $result.ConfidenceScore | Should -Not -BeNullOrEmpty
            $result.ConfidenceScore | Should -BeGreaterThan 0
            $result.ConfidenceScore | Should -BeLessOrEqual 100
        }
    }

    Context "Fusion de plusieurs objets" {
        It "Devrait fusionner plus de deux objets" {
            $result = Merge-ExtractedInfo -InfoArray @($testData.Text1, $testData.Text2, $testData.Text1) -MergeStrategy "Combine"
            $result._Type | Should -Be "TextExtractedInfo"
            $result.Text | Should -Not -BeNullOrEmpty
            $result.Text.Length | Should -BeGreaterThan $testData.Text1.Text.Length
        }
    }
}
