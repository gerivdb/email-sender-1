<#
.SYNOPSIS
    Tests unitaires pour le module de surveillance
.DESCRIPTION
    Ce script exécute des tests unitaires pour le module de surveillance du Script Manager
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Le module Pester n'est pas installé. Installation..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Définir le chemin du module à tester
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\Monitoring\MonitoringModule.psm1"

# Vérifier si le module existe
if (-not (Test-Path -Path $ModulePath)) {
    Write-Host "Module de surveillance non trouvé: $ModulePath" -ForegroundColor Red
    exit 1
}

# Importer le module
Import-Module $ModulePath -Force

# Créer un dossier temporaire pour les tests
$TestDir = Join-Path -Path $env:TEMP -ChildPath "ScriptManagerTests"
if (-not (Test-Path -Path $TestDir)) {
    New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
}

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
            Path = Join-Path -Path $TestDir -ChildPath "test.ps1"
            Name = "test.ps1"
            Directory = $TestDir
            Extension = ".ps1"
            Type = "PowerShell"
            Size = 500
            CreationTime = Get-Date
            LastWriteTime = Get-Date
            Metadata = @{
                Author = "Test User"
                Description = "Test PowerShell script"
                Version = "1.0"
                Tags = @("test", "unit", "powershell")
                Dependencies = @("PSReadLine")
            }
        },
        @{
            Path = Join-Path -Path $TestDir -ChildPath "test.py"
            Name = "test.py"
            Directory = $TestDir
            Extension = ".py"
            Type = "Python"
            Size = 400
            CreationTime = Get-Date
            LastWriteTime = Get-Date
            Metadata = @{
                Author = "Test User"
                Description = "Test Python script"
                Version = "1.0"
                Tags = @("test", "unit", "python")
                Dependencies = @("os", "sys", "datetime")
            }
        },
        @{
            Path = Join-Path -Path $TestDir -ChildPath "test.cmd"
            Name = "test.cmd"
            Directory = $TestDir
            Extension = ".cmd"
            Type = "Batch"
            Size = 300
            CreationTime = Get-Date
            LastWriteTime = Get-Date
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

# Créer les fichiers de test
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

# Définir le chemin de sortie pour la surveillance
$MonitoringPath = Join-Path -Path $TestDir -ChildPath "monitoring"

# Exécuter les tests
Describe "Module de surveillance" {
    Context "Start-ScriptMonitoring" {
        It "Devrait configurer la surveillance avec succès" {
            $Monitoring = Start-ScriptMonitoring -InventoryPath $InventoryPath -OutputPath $MonitoringPath -MonitoringInterval 30
            $Monitoring | Should -Not -BeNullOrEmpty
            $Monitoring.TotalScripts | Should -Be 3
            $Monitoring.MonitoringInterval | Should -Be 30
        }
        
        It "Devrait créer les dossiers de surveillance" {
            Test-Path -Path $MonitoringPath | Should -Be $true
            Test-Path -Path (Join-Path -Path $MonitoringPath -ChildPath "dashboard") | Should -Be $true
            Test-Path -Path (Join-Path -Path $MonitoringPath -ChildPath "changes") | Should -Be $true
            Test-Path -Path (Join-Path -Path $MonitoringPath -ChildPath "alerts") | Should -Be $true
            Test-Path -Path (Join-Path -Path $MonitoringPath -ChildPath "usage") | Should -Be $true
        }
        
        It "Devrait créer le tableau de bord" {
            Test-Path -Path (Join-Path -Path $MonitoringPath -ChildPath "dashboard\dashboard.html") | Should -Be $true
            Test-Path -Path (Join-Path -Path $MonitoringPath -ChildPath "dashboard\dashboard_data.json") | Should -Be $true
        }
        
        It "Devrait créer le suivi des modifications" {
            Test-Path -Path (Join-Path -Path $MonitoringPath -ChildPath "changes\initial_snapshot.json") | Should -Be $true
            Test-Path -Path (Join-Path -Path $MonitoringPath -ChildPath "changes\changes_history.json") | Should -Be $true
        }
        
        It "Devrait créer le système d'alertes" {
            Test-Path -Path (Join-Path -Path $MonitoringPath -ChildPath "alerts\alert_config.json") | Should -Be $true
            Test-Path -Path (Join-Path -Path $MonitoringPath -ChildPath "alerts\alert_history.json") | Should -Be $true
        }
        
        It "Devrait créer le suivi d'utilisation" {
            Test-Path -Path (Join-Path -Path $MonitoringPath -ChildPath "usage\usage_data.json") | Should -Be $true
        }
    }
}

# Nettoyer les fichiers de test
Remove-Item -Path $TestDir -Recurse -Force
