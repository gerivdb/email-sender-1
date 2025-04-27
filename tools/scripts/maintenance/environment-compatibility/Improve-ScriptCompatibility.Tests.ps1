<#
.SYNOPSIS
    Tests unitaires pour le script Improve-ScriptCompatibility.

.DESCRIPTION
    Ce script contient des tests unitaires pour le script Improve-ScriptCompatibility
    en utilisant le framework Pester.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
    PrÃ©requis:      Pester 5.0 ou supÃ©rieur
#>

# VÃ©rifier si Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# DÃ©finir le chemin du script Ã  tester
$scriptRoot = $PSScriptRoot
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "Improve-ScriptCompatibility.ps1"
$modulePath = Join-Path -Path $scriptRoot -ChildPath "EnvironmentManager.psm1"

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testRoot = Join-Path -Path $env:TEMP -ChildPath "ScriptCompatibilityTests"
if (Test-Path -Path $testRoot) {
    Remove-Item -Path $testRoot -Recurse -Force
}
New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

# DÃ©finir les tests Pester
Describe "Script Improve-ScriptCompatibility" {
    BeforeAll {
        # Importer le module EnvironmentManager
        Import-Module $modulePath -Force

        # Initialiser le module
        Initialize-EnvironmentManager

        # CrÃ©er des scripts de test avec diffÃ©rents problÃ¨mes de compatibilitÃ©
        $testScripts = @{
            "HardcodedPaths" = @{
                Path = Join-Path -Path $testRoot -ChildPath "HardcodedPaths.ps1"
                Content = @"
# Script avec des chemins codÃ©s en dur
`$logPath = "D:\Logs\app.log"
`$configPath = "C:\Program Files\App\config.xml"
Write-Host "Log Path: `$logPath"
Write-Host "Config Path: `$configPath"
"@
            }
            "WindowsSeparators" = @{
                Path = Join-Path -Path $testRoot -ChildPath "WindowsSeparators.ps1"
                Content = @"
# Script avec des sÃ©parateurs de chemin spÃ©cifiques Ã  Windows
`$scriptPath = "scripts\\utils\\path-utils.ps1"
`$dataPath = "data\\files\\data.csv"
Write-Host "Script Path: `$scriptPath"
Write-Host "Data Path: `$dataPath"
"@
            }
            "WindowsCommands" = @{
                Path = Join-Path -Path $testRoot -ChildPath "WindowsCommands.ps1"
                Content = @"
# Script avec des commandes spÃ©cifiques Ã  Windows
`$result = cmd.exe /c "dir /b"
`$output = powershell.exe -Command "Get-Process"
Write-Host "Result: `$result"
Write-Host "Output: `$output"
"@
            }
            "WindowsEnvironmentVars" = @{
                Path = Join-Path -Path $testRoot -ChildPath "WindowsEnvironmentVars.ps1"
                Content = @"
# Script avec des variables d'environnement spÃ©cifiques Ã  Windows
`$userProfile = `$env:USERPROFILE
`$appData = `$env:APPDATA
`$programFiles = `$env:ProgramFiles
`$systemRoot = `$env:SystemRoot
Write-Host "User Profile: `$userProfile"
Write-Host "App Data: `$appData"
Write-Host "Program Files: `$programFiles"
Write-Host "System Root: `$systemRoot"
"@
            }
            "WindowsFunctions" = @{
                Path = Join-Path -Path $testRoot -ChildPath "WindowsFunctions.ps1"
                Content = @"
# Script avec des fonctions spÃ©cifiques Ã  PowerShell Windows
`$processes = Get-WmiObject -Class Win32_Process
`$logs = Get-EventLog -LogName Application -Newest 10
Write-Host "Processes: `$(`$processes.Count)"
Write-Host "Logs: `$(`$logs.Count)"
"@
            }
            "AlreadyCompatible" = @{
                Path = Join-Path -Path $testRoot -ChildPath "AlreadyCompatible.ps1"
                Content = @"
# Script dÃ©jÃ  compatible
# Importer le module EnvironmentManager
`$modulePath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\maintenance\environment-compatibility\EnvironmentManager.psm1"
if (Test-Path -Path `$modulePath) {
    Import-Module `$modulePath -Force
}

# Initialiser le module
Initialize-EnvironmentManager

# Utiliser des fonctions compatibles
`$path = Join-CrossPlatformPath -Path "data" -ChildPath "files", "data.csv"
`$exists = Test-CrossPlatformPath -Path `$path
Write-Host "Path: `$path"
Write-Host "Exists: `$exists"
"@
            }
        }

        # CrÃ©er les fichiers de test
        foreach ($script in $testScripts.GetEnumerator()) {
            Set-Content -Path $script.Value.Path -Value $script.Value.Content -Force
        }
    }

    Context "Analyse de compatibilitÃ©" {
        It "Devrait dÃ©tecter les chemins codÃ©s en dur" {
            $scriptPath = $testScripts["HardcodedPaths"].Path
            $result = & $scriptPath -ScriptPath $scriptPath -ReportOnly
            $result.Issues | Should -Contain "Chemins codÃ©s en dur"
        }

        It "Devrait dÃ©tecter les sÃ©parateurs de chemin spÃ©cifiques Ã  Windows" {
            $scriptPath = $testScripts["WindowsSeparators"].Path
            $result = & $scriptPath -ScriptPath $scriptPath -ReportOnly
            $result.Issues | Should -Contain "SÃ©parateurs de chemin spÃ©cifiques Ã  Windows"
        }

        It "Devrait dÃ©tecter les commandes spÃ©cifiques Ã  Windows" {
            $scriptPath = $testScripts["WindowsCommands"].Path
            $result = & $scriptPath -ScriptPath $scriptPath -ReportOnly
            $result.Issues | Should -Contain "Commandes spÃ©cifiques Ã  Windows"
        }

        It "Devrait dÃ©tecter les variables d'environnement spÃ©cifiques Ã  Windows" {
            $scriptPath = $testScripts["WindowsEnvironmentVars"].Path
            $result = & $scriptPath -ScriptPath $scriptPath -ReportOnly
            $result.Issues | Should -Contain "Variables d'environnement spÃ©cifiques Ã  Windows"
        }

        It "Devrait dÃ©tecter les fonctions spÃ©cifiques Ã  PowerShell Windows" {
            $scriptPath = $testScripts["WindowsFunctions"].Path
            $result = & $scriptPath -ScriptPath $scriptPath -ReportOnly
            $result.Issues | Should -Contain "Fonctions spÃ©cifiques Ã  PowerShell Windows"
        }
    }

    Context "AmÃ©lioration de compatibilitÃ©" {
        It "Devrait amÃ©liorer les chemins codÃ©s en dur" {
            $scriptPath = $testScripts["HardcodedPaths"].Path
            $backupPath = "$scriptPath.bak"

            # CrÃ©er une sauvegarde du script original
            Copy-Item -Path $scriptPath -Destination $backupPath -Force

            # AmÃ©liorer le script
            & $scriptPath -ScriptPath $scriptPath -BackupFiles

            # VÃ©rifier que le script a Ã©tÃ© modifiÃ©
            $originalContent = Get-Content -Path $backupPath -Raw
            $modifiedContent = Get-Content -Path $scriptPath -Raw
            $modifiedContent | Should -Not -Be $originalContent

            # VÃ©rifier que le module EnvironmentManager a Ã©tÃ© importÃ©
            $modifiedContent | Should -Match "EnvironmentManager\.psm1"
        }

        It "Devrait amÃ©liorer les sÃ©parateurs de chemin spÃ©cifiques Ã  Windows" {
            $scriptPath = $testScripts["WindowsSeparators"].Path
            $backupPath = "$scriptPath.bak"

            # CrÃ©er une sauvegarde du script original
            Copy-Item -Path $scriptPath -Destination $backupPath -Force

            # AmÃ©liorer le script
            & $scriptPath -ScriptPath $scriptPath -BackupFiles

            # VÃ©rifier que le script a Ã©tÃ© modifiÃ©
            $originalContent = Get-Content -Path $backupPath -Raw
            $modifiedContent = Get-Content -Path $scriptPath -Raw
            $modifiedContent | Should -Not -Be $originalContent

            # VÃ©rifier que les sÃ©parateurs de chemin ont Ã©tÃ© standardisÃ©s
            $modifiedContent | Should -Not -Match "scripts\\\\utils\\\\path-utils\.ps1"
        }

        It "Devrait amÃ©liorer les commandes spÃ©cifiques Ã  Windows" {
            $scriptPath = $testScripts["WindowsCommands"].Path
            $backupPath = "$scriptPath.bak"

            # CrÃ©er une sauvegarde du script original
            Copy-Item -Path $scriptPath -Destination $backupPath -Force

            # AmÃ©liorer le script
            & $scriptPath -ScriptPath $scriptPath -BackupFiles

            # VÃ©rifier que le script a Ã©tÃ© modifiÃ©
            $originalContent = Get-Content -Path $backupPath -Raw
            $modifiedContent = Get-Content -Path $scriptPath -Raw
            $modifiedContent | Should -Not -Be $originalContent

            # VÃ©rifier que les commandes spÃ©cifiques Ã  Windows ont Ã©tÃ© remplacÃ©es
            $modifiedContent | Should -Not -Match "cmd\.exe /c"
            $modifiedContent | Should -Match "Invoke-CrossPlatformCommand"
        }

        It "Devrait amÃ©liorer les variables d'environnement spÃ©cifiques Ã  Windows" {
            $scriptPath = $testScripts["WindowsEnvironmentVars"].Path
            $backupPath = "$scriptPath.bak"

            # CrÃ©er une sauvegarde du script original
            Copy-Item -Path $scriptPath -Destination $backupPath -Force

            # AmÃ©liorer le script
            & $scriptPath -ScriptPath $scriptPath -BackupFiles

            # VÃ©rifier que le script a Ã©tÃ© modifiÃ©
            $originalContent = Get-Content -Path $backupPath -Raw
            $modifiedContent = Get-Content -Path $scriptPath -Raw
            $modifiedContent | Should -Not -Be $originalContent

            # VÃ©rifier que les variables d'environnement spÃ©cifiques Ã  Windows ont Ã©tÃ© remplacÃ©es
            $modifiedContent | Should -Match "if \(\$IsWindows\)"
        }

        It "Devrait amÃ©liorer les fonctions spÃ©cifiques Ã  PowerShell Windows" {
            $scriptPath = $testScripts["WindowsFunctions"].Path
            $backupPath = "$scriptPath.bak"

            # CrÃ©er une sauvegarde du script original
            Copy-Item -Path $scriptPath -Destination $backupPath -Force

            # AmÃ©liorer le script
            & $scriptPath -ScriptPath $scriptPath -BackupFiles

            # VÃ©rifier que le script a Ã©tÃ© modifiÃ©
            $originalContent = Get-Content -Path $backupPath -Raw
            $modifiedContent = Get-Content -Path $scriptPath -Raw
            $modifiedContent | Should -Not -Be $originalContent

            # VÃ©rifier que les fonctions spÃ©cifiques Ã  PowerShell Windows ont Ã©tÃ© remplacÃ©es
            $modifiedContent | Should -Not -Match "Get-WmiObject"
            $modifiedContent | Should -Match "Get-CimInstance"
        }
    }

    AfterAll {
        # Nettoyer
        Remove-Module -Name EnvironmentManager -Force -ErrorAction SilentlyContinue

        # Supprimer le rÃ©pertoire de test
        if (Test-Path -Path $testRoot) {
            Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed
