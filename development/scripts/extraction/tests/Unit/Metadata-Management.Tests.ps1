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

Describe "Metadata Management" {
    Context "When adding metadata to extracted info" {
        It "Should add new metadata to an extracted info object" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $key = "TestKey"
            $value = "TestValue"
            
            # Act
            $result = Add-ExtractedInfoMetadata -Info $info -Key $key -Value $value
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Metadata[$key] | Should -Be $value
        }
        
        It "Should update existing metadata in an extracted info object" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $key = "TestKey"
            $value1 = "TestValue1"
            $value2 = "TestValue2"
            
            # Add initial metadata
            $info = Add-ExtractedInfoMetadata -Info $info -Key $key -Value $value1
            
            # Act - Update the metadata
            $result = Add-ExtractedInfoMetadata -Info $info -Key $key -Value $value2
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Metadata[$key] | Should -Be $value2
        }
        
        It "Should add multiple metadata entries to an extracted info object" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $metadata = @{
                Key1 = "Value1"
                Key2 = "Value2"
                Key3 = "Value3"
            }
            
            # Act
            $result = Add-ExtractedInfoMetadata -Info $info -Metadata $metadata
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Metadata.Key1 | Should -Be "Value1"
            $result.Metadata.Key2 | Should -Be "Value2"
            $result.Metadata.Key3 | Should -Be "Value3"
        }
        
        It "Should throw an error when Info is null" {
            # Act & Assert
            { Add-ExtractedInfoMetadata -Info $null -Key "TestKey" -Value "TestValue" } | Should -Throw
        }
        
        It "Should throw an error when neither Key/Value nor Metadata is provided" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            
            # Act & Assert
            { Add-ExtractedInfoMetadata -Info $info } | Should -Throw
        }
    }
    
    Context "When removing metadata from extracted info" {
        It "Should remove a metadata entry from an extracted info object" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $key = "TestKey"
            $value = "TestValue"
            
            # Add metadata
            $info = Add-ExtractedInfoMetadata -Info $info -Key $key -Value $value
            
            # Act
            $result = Remove-ExtractedInfoMetadata -Info $info -Key $key
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Metadata.ContainsKey($key) | Should -Be $false
        }
        
        It "Should not modify the object when removing a non-existent key" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $key = "NonExistentKey"
            
            # Act
            $result = Remove-ExtractedInfoMetadata -Info $info -Key $key
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Metadata | Should -Be $info.Metadata
        }
        
        It "Should remove multiple metadata entries from an extracted info object" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $metadata = @{
                Key1 = "Value1"
                Key2 = "Value2"
                Key3 = "Value3"
            }
            
            # Add metadata
            $info = Add-ExtractedInfoMetadata -Info $info -Metadata $metadata
            
            # Act
            $result = Remove-ExtractedInfoMetadata -Info $info -Keys @("Key1", "Key3")
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Metadata.ContainsKey("Key1") | Should -Be $false
            $result.Metadata.ContainsKey("Key2") | Should -Be $true
            $result.Metadata.ContainsKey("Key3") | Should -Be $false
        }
        
        It "Should throw an error when Info is null" {
            # Act & Assert
            { Remove-ExtractedInfoMetadata -Info $null -Key "TestKey" } | Should -Throw
        }
        
        It "Should throw an error when neither Key nor Keys is provided" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            
            # Act & Assert
            { Remove-ExtractedInfoMetadata -Info $info } | Should -Throw
        }
    }
    
    Context "When getting metadata from extracted info" {
        It "Should get a specific metadata value from an extracted info object" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $key = "TestKey"
            $value = "TestValue"
            
            # Add metadata
            $info = Add-ExtractedInfoMetadata -Info $info -Key $key -Value $value
            
            # Act
            $result = Get-ExtractedInfoMetadata -Info $info -Key $key
            
            # Assert
            $result | Should -Be $value
        }
        
        It "Should return null when getting a non-existent metadata key" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $key = "NonExistentKey"
            
            # Act
            $result = Get-ExtractedInfoMetadata -Info $info -Key $key
            
            # Assert
            $result | Should -BeNullOrEmpty
        }
        
        It "Should get all metadata from an extracted info object" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $metadata = @{
                Key1 = "Value1"
                Key2 = "Value2"
                Key3 = "Value3"
            }
            
            # Add metadata
            $info = Add-ExtractedInfoMetadata -Info $info -Metadata $metadata
            
            # Act
            $result = Get-ExtractedInfoMetadata -Info $info
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Key1 | Should -Be "Value1"
            $result.Key2 | Should -Be "Value2"
            $result.Key3 | Should -Be "Value3"
        }
        
        It "Should throw an error when Info is null" {
            # Act & Assert
            { Get-ExtractedInfoMetadata -Info $null } | Should -Throw
        }
    }
    
    Context "When clearing metadata from extracted info" {
        It "Should clear all metadata from an extracted info object" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $metadata = @{
                Key1 = "Value1"
                Key2 = "Value2"
                Key3 = "Value3"
            }
            
            # Add metadata
            $info = Add-ExtractedInfoMetadata -Info $info -Metadata $metadata
            
            # Act
            $result = Clear-ExtractedInfoMetadata -Info $info
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Metadata.Count | Should -Be 0
        }
        
        It "Should not modify the object when clearing already empty metadata" {
            # Arrange
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $info.Metadata.Clear()
            
            # Act
            $result = Clear-ExtractedInfoMetadata -Info $info
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Metadata.Count | Should -Be 0
        }
        
        It "Should throw an error when Info is null" {
            # Act & Assert
            { Clear-ExtractedInfoMetadata -Info $null } | Should -Throw
        }
    }
}
