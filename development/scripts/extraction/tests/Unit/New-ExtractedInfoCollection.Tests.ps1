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

Describe "New-ExtractedInfoCollection" {
    Context "When creating a basic collection" {
        It "Should create a valid collection with required parameters" {
            # Arrange
            $name = "TestCollection"
            
            # Act
            $result = New-ExtractedInfoCollection -Name $name
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result._Type | Should -Be "ExtractedInfoCollection"
            $result.Name | Should -Be $name
            $result.Description | Should -Be ""
            $result.Items | Should -Not -BeNullOrEmpty
            $result.Items.Count | Should -Be 0
            $result.Metadata | Should -Not -BeNullOrEmpty
            $result.CreationDate | Should -Not -BeNullOrEmpty
            $result.LastModifiedDate | Should -Not -BeNullOrEmpty
        }
        
        It "Should create a collection with custom description" {
            # Arrange
            $name = "TestCollection"
            $description = "This is a test collection"
            
            # Act
            $result = New-ExtractedInfoCollection -Name $name -Description $description
            
            # Assert
            $result.Description | Should -Be $description
        }
        
        It "Should create a collection with custom metadata" {
            # Arrange
            $name = "TestCollection"
            $metadata = @{
                Key1 = "Value1"
                Key2 = "Value2"
            }
            
            # Act
            $result = New-ExtractedInfoCollection -Name $name -Metadata $metadata
            
            # Assert
            $result.Metadata.Key1 | Should -Be "Value1"
            $result.Metadata.Key2 | Should -Be "Value2"
        }
        
        It "Should create a collection with initial items" {
            # Arrange
            $name = "TestCollection"
            $item1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $item2 = New-ExtractedInfo -Source "Source2" -ExtractorName "Extractor2"
            $items = @($item1, $item2)
            
            # Act
            $result = New-ExtractedInfoCollection -Name $name -Items $items
            
            # Assert
            $result.Items.Count | Should -Be 2
            $result.Items[0].Source | Should -Be "Source1"
            $result.Items[1].Source | Should -Be "Source2"
        }
        
        It "Should create a collection with optimized indexes when specified" {
            # Arrange
            $name = "TestCollection"
            
            # Act
            $result = New-ExtractedInfoCollection -Name $name -CreateIndexes
            
            # Assert
            $result.Indexes | Should -Not -BeNullOrEmpty
            $result.Indexes.ContainsKey("ID") | Should -Be $true
            $result.Indexes.ContainsKey("Type") | Should -Be $true
            $result.Indexes.ContainsKey("Source") | Should -Be $true
            $result.Indexes.ContainsKey("ProcessingState") | Should -Be $true
        }
    }
    
    Context "When creating a collection with invalid parameters" {
        It "Should throw an error when Name is null or empty" {
            # Act & Assert
            { New-ExtractedInfoCollection -Name $null } | Should -Throw
            { New-ExtractedInfoCollection -Name "" } | Should -Throw
        }
        
        It "Should throw an error when Items contains invalid objects" {
            # Arrange
            $name = "TestCollection"
            $invalidItems = @(
                New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1",
                "This is not a valid extracted info object",
                New-ExtractedInfo -Source "Source2" -ExtractorName "Extractor2"
            )
            
            # Act & Assert
            { New-ExtractedInfoCollection -Name $name -Items $invalidItems } | Should -Throw
        }
    }
}

