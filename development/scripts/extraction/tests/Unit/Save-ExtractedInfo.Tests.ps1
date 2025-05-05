BeforeAll {
    # Importer le module à tester
    $modulePath = Join-Path $PSScriptRoot "..\..\ExtractedInfoModuleV2.psm1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    }
    else {
        throw "Module not found at path: $modulePath"
    }
    
    # Créer un répertoire temporaire pour les tests
    $script:TestDir = Join-Path $TestDrive "ExtractedInfoTests"
    New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
}

Describe "Save-ExtractedInfoToFile" {
    Context "When saving a basic extracted info to a file" {
        It "Should save a basic extracted info object to a file" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -ProcessingState "Raw" -ConfidenceScore 75
            $info = Add-ExtractedInfoMetadata -Info $info -Key "TestKey" -Value "TestValue"
            $filePath = Join-Path $script:TestDir "basic_info.json"
            
            # Act
            $result = Save-ExtractedInfoToFile -Info $info -FilePath $filePath
            
            # Assert
            $result | Should -BeTrue
            Test-Path $filePath | Should -BeTrue
            
            # Verify the file content
            $fileContent = Get-Content -Path $filePath -Raw
            $fileContent | Should -Not -BeNullOrEmpty
            
            # Verify the content can be parsed back
            $parsedInfo = ConvertFrom-ExtractedInfoJson -Json $fileContent
            $parsedInfo | Should -Not -BeNullOrEmpty
            $parsedInfo._Type | Should -Be $info._Type
            $parsedInfo.Id | Should -Be $info.Id
            $parsedInfo.Source | Should -Be $info.Source
            $parsedInfo.Metadata.TestKey | Should -Be "TestValue"
        }
        
        It "Should save a text extracted info object to a file" {
            # Arrange
            $info = New-TextExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Text "This is a test text" -Language "en"
            $filePath = Join-Path $script:TestDir "text_info.json"
            
            # Act
            $result = Save-ExtractedInfoToFile -Info $info -FilePath $filePath
            
            # Assert
            $result | Should -BeTrue
            Test-Path $filePath | Should -BeTrue
            
            # Verify the content can be parsed back
            $fileContent = Get-Content -Path $filePath -Raw
            $parsedInfo = ConvertFrom-ExtractedInfoJson -Json $fileContent
            $parsedInfo | Should -Not -BeNullOrEmpty
            $parsedInfo._Type | Should -Be "TextExtractedInfo"
            $parsedInfo.Text | Should -Be $info.Text
        }
        
        It "Should save a structured data extracted info object to a file" {
            # Arrange
            $data = @{
                Property1 = "Value1"
                Property2 = @{
                    NestedProperty = "NestedValue"
                }
                Property3 = @(1, 2, 3)
            }
            $info = New-StructuredDataExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Data $data -DataFormat "JSON"
            $filePath = Join-Path $script:TestDir "structured_info.json"
            
            # Act
            $result = Save-ExtractedInfoToFile -Info $info -FilePath $filePath
            
            # Assert
            $result | Should -BeTrue
            Test-Path $filePath | Should -BeTrue
            
            # Verify the content can be parsed back
            $fileContent = Get-Content -Path $filePath -Raw
            $parsedInfo = ConvertFrom-ExtractedInfoJson -Json $fileContent
            $parsedInfo | Should -Not -BeNullOrEmpty
            $parsedInfo._Type | Should -Be "StructuredDataExtractedInfo"
            $parsedInfo.Data.Property1 | Should -Be "Value1"
            $parsedInfo.Data.Property2.NestedProperty | Should -Be "NestedValue"
        }
    }
    
    Context "When saving a collection to a file" {
        It "Should save a collection to a file" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection" -Description "Test description"
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $info2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Test text"
            $collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2)
            $filePath = Join-Path $script:TestDir "collection.json"
            
            # Act
            $result = Save-ExtractedInfoToFile -Collection $collection -FilePath $filePath
            
            # Assert
            $result | Should -BeTrue
            Test-Path $filePath | Should -BeTrue
            
            # Verify the content can be parsed back
            $fileContent = Get-Content -Path $filePath -Raw
            $parsedCollection = ConvertFrom-ExtractedInfoJson -Json $fileContent
            $parsedCollection | Should -Not -BeNullOrEmpty
            $parsedCollection._Type | Should -Be "ExtractedInfoCollection"
            $parsedCollection.Name | Should -Be "TestCollection"
            $parsedCollection.Items.Count | Should -Be 2
            $parsedCollection.Items[1]._Type | Should -Be "TextExtractedInfo"
        }
        
        It "Should save a collection with indexes to a file" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection" -CreateIndexes
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $info2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Test text"
            $collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2)
            $filePath = Join-Path $script:TestDir "collection_with_indexes.json"
            
            # Act
            $result = Save-ExtractedInfoToFile -Collection $collection -FilePath $filePath
            
            # Assert
            $result | Should -BeTrue
            Test-Path $filePath | Should -BeTrue
            
            # Verify the content can be parsed back
            $fileContent = Get-Content -Path $filePath -Raw
            $parsedCollection = ConvertFrom-ExtractedInfoJson -Json $fileContent
            $parsedCollection | Should -Not -BeNullOrEmpty
            $parsedCollection.Indexes | Should -Not -BeNullOrEmpty
            $parsedCollection.Indexes.ID | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "When using formatting options" {
        It "Should respect the Indent parameter" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $filePathWithIndent = Join-Path $script:TestDir "info_with_indent.json"
            $filePathWithoutIndent = Join-Path $script:TestDir "info_without_indent.json"
            
            # Act - With indentation
            Save-ExtractedInfoToFile -Info $info -FilePath $filePathWithIndent -Indent | Out-Null
            
            # Act - Without indentation
            Save-ExtractedInfoToFile -Info $info -FilePath $filePathWithoutIndent | Out-Null
            
            # Assert
            $contentWithIndent = Get-Content -Path $filePathWithIndent -Raw
            $contentWithoutIndent = Get-Content -Path $filePathWithoutIndent -Raw
            
            $contentWithIndent | Should -Not -BeNullOrEmpty
            $contentWithoutIndent | Should -Not -BeNullOrEmpty
            
            # Indented content should be longer and contain newlines
            $contentWithIndent.Length | Should -BeGreaterThan $contentWithoutIndent.Length
            $contentWithIndent | Should -Match "`n"
            $contentWithoutIndent | Should -Not -Match "`n"
        }
        
        It "Should respect the ExcludeMetadata parameter" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $info = Add-ExtractedInfoMetadata -Info $info -Key "TestKey" -Value "TestValue"
            $filePathWithMetadata = Join-Path $script:TestDir "info_with_metadata.json"
            $filePathWithoutMetadata = Join-Path $script:TestDir "info_without_metadata.json"
            
            # Act - With metadata
            Save-ExtractedInfoToFile -Info $info -FilePath $filePathWithMetadata | Out-Null
            
            # Act - Without metadata
            Save-ExtractedInfoToFile -Info $info -FilePath $filePathWithoutMetadata -ExcludeMetadata | Out-Null
            
            # Assert
            $contentWithMetadata = Get-Content -Path $filePathWithMetadata -Raw
            $contentWithoutMetadata = Get-Content -Path $filePathWithoutMetadata -Raw
            
            $contentWithMetadata | Should -Not -BeNullOrEmpty
            $contentWithoutMetadata | Should -Not -BeNullOrEmpty
            
            # Content with metadata should contain the metadata key
            $contentWithMetadata | Should -Match "TestKey"
            $contentWithoutMetadata | Should -Not -Match "TestKey"
        }
        
        It "Should respect the ExcludeIndexes parameter for collections" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection" -CreateIndexes
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info
            $filePathWithIndexes = Join-Path $script:TestDir "collection_with_indexes.json"
            $filePathWithoutIndexes = Join-Path $script:TestDir "collection_without_indexes.json"
            
            # Act - With indexes
            Save-ExtractedInfoToFile -Collection $collection -FilePath $filePathWithIndexes | Out-Null
            
            # Act - Without indexes
            Save-ExtractedInfoToFile -Collection $collection -FilePath $filePathWithoutIndexes -ExcludeIndexes | Out-Null
            
            # Assert
            $contentWithIndexes = Get-Content -Path $filePathWithIndexes -Raw
            $contentWithoutIndexes = Get-Content -Path $filePathWithoutIndexes -Raw
            
            $contentWithIndexes | Should -Not -BeNullOrEmpty
            $contentWithoutIndexes | Should -Not -BeNullOrEmpty
            
            # Content with indexes should contain the indexes key
            $contentWithIndexes | Should -Match "Indexes"
            $contentWithoutIndexes | Should -Not -Match "Indexes"
        }
    }
    
    Context "When handling file paths" {
        It "Should create parent directories if they don't exist" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $nestedDir = Join-Path $script:TestDir "nested/deeply/path"
            $filePath = Join-Path $nestedDir "info.json"
            
            # Act
            $result = Save-ExtractedInfoToFile -Info $info -FilePath $filePath -CreateDirectories
            
            # Assert
            $result | Should -BeTrue
            Test-Path $filePath | Should -BeTrue
        }
        
        It "Should throw an error if parent directory doesn't exist and CreateDirectories is not specified" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $nestedDir = Join-Path $script:TestDir "nonexistent/path"
            $filePath = Join-Path $nestedDir "info.json"
            
            # Act & Assert
            { Save-ExtractedInfoToFile -Info $info -FilePath $filePath } | Should -Throw
        }
        
        It "Should overwrite existing file when Force is specified" {
            # Arrange
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $info2 = New-ExtractedInfo -Source "Source2" -ExtractorName "Extractor2"
            $filePath = Join-Path $script:TestDir "overwrite_test.json"
            
            # Save first info
            Save-ExtractedInfoToFile -Info $info1 -FilePath $filePath | Out-Null
            
            # Verify first info was saved
            $content1 = Get-Content -Path $filePath -Raw
            $parsed1 = ConvertFrom-ExtractedInfoJson -Json $content1
            $parsed1.Source | Should -Be "Source1"
            
            # Act - Save second info with Force
            $result = Save-ExtractedInfoToFile -Info $info2 -FilePath $filePath -Force
            
            # Assert
            $result | Should -BeTrue
            
            # Verify file was overwritten
            $content2 = Get-Content -Path $filePath -Raw
            $parsed2 = ConvertFrom-ExtractedInfoJson -Json $content2
            $parsed2.Source | Should -Be "Source2"
        }
        
        It "Should throw an error when trying to overwrite existing file without Force" {
            # Arrange
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $info2 = New-ExtractedInfo -Source "Source2" -ExtractorName "Extractor2"
            $filePath = Join-Path $script:TestDir "no_overwrite_test.json"
            
            # Save first info
            Save-ExtractedInfoToFile -Info $info1 -FilePath $filePath | Out-Null
            
            # Act & Assert - Try to save second info without Force
            { Save-ExtractedInfoToFile -Info $info2 -FilePath $filePath } | Should -Throw
        }
    }
    
    Context "When handling invalid inputs" {
        It "Should throw an error when neither Info nor Collection is provided" {
            # Arrange
            $filePath = Join-Path $script:TestDir "invalid_test.json"
            
            # Act & Assert
            { Save-ExtractedInfoToFile -FilePath $filePath } | Should -Throw
        }
        
        It "Should throw an error when FilePath is null or empty" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            
            # Act & Assert
            { Save-ExtractedInfoToFile -Info $info -FilePath $null } | Should -Throw
            { Save-ExtractedInfoToFile -Info $info -FilePath "" } | Should -Throw
        }
        
        It "Should throw an error when Info is not a valid extracted info object" {
            # Arrange
            $invalidInfo = @{
                Property = "Value"
            }
            $filePath = Join-Path $script:TestDir "invalid_info_test.json"
            
            # Act & Assert
            { Save-ExtractedInfoToFile -Info $invalidInfo -FilePath $filePath } | Should -Throw
        }
        
        It "Should throw an error when Collection is not a valid collection object" {
            # Arrange
            $invalidCollection = @{
                Property = "Value"
            }
            $filePath = Join-Path $script:TestDir "invalid_collection_test.json"
            
            # Act & Assert
            { Save-ExtractedInfoToFile -Collection $invalidCollection -FilePath $filePath } | Should -Throw
        }
    }
}

Describe "Load-ExtractedInfoFromFile" {
    Context "When loading a basic extracted info from a file" {
        It "Should load a basic extracted info object from a file" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -ProcessingState "Raw" -ConfidenceScore 75
            $info = Add-ExtractedInfoMetadata -Info $info -Key "TestKey" -Value "TestValue"
            $filePath = Join-Path $script:TestDir "load_basic_info.json"
            Save-ExtractedInfoToFile -Info $info -FilePath $filePath | Out-Null
            
            # Act
            $result = Load-ExtractedInfoFromFile -FilePath $filePath
            
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
        
        It "Should load a text extracted info object from a file" {
            # Arrange
            $info = New-TextExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Text "This is a test text" -Language "en"
            $filePath = Join-Path $script:TestDir "load_text_info.json"
            Save-ExtractedInfoToFile -Info $info -FilePath $filePath | Out-Null
            
            # Act
            $result = Load-ExtractedInfoFromFile -FilePath $filePath
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result._Type | Should -Be "TextExtractedInfo"
            $result.Text | Should -Be $info.Text
            $result.Language | Should -Be $info.Language
        }
        
        It "Should load a structured data extracted info object from a file" {
            # Arrange
            $data = @{
                Property1 = "Value1"
                Property2 = @{
                    NestedProperty = "NestedValue"
                }
                Property3 = @(1, 2, 3)
            }
            $info = New-StructuredDataExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Data $data -DataFormat "JSON"
            $filePath = Join-Path $script:TestDir "load_structured_info.json"
            Save-ExtractedInfoToFile -Info $info -FilePath $filePath | Out-Null
            
            # Act
            $result = Load-ExtractedInfoFromFile -FilePath $filePath
            
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
    }
    
    Context "When loading a collection from a file" {
        It "Should load a collection from a file" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection" -Description "Test description"
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $info2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Test text"
            $collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2)
            $filePath = Join-Path $script:TestDir "load_collection.json"
            Save-ExtractedInfoToFile -Collection $collection -FilePath $filePath | Out-Null
            
            # Act
            $result = Load-ExtractedInfoFromFile -FilePath $filePath
            
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
        
        It "Should load a collection with indexes from a file" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection" -CreateIndexes
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $info2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Test text"
            $collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2)
            $filePath = Join-Path $script:TestDir "load_collection_with_indexes.json"
            Save-ExtractedInfoToFile -Collection $collection -FilePath $filePath | Out-Null
            
            # Act
            $result = Load-ExtractedInfoFromFile -FilePath $filePath
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Indexes | Should -Not -BeNullOrEmpty
            $result.Indexes.ID | Should -Not -BeNullOrEmpty
            $result.Indexes.Type | Should -Not -BeNullOrEmpty
            $result.Indexes.Source | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "When using the AsHashtable parameter" {
        It "Should return a hashtable instead of a custom object when specified" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $filePath = Join-Path $script:TestDir "load_as_hashtable.json"
            Save-ExtractedInfoToFile -Info $info -FilePath $filePath | Out-Null
            
            # Act
            $result = Load-ExtractedInfoFromFile -FilePath $filePath -AsHashtable
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [System.Collections.Hashtable]
            $result._Type | Should -Be "ExtractedInfo"
            $result.Source | Should -Be "TestSource"
        }
    }
    
    Context "When using the ValidateOnly parameter" {
        It "Should return true for a valid extracted info file" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $filePath = Join-Path $script:TestDir "validate_info.json"
            Save-ExtractedInfoToFile -Info $info -FilePath $filePath | Out-Null
            
            # Act
            $result = Load-ExtractedInfoFromFile -FilePath $filePath -ValidateOnly
            
            # Assert
            $result | Should -BeTrue
        }
        
        It "Should return true for a valid collection file" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            $filePath = Join-Path $script:TestDir "validate_collection.json"
            Save-ExtractedInfoToFile -Collection $collection -FilePath $filePath | Out-Null
            
            # Act
            $result = Load-ExtractedInfoFromFile -FilePath $filePath -ValidateOnly
            
            # Assert
            $result | Should -BeTrue
        }
        
        It "Should return false for an invalid file" {
            # Arrange
            $filePath = Join-Path $script:TestDir "invalid_file.json"
            "This is not valid JSON" | Set-Content -Path $filePath
            
            # Act
            $result = Load-ExtractedInfoFromFile -FilePath $filePath -ValidateOnly -ErrorAction SilentlyContinue
            
            # Assert
            $result | Should -BeFalse
        }
    }
    
    Context "When handling invalid inputs" {
        It "Should throw an error when FilePath is null or empty" {
            # Act & Assert
            { Load-ExtractedInfoFromFile -FilePath $null } | Should -Throw
            { Load-ExtractedInfoFromFile -FilePath "" } | Should -Throw
        }
        
        It "Should throw an error when file does not exist" {
            # Arrange
            $nonExistentPath = Join-Path $script:TestDir "non_existent_file.json"
            
            # Act & Assert
            { Load-ExtractedInfoFromFile -FilePath $nonExistentPath } | Should -Throw
        }
        
        It "Should throw an error when file contains invalid JSON" {
            # Arrange
            $filePath = Join-Path $script:TestDir "invalid_json.json"
            "This is not valid JSON" | Set-Content -Path $filePath
            
            # Act & Assert
            { Load-ExtractedInfoFromFile -FilePath $filePath } | Should -Throw
        }
        
        It "Should throw an error when file contains JSON that is not a valid extracted info object" {
            # Arrange
            $filePath = Join-Path $script:TestDir "invalid_object.json"
            '{"Property": "Value"}' | Set-Content -Path $filePath
            
            # Act & Assert
            { Load-ExtractedInfoFromFile -FilePath $filePath } | Should -Throw
        }
    }
}
