<#
.SYNOPSIS
    Exemple d'utilisation du module UsageMonitor.
.DESCRIPTION
    Ce script montre comment utiliser le module UsageMonitor pour suivre l'utilisation des scripts
    et analyser les performances.
.EXAMPLE
    .\Example-Usage.ps1
.NOTES
    Auteur: Augment Agent
    Date: 2025-05-15
    Version: 1.0
#>

# Importer le module UsageMonitor
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "UsageMonitor.psm1"
Import-Module $modulePath -Force

# Initialiser le moniteur d'utilisation
Initialize-UsageMonitor -Verbose

# Fonction de démonstration qui simule un script avec différentes performances
function Test-ScriptPerformance {
    param (
        [int]$Duration,
        [bool]$ShouldFail = $false
    )
    
    # Démarrer le suivi d'utilisation
    $executionId = Start-ScriptUsageTracking -ScriptPath $PSCommandPath -Function "Test-ScriptPerformance" -Parameters @{
        Duration = $Duration
        ShouldFail = $ShouldFail
    }
    
    try {
        # Simuler un traitement
        Write-Host "Exécution du script pendant $Duration ms..." -ForegroundColor Cyan
        Start-Sleep -Milliseconds $Duration
        
        # Simuler une utilisation de mémoire
        $array = New-Object byte[] (1024 * 1024 * 10) # 10 Mo
        
        # Simuler une erreur si demandé
        if ($ShouldFail) {
            throw "Erreur simulée pour les besoins de la démonstration"
        }
        
        # Terminer le suivi d'utilisation avec succès
        Stop-ScriptUsageTracking -ExecutionId $executionId -Success $true
        
        return "Opération réussie"
    }
    catch {
        # Terminer le suivi d'utilisation avec échec
        Stop-ScriptUsageTracking -ExecutionId $executionId -Success $false -ErrorMessage $_.Exception.Message
        
        Write-Error "Erreur lors de l'exécution du script: $_"
        return "Opération échouée"
    }
    finally {
        # Libérer la mémoire
        $array = $null
        [System.GC]::Collect()
    }
}

# Exécuter plusieurs tests avec différentes durées et résultats
Write-Host "`n=== Exécution de tests de performance ===" -ForegroundColor Green

# Tests réussis avec différentes durées
for ($i = 1; $i -le 5; $i++) {
    $duration = Get-Random -Minimum 100 -Maximum 500
    Test-ScriptPerformance -Duration $duration
}

# Tests plus lents (potentiels goulots d'étranglement)
for ($i = 1; $i -le 2; $i++) {
    $duration = Get-Random -Minimum 800 -Maximum 1200
    Test-ScriptPerformance -Duration $duration
}

# Tests avec échecs
for ($i = 1; $i -le 3; $i++) {
    $duration = Get-Random -Minimum 100 -Maximum 300
    Test-ScriptPerformance -Duration $duration -ShouldFail $true
}

# Afficher les statistiques d'utilisation
Write-Host "`n=== Statistiques d'utilisation ===" -ForegroundColor Green
$stats = Get-ScriptUsageStatistics
Write-Host "`nScripts les plus utilisés:" -ForegroundColor Yellow
$stats.TopUsedScripts | Format-Table -AutoSize

Write-Host "`nScripts les plus lents:" -ForegroundColor Yellow
$stats.SlowestScripts | Format-Table -AutoSize

Write-Host "`nScripts avec le plus d'échecs:" -ForegroundColor Yellow
$stats.MostFailingScripts | Format-Table -AutoSize

Write-Host "`nScripts les plus intensifs en ressources:" -ForegroundColor Yellow
$stats.ResourceIntensiveScripts | Format-Table -AutoSize

# Analyser les goulots d'étranglement
Write-Host "`n=== Analyse des goulots d'étranglement ===" -ForegroundColor Green
$bottlenecks = Find-ScriptBottlenecks
if ($bottlenecks.Count -gt 0) {
    $bottlenecks | ForEach-Object {
        Write-Host "`nGoulot d'étranglement détecté dans $($_.ScriptName):" -ForegroundColor Red
        Write-Host "  - Durée moyenne: $([math]::Round($_.AverageDuration, 2)) ms" -ForegroundColor Yellow
        Write-Host "  - Seuil de lenteur: $([math]::Round($_.SlowThreshold, 2)) ms" -ForegroundColor Yellow
        Write-Host "  - Exécutions lentes: $($_.SlowExecutionsCount)/$($_.TotalExecutionsCount) ($([math]::Round($_.SlowExecutionPercentage, 2))%)" -ForegroundColor Yellow
    }
}
else {
    Write-Host "Aucun goulot d'étranglement détecté." -ForegroundColor Green
}

# Sauvegarder la base de données
Save-UsageDatabase -Verbose
