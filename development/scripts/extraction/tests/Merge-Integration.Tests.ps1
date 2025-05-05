#Requires -Version 5.1
<#
.SYNOPSIS
Tests d'intégration pour la fonctionnalité de fusion d'objets d'information extraite.

.DESCRIPTION
Ce script contient des tests d'intégration pour la fonctionnalité de fusion d'objets
d'information extraite, en se concentrant sur des scénarios complexes.

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

# Démarrer les tests Pester
Describe "Merge-ExtractedInfo - Tests d'intégration" {
    BeforeAll {
        # Créer une collection d'objets d'information extraite
        $collection = New-ExtractedInfoCollection -Name "Collection de test"
        
        # Créer des objets TextExtractedInfo
        $text1 = New-TextExtractedInfo -Source "article.txt" -Text "Introduction à l'intelligence artificielle." -Language "fr"
        $text1.ConfidenceScore = 80
        $text1 = Add-ExtractedInfoMetadata -Info $text1 -Metadata @{
            Author = "Jean Dupont"
            Category = "Technologie"
            Keywords = @("IA", "introduction")
            CreatedAt = [datetime]::Now.AddDays(-10)
        }
        
        $text2 = New-TextExtractedInfo -Source "article.txt" -Text "L'IA est un domaine en pleine expansion." -Language "fr"
        $text2.ConfidenceScore = 85
        $text2 = Add-ExtractedInfoMetadata -Info $text2 -Metadata @{
            Author = "Jean Dupont"
            Keywords = @("IA", "expansion")
            CreatedAt = [datetime]::Now.AddDays(-9)
        }
        
        $text3 = New-TextExtractedInfo -Source "article.txt" -Text "Elle transforme de nombreux secteurs d'activité." -Language "fr"
        $text3.ConfidenceScore = 75
        $text3 = Add-ExtractedInfoMetadata -Info $text3 -Metadata @{
            Author = "Marie Martin"
            Keywords = @("IA", "transformation", "secteurs")
            CreatedAt = [datetime]::Now.AddDays(-8)
        }
        
        # Créer des objets StructuredDataExtractedInfo
        $data1 = New-StructuredDataExtractedInfo -Source "stats.json" -Data @{
            AIMarket = @{
                "2020" = 50000000000
                "2021" = 60000000000
                "2022" = 75000000000
            }
        } -DataFormat "Hashtable"
        $data1.ConfidenceScore = 90
        
        $data2 = New-StructuredDataExtractedInfo -Source "stats.json" -Data @{
            AIMarket = @{
                "2023" = 90000000000
                "2024" = 110000000000
            }
            TopCompanies = @(
                "Google",
                "Microsoft",
                "Amazon"
            )
        } -DataFormat "Hashtable"
        $data2.ConfidenceScore = 85
        
        # Ajouter les objets à la collection
        $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $text1
        $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $text2
        $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $text3
        $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $data1
        $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $data2
    }
    
    Context "Scénario 1: Fusion de textes fragmentés" {
        It "Devrait fusionner plusieurs fragments de texte en un texte cohérent" {
            # Récupérer les objets TextExtractedInfo de la collection
            $textObjects = Get-ExtractedInfoFromCollection -Collection $collection -Filter { $_._Type -eq "TextExtractedInfo" }
            
            # Fusionner les objets
            $mergedText = Merge-ExtractedInfo -InfoArray $textObjects -MergeStrategy "Combine"
            
            # Vérifier le résultat
            $mergedText._Type | Should -Be "TextExtractedInfo"
            $mergedText.Text | Should -Contain "Introduction à l'intelligence artificielle"
            $mergedText.Text | Should -Contain "L'IA est un domaine en pleine expansion"
            $mergedText.Text | Should -Contain "Elle transforme de nombreux secteurs d'activité"
            $mergedText.Language | Should -Be "fr"
            
            # Vérifier les métadonnées fusionnées
            $mergedText.Metadata.Keywords.Count | Should -BeGreaterThan 3
            $mergedText.Metadata.Keywords | Should -Contain "IA"
            $mergedText.Metadata.Keywords | Should -Contain "introduction"
            $mergedText.Metadata.Keywords | Should -Contain "expansion"
            $mergedText.Metadata.Keywords | Should -Contain "transformation"
            $mergedText.Metadata.Keywords | Should -Contain "secteurs"
        }
    }
    
    Context "Scénario 2: Fusion de données structurées complémentaires" {
        It "Devrait fusionner des données structurées complémentaires" {
            # Récupérer les objets StructuredDataExtractedInfo de la collection
            $dataObjects = Get-ExtractedInfoFromCollection -Collection $collection -Filter { $_._Type -eq "StructuredDataExtractedInfo" }
            
            # Fusionner les objets
            $mergedData = Merge-ExtractedInfo -InfoArray $dataObjects -MergeStrategy "Combine"
            
            # Vérifier le résultat
            $mergedData._Type | Should -Be "StructuredDataExtractedInfo"
            $mergedData.Data.AIMarket.Count | Should -Be 5
            $mergedData.Data.AIMarket["2020"] | Should -Be 50000000000
            $mergedData.Data.AIMarket["2024"] | Should -Be 110000000000
            $mergedData.Data.TopCompanies.Count | Should -Be 3
            $mergedData.Data.TopCompanies | Should -Contain "Google"
            $mergedData.Data.TopCompanies | Should -Contain "Microsoft"
            $mergedData.Data.TopCompanies | Should -Contain "Amazon"
        }
    }
    
    Context "Scénario 3: Fusion avec filtrage et tri" {
        It "Devrait fusionner des objets filtrés et triés" {
            # Récupérer les objets TextExtractedInfo avec un score de confiance > 75
            $highConfidenceTexts = Get-ExtractedInfoFromCollection -Collection $collection -Filter { 
                $_._Type -eq "TextExtractedInfo" -and $_.ConfidenceScore -gt 75 
            }
            
            # Trier les objets par score de confiance décroissant
            $sortedTexts = $highConfidenceTexts | Sort-Object -Property ConfidenceScore -Descending
            
            # Fusionner les objets
            $mergedText = Merge-ExtractedInfo -InfoArray $sortedTexts -MergeStrategy "HighestConfidence"
            
            # Vérifier le résultat
            $mergedText._Type | Should -Be "TextExtractedInfo"
            $mergedText.ConfidenceScore | Should -BeGreaterThan 80
            $mergedText.Text | Should -Be $sortedTexts[0].Text
        }
    }
    
    Context "Scénario 4: Fusion avec stratégies mixtes" {
        It "Devrait fusionner des objets avec des stratégies différentes pour le contenu et les métadonnées" {
            # Récupérer les objets TextExtractedInfo de la collection
            $textObjects = Get-ExtractedInfoFromCollection -Collection $collection -Filter { $_._Type -eq "TextExtractedInfo" }
            
            # Fusionner les objets avec des stratégies différentes
            $mergedText = Merge-ExtractedInfo -InfoArray $textObjects -MergeStrategy "LastWins" -MetadataMergeStrategy "Combine"
            
            # Vérifier le résultat
            $mergedText._Type | Should -Be "TextExtractedInfo"
            $mergedText.Text | Should -Be $textObjects[-1].Text # LastWins pour le contenu
            $mergedText.Metadata.Keywords.Count | Should -BeGreaterThan 3 # Combine pour les métadonnées
        }
    }
    
    Context "Scénario 5: Fusion d'objets de types différents avec Force" {
        It "Devrait fusionner des objets de types différents avec l'option Force" {
            # Récupérer un objet TextExtractedInfo et un objet StructuredDataExtractedInfo
            $text = Get-ExtractedInfoFromCollection -Collection $collection -Filter { $_._Type -eq "TextExtractedInfo" } | Select-Object -First 1
            $data = Get-ExtractedInfoFromCollection -Collection $collection -Filter { $_._Type -eq "StructuredDataExtractedInfo" } | Select-Object -First 1
            
            # Fusionner les objets avec l'option Force
            $mergedInfo = Merge-ExtractedInfo -PrimaryInfo $text -SecondaryInfo $data -MergeStrategy "Combine" -Force
            
            # Vérifier le résultat
            $mergedInfo._Type | Should -Be $text._Type
            $mergedInfo.Text | Should -Be $text.Text
            $mergedInfo.ContainsKey("Data") | Should -Be $true
        }
    }
    
    Context "Scénario 6: Fusion en chaîne" {
        It "Devrait permettre la fusion en chaîne de plusieurs objets" {
            # Récupérer les objets TextExtractedInfo de la collection
            $textObjects = Get-ExtractedInfoFromCollection -Collection $collection -Filter { $_._Type -eq "TextExtractedInfo" }
            
            # Fusionner les objets en chaîne
            $mergedText1 = Merge-ExtractedInfo -PrimaryInfo $textObjects[0] -SecondaryInfo $textObjects[1] -MergeStrategy "Combine"
            $mergedText2 = Merge-ExtractedInfo -PrimaryInfo $mergedText1 -SecondaryInfo $textObjects[2] -MergeStrategy "Combine"
            
            # Vérifier le résultat
            $mergedText2._Type | Should -Be "TextExtractedInfo"
            $mergedText2.Text | Should -Contain $textObjects[0].Text
            $mergedText2.Text | Should -Contain $textObjects[1].Text
            $mergedText2.Text | Should -Contain $textObjects[2].Text
        }
    }
}
