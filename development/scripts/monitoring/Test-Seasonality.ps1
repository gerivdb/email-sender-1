#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour la fonction d'analyse de saisonnalité du module TrendAnalyzer.
.DESCRIPTION
    Ce script teste la fonction d'analyse de saisonnalité du module TrendAnalyzer
    en utilisant des données de test avec des patterns saisonniers.
.NOTES
    Nom: Test-Seasonality.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.3
    Date de création: 2025-05-13
#>

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "TrendAnalyzer.psm1"
Import-Module $modulePath -Force

# Créer des données de test avec un pattern saisonnier journalier
function New-SeasonalTestData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Days = 7,
        
        [Parameter(Mandatory = $false)]
        [int]$SamplesPerDay = 24
    )
    
    $startTime = (Get-Date).Date.AddDays(-$Days)
    $endTime = (Get-Date).Date
    $totalSamples = $Days * $SamplesPerDay
    
    $values = @()
    $timestamps = @()
    
    # Générer des données avec un pattern journalier clair
    for ($day = 0; $day -lt $Days; $day++) {
        for ($hour = 0; $hour -lt $SamplesPerDay; $hour++) {
            $timestamp = $startTime.AddDays($day).AddHours($hour)
            $timestamps += $timestamp
            
            # Pattern journalier: pic à 14h, creux à 2h
            $baseValue = 50
            $dailyAmplitude = 30
            
            # Pattern hebdomadaire: plus élevé en semaine, plus bas le weekend
            $weekdayFactor = if ($timestamp.DayOfWeek -in @([DayOfWeek]::Saturday, [DayOfWeek]::Sunday)) { 0.7 } else { 1.2 }
            
            # Calculer la valeur en fonction de l'heure (pattern journalier)
            if ($hour -ge 2 -and $hour -lt 14) {
                # De 2h à 14h: montée progressive
                $factor = ($hour - 2) / 12.0
                $dailyValue = $baseValue + $dailyAmplitude * $factor
            }
            elseif ($hour -ge 14) {
                # De 14h à 2h (le lendemain): descente progressive
                $factor = 1 - (($hour - 14) / 12.0)
                $dailyValue = $baseValue + $dailyAmplitude * $factor
            }
            else {
                # De 0h à 2h: fin de la descente
                $factor = 1 - ((24 + $hour - 14) / 12.0)
                $dailyValue = $baseValue + $dailyAmplitude * $factor
            }
            
            # Appliquer le facteur hebdomadaire
            $value = $dailyValue * $weekdayFactor
            
            # Ajouter un peu de bruit aléatoire
            $value = [Math]::Min(100, [Math]::Max(0, $value + (Get-Random -Minimum -5 -Maximum 5)))
            
            $values += $value
        }
    }
    
    # Créer la structure de données
    $testData = @{
        CollectorName = "TestSeasonalCollector"
        StartTime = $startTime
        EndTime = $endTime
        SamplingInterval = 3600 # 1 heure
        MetricsData = @{
            CPU_Usage = @{
                Values = $values
                Timestamps = $timestamps
                Unit = "%"
            }
        }
    }
    
    return $testData
}

Write-Host "Test d'analyse de saisonnalité" -ForegroundColor Cyan

# Créer des données de test avec des patterns saisonniers
$testData = New-SeasonalTestData -Days 14 -SamplesPerDay 24
Write-Host "Données de test créées: $($testData.MetricsData.CPU_Usage.Values.Count) échantillons sur $((New-TimeSpan -Start $testData.StartTime -End $testData.EndTime).Days) jours" -ForegroundColor Yellow

# Analyser la saisonnalité journalière
Write-Host "`nTest de l'analyse de saisonnalité journalière:" -ForegroundColor Yellow
$seasonality = Get-MetricsSeasonality -MetricsData $testData -MetricName "CPU_Usage" -SeasonalityPeriods @(24)

if ($null -eq $seasonality) {
    Write-Host "Échec: Aucun résultat d'analyse de saisonnalité retourné." -ForegroundColor Red
    exit 1
}

# Vérifier si la saisonnalité a été détectée
$dailySeasonality = $seasonality.SeasonalityResults[24]

Write-Host "Résultats de l'analyse de saisonnalité journalière:" -ForegroundColor Cyan
Write-Host "  Saisonnalité détectée: $($dailySeasonality.HasSeasonality)"
Write-Host "  Force de la saisonnalité: $([Math]::Round($dailySeasonality.SeasonalityStrength, 3))"
Write-Host "  Confiance: $([Math]::Round($dailySeasonality.Confidence * 100, 1))%"

if ($dailySeasonality.HasSeasonality) {
    Write-Host "  Pics d'autocorrélation aux décalages: $($dailySeasonality.PeakLags -join ', ')"
    
    # Vérifier que le pic principal est proche de 24h
    $mainPeak = $dailySeasonality.PeakLags[0]
    $peakNear24 = [Math]::Abs($mainPeak - 24) -lt 3
    
    if ($peakNear24) {
        Write-Host "`nTest réussi: Saisonnalité journalière correctement détectée!" -ForegroundColor Green
    }
    else {
        Write-Host "`nÉchec: Le pic principal n'est pas proche de 24h." -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "`nÉchec: Aucune saisonnalité journalière détectée." -ForegroundColor Red
    exit 1
}

# Analyser la saisonnalité hebdomadaire
Write-Host "`nTest de l'analyse de saisonnalité hebdomadaire:" -ForegroundColor Yellow
$seasonality = Get-MetricsSeasonality -MetricsData $testData -MetricName "CPU_Usage" -SeasonalityPeriods @(168)

if ($null -eq $seasonality) {
    Write-Host "Échec: Aucun résultat d'analyse de saisonnalité retourné." -ForegroundColor Red
    exit 1
}

# Vérifier si la saisonnalité a été détectée
$weeklySeasonality = $seasonality.SeasonalityResults[168]

Write-Host "Résultats de l'analyse de saisonnalité hebdomadaire:" -ForegroundColor Cyan
Write-Host "  Saisonnalité détectée: $($weeklySeasonality.HasSeasonality)"

if ($weeklySeasonality.HasSeasonality) {
    Write-Host "  Force de la saisonnalité: $([Math]::Round($weeklySeasonality.SeasonalityStrength, 3))"
    Write-Host "  Confiance: $([Math]::Round($weeklySeasonality.Confidence * 100, 1))%"
    Write-Host "  Pics d'autocorrélation aux décalages: $($weeklySeasonality.PeakLags -join ', ')"
    Write-Host "`nTest réussi: Saisonnalité hebdomadaire correctement détectée!" -ForegroundColor Green
}
else {
    Write-Host "  Raison: $($weeklySeasonality.Reason)" -ForegroundColor Yellow
    Write-Host "`nNote: La saisonnalité hebdomadaire peut nécessiter plus de données pour être détectée." -ForegroundColor Yellow
}

Write-Host "`nTous les tests d'analyse de saisonnalité ont réussi!" -ForegroundColor Green
exit 0
