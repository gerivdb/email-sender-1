<#
.SYNOPSIS
    Script pour exécuter les tests progressifs pour le mécanisme de throttling adaptatif.

.DESCRIPTION
    Ce script exécute les tests progressifs pour le mécanisme de throttling adaptatif
    en utilisant une nouvelle session PowerShell pour chaque phase de test.

.PARAMETER Phase
    Phase de test à exécuter. Valeurs possibles: P1, P2, P3, P4, All.
    Par défaut: All (toutes les phases).

.EXAMPLE
    .\Run-AdaptiveThrottlingTests.ps1 -Phase P1

    Exécute les tests de phase 1 (tests basiques) pour le mécanisme de throttling adaptatif.

.NOTES
    Version:        1.0.0
    Auteur:         UnifiedParallel Team
    Date création:  2025-05-27
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('P1', 'P2', 'P3', 'P4', 'All')]
    [string]$Phase = 'All'
)

# Chemin du script de test
$testScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "AdaptiveThrottling.Progressive.Tests.ps1"

# Vérifier que le script de test existe
if (-not (Test-Path -Path $testScriptPath)) {
    throw "Le script de test n'a pas été trouvé à l'emplacement $testScriptPath."
}

# Fonction pour exécuter les tests d'une phase spécifique
function Invoke-PhaseTests {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Phase
    )

    Write-Host "Exécution des tests de phase $Phase pour le throttling adaptatif..." -ForegroundColor Cyan

    # Exécuter les tests avec un job PowerShell pour pouvoir utiliser un timeout
    try {
        # Créer un job pour exécuter les tests
        $job = Start-Job -ScriptBlock {
            param($testScriptPath, $phase)
            Import-Module Pester
            Invoke-Pester -Path $testScriptPath -Tag $phase -Output Detailed
        } -ArgumentList $testScriptPath, $Phase

        # Attendre que le job se termine ou que le timeout soit atteint
        $timeout = 120 # secondes
        if (-not (Wait-Job -Job $job -Timeout $timeout)) {
            Write-Warning "Le job n'a pas terminé dans le délai imparti ($timeout secondes). Arrêt forcé."
            Stop-Job -Job $job
        }
        else {
            # Récupérer les résultats du job
            Receive-Job -Job $job
        }
    }
    finally {
        # Nettoyer les jobs
        Get-Job | Where-Object { $_.State -ne 'Running' } | Remove-Job
    }
}

# Exécuter les tests selon la phase spécifiée
if ($Phase -eq 'All') {
    Write-Host "Exécution de tous les tests progressifs pour le throttling adaptatif..." -ForegroundColor Green
    
    # Exécuter chaque phase séparément
    Invoke-PhaseTests -Phase 'P1'
    Invoke-PhaseTests -Phase 'P2'
    Invoke-PhaseTests -Phase 'P3'
    Invoke-PhaseTests -Phase 'P4'
}
else {
    # Exécuter la phase spécifiée
    Invoke-PhaseTests -Phase $Phase
}

Write-Host "Exécution des tests terminée." -ForegroundColor Green
