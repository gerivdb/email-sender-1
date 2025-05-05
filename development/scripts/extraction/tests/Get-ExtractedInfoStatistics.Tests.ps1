#Requires -Version 5.1
<#
.SYNOPSIS
Tests unitaires pour la fonction Get-ExtractedInfoStatistics.

.DESCRIPTION
Ce script contient les tests unitaires pour la fonction Get-ExtractedInfoStatistics
qui génère des statistiques sur des objets d'information extraite.

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
    # Créer une collection d'objets d'information extraite
    $collection = New-ExtractedInfoCollection -Name "Test Collection"
    
    # Créer des objets TextExtractedInfo
    $text1 = New-TextExtractedInfo -Source "document1.txt" -Text "Ceci est un exemple de texte court." -Language "fr"
    $text1.ExtractedAt = [datetime]::Now.AddDays(-10)
    $text1.ConfidenceScore = 85
    $text1 = Add-ExtractedInfoMetadata -Info $text1 -Metadata @{
        Author = "John Doe"
        Category = "Test"
        Keywords = @("test", "exemple", "court")
    }
    
    $text2 = New-TextExtractedInfo -Source "document2.txt" -Text "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat." -Language "la"
    $text2.ExtractedAt = [datetime]::Now.AddDays(-5)
    $text2.ConfidenceScore = 70
    $text2 = Add-ExtractedInfoMetadata -Info $text2 -Metadata @{
        Author = "Jane Smith"
        Category = "Test"
        Keywords = @("lorem", "ipsum", "long")
    }
    
    # Créer des objets StructuredDataExtractedInfo
    $data1 = New-StructuredDataExtractedInfo -Source "data1.json" -Data @{
        Name = "Test Object"
        Value = 42
        IsActive = $true
    } -DataFormat "Hashtable"
    $data1.ExtractedAt = [datetime]::Now.AddDays(-15)
    $data1.ConfidenceScore = 95
    
    $data2 = New-StructuredDataExtractedInfo -Source "data2.json" -Data @{
        Users = @(
            @{ Id = 1; Name = "User 1" },
            @{ Id = 2; Name = "User 2" }
        )
    } -DataFormat "Hashtable"
    $data2.ExtractedAt = [datetime]::Now.AddDays(-2)
    $data2.ConfidenceScore = 60
    $data2 = Add-ExtractedInfoMetadata -Info $data2 -Metadata @{
        Source = "API"
        Version = "1.0"
    }
    
    # Créer un objet GeoLocationExtractedInfo
    $geo = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France"
    $geo.ExtractedAt = [datetime]::Now.AddDays(-20)
    $geo.ConfidenceScore = 90
    $geo = Add-ExtractedInfoMetadata -Info $geo -Metadata @{
        Population = 2161000
        TimeZone = "Europe/Paris"
    }
    
    # Ajouter les objets à la collection
    $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $text1
    $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $text2
    $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $data1
    $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $data2
    $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $geo
    
    return @{
        Collection = $collection
        Text1 = $text1
        Text2 = $text2
        Data1 = $data1
        Data2 = $data2
        Geo = $geo
    }
}

