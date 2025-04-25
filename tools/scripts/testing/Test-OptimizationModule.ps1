<#
.SYNOPSIS
    Tests unitaires pour le module d'optimisation
.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour le module d'optimisation du Script Manager

<#
.SYNOPSIS
    Tests unitaires pour le module d'optimisation
.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour le module d'optimisation du Script Manager
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
    Write-Host "Module d'optimisation non trouvÃ©: $ModulePath" -ForegroundColor Red
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
            StaticAnalysis = @{
                LineCount = 100
                FunctionCount = 2
                Variables = @("var1", "var2", "result")
                Functions = @("Test-Function", "Get-Result")
            }
            CodeQuality = @{
                Metrics = @{
                    CommentRatio = 0.05
                    MaxLineLength = 120
                    ComplexityScore = 15
                    EmptyLineRatio = 0.2
                }
            }
            Problems = @(
                @{
                    Type = "Performance"
                    Severity = "Medium"
                    Description = "Utilisation inefficace des ressources"
                }
            )
            UsedBy = @()
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
            StaticAnalysis = @{
                LineCount = 80
                FunctionCount = 3
                Variables = @("var1", "var2", "result")
                Functions = @("test_function", "get_result", "main")
            }
            CodeQuality = @{
                Metrics = @{
                    CommentRatio = 0.1
                    MaxLineLength = 90
                    ComplexityScore = 8
                    EmptyLineRatio = 0.15
                }
            }
            Problems = @()
            UsedBy = @("test.ps1")
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
            StaticAnalysis = @{
                LineCount = 50
                FunctionCount = 0
                Variables = @("var1", "var2", "result")
                Functions = @()
            }
            CodeQuality = @{
                Metrics = @{
                    CommentRatio = 0.02
                    MaxLineLength = 80
                    ComplexityScore = 5
                    EmptyLineRatio = 0.1
                }
            }
            Problems = @(
                @{
                    Type = "Syntax"
                    Severity = "Low"
                    Description = "Utilisation de commandes obsolÃ¨tes"
                }
            )
            UsedBy = @()
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

    
    if ($Parameter -eq $null) {
        Write-Host "Parameter is null"
        return $false
    }
    
    $result = $Parameter.Length * 2
    
    if ($result -gt 10) {
        if ($result -gt 20) {
            if ($result -gt 30) {
                if ($result -gt 40) {
                    Write-Host "Result is greater than 40"
                } else {
                    Write-Host "Result is between 30 and 40"
                }
            } else {
                Write-Host "Result is between 20 and 30"
            }
        } else {
            Write-Host "Result is between 10 and 20"
        }
    } else {
        Write-Host "Result is less than or equal to 10"
    }
    
    return $true
}

function Get-Result {
    param (
        [switch]$Verbose = $true
    )
    
    $var1 = 10
    $var2 = 20
    $result = $var1 + $var2
    
    if ($Verbose) {
        Write-Host "Result: $result"
    }
    
    return $result
}

# Main code
$parameter = "test"
Test-Function -Parameter $parameter
$result = Get-Result
Write-Host "Final result: $result"

# Dead code
<#
function Unused-Function {
    param (
        [string]$Parameter
    )
    
    return $Parameter.ToUpper()
}

$unusedVar = "unused"
Unused-Function -Parameter $unusedVar
#>
'@

$PythonContent = @'
# Test Python script
# Author: Test User
# Version: 1.0

def test_function(parameter):
    """Test function docstring"""
    if parameter == None:
        print("Parameter is None")
        return False
    
    result = len(parameter) * 2
    
    if result > 10:
        if result > 20:
            if result > 30:
                if result > 40:
                    print("Result is greater than 40")
                else:
                    print("Result is between 30 and 40")
            else:
                print("Result is between 20 and 30")
        else:
            print("Result is between 10 and 20")
    else:
        print("Result is less than or equal to 10")
    
    return True

def get_result(verbose=True):
    var1 = 10
    var2 = 20
    result = var1 + var2
    
    if verbose:
        print("Result:", result)
    
    return result

