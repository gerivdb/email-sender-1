<#
.SYNOPSIS
    Tests unitaires pour les fonctionnalitÃ©s de conversion de donnÃ©es du module d'export Excel.
.DESCRIPTION
    Ce script contient des tests unitaires pour vÃ©rifier le bon fonctionnement
    des fonctionnalitÃ©s de conversion de donnÃ©es du module excel_exporter.ps1.
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin vers le module Ã  tester
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "excel_exporter.ps1"

# ExÃ©cuter les tests
Describe "Excel Data Conversion Tests" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $script:TestDir = Join-Path -Path $TestDrive -ChildPath "excel_data_conversion_tests"
        New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
        
        # Importer le module Ã  tester
        . $ModulePath
        
        # CrÃ©er un exporteur Excel
        $script:Exporter = New-ExcelExporter
        
        # CrÃ©er un classeur de test
        $script:WorkbookPath = Join-Path -Path $script:TestDir -ChildPath "test_data_conversion.xlsx"
        $script:WorkbookId = New-ExcelWorkbook -Exporter $script:Exporter -Path $script:WorkbookPath
        
        # CrÃ©er une feuille de test
        $script:WorksheetId = Add-ExcelWorksheet -Exporter $script:Exporter -WorkbookId $script:WorkbookId -Name "TestData"
    }
    
    AfterAll {
        # Fermer le classeur
        Close-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
    }
    
    Context "Conversion des types de donnÃ©es primitifs" {
        It "Should convert numeric values correctly" {
            # CrÃ©er des donnÃ©es de test
            $TestData = @(
                [PSCustomObject]@{
                    Name = "Integer"
                    Value = 42
                    Type = "Numeric"
                },
                [PSCustomObject]@{
                    Name = "Double"
                    Value = 3.14159
                    Type = "Numeric"
                },
                [PSCustomObject]@{
                    Name = "Decimal"
                    Value = [decimal]123.456
                    Type = "Numeric"
                }
            )
            
            # Ajouter les donnÃ©es Ã  la feuille
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Data $TestData -StartRow 1 -StartColumn 1
            
            # Sauvegarder le classeur
            Save-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
            
            # Lire les donnÃ©es
            $Data = Get-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Range "A1:C4"
            
            # VÃ©rifier les donnÃ©es
            $Data.Count | Should -Be 3
            $Data[0].Value | Should -Be 42
            $Data[1].Value | Should -Be 3.14159
            $Data[2].Value | Should -Be 123.456
        }
        
        It "Should convert string values correctly" {
            # CrÃ©er des donnÃ©es de test
            $TestData = @(
                [PSCustomObject]@{
                    Name = "Simple String"
                    Value = "Hello, World!"
                    Type = "Text"
                },
                [PSCustomObject]@{
                    Name = "Empty String"
                    Value = ""
                    Type = "Text"
                },
                [PSCustomObject]@{
                    Name = "Special Characters"
                    Value = "!@#$%^&*()"
                    Type = "Text"
                }
            )
            
            # Ajouter les donnÃ©es Ã  la feuille
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Data $TestData -StartRow 5 -StartColumn 1
            
            # Sauvegarder le classeur
            Save-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
            
            # Lire les donnÃ©es
            $Data = Get-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Range "A5:C8"
            
            # VÃ©rifier les donnÃ©es
            $Data.Count | Should -Be 3
            $Data[0].Value | Should -Be "Hello, World!"
            $Data[1].Value | Should -Be ""
            $Data[2].Value | Should -Be "!@#$%^&*()"
        }
        
        It "Should convert boolean values correctly" {
            # CrÃ©er des donnÃ©es de test
            $TestData = @(
                [PSCustomObject]@{
                    Name = "True"
                    Value = $true
                    Type = "Boolean"
                },
                [PSCustomObject]@{
                    Name = "False"
                    Value = $false
                    Type = "Boolean"
                }
            )
            
            # Ajouter les donnÃ©es Ã  la feuille
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Data $TestData -StartRow 9 -StartColumn 1
            
            # Sauvegarder le classeur
            Save-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
            
            # Lire les donnÃ©es
            $Data = Get-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Range "A9:C11"
            
            # VÃ©rifier les donnÃ©es
            $Data.Count | Should -Be 2
            $Data[0].Value | Should -Be $true
            $Data[1].Value | Should -Be $false
        }
        
        It "Should convert date and time values correctly" {
            # CrÃ©er des donnÃ©es de test
            $Date1 = Get-Date -Year 2025 -Month 4 -Day 23 -Hour 10 -Minute 30 -Second 0
            $Date2 = Get-Date -Year 2025 -Month 12 -Day 31 -Hour 23 -Minute 59 -Second 59
            
            $TestData = @(
                [PSCustomObject]@{
                    Name = "Date 1"
                    Value = $Date1
                    Type = "DateTime"
                },
                [PSCustomObject]@{
                    Name = "Date 2"
                    Value = $Date2
                    Type = "DateTime"
                }
            )
            
            # Ajouter les donnÃ©es Ã  la feuille
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Data $TestData -StartRow 12 -StartColumn 1
            
            # Sauvegarder le classeur
            Save-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
            
            # Lire les donnÃ©es
            $Data = Get-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Range "A12:C14"
            
            # VÃ©rifier les donnÃ©es
            $Data.Count | Should -Be 2
            $Data[0].Value.ToString("yyyy-MM-dd HH:mm:ss") | Should -Be $Date1.ToString("yyyy-MM-dd HH:mm:ss")
            $Data[1].Value.ToString("yyyy-MM-dd HH:mm:ss") | Should -Be $Date2.ToString("yyyy-MM-dd HH:mm:ss")
        }
        
        It "Should handle null values correctly" {
            # CrÃ©er des donnÃ©es de test
            $TestData = @(
                [PSCustomObject]@{
                    Name = "Null Value"
                    Value = $null
                    Type = "Null"
                }
            )
            
            # Ajouter les donnÃ©es Ã  la feuille
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Data $TestData -StartRow 15 -StartColumn 1
            
            # Sauvegarder le classeur
            Save-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
            
            # Lire les donnÃ©es
            $Data = Get-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Range "A15:C16"
            
            # VÃ©rifier les donnÃ©es
            $Data.Count | Should -Be 1
            $Data[0].Value | Should -BeNullOrEmpty
        }
    }
    
    Context "Conversion des structures complexes" {
        It "Should convert arrays correctly" {
            # CrÃ©er des donnÃ©es de test
            $TestData = @(
                [PSCustomObject]@{
                    Name = "Array of Numbers"
                    Values = @(1, 2, 3, 4, 5)
                },
                [PSCustomObject]@{
                    Name = "Array of Strings"
                    Values = @("a", "b", "c")
                }
            )
            
            # Ajouter les donnÃ©es Ã  la feuille
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Data $TestData -StartRow 17 -StartColumn 1
            
            # Sauvegarder le classeur
            Save-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
            
            # Lire les donnÃ©es
            $Data = Get-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Range "A17:B19"
            
            # VÃ©rifier les donnÃ©es
            $Data.Count | Should -Be 2
            $Data[0].Name | Should -Be "Array of Numbers"
            $Data[1].Name | Should -Be "Array of Strings"
        }
        
        It "Should convert hashtables correctly" {
            # CrÃ©er des donnÃ©es de test
            $TestData = @(
                [PSCustomObject]@{
                    Name = "Simple Hashtable"
                    Value = @{
                        Key1 = "Value1"
                        Key2 = 42
                        Key3 = $true
                    }
                }
            )
            
            # Ajouter les donnÃ©es Ã  la feuille
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Data $TestData -StartRow 20 -StartColumn 1
            
            # Sauvegarder le classeur
            Save-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
            
            # Lire les donnÃ©es
            $Data = Get-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Range "A20:B21"
            
            # VÃ©rifier les donnÃ©es
            $Data.Count | Should -Be 1
            $Data[0].Name | Should -Be "Simple Hashtable"
            # La valeur sera convertie en chaÃ®ne par Excel
            $Data[0].Value | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Lecture et Ã©criture de donnÃ©es" {
        It "Should read and write data correctly" {
            # CrÃ©er une nouvelle feuille
            $ReadWriteSheetId = Add-ExcelWorksheet -Exporter $script:Exporter -WorkbookId $script:WorkbookId -Name "ReadWrite"
            
            # CrÃ©er des donnÃ©es de test
            $TestData = @(
                [PSCustomObject]@{
                    ID = 1
                    Name = "John Doe"
                    Age = 30
                    Active = $true
                },
                [PSCustomObject]@{
                    ID = 2
                    Name = "Jane Smith"
                    Age = 25
                    Active = $true
                },
                [PSCustomObject]@{
                    ID = 3
                    Name = "Bob Johnson"
                    Age = 40
                    Active = $false
                }
            )
            
            # Ajouter les donnÃ©es Ã  la feuille
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $ReadWriteSheetId -Data $TestData
            
            # Sauvegarder le classeur
            Save-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
            
            # Lire les donnÃ©es
            $Data = Get-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $ReadWriteSheetId
            
            # VÃ©rifier les donnÃ©es
            $Data.Count | Should -Be 3
            $Data[0].ID | Should -Be 1
            $Data[0].Name | Should -Be "John Doe"
            $Data[0].Age | Should -Be 30
            $Data[0].Active | Should -Be $true
            
            $Data[1].ID | Should -Be 2
            $Data[1].Name | Should -Be "Jane Smith"
            $Data[1].Age | Should -Be 25
            $Data[1].Active | Should -Be $true
            
            $Data[2].ID | Should -Be 3
            $Data[2].Name | Should -Be "Bob Johnson"
            $Data[2].Age | Should -Be 40
            $Data[2].Active | Should -Be $false
        }
    }
}

# Ne pas exÃ©cuter les tests automatiquement Ã  la fin du script
# Pour exÃ©cuter les tests, utilisez la commande suivante :
# Invoke-Pester -Path .\excel_data_conversion.tests.ps1 -Output Detailed
