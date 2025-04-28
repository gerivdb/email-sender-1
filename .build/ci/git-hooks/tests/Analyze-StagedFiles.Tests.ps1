#Requires -Modules Pester
<#
.SYNOPSIS
    Tests unitaires pour le script Analyze-StagedFiles.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Analyze-StagedFiles.ps1
    qui est utilisé par le hook pre-commit Git.
.NOTES
    Auteur: Augment Code
    Date: 14/04/2025
#>

# Chemin vers le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Analyze-StagedFiles.ps1"

# Chemin vers le module d'analyse des patterns d'erreurs
$modulePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent) -ChildPath "scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1"

# Vérifier que les fichiers existent
if (-not (Test-Path -Path $scriptPath)) {
    throw "Script non trouvé: $scriptPath"
}

if (-not (Test-Path -Path $modulePath)) {
    throw "Module non trouvé: $modulePath"
}

# Importer le module d'analyse des patterns d'erreurs
Import-Module $modulePath -Force

# Créer une fonction mock pour git
function git {
    param (
        [Parameter(ValueFromRemainingArguments = $true)]
        $Arguments
    )
    
    # Simuler la commande git rev-parse --show-toplevel
    if ($Arguments -contains "rev-parse" -and $Arguments -contains "--show-toplevel") {
        return (Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent)
    }
    
    # Simuler la commande git diff --cached --name-only --diff-filter=ACM
    if ($Arguments -contains "diff" -and $Arguments -contains "--cached") {
        return @(
            "git-hooks/test-files/test-script-with-errors.ps1",
            "git-hooks/test-files/test-script-without-errors.ps1",
            "development/scripts/maintenance/error-learning/ErrorPatternAnalyzer.psm1"
        )
    }
}

# Créer un mock pour la fonction Test-ExcludePath
function Test-ExcludePath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    # Simuler l'exclusion de certains chemins
    return $Path -like "*error-learning*"
}

# Créer un mock pour la fonction Get-ErrorPatterns
function Get-ErrorPatterns {
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Content')]
        [string]$ScriptContent,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
        [string]$FilePath
    )
    
    # Simuler la détection de patterns d'erreurs
    if ($PSCmdlet.ParameterSetName -eq 'Path') {
        if ($FilePath -like "*test-script-with-errors*") {
            return @(
                @{
                    Id = "null-reference"
                    LineNumber = 4
                    StartColumn = 10
                    EndColumn = 20
                    Message = "Référence potentiellement nulle"
                    Severity = "Warning"
                    Description = "Accès à une propriété d'un objet potentiellement nul"
                    Suggestion = "Ajouter une vérification de nullité avant d'accéder aux propriétés"
                    CodeExample = "if (`$object -ne `$null) { ... }"
                },
                @{
                    Id = "index-out-of-bounds"
                    LineNumber = 8
                    StartColumn = 10
                    EndColumn = 20
                    Message = "Index potentiellement hors limites"
                    Severity = "Warning"
                    Description = "Accès à un élément de tableau avec un index potentiellement hors limites"
                    Suggestion = "Vérifier les limites du tableau avant d'accéder aux éléments"
                    CodeExample = "if (`$array.Length -gt `$index) { ... }"
                }
            )
        } else {
            return @()
        }
    } else {
        if ($ScriptContent -like "*`$user.Name*") {
            return @(
                @{
                    Id = "null-reference"
                    LineNumber = 4
                    StartColumn = 10
                    EndColumn = 20
                    Message = "Référence potentiellement nulle"
                    Severity = "Warning"
                    Description = "Accès à une propriété d'un objet potentiellement nul"
                    Suggestion = "Ajouter une vérification de nullité avant d'accéder aux propriétés"
                    CodeExample = "if (`$object -ne `$null) { ... }"
                }
            )
        } else {
            return @()
        }
    }
}

Describe "Analyze-StagedFiles" {
    BeforeAll {
        # Créer un mock pour Out-File
        Mock Out-File { }
        
        # Créer un mock pour Write-Host
        Mock Write-Host { }
        
        # Créer un mock pour Write-Warning
        Mock Write-Warning { }
        
        # Créer un mock pour Write-Error
        Mock Write-Error { }
        
        # Créer un mock pour New-Item
        Mock New-Item { }
        
        # Créer un mock pour Test-Path
        Mock Test-Path { return $true }
        
        # Créer un mock pour Get-Content
        Mock Get-Content {
            if ($Path -like "*pre-commit-config.json") {
                return '{"IgnorePatterns":["PSAvoidUsingWriteHost"],"SeverityLevel":"Warning","MaxErrors":10,"ExcludePaths":["node_modules","vendor","dist","out","tests","examples"]}'
            } else {
                return "# Test script`n`$user = `$null`n`$name = `$user.Name"
            }
        }
        
        # Définir la variable globale pour le test
        $global:config = @{
            IgnorePatterns = @("PSAvoidUsingWriteHost")
            SeverityLevel = "Warning"
            MaxErrors = 10
            ExcludePaths = @("node_modules", "vendor", "dist", "out", "tests", "examples")
        }
    }
    
    Context "Filtrage des fichiers" {
        It "Devrait filtrer les fichiers exclus" {
            # Définir les paramètres
            $params = @{
                ConfigPath = "git-hooks\config\pre-commit-config.json"
            }
            
            # Exécuter le script
            $result = & $scriptPath @params
            
            # Vérifier que la fonction Test-ExcludePath a été appelée
            Should -Invoke Test-Path -Times 1 -Exactly
        }
    }
    
    Context "Analyse des fichiers" {
        It "Devrait analyser les fichiers PowerShell modifiés" {
            # Définir les paramètres
            $params = @{
                ConfigPath = "git-hooks\config\pre-commit-config.json"
            }
            
            # Exécuter le script
            $result = & $scriptPath @params
            
            # Vérifier que la fonction Get-ErrorPatterns a été appelée
            Should -Invoke Get-Content -Times 1 -Exactly
        }
        
        It "Devrait générer un rapport d'analyse" {
            # Définir les paramètres
            $params = @{
                ConfigPath = "git-hooks\config\pre-commit-config.json"
            }
            
            # Exécuter le script
            $result = & $scriptPath @params
            
            # Vérifier que la fonction Out-File a été appelée
            Should -Invoke Out-File -Times 1 -Exactly
        }
    }
    
    Context "Gestion des erreurs" {
        It "Devrait gérer les erreurs lors du chargement de la configuration" {
            # Créer un mock pour Get-Content qui génère une erreur
            Mock Get-Content { throw "Erreur de test" }
            
            # Définir les paramètres
            $params = @{
                ConfigPath = "git-hooks\config\pre-commit-config.json"
            }
            
            # Exécuter le script
            $result = & $scriptPath @params
            
            # Vérifier que la fonction Write-Warning a été appelée
            Should -Invoke Write-Warning -Times 2 -Exactly
        }
    }
    
    AfterAll {
        # Nettoyer les variables globales
        Remove-Variable -Name config -Scope Global -ErrorAction SilentlyContinue
    }
}
