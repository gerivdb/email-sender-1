<#
.SYNOPSIS
    Tests unitaires pour le module d'export Excel.
.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    du module excel_exporter.ps1.
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
Describe "Excel Exporter Module Tests" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:TestDir = Join-Path -Path $TestDrive -ChildPath "excel_exporter_tests"
        New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
        
        # Importer le module à tester
        . $ModulePath
    }
    
    Context "New-ExcelExporter function" {
        It "Should create a new Excel exporter" {
            $Exporter = New-ExcelExporter
            
            $Exporter | Should -Not -BeNullOrEmpty
            $Exporter | Should -BeOfType [ExcelExporter]
        }
    }
    
    Context "New-ExcelWorkbook function" {
        It "Should create a new Excel workbook" {
            $Exporter = New-ExcelExporter
            $WorkbookId = New-ExcelWorkbook -Exporter $Exporter
            
            $WorkbookId | Should -Not -BeNullOrEmpty
            $Exporter.WorkbookExists($WorkbookId) | Should -Be $true
            
            # Cleanup
            Close-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId
        }
        
        It "Should create a new Excel workbook with a specified path" {
            $Exporter = New-ExcelExporter
            $Path = Join-Path -Path $script:TestDir -ChildPath "test_workbook.xlsx"
            $WorkbookId = New-ExcelWorkbook -Exporter $Exporter -Path $Path
            
            $WorkbookId | Should -Not -BeNullOrEmpty
            $Exporter.WorkbookExists($WorkbookId) | Should -Be $true
            
            # Sauvegarder le classeur
            $SavedPath = Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId
            
            $SavedPath | Should -Be $Path
            Test-Path -Path $Path | Should -Be $true
            
            # Cleanup
            Close-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId
        }
    }
    
    Context "Add-ExcelWorksheet function" {
        It "Should add a worksheet to a workbook" {
            $Exporter = New-ExcelExporter
            $WorkbookId = New-ExcelWorkbook -Exporter $Exporter
            $WorksheetId = Add-ExcelWorksheet -Exporter $Exporter -WorkbookId $WorkbookId -Name "Test"
            
            $WorksheetId | Should -Not -BeNullOrEmpty
            $Exporter.WorksheetExists($WorkbookId, $WorksheetId) | Should -Be $true
            $Exporter.GetWorksheetName($WorkbookId, $WorksheetId) | Should -Be "Test"
            
            # Cleanup
            Close-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId
        }
        
        It "Should return an existing worksheet if the name already exists" {
            $Exporter = New-ExcelExporter
            $WorkbookId = New-ExcelWorkbook -Exporter $Exporter
            $WorksheetId1 = Add-ExcelWorksheet -Exporter $Exporter -WorkbookId $WorkbookId -Name "Test"
            $WorksheetId2 = Add-ExcelWorksheet -Exporter $Exporter -WorkbookId $WorkbookId -Name "Test"
            
            $WorksheetId1 | Should -Not -BeNullOrEmpty
            $WorksheetId2 | Should -Not -BeNullOrEmpty
            $WorksheetId1 | Should -Not -Be $WorksheetId2
            $Exporter.GetWorksheetName($WorkbookId, $WorksheetId1) | Should -Be "Test"
            $Exporter.GetWorksheetName($WorkbookId, $WorksheetId2) | Should -Be "Test"
            
            # Cleanup
            Close-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId
        }
    }
    
    Context "Get-ExcelWorksheets function" {
        It "Should list all worksheets in a workbook" {
            $Exporter = New-ExcelExporter
            $WorkbookId = New-ExcelWorkbook -Exporter $Exporter
            $WorksheetId1 = Add-ExcelWorksheet -Exporter $Exporter -WorkbookId $WorkbookId -Name "Sheet1"
            $WorksheetId2 = Add-ExcelWorksheet -Exporter $Exporter -WorkbookId $WorkbookId -Name "Sheet2"
            
            $Worksheets = Get-ExcelWorksheets -Exporter $Exporter -WorkbookId $WorkbookId
            
            $Worksheets | Should -Not -BeNullOrEmpty
            $Worksheets.Count | Should -Be 2
            $Worksheets[$WorksheetId1] | Should -Be "Sheet1"
            $Worksheets[$WorksheetId2] | Should -Be "Sheet2"
            
            # Cleanup
            Close-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId
        }
    }
    
    Context "Save-ExcelWorkbook function" {
        It "Should save a workbook to a specified path" {
            $Exporter = New-ExcelExporter
            $WorkbookId = New-ExcelWorkbook -Exporter $Exporter
            $Path = Join-Path -Path $script:TestDir -ChildPath "saved_workbook.xlsx"
            
            $SavedPath = Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId -Path $Path
            
            $SavedPath | Should -Be $Path
            Test-Path -Path $Path | Should -Be $true
            
            # Cleanup
            Close-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId
        }
    }
    
    Context "Close-ExcelWorkbook function" {
        It "Should close a workbook and release resources" {
            $Exporter = New-ExcelExporter
            $WorkbookId = New-ExcelWorkbook -Exporter $Exporter
            
            Close-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId
            
            $Exporter.WorkbookExists($WorkbookId) | Should -Be $false
        }
    }
    
    Context "Error handling" {
        It "Should handle invalid workbook IDs" {
            $Exporter = New-ExcelExporter
            
            { $Exporter.GetWorksheetName("invalid_id", "invalid_id") } | Should -Throw
            $Exporter.GetLastError() | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle invalid worksheet IDs" {
            $Exporter = New-ExcelExporter
            $WorkbookId = New-ExcelWorkbook -Exporter $Exporter
            
            { $Exporter.GetWorksheetName($WorkbookId, "invalid_id") } | Should -Throw
            $Exporter.GetLastError() | Should -Not -BeNullOrEmpty
            
            # Cleanup
            Close-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId
        }
    }
}

# Ne pas exécuter les tests automatiquement à la fin du script
# Pour exécuter les tests, utilisez la commande suivante :
# Invoke-Pester -Path .\excel_exporter.tests.ps1 -Output Detailed
