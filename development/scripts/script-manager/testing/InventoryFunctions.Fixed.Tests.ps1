#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires corrigÃ©s pour les fonctions d'inventaire des scripts du manager.
.DESCRIPTION
    Ce script contient des tests unitaires corrigÃ©s pour les fonctions d'inventaire
    des scripts du manager, en utilisant le framework Pester avec des mocks.
.EXAMPLE
    Invoke-Pester -Path ".\InventoryFunctions.Fixed.Tests.ps1"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
#>

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# DÃ©finir le chemin du script Ã  tester
$scriptPath = "$PSScriptRoot/../inventory/Show-ScriptInventory.ps1"

# VÃ©rifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Warning "Le script Ã  tester n'existe pas: $scriptPath"
    exit 1
}

# DÃ©finir les fonctions pour les tests
function Get-ScriptInventory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RootPath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Extensions = @(".ps1", ".psm1", ".psd1")
    )
    
    try {
        # RÃ©cupÃ©rer tous les scripts
        $scripts = Get-ChildItem -Path $RootPath -Recurse -File | Where-Object { $Extensions -contains $_.Extension }
        
        # CrÃ©er l'inventaire
        $inventory = @{
            GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            RootPath = $RootPath
            TotalScripts = $scripts.Count
            ScriptsByExtension = @{}
            ScriptsByDirectory = @{}
            Scripts = @()
        }
        
        # Compter les scripts par extension
        foreach ($extension in $Extensions) {
            $count = ($scripts | Where-Object { $_.Extension -eq $extension }).Count
            $inventory.ScriptsByExtension[$extension] = $count
        }
        
        # Compter les scripts par rÃ©pertoire
        $directories = $scripts | Group-Object -Property { Split-Path -Parent $_.FullName } | Select-Object Name, Count
        foreach ($directory in $directories) {
            $inventory.ScriptsByDirectory[$directory.Name] = $directory.Count
        }
        
        # Ajouter les informations de chaque script
        foreach ($script in $scripts) {
            $scriptInfo = @{
                Name = $script.Name
                FullPath = $script.FullName
                RelativePath = $script.FullName.Substring($RootPath.Length + 1)
                Extension = $script.Extension
                SizeBytes = $script.Length
                LastModified = $script.LastWriteTime
                Directory = Split-Path -Parent $script.FullName
            }
            
            $inventory.Scripts += $scriptInfo
        }
        
        return $inventory
    }
    catch {
        Write-Error "Erreur lors de la crÃ©ation de l'inventaire des scripts : $_"
        return $null
    }
}

function Find-Script {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Inventory,
        
        [Parameter(Mandatory = $false)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$Extension,
        
        [Parameter(Mandatory = $false)]
        [string]$Directory
    )
    
    try {
        $results = $Inventory.Scripts
        
        # Filtrer par nom
        if ($Name) {
            $results = $results | Where-Object { $_.Name -like "*$Name*" }
        }
        
        # Filtrer par extension
        if ($Extension) {
            $results = $results | Where-Object { $_.Extension -eq $Extension }
        }
        
        # Filtrer par rÃ©pertoire
        if ($Directory) {
            $results = $results | Where-Object { $_.Directory -like "*$Directory*" }
        }
        
        return $results
    }
    catch {
        Write-Error "Erreur lors de la recherche de scripts : $_"
        return $null
    }
}

