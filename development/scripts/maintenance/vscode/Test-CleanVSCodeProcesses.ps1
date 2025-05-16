﻿<#
.SYNOPSIS
Teste le script Clean-VSCodeProcesses.ps1.

.DESCRIPTION
Ce script teste le script Clean-VSCodeProcesses.ps1 en mode simulation (WhatIf)
pour vérifier qu'il fonctionne correctement sans arrêter réellement des processus.

.EXAMPLE
    .\Test-CleanVSCodeProcesses.ps1

.NOTES
    Auteur: Maintenance Team
    Version: 1.0
    Date de création: 2025-05-16
#>

# Définir le chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Clean-VSCodeProcesses.ps1"

# Vérifier si le script existe
if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
    Write-Error "Le script Clean-VSCodeProcesses.ps1 n'existe pas: $scriptPath"
    exit 1
}

# Fonction pour vérifier la syntaxe du script
function Test-ScriptSyntax {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    try {
        # Utiliser la méthode moderne pour vérifier la syntaxe (PowerShell 5.1+)
        if ($PSVersionTable.PSVersion.Major -ge 5) {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$errors)

            if ($errors.Count -gt 0) {
                foreach ($error in $errors) {
                    Write-Error "Erreur de syntaxe à la ligne $($error.Extent.StartLineNumber), colonne $($error.Extent.StartColumnNumber): $($error.Message)"
                }
                return $false
            }
        }
        # Méthode de secours pour les anciennes versions de PowerShell
        else {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $ScriptPath -Raw), [ref]$null)
        }

        Write-Host "Vérification de la syntaxe réussie pour: $ScriptPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Erreur de syntaxe dans le script $ScriptPath : $_"
        return $false
    }
}

# Fonction pour créer des processus VSCode fictifs pour les tests
function Get-MockVSCodeProcesses {
    [CmdletBinding()]
    param (
        [int]$Count = 5
    )

    $mockProcesses = @()

    for ($i = 1; $i -le $Count; $i++) {
        $mockProcesses += [PSCustomObject]@{
            Id = 1000 + $i
            Name = "code"
            WorkingSetMB = 100 * $i
            CPU = 5 * $i
            StartTime = (Get-Date).AddMinutes(-$i * 10)
            MainWindowTitle = if ($i -eq 1) { "Visual Studio Code" } else { "" }
            MainWindowHandle = if ($i -eq 1) { 12345 } else { 0 }
        }
    }

    return $mockProcesses
}

# Fonction pour tester le script Clean-VSCodeProcesses.ps1
function Test-CleanVSCodeProcesses {
    [CmdletBinding()]
    param ()

    Write-Host "Test du script Clean-VSCodeProcesses.ps1..." -ForegroundColor Cyan

    # Vérifier la syntaxe du script
    if (-not (Test-ScriptSyntax -ScriptPath $scriptPath)) {
        return $false
    }

    # Tester les fonctionnalités du script
    try {
        # Créer un mock pour Get-Process
        $mockScript = @'
function Get-Process {
    param()

    $processes = @()

    # Créer 5 processus fictifs
    for ($i = 1; $i -le 5; $i++) {
        $processes += [PSCustomObject]@{
            Id = 1000 + $i
            Name = "code"
            WorkingSet = 100MB * $i
            CPU = 5 * $i
            StartTime = (Get-Date).AddMinutes(-$i * 10)
            MainWindowTitle = if ($i -eq 1) { "Visual Studio Code" } else { "" }
            MainWindowHandle = if ($i -eq 1) { 12345 } else { 0 }
        }
    }

    return $processes
}

function Stop-Process {
    param(
        [int]$Id,
        [switch]$Force
    )

    Write-Host "[MOCK] Arrêt du processus $Id" -ForegroundColor Yellow
    return $true
}
'@

        # Créer un fichier temporaire pour le mock
        $mockPath = Join-Path -Path $env:TEMP -ChildPath "VSCodeMock.ps1"
        Set-Content -Path $mockPath -Value $mockScript -Force

        Write-Host "Exécution du script avec le mock et WhatIf..." -ForegroundColor Cyan

        # Exécuter le script avec le mock et WhatIf
        Write-Host "Commande à exécuter: & '$mockPath'; & '$scriptPath' -WhatIf" -ForegroundColor Cyan

        # Exécuter le mock d'abord
        . $mockPath

        # Puis exécuter le script à tester
        & $scriptPath -WhatIf

        # Nettoyer le fichier temporaire
        Remove-Item -Path $mockPath -Force

        Write-Host "Test du script Clean-VSCodeProcesses.ps1 réussi." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Erreur lors du test du script Clean-VSCodeProcesses.ps1 : $_"
        return $false
    }
}

# Exécuter le test
$result = Test-CleanVSCodeProcesses

# Afficher le résultat
if ($result) {
    Write-Host "Le script Clean-VSCodeProcesses.ps1 a passé tous les tests avec succès!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Le script Clean-VSCodeProcesses.ps1 a échoué aux tests." -ForegroundColor Red
    exit 1
}
