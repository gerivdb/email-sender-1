<#
.SYNOPSIS
    Tests pour valider la documentation de FormatException et ses scÃ©narios.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les exemples et les informations
    fournies dans la documentation de FormatException et ses scÃ©narios.

.NOTES
    Version:        1.0
    Author:         Augment Code
    Creation Date:  2023-06-17
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# DÃ©finir les tests
Describe "Tests de la documentation de FormatException et ses scÃ©narios" {
    Context "FormatException" {
        It "Devrait Ãªtre une sous-classe de SystemException" {
            [System.FormatException] | Should -BeOfType [System.Type]
            [System.FormatException].IsSubclassOf([System.SystemException]) | Should -Be $true
        }
        
        It "Devrait permettre de spÃ©cifier un message" {
            $exception = [System.FormatException]::new("Message de test")
            $exception.Message | Should -Be "Message de test"
        }
        
        It "Exemple 1: Devrait gÃ©rer la conversion de chaÃ®ne en nombre" {
            function Convert-ToNumber {
                param (
                    [string]$InputString
                )
                
                try {
                    return [int]::Parse($InputString)
                } catch [System.FormatException] {
                    return "Erreur de format: '$InputString' n'est pas un nombre valide"
                }
            }
            
            Convert-ToNumber -InputString "123" | Should -Be 123
            Convert-ToNumber -InputString "abc" | Should -Be "Erreur de format: 'abc' n'est pas un nombre valide"
            Convert-ToNumber -InputString "123.45" | Should -Be "Erreur de format: '123.45' n'est pas un nombre valide"
        }
        
        It "Exemple 2: Devrait gÃ©rer la conversion de chaÃ®ne en date" {
            function Convert-ToDate {
                param (
                    [string]$DateString
                )
                
                try {
                    return [DateTime]::Parse($DateString)
                } catch [System.FormatException] {
                    return "Erreur de format: '$DateString' n'est pas une date valide"
                }
            }
            
            (Convert-ToDate -DateString "2023-06-17") | Should -BeOfType [DateTime]
            Convert-ToDate -DateString "Pas une date" | Should -Be "Erreur de format: 'Pas une date' n'est pas une date valide"
        }
        
        It "Exemple 3: Devrait gÃ©rer la conversion de chaÃ®ne en GUID" {
            function Convert-ToGuid {
                param (
                    [string]$GuidString
                )
                
                try {
                    return [Guid]::Parse($GuidString)
                } catch [System.FormatException] {
                    return "Erreur de format: '$GuidString' n'est pas un GUID valide"
                }
            }
            
            (Convert-ToGuid -GuidString "12345678-1234-1234-1234-123456789012") | Should -BeOfType [Guid]
            Convert-ToGuid -GuidString "Pas un GUID" | Should -Be "Erreur de format: 'Pas un GUID' n'est pas un GUID valide"
            Convert-ToGuid -GuidString "12345678-1234-1234-1234-12345678901" | Should -Be "Erreur de format: '12345678-1234-1234-1234-12345678901' n'est pas un GUID valide"
        }
        
        It "Exemple 4: Devrait gÃ©rer le formatage de chaÃ®ne avec placeholders" {
            function Format-Message {
                param (
                    [string]$Template,
                    [object[]]$Args
                )
                
                try {
                    return [string]::Format($Template, $Args)
                } catch [System.FormatException] {
                    return "Erreur de format: Le template '$Template' est invalide avec les arguments fournis"
                }
            }
            
            Format-Message -Template "Bonjour {0}, vous avez {1} messages" -Args @("John", 5) | Should -Be "Bonjour John, vous avez 5 messages"
            Format-Message -Template "Bonjour {0}, vous avez {1} messages" -Args @("John") | Should -Be "Erreur de format: Le template 'Bonjour {0}, vous avez {1} messages' est invalide avec les arguments fournis"
            Format-Message -Template "Bonjour {0}, vous avez {2} messages" -Args @("John", 5) | Should -Be "Erreur de format: Le template 'Bonjour {0}, vous avez {2} messages' est invalide avec les arguments fournis"
        }
        
        It "Exemple 5: Devrait gÃ©rer la conversion de base64" {
            function Convert-FromBase64 {
                param (
                    [string]$Base64String
                )
                
                try {
                    $bytes = [Convert]::FromBase64String($Base64String)
                    return [System.Text.Encoding]::UTF8.GetString($bytes)
                } catch [System.FormatException] {
                    return "Erreur de format: '$Base64String' n'est pas une chaÃ®ne base64 valide"
                }
            }
            
            $validBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("Hello World"))
            Convert-FromBase64 -Base64String $validBase64 | Should -Be "Hello World"
            Convert-FromBase64 -Base64String "Pas du base64" | Should -Be "Erreur de format: 'Pas du base64' n'est pas une chaÃ®ne base64 valide"
            Convert-FromBase64 -Base64String "SGVsbG8gV29ybGQ=" | Should -Be "Hello World"
        }
    }
    
    Context "PrÃ©vention des FormatException" {
        It "Technique 1: Devrait utiliser TryParse pour Ã©viter les exceptions" {
            function Convert-ToNumberSafely {
                param (
                    [string]$InputString
                )
                
                $number = 0
                $success = [int]::TryParse($InputString, [ref]$number)
                
                if ($success) {
                    return $number
                } else {
                    return "La conversion a Ã©chouÃ©: '$InputString' n'est pas un nombre valide"
                }
            }
            
            Convert-ToNumberSafely -InputString "123" | Should -Be 123
            Convert-ToNumberSafely -InputString "abc" | Should -Be "La conversion a Ã©chouÃ©: 'abc' n'est pas un nombre valide"
        }
        
        It "Technique 2: Devrait utiliser des expressions rÃ©guliÃ¨res pour la validation prÃ©alable" {
            function Convert-ToDateSafely {
                param (
                    [string]$DateString
                )
                
                # Expression rÃ©guliÃ¨re simple pour une date au format YYYY-MM-DD
                if ($DateString -match '^\d{4}-\d{2}-\d{2}$') {
                    try {
                        return [DateTime]::Parse($DateString)
                    } catch {
                        return "La date est au bon format mais invalide: $DateString"
                    }
                } else {
                    return "Format de date incorrect: $DateString"
                }
            }
            
            (Convert-ToDateSafely -DateString "2023-06-17") | Should -BeOfType [DateTime]
            Convert-ToDateSafely -DateString "06-17-2023" | Should -Be "Format de date incorrect: 06-17-2023"
            Convert-ToDateSafely -DateString "2023-13-45" | Should -Be "La date est au bon format mais invalide: 2023-13-45"
        }
        
        It "Technique 3: Devrait utiliser des valeurs par dÃ©faut" {
            function Get-NumberWithDefault {
                param (
                    [string]$InputString,
                    [int]$DefaultValue = 0
                )
                
                $number = 0
                if ([int]::TryParse($InputString, [ref]$number)) {
                    return $number
                } else {
                    return $DefaultValue
                }
            }
            
            Get-NumberWithDefault -InputString "123" | Should -Be 123
            Get-NumberWithDefault -InputString "abc" | Should -Be 0
            Get-NumberWithDefault -InputString "xyz" -DefaultValue 42 | Should -Be 42
        }
        
        It "Technique 4: Devrait utiliser des cultures spÃ©cifiques" {
            function Convert-ToDateWithCulture {
                param (
                    [string]$DateString,
                    [string]$CultureName = "fr-FR"
                )
                
                try {
                    $culture = [System.Globalization.CultureInfo]::GetCultureInfo($CultureName)
                    return [DateTime]::Parse($DateString, $culture)
                } catch [System.FormatException] {
                    return "Erreur de format: '$DateString' n'est pas une date valide dans la culture $CultureName"
                }
            }
            
            (Convert-ToDateWithCulture -DateString "17/06/2023" -CultureName "fr-FR") | Should -BeOfType [DateTime]
            (Convert-ToDateWithCulture -DateString "06/17/2023" -CultureName "en-US") | Should -BeOfType [DateTime]
        }
    }
    
    Context "DÃ©bogage des FormatException" {
        It "Devrait fournir des informations de dÃ©bogage utiles" {
            function Debug-FormatException {
                param (
                    [string]$InputValue,
                    [string]$TargetType
                )
                
                $result = [PSCustomObject]@{
                    InputValue = $InputValue
                    TargetType = $TargetType
                    InputLength = $InputValue.Length
                    ConversionSuccess = $false
                    ConversionResult = $null
                    ExceptionType = $null
                    ExceptionMessage = $null
                }
                
                try {
                    $conversionResult = switch ($TargetType) {
                        "Int32" { [int]::Parse($InputValue) }
                        "Double" { [double]::Parse($InputValue) }
                        "DateTime" { [DateTime]::Parse($InputValue) }
                        "Guid" { [Guid]::Parse($InputValue) }
                        default { throw "Type cible non supportÃ©: $TargetType" }
                    }
                    
                    $result.ConversionSuccess = $true
                    $result.ConversionResult = $conversionResult
                } catch {
                    $result.ExceptionType = $_.Exception.GetType().FullName
                    $result.ExceptionMessage = $_.Exception.Message
                }
                
                return $result
            }
            
            $result1 = Debug-FormatException -InputValue "123" -TargetType "Int32"
            $result1.ConversionSuccess | Should -Be $true
            $result1.ConversionResult | Should -Be 123
            
            $result2 = Debug-FormatException -InputValue "abc" -TargetType "Int32"
            $result2.ConversionSuccess | Should -Be $false
            $result2.ExceptionType | Should -Be "System.FormatException"
        }
    }
    
    Context "DiffÃ©rence entre FormatException et autres exceptions de conversion" {
        It "Devrait montrer la diffÃ©rence entre les exceptions de conversion" {
            function Compare-ConversionExceptions {
                param (
                    [string]$TestCase
                )
                
                try {
                    switch ($TestCase) {
                        "Format" {
                            # GÃ©nÃ¨re FormatException
                            return [int]::Parse("abc")
                        }
                        "Overflow" {
                            # GÃ©nÃ¨re OverflowException
                            return [byte]::Parse("1000")
                        }
                        "ArgumentNull" {
                            # GÃ©nÃ¨re ArgumentNullException
                            return [int]::Parse($null)
                        }
                        default {
                            throw "Cas de test inconnu: $TestCase"
                        }
                    }
                } catch {
                    return $_.Exception.GetType().FullName
                }
            }
            
            Compare-ConversionExceptions -TestCase "Format" | Should -Be "System.FormatException"
            Compare-ConversionExceptions -TestCase "Overflow" | Should -Be "System.OverflowException"
            Compare-ConversionExceptions -TestCase "ArgumentNull" | Should -Be "System.ArgumentNullException"
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