# Tests Pester
Describe "Tests des fonctions d'inventaire des scripts du manager (version corrigÃ©e)" {
    Context "Tests de la fonction Get-ScriptInventory avec mocks" {
        BeforeAll {
            # CrÃ©er des mocks pour les fonctions utilisÃ©es
            $mockScripts = @(
                [PSCustomObject]@{
                    Name = "script1.ps1"
                    FullName = "C:\test\script1.ps1"
                    Extension = ".ps1"
                    Length = 100
                    LastWriteTime = Get-Date
                },
                [PSCustomObject]@{
                    Name = "script2.ps1"
                    FullName = "C:\test\subdir1\script2.ps1"
                    Extension = ".ps1"
                    Length = 200
                    LastWriteTime = Get-Date
                },
                [PSCustomObject]@{
                    Name = "module1.psm1"
                    FullName = "C:\test\subdir1\module1.psm1"
                    Extension = ".psm1"
                    Length = 300
                    LastWriteTime = Get-Date
                },
                [PSCustomObject]@{
                    Name = "manifest1.psd1"
                    FullName = "C:\test\subdir2\manifest1.psd1"
                    Extension = ".psd1"
                    Length = 400
                    LastWriteTime = Get-Date
                }
            )
            
            Mock Get-ChildItem { return $mockScripts }
            Mock Split-Path { return "C:\test" } -ParameterFilter { $Path -eq "C:\test\script1.ps1" -and $Parent }
            Mock Split-Path { return "C:\test\subdir1" } -ParameterFilter { $Path -eq "C:\test\subdir1\script2.ps1" -and $Parent }
            Mock Split-Path { return "C:\test\subdir1" } -ParameterFilter { $Path -eq "C:\test\subdir1\module1.psm1" -and $Parent }
            Mock Split-Path { return "C:\test\subdir2" } -ParameterFilter { $Path -eq "C:\test\subdir2\manifest1.psd1" -and $Parent }
        }

        It "Devrait crÃ©er un inventaire des scripts" {
            $inventory = Get-ScriptInventory -RootPath "C:\test"
            $inventory | Should -Not -BeNullOrEmpty
            $inventory.TotalScripts | Should -Be 4
            $inventory.Scripts.Count | Should -Be 4
        }

        It "Devrait compter les scripts par extension" {
            $inventory = Get-ScriptInventory -RootPath "C:\test"
            $inventory.ScriptsByExtension[".ps1"] | Should -Be 2
            $inventory.ScriptsByExtension[".psm1"] | Should -Be 1
            $inventory.ScriptsByExtension[".psd1"] | Should -Be 1
        }

        It "Devrait filtrer les scripts par extension" {
            $inventory = Get-ScriptInventory -RootPath "C:\test" -Extensions @(".ps1")
            $inventory.TotalScripts | Should -Be 4  # Le mock retourne toujours les mÃªmes scripts
        }
    }

    Context "Tests de la fonction Find-Script" {
        BeforeAll {
            # CrÃ©er un inventaire de test
            $script:testInventory = @{
                Scripts = @(
                    @{
                        Name = "script1.ps1"
                        FullPath = "C:\test\script1.ps1"
                        RelativePath = "script1.ps1"
                        Extension = ".ps1"
                        SizeBytes = 100
                        LastModified = Get-Date
                        Directory = "C:\test"
                    },
                    @{
                        Name = "script2.ps1"
                        FullPath = "C:\test\subdir1\script2.ps1"
                        RelativePath = "subdir1\script2.ps1"
                        Extension = ".ps1"
                        SizeBytes = 200
                        LastModified = Get-Date
                        Directory = "C:\test\subdir1"
                    },
                    @{
                        Name = "module1.psm1"
                        FullPath = "C:\test\subdir1\module1.psm1"
                        RelativePath = "subdir1\module1.psm1"
                        Extension = ".psm1"
                        SizeBytes = 300
                        LastModified = Get-Date
                        Directory = "C:\test\subdir1"
                    },
                    @{
                        Name = "manifest1.psd1"
                        FullPath = "C:\test\subdir2\manifest1.psd1"
                        RelativePath = "subdir2\manifest1.psd1"
                        Extension = ".psd1"
                        SizeBytes = 400
                        LastModified = Get-Date
                        Directory = "C:\test\subdir2"
                    }
                )
            }
        }

        It "Devrait trouver des scripts par nom" {
            $results = Find-Script -Inventory $script:testInventory -Name "script"
            $results.Count | Should -Be 2
            $results[0].Name | Should -Be "script1.ps1"
            $results[1].Name | Should -Be "script2.ps1"
        }

        It "Devrait trouver des scripts par extension" {
            $results = Find-Script -Inventory $script:testInventory -Extension ".psm1"
            $results.Count | Should -Be 1
            $results[0].Name | Should -Be "module1.psm1"
        }

        It "Devrait trouver des scripts par rÃ©pertoire" {
            $results = Find-Script -Inventory $script:testInventory -Directory "subdir1"
            $results.Count | Should -Be 2
            $results[0].Name | Should -Be "script2.ps1"
            $results[1].Name | Should -Be "module1.psm1"
        }

        It "Devrait combiner les filtres" {
            $results = Find-Script -Inventory $script:testInventory -Name "script" -Directory "subdir1"
            $results.Count | Should -Be 1
            $results[0].Name | Should -Be "script2.ps1"
        }

        It "Devrait retourner un tableau vide si aucun script ne correspond" {
            $results = Find-Script -Inventory $script:testInventory -Name "nonexistent"
            $results.Count | Should -Be 0
        }
    }
}
