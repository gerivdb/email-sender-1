<#
.SYNOPSIS
    Tests unitaires pour le module d'analyse
.DESCRIPTION
    Ce script exécute des tests unitaires pour le module d'analyse du Script Manager
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Le module Pester n'est pas installé. Installation..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Définir le chemin du module à tester
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\D"

# Vérifier si le module existe
if (-not (Test-Path -Path $ModulePath)) {
    Write-Host "Module d'analyse non trouvé: $ModulePath" -ForegroundColor Red
    exit 1
}

# Importer le module
Import-Module $ModulePath -Force

# Créer un dossier temporaire pour les tests
$TestDir = Join-Path -Path $env:TEMP -ChildPath "ScriptManagerTests"
if (-not (Test-Path -Path $TestDir)) {
    New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
}

# Créer des fichiers de test
$PowerShellTestFile = Join-Path -Path $TestDir -ChildPath "test.ps1"
$PythonTestFile = Join-Path -Path $TestDir -ChildPath "test.py"
$BatchTestFile = Join-Path -Path $TestDir -ChildPath "test.cmd"

# Contenu des fichiers de test
$PowerShellContent = @'
# Test PowerShell script
# Author: Test User
# Version: 1.0
# Tags: test, unit, powershell

function Test-Function {
    param (
        [string]$Parameter
    )
    
    if ($Parameter -eq "test") {
        Write-Host "Test successful" -ForegroundColor Green
    } else {
        Write-Host "Test failed" -ForegroundColor Red
    }
}

# Import a module
Import-Module PSReadLine

# Call another script
. .\helper.ps1

# Main code
$variable = "test"
Test-Function -Parameter $variable
'@

$PythonContent = @'
# Test Python script
# Author: Test User
# Version: 1.0
# Tags: test, unit, python

import os
import sys
from datetime import datetime

def test_function(parameter):
    """Test function docstring"""
    if parameter == "test":
        print("Test successful")
    else:
        print("Test failed")

# Main code
if __name__ == "__main__":
    variable = "test"
    test_function(variable)
'@

$BatchContent = @'
@ECHO OFF
REM Test Batch script
REM Author: Test User
REM Version: 1.0

SETLOCAL

SET variable=test

IF "%variable%"=="test" (
    ECHO Test successful
) ELSE (
    ECHO Test failed
)

CALL helper.cmd

ENDLOCAL
'@

# Écrire les fichiers de test
Set-Content -Path $PowerShellTestFile -Value $PowerShellContent
Set-Content -Path $PythonTestFile -Value $PythonContent
Set-Content -Path $BatchTestFile -Value $BatchContent

# Créer un fichier d'inventaire de test
$InventoryPath = Join-Path -Path $TestDir -ChildPath "inventory.json"
$Inventory = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalScripts = 3
    ScriptsByType = @(
        @{
            Type = "PowerShell"
            Count = 1
        },
        @{
            Type = "Python"
            Count = 1
        },
        @{
            Type = "Batch"
            Count = 1
        }
    )
    Scripts = @(
        @{
            Path = $PowerShellTestFile
            Name = "test.ps1"
            Directory = $TestDir
            Extension = ".ps1"
            Type = "PowerShell"
            Size = (Get-Item -Path $PowerShellTestFile).Length
            CreationTime = (Get-Item -Path $PowerShellTestFile).CreationTime
            LastWriteTime = (Get-Item -Path $PowerShellTestFile).LastWriteTime
            Metadata = @{
                Author = "Test User"
                Description = "Test PowerShell script"
                Version = "1.0"
                Tags = @("test", "unit", "powershell")
                Dependencies = @("PSReadLine")
            }
        },
        @{
            Path = $PythonTestFile
            Name = "test.py"
            Directory = $TestDir
            Extension = ".py"
            Type = "Python"
            Size = (Get-Item -Path $PythonTestFile).Length
            CreationTime = (Get-Item -Path $PythonTestFile).CreationTime
            LastWriteTime = (Get-Item -Path $PythonTestFile).LastWriteTime
            Metadata = @{
                Author = "Test User"
                Description = "Test Python script"
                Version = "1.0"
                Tags = @("test", "unit", "python")
                Dependencies = @("os", "sys", "datetime")
            }
        },
        @{
            Path = $BatchTestFile
            Name = "test.cmd"
            Directory = $TestDir
            Extension = ".cmd"
            Type = "Batch"
            Size = (Get-Item -Path $BatchTestFile).Length
            CreationTime = (Get-Item -Path $BatchTestFile).CreationTime
            LastWriteTime = (Get-Item -Path $BatchTestFile).LastWriteTime
            Metadata = @{
                Author = "Test User"
                Description = "Test Batch script"
                Version = "1.0"
                Tags = @()
                Dependencies = @()
            }
        }
    )
} | ConvertTo-Json -Depth 10

Set-Content -Path $InventoryPath -Value $Inventory

# Définir le chemin de sortie pour l'analyse
$AnalysisPath = Join-Path -Path $TestDir -ChildPath "analysis.json"

# Exécuter les tests
Describe "Module d'analyse" {
    Context "Invoke-ScriptAnalysis" {
        It "Devrait analyser les scripts avec succès" {
            $Analysis = Invoke-ScriptAnalysis -InventoryPath $InventoryPath -OutputPath $AnalysisPath -Depth "Basic"
            $Analysis | Should -Not -BeNullOrEmpty
            $Analysis.TotalScripts | Should -Be 3
        }
        
        It "Devrait créer un fichier d'analyse" {
            Test-Path -Path $AnalysisPath | Should -Be $true
        }
        
        It "Devrait contenir des informations d'analyse pour chaque script" {
            $AnalysisContent = Get-Content -Path $AnalysisPath -Raw | ConvertFrom-Json
            $AnalysisContent.Scripts.Count | Should -Be 3
            $AnalysisContent.Scripts[0].StaticAnalysis | Should -Not -BeNullOrEmpty
            $AnalysisContent.Scripts[0].Dependencies | Should -Not -BeNullOrEmpty
            $AnalysisContent.Scripts[0].CodeQuality | Should -Not -BeNullOrEmpty
        }
    }
}

# Nettoyer les fichiers de test
Remove-Item -Path $TestDir -Recurse -Force