Describe "Copy-ExtractedInfoCollection" {
    Context "When copying a collection" {
        It "Should create a deep copy of a collection" {
            # Arrange
            $original = New-ExtractedInfoCollection -Name "OriginalCollection" -Description "Original description"
            $item1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $item2 = New-ExtractedInfo -Source "Source2" -ExtractorName "Extractor2"
            $original = Add-ExtractedInfoToCollection -Collection $original -Info $item1
            $original = Add-ExtractedInfoToCollection -Collection $original -Info $item2
            
            # Act
            $copy = Copy-ExtractedInfoCollection -Collection $original
            
            # Assert
            $copy | Should -Not -BeNullOrEmpty
            $copy._Type | Should -Be $original._Type
            $copy.Name | Should -Be $original.Name
            $copy.Description | Should -Be $original.Description
            $copy.Items.Count | Should -Be $original.Items.Count
            
            # Verify it's a deep copy by checking references
            $copy | Should -Not -BeSameAs $original
            $copy.Items | Should -Not -BeSameAs $original.Items
            $copy.Metadata | Should -Not -BeSameAs $original.Metadata
            
            # Verify items are also deep copied
            $copy.Items[0] | Should -Not -BeSameAs $original.Items[0]
            $copy.Items[1] | Should -Not -BeSameAs $original.Items[1]
            
            # Verify item IDs are preserved
            $copy.Items[0].Id | Should -Be $original.Items[0].Id
            $copy.Items[1].Id | Should -Be $original.Items[1].Id
        }
        
        It "Should override name when specified" {
            # Arrange
            $original = New-ExtractedInfoCollection -Name "OriginalCollection"
            $newName = "NewCollection"
            
            # Act
            $copy = Copy-ExtractedInfoCollection -Collection $original -Name $newName
            
            # Assert
            $copy.Name | Should -Be $newName
        }
        
        It "Should override description when specified" {
            # Arrange
            $original = New-ExtractedInfoCollection -Name "TestCollection" -Description "Original description"
            $newDescription = "New description"
            
            # Act
            $copy = Copy-ExtractedInfoCollection -Collection $original -Description $newDescription
            
            # Assert
            $copy.Description | Should -Be $newDescription
        }
        
        It "Should add new metadata when specified" {
            # Arrange
            $original = New-ExtractedInfoCollection -Name "TestCollection"
            $original.Metadata["OriginalKey"] = "OriginalValue"
            $newMetadata = @{
                NewKey1 = "NewValue1"
                NewKey2 = "NewValue2"
            }
            
            # Act
            $copy = Copy-ExtractedInfoCollection -Collection $original -AdditionalMetadata $newMetadata
            
            # Assert
            $copy.Metadata.OriginalKey | Should -Be "OriginalValue"
            $copy.Metadata.NewKey1 | Should -Be "NewValue1"
            $copy.Metadata.NewKey2 | Should -Be "NewValue2"
        }
        
        It "Should preserve indexes when present" {
            # Arrange
            $original = New-ExtractedInfoCollection -Name "TestCollection" -CreateIndexes
            $item1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $item2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Test text"
            $original = Add-ExtractedInfoToCollection -Collection $original -Info $item1
            $original = Add-ExtractedInfoToCollection -Collection $original -Info $item2
            
            # Act
            $copy = Copy-ExtractedInfoCollection -Collection $original
            
            # Assert
            $copy.Indexes | Should -Not -BeNullOrEmpty
            $copy.Indexes.ContainsKey("ID") | Should -Be $true
            $copy.Indexes.ContainsKey("Type") | Should -Be $true
            $copy.Indexes.ID.ContainsKey($item1.Id) | Should -Be $true
            $copy.Indexes.ID.ContainsKey($item2.Id) | Should -Be $true
            $copy.Indexes.Type.ContainsKey("ExtractedInfo") | Should -Be $true
            $copy.Indexes.Type.ContainsKey("TextExtractedInfo") | Should -Be $true
            
            # Verify indexes are deep copied
            $copy.Indexes | Should -Not -BeSameAs $original.Indexes
            $copy.Indexes.ID | Should -Not -BeSameAs $original.Indexes.ID
            $copy.Indexes.Type | Should -Not -BeSameAs $original.Indexes.Type
        }
        
        It "Should create indexes when specified even if original doesn't have them" {
            # Arrange
            $original = New-ExtractedInfoCollection -Name "TestCollection"
            $item1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $item2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Test text"
            $original = Add-ExtractedInfoToCollection -Collection $original -Info $item1
            $original = Add-ExtractedInfoToCollection -Collection $original -Info $item2
            
            # Act
            $copy = Copy-ExtractedInfoCollection -Collection $original -CreateIndexes
            
            # Assert
            $copy.Indexes | Should -Not -BeNullOrEmpty
            $copy.Indexes.ContainsKey("ID") | Should -Be $true
            $copy.Indexes.ContainsKey("Type") | Should -Be $true
            $copy.Indexes.ID.ContainsKey($item1.Id) | Should -Be $true
            $copy.Indexes.ID.ContainsKey($item2.Id) | Should -Be $true
            $copy.Indexes.Type.ContainsKey("ExtractedInfo") | Should -Be $true
            $copy.Indexes.Type.ContainsKey("TextExtractedInfo") | Should -Be $true
        }
    }
    
    Context "When handling invalid inputs" {
        It "Should throw an error when Collection is null" {
            # Act & Assert
            { Copy-ExtractedInfoCollection -Collection $null } | Should -Throw
        }
        
        It "Should throw an error when Collection is not a valid collection object" {
            # Arrange
            $invalidCollection = @{
                Property = "Value"
            }
            
            # Act & Assert
            { Copy-ExtractedInfoCollection -Collection $invalidCollection } | Should -Throw
        }
    }
}
