<#
.SYNOPSIS
    Tests unitaires pour le script Improve-ScriptCompatibility.

.DESCRIPTION
    Ce script contient des tests unitaires pour le script Improve-ScriptCompatibility
    en utilisant le framework Pester.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
    Prérequis:      Pester 5.0 ou supérieur
#>

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Définir le chemin du script à tester
$scriptRoot = $PSScriptRoot
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "Improve-ScriptCompatibility.ps1"
$modulePath = Join-Path -Path $scriptRoot -ChildPath "EnvironmentManager.psm1"

# Créer un répertoire temporaire pour les tests
$testRoot = Join-Path -Path $env:TEMP -ChildPath "ScriptCompatibilityTests"
if (Test-Path -Path $testRoot) {
    Remove-Item -Path $testRoot -Recurse -Force
}
New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

# Définir les tests Pester
Describe "Script Improve-ScriptCompatibility" {
    BeforeAll {
        # Importer le module EnvironmentManager
        Import-Module $modulePath -Force

        # Initialiser le module
        Initialize-EnvironmentManager

        # Créer des scripts de test avec différents problèmes de compatibilité
        $testScripts = @{
            "HardcodedPaths" = @{
                Path = Join-Path -Path $testRoot -ChildPath "HardcodedPaths.ps1"
                Content = @"
# Script avec des chemins codés en dur
`$logPath = "D:\Logs\app.log"
`$configPath = "C:\Program Files\App\config.xml"
Write-Host "Log Path: `$logPath"
Write-Host "Config Path: `$configPath"
"@
            }
            "WindowsSeparators" = @{
                Path = Join-Path -Path $testRoot -ChildPath "WindowsSeparators.ps1"
                Content = @"
# Script avec des séparateurs de chemin spécifiques à Windows
`$scriptPath = "scripts\\utils\\path-utils.ps1"
`$dataPath = "data\\files\\data.csv"
Write-Host "Script Path: `$scriptPath"
Write-Host "Data Path: `$dataPath"
"@
            }
            "WindowsCommands" = @{
                Path = Join-Path -Path $testRoot -ChildPath "WindowsCommands.ps1"
                Content = @"
# Script avec des commandes spécifiques à Windows
`$result = cmd.exe /c "dir /b"
`$output = powershell.exe -Command "Get-Process"
Write-Host "Result: `$result"
Write-Host "Output: `$output"
"@
            }
            "WindowsEnvironmentVars" = @{
                Path = Join-Path -Path $testRoot -ChildPath "WindowsEnvironmentVars.ps1"
                Content = @"
# Script avec des variables d'environnement spécifiques à Windows
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
# Script avec des fonctions spécifiques à PowerShell Windows
`$processes = Get-WmiObject -Class Win32_Process
`$logs = Get-EventLog -LogName Application -Newest 10
Write-Host "Processes: `$(`$processes.Count)"
Write-Host "Logs: `$(`$logs.Count)"
"@
            }
            "AlreadyCompatible" = @{
                Path = Join-Path -Path $testRoot -ChildPath "AlreadyCompatible.ps1"
                Content = @"
# Script déjà compatible
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

        # Créer les fichiers de test
        foreach ($script in $testScripts.GetEnumerator()) {
            Set-Content -Path $script.Value.Path -Value $script.Value.Content -Force
        }
    }

    Context "Analyse de compatibilité" {
        It "Devrait détecter les chemins codés en dur" {
            $scriptPath = $testScripts["HardcodedPaths"].Path
            $result = & $scriptPath -ScriptPath $scriptPath -ReportOnly
            $result.Issues | Should -Contain "Chemins codés en dur"
        }

        It "Devrait détecter les séparateurs de chemin spécifiques à Windows" {
            $scriptPath = $testScripts["WindowsSeparators"].Path
            $result = & $scriptPath -ScriptPath $scriptPath -ReportOnly
            $result.Issues | Should -Contain "Séparateurs de chemin spécifiques à Windows"
        }

        It "Devrait détecter les commandes spécifiques à Windows" {
            $scriptPath = $testScripts["WindowsCommands"].Path
            $result = & $scriptPath -ScriptPath $scriptPath -ReportOnly
            $result.Issues | Should -Contain "Commandes spécifiques à Windows"
        }

        It "Devrait détecter les variables d'environnement spécifiques à Windows" {
            $scriptPath = $testScripts["WindowsEnvironmentVars"].Path
            $result = & $scriptPath -ScriptPath $scriptPath -ReportOnly
            $result.Issues | Should -Contain "Variables d'environnement spécifiques à Windows"
        }

        It "Devrait détecter les fonctions spécifiques à PowerShell Windows" {
            $scriptPath = $testScripts["WindowsFunctions"].Path
            $result = & $scriptPath -ScriptPath $scriptPath -ReportOnly
            $result.Issues | Should -Contain "Fonctions spécifiques à PowerShell Windows"
        }
    }

    Context "Amélioration de compatibilité" {
        It "Devrait améliorer les chemins codés en dur" {
            $scriptPath = $testScripts["HardcodedPaths"].Path
            $backupPath = "$scriptPath.bak"

            # Créer une sauvegarde du script original
            Copy-Item -Path $scriptPath -Destination $backupPath -Force

            # Améliorer le script
            & $scriptPath -ScriptPath $scriptPath -BackupFiles

            # Vérifier que le script a été modifié
            $originalContent = Get-Content -Path $backupPath -Raw
            $modifiedContent = Get-Content -Path $scriptPath -Raw
            $modifiedContent | Should -Not -Be $originalContent

            # Vérifier que le module EnvironmentManager a été importé
            $modifiedContent | Should -Match "EnvironmentManager\.psm1"
        }

        It "Devrait améliorer les séparateurs de chemin spécifiques à Windows" {
            $scriptPath = $testScripts["WindowsSeparators"].Path
            $backupPath = "$scriptPath.bak"

            # Créer une sauvegarde du script original
            Copy-Item -Path $scriptPath -Destination $backupPath -Force

            # Améliorer le script
            & $scriptPath -ScriptPath $scriptPath -BackupFiles

            # Vérifier que le script a été modifié
            $originalContent = Get-Content -Path $backupPath -Raw
            $modifiedContent = Get-Content -Path $scriptPath -Raw
            $modifiedContent | Should -Not -Be $originalContent

            # Vérifier que les séparateurs de chemin ont été standardisés
            $modifiedContent | Should -Not -Match "scripts\\\\utils\\\\path-utils\.ps1"
        }

        It "Devrait améliorer les commandes spécifiques à Windows" {
            $scriptPath = $testScripts["WindowsCommands"].Path
            $backupPath = "$scriptPath.bak"

            # Créer une sauvegarde du script original
            Copy-Item -Path $scriptPath -Destination $backupPath -Force

            # Améliorer le script
            & $scriptPath -ScriptPath $scriptPath -BackupFiles

            # Vérifier que le script a été modifié
            $originalContent = Get-Content -Path $backupPath -Raw
            $modifiedContent = Get-Content -Path $scriptPath -Raw
            $modifiedContent | Should -Not -Be $originalContent

            # Vérifier que les commandes spécifiques à Windows ont été remplacées
            $modifiedContent | Should -Not -Match "cmd\.exe /c"
            $modifiedContent | Should -Match "Invoke-CrossPlatformCommand"
        }

        It "Devrait améliorer les variables d'environnement spécifiques à Windows" {
            $scriptPath = $testScripts["WindowsEnvironmentVars"].Path
            $backupPath = "$scriptPath.bak"

            # Créer une sauvegarde du script original
            Copy-Item -Path $scriptPath -Destination $backupPath -Force

            # Améliorer le script
            & $scriptPath -ScriptPath $scriptPath -BackupFiles

            # Vérifier que le script a été modifié
            $originalContent = Get-Content -Path $backupPath -Raw
            $modifiedContent = Get-Content -Path $scriptPath -Raw
            $modifiedContent | Should -Not -Be $originalContent

            # Vérifier que les variables d'environnement spécifiques à Windows ont été remplacées
            $modifiedContent | Should -Match "if \(\$IsWindows\)"
        }

        It "Devrait améliorer les fonctions spécifiques à PowerShell Windows" {
            $scriptPath = $testScripts["WindowsFunctions"].Path
            $backupPath = "$scriptPath.bak"

            # Créer une sauvegarde du script original
            Copy-Item -Path $scriptPath -Destination $backupPath -Force

            # Améliorer le script
            & $scriptPath -ScriptPath $scriptPath -BackupFiles

            # Vérifier que le script a été modifié
            $originalContent = Get-Content -Path $backupPath -Raw
            $modifiedContent = Get-Content -Path $scriptPath -Raw
            $modifiedContent | Should -Not -Be $originalContent

            # Vérifier que les fonctions spécifiques à PowerShell Windows ont été remplacées
            $modifiedContent | Should -Not -Match "Get-WmiObject"
            $modifiedContent | Should -Match "Get-CimInstance"
        }
    }

    AfterAll {
        # Nettoyer
        Remove-Module -Name EnvironmentManager -Force -ErrorAction SilentlyContinue

        # Supprimer le répertoire de test
        if (Test-Path -Path $testRoot) {
            Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Exécuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed
