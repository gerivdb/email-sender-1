<#
.SYNOPSIS
    Script pour exécuter les tests progressifs pour les fonctionnalités de clonage profond.

.DESCRIPTION
    Ce script exécute les tests progressifs pour les fonctionnalités de clonage profond
    en utilisant une nouvelle session PowerShell pour éviter les conflits avec les modules existants.

.PARAMETER Phase
    Phase de test à exécuter. Valeurs possibles: P1, P2, P3, P4, All.
    Par défaut: All (toutes les phases).

.EXAMPLE
    .\RunTestDeepClone.ps1 -Phase P1

    Exécute les tests de phase 1 (tests basiques) pour les fonctionnalités de clonage profond.

.NOTES
    Version:        1.0.0
    Auteur:         UnifiedParallel Team
    Date création:  2025-05-26
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('P1', 'P2', 'P3', 'P4', 'All')]
    [string]$Phase = 'All'
)

# Chemin du script de test
$testScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "TestDeepClone.Progressive.Tests.ps1"

# Vérifier que le script de test existe
if (-not (Test-Path -Path $testScriptPath)) {
    throw "Le script de test n'a pas été trouvé à l'emplacement $testScriptPath."
}

# Créer un script temporaire pour exécuter les tests dans une nouvelle session PowerShell
$tempScriptPath = Join-Path -Path $env:TEMP -ChildPath "RunTestDeepClone_$(Get-Date -Format 'yyyyMMdd_HHmmss').ps1"

$scriptContent = @"
# Importer Pester
Import-Module Pester

# Exécuter les tests
Invoke-Pester -Path '$testScriptPath' -Tag '$Phase'
"@

Set-Content -Path $tempScriptPath -Value $scriptContent

try {
    # Exécuter le script temporaire dans une nouvelle session PowerShell
    Write-Host "Exécution des tests de phase $Phase pour les fonctionnalités de clonage profond..." -ForegroundColor Cyan
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tempScriptPath
}
finally {
    # Supprimer le script temporaire
    if (Test-Path -Path $tempScriptPath) {
        Remove-Item -Path $tempScriptPath -Force
    }
}
