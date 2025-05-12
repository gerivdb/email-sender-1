# Test-DureeCompositeTags.ps1
# Script pour tester l'extraction des tags de type #durée avec formats composés
# Version: 1.0
# Date: 2025-05-15

# Créer un contenu de test avec différents tags de type #durée composés
$testContent = @"
# Test de l'extraction des tags de type #durée avec formats composés

## Tags de durée composés jours/heures
- [ ] **1.1** Tâche avec tag de durée jours/heures #durée:2j4h
- [ ] **1.2** Tâche avec tag de durée jours/heures avec décimales #durée:1.5j3h
- [ ] **1.3** Tâche avec tag de durée jours/heures et séparateur #durée:2j-4h
- [ ] **1.4** Tâche avec tag de durée jours/heures et séparateur #durée:2j_4h

## Tags de durée composés heures/minutes
- [ ] **2.1** Tâche avec tag de durée heures/minutes #durée:3h30m
- [ ] **2.2** Tâche avec tag de durée heures/minutes avec décimales #durée:2.5h45m
- [ ] **2.3** Tâche avec tag de durée heures/minutes et séparateur #durée:3h-30m
- [ ] **2.4** Tâche avec tag de durée heures/minutes et séparateur #durée:3h_30m

## Tâches sans tags de durée
- [ ] **5.1** Tâche sans tag de durée
"@

# Fonction pour extraire les tags de type #durée avec formats composés
function Get-DureeCompositeTags {
    param (
        [string]$Content
    )
    
    Write-Host "Extraction des tags de type #durée avec formats composés..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Patterns pour les tags de type #durée avec formats composés
    # Format jours/heures: #durée:XjYh ou #durée:Xj-Yh ou #durée:Xj_Yh
    $dureeDaysHoursPattern = '#durée:(\d+(?:\.\d+)?)j[-_]?(\d+(?:\.\d+)?)h\b'
    
    # Format heures/minutes: #durée:XhYm ou #durée:Xh-Ym ou #durée:Xh_Ym
    $dureeHoursMinutesPattern = '#durée:(\d+(?:\.\d+)?)h[-_]?(\d+(?:\.\d+)?)m\b'
    
    # Analyser chaque ligne
    foreach ($line in $lines) {
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Initialiser la tâche si elle n'existe pas déjà
            if (-not $tasks.ContainsKey($taskId)) {
                $tasks[$taskId] = @{
                    Id = $taskId
                    DureeTags = @{
                        DaysHours = @()
                        HoursMinutes = @()
                    }
                }
            }
            
            # Extraire les tags de durée composés jours/heures
            if ($taskLine -match $dureeDaysHoursPattern) {
                $dureeDays = $matches[1]
                $dureeHours = $matches[2]
                
                $originalTag = if ($taskLine -match '#durée:\d+(?:\.\d+)?j[-_]?\d+(?:\.\d+)?h\b') { $matches[0] } else { "#durée:${dureeDays}j${dureeHours}h" }
                
                $tasks[$taskId].DureeTags.DaysHours += @{
                    Days = $dureeDays
                    Hours = $dureeHours
                    Original = $originalTag
                }
                
                Write-Host "Tache ${taskId}: ${dureeDays} jours ${dureeHours} heures (${originalTag})" -ForegroundColor Green
            }
            
            # Extraire les tags de durée composés heures/minutes
            if ($taskLine -match $dureeHoursMinutesPattern) {
                $dureeHours = $matches[1]
                $dureeMinutes = $matches[2]
                
                $originalTag = if ($taskLine -match '#durée:\d+(?:\.\d+)?h[-_]?\d+(?:\.\d+)?m\b') { $matches[0] } else { "#durée:${dureeHours}h${dureeMinutes}m" }
                
                $tasks[$taskId].DureeTags.HoursMinutes += @{
                    Hours = $dureeHours
                    Minutes = $dureeMinutes
                    Original = $originalTag
                }
                
                Write-Host "Tache ${taskId}: ${dureeHours} heures ${dureeMinutes} minutes (${originalTag})" -ForegroundColor Green
            }
        }
    }
    
    return $tasks
}

# Exécuter la fonction d'extraction des tags de durée avec formats composés
Write-Host "Test d'extraction des tags de type #durée avec formats composés..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$dureeCompositeTags = Get-DureeCompositeTags -Content $testContent

# Afficher les résultats
Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de durée composés jours/heures: $(($dureeCompositeTags.Values | Where-Object { $_.DureeTags.DaysHours.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de durée composés heures/minutes: $(($dureeCompositeTags.Values | Where-Object { $_.DureeTags.HoursMinutes.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches sans tags de durée: $(9 - $dureeCompositeTags.Count)" -ForegroundColor Yellow

Write-Host "`nTest terminé." -ForegroundColor Cyan
