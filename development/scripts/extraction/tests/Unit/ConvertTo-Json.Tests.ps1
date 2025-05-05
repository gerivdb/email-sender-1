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

Describe "ConvertTo-ExtractedInfoJson" {
    Context "When converting a basic extracted info to JSON" {
        It "Should convert a basic extracted info object to valid JSON" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -ProcessingState "Raw" -ConfidenceScore 75
            $info = Add-ExtractedInfoMetadata -Info $info -Key "TestKey" -Value "TestValue"
            
            # Act
            $result = ConvertTo-ExtractedInfoJson -Info $info
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            
            # Verify the JSON can be parsed back to an object
            $parsedObject = $result | ConvertFrom-Json
            $parsedObject | Should -Not -BeNullOrEmpty
            $parsedObject._Type | Should -Be $info._Type
            $parsedObject.Id | Should -Be $info.Id
            $parsedObject.Source | Should -Be $info.Source
            $parsedObject.ExtractorName | Should -Be $info.ExtractorName
            $parsedObject.ProcessingState | Should -Be $info.ProcessingState
            $parsedObject.ConfidenceScore | Should -Be $info.ConfidenceScore
            $parsedObject.Metadata.TestKey | Should -Be "TestValue"
        }
        
        It "Should convert a text extracted info object to valid JSON" {
            # Arrange
            $info = New-TextExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Text "This is a test text" -Language "en"
            
            # Act
            $result = ConvertTo-ExtractedInfoJson -Info $info
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            
            # Verify the JSON can be parsed back to an object
            $parsedObject = $result | ConvertFrom-Json
            $parsedObject | Should -Not -BeNullOrEmpty
            $parsedObject._Type | Should -Be "TextExtractedInfo"
            $parsedObject.Text | Should -Be $info.Text
            $parsedObject.Language | Should -Be $info.Language
        }
        
        It "Should convert a structured data extracted info object to valid JSON" {
            # Arrange
            $data = @{
                Property1 = "Value1"
                Property2 = @{
                    NestedProperty = "NestedValue"
                }
                Property3 = @(1, 2, 3)
            }
            $info = New-StructuredDataExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Data $data -DataFormat "JSON"
            
            # Act
            $result = ConvertTo-ExtractedInfoJson -Info $info
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            
            # Verify the JSON can be parsed back to an object
            $parsedObject = $result | ConvertFrom-Json
            $parsedObject | Should -Not -BeNullOrEmpty
            $parsedObject._Type | Should -Be "StructuredDataExtractedInfo"
            $parsedObject.DataFormat | Should -Be "JSON"
            $parsedObject.Data.Property1 | Should -Be "Value1"
            $parsedObject.Data.Property2.NestedProperty | Should -Be "NestedValue"
            $parsedObject.Data.Property3[0] | Should -Be 1
            $parsedObject.Data.Property3[1] | Should -Be 2
            $parsedObject.Data.Property3[2] | Should -Be 3
        }
        
        It "Should convert a media extracted info object to valid JSON" {
            # Arrange
            $info = New-MediaExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -MediaPath "C:\path\to\media.jpg" -MediaType "Image" -MediaSize 1024
            
            # Act
            $result = ConvertTo-ExtractedInfoJson -Info $info
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            
            # Verify the JSON can be parsed back to an object
            $parsedObject = $result | ConvertFrom-Json
            $parsedObject | Should -Not -BeNullOrEmpty
            $parsedObject._Type | Should -Be "MediaExtractedInfo"
            $parsedObject.MediaPath | Should -Be $info.MediaPath
            $parsedObject.MediaType | Should -Be $info.MediaType
            $parsedObject.MediaSize | Should -Be $info.MediaSize
        }
    }
    
    Context "When converting a collection to JSON" {
        It "Should convert a collection to valid JSON" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection" -Description "Test description"
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $info2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Test text"
            $collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2)
            
            # Act
            $result = ConvertTo-ExtractedInfoJson -Collection $collection
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            
            # Verify the JSON can be parsed back to an object
            $parsedObject = $result | ConvertFrom-Json
            $parsedObject | Should -Not -BeNullOrEmpty
            $parsedObject._Type | Should -Be "ExtractedInfoCollection"
            $parsedObject.Name | Should -Be "TestCollection"
            $parsedObject.Description | Should -Be "Test description"
            $parsedObject.Items.Count | Should -Be 2
            $parsedObject.Items[0]._Type | Should -Be "ExtractedInfo"
            $parsedObject.Items[1]._Type | Should -Be "TextExtractedInfo"
            $parsedObject.Items[1].Text | Should -Be "Test text"
        }
        
        It "Should convert a collection with indexes to valid JSON" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection" -CreateIndexes
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $info2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Test text"
            $collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2)
            
            # Act
            $result = ConvertTo-ExtractedInfoJson -Collection $collection
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            
            # Verify the JSON can be parsed back to an object
            $parsedObject = $result | ConvertFrom-Json
            $parsedObject | Should -Not -BeNullOrEmpty
            $parsedObject.Indexes | Should -Not -BeNullOrEmpty
            $parsedObject.Indexes.ID | Should -Not -BeNullOrEmpty
            $parsedObject.Indexes.Type | Should -Not -BeNullOrEmpty
            $parsedObject.Indexes.Source | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "When using formatting options" {
        It "Should respect the Indent parameter" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            
            # Act - With indentation
            $resultWithIndent = ConvertTo-ExtractedInfoJson -Info $info -Indent
            
            # Act - Without indentation
            $resultWithoutIndent = ConvertTo-ExtractedInfoJson -Info $info
            
            # Assert
            $resultWithIndent | Should -Not -BeNullOrEmpty
            $resultWithoutIndent | Should -Not -BeNullOrEmpty
            
            # Indented JSON should be longer and contain newlines
            $resultWithIndent.Length | Should -BeGreaterThan $resultWithoutIndent.Length
            $resultWithIndent | Should -Match "`n"
            $resultWithoutIndent | Should -Not -Match "`n"
        }
        
        It "Should respect the Depth parameter" {
            # Arrange
            $data = @{
                Level1 = @{
                    Level2 = @{
                        Level3 = @{
                            Level4 = "Value"
                        }
                    }
                }
            }
            $info = New-StructuredDataExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Data $data
            
            # Act - With limited depth
            $resultWithLimitedDepth = ConvertTo-ExtractedInfoJson -Info $info -Depth 2
            
            # Act - With full depth
            $resultWithFullDepth = ConvertTo-ExtractedInfoJson -Info $info -Depth 10
            
            # Assert
            $resultWithLimitedDepth | Should -Not -BeNullOrEmpty
            $resultWithFullDepth | Should -Not -BeNullOrEmpty
            
            # Limited depth JSON should be shorter
            $resultWithLimitedDepth.Length | Should -BeLessThan $resultWithFullDepth.Length
            
            # Full depth JSON should contain the deepest value
            $resultWithFullDepth | Should -Match "Value"
        }
        
        It "Should respect the ExcludeMetadata parameter" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $info = Add-ExtractedInfoMetadata -Info $info -Key "TestKey" -Value "TestValue"
            
            # Act - With metadata
            $resultWithMetadata = ConvertTo-ExtractedInfoJson -Info $info
            
            # Act - Without metadata
            $resultWithoutMetadata = ConvertTo-ExtractedInfoJson -Info $info -ExcludeMetadata
            
            # Assert
            $resultWithMetadata | Should -Not -BeNullOrEmpty
            $resultWithoutMetadata | Should -Not -BeNullOrEmpty
            
            # JSON with metadata should contain the metadata key
            $resultWithMetadata | Should -Match "TestKey"
            $resultWithoutMetadata | Should -Not -Match "TestKey"
            
            # Parse and verify
            $parsedWithMetadata = $resultWithMetadata | ConvertFrom-Json
            $parsedWithoutMetadata = $resultWithoutMetadata | ConvertFrom-Json
            
            $parsedWithMetadata.Metadata | Should -Not -BeNullOrEmpty
            $parsedWithoutMetadata.PSObject.Properties.Name | Should -Not -Contain "Metadata"
        }
        
        It "Should respect the ExcludeIndexes parameter for collections" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection" -CreateIndexes
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info
            
            # Act - With indexes
            $resultWithIndexes = ConvertTo-ExtractedInfoJson -Collection $collection
            
            # Act - Without indexes
            $resultWithoutIndexes = ConvertTo-ExtractedInfoJson -Collection $collection -ExcludeIndexes
            
            # Assert
            $resultWithIndexes | Should -Not -BeNullOrEmpty
            $resultWithoutIndexes | Should -Not -BeNullOrEmpty
            
            # JSON with indexes should contain the indexes key
            $resultWithIndexes | Should -Match "Indexes"
            $resultWithoutIndexes | Should -Not -Match "Indexes"
            
            # Parse and verify
            $parsedWithIndexes = $resultWithIndexes | ConvertFrom-Json
            $parsedWithoutIndexes = $resultWithoutIndexes | ConvertFrom-Json
            
            $parsedWithIndexes.Indexes | Should -Not -BeNullOrEmpty
            $parsedWithoutIndexes.PSObject.Properties.Name | Should -Not -Contain "Indexes"
        }
    }
    
    Context "When handling invalid inputs" {
        It "Should throw an error when neither Info nor Collection is provided" {
            # Act & Assert
            { ConvertTo-ExtractedInfoJson } | Should -Throw
        }
        
        It "Should throw an error when Info is not a valid extracted info object" {
            # Arrange
            $invalidInfo = @{
                Property = "Value"
            }
            
            # Act & Assert
            { ConvertTo-ExtractedInfoJson -Info $invalidInfo } | Should -Throw
        }
        
        It "Should throw an error when Collection is not a valid collection object" {
            # Arrange
            $invalidCollection = @{
                Property = "Value"
            }
            
            # Act & Assert
            { ConvertTo-ExtractedInfoJson -Collection $invalidCollection } | Should -Throw
        }
        
        It "Should throw an error when Depth is less than 1" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            
            # Act & Assert
            { ConvertTo-ExtractedInfoJson -Info $info -Depth 0 } | Should -Throw
        }
    }
}
