#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour les fonctions d'inventaire des scripts du manager.
.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctions d'inventaire
    des scripts du manager, en utilisant le framework Pester.
.EXAMPLE
    Invoke-Pester -Path ".\InventoryFunctions.Tests.ps1"
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

# CrÃ©er des fonctions de test pour l'inventaire des scripts
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
Describe "Tests des fonctions d'inventaire des scripts du manager" {
    Context "Tests de la fonction Get-ScriptInventory" {
        BeforeAll {
            # CrÃ©er un dossier temporaire pour les tests
            $testDir = Join-Path -Path $env:TEMP -ChildPath "ScriptInventoryTests"
            if (Test-Path -Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null

            # CrÃ©er des sous-dossiers
            $subDir1 = Join-Path -Path $testDir -ChildPath "subdir1"
            $subDir2 = Join-Path -Path $testDir -ChildPath "subdir2"
            New-Item -Path $subDir1 -ItemType Directory -Force | Out-Null
            New-Item -Path $subDir2 -ItemType Directory -Force | Out-Null

            # CrÃ©er des scripts de test
            $script1Path = Join-Path -Path $testDir -ChildPath "script1.ps1"
            $script2Path = Join-Path -Path $subDir1 -ChildPath "script2.ps1"
            $script3Path = Join-Path -Path $subDir1 -ChildPath "script3.psm1"
            $script4Path = Join-Path -Path $subDir2 -ChildPath "script4.psd1"
            
            Set-Content -Path $script1Path -Value "# Script 1" -Encoding UTF8
            Set-Content -Path $script2Path -Value "# Script 2" -Encoding UTF8
            Set-Content -Path $script3Path -Value "# Script 3" -Encoding UTF8
            Set-Content -Path $script4Path -Value "# Script 4" -Encoding UTF8

            # Sauvegarder les chemins pour les tests
            $script:testDir = $testDir
            $script:subDir1 = $subDir1
            $script:subDir2 = $subDir2
            $script:script1Path = $script1Path
            $script:script2Path = $script2Path
            $script:script3Path = $script3Path
            $script:script4Path = $script4Path
        }

        AfterAll {
            # Nettoyer aprÃ¨s les tests
            if (Test-Path -Path $script:testDir) {
                Remove-Item -Path $script:testDir -Recurse -Force
            }
        }

        It "Devrait crÃ©er un inventaire des scripts" {
            $inventory = Get-ScriptInventory -RootPath $script:testDir
            $inventory | Should -Not -BeNullOrEmpty
            $inventory.TotalScripts | Should -Be 4
            $inventory.ScriptsByExtension[".ps1"] | Should -Be 2
            $inventory.ScriptsByExtension[".psm1"] | Should -Be 1
            $inventory.ScriptsByExtension[".psd1"] | Should -Be 1
            $inventory.Scripts.Count | Should -Be 4
        }

        It "Devrait compter les scripts par rÃ©pertoire" {
            $inventory = Get-ScriptInventory -RootPath $script:testDir
            $inventory.ScriptsByDirectory[$script:testDir] | Should -Be 1
            $inventory.ScriptsByDirectory[$script:subDir1] | Should -Be 2
            $inventory.ScriptsByDirectory[$script:subDir2] | Should -Be 1
        }

        It "Devrait filtrer les scripts par extension" {
            $inventory = Get-ScriptInventory -RootPath $script:testDir -Extensions @(".ps1")
            $inventory.TotalScripts | Should -Be 2
            $inventory.ScriptsByExtension[".ps1"] | Should -Be 2
            $inventory.ScriptsByExtension[".psm1"] | Should -BeNullOrEmpty
            $inventory.ScriptsByExtension[".psd1"] | Should -BeNullOrEmpty
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
