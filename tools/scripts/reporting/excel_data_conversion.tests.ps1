<#
.SYNOPSIS
    Tests unitaires pour les fonctionnalités de conversion de données du module d'export Excel.
.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    des fonctionnalités de conversion de données du module excel_exporter.ps1.
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin vers le module à tester
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "excel_exporter.ps1"

# Exécuter les tests
Describe "Excel Data Conversion Tests" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:TestDir = Join-Path -Path $TestDrive -ChildPath "excel_data_conversion_tests"
        New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
        
        # Importer le module à tester
        . $ModulePath
        
        # Créer un exporteur Excel
        $script:Exporter = New-ExcelExporter
        
        # Créer un classeur de test
        $script:WorkbookPath = Join-Path -Path $script:TestDir -ChildPath "test_data_conversion.xlsx"
        $script:WorkbookId = New-ExcelWorkbook -Exporter $script:Exporter -Path $script:WorkbookPath
        
        # Créer une feuille de test
        $script:WorksheetId = Add-ExcelWorksheet -Exporter $script:Exporter -WorkbookId $script:WorkbookId -Name "TestData"
    }
    
    AfterAll {
        # Fermer le classeur
        Close-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
    }
    
    Context "Conversion des types de données primitifs" {
        It "Should convert numeric values correctly" {
            # Créer des données de test
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
            
            # Ajouter les données à la feuille
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Data $TestData -StartRow 1 -StartColumn 1
            
            # Sauvegarder le classeur
            Save-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
            
            # Lire les données
            $Data = Get-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Range "A1:C4"
            
            # Vérifier les données
            $Data.Count | Should -Be 3
            $Data[0].Value | Should -Be 42
            $Data[1].Value | Should -Be 3.14159
            $Data[2].Value | Should -Be 123.456
        }
        
        It "Should convert string values correctly" {
            # Créer des données de test
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
            
            # Ajouter les données à la feuille
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Data $TestData -StartRow 5 -StartColumn 1
            
            # Sauvegarder le classeur
            Save-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
            
            # Lire les données
            $Data = Get-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Range "A5:C8"
            
            # Vérifier les données
            $Data.Count | Should -Be 3
            $Data[0].Value | Should -Be "Hello, World!"
            $Data[1].Value | Should -Be ""
            $Data[2].Value | Should -Be "!@#$%^&*()"
        }
        
        It "Should convert boolean values correctly" {
            # Créer des données de test
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
            
            # Ajouter les données à la feuille
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Data $TestData -StartRow 9 -StartColumn 1
            
            # Sauvegarder le classeur
            Save-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
            
            # Lire les données
            $Data = Get-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Range "A9:C11"
            
            # Vérifier les données
            $Data.Count | Should -Be 2
            $Data[0].Value | Should -Be $true
            $Data[1].Value | Should -Be $false
        }
        
        It "Should convert date and time values correctly" {
            # Créer des données de test
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
            
            # Ajouter les données à la feuille
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Data $TestData -StartRow 12 -StartColumn 1
            
            # Sauvegarder le classeur
            Save-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
            
            # Lire les données
            $Data = Get-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Range "A12:C14"
            
            # Vérifier les données
            $Data.Count | Should -Be 2
            $Data[0].Value.ToString("yyyy-MM-dd HH:mm:ss") | Should -Be $Date1.ToString("yyyy-MM-dd HH:mm:ss")
            $Data[1].Value.ToString("yyyy-MM-dd HH:mm:ss") | Should -Be $Date2.ToString("yyyy-MM-dd HH:mm:ss")
        }
        
        It "Should handle null values correctly" {
            # Créer des données de test
            $TestData = @(
                [PSCustomObject]@{
                    Name = "Null Value"
                    Value = $null
                    Type = "Null"
                }
            )
            
            # Ajouter les données à la feuille
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Data $TestData -StartRow 15 -StartColumn 1
            
            # Sauvegarder le classeur
            Save-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
            
            # Lire les données
            $Data = Get-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Range "A15:C16"
            
            # Vérifier les données
            $Data.Count | Should -Be 1
            $Data[0].Value | Should -BeNullOrEmpty
        }
    }
    
    Context "Conversion des structures complexes" {
        It "Should convert arrays correctly" {
            # Créer des données de test
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
            
            # Ajouter les données à la feuille
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Data $TestData -StartRow 17 -StartColumn 1
            
            # Sauvegarder le classeur
            Save-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
            
            # Lire les données
            $Data = Get-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Range "A17:B19"
            
            # Vérifier les données
            $Data.Count | Should -Be 2
            $Data[0].Name | Should -Be "Array of Numbers"
            $Data[1].Name | Should -Be "Array of Strings"
        }
        
        It "Should convert hashtables correctly" {
            # Créer des données de test
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
            
            # Ajouter les données à la feuille
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Data $TestData -StartRow 20 -StartColumn 1
            
            # Sauvegarder le classeur
            Save-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
            
            # Lire les données
            $Data = Get-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $script:WorksheetId -Range "A20:B21"
            
            # Vérifier les données
            $Data.Count | Should -Be 1
            $Data[0].Name | Should -Be "Simple Hashtable"
            # La valeur sera convertie en chaîne par Excel
            $Data[0].Value | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Lecture et écriture de données" {
        It "Should read and write data correctly" {
            # Créer une nouvelle feuille
            $ReadWriteSheetId = Add-ExcelWorksheet -Exporter $script:Exporter -WorkbookId $script:WorkbookId -Name "ReadWrite"
            
            # Créer des données de test
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
            
            # Ajouter les données à la feuille
            Add-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $ReadWriteSheetId -Data $TestData
            
            # Sauvegarder le classeur
            Save-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $script:WorkbookId
            
            # Lire les données
            $Data = Get-ExcelData -Exporter $script:Exporter -WorkbookId $script:WorkbookId -WorksheetId $ReadWriteSheetId
            
            # Vérifier les données
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

# Ne pas exécuter les tests automatiquement à la fin du script
# Pour exécuter les tests, utilisez la commande suivante :
# Invoke-Pester -Path .\excel_data_conversion.tests.ps1 -Output Detailed
