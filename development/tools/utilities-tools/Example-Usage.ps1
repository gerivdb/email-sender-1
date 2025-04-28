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

# Fonction de dÃ©monstration qui simule un script avec diffÃ©rentes performances
function Test-ScriptPerformance {
    param (
        [int]$Duration,
        [bool]$ShouldFail = $false
    )
    
    # DÃ©marrer le suivi d'utilisation
    $executionId = Start-ScriptUsageTracking -ScriptPath $PSCommandPath -Function "Test-ScriptPerformance" -Parameters @{
        Duration = $Duration
        ShouldFail = $ShouldFail
    }
    
    try {
        # Simuler un traitement
        Write-Host "ExÃ©cution du script pendant $Duration ms..." -ForegroundColor Cyan
        Start-Sleep -Milliseconds $Duration
        
        # Simuler une utilisation de mÃ©moire
        $array = New-Object byte[] (1024 * 1024 * 10) # 10 Mo
        
        # Simuler une erreur si demandÃ©
        if ($ShouldFail) {
            throw "Erreur simulÃ©e pour les besoins de la dÃ©monstration"
        }
        
        # Terminer le suivi d'utilisation avec succÃ¨s
        Stop-ScriptUsageTracking -ExecutionId $executionId -Success $true
        
        return "OpÃ©ration rÃ©ussie"
    }
    catch {
        # Terminer le suivi d'utilisation avec Ã©chec
        Stop-ScriptUsageTracking -ExecutionId $executionId -Success $false -ErrorMessage $_.Exception.Message
        
        Write-Error "Erreur lors de l'exÃ©cution du script: $_"
        return "OpÃ©ration Ã©chouÃ©e"
    }
    finally {
        # LibÃ©rer la mÃ©moire
        $array = $null
        [System.GC]::Collect()
    }
}

# ExÃ©cuter plusieurs tests avec diffÃ©rentes durÃ©es et rÃ©sultats
Write-Host "`n=== ExÃ©cution de tests de performance ===" -ForegroundColor Green

# Tests rÃ©ussis avec diffÃ©rentes durÃ©es
for ($i = 1; $i -le 5; $i++) {
    $duration = Get-Random -Minimum 100 -Maximum 500
    Test-ScriptPerformance -Duration $duration
}

# Tests plus lents (potentiels goulots d'Ã©tranglement)
for ($i = 1; $i -le 2; $i++) {
    $duration = Get-Random -Minimum 800 -Maximum 1200
    Test-ScriptPerformance -Duration $duration
}

# Tests avec Ã©checs
for ($i = 1; $i -le 3; $i++) {
    $duration = Get-Random -Minimum 100 -Maximum 300
    Test-ScriptPerformance -Duration $duration -ShouldFail $true
}

# Afficher les statistiques d'utilisation
Write-Host "`n=== Statistiques d'utilisation ===" -ForegroundColor Green
$stats = Get-ScriptUsageStatistics
Write-Host "`nScripts les plus utilisÃ©s:" -ForegroundColor Yellow
$stats.TopUsedScripts | Format-Table -AutoSize

Write-Host "`nScripts les plus lents:" -ForegroundColor Yellow
$stats.SlowestScripts | Format-Table -AutoSize

Write-Host "`nScripts avec le plus d'Ã©checs:" -ForegroundColor Yellow
$stats.MostFailingScripts | Format-Table -AutoSize

Write-Host "`nScripts les plus intensifs en ressources:" -ForegroundColor Yellow
$stats.ResourceIntensiveScripts | Format-Table -AutoSize

# Analyser les goulots d'Ã©tranglement
Write-Host "`n=== Analyse des goulots d'Ã©tranglement ===" -ForegroundColor Green
$bottlenecks = Find-ScriptBottlenecks
if ($bottlenecks.Count -gt 0) {
    $bottlenecks | ForEach-Object {
        Write-Host "`nGoulot d'Ã©tranglement dÃ©tectÃ© dans $($_.ScriptName):" -ForegroundColor Red
        Write-Host "  - DurÃ©e moyenne: $([math]::Round($_.AverageDuration, 2)) ms" -ForegroundColor Yellow
        Write-Host "  - Seuil de lenteur: $([math]::Round($_.SlowThreshold, 2)) ms" -ForegroundColor Yellow
        Write-Host "  - ExÃ©cutions lentes: $($_.SlowExecutionsCount)/$($_.TotalExecutionsCount) ($([math]::Round($_.SlowExecutionPercentage, 2))%)" -ForegroundColor Yellow
    }
}
else {
    Write-Host "Aucun goulot d'Ã©tranglement dÃ©tectÃ©." -ForegroundColor Green
}

# Sauvegarder la base de donnÃ©es
Save-UsageDatabase -Verbose
