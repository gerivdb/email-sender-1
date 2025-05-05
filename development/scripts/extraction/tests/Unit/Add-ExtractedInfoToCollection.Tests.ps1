BeforeAll {
    # Importer le module à tester
    $modulePath = Join-Path $PSScriptRoot "..\..\ExtractedInfoModuleV2.psm1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    }
    else {
        throw "Module not found at path: $modulePath"
    }
}

Describe "Add-ExtractedInfoToCollection" {
    Context "When adding a single item to a collection" {
        It "Should add a new item to an empty collection" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            
            # Act
            $result = Add-ExtractedInfoToCollection -Collection $collection -Info $info
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Items.Count | Should -Be 1
            $result.Items[0].Id | Should -Be $info.Id
            $result.Items[0].Source | Should -Be $info.Source
            $result.LastModifiedDate | Should -BeGreaterThan $collection.LastModifiedDate
        }
        
        It "Should add a new item to a non-empty collection" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $info2 = New-ExtractedInfo -Source "Source2" -ExtractorName "Extractor2"
            
            # Add first item
            $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info1
            
            # Act - Add second item
            $result = Add-ExtractedInfoToCollection -Collection $collection -Info $info2
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Items.Count | Should -Be 2
            $result.Items[0].Id | Should -Be $info1.Id
            $result.Items[1].Id | Should -Be $info2.Id
        }
        
        It "Should update an existing item with the same ID" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -ProcessingState "Raw"
            
            # Add the item
            $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info
            
            # Modify the item
            $updatedInfo = Copy-ExtractedInfo -Info $info -ProcessingState "Processed"
            $updatedInfo.Id = $info.Id # Ensure same ID for update
            
            # Act - Update the item
            $result = Add-ExtractedInfoToCollection -Collection $collection -Info $updatedInfo
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Items.Count | Should -Be 1
            $result.Items[0].Id | Should -Be $info.Id
            $result.Items[0].ProcessingState | Should -Be "Processed"
        }
        
        It "Should add different types of extracted info to the collection" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            $basicInfo = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $textInfo = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Test text"
            $structuredInfo = New-StructuredDataExtractedInfo -Source "Source3" -ExtractorName "Extractor3" -Data @{ Key = "Value" }
            $mediaInfo = New-MediaExtractedInfo -Source "Source4" -ExtractorName "Extractor4" -MediaPath "C:\path\to\media.jpg" -MediaType "Image"
            
            # Act
            $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $basicInfo
            $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $textInfo
            $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $structuredInfo
            $result = Add-ExtractedInfoToCollection -Collection $collection -Info $mediaInfo
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Items.Count | Should -Be 4
            $result.Items[0]._Type | Should -Be "ExtractedInfo"
            $result.Items[1]._Type | Should -Be "TextExtractedInfo"
            $result.Items[2]._Type | Should -Be "StructuredDataExtractedInfo"
            $result.Items[3]._Type | Should -Be "MediaExtractedInfo"
        }
    }
    
    Context "When adding multiple items to a collection" {
        It "Should add multiple new items to an empty collection" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $info2 = New-ExtractedInfo -Source "Source2" -ExtractorName "Extractor2"
            $info3 = New-ExtractedInfo -Source "Source3" -ExtractorName "Extractor3"
            $items = @($info1, $info2, $info3)
            
            # Act
            $result = Add-ExtractedInfoToCollection -Collection $collection -InfoList $items
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Items.Count | Should -Be 3
            $result.Items[0].Id | Should -Be $info1.Id
            $result.Items[1].Id | Should -Be $info2.Id
            $result.Items[2].Id | Should -Be $info3.Id
        }
        
        It "Should add multiple new items to a non-empty collection" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            
            # Add first item
            $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info1
            
            # Prepare additional items
            $info2 = New-ExtractedInfo -Source "Source2" -ExtractorName "Extractor2"
            $info3 = New-ExtractedInfo -Source "Source3" -ExtractorName "Extractor3"
            $items = @($info2, $info3)
            
            # Act - Add multiple items
            $result = Add-ExtractedInfoToCollection -Collection $collection -InfoList $items
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Items.Count | Should -Be 3
            $result.Items[0].Id | Should -Be $info1.Id
            $result.Items[1].Id | Should -Be $info2.Id
            $result.Items[2].Id | Should -Be $info3.Id
        }
        
        It "Should update existing items with the same IDs" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1" -ProcessingState "Raw"
            $info2 = New-ExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -ProcessingState "Raw"
            
            # Add initial items
            $collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2)
            
            # Modify the items
            $updatedInfo1 = Copy-ExtractedInfo -Info $info1 -ProcessingState "Processed"
            $updatedInfo1.Id = $info1.Id # Ensure same ID for update
            $updatedInfo2 = Copy-ExtractedInfo -Info $info2 -ProcessingState "Validated"
            $updatedInfo2.Id = $info2.Id # Ensure same ID for update
            
            # Act - Update the items
            $result = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($updatedInfo1, $updatedInfo2)
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Items.Count | Should -Be 2
            $result.Items[0].Id | Should -Be $info1.Id
            $result.Items[0].ProcessingState | Should -Be "Processed"
            $result.Items[1].Id | Should -Be $info2.Id
            $result.Items[1].ProcessingState | Should -Be "Validated"
        }
        
        It "Should handle a mix of new and existing items" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            
            # Add first item
            $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info1
            
            # Prepare updated first item and new second item
            $updatedInfo1 = Copy-ExtractedInfo -Info $info1 -ProcessingState "Processed"
            $updatedInfo1.Id = $info1.Id # Ensure same ID for update
            $info2 = New-ExtractedInfo -Source "Source2" -ExtractorName "Extractor2"
            
            # Act - Add/update items
            $result = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($updatedInfo1, $info2)
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Items.Count | Should -Be 2
            $result.Items[0].Id | Should -Be $info1.Id
            $result.Items[0].ProcessingState | Should -Be "Processed"
            $result.Items[1].Id | Should -Be $info2.Id
        }
    }
    
    Context "When adding items to a collection with indexes" {
        It "Should update indexes when adding a new item" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection" -CreateIndexes
            $info = New-TextExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Text "Test text" -ProcessingState "Raw"
            
            # Act
            $result = Add-ExtractedInfoToCollection -Collection $collection -Info $info
            
            # Assert
            $result.Indexes | Should -Not -BeNullOrEmpty
            $result.Indexes.ID.ContainsKey($info.Id) | Should -Be $true
            $result.Indexes.Type.ContainsKey("TextExtractedInfo") | Should -Be $true
            $result.Indexes.Type["TextExtractedInfo"] | Should -Contain $info.Id
            $result.Indexes.Source.ContainsKey("TestSource") | Should -Be $true
            $result.Indexes.Source["TestSource"] | Should -Contain $info.Id
            $result.Indexes.ProcessingState.ContainsKey("Raw") | Should -Be $true
            $result.Indexes.ProcessingState["Raw"] | Should -Contain $info.Id
        }
        
        It "Should update indexes when updating an existing item" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection" -CreateIndexes
            $info = New-ExtractedInfo -Source "OriginalSource" -ExtractorName "TestExtractor" -ProcessingState "Raw"
            
            # Add the item
            $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info
            
            # Modify the item
            $updatedInfo = Copy-ExtractedInfo -Info $info -Source "NewSource" -ProcessingState "Processed"
            $updatedInfo.Id = $info.Id # Ensure same ID for update
            
            # Act - Update the item
            $result = Add-ExtractedInfoToCollection -Collection $collection -Info $updatedInfo
            
            # Assert
            $result.Indexes | Should -Not -BeNullOrEmpty
            
            # ID index should still have the item
            $result.Indexes.ID.ContainsKey($info.Id) | Should -Be $true
            
            # Source index should be updated
            $result.Indexes.Source.ContainsKey("OriginalSource") | Should -Be $false
            $result.Indexes.Source.ContainsKey("NewSource") | Should -Be $true
            $result.Indexes.Source["NewSource"] | Should -Contain $info.Id
            
            # ProcessingState index should be updated
            $result.Indexes.ProcessingState.ContainsKey("Raw") | Should -Be $false
            $result.Indexes.ProcessingState.ContainsKey("Processed") | Should -Be $true
            $result.Indexes.ProcessingState["Processed"] | Should -Contain $info.Id
        }
    }
    
    Context "When handling invalid inputs" {
        It "Should throw an error when Collection is null" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            
            # Act & Assert
            { Add-ExtractedInfoToCollection -Collection $null -Info $info } | Should -Throw
        }
        
        It "Should throw an error when Info is null" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            
            # Act & Assert
            { Add-ExtractedInfoToCollection -Collection $collection -Info $null } | Should -Throw
        }
        
        It "Should throw an error when InfoList contains null items" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $info2 = $null
            
            # Act & Assert
            { Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2) } | Should -Throw
        }
        
        It "Should throw an error when Collection is not a valid collection object" {
            # Arrange
            $invalidCollection = @{
                Property = "Value"
            }
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            
            # Act & Assert
            { Add-ExtractedInfoToCollection -Collection $invalidCollection -Info $info } | Should -Throw
        }
        
        It "Should throw an error when Info is not a valid extracted info object" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            $invalidInfo = @{
                Property = "Value"
            }
            
            # Act & Assert
            { Add-ExtractedInfoToCollection -Collection $collection -Info $invalidInfo } | Should -Throw
        }
        
        It "Should throw an error when neither Info nor InfoList is provided" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            
            # Act & Assert
            { Add-ExtractedInfoToCollection -Collection $collection } | Should -Throw
        }
    }
}
