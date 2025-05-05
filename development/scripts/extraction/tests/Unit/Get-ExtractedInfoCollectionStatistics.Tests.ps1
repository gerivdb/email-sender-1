BeforeAll {
    # Importer le module à tester
    $modulePath = Join-Path $PSScriptRoot "..\..\ExtractedInfoModuleV2.psm1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    }
    else {
        throw "Module not found at path: $modulePath"
    }
    
    # Créer une collection de test avec plusieurs éléments
    function Create-TestCollection {
        $collection = New-ExtractedInfoCollection -Name "TestCollection" -CreateIndexes
        
        # Basic info items
        $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1" -ProcessingState "Raw" -ConfidenceScore 50
        $info2 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor2" -ProcessingState "Processed" -ConfidenceScore 75
        
        # Text info items
        $textInfo1 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor1" -Text "Text 1" -Language "en" -ProcessingState "Raw" -ConfidenceScore 60
        $textInfo2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Text 2" -Language "fr" -ProcessingState "Validated" -ConfidenceScore 90
        
        # Structured data info items
        $dataInfo1 = New-StructuredDataExtractedInfo -Source "Source3" -ExtractorName "Extractor3" -Data @{ Key1 = "Value1" } -DataFormat "JSON" -ProcessingState "Processed" -ConfidenceScore 80
        $dataInfo2 = New-StructuredDataExtractedInfo -Source "Source3" -ExtractorName "Extractor3" -Data @{ Key2 = "Value2" } -DataFormat "XML" -ProcessingState "Error" -ConfidenceScore 30
        
        # Media info items
        $mediaInfo1 = New-MediaExtractedInfo -Source "Source4" -ExtractorName "Extractor4" -MediaPath "C:\path\to\image.jpg" -MediaType "Image" -ProcessingState "Raw" -ConfidenceScore 70
        $mediaInfo2 = New-MediaExtractedInfo -Source "Source4" -ExtractorName "Extractor4" -MediaPath "C:\path\to\video.mp4" -MediaType "Video" -ProcessingState "Processed" -ConfidenceScore 85
        
        # Add all items to the collection
        $items = @($info1, $info2, $textInfo1, $textInfo2, $dataInfo1, $dataInfo2, $mediaInfo1, $mediaInfo2)
        $collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList $items
        
        # Return the collection and the items for reference
        return @{
            Collection = $collection
            Items = $items
        }
    }
}

