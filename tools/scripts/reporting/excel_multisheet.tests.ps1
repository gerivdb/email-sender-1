<#
.SYNOPSIS
    Tests unitaires pour le module de gestion des feuilles multiples Excel.
.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    du module excel_multisheet.ps1.
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin vers les modules à tester
$ExporterPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_exporter.ps1"
$MultiSheetPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_multisheet.ps1"

# Exécuter les tests
Describe "Excel MultiSheet Module Tests" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:TestDir = Join-Path -Path $TestDrive -ChildPath "excel_multisheet_tests"
        New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
        
        # Importer les modules à tester
        . $ExporterPath
        . $MultiSheetPath
        
        # Créer un exporteur Excel
        $script:Exporter = New-ExcelExporter
    }
    
    Context "New-ExcelMultiSheetWorkbook function" {
        It "Should create a workbook with multiple sheets" {
            $WorkbookPath = Join-Path -Path $script:TestDir -ChildPath "multi_sheet_test.xlsx"
            $SheetNames = @("Sheet1", "Sheet2", "Sheet3")
            
            $Result = New-ExcelMultiSheetWorkbook -Exporter $script:Exporter -Path $WorkbookPath -SheetNames $SheetNames
            
            $Result | Should -Not -BeNullOrEmpty
            $Result.WorkbookId | Should -Not -BeNullOrEmpty
            $Result.Worksheets.Count | Should -Be 3
            $Result.Worksheets["Sheet1"] | Should -Not -BeNullOrEmpty
            $Result.Worksheets["Sheet2"] | Should -Not -BeNullOrEmpty
            $Result.Worksheets["Sheet3"] | Should -Not -BeNullOrEmpty
            
            Test-Path -Path $WorkbookPath | Should -Be $true
            
            # Cleanup
            Close-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $Result.WorkbookId
        }
    }
    
    Context "Split-ExcelDataToSheets function" {
        It "Should split data by category" {
            # Créer un classeur de test
            $WorkbookPath = Join-Path -Path $script:TestDir -ChildPath "split_by_category_test.xlsx"
            $WorkbookId = New-ExcelWorkbook -Exporter $script:Exporter -Path $WorkbookPath
            
            # Créer des données de test
            $TestData = @(
                [PSCustomObject]@{
                    Name = "John Doe"
                    Department = "IT"
                    Salary = 50000
                },
                [PSCustomObject]@{
                    Name = "Jane Smith"
                    Department = "HR"
                    Salary = 45000
                },
                [PSCustomObject]@{
                    Name = "Bob Johnson"
                    Department = "IT"
                    Salary = 55000
                },
                [PSCustomObject]@{
                    Name = "Alice Brown"
                    Department = "Finance"
                    Salary = 60000
                },
                [PSCustomObject]@{
                    Name = "Charlie Davis"
                    Department = "HR"
                    Salary = 40000
                }
            )
            
            # Répartir les données par catégorie
            $Result = Split-ExcelDataToSheets -Exporter $script:Exporter -WorkbookId $WorkbookId -Data $TestData -Strategy "ByCategory" -CategoryProperty "Department"
            
            $Result | Should -Not -BeNullOrEmpty
            $Result.Count | Should -Be 3
            $Result["IT"] | Should -Not -BeNullOrEmpty
            $Result["HR"] | Should -Not -BeNullOrEmpty
            $Result["Finance"] | Should -Not -BeNullOrEmpty
            
            # Vérifier que le fichier a été créé
            Test-Path -Path $WorkbookPath | Should -Be $true
            
            # Cleanup
            Close-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $WorkbookId
        }
        
        It "Should split data by size" {
            # Créer un classeur de test
            $WorkbookPath = Join-Path -Path $script:TestDir -ChildPath "split_by_size_test.xlsx"
            $WorkbookId = New-ExcelWorkbook -Exporter $script:Exporter -Path $WorkbookPath
            
            # Créer des données de test (20 éléments)
            $TestData = 1..20 | ForEach-Object {
                [PSCustomObject]@{
                    ID = $_
                    Name = "Item $_"
                    Value = $_ * 10
                }
            }
            
            # Répartir les données par taille (10 éléments par feuille)
            $Result = Split-ExcelDataToSheets -Exporter $script:Exporter -WorkbookId $WorkbookId -Data $TestData -Strategy "BySize" -MaxRowsPerSheet 10 -SheetPrefix "Page"
            
            $Result | Should -Not -BeNullOrEmpty
            $Result.Count | Should -Be 2
            $Result["Page1"] | Should -Not -BeNullOrEmpty
            $Result["Page2"] | Should -Not -BeNullOrEmpty
            
            # Vérifier que le fichier a été créé
            Test-Path -Path $WorkbookPath | Should -Be $true
            
            # Cleanup
            Close-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $WorkbookId
        }
    }
    
    Context "Add-ExcelTableOfContents function" {
        It "Should create a table of contents" {
            # Créer un classeur de test avec plusieurs feuilles
            $WorkbookPath = Join-Path -Path $script:TestDir -ChildPath "toc_test.xlsx"
            $SheetNames = @("Data", "Charts", "Summary")
            
            $Result = New-ExcelMultiSheetWorkbook -Exporter $script:Exporter -Path $WorkbookPath -SheetNames $SheetNames
            
            # Créer une table des matières
            $Descriptions = @{
                $Result.Worksheets["Data"] = "Données brutes"
                $Result.Worksheets["Charts"] = "Graphiques et visualisations"
                $Result.Worksheets["Summary"] = "Résumé des résultats"
            }
            
            $TocSheetId = Add-ExcelTableOfContents -Exporter $script:Exporter -WorkbookId $Result.WorkbookId -TocSheetName "Contents" -IncludeDescription $true -Descriptions $Descriptions
            
            $TocSheetId | Should -Not -BeNullOrEmpty
            
            # Vérifier que le fichier a été créé
            Test-Path -Path $WorkbookPath | Should -Be $true
            
            # Cleanup
            Close-ExcelWorkbook -Exporter $script:Exporter -WorkbookId $Result.WorkbookId
        }
    }
}

# Ne pas exécuter les tests automatiquement à la fin du script
# Pour exécuter les tests, utilisez la commande suivante :
# Invoke-Pester -Path .\excel_multisheet.tests.ps1 -Output Detailed
