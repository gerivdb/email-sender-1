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

Describe "Add-ExtractedInfoValidationRule" {
    Context "When adding a validation rule" {
        It "Should add a validation rule to the global validation rules" {
            # Arrange
            $ruleName = "TestRule"
            $ruleScript = {
                param($Info)
                
                $errors = @()
                
                if ($Info.ConfidenceScore -lt 70) {
                    $errors += "ConfidenceScore must be at least 70"
                }
                
                return $errors
            }
            
            # Act
            $result = Add-ExtractedInfoValidationRule -Name $ruleName -Rule $ruleScript
            
            # Assert
            $result | Should -BeTrue
            
            # Verify the rule was added
            $rules = Get-ExtractedInfoValidationRules
            $rules | Should -Not -BeNullOrEmpty
            $rules.ContainsKey($ruleName) | Should -BeTrue
            $rules[$ruleName] | Should -Not -BeNullOrEmpty
        }
        
        It "Should add a validation rule with a description" {
            # Arrange
            $ruleName = "TestRuleWithDescription"
            $ruleDescription = "This rule checks if the confidence score is at least 70"
            $ruleScript = {
                param($Info)
                
                $errors = @()
                
                if ($Info.ConfidenceScore -lt 70) {
                    $errors += "ConfidenceScore must be at least 70"
                }
                
                return $errors
            }
            
            # Act
            $result = Add-ExtractedInfoValidationRule -Name $ruleName -Rule $ruleScript -Description $ruleDescription
            
            # Assert
            $result | Should -BeTrue
            
            # Verify the rule was added with description
            $rules = Get-ExtractedInfoValidationRules -Detailed
            $rules | Should -Not -BeNullOrEmpty
            $rules[$ruleName] | Should -Not -BeNullOrEmpty
            $rules[$ruleName].Description | Should -Be $ruleDescription
        }
        
        It "Should add a validation rule with a specific target type" {
            # Arrange
            $ruleName = "TestRuleForTextInfo"
            $targetType = "TextExtractedInfo"
            $ruleScript = {
                param($Info)
                
                $errors = @()
                
                if ($Info.Text.Length -lt 10) {
                    $errors += "Text must be at least 10 characters long"
                }
                
                return $errors
            }
            
            # Act
            $result = Add-ExtractedInfoValidationRule -Name $ruleName -Rule $ruleScript -TargetType $targetType
            
            # Assert
            $result | Should -BeTrue
            
            # Verify the rule was added with target type
            $rules = Get-ExtractedInfoValidationRules -Detailed
            $rules | Should -Not -BeNullOrEmpty
            $rules[$ruleName] | Should -Not -BeNullOrEmpty
            $rules[$ruleName].TargetType | Should -Be $targetType
        }
        
        It "Should override an existing rule when Force is specified" {
            # Arrange
            $ruleName = "RuleToOverride"
            $originalRule = {
                param($Info)
                return @("Original rule")
            }
            
            $newRule = {
                param($Info)
                return @("New rule")
            }
            
            # Add the original rule
            Add-ExtractedInfoValidationRule -Name $ruleName -Rule $originalRule | Out-Null
            
            # Act - Try to override without Force
            { Add-ExtractedInfoValidationRule -Name $ruleName -Rule $newRule } | Should -Throw
            
            # Act - Override with Force
            $result = Add-ExtractedInfoValidationRule -Name $ruleName -Rule $newRule -Force
            
            # Assert
            $result | Should -BeTrue
            
            # Verify the rule was overridden
            $rules = Get-ExtractedInfoValidationRules
            $rules[$ruleName] | Should -Not -BeNullOrEmpty
            
            # Create a test info to verify the rule behavior
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $errors = & $rules[$ruleName] $info
            $errors | Should -Contain "New rule"
        }
    }
    
    Context "When using validation rules" {
        BeforeEach {
            # Clear all validation rules before each test
            Clear-ExtractedInfoValidationRules
        }
        
        It "Should apply a global validation rule when validating an object" {
            # Arrange
            $ruleName = "MinConfidenceRule"
            $ruleScript = {
                param($Info)
                
                $errors = @()
                
                if ($Info.ConfidenceScore -lt 70) {
                    $errors += "ConfidenceScore must be at least 70"
                }
                
                return $errors
            }
            
            # Add the rule
            Add-ExtractedInfoValidationRule -Name $ruleName -Rule $ruleScript | Out-Null
            
            # Create a test info with low confidence score
            $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -ConfidenceScore 60
            
            # Act
            $result = Test-ExtractedInfo -Info $info -Detailed
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.IsValid | Should -BeFalse
            $result.Errors | Should -Contain "ConfidenceScore must be at least 70"
        }
        
        It "Should only apply rules targeting the specific object type" {
            # Arrange
            # Rule for TextExtractedInfo
            Add-ExtractedInfoValidationRule -Name "TextLengthRule" -Rule {
                param($Info)
                
                $errors = @()
                
                if ($Info.Text.Length -lt 10) {
                    $errors += "Text must be at least 10 characters long"
                }
                
                return $errors
            } -TargetType "TextExtractedInfo" | Out-Null
            
            # Rule for all types
            Add-ExtractedInfoValidationRule -Name "SourceRule" -Rule {
                param($Info)
                
                $errors = @()
                
                if ($Info.Source -ne "ValidSource") {
                    $errors += "Source must be 'ValidSource'"
                }
                
                return $errors
            } | Out-Null
            
            # Create a basic info (not TextExtractedInfo)
            $basicInfo = New-ExtractedInfo -Source "InvalidSource" -ExtractorName "TestExtractor"
            
            # Create a text info with short text
            $textInfo = New-TextExtractedInfo -Source "InvalidSource" -ExtractorName "TestExtractor" -Text "Short"
            
            # Act
            $basicResult = Test-ExtractedInfo -Info $basicInfo -Detailed
            $textResult = Test-ExtractedInfo -Info $textInfo -Detailed
            
            # Assert
            $basicResult | Should -Not -BeNullOrEmpty
            $basicResult.IsValid | Should -BeFalse
            $basicResult.Errors | Should -Contain "Source must be 'ValidSource'"
            $basicResult.Errors | Should -Not -Contain "Text must be at least 10 characters long"
            
            $textResult | Should -Not -BeNullOrEmpty
            $textResult.IsValid | Should -BeFalse
            $textResult.Errors | Should -Contain "Source must be 'ValidSource'"
            $textResult.Errors | Should -Contain "Text must be at least 10 characters long"
        }
        
        It "Should apply rules to collection items when validating a collection" {
            # Arrange
            # Rule for TextExtractedInfo
            Add-ExtractedInfoValidationRule -Name "TextLengthRule" -Rule {
                param($Info)
                
                $errors = @()
                
                if ($Info.Text.Length -lt 10) {
                    $errors += "Text must be at least 10 characters long"
                }
                
                return $errors
            } -TargetType "TextExtractedInfo" | Out-Null
            
            # Create a collection with a valid basic info and an invalid text info
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            $basicInfo = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
            $textInfo = New-TextExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor" -Text "Short"
            $collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($basicInfo, $textInfo)
            
            # Act
            $result = Test-ExtractedInfoCollection -Collection $collection -IncludeItemErrors -Detailed
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.IsValid | Should -BeFalse
            $result.ItemErrors | Should -Not -BeNullOrEmpty
            $result.ItemErrors.Count | Should -Be 1
            $result.ItemErrors[0].ItemIndex | Should -Be 1
            $result.ItemErrors[0].Errors | Should -Contain "Text must be at least 10 characters long"
        }
    }
    
    Context "When managing validation rules" {
        BeforeEach {
            # Clear all validation rules before each test
            Clear-ExtractedInfoValidationRules
        }
        
        It "Should list all validation rules" {
            # Arrange
            Add-ExtractedInfoValidationRule -Name "Rule1" -Rule { param($Info) @() } | Out-Null
            Add-ExtractedInfoValidationRule -Name "Rule2" -Rule { param($Info) @() } | Out-Null
            
            # Act
            $rules = Get-ExtractedInfoValidationRules
            
            # Assert
            $rules | Should -Not -BeNullOrEmpty
            $rules.Count | Should -Be 2
            $rules.ContainsKey("Rule1") | Should -BeTrue
            $rules.ContainsKey("Rule2") | Should -BeTrue
        }
        
        It "Should list validation rules with details" {
            # Arrange
            Add-ExtractedInfoValidationRule -Name "Rule1" -Rule { param($Info) @() } -Description "Description 1" -TargetType "ExtractedInfo" | Out-Null
            Add-ExtractedInfoValidationRule -Name "Rule2" -Rule { param($Info) @() } -Description "Description 2" | Out-Null
            
            # Act
            $rules = Get-ExtractedInfoValidationRules -Detailed
            
            # Assert
            $rules | Should -Not -BeNullOrEmpty
            $rules.Count | Should -Be 2
            $rules["Rule1"].Description | Should -Be "Description 1"
            $rules["Rule1"].TargetType | Should -Be "ExtractedInfo"
            $rules["Rule2"].Description | Should -Be "Description 2"
            $rules["Rule2"].TargetType | Should -BeNullOrEmpty
        }
        
        It "Should remove a specific validation rule" {
            # Arrange
            Add-ExtractedInfoValidationRule -Name "Rule1" -Rule { param($Info) @() } | Out-Null
            Add-ExtractedInfoValidationRule -Name "Rule2" -Rule { param($Info) @() } | Out-Null
            
            # Act
            $result = Remove-ExtractedInfoValidationRule -Name "Rule1"
            
            # Assert
            $result | Should -BeTrue
            
            # Verify the rule was removed
            $rules = Get-ExtractedInfoValidationRules
            $rules.Count | Should -Be 1
            $rules.ContainsKey("Rule1") | Should -BeFalse
            $rules.ContainsKey("Rule2") | Should -BeTrue
        }
        
        It "Should clear all validation rules" {
            # Arrange
            Add-ExtractedInfoValidationRule -Name "Rule1" -Rule { param($Info) @() } | Out-Null
            Add-ExtractedInfoValidationRule -Name "Rule2" -Rule { param($Info) @() } | Out-Null
            
            # Act
            $result = Clear-ExtractedInfoValidationRules
            
            # Assert
            $result | Should -BeTrue
            
            # Verify all rules were removed
            $rules = Get-ExtractedInfoValidationRules
            $rules.Count | Should -Be 0
        }
    }
    
    Context "When handling invalid inputs" {
        It "Should throw an error when Name is null or empty" {
            # Arrange
            $ruleScript = { param($Info) @() }
            
            # Act & Assert
            { Add-ExtractedInfoValidationRule -Name $null -Rule $ruleScript } | Should -Throw
            { Add-ExtractedInfoValidationRule -Name "" -Rule $ruleScript } | Should -Throw
        }
        
        It "Should throw an error when Rule is null" {
            # Act & Assert
            { Add-ExtractedInfoValidationRule -Name "TestRule" -Rule $null } | Should -Throw
        }
        
        It "Should throw an error when Rule is not a script block" {
            # Arrange
            $invalidRule = "Not a script block"
            
            # Act & Assert
            { Add-ExtractedInfoValidationRule -Name "TestRule" -Rule $invalidRule } | Should -Throw
        }
        
        It "Should throw an error when TargetType is invalid" {
            # Arrange
            $ruleScript = { param($Info) @() }
            $invalidType = "InvalidType"
            
            # Act & Assert
            { Add-ExtractedInfoValidationRule -Name "TestRule" -Rule $ruleScript -TargetType $invalidType } | Should -Throw
        }
        
        It "Should throw an error when trying to add a rule with an existing name without Force" {
            # Arrange
            $ruleName = "ExistingRule"
            $ruleScript = { param($Info) @() }
            
            # Add the rule first
            Add-ExtractedInfoValidationRule -Name $ruleName -Rule $ruleScript | Out-Null
            
            # Act & Assert
            { Add-ExtractedInfoValidationRule -Name $ruleName -Rule $ruleScript } | Should -Throw
        }
    }
}
