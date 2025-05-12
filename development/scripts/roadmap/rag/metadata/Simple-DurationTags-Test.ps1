# Simple-DurationTags-Test.ps1
# Script de test simplifié pour l'extraction des tags de durée
# Version: 1.0
# Date: 2025-05-15

# Créer un contenu de test avec différents tags de durée
$testContent = @"
# Test de l'extraction des tags de durée

## Tags de durée en jours
- [ ] **1.1** Tâche avec tag de durée en jours #duration:5d
- [ ] **1.2** Tâche avec tag de durée en jours décimaux #duration:2.5d

## Tags de durée en semaines
- [ ] **2.1** Tâche avec tag de durée en semaines #duration:2w
- [ ] **2.2** Tâche avec tag de durée en semaines décimales #duration:1.5w

## Tags de durée en mois
- [ ] **3.1** Tâche avec tag de durée en mois #duration:1m
- [ ] **3.2** Tâche avec tag de durée en mois décimaux #duration:1.5m

## Tâches sans tags de durée
- [ ] **5.1** Tâche sans tag de durée
"@

# Fonction pour extraire les tags de type #duration
function Get-DurationTags {
    param (
        [string]$Content
    )
    
    Write-Host "Extraction des tags de type #duration..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Patterns pour les tags de type #duration
    $durationDaysPattern = '#duration:(\d+(?:\.\d+)?)d\b'
    $durationWeeksPattern = '#duration:(\d+(?:\.\d+)?)w\b'
    $durationMonthsPattern = '#duration:(\d+(?:\.\d+)?)m\b'
    
    # Analyser chaque ligne
    foreach ($line in $lines) {
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Extraire les tags de durée en jours
            if ($taskLine -match $durationDaysPattern) {
                $durationValue = $matches[1]
                
                if (-not $tasks.ContainsKey($taskId)) {
                    $tasks[$taskId] = @{
                        Id = $taskId
                        DurationTags = @{
                            Days = @()
                            Weeks = @()
                            Months = @()
                        }
                    }
                }
                
                $tasks[$taskId].DurationTags.Days += @{
                    Value = $durationValue
                    Unit = "jours"
                    Original = "#duration:${durationValue}d"
                }
                
                Write-Host "Tache ${taskId}: ${durationValue} jours (#duration:${durationValue}d)" -ForegroundColor Green
            }
            
            # Extraire les tags de durée en semaines
            if ($taskLine -match $durationWeeksPattern) {
                $durationValue = $matches[1]
                
                if (-not $tasks.ContainsKey($taskId)) {
                    $tasks[$taskId] = @{
                        Id = $taskId
                        DurationTags = @{
                            Days = @()
                            Weeks = @()
                            Months = @()
                        }
                    }
                }
                
                $tasks[$taskId].DurationTags.Weeks += @{
                    Value = $durationValue
                    Unit = "semaines"
                    Original = "#duration:${durationValue}w"
                }
                
                Write-Host "Tache ${taskId}: ${durationValue} semaines (#duration:${durationValue}w)" -ForegroundColor Green
            }
            
            # Extraire les tags de durée en mois
            if ($taskLine -match $durationMonthsPattern) {
                $durationValue = $matches[1]
                
                if (-not $tasks.ContainsKey($taskId)) {
                    $tasks[$taskId] = @{
                        Id = $taskId
                        DurationTags = @{
                            Days = @()
                            Weeks = @()
                            Months = @()
                        }
                    }
                }
                
                $tasks[$taskId].DurationTags.Months += @{
                    Value = $durationValue
                    Unit = "mois"
                    Original = "#duration:${durationValue}m"
                }
                
                Write-Host "Tache ${taskId}: ${durationValue} mois (#duration:${durationValue}m)" -ForegroundColor Green
            }
        }
    }
    
    return $tasks
}

# Exécuter la fonction d'extraction des tags de durée
Write-Host "Test d'extraction des tags de durée..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$durationTags = Get-DurationTags -Content $testContent

# Afficher les résultats
Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de durée en jours: $(($durationTags.Values | Where-Object { $_.DurationTags.Days.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de durée en semaines: $(($durationTags.Values | Where-Object { $_.DurationTags.Weeks.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de durée en mois: $(($durationTags.Values | Where-Object { $_.DurationTags.Months.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches sans tags de durée: $(7 - $durationTags.Count)" -ForegroundColor Yellow

Write-Host "`nTest terminé." -ForegroundColor Cyan
