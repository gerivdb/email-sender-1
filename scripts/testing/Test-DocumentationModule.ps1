<#
.SYNOPSIS
    Tests unitaires pour le module de documentation
.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour le module de documentation du Script Manager

<#
.SYNOPSIS
    Tests unitaires pour le module de documentation
.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour le module de documentation du Script Manager
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
    Write-Host "Module de documentation non trouvÃ©: $ModulePath" -ForegroundColor Red
    exit 1
}

# Importer le module
Import-Module $ModulePath -Force

# CrÃ©er un dossier temporaire pour les tests
$TestDir = Join-Path -Path $env:TEMP -ChildPath "ScriptManagerTests"
if (-not (Test-Path -Path $TestDir)) {
    New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
}

# CrÃ©er un fichier d'analyse de test
$AnalysisPath = Join-Path -Path $TestDir -ChildPath "analysis.json"
$Analysis = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalScripts = 3
    AnalysisDepth = "Basic"
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
    ScriptsWithProblems = 0
    ScriptsWithDependencies = 2
    AverageCodeQuality = 75.5
    Scripts = @(
        @{
            Path = Join-Path -Path $TestDir -ChildPath "test.ps1"
            Name = "test.ps1"
            Type = "PowerShell"
            StaticAnalysis = @{
                LineCount = 20
                CommentCount = 5
                FunctionCount = 1
                VariableCount = 1
                ComplexityScore = 2
                Imports = @("PSReadLine")
                Functions = @("Test-Function")
                Variables = @("variable")
                Classes = @()
                Conditionals = 1
                Loops = 0
            }
            Dependencies = @(
                @{
                    Type = "Module"
                    Name = "PSReadLine"
                    Path = $null
                    ImportType = "Import-Module"
                },
                @{
                    Type = "Script"
                    Name = "helper.ps1"
                    Path = $null
                    ImportType = "Dot-Source"
                }
            )
            CodeQuality = @{
                Score = 80
                MaxScore = 100
                Metrics = @{
                    LineCount = 20
                    CommentRatio = 0.25
                    AverageLineLength = 40
                    MaxLineLength = 80
                    EmptyLineRatio = 0.1
                    FunctionCount = 1
                    ComplexityScore = 2
                    DuplicationScore = 0
                }
                Issues = @()
                Recommendations = @()
            }
            Problems = @()
            AnalysisDepth = "Basic"
            AnalysisTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        },
        @{
            Path = Join-Path -Path $TestDir -ChildPath "test.py"
            Name = "test.py"
            Type = "Python"
            StaticAnalysis = @{
                LineCount = 15
                CommentCount = 4
                FunctionCount = 1
                VariableCount = 1
                ComplexityScore = 2
                Imports = @("os", "sys", "datetime")
                Functions = @("test_function")
                Variables = @("variable")
                Classes = @()
                Conditionals = 1
                Loops = 0
            }
            Dependencies = @(
                @{
                    Type = "Module"
                    Name = "os"
                    Path = $null
                    ImportType = "Import"
                },
                @{
                    Type = "Module"
                    Name = "sys"
                    Path = $null
                    ImportType = "Import"
                },
                @{
                    Type = "Module"
                    Name = "datetime"
                    Path = $null
                    ImportType = "From-Import"
                }
            )
            CodeQuality = @{
                Score = 85
                MaxScore = 100
                Metrics = @{
                    LineCount = 15
                    CommentRatio = 0.27
                    AverageLineLength = 35
                    MaxLineLength = 70
                    EmptyLineRatio = 0.1
                    FunctionCount = 1
                    ComplexityScore = 2
                    DuplicationScore = 0
                }
                Issues = @()
                Recommendations = @()
            }
            Problems = @()
            AnalysisDepth = "Basic"
            AnalysisTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        },
        @{
            Path = Join-Path -Path $TestDir -ChildPath "test.cmd"
            Name = "test.cmd"
            Type = "Batch"
            StaticAnalysis = @{
                LineCount = 12
                CommentCount = 3
                FunctionCount = 0
                VariableCount = 1
                ComplexityScore = 1
                Imports = @()
                Functions = @()
                Variables = @("variable")
                Classes = @()
                Conditionals = 1
                Loops = 0
            }
            Dependencies = @(
                @{
                    Type = "Script"
                    Name = "helper.cmd"
                    Path = $null
                    ImportType = "Call"
                }
            )
            CodeQuality = @{
                Score = 70
                MaxScore = 100
                Metrics = @{
                    LineCount = 12
                    CommentRatio = 0.25
                    AverageLineLength = 30
                    MaxLineLength = 60
                    EmptyLineRatio = 0.1
                    FunctionCount = 0
                    ComplexityScore = 1
                    DuplicationScore = 0
                }
                Issues = @()
                Recommendations = @()
            }
            Problems = @()
            AnalysisDepth = "Basic"
            AnalysisTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    )
} | ConvertTo-Json -Depth 10

Set-Content -Path $AnalysisPath -Value $Analysis

# CrÃ©er les fichiers de test
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

# DÃ©finir le chemin de sortie pour la documentation
$DocsPath = Join-Path -Path $TestDir -ChildPath "docs"

# ExÃ©cuter les tests
Describe "Module de documentation" {
    Context "Invoke-ScriptDocumentation" {
        It "Devrait gÃ©nÃ©rer la documentation avec succÃ¨s" {
            $Documentation = Invoke-ScriptDocumentation -AnalysisPath $AnalysisPath -OutputPath $DocsPath
            $Documentation | Should -Not -BeNullOrEmpty
            $Documentation.TotalScripts | Should -Be 3
        }
        
        It "Devrait crÃ©er les dossiers de documentation" {
            Test-Path -Path $DocsPath | Should -Be $true
            Test-Path -Path (Join-Path -Path $DocsPath -ChildPath "scripts") | Should -Be $true
            Test-Path -Path (Join-Path -Path $DocsPath -ChildPath "folders") | Should -Be $true
        }
        
        It "Devrait gÃ©nÃ©rer un index global" {
            Test-Path -Path (Join-Path -Path $DocsPath -ChildPath "index.md") | Should -Be $true
            Test-Path -Path (Join-Path -Path $DocsPath -ChildPath "README.md") | Should -Be $true
        }
        
        It "Devrait gÃ©nÃ©rer la documentation pour chaque script" {
            Test-Path -Path (Join-Path -Path $DocsPath -ChildPath "scripts\PowerShell\test.md") | Should -Be $true
            Test-Path -Path (Join-Path -Path $DocsPath -ChildPath "scripts\Python\test.md") | Should -Be $true
            Test-Path -Path (Join-Path -Path $DocsPath -ChildPath "scripts\Batch\test.md") | Should -Be $true
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
