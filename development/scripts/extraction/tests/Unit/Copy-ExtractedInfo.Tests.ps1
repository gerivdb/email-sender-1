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

Describe "Copy-ExtractedInfo" {
    Context "When copying a basic extracted info" {
        It "Should create a deep copy of an extracted info object" {
            # Arrange
            $original = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            
            # Act
            $copy = Copy-ExtractedInfo -Info $original
            
            # Assert
            $copy | Should -Not -BeNullOrEmpty
            $copy._Type | Should -Be $original._Type
            $copy.Source | Should -Be $original.Source
            $copy.ExtractorName | Should -Be $original.ExtractorName
            $copy.ProcessingState | Should -Be $original.ProcessingState
            $copy.ConfidenceScore | Should -Be $original.ConfidenceScore
            
            # Verify it's a deep copy by checking references
            $copy | Should -Not -BeSameAs $original
            $copy.Metadata | Should -Not -BeSameAs $original.Metadata
        }
        
        It "Should generate a new ID for the copied object" {
            # Arrange
            $original = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            
            # Act
            $copy = Copy-ExtractedInfo -Info $original
            
            # Assert
            $copy.Id | Should -Not -BeNullOrEmpty
            $copy.Id | Should -Not -Be $original.Id
        }
        
        It "Should update the LastModifiedDate in the copied object" {
            # Arrange
            $original = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            
            # Ensure some time passes
            Start-Sleep -Milliseconds 10
            
            # Act
            $copy = Copy-ExtractedInfo -Info $original
            
            # Assert
            $copy.LastModifiedDate | Should -Not -Be $original.LastModifiedDate
            $copy.LastModifiedDate | Should -BeGreaterThan $original.LastModifiedDate
        }
        
        It "Should preserve the ExtractionDate in the copied object" {
            # Arrange
            $original = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            
            # Act
            $copy = Copy-ExtractedInfo -Info $original
            
            # Assert
            $copy.ExtractionDate | Should -Be $original.ExtractionDate
        }
        
        It "Should copy all metadata to the new object" {
            # Arrange
            $original = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $original = Add-ExtractedInfoMetadata -Info $original -Metadata @{
                Key1 = "Value1"
                Key2 = "Value2"
                Key3 = @{
                    NestedKey1 = "NestedValue1"
                    NestedKey2 = @(1, 2, 3)
                }
            }
            
            # Act
            $copy = Copy-ExtractedInfo -Info $original
            
            # Assert
            $copy.Metadata.Key1 | Should -Be $original.Metadata.Key1
            $copy.Metadata.Key2 | Should -Be $original.Metadata.Key2
            $copy.Metadata.Key3.NestedKey1 | Should -Be $original.Metadata.Key3.NestedKey1
            $copy.Metadata.Key3.NestedKey2 | Should -Be $original.Metadata.Key3.NestedKey2
            
            # Verify nested objects are also deep copied
            $copy.Metadata.Key3 | Should -Not -BeSameAs $original.Metadata.Key3
            $copy.Metadata.Key3.NestedKey2 | Should -Not -BeSameAs $original.Metadata.Key3.NestedKey2
        }
    }
    
    Context "When copying a text extracted info" {
        It "Should create a deep copy of a text extracted info object" {
            # Arrange
            $original = New-TextExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Text "This is a test text" -Language "en"
            
            # Act
            $copy = Copy-ExtractedInfo -Info $original
            
            # Assert
            $copy | Should -Not -BeNullOrEmpty
            $copy._Type | Should -Be $original._Type
            $copy.Text | Should -Be $original.Text
            $copy.Language | Should -Be $original.Language
        }
    }
    
    Context "When copying a structured data extracted info" {
        It "Should create a deep copy of a structured data extracted info object" {
            # Arrange
            $data = @{
                Property1 = "Value1"
                Property2 = @{
                    NestedProperty = "NestedValue"
                }
                Property3 = @(1, 2, 3)
            }
            $original = New-StructuredDataExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Data $data -DataFormat "JSON"
            
            # Act
            $copy = Copy-ExtractedInfo -Info $original
            
            # Assert
            $copy | Should -Not -BeNullOrEmpty
            $copy._Type | Should -Be $original._Type
            $copy.DataFormat | Should -Be $original.DataFormat
            
            # Verify data is correctly copied
            $copy.Data.Property1 | Should -Be $original.Data.Property1
            $copy.Data.Property2.NestedProperty | Should -Be $original.Data.Property2.NestedProperty
            $copy.Data.Property3 | Should -Be $original.Data.Property3
            
            # Verify nested objects are also deep copied
            $copy.Data | Should -Not -BeSameAs $original.Data
            $copy.Data.Property2 | Should -Not -BeSameAs $original.Data.Property2
            $copy.Data.Property3 | Should -Not -BeSameAs $original.Data.Property3
        }
    }
    
    Context "When copying a media extracted info" {
        It "Should create a deep copy of a media extracted info object" {
            # Arrange
            $original = New-MediaExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -MediaPath "C:\path\to\media.jpg" -MediaType "Image" -MediaSize 1024
            
            # Act
            $copy = Copy-ExtractedInfo -Info $original
            
            # Assert
            $copy | Should -Not -BeNullOrEmpty
            $copy._Type | Should -Be $original._Type
            $copy.MediaPath | Should -Be $original.MediaPath
            $copy.MediaType | Should -Be $original.MediaType
            $copy.MediaSize | Should -Be $original.MediaSize
        }
    }
    
    Context "When copying with custom parameters" {
        It "Should override source when specified" {
            # Arrange
            $original = New-ExtractedInfo -Source "OriginalSource" -ExtractorName "TestExtractor"
            $newSource = "NewSource"
            
            # Act
            $copy = Copy-ExtractedInfo -Info $original -Source $newSource
            
            # Assert
            $copy.Source | Should -Be $newSource
        }
        
        It "Should override processing state when specified" {
            # Arrange
            $original = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -ProcessingState "Raw"
            $newState = "Processed"
            
            # Act
            $copy = Copy-ExtractedInfo -Info $original -ProcessingState $newState
            
            # Assert
            $copy.ProcessingState | Should -Be $newState
        }
        
        It "Should override confidence score when specified" {
            # Arrange
            $original = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -ConfidenceScore 50
            $newScore = 75
            
            # Act
            $copy = Copy-ExtractedInfo -Info $original -ConfidenceScore $newScore
            
            # Assert
            $copy.ConfidenceScore | Should -Be $newScore
        }
        
        It "Should add new metadata when specified" {
            # Arrange
            $original = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $original = Add-ExtractedInfoMetadata -Info $original -Key "OriginalKey" -Value "OriginalValue"
            $newMetadata = @{
                NewKey1 = "NewValue1"
                NewKey2 = "NewValue2"
            }
            
            # Act
            $copy = Copy-ExtractedInfo -Info $original -AdditionalMetadata $newMetadata
            
            # Assert
            $copy.Metadata.OriginalKey | Should -Be "OriginalValue"
            $copy.Metadata.NewKey1 | Should -Be "NewValue1"
            $copy.Metadata.NewKey2 | Should -Be "NewValue2"
        }
        
        It "Should override existing metadata when specified" {
            # Arrange
            $original = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $original = Add-ExtractedInfoMetadata -Info $original -Key "CommonKey" -Value "OriginalValue"
            $newMetadata = @{
                CommonKey = "NewValue"
                NewKey = "AnotherValue"
            }
            
            # Act
            $copy = Copy-ExtractedInfo -Info $original -AdditionalMetadata $newMetadata
            
            # Assert
            $copy.Metadata.CommonKey | Should -Be "NewValue"
            $copy.Metadata.NewKey | Should -Be "AnotherValue"
        }
    }
    
    Context "When handling invalid inputs" {
        It "Should throw an error when Info is null" {
            # Act & Assert
            { Copy-ExtractedInfo -Info $null } | Should -Throw
        }
        
        It "Should throw an error when Info is not a valid extracted info object" {
            # Arrange
            $invalidInfo = @{
                Property = "Value"
            }
            
            # Act & Assert
            { Copy-ExtractedInfo -Info $invalidInfo } | Should -Throw
        }
        
        It "Should throw an error when ConfidenceScore is out of range" {
            # Arrange
            $original = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            
            # Act & Assert
            { Copy-ExtractedInfo -Info $original -ConfidenceScore -1 } | Should -Throw
            { Copy-ExtractedInfo -Info $original -ConfidenceScore 101 } | Should -Throw
        }
        
        It "Should throw an error when ProcessingState is invalid" {
            # Arrange
            $original = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            
            # Act & Assert
            { Copy-ExtractedInfo -Info $original -ProcessingState "InvalidState" } | Should -Throw
        }
    }
}
