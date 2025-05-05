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

Describe "Get-ExtractedInfoFromCollection" {
    Context "When retrieving by ID" {
        It "Should retrieve a specific item by ID" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $targetItem = $testData.Items[3] # textInfo2
            
            # Act
            $result = Get-ExtractedInfoFromCollection -Collection $collection -Id $targetItem.Id
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Id | Should -Be $targetItem.Id
            $result._Type | Should -Be $targetItem._Type
            $result.Source | Should -Be $targetItem.Source
            $result.Text | Should -Be $targetItem.Text
        }
        
        It "Should return null when ID does not exist" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $nonExistentId = "non-existent-id"
            
            # Act
            $result = Get-ExtractedInfoFromCollection -Collection $collection -Id $nonExistentId
            
            # Assert
            $result | Should -BeNullOrEmpty
        }
        
        It "Should prioritize ID over other filter criteria" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $targetItem = $testData.Items[0] # info1
            
            # Act - Use ID with conflicting filter criteria
            $result = Get-ExtractedInfoFromCollection -Collection $collection -Id $targetItem.Id -Source "WrongSource" -Type "WrongType"
            
            # Assert - Should still find by ID
            $result | Should -Not -BeNullOrEmpty
            $result.Id | Should -Be $targetItem.Id
        }
    }
    
    Context "When filtering by Source" {
        It "Should retrieve all items from a specific source" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $source = "Source2"
            
            # Act
            $result = Get-ExtractedInfoFromCollection -Collection $collection -Source $source
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].Source | Should -Be $source
            $result[1].Source | Should -Be $source
        }
        
        It "Should return empty array when source does not exist" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $nonExistentSource = "non-existent-source"
            
            # Act
            $result = Get-ExtractedInfoFromCollection -Collection $collection -Source $nonExistentSource
            
            # Assert
            $result | Should -BeOfType [System.Array]
            $result.Count | Should -Be 0
        }
        
        It "Should use index for source filtering when available" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $source = "Source3"
            
            # Act
            $result = Get-ExtractedInfoFromCollection -Collection $collection -Source $source
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].Source | Should -Be $source
            $result[1].Source | Should -Be $source
        }
    }
    
    Context "When filtering by Type" {
        It "Should retrieve all items of a specific type" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $type = "TextExtractedInfo"
            
            # Act
            $result = Get-ExtractedInfoFromCollection -Collection $collection -Type $type
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0]._Type | Should -Be $type
            $result[1]._Type | Should -Be $type
        }
        
        It "Should return empty array when type does not exist" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $nonExistentType = "non-existent-type"
            
            # Act
            $result = Get-ExtractedInfoFromCollection -Collection $collection -Type $nonExistentType
            
            # Assert
            $result | Should -BeOfType [System.Array]
            $result.Count | Should -Be 0
        }
        
        It "Should use index for type filtering when available" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $type = "MediaExtractedInfo"
            
            # Act
            $result = Get-ExtractedInfoFromCollection -Collection $collection -Type $type
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0]._Type | Should -Be $type
            $result[1]._Type | Should -Be $type
        }
    }
    
    Context "When filtering by ProcessingState" {
        It "Should retrieve all items with a specific processing state" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $state = "Processed"
            
            # Act
            $result = Get-ExtractedInfoFromCollection -Collection $collection -ProcessingState $state
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].ProcessingState | Should -Be $state
            $result[1].ProcessingState | Should -Be $state
            $result[2].ProcessingState | Should -Be $state
        }
        
        It "Should return empty array when processing state does not exist" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $nonExistentState = "non-existent-state"
            
            # Act
            $result = Get-ExtractedInfoFromCollection -Collection $collection -ProcessingState $nonExistentState
            
            # Assert
            $result | Should -BeOfType [System.Array]
            $result.Count | Should -Be 0
        }
        
        It "Should use index for processing state filtering when available" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $state = "Raw"
            
            # Act
            $result = Get-ExtractedInfoFromCollection -Collection $collection -ProcessingState $state
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].ProcessingState | Should -Be $state
            $result[1].ProcessingState | Should -Be $state
            $result[2].ProcessingState | Should -Be $state
        }
    }
    
    Context "When filtering by ConfidenceScore" {
        It "Should retrieve all items with confidence score above threshold" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $minScore = 75
            
            # Act
            $result = Get-ExtractedInfoFromCollection -Collection $collection -MinConfidenceScore $minScore
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 4
            $result | ForEach-Object { $_.ConfidenceScore | Should -BeGreaterOrEqual $minScore }
        }
        
        It "Should return empty array when no items meet the confidence score threshold" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $minScore = 95
            
            # Act
            $result = Get-ExtractedInfoFromCollection -Collection $collection -MinConfidenceScore $minScore
            
            # Assert
            $result | Should -BeOfType [System.Array]
            $result.Count | Should -Be 0
        }
    }
    
    Context "When using multiple filter criteria" {
        It "Should retrieve items matching all filter criteria" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $source = "Source1"
            $state = "Processed"
            
            # Act
            $result = Get-ExtractedInfoFromCollection -Collection $collection -Source $source -ProcessingState $state
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].Source | Should -Be $source
            $result[0].ProcessingState | Should -Be $state
        }
        
        It "Should return empty array when no items match all criteria" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $source = "Source1"
            $state = "Validated"
            
            # Act
            $result = Get-ExtractedInfoFromCollection -Collection $collection -Source $source -ProcessingState $state
            
            # Assert
            $result | Should -BeOfType [System.Array]
            $result.Count | Should -Be 0
        }
        
        It "Should use the most selective index first when multiple indexes are available" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $type = "MediaExtractedInfo"
            $state = "Raw"
            
            # Act
            $result = Get-ExtractedInfoFromCollection -Collection $collection -Type $type -ProcessingState $state
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0]._Type | Should -Be $type
            $result[0].ProcessingState | Should -Be $state
        }
    }
    
    Context "When retrieving all items" {
        It "Should retrieve all items when no filter criteria are provided" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            $expectedCount = $testData.Items.Count
            
            # Act
            $result = Get-ExtractedInfoFromCollection -Collection $collection
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be $expectedCount
        }
    }
    
    Context "When handling invalid inputs" {
        It "Should throw an error when Collection is null" {
            # Act & Assert
            { Get-ExtractedInfoFromCollection -Collection $null } | Should -Throw
        }
        
        It "Should throw an error when Collection is not a valid collection object" {
            # Arrange
            $invalidCollection = @{
                Property = "Value"
            }
            
            # Act & Assert
            { Get-ExtractedInfoFromCollection -Collection $invalidCollection } | Should -Throw
        }
        
        It "Should throw an error when MinConfidenceScore is out of range" {
            # Arrange
            $testData = Create-TestCollection
            $collection = $testData.Collection
            
            # Act & Assert
            { Get-ExtractedInfoFromCollection -Collection $collection -MinConfidenceScore -1 } | Should -Throw
            { Get-ExtractedInfoFromCollection -Collection $collection -MinConfidenceScore 101 } | Should -Throw
        }
    }
}