# Démarrer les tests Pester
Describe "Get-ExtractedInfoStatistics" {
    BeforeAll {
        $testData = New-TestData
    }
    
    Context "Paramètres et validation" {
        It "Devrait accepter un objet Info" {
            { Get-ExtractedInfoStatistics -Info $testData.Text1 } | Should -Not -Throw
        }
        
        It "Devrait accepter une collection" {
            { Get-ExtractedInfoStatistics -Collection $testData.Collection } | Should -Not -Throw
        }
        
        It "Devrait rejeter un objet Info invalide" {
            { Get-ExtractedInfoStatistics -Info @{ InvalidObject = $true } } | Should -Throw
        }
        
        It "Devrait rejeter une collection invalide" {
            { Get-ExtractedInfoStatistics -Collection @{ InvalidCollection = $true } } | Should -Throw
        }
        
        It "Devrait accepter différents types de statistiques" {
            { Get-ExtractedInfoStatistics -Info $testData.Text1 -StatisticsType "Basic" } | Should -Not -Throw
            { Get-ExtractedInfoStatistics -Info $testData.Text1 -StatisticsType "Temporal" } | Should -Not -Throw
            { Get-ExtractedInfoStatistics -Info $testData.Text1 -StatisticsType "Confidence" } | Should -Not -Throw
            { Get-ExtractedInfoStatistics -Info $testData.Text1 -StatisticsType "Content" } | Should -Not -Throw
            { Get-ExtractedInfoStatistics -Info $testData.Text1 -StatisticsType "All" } | Should -Not -Throw
        }
        
        It "Devrait accepter différents formats de sortie" {
            { Get-ExtractedInfoStatistics -Info $testData.Text1 -OutputFormat "Text" } | Should -Not -Throw
            { Get-ExtractedInfoStatistics -Info $testData.Text1 -OutputFormat "HTML" } | Should -Not -Throw
            { Get-ExtractedInfoStatistics -Info $testData.Text1 -OutputFormat "JSON" } | Should -Not -Throw
        }
    }
    
    Context "Statistiques de base" {
        It "Devrait générer des statistiques de base pour un objet Info" {
            $stats = Get-ExtractedInfoStatistics -Info $testData.Text1 -StatisticsType "Basic"
            $stats | Should -BeOfType [hashtable]
            $stats.ContainsKey("BasicStats") | Should -Be $true
            $stats.BasicStats.TypeDistribution.ContainsKey("TextExtractedInfo") | Should -Be $true
        }
        
        It "Devrait générer des statistiques de base pour une collection" {
            $stats = Get-ExtractedInfoStatistics -Collection $testData.Collection -StatisticsType "Basic"
            $stats | Should -BeOfType [hashtable]
            $stats.ContainsKey("BasicStats") | Should -Be $true
            $stats.BasicStats.TypeDistribution.Count | Should -BeGreaterThan 0
            $stats.BasicStats.SourceDistribution.Count | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer correctement les pourcentages" {
            $stats = Get-ExtractedInfoStatistics -Collection $testData.Collection -StatisticsType "Basic"
            $totalPercentage = 0
            foreach ($percent in $stats.BasicStats.TypePercentages.Values) {
                $totalPercentage += $percent
            }
            $totalPercentage | Should -BeApproximately 100 0.1
        }
    }
    
    Context "Statistiques temporelles" {
        It "Devrait générer des statistiques temporelles" {
            $stats = Get-ExtractedInfoStatistics -Collection $testData.Collection -StatisticsType "Temporal"
            $stats | Should -BeOfType [hashtable]
            $stats.ContainsKey("TemporalStats") | Should -Be $true
            $stats.TemporalStats.ContainsKey("AverageAgeInDays") | Should -Be $true
        }
        
        It "Devrait identifier les périodes les plus actives" {
            $stats = Get-ExtractedInfoStatistics -Collection $testData.Collection -StatisticsType "Temporal"
            $stats.TemporalStats.ContainsKey("MostActiveDay") | Should -Be $true
            $stats.TemporalStats.ContainsKey("MostActiveMonth") | Should -Be $true
            $stats.TemporalStats.ContainsKey("MostActiveWeekday") | Should -Be $true
        }
    }
    
    Context "Statistiques de confiance" {
        It "Devrait générer des statistiques de confiance" {
            $stats = Get-ExtractedInfoStatistics -Collection $testData.Collection -StatisticsType "Confidence"
            $stats | Should -BeOfType [hashtable]
            $stats.ContainsKey("ConfidenceStats") | Should -Be $true
            $stats.ConfidenceStats.ContainsKey("AverageConfidence") | Should -Be $true
            $stats.ConfidenceStats.ContainsKey("MedianConfidence") | Should -Be $true
        }
        
        It "Devrait calculer correctement les plages de confiance" {
            $stats = Get-ExtractedInfoStatistics -Collection $testData.Collection -StatisticsType "Confidence"
            $totalItems = 0
            foreach ($count in $stats.ConfidenceStats.ConfidenceRanges.Values) {
                $totalItems += $count
            }
            $totalItems | Should -Be $testData.Collection.Items.Count
        }
    }
    
    Context "Statistiques de contenu" {
        It "Devrait générer des statistiques de contenu" {
            $stats = Get-ExtractedInfoStatistics -Collection $testData.Collection -StatisticsType "Content"
            $stats | Should -BeOfType [hashtable]
            $stats.ContainsKey("ContentStats") | Should -Be $true
            $stats.ContentStats.ContainsKey("AverageSize") | Should -Be $true
            $stats.ContentStats.ContainsKey("MedianSize") | Should -Be $true
        }
        
        It "Devrait générer des statistiques spécifiques aux types" {
            $stats = Get-ExtractedInfoStatistics -Collection $testData.Collection -StatisticsType "Content"
            $stats.ContentStats.ContainsKey("TypeSpecificStats") | Should -Be $true
            $stats.ContentStats.TypeSpecificStats.ContainsKey("TextExtractedInfo") | Should -Be $true
            $stats.ContentStats.TypeSpecificStats.ContainsKey("StructuredDataExtractedInfo") | Should -Be $true
            $stats.ContentStats.TypeSpecificStats.ContainsKey("GeoLocationExtractedInfo") | Should -Be $true
        }
    }
    
    Context "Statistiques de métadonnées" {
        It "Devrait générer des statistiques de métadonnées quand IncludeMetadata est activé" {
            $stats = Get-ExtractedInfoStatistics -Collection $testData.Collection -StatisticsType "Basic" -IncludeMetadata
            $stats | Should -BeOfType [hashtable]
            $stats.ContainsKey("MetadataStats") | Should -Be $true
            $stats.MetadataStats.ContainsKey("ItemsWithMetadata") | Should -Be $true
        }
        
        It "Ne devrait pas générer de statistiques de métadonnées quand IncludeMetadata est désactivé" {
            $stats = Get-ExtractedInfoStatistics -Collection $testData.Collection -StatisticsType "Basic" -IncludeMetadata:$false
            $stats | Should -BeOfType [hashtable]
            $stats.ContainsKey("MetadataStats") | Should -Be $false
        }
        
        It "Devrait identifier les clés de métadonnées les plus courantes" {
            $stats = Get-ExtractedInfoStatistics -Collection $testData.Collection -StatisticsType "Basic" -IncludeMetadata
            $stats.MetadataStats.ContainsKey("MostCommonMetadataKeys") | Should -Be $true
            $stats.MetadataStats.MostCommonMetadataKeys.Count | Should -BeGreaterThan 0
        }
    }
    
    Context "Formats de sortie" {
        It "Devrait générer une sortie au format texte" {
            $output = Get-ExtractedInfoStatistics -Collection $testData.Collection -OutputFormat "Text"
            $output | Should -BeOfType [string]
            $output | Should -Match "RAPPORT D'ANALYSE STATISTIQUE"
        }
        
        It "Devrait générer une sortie au format HTML" {
            $output = Get-ExtractedInfoStatistics -Collection $testData.Collection -OutputFormat "HTML"
            $output | Should -BeOfType [string]
            $output | Should -Match "<html>"
            $output | Should -Match "</html>"
        }
        
        It "Devrait générer une sortie au format JSON" {
            $output = Get-ExtractedInfoStatistics -Collection $testData.Collection -OutputFormat "JSON"
            $output | Should -BeOfType [string]
            { $output | ConvertFrom-Json } | Should -Not -Throw
        }
    }
    
    Context "Statistiques complètes" {
        It "Devrait générer toutes les statistiques avec le type 'All'" {
            $stats = Get-ExtractedInfoStatistics -Collection $testData.Collection -StatisticsType "All"
            $stats | Should -BeOfType [hashtable]
            $stats.ContainsKey("BasicStats") | Should -Be $true
            $stats.ContainsKey("TemporalStats") | Should -Be $true
            $stats.ContainsKey("ConfidenceStats") | Should -Be $true
            $stats.ContainsKey("ContentStats") | Should -Be $true
        }
    }
}
