# Simple-Duration-Test.ps1
# Script de test simplifié pour l'extraction des durées
# Version: 1.0
# Date: 2025-05-15

# Créer un contenu de test avec différentes durées
$testContent = @"
# Test de l'extraction des durées

## Durées en jours/semaines/mois
- [ ] **1.1** Tâche avec durée en jours (durée: 5 jours)
- [ ] **1.2** Tâche avec durée en semaines (durée: 2 semaines)

## Durées en heures/minutes
- [ ] **2.1** Tâche avec durée en heures (durée: 8 heures)
- [ ] **2.2** Tâche avec durée en minutes (durée: 45 minutes)

## Durées composées
- [ ] **3.1** Tâche avec durée composée jours/heures (durée: 2 jours 4 heures)
- [ ] **3.2** Tâche avec durée composée heures/minutes (durée: 3 heures 30 minutes)
"@

# Fonction pour extraire les durées en jours/semaines/mois
function Get-DayWeekMonthDurations {
    param (
        [string]$Content
    )

    Write-Host "Extraction des durées en jours/semaines/mois..." -ForegroundColor Cyan

    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"

    # Initialiser les variables d'analyse
    $tasks = @{}

    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'

    # Patterns pour les durées en jours/semaines/mois
    $durationPattern = '(?:durée|duration|temps):\s*(\d+(?:\.\d+)?)\s*(jour|jours|semaine|semaines|mois|an|ans|année|années)'

    # Analyser chaque ligne
    foreach ($line in $lines) {
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line

            # Extraire les durées en jours/semaines/mois
            if ($taskLine -match $durationPattern) {
                $durationValue = $matches[1]
                $durationUnit = $matches[2]

                # Normaliser les unités
                $normalizedUnit = switch -Regex ($durationUnit) {
                    '^jour(s)?$' { "jours" }
                    '^semaine(s)?$' { "semaines" }
                    '^mois$' { "mois" }
                    '^an(s|née|nées)?$' { "années" }
                    default { $durationUnit }
                }

                $tasks[$taskId] = @{
                    Id       = $taskId
                    Duration = @{
                        Value    = $durationValue
                        Unit     = $normalizedUnit
                        Original = "$durationValue $durationUnit"
                    }
                }

                Write-Host "Tache ${taskId}: ${durationValue} ${normalizedUnit}" -ForegroundColor Green
            }
        }
    }

    return $tasks
}

# Fonction pour extraire les durées en heures/minutes
function Get-HourMinuteDurations {
    param (
        [string]$Content
    )

    Write-Host "Extraction des durées en heures/minutes..." -ForegroundColor Cyan

    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"

    # Initialiser les variables d'analyse
    $tasks = @{}

    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'

    # Patterns pour les durées en heures/minutes
    $durationPattern = '(?:durée|duration|temps):\s*(\d+(?:\.\d+)?)\s*(heure|heures|minute|minutes|h|min)'

    # Analyser chaque ligne
    foreach ($line in $lines) {
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line

            # Extraire les durées en heures/minutes
            if ($taskLine -match $durationPattern) {
                $durationValue = $matches[1]
                $durationUnit = $matches[2]

                # Normaliser les unités
                $normalizedUnit = switch -Regex ($durationUnit) {
                    '^h(eure|eures)?$' { "heures" }
                    '^min(ute|utes)?$' { "minutes" }
                    default { $durationUnit }
                }

                $tasks[$taskId] = @{
                    Id       = $taskId
                    Duration = @{
                        Value    = $durationValue
                        Unit     = $normalizedUnit
                        Original = "$durationValue $durationUnit"
                    }
                }

                Write-Host "Tache ${taskId}: ${durationValue} ${normalizedUnit}" -ForegroundColor Green
            }
        }
    }

    return $tasks
}

# Fonction pour extraire les durées composées
function Get-CompositeDurations {
    param (
        [string]$Content
    )

    Write-Host "Extraction des durées composées..." -ForegroundColor Cyan

    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"

    # Initialiser les variables d'analyse
    $tasks = @{}

    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'

    # Patterns pour les durées composées
    $durationPattern1 = '(?:durée|duration|temps):\s*(\d+(?:\.\d+)?)\s*(jour|jours|j)\s+(?:et)?\s*(\d+(?:\.\d+)?)\s*(heure|heures|h)'
    $durationPattern2 = '(?:durée|duration|temps):\s*(\d+(?:\.\d+)?)\s*(heure|heures|h)\s+(?:et)?\s*(\d+(?:\.\d+)?)\s*(minute|minutes|min)'

    # Analyser chaque ligne
    foreach ($line in $lines) {
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line

            # Extraire les durées composées jours/heures
            if ($taskLine -match $durationPattern1) {
                $durationValue1 = $matches[1]
                $durationUnit1 = $matches[2]
                $durationValue2 = $matches[3]
                $durationUnit2 = $matches[4]

                # Normaliser les unités
                $normalizedUnit1 = switch -Regex ($durationUnit1) {
                    '^j(our|ours)?$' { "jours" }
                    default { $durationUnit1 }
                }

                $normalizedUnit2 = switch -Regex ($durationUnit2) {
                    '^h(eure|eures)?$' { "heures" }
                    default { $durationUnit2 }
                }

                $tasks[$taskId] = @{
                    Id       = $taskId
                    Duration = @{
                        Value1   = $durationValue1
                        Unit1    = $normalizedUnit1
                        Value2   = $durationValue2
                        Unit2    = $normalizedUnit2
                        Original = "$durationValue1 $durationUnit1 $durationValue2 $durationUnit2"
                    }
                }

                Write-Host "Tache ${taskId}: ${durationValue1} ${normalizedUnit1} et ${durationValue2} ${normalizedUnit2}" -ForegroundColor Green
            }
            # Extraire les durées composées heures/minutes
            elseif ($taskLine -match $durationPattern2) {
                $durationValue1 = $matches[1]
                $durationUnit1 = $matches[2]
                $durationValue2 = $matches[3]
                $durationUnit2 = $matches[4]

                # Normaliser les unités
                $normalizedUnit1 = switch -Regex ($durationUnit1) {
                    '^h(eure|eures)?$' { "heures" }
                    default { $durationUnit1 }
                }

                $normalizedUnit2 = switch -Regex ($durationUnit2) {
                    '^min(ute|utes)?$' { "minutes" }
                    default { $durationUnit2 }
                }

                $tasks[$taskId] = @{
                    Id       = $taskId
                    Duration = @{
                        Value1   = $durationValue1
                        Unit1    = $normalizedUnit1
                        Value2   = $durationValue2
                        Unit2    = $normalizedUnit2
                        Original = "$durationValue1 $durationUnit1 $durationValue2 $durationUnit2"
                    }
                }

                Write-Host "Tache ${taskId}: ${durationValue1} ${normalizedUnit1} et ${durationValue2} ${normalizedUnit2}" -ForegroundColor Green
            }
        }
    }

    return $tasks
}

# Exécuter les fonctions d'extraction
Write-Host "Test d'extraction des durées..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$dayWeekMonthDurations = Get-DayWeekMonthDurations -Content $testContent
$hourMinuteDurations = Get-HourMinuteDurations -Content $testContent
$compositeDurations = Get-CompositeDurations -Content $testContent

# Afficher les résultats
Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
Write-Host "- Tâches avec durées en jours/semaines/mois: $($dayWeekMonthDurations.Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec durées en heures/minutes: $($hourMinuteDurations.Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec durées composées: $($compositeDurations.Count)" -ForegroundColor Yellow

Write-Host "`nTest terminé." -ForegroundColor Cyan
