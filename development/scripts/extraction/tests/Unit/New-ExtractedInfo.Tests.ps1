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

Describe "New-ExtractedInfo" {
    Context "When creating a basic extracted info" {
        It "Should create a valid extracted info object with required parameters" {
            # Arrange
            $source = "TestSource"
            $extractorName = "TestExtractor"
            
            # Act
            $result = New-ExtractedInfo -Source $source -ExtractorName $extractorName
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result._Type | Should -Be "ExtractedInfo"
            $result.Id | Should -Not -BeNullOrEmpty
            $result.Source | Should -Be $source
            $result.ExtractorName | Should -Be $extractorName
            $result.ExtractionDate | Should -Not -BeNullOrEmpty
            $result.LastModifiedDate | Should -Not -BeNullOrEmpty
            $result.ProcessingState | Should -Be "Raw"
            $result.ConfidenceScore | Should -Be 0
            $result.Metadata | Should -Not -BeNullOrEmpty
            $result.Metadata | Should -BeOfType [System.Collections.Hashtable]
        }
        
        It "Should create an extracted info with custom processing state" {
            # Arrange
            $source = "TestSource"
            $extractorName = "TestExtractor"
            $processingState = "Processed"
            
            # Act
            $result = New-ExtractedInfo -Source $source -ExtractorName $extractorName -ProcessingState $processingState
            
            # Assert
            $result.ProcessingState | Should -Be $processingState
        }
        
        It "Should create an extracted info with custom confidence score" {
            # Arrange
            $source = "TestSource"
            $extractorName = "TestExtractor"
            $confidenceScore = 85
            
            # Act
            $result = New-ExtractedInfo -Source $source -ExtractorName $extractorName -ConfidenceScore $confidenceScore
            
            # Assert
            $result.ConfidenceScore | Should -Be $confidenceScore
        }
        
        It "Should create an extracted info with custom metadata" {
            # Arrange
            $source = "TestSource"
            $extractorName = "TestExtractor"
            $metadata = @{
                Key1 = "Value1"
                Key2 = "Value2"
            }
            
            # Act
            $result = New-ExtractedInfo -Source $source -ExtractorName $extractorName -Metadata $metadata
            
            # Assert
            $result.Metadata.Key1 | Should -Be "Value1"
            $result.Metadata.Key2 | Should -Be "Value2"
        }
    }
    
    Context "When creating an extracted info with invalid parameters" {
        It "Should throw an error when Source is null or empty" {
            # Act & Assert
            { New-ExtractedInfo -Source $null -ExtractorName "TestExtractor" } | Should -Throw
            { New-ExtractedInfo -Source "" -ExtractorName "TestExtractor" } | Should -Throw
        }
        
        It "Should throw an error when ExtractorName is null or empty" {
            # Act & Assert
            { New-ExtractedInfo -Source "TestSource" -ExtractorName $null } | Should -Throw
            { New-ExtractedInfo -Source "TestSource" -ExtractorName "" } | Should -Throw
        }
        
        It "Should throw an error when ConfidenceScore is out of range" {
            # Act & Assert
            { New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -ConfidenceScore -1 } | Should -Throw
            { New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -ConfidenceScore 101 } | Should -Throw
        }
        
        It "Should throw an error when ProcessingState is invalid" {
            # Act & Assert
            { New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -ProcessingState "InvalidState" } | Should -Throw
        }
    }
}

Describe "New-TextExtractedInfo" {
    Context "When creating a text extracted info" {
        It "Should create a valid text extracted info object with required parameters" {
            # Arrange
            $source = "TestSource"
            $extractorName = "TestExtractor"
            $text = "This is a test text"
            
            # Act
            $result = New-TextExtractedInfo -Source $source -ExtractorName $extractorName -Text $text
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result._Type | Should -Be "TextExtractedInfo"
            $result.Id | Should -Not -BeNullOrEmpty
            $result.Source | Should -Be $source
            $result.ExtractorName | Should -Be $extractorName
            $result.Text | Should -Be $text
            $result.Language | Should -Be "unknown"
        }
        
        It "Should create a text extracted info with custom language" {
            # Arrange
            $source = "TestSource"
            $extractorName = "TestExtractor"
            $text = "This is a test text"
            $language = "en"
            
            # Act
            $result = New-TextExtractedInfo -Source $source -ExtractorName $extractorName -Text $text -Language $language
            
            # Assert
            $result.Language | Should -Be $language
        }
        
        It "Should throw an error when Text is null or empty" {
            # Act & Assert
            { New-TextExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Text $null } | Should -Throw
            { New-TextExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Text "" } | Should -Throw
        }
    }
}

