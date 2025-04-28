<#
.SYNOPSIS
    Tests unitaires pour le module d'analyse
.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour le module d'analyse du Script Manager

<#
.SYNOPSIS
    Tests unitaires pour le module d'analyse
.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour le module d'analyse du Script Manager
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Le module Pester n'est pas installÃ©. Installation..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# DÃ©finir le chemin du module Ã  tester
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\D"

# VÃ©rifier si le module existe
if (-not (Test-Path -Path $ModulePath)) {
    Write-Host "Module d'analyse non trouvÃ©: $ModulePath" -ForegroundColor Red
    exit 1
}

# Importer le module
Import-Module $ModulePath -Force

# CrÃ©er un dossier temporaire pour les tests
$TestDir = Join-Path -Path $env:TEMP -ChildPath "ScriptManagerTests"
if (-not (Test-Path -Path $TestDir)) {
    New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
}

# CrÃ©er des fichiers de test
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

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal

    
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

# Ã‰crire les fichiers de test
Set-Content -Path $PowerShellTestFile -Value $PowerShellContent
Set-Content -Path $PythonTestFile -Value $PythonContent
Set-Content -Path $BatchTestFile -Value $BatchContent

# CrÃ©er un fichier d'inventaire de test
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

# DÃ©finir le chemin de sortie pour l'analyse
$AnalysisPath = Join-Path -Path $TestDir -ChildPath "analysis.json"

# ExÃ©cuter les tests
Describe "Module d'analyse" {
    Context "Invoke-ScriptAnalysis" {
        It "Devrait analyser les scripts avec succÃ¨s" {
            $Analysis = Invoke-ScriptAnalysis -InventoryPath $InventoryPath -OutputPath $AnalysisPath -Depth "Basic"
            $Analysis | Should -Not -BeNullOrEmpty
            $Analysis.TotalScripts | Should -Be 3
        }
        
        It "Devrait crÃ©er un fichier d'analyse" {
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


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
