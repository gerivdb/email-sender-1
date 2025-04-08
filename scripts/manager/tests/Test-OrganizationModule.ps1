<#
.SYNOPSIS
    Tests unitaires pour le module d'organisation
.DESCRIPTION
    Ce script exécute des tests unitaires pour le module d'organisation du Script Manager
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Le module Pester n'est pas installé. Installation..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Définir le chemin du module à tester
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\Organization\OrganizationModule.psm1"

# Vérifier si le module existe
if (-not (Test-Path -Path $ModulePath)) {
    Write-Host "Module d'organisation non trouvé: $ModulePath" -ForegroundColor Red
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
$AnalysisPath = Join-Path -Path $TestDir -ChildPath "analysis.json"
$RulesPath = Join-Path -Path $TestDir -ChildPath "rules.json"
$OrganizationPath = Join-Path -Path $TestDir -ChildPath "organization.json"

# Contenu du fichier d'analyse
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

# Contenu du fichier de règles
$Rules = @{
    rules = @(
        @{
            name = "PowerShell Scripts Organization"
            description = "Règles pour organiser les scripts PowerShell"
            patterns = @(
                @{
                    pattern = ".*\.ps1$"
                    type = "regex"
                }
            )
            conditions = @(
                @{
                    field = "content"
                    pattern = "test"
                    type = "regex"
                    destination = "scripts/testing"
                }
            )
        },
        @{
            name = "Python Scripts Organization"
            description = "Règles pour organiser les scripts Python"
            patterns = @(
                @{
                    pattern = ".*\.py$"
                    type = "regex"
                }
            )
            conditions = @(
                @{
                    field = "content"
                    pattern = "test"
                    type = "regex"
                    destination = "scripts/python/testing"
                }
            )
        },
        @{
            name = "Batch Scripts Organization"
            description = "Règles pour organiser les scripts batch"
            patterns = @(
                @{
                    pattern = ".*\.(cmd|bat)$"
                    type = "regex"
                }
            )
            conditions = @(
                @{
                    field = "content"
                    pattern = "test"
                    type = "regex"
                    destination = "scripts/batch/testing"
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

# Écrire les fichiers de test
Set-Content -Path $AnalysisPath -Value $Analysis
Set-Content -Path $RulesPath -Value $Rules

# Exécuter les tests
Describe "Module d'organisation" {
    Context "Invoke-ScriptOrganization" {
        It "Devrait organiser les scripts avec succès en mode simulation" {
            $Organization = Invoke-ScriptOrganization -AnalysisPath $AnalysisPath -RulesPath $RulesPath -OutputPath $OrganizationPath
            $Organization | Should -Not -BeNullOrEmpty
            $Organization.TotalScripts | Should -Be 3
            $Organization.AutoApply | Should -Be $false
        }
        
        It "Devrait créer un fichier d'organisation" {
            Test-Path -Path $OrganizationPath | Should -Be $true
        }
        
        It "Devrait contenir des informations d'organisation pour chaque script" {
            $OrganizationContent = Get-Content -Path $OrganizationPath -Raw | ConvertFrom-Json
            $OrganizationContent.Results.Count | Should -Be 3
            $OrganizationContent.Results[0].NeedsMove | Should -Not -BeNullOrEmpty
            $OrganizationContent.Results[0].TargetPath | Should -Not -BeNullOrEmpty
        }
    }
}

# Nettoyer les fichiers de test
Remove-Item -Path $TestDir -Recurse -Force