Describe "New-StructuredDataExtractedInfo" {
    Context "When creating a structured data extracted info" {
        It "Should create a valid structured data extracted info object with required parameters" {
            # Arrange
            $source = "TestSource"
            $extractorName = "TestExtractor"
            $data = @{
                Property1 = "Value1"
                Property2 = "Value2"
            }
            
            # Act
            $result = New-StructuredDataExtractedInfo -Source $source -ExtractorName $extractorName -Data $data
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result._Type | Should -Be "StructuredDataExtractedInfo"
            $result.Id | Should -Not -BeNullOrEmpty
            $result.Source | Should -Be $source
            $result.ExtractorName | Should -Be $extractorName
            $result.Data | Should -Not -BeNullOrEmpty
            $result.Data.Property1 | Should -Be "Value1"
            $result.Data.Property2 | Should -Be "Value2"
            $result.DataFormat | Should -Be "JSON"
        }
        
        It "Should create a structured data extracted info with custom data format" {
            # Arrange
            $source = "TestSource"
            $extractorName = "TestExtractor"
            $data = @{
                Property1 = "Value1"
                Property2 = "Value2"
            }
            $dataFormat = "XML"
            
            # Act
            $result = New-StructuredDataExtractedInfo -Source $source -ExtractorName $extractorName -Data $data -DataFormat $dataFormat
            
            # Assert
            $result.DataFormat | Should -Be $dataFormat
        }
        
        It "Should throw an error when Data is null" {
            # Act & Assert
            { New-StructuredDataExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Data $null } | Should -Throw
        }
    }
}

Describe "New-MediaExtractedInfo" {
    Context "When creating a media extracted info" {
        It "Should create a valid media extracted info object with required parameters" {
            # Arrange
            $source = "TestSource"
            $extractorName = "TestExtractor"
            $mediaPath = "C:\path\to\media.jpg"
            $mediaType = "Image"
            
            # Act
            $result = New-MediaExtractedInfo -Source $source -ExtractorName $extractorName -MediaPath $mediaPath -MediaType $mediaType
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result._Type | Should -Be "MediaExtractedInfo"
            $result.Id | Should -Not -BeNullOrEmpty
            $result.Source | Should -Be $source
            $result.ExtractorName | Should -Be $extractorName
            $result.MediaPath | Should -Be $mediaPath
            $result.MediaType | Should -Be $mediaType
            $result.MediaSize | Should -Be 0
        }
        
        It "Should create a media extracted info with custom media size" {
            # Arrange
            $source = "TestSource"
            $extractorName = "TestExtractor"
            $mediaPath = "C:\path\to\media.jpg"
            $mediaType = "Image"
            $mediaSize = 1024
            
            # Act
            $result = New-MediaExtractedInfo -Source $source -ExtractorName $extractorName -MediaPath $mediaPath -MediaType $mediaType -MediaSize $mediaSize
            
            # Assert
            $result.MediaSize | Should -Be $mediaSize
        }
        
        It "Should throw an error when MediaPath is null or empty" {
            # Act & Assert
            { New-MediaExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -MediaPath $null -MediaType "Image" } | Should -Throw
            { New-MediaExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -MediaPath "" -MediaType "Image" } | Should -Throw
        }
        
        It "Should throw an error when MediaType is invalid" {
            # Act & Assert
            { New-MediaExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -MediaPath "C:\path\to\media.jpg" -MediaType "InvalidType" } | Should -Throw
        }
    }
}
