#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intÃ©gration pour la structure de documentation Augment.

.DESCRIPTION
    Ce script vÃ©rifie que la structure de documentation Augment est correctement
    intÃ©grÃ©e avec VS Code et Augment.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-14
#>

[CmdletBinding()]
param()

# Importer le module Pester s'il est disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -ErrorAction Stop

# DÃ©finir le chemin racine du projet
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Describe "IntÃ©gration Augment" {
    Context "Configuration VS Code" {
        It "Le fichier settings.json existe" {
            Test-Path -Path "$projectRoot\.vscode\settings.json" -PathType Leaf | Should -Be $true
        }

        It "Le fichier settings.json contient les paramÃ¨tres Augment" {
            $settings = Get-Content -Path "$projectRoot\.vscode\settings.json" -Raw | ConvertFrom-Json
            $settings.PSObject.Properties | Where-Object { $_.Name -like "augment.*" } | Should -Not -BeNullOrEmpty
        }
    }

    Context "Validation de l'accÃ¨s aux fichiers" {
        # Cette fonction simule l'accÃ¨s aux fichiers comme le ferait Augment
        function Test-FileAccess {
            param (
                [string]$FilePath
            )
            
            try {
                $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
                return $true
            }
            catch {
                return $false
            }
        }

        $allFiles = @(
            Get-ChildItem -Path "$projectRoot\.augment\guidelines\*.md"
            Get-ChildItem -Path "$projectRoot\.augment\context\*.md"
        )

        foreach ($file in $allFiles) {
            It "Le fichier $($file.Name) est accessible en lecture" {
                Test-FileAccess -FilePath $file.FullName | Should -Be $true
            }
        }
    }

    Context "Validation des patterns de fichiers" {
        It "Le pattern .augment/guidelines/*.md correspond Ã  des fichiers" {
            $files = Get-ChildItem -Path "$projectRoot\.augment\guidelines\*.md"
            $files.Count | Should -BeGreaterThan 0
        }

        It "Le pattern .augment/context/*.md correspond Ã  des fichiers" {
            $files = Get-ChildItem -Path "$projectRoot\.augment\context\*.md"
            $files.Count | Should -BeGreaterThan 0
        }
    }
}

# Fonction pour simuler l'accÃ¨s aux fichiers via la configuration Augment
function Test-AugmentConfigAccess {
    param (
        [string]$ConfigPath
    )

    $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
    $providers = $config.context_providers | Where-Object { $_.type -eq "file" }
    
    $results = @()
    foreach ($provider in $providers) {
        $pattern = $provider.path -replace '\$\{workspace_root\}', $projectRoot
        $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
        $results += [PSCustomObject]@{
            Provider = $provider.name
            Pattern = $pattern
            FilesFound = $files.Count
            Success = $files.Count -gt 0
        }
    }
    
    return $results
}

Describe "Simulation d'accÃ¨s Augment" {
    $configResults = Test-AugmentConfigAccess -ConfigPath "$projectRoot\.augment\config.json"
    
    foreach ($result in $configResults) {
        It "Le provider '$($result.Provider)' trouve des fichiers avec le pattern '$($result.Pattern)'" {
            $result.Success | Should -Be $true
            $result.FilesFound | Should -BeGreaterThan 0
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Output Detailed