def main():
    parameter = "test"
    test_function(parameter)
    result = get_result()
    print("Final result:", result)

# Main code
main()

# Dead code
"""
def unused_function(parameter):
    return parameter.upper()

unused_var = "unused"
unused_function(unused_var)
"""
'@

$BatchContent = @'
REM Test Batch script
REM Author: Test User
REM Version: 1.0

ECHO Starting script...

SET var1=10
SET var2=20
SET result=%var1%

IF %var1% GTR %var2% (
    ECHO var1 is greater than var2
) ELSE (
    ECHO var1 is less than or equal to var2
    SET result=%var2%
)

ECHO Result: %result%

REM Dead code
REM GOTO unused_label
REM :unused_label
REM ECHO This is unused code
REM GOTO end

ECHO Script completed
'@

# Ã‰crire les fichiers de test
Set-Content -Path $PowerShellTestFile -Value $PowerShellContent
Set-Content -Path $PythonTestFile -Value $PythonContent
Set-Content -Path $BatchTestFile -Value $BatchContent

# DÃ©finir le chemin de sortie pour l'optimisation
$OptimizationPath = Join-Path -Path $TestDir -ChildPath "optimization"

# ExÃ©cuter les tests
Describe "Module d'optimisation" {
    Context "Invoke-ScriptOptimization" {
        It "Devrait exÃ©cuter l'optimisation avec succÃ¨s" {
            $Optimization = Invoke-ScriptOptimization -AnalysisPath $AnalysisPath -OutputPath $OptimizationPath -LearningEnabled
            $Optimization | Should -Not -BeNullOrEmpty
            $Optimization.TotalScripts | Should -Be 3
        }
        
        It "Devrait crÃ©er les dossiers d'optimisation" {
            Test-Path -Path $OptimizationPath | Should -Be $true
            Test-Path -Path (Join-Path -Path $OptimizationPath -ChildPath "suggestions") | Should -Be $true
            Test-Path -Path (Join-Path -Path $OptimizationPath -ChildPath "anti-patterns") | Should -Be $true
            Test-Path -Path (Join-Path -Path $OptimizationPath -ChildPath "learning") | Should -Be $true
            Test-Path -Path (Join-Path -Path $OptimizationPath -ChildPath "refactoring") | Should -Be $true
        }
        
        It "Devrait crÃ©er le fichier d'optimisation" {
            Test-Path -Path (Join-Path -Path $OptimizationPath -ChildPath "optimization.json") | Should -Be $true
        }
        
        It "Devrait dÃ©tecter des anti-patterns" {
            Test-Path -Path (Join-Path -Path $OptimizationPath -ChildPath "anti-patterns\anti_patterns.json") | Should -Be $true
            $AntiPatterns = Get-Content -Path (Join-Path -Path $OptimizationPath -ChildPath "anti-patterns\anti_patterns.json") | ConvertFrom-Json
            $AntiPatterns.TotalScripts | Should -Be 3
        }
        
        It "Devrait gÃ©nÃ©rer des suggestions" {
            Test-Path -Path (Join-Path -Path $OptimizationPath -ChildPath "suggestions\suggestions.json") | Should -Be $true
            $Suggestions = Get-Content -Path (Join-Path -Path $OptimizationPath -ChildPath "suggestions\suggestions.json") | ConvertFrom-Json
            $Suggestions.TotalScripts | Should -Be 3
        }
        
        It "Devrait crÃ©er un rapport HTML des suggestions" {
            Test-Path -Path (Join-Path -Path $OptimizationPath -ChildPath "suggestions\suggestions_report.html") | Should -Be $true
        }
        
        It "Devrait crÃ©er un modÃ¨le d'apprentissage" {
            Test-Path -Path (Join-Path -Path $OptimizationPath -ChildPath "learning\global_model.json") | Should -Be $true
            $LearningModel = Get-Content -Path (Join-Path -Path $OptimizationPath -ChildPath "learning\global_model.json") | ConvertFrom-Json
            $LearningModel.TotalScripts | Should -Be 3
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
