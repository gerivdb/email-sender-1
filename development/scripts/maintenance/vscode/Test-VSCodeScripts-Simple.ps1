<#
.SYNOPSIS
Teste les scripts de maintenance VSCode.

.DESCRIPTION
Ce script teste les scripts de maintenance VSCode pour s'assurer qu'ils fonctionnent correctement.

.EXAMPLE
.\Test-VSCodeScripts-Simple.ps1

.NOTES
Auteur: Maintenance Team
Version: 1.0
Date de création: 2025-05-16
#>

[CmdletBinding()]
param ()

# Fonction pour tester un script PowerShell
function Test-PowerShellScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [string[]]$Parameters = @()
    )

    Write-Host "Test du script: $ScriptPath" -ForegroundColor Cyan

    # Vérifier si le script existe
    if (-not (Test-Path -Path $ScriptPath -PathType Leaf)) {
        Write-Host "ERREUR: Le script n'existe pas: $ScriptPath" -ForegroundColor Red
        return $false
    }

    # Vérifier la syntaxe du script
    try {
        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$errors)

        if ($errors.Count -gt 0) {
            Write-Host "ERREUR: Erreurs de syntaxe dans le script:" -ForegroundColor Red
            foreach ($error in $errors) {
                Write-Host "  - Ligne $($error.Extent.StartLineNumber), colonne $($error.Extent.StartColumnNumber): $($error.Message)" -ForegroundColor Red
            }
            return $false
        }

        Write-Host "Syntaxe du script valide." -ForegroundColor Green

        # Exécuter le script avec les paramètres spécifiés
        if ($Parameters.Count -gt 0) {
            $paramString = $Parameters -join " "
            Write-Host "Exécution du script avec les paramètres: $paramString" -ForegroundColor Cyan

            # Construire la commande d'exécution
            $command = "& '$ScriptPath' $paramString"

            try {
                Invoke-Expression $command -ErrorAction Stop
                Write-Host "Exécution réussie." -ForegroundColor Green
                return $true
            } catch {
                Write-Host "ERREUR: Échec de l'exécution: $_" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "Aucun paramètre spécifié, test de syntaxe uniquement." -ForegroundColor Yellow
            return $true
        }
    } catch {
        Write-Host "ERREUR: Échec de la vérification de syntaxe: $_" -ForegroundColor Red
        return $false
    }
}

# Fonction principale
function Main {
    Write-Host "=== TESTS DES SCRIPTS DE MAINTENANCE VSCODE ===" -ForegroundColor Cyan
    Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Write-Host "Version PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan

    $scriptsToTest = @(
        @{
            Path       = Join-Path -Path $PSScriptRoot -ChildPath "Clean-VSCodeProcesses.ps1"
            Parameters = @("-WhatIf")
        },
        @{
            Path       = Join-Path -Path $PSScriptRoot -ChildPath "Monitor-VSCodeProcesses.ps1"
            Parameters = @("-RunOnce")
        },
        @{
            Path       = Join-Path -Path $PSScriptRoot -ChildPath "Configure-VSCodePerformance.ps1"
            Parameters = @()
        },
        @{
            Path       = Join-Path -Path $PSScriptRoot -ChildPath "Set-VSCodeStartupOptions.ps1"
            Parameters = @()
        }
    )

    $results = @()

    foreach ($script in $scriptsToTest) {
        $scriptName = Split-Path -Path $script.Path -Leaf
        $result = Test-PowerShellScript -ScriptPath $script.Path -Parameters $script.Parameters

        $results += [PSCustomObject]@{
            Script = $scriptName
            Result = $result
            Status = if ($result) { "RÉUSSI" } else { "ÉCHOUÉ" }
        }

        Write-Host "------------------------------------------------" -ForegroundColor Cyan
    }

    # Afficher le résumé des tests
    Write-Host "=== RÉSUMÉ DES TESTS ===" -ForegroundColor Cyan

    foreach ($result in $results) {
        $color = if ($result.Result) { "Green" } else { "Red" }
        Write-Host "$($result.Script): $($result.Status)" -ForegroundColor $color
    }

    $successCount = ($results | Where-Object { $_.Result -eq $true }).Count
    $failureCount = ($results | Where-Object { $_.Result -eq $false }).Count

    Write-Host "------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Total: $($results.Count) tests, $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })
    Write-Host "================================================" -ForegroundColor Cyan
}

# Exécuter la fonction principale
Main