Describe "Get-ExtractedInfoCollectionStatistics" {
    Context "When getting basic statistics" {
        It "Should return correct total count" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $expectedCount = $testData.Items.Count
            
            # Act
            $result = Get-ExtractedInfoCollectionStatistics -Collection $collection
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.TotalCount | Should -Be $expectedCount
        }
        
        It "Should return correct type distribution" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            
            # Act
            $result = Get-ExtractedInfoCollectionStatistics -Collection $collection
            
            # Assert
            $result.TypeDistribution | Should -Not -BeNullOrEmpty
            $result.TypeDistribution.ExtractedInfo | Should -Be 2
            $result.TypeDistribution.TextExtractedInfo | Should -Be 2
            $result.TypeDistribution.StructuredDataExtractedInfo | Should -Be 2
            $result.TypeDistribution.MediaExtractedInfo | Should -Be 2
        }
        
        It "Should return correct source distribution" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            
            # Act
            $result = Get-ExtractedInfoCollectionStatistics -Collection $collection
            
            # Assert
            $result.SourceDistribution | Should -Not -BeNullOrEmpty
            $result.SourceDistribution.Source1 | Should -Be 2
            $result.SourceDistribution.Source2 | Should -Be 2
            $result.SourceDistribution.Source3 | Should -Be 2
            $result.SourceDistribution.Source4 | Should -Be 2
        }
        
        It "Should return correct processing state distribution" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            
            # Act
            $result = Get-ExtractedInfoCollectionStatistics -Collection $collection
            
            # Assert
            $result.ProcessingStateDistribution | Should -Not -BeNullOrEmpty
            $result.ProcessingStateDistribution.Raw | Should -Be 3
            $result.ProcessingStateDistribution.Processed | Should -Be 3
            $result.ProcessingStateDistribution.Validated | Should -Be 1
            $result.ProcessingStateDistribution.Error | Should -Be 1
        }
        
        It "Should return correct confidence score statistics" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            
            # Act
            $result = Get-ExtractedInfoCollectionStatistics -Collection $collection
            
            # Assert
            $result.ConfidenceScoreStatistics | Should -Not -BeNullOrEmpty
            $result.ConfidenceScoreStatistics.Min | Should -Be 30
            $result.ConfidenceScoreStatistics.Max | Should -Be 90
            $result.ConfidenceScoreStatistics.Average | Should -BeGreaterOrEqual 67
            $result.ConfidenceScoreStatistics.Average | Should -BeLessOrEqual 68
        }
        
        It "Should return correct extractor distribution" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            
            # Act
            $result = Get-ExtractedInfoCollectionStatistics -Collection $collection
            
            # Assert
            $result.ExtractorDistribution | Should -Not -BeNullOrEmpty
            $result.ExtractorDistribution.Extractor1 | Should -Be 2
            $result.ExtractorDistribution.Extractor2 | Should -Be 2
            $result.ExtractorDistribution.Extractor3 | Should -Be 2
            $result.ExtractorDistribution.Extractor4 | Should -Be 2
        }
    }
    
    Context "When getting statistics with filters" {
        It "Should return statistics for items of a specific type" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $type = "TextExtractedInfo"
            
            # Act
            $result = Get-ExtractedInfoCollectionStatistics -Collection $collection -Type $type
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.TotalCount | Should -Be 2
            $result.TypeDistribution.Count | Should -Be 1
            $result.TypeDistribution[$type] | Should -Be 2
        }
        
        It "Should return statistics for items from a specific source" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $source = "Source3"
            
            # Act
            $result = Get-ExtractedInfoCollectionStatistics -Collection $collection -Source $source
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.TotalCount | Should -Be 2
            $result.SourceDistribution.Count | Should -Be 1
            $result.SourceDistribution[$source] | Should -Be 2
            $result.TypeDistribution.StructuredDataExtractedInfo | Should -Be 2
        }
        
        It "Should return statistics for items with a specific processing state" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $state = "Processed"
            
            # Act
            $result = Get-ExtractedInfoCollectionStatistics -Collection $collection -ProcessingState $state
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.TotalCount | Should -Be 3
            $result.ProcessingStateDistribution.Count | Should -Be 1
            $result.ProcessingStateDistribution[$state] | Should -Be 3
        }
        
        It "Should return statistics for items with confidence score above threshold" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $minScore = 75
            
            # Act
            $result = Get-ExtractedInfoCollectionStatistics -Collection $collection -MinConfidenceScore $minScore
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.TotalCount | Should -Be 4
            $result.ConfidenceScoreStatistics.Min | Should -BeGreaterOrEqual $minScore
        }
        
        It "Should return statistics for items matching multiple filter criteria" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $source = "Source4"
            $state = "Processed"
            
            # Act
            $result = Get-ExtractedInfoCollectionStatistics -Collection $collection -Source $source -ProcessingState $state
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.TotalCount | Should -Be 1
            $result.SourceDistribution.Count | Should -Be 1
            $result.SourceDistribution[$source] | Should -Be 1
            $result.ProcessingStateDistribution.Count | Should -Be 1
            $result.ProcessingStateDistribution[$state] | Should -Be 1
        }
    }
    
    Context "When getting statistics for empty collections" {
        It "Should return zero counts for an empty collection" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "EmptyCollection"
            
            # Act
            $result = Get-ExtractedInfoCollectionStatistics -Collection $collection
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.TotalCount | Should -Be 0
            $result.TypeDistribution.Count | Should -Be 0
            $result.SourceDistribution.Count | Should -Be 0
            $result.ProcessingStateDistribution.Count | Should -Be 0
            $result.ExtractorDistribution.Count | Should -Be 0
            $result.ConfidenceScoreStatistics.Min | Should -Be 0
            $result.ConfidenceScoreStatistics.Max | Should -Be 0
            $result.ConfidenceScoreStatistics.Average | Should -Be 0
        }
        
        It "Should return zero counts when no items match filter criteria" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $nonExistentSource = "non-existent-source"
            
            # Act
            $result = Get-ExtractedInfoCollectionStatistics -Collection $collection -Source $nonExistentSource
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.TotalCount | Should -Be 0
            $result.TypeDistribution.Count | Should -Be 0
            $result.SourceDistribution.Count | Should -Be 0
            $result.ProcessingStateDistribution.Count | Should -Be 0
            $result.ExtractorDistribution.Count | Should -Be 0
            $result.ConfidenceScoreStatistics.Min | Should -Be 0
            $result.ConfidenceScoreStatistics.Max | Should -Be 0
            $result.ConfidenceScoreStatistics.Average | Should -Be 0
        }
    }
    
    Context "When using optimized indexes" {
        It "Should use indexes for faster statistics calculation when available" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            
            # Act
            $result = Get-ExtractedInfoCollectionStatistics -Collection $collection
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.UsedIndexes | Should -Be $true
        }
        
        It "Should fall back to manual calculation when indexes are not available" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection" # No indexes
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $info2 = New-ExtractedInfo -Source "Source2" -ExtractorName "Extractor2"
            $collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2)
            
            # Act
            $result = Get-ExtractedInfoCollectionStatistics -Collection $collection
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.UsedIndexes | Should -Be $false
            $result.TotalCount | Should -Be 2
        }
    }
    
    Context "When handling invalid inputs" {
        It "Should throw an error when Collection is null" {
            # Act & Assert
            { Get-ExtractedInfoCollectionStatistics -Collection $null } | Should -Throw
        }
        
        It "Should throw an error when Collection is not a valid collection object" {
            # Arrange
            $invalidCollection = @{
                Property = "Value"
            }
            
            # Act & Assert
            { Get-ExtractedInfoCollectionStatistics -Collection $invalidCollection } | Should -Throw
        }
        
        It "Should throw an error when MinConfidenceScore is out of range" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            
            # Act & Assert
            { Get-ExtractedInfoCollectionStatistics -Collection $collection -MinConfidenceScore -1 } | Should -Throw
            { Get-ExtractedInfoCollectionStatistics -Collection $collection -MinConfidenceScore 101 } | Should -Throw
        }
    }
}
