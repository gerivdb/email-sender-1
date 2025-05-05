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

Describe "ConvertFrom-ExtractedInfoJson" {
    Context "When converting JSON to a basic extracted info" {
        It "Should convert valid JSON to a basic extracted info object" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -ProcessingState "Raw" -ConfidenceScore 75
            $info = Add-ExtractedInfoMetadata -Info $info -Key "TestKey" -Value "TestValue"
            $json = ConvertTo-ExtractedInfoJson -Info $info
            
            # Act
            $result = ConvertFrom-ExtractedInfoJson -Json $json
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result._Type | Should -Be $info._Type
            $result.Id | Should -Be $info.Id
            $result.Source | Should -Be $info.Source
            $result.ExtractorName | Should -Be $info.ExtractorName
            $result.ProcessingState | Should -Be $info.ProcessingState
            $result.ConfidenceScore | Should -Be $info.ConfidenceScore
            $result.Metadata.TestKey | Should -Be "TestValue"
        }
        
        It "Should convert valid JSON to a text extracted info object" {
            # Arrange
            $info = New-TextExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Text "This is a test text" -Language "en"
            $json = ConvertTo-ExtractedInfoJson -Info $info
            
            # Act
            $result = ConvertFrom-ExtractedInfoJson -Json $json
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result._Type | Should -Be "TextExtractedInfo"
            $result.Text | Should -Be $info.Text
            $result.Language | Should -Be $info.Language
        }
        
        It "Should convert valid JSON to a structured data extracted info object" {
            # Arrange
            $data = @{
                Property1 = "Value1"
                Property2 = @{
                    NestedProperty = "NestedValue"
                }
                Property3 = @(1, 2, 3)
            }
            $info = New-StructuredDataExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Data $data -DataFormat "JSON"
            $json = ConvertTo-ExtractedInfoJson -Info $info
            
            # Act
            $result = ConvertFrom-ExtractedInfoJson -Json $json
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result._Type | Should -Be "StructuredDataExtractedInfo"
            $result.DataFormat | Should -Be "JSON"
            $result.Data.Property1 | Should -Be "Value1"
            $result.Data.Property2.NestedProperty | Should -Be "NestedValue"
            $result.Data.Property3[0] | Should -Be 1
            $result.Data.Property3[1] | Should -Be 2
            $result.Data.Property3[2] | Should -Be 3
        }
        
        It "Should convert valid JSON to a media extracted info object" {
            # Arrange
            $info = New-MediaExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -MediaPath "C:\path\to\media.jpg" -MediaType "Image" -MediaSize 1024
            $json = ConvertTo-ExtractedInfoJson -Info $info
            
            # Act
            $result = ConvertFrom-ExtractedInfoJson -Json $json
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result._Type | Should -Be "MediaExtractedInfo"
            $result.MediaPath | Should -Be $info.MediaPath
            $result.MediaType | Should -Be $info.MediaType
            $result.MediaSize | Should -Be $info.MediaSize
        }
    }
    
    Context "When converting JSON to a collection" {
        It "Should convert valid JSON to a collection object" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection" -Description "Test description"
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $info2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Test text"
            $collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2)
            $json = ConvertTo-ExtractedInfoJson -Collection $collection
            
            # Act
            $result = ConvertFrom-ExtractedInfoJson -Json $json
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result._Type | Should -Be "ExtractedInfoCollection"
            $result.Name | Should -Be "TestCollection"
            $result.Description | Should -Be "Test description"
            $result.Items.Count | Should -Be 2
            $result.Items[0]._Type | Should -Be "ExtractedInfo"
            $result.Items[1]._Type | Should -Be "TextExtractedInfo"
            $result.Items[1].Text | Should -Be "Test text"
        }
        
        It "Should convert valid JSON to a collection object with indexes" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection" -CreateIndexes
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $info2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Test text"
            $collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2)
            $json = ConvertTo-ExtractedInfoJson -Collection $collection
            
            # Act
            $result = ConvertFrom-ExtractedInfoJson -Json $json
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Indexes | Should -Not -BeNullOrEmpty
            $result.Indexes.ID | Should -Not -BeNullOrEmpty
            $result.Indexes.Type | Should -Not -BeNullOrEmpty
            $result.Indexes.Source | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "When handling dates in JSON" {
        It "Should correctly convert date strings to DateTime objects" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $originalExtractionDate = $info.ExtractionDate
            $originalLastModifiedDate = $info.LastModifiedDate
            $json = ConvertTo-ExtractedInfoJson -Info $info
            
            # Act
            $result = ConvertFrom-ExtractedInfoJson -Json $json
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.ExtractionDate | Should -BeOfType [DateTime]
            $result.LastModifiedDate | Should -BeOfType [DateTime]
            $result.ExtractionDate | Should -Be $originalExtractionDate
            $result.LastModifiedDate | Should -Be $originalLastModifiedDate
        }
        
        It "Should correctly convert collection date strings to DateTime objects" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            $originalCreationDate = $collection.CreationDate
            $originalLastModifiedDate = $collection.LastModifiedDate
            $json = ConvertTo-ExtractedInfoJson -Collection $collection
            
            # Act
            $result = ConvertFrom-ExtractedInfoJson -Json $json
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.CreationDate | Should -BeOfType [DateTime]
            $result.LastModifiedDate | Should -BeOfType [DateTime]
            $result.CreationDate | Should -Be $originalCreationDate
            $result.LastModifiedDate | Should -Be $originalLastModifiedDate
        }
    }
    
    Context "When handling special characters in JSON" {
        It "Should correctly handle special characters in text" {
            # Arrange
            $textWithSpecialChars = "This text contains special characters: àéèêëìíîïòóôõöùúûüýÿ and symbols: !@#$%^&*()_+-=[]{}|;':\",./<>?"
            $info = New-TextExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Text $textWithSpecialChars
            $json = ConvertTo-ExtractedInfoJson -Info $info
            
            # Act
            $result = ConvertFrom-ExtractedInfoJson -Json $json
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Text | Should -Be $textWithSpecialChars
        }
        
        It "Should correctly handle escaped characters in JSON" {
            # Arrange
            $textWithEscapes = "This text contains escaped characters: \t (tab), \r\n (newline), \\ (backslash), \" (quote)"
            $info = New-TextExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Text $textWithEscapes
            $json = ConvertTo-ExtractedInfoJson -Info $info
            
            # Act
            $result = ConvertFrom-ExtractedInfoJson -Json $json
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Text | Should -Be $textWithEscapes
        }
    }
    
    Context "When handling invalid inputs" {
        It "Should throw an error when Json is null or empty" {
            # Act & Assert
            { ConvertFrom-ExtractedInfoJson -Json $null } | Should -Throw
            { ConvertFrom-ExtractedInfoJson -Json "" } | Should -Throw
        }
        
        It "Should throw an error when Json is not valid JSON" {
            # Arrange
            $invalidJson = "This is not valid JSON"
            
            # Act & Assert
            { ConvertFrom-ExtractedInfoJson -Json $invalidJson } | Should -Throw
        }
        
        It "Should throw an error when Json does not represent a valid extracted info object" {
            # Arrange
            $invalidObjectJson = '{"Property": "Value"}'
            
            # Act & Assert
            { ConvertFrom-ExtractedInfoJson -Json $invalidObjectJson } | Should -Throw
        }
        
        It "Should throw an error when Json is missing required properties" {
            # Arrange
            $missingPropertiesJson = '{"_Type": "ExtractedInfo"}'
            
            # Act & Assert
            { ConvertFrom-ExtractedInfoJson -Json $missingPropertiesJson } | Should -Throw
        }
    }
    
    Context "When using the AsHashtable parameter" {
        It "Should return a hashtable instead of a custom object when specified" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $json = ConvertTo-ExtractedInfoJson -Info $info
            
            # Act
            $result = ConvertFrom-ExtractedInfoJson -Json $json -AsHashtable
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [System.Collections.Hashtable]
            $result._Type | Should -Be "ExtractedInfo"
            $result.Source | Should -Be "TestSource"
        }
    }
    
    Context "When using the ValidateOnly parameter" {
        It "Should return true for valid extracted info JSON" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $json = ConvertTo-ExtractedInfoJson -Info $info
            
            # Act
            $result = ConvertFrom-ExtractedInfoJson -Json $json -ValidateOnly
            
            # Assert
            $result | Should -BeTrue
        }
        
        It "Should return true for valid collection JSON" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            $json = ConvertTo-ExtractedInfoJson -Collection $collection
            
            # Act
            $result = ConvertFrom-ExtractedInfoJson -Json $json -ValidateOnly
            
            # Assert
            $result | Should -BeTrue
        }
        
        It "Should return false for invalid JSON" {
            # Arrange
            $invalidJson = "This is not valid JSON"
            
            # Act
            $result = ConvertFrom-ExtractedInfoJson -Json $invalidJson -ValidateOnly -ErrorAction SilentlyContinue
            
            # Assert
            $result | Should -BeFalse
        }
        
        It "Should return false for JSON that does not represent a valid extracted info object" {
            # Arrange
            $invalidObjectJson = '{"Property": "Value"}'
            
            # Act
            $result = ConvertFrom-ExtractedInfoJson -Json $invalidObjectJson -ValidateOnly -ErrorAction SilentlyContinue
            
            # Assert
            $result | Should -BeFalse
        }
    }
}
