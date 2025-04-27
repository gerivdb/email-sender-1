<#
.SYNOPSIS
    Script simple de gestion d'erreurs pour les tests.

.DESCRIPTION
    Ce script implÃ©mente une gestion d'erreurs simple pour les tests.
    Il inclut des fonctions pour ajouter des blocs try/catch et journaliser les erreurs.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# Variables globales pour la configuration
$script:ErrorLogPath = Join-Path -Path $env:TEMP -ChildPath "ErrorLogs"
$script:DefaultErrorLogFile = Join-Path -Path $script:ErrorLogPath -ChildPath "error_log.json"

# Fonction pour initialiser le module
function Initialize-ErrorHandling {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$LogPath
    )

    try {
        # DÃ©finir le chemin du journal d'erreurs
        if ($LogPath) {
            $script:ErrorLogPath = $LogPath
        }

        if (-not (Test-Path -Path $script:ErrorLogPath)) {
            New-Item -Path $script:ErrorLogPath -ItemType Directory -Force | Out-Null
        }

        Write-Host "Gestion d'erreurs initialisÃ©e avec succÃ¨s. Chemin des journaux: $script:ErrorLogPath"
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'initialisation de la gestion d'erreurs: $_"
        return $false
    }
}

# Fonction pour ajouter un bloc try/catch Ã  un script
function Add-TryCatchBlock {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [switch]$BackupFile
    )

    try {
        # VÃ©rifier que le fichier existe
        if (-not (Test-Path -Path $ScriptPath)) {
            throw "Le fichier spÃ©cifiÃ© n'existe pas: $ScriptPath"
        }

        # CrÃ©er une sauvegarde si demandÃ©
        if ($BackupFile) {
            $backupPath = "$ScriptPath.bak"
            Copy-Item -Path $ScriptPath -Destination $backupPath -Force
            Write-Host "Sauvegarde crÃ©Ã©e: $backupPath"
        }

        # Lire le contenu du script
        $scriptContent = Get-Content -Path $ScriptPath -Raw

        # VÃ©rifier si le script contient dÃ©jÃ  des blocs try/catch
        $hasTryCatch = $scriptContent -match "try\s*\{"

        if ($hasTryCatch) {
            Write-Warning "Le script contient dÃ©jÃ  des blocs try/catch."
            return $false
        }

        # Ajouter un bloc try/catch global
        $newContent = @"
try {
$scriptContent
} catch {
    Write-Error "Erreur dans le script : `$_"
    Write-Log-Error -ErrorRecord `$_ -FunctionName "Main"
}
"@

        # Ã‰crire le contenu modifiÃ© dans le fichier
        Set-Content -Path $ScriptPath -Value $newContent -Force

        Write-Host "Blocs try/catch ajoutÃ©s avec succÃ¨s au script: $ScriptPath"
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'ajout des blocs try/catch: $_"
        return $false
    }
}

# Fonction pour journaliser une erreur
function Write-Log-Error {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory = $false)]
        [string]$FunctionName = "Unknown",

        [Parameter(Mandatory = $false)]
        [string]$Category = "Unknown"
    )

    try {
        # CrÃ©er le rÃ©pertoire de journaux s'il n'existe pas
        if (-not (Test-Path -Path $script:ErrorLogPath)) {
            New-Item -Path $script:ErrorLogPath -ItemType Directory -Force | Out-Null
        }

        # DÃ©finir le fichier de journal
        $logFile = Join-Path -Path $script:ErrorLogPath -ChildPath "error_log.json"

        # CrÃ©er l'entrÃ©e d'erreur
        $errorEntry = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            FunctionName = $FunctionName
            Category = $Category
            Message = $ErrorRecord.Exception.Message
            ScriptStackTrace = $ErrorRecord.ScriptStackTrace
            PositionMessage = $ErrorRecord.InvocationInfo.PositionMessage
            Exception = $ErrorRecord.Exception.GetType().FullName
        }

        # Charger le journal existant ou crÃ©er un nouveau
        $errorLog = @()
        if (Test-Path -Path $logFile) {
            $errorLogContent = Get-Content -Path $logFile -Raw
            if ($errorLogContent) {
                $errorLog = $errorLogContent | ConvertFrom-Json
            }
        }

        # Ajouter la nouvelle entrÃ©e
        $errorLog += $errorEntry

        # Enregistrer le journal
        $errorLog | ConvertTo-Json -Depth 5 | Set-Content -Path $logFile -Force

        Write-Host "Erreur journalisÃ©e avec succÃ¨s: $($ErrorRecord.Exception.Message)"
        return $true
    }
    catch {
        Write-Error "Erreur lors de la journalisation de l'erreur: $_"
        return $false
    }
}

# Fonction pour crÃ©er un script de test
function New-TestScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    try {
        $testScriptContent = @"
# Script de test sans gestion d'erreurs
function Test-Function {
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Path
    )

    Get-Content -Path `$Path
}

# Appeler la fonction avec un chemin invalide
Test-Function -Path "C:\chemin\invalide.txt"
"@

        Set-Content -Path $OutputPath -Value $testScriptContent -Force

        Write-Host "Script de test crÃ©Ã© avec succÃ¨s: $OutputPath"
        return $true
    }
    catch {
        Write-Error "Erreur lors de la crÃ©ation du script de test: $_"
        return $false
    }
}

# Fonction pour tester la gestion d'erreurs
function Test-ErrorHandling {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TestDirectory = (Join-Path -Path $env:TEMP -ChildPath "ErrorHandlingTests")
    )

    try {
        # CrÃ©er le rÃ©pertoire de test
        if (-not (Test-Path -Path $TestDirectory)) {
            New-Item -Path $TestDirectory -ItemType Directory -Force | Out-Null
        }

        # Initialiser la gestion d'erreurs
        Write-Host "Test 1: Initialisation de la gestion d'erreurs"
        $initResult = Initialize-ErrorHandling -LogPath $TestDirectory
        Write-Host "  RÃ©sultat: $initResult"

        # CrÃ©er un script de test
        $testScriptPath = Join-Path -Path $TestDirectory -ChildPath "TestScript.ps1"
        Write-Host "Test 2: CrÃ©ation d'un script de test"
        $createResult = New-TestScript -OutputPath $testScriptPath
        Write-Host "  RÃ©sultat: $createResult"

        # Ajouter des blocs try/catch
        Write-Host "Test 3: Ajout de blocs try/catch"
        $addResult = Add-TryCatchBlock -ScriptPath $testScriptPath -BackupFile
        Write-Host "  RÃ©sultat: $addResult"

        # Tester la journalisation des erreurs
        Write-Host "Test 4: Journalisation des erreurs"
        try {
            Get-Content -Path "C:\chemin\invalide.txt" -ErrorAction Stop
        }
        catch {
            $logResult = Write-Log-Error -ErrorRecord $_ -FunctionName "Test-Function" -Category "FileSystem"
            Write-Host "  RÃ©sultat: $logResult"
        }

        Write-Host "Tests terminÃ©s avec succÃ¨s!"
        return $true
    }
    catch {
        Write-Error "Erreur lors des tests: $_"
        return $false
    }
}

# Les fonctions sont disponibles aprÃ¨s avoir dot-sourced ce script
# Initialize-ErrorHandling, Add-TryCatchBlock, Write-Log-Error, New-TestScript, Test-ErrorHandling
