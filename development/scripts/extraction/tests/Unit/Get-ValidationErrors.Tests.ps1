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

Describe "Get-ExtractedInfoValidationErrors" {
    Context "When validating a basic extracted info" {
        It "Should return an empty array for a valid extracted info object" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            
            # Act
            $result = Get-ExtractedInfoValidationErrors -Info $info
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [System.Array]
            $result.Count | Should -Be 0
        }
        
        It "Should return validation errors for an object missing required properties" {
            # Arrange
            $invalidInfo = @{
                _Type = "ExtractedInfo"
                Id = [guid]::NewGuid().ToString()
                # Missing Source and ExtractorName
                ExtractionDate = Get-Date
                LastModifiedDate = Get-Date
                ProcessingState = "Raw"
                ConfidenceScore = 75
                Metadata = @{}
            }
            
            # Act
            $result = Get-ExtractedInfoValidationErrors -Info $invalidInfo
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result | Should -Contain "Missing required property: Source"
            $result | Should -Contain "Missing required property: ExtractorName"
        }
        
        It "Should return validation errors for an object with invalid property types" {
            # Arrange
            $invalidInfo = @{
                _Type = "ExtractedInfo"
                Id = [guid]::NewGuid().ToString()
                Source = 123 # Should be string
                ExtractorName = "TestExtractor"
                ExtractionDate = "Not a date" # Should be DateTime
                LastModifiedDate = Get-Date
                ProcessingState = "Raw"
                ConfidenceScore = 75
                Metadata = @{}
            }
            
            # Act
            $result = Get-ExtractedInfoValidationErrors -Info $invalidInfo
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result | Should -Contain "Invalid property type: Source should be String"
            $result | Should -Contain "Invalid property type: ExtractionDate should be DateTime"
        }
        
        It "Should return validation errors for an object with invalid property values" {
            # Arrange
            $invalidInfo = @{
                _Type = "ExtractedInfo"
                Id = [guid]::NewGuid().ToString()
                Source = "TestSource"
                ExtractorName = "TestExtractor"
                ExtractionDate = Get-Date
                LastModifiedDate = Get-Date
                ProcessingState = "InvalidState" # Invalid state
                ConfidenceScore = 150 # Out of range
                Metadata = @{}
            }
            
            # Act
            $result = Get-ExtractedInfoValidationErrors -Info $invalidInfo
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result | Should -Contain "Invalid ProcessingState value: InvalidState"
            $result | Should -Contain "ConfidenceScore must be between 0 and 100"
        }
    }
    
    Context "When validating a text extracted info" {
        It "Should return an empty array for a valid text extracted info object" {
            # Arrange
            $info = New-TextExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Text "This is a test text"
            
            # Act
            $result = Get-ExtractedInfoValidationErrors -Info $info
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 0
        }
        
        It "Should return validation errors for a text info missing required properties" {
            # Arrange
            $invalidInfo = @{
                _Type = "TextExtractedInfo"
                Id = [guid]::NewGuid().ToString()
                Source = "TestSource"
                ExtractorName = "TestExtractor"
                ExtractionDate = Get-Date
                LastModifiedDate = Get-Date
                ProcessingState = "Raw"
                ConfidenceScore = 75
                Metadata = @{}
                # Missing Text
                Language = "en"
            }
            
            # Act
            $result = Get-ExtractedInfoValidationErrors -Info $invalidInfo
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result | Should -Contain "Missing required property: Text"
        }
    }
    
    Context "When validating a structured data extracted info" {
        It "Should return an empty array for a valid structured data extracted info object" {
            # Arrange
            $data = @{
                Property1 = "Value1"
                Property2 = "Value2"
            }
            $info = New-StructuredDataExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Data $data
            
            # Act
            $result = Get-ExtractedInfoValidationErrors -Info $info
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 0
        }
        
        It "Should return validation errors for a structured data info missing required properties" {
            # Arrange
            $invalidInfo = @{
                _Type = "StructuredDataExtractedInfo"
                Id = [guid]::NewGuid().ToString()
                Source = "TestSource"
                ExtractorName = "TestExtractor"
                ExtractionDate = Get-Date
                LastModifiedDate = Get-Date
                ProcessingState = "Raw"
                ConfidenceScore = 75
                Metadata = @{}
                # Missing Data
                DataFormat = "JSON"
            }
            
            # Act
            $result = Get-ExtractedInfoValidationErrors -Info $invalidInfo
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result | Should -Contain "Missing required property: Data"
        }
    }
    
    Context "When validating a media extracted info" {
        It "Should return an empty array for a valid media extracted info object" {
            # Arrange
            $info = New-MediaExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -MediaPath "C:\path\to\media.jpg" -MediaType "Image"
            
            # Act
            $result = Get-ExtractedInfoValidationErrors -Info $info
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 0
        }
        
        It "Should return validation errors for a media info missing required properties" {
            # Arrange
            $invalidInfo = @{
                _Type = "MediaExtractedInfo"
                Id = [guid]::NewGuid().ToString()
                Source = "TestSource"
                ExtractorName = "TestExtractor"
                ExtractionDate = Get-Date
                LastModifiedDate = Get-Date
                ProcessingState = "Raw"
                ConfidenceScore = 75
                Metadata = @{}
                # Missing MediaPath
                MediaType = "Image"
                MediaSize = 1024
            }
            
            # Act
            $result = Get-ExtractedInfoValidationErrors -Info $invalidInfo
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result | Should -Contain "Missing required property: MediaPath"
        }
        
        It "Should return validation errors for a media info with invalid property values" {
            # Arrange
            $invalidInfo = @{
                _Type = "MediaExtractedInfo"
                Id = [guid]::NewGuid().ToString()
                Source = "TestSource"
                ExtractorName = "TestExtractor"
                ExtractionDate = Get-Date
                LastModifiedDate = Get-Date
                ProcessingState = "Raw"
                ConfidenceScore = 75
                Metadata = @{}
                MediaPath = "C:\path\to\media.jpg"
                MediaType = "InvalidType" # Invalid media type
                MediaSize = 1024
            }
            
            # Act
            $result = Get-ExtractedInfoValidationErrors -Info $invalidInfo
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result | Should -Contain "Invalid MediaType value: InvalidType"
        }
    }
    
    Context "When validating a collection" {
        It "Should return an empty array for a valid collection object" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            
            # Act
            $result = Get-ExtractedInfoCollectionValidationErrors -Collection $collection
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 0
        }
        
        It "Should return an empty array for a valid collection with items" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $info2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Test text"
            $collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2)
            
            # Act
            $result = Get-ExtractedInfoCollectionValidationErrors -Collection $collection
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 0
        }
        
        It "Should return validation errors for a collection missing required properties" {
            # Arrange
            $invalidCollection = @{
                _Type = "ExtractedInfoCollection"
                # Missing Name
                Description = "Test description"
                Items = @()
                Metadata = @{}
                CreationDate = Get-Date
                LastModifiedDate = Get-Date
            }
            
            # Act
            $result = Get-ExtractedInfoCollectionValidationErrors -Collection $invalidCollection
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result | Should -Contain "Missing required property: Name"
        }
        
        It "Should return validation errors for a collection with invalid items" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            
            # Create a valid collection but manually add an invalid item
            $collection.Items += @{
                _Type = "TextExtractedInfo"
                Id = [guid]::NewGuid().ToString()
                Source = "Source2"
                ExtractorName = "Extractor2"
                ExtractionDate = Get-Date
                LastModifiedDate = Get-Date
                ProcessingState = "Raw"
                ConfidenceScore = 75
                Metadata = @{}
                # Missing Text
            }
            
            # Act
            $result = Get-ExtractedInfoCollectionValidationErrors -Collection $collection -IncludeItemErrors
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result | Should -Contain "Item at index 0 has validation errors: Missing required property: Text"
        }
    }
    
    Context "When using the IncludeItemErrors parameter" {
        It "Should not include item errors by default" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            
            # Create a valid collection but manually add an invalid item
            $collection.Items += @{
                _Type = "TextExtractedInfo"
                Id = [guid]::NewGuid().ToString()
                Source = "Source2"
                ExtractorName = "Extractor2"
                ExtractionDate = Get-Date
                LastModifiedDate = Get-Date
                ProcessingState = "Raw"
                ConfidenceScore = 75
                Metadata = @{}
                # Missing Text
            }
            
            # Act
            $result = Get-ExtractedInfoCollectionValidationErrors -Collection $collection
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 0
        }
        
        It "Should include item errors when specified" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            
            # Create a valid collection but manually add an invalid item
            $collection.Items += @{
                _Type = "TextExtractedInfo"
                Id = [guid]::NewGuid().ToString()
                Source = "Source2"
                ExtractorName = "Extractor2"
                ExtractionDate = Get-Date
                LastModifiedDate = Get-Date
                ProcessingState = "Raw"
                ConfidenceScore = 75
                Metadata = @{}
                # Missing Text
            }
            
            # Act
            $result = Get-ExtractedInfoCollectionValidationErrors -Collection $collection -IncludeItemErrors
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result | Should -Contain "Item at index 0 has validation errors: Missing required property: Text"
        }
    }
    
    Context "When using the Detailed parameter" {
        It "Should return a detailed validation result for a valid object" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            
            # Act
            $result = Get-ExtractedInfoValidationErrors -Info $info -Detailed
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.IsValid | Should -BeTrue
            $result.Errors.Count | Should -Be 0
            $result.ObjectType | Should -Be "ExtractedInfo"
        }
        
        It "Should return detailed validation errors for an invalid object" {
            # Arrange
            $invalidInfo = @{
                _Type = "ExtractedInfo"
                Id = [guid]::NewGuid().ToString()
                # Missing Source
                ExtractorName = "TestExtractor"
                ExtractionDate = Get-Date
                LastModifiedDate = Get-Date
                ProcessingState = "InvalidState" # Invalid state
                ConfidenceScore = 150 # Out of range
                Metadata = @{}
            }
            
            # Act
            $result = Get-ExtractedInfoValidationErrors -Info $invalidInfo -Detailed
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.IsValid | Should -BeFalse
            $result.Errors.Count | Should -BeGreaterThan 0
            $result.Errors | Should -Contain "Missing required property: Source"
            $result.Errors | Should -Contain "Invalid ProcessingState value: InvalidState"
            $result.Errors | Should -Contain "ConfidenceScore must be between 0 and 100"
        }
        
        It "Should return detailed validation errors for a collection with invalid items" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            $validInfo = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $validInfo
            
            # Manually add an invalid item
            $collection.Items += @{
                _Type = "TextExtractedInfo"
                Id = [guid]::NewGuid().ToString()
                Source = "Source2"
                ExtractorName = "Extractor2"
                ExtractionDate = Get-Date
                LastModifiedDate = Get-Date
                ProcessingState = "Raw"
                ConfidenceScore = 75
                Metadata = @{}
                # Missing Text
            }
            
            # Act
            $result = Get-ExtractedInfoCollectionValidationErrors -Collection $collection -IncludeItemErrors -Detailed
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.IsValid | Should -BeFalse
            $result.Errors.Count | Should -BeGreaterThan 0
            $result.ItemErrors | Should -Not -BeNullOrEmpty
            $result.ItemErrors.Count | Should -Be 1
            $result.ItemErrors[0].ItemIndex | Should -Be 1
            $result.ItemErrors[0].Errors | Should -Contain "Missing required property: Text"
        }
    }
    
    Context "When using custom validation rules" {
        It "Should apply custom validation rules when provided" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -ConfidenceScore 60
            
            # Custom rule: ConfidenceScore must be at least 70
            $customRule = {
                param($Info)
                
                $errors = @()
                
                if ($Info.ConfidenceScore -lt 70) {
                    $errors += "ConfidenceScore must be at least 70"
                }
                
                return $errors
            }
            
            # Act
            $result = Get-ExtractedInfoValidationErrors -Info $info -CustomValidationRule $customRule
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result | Should -Contain "ConfidenceScore must be at least 70"
        }
        
        It "Should combine standard and custom validation rules" {
            # Arrange
            $invalidInfo = @{
                _Type = "ExtractedInfo"
                Id = [guid]::NewGuid().ToString()
                # Missing Source
                ExtractorName = "TestExtractor"
                ExtractionDate = Get-Date
                LastModifiedDate = Get-Date
                ProcessingState = "Raw"
                ConfidenceScore = 60
                Metadata = @{}
            }
            
            # Custom rule: ConfidenceScore must be at least 70
            $customRule = {
                param($Info)
                
                $errors = @()
                
                if ($Info.ConfidenceScore -lt 70) {
                    $errors += "ConfidenceScore must be at least 70"
                }
                
                return $errors
            }
            
            # Act
            $result = Get-ExtractedInfoValidationErrors -Info $invalidInfo -CustomValidationRule $customRule
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result | Should -Contain "Missing required property: Source"
            $result | Should -Contain "ConfidenceScore must be at least 70"
        }
    }
    
    Context "When handling invalid inputs" {
        It "Should throw an error when Info is null" {
            # Act & Assert
            { Get-ExtractedInfoValidationErrors -Info $null } | Should -Throw
        }
        
        It "Should throw an error when Collection is null" {
            # Act & Assert
            { Get-ExtractedInfoCollectionValidationErrors -Collection $null } | Should -Throw
        }
        
        It "Should throw an error when CustomValidationRule is not a script block" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $invalidRule = "Not a script block"
            
            # Act & Assert
            { Get-ExtractedInfoValidationErrors -Info $info -CustomValidationRule $invalidRule } | Should -Throw
        }
    }
}
