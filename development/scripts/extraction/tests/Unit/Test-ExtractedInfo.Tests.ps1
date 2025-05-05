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

Describe "Test-ExtractedInfo" {
    Context "When validating a basic extracted info" {
        It "Should return true for a valid extracted info object" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            
            # Act
            $result = Test-ExtractedInfo -Info $info
            
            # Assert
            $result | Should -BeTrue
        }
        
        It "Should return false for an object missing required properties" {
            # Arrange
            $invalidInfo = @{
                _Type = "ExtractedInfo"
                Id = [guid]::NewGuid().ToString()
                # Missing Source and ExtractorName
            }
            
            # Act
            $result = Test-ExtractedInfo -Info $invalidInfo -ErrorAction SilentlyContinue
            
            # Assert
            $result | Should -BeFalse
        }
        
        It "Should return false for an object with invalid property types" {
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
            $result = Test-ExtractedInfo -Info $invalidInfo -ErrorAction SilentlyContinue
            
            # Assert
            $result | Should -BeFalse
        }
        
        It "Should return false for an object with invalid property values" {
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
            $result = Test-ExtractedInfo -Info $invalidInfo -ErrorAction SilentlyContinue
            
            # Assert
            $result | Should -BeFalse
        }
    }
    
    Context "When validating a text extracted info" {
        It "Should return true for a valid text extracted info object" {
            # Arrange
            $info = New-TextExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Text "This is a test text"
            
            # Act
            $result = Test-ExtractedInfo -Info $info
            
            # Assert
            $result | Should -BeTrue
        }
        
        It "Should return false for a text info missing required properties" {
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
            $result = Test-ExtractedInfo -Info $invalidInfo -ErrorAction SilentlyContinue
            
            # Assert
            $result | Should -BeFalse
        }
    }
    
    Context "When validating a structured data extracted info" {
        It "Should return true for a valid structured data extracted info object" {
            # Arrange
            $data = @{
                Property1 = "Value1"
                Property2 = "Value2"
            }
            $info = New-StructuredDataExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Data $data
            
            # Act
            $result = Test-ExtractedInfo -Info $info
            
            # Assert
            $result | Should -BeTrue
        }
        
        It "Should return false for a structured data info missing required properties" {
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
            $result = Test-ExtractedInfo -Info $invalidInfo -ErrorAction SilentlyContinue
            
            # Assert
            $result | Should -BeFalse
        }
    }
    
    Context "When validating a media extracted info" {
        It "Should return true for a valid media extracted info object" {
            # Arrange
            $info = New-MediaExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -MediaPath "C:\path\to\media.jpg" -MediaType "Image"
            
            # Act
            $result = Test-ExtractedInfo -Info $info
            
            # Assert
            $result | Should -BeTrue
        }
        
        It "Should return false for a media info missing required properties" {
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
            $result = Test-ExtractedInfo -Info $invalidInfo -ErrorAction SilentlyContinue
            
            # Assert
            $result | Should -BeFalse
        }
        
        It "Should return false for a media info with invalid property values" {
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
            $result = Test-ExtractedInfo -Info $invalidInfo -ErrorAction SilentlyContinue
            
            # Assert
            $result | Should -BeFalse
        }
    }
    
    Context "When validating a collection" {
        It "Should return true for a valid collection object" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            
            # Act
            $result = Test-ExtractedInfoCollection -Collection $collection
            
            # Assert
            $result | Should -BeTrue
        }
        
        It "Should return true for a valid collection with items" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            $info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
            $info2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Test text"
            $collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2)
            
            # Act
            $result = Test-ExtractedInfoCollection -Collection $collection
            
            # Assert
            $result | Should -BeTrue
        }
        
        It "Should return false for a collection missing required properties" {
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
            $result = Test-ExtractedInfoCollection -Collection $invalidCollection -ErrorAction SilentlyContinue
            
            # Assert
            $result | Should -BeFalse
        }
        
        It "Should return false for a collection with invalid items" {
            # Arrange
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            
            # Create a valid collection but manually add an invalid item
            $collection.Items += @{
                _Type = "InvalidType"
                Id = [guid]::NewGuid().ToString()
            }
            
            # Act
            $result = Test-ExtractedInfoCollection -Collection $collection -ErrorAction SilentlyContinue
            
            # Assert
            $result | Should -BeFalse
        }
    }
    
    Context "When using the Detailed parameter" {
        It "Should return a detailed validation result for a valid object" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            
            # Act
            $result = Test-ExtractedInfo -Info $info -Detailed
            
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
            $result = Test-ExtractedInfo -Info $invalidInfo -Detailed -ErrorAction SilentlyContinue
            
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
            $result = Test-ExtractedInfoCollection -Collection $collection -Detailed -ErrorAction SilentlyContinue
            
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
                
                $isValid = $true
                $errors = @()
                
                if ($Info.ConfidenceScore -lt 70) {
                    $isValid = $false
                    $errors += "ConfidenceScore must be at least 70"
                }
                
                return @{
                    IsValid = $isValid
                    Errors = $errors
                }
            }
            
            # Act
            $result = Test-ExtractedInfo -Info $info -CustomValidationRule $customRule -Detailed -ErrorAction SilentlyContinue
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.IsValid | Should -BeFalse
            $result.Errors | Should -Contain "ConfidenceScore must be at least 70"
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
                
                $isValid = $true
                $errors = @()
                
                if ($Info.ConfidenceScore -lt 70) {
                    $isValid = $false
                    $errors += "ConfidenceScore must be at least 70"
                }
                
                return @{
                    IsValid = $isValid
                    Errors = $errors
                }
            }
            
            # Act
            $result = Test-ExtractedInfo -Info $invalidInfo -CustomValidationRule $customRule -Detailed -ErrorAction SilentlyContinue
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.IsValid | Should -BeFalse
            $result.Errors | Should -Contain "Missing required property: Source"
            $result.Errors | Should -Contain "ConfidenceScore must be at least 70"
        }
    }
    
    Context "When handling invalid inputs" {
        It "Should throw an error when Info is null" {
            # Act & Assert
            { Test-ExtractedInfo -Info $null } | Should -Throw
        }
        
        It "Should throw an error when Collection is null" {
            # Act & Assert
            { Test-ExtractedInfoCollection -Collection $null } | Should -Throw
        }
        
        It "Should throw an error when CustomValidationRule is not a script block" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $invalidRule = "Not a script block"
            
            # Act & Assert
            { Test-ExtractedInfo -Info $info -CustomValidationRule $invalidRule } | Should -Throw
        }
    }
}
