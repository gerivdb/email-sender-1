# Test-DurationCompositeTags.ps1
# Script pour tester l'extraction des tags de durée avec formats composés
# Version: 1.0
# Date: 2025-05-15

# Créer un contenu de test avec différents tags de durée composés
$testContent = @"
# Test de l'extraction des tags de durée avec formats composés

## Tags de durée composés jours/heures
- [ ] **1.1** Tâche avec tag de durée jours/heures #duration:2d4h
- [ ] **1.2** Tâche avec tag de durée jours/heures avec décimales #duration:1.5d3h
- [ ] **1.3** Tâche avec tag de durée jours/heures et séparateur #duration:2d-4h
- [ ] **1.4** Tâche avec tag de durée jours/heures et séparateur #duration:2d_4h

## Tags de durée composés heures/minutes
- [ ] **2.1** Tâche avec tag de durée heures/minutes #duration:3h30m
- [ ] **2.2** Tâche avec tag de durée heures/minutes avec décimales #duration:2.5h45m
- [ ] **2.3** Tâche avec tag de durée heures/minutes et séparateur #duration:3h-30m
- [ ] **2.4** Tâche avec tag de durée heures/minutes et séparateur #duration:3h_30m

## Tâches sans tags de durée
- [ ] **5.1** Tâche sans tag de durée
"@

# Fonction pour extraire les tags de type #duration avec formats composés
function Get-DurationCompositeTags {
    param (
        [string]$Content
    )

    Write-Host "Extraction des tags de type #duration avec formats composés..." -ForegroundColor Cyan

    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"

    # Initialiser les variables d'analyse
    $tasks = @{}

    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'

    # Patterns pour les tags de type #duration avec formats composés
    # Format jours/heures: #duration:XdYh ou #duration:Xd-Yh ou #duration:Xd_Yh
    $durationDaysHoursPattern = '#duration:(\d+(?:\.\d+)?)d[-_]?(\d+(?:\.\d+)?)h\b'

    # Format heures/minutes: #duration:XhYm ou #duration:Xh-Ym ou #duration:Xh_Ym
    $durationHoursMinutesPattern = '#duration:(\d+(?:\.\d+)?)h[-_]?(\d+(?:\.\d+)?)m\b'

    # Analyser chaque ligne
    foreach ($line in $lines) {
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line

            # Extraire les tags de durée composés jours/heures
            if ($taskLine -match $durationDaysHoursPattern) {
                $durationDays = $matches[1]
                $durationHours = $matches[2]

                if (-not $tasks.ContainsKey($taskId)) {
                    $tasks[$taskId] = @{
                        Id           = $taskId
                        DurationTags = @{
                            DaysHours    = @()
                            HoursMinutes = @()
                        }
                    }
                }

                $originalTag = if ($taskLine -match '#duration:\d+(?:\.\d+)?d[-_]?\d+(?:\.\d+)?h\b') { $matches[0] } else { "#duration:${durationDays}d${durationHours}h" }

                $tasks[$taskId].DurationTags.DaysHours += @{
                    Days     = $durationDays
                    Hours    = $durationHours
                    Original = $originalTag
                }

                Write-Host "Tache ${taskId}: ${durationDays} jours ${durationHours} heures (${originalTag})" -ForegroundColor Green
            }

            # Extraire les tags de durée composés heures/minutes
            if ($taskLine -match $durationHoursMinutesPattern) {
                $durationHours = $matches[1]
                $durationMinutes = $matches[2]

                if (-not $tasks.ContainsKey($taskId)) {
                    $tasks[$taskId] = @{
                        Id           = $taskId
                        DurationTags = @{
                            DaysHours    = @()
                            HoursMinutes = @()
                        }
                    }
                }

                $originalTag = if ($taskLine -match '#duration:\d+(?:\.\d+)?h[-_]?\d+(?:\.\d+)?m\b') { $matches[0] } else { "#duration:${durationHours}h${durationMinutes}m" }

                $tasks[$taskId].DurationTags.HoursMinutes += @{
                    Hours    = $durationHours
                    Minutes  = $durationMinutes
                    Original = $originalTag
                }

                Write-Host "Tache ${taskId}: ${durationHours} heures ${durationMinutes} minutes (${originalTag})" -ForegroundColor Green
            }
        }
    }

    return $tasks
}

# Exécuter la fonction d'extraction des tags de durée avec formats composés
Write-Host "Test d'extraction des tags de durée avec formats composés..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$durationCompositeTags = Get-DurationCompositeTags -Content $testContent

# Afficher les résultats
Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de durée composés jours/heures: $(($durationCompositeTags.Values | Where-Object { $_.DurationTags.DaysHours.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de durée composés heures/minutes: $(($durationCompositeTags.Values | Where-Object { $_.DurationTags.HoursMinutes.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches sans tags de durée: $(9 - $durationCompositeTags.Count)" -ForegroundColor Yellow

Write-Host "`nTest terminé." -ForegroundColor Cyan
