# Test-TempsCompositeTags.ps1
# Script pour tester l'extraction des tags de type #temps avec formats composés
# Version: 1.0
# Date: 2025-05-15

# Créer un contenu de test avec différents tags de type #temps composés
$testContent = @"
# Test de l'extraction des tags de type #temps avec formats composés

## Tags de temps composés jours/heures
- [ ] **1.1** Tâche avec tag de temps jours/heures #temps:2j4h
- [ ] **1.2** Tâche avec tag de temps jours/heures avec décimales #temps:1.5j3h
- [ ] **1.3** Tâche avec tag de temps jours/heures et séparateur #temps:2j-4h
- [ ] **1.4** Tâche avec tag de temps jours/heures et séparateur #temps:2j_4h

## Tags de temps composés heures/minutes
- [ ] **2.1** Tâche avec tag de temps heures/minutes #temps:3h30m
- [ ] **2.2** Tâche avec tag de temps heures/minutes avec décimales #temps:2.5h45m
- [ ] **2.3** Tâche avec tag de temps heures/minutes et séparateur #temps:3h-30m
- [ ] **2.4** Tâche avec tag de temps heures/minutes et séparateur #temps:3h_30m

## Tâches sans tags de temps
- [ ] **5.1** Tâche sans tag de temps
"@

# Fonction pour extraire les tags de type #temps avec formats composés
function Get-TempsCompositeTags {
    param (
        [string]$Content
    )
    
    Write-Host "Extraction des tags de type #temps avec formats composés..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Patterns pour les tags de type #temps avec formats composés
    # Format jours/heures: #temps:XjYh ou #temps:Xj-Yh ou #temps:Xj_Yh
    $tempsDaysHoursPattern = '#temps:(\d+(?:\.\d+)?)j[-_]?(\d+(?:\.\d+)?)h\b'
    
    # Format heures/minutes: #temps:XhYm ou #temps:Xh-Ym ou #temps:Xh_Ym
    $tempsHoursMinutesPattern = '#temps:(\d+(?:\.\d+)?)h[-_]?(\d+(?:\.\d+)?)m\b'
    
    # Analyser chaque ligne
    foreach ($line in $lines) {
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Initialiser la tâche si elle n'existe pas déjà
            if (-not $tasks.ContainsKey($taskId)) {
                $tasks[$taskId] = @{
                    Id = $taskId
                    TempsTags = @{
                        DaysHours = @()
                        HoursMinutes = @()
                    }
                }
            }
            
            # Extraire les tags de temps composés jours/heures
            if ($taskLine -match $tempsDaysHoursPattern) {
                $tempsDays = $matches[1]
                $tempsHours = $matches[2]
                
                $originalTag = if ($taskLine -match '#temps:\d+(?:\.\d+)?j[-_]?\d+(?:\.\d+)?h\b') { $matches[0] } else { "#temps:${tempsDays}j${tempsHours}h" }
                
                $tasks[$taskId].TempsTags.DaysHours += @{
                    Days = $tempsDays
                    Hours = $tempsHours
                    Original = $originalTag
                }
                
                Write-Host "Tache ${taskId}: ${tempsDays} jours ${tempsHours} heures (${originalTag})" -ForegroundColor Green
            }
            
            # Extraire les tags de temps composés heures/minutes
            if ($taskLine -match $tempsHoursMinutesPattern) {
                $tempsHours = $matches[1]
                $tempsMinutes = $matches[2]
                
                $originalTag = if ($taskLine -match '#temps:\d+(?:\.\d+)?h[-_]?\d+(?:\.\d+)?m\b') { $matches[0] } else { "#temps:${tempsHours}h${tempsMinutes}m" }
                
                $tasks[$taskId].TempsTags.HoursMinutes += @{
                    Hours = $tempsHours
                    Minutes = $tempsMinutes
                    Original = $originalTag
                }
                
                Write-Host "Tache ${taskId}: ${tempsHours} heures ${tempsMinutes} minutes (${originalTag})" -ForegroundColor Green
            }
        }
    }
    
    return $tasks
}

# Exécuter la fonction d'extraction des tags de temps avec formats composés
Write-Host "Test d'extraction des tags de type #temps avec formats composés..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$tempsCompositeTags = Get-TempsCompositeTags -Content $testContent

# Afficher les résultats
Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de temps composés jours/heures: $(($tempsCompositeTags.Values | Where-Object { $_.TempsTags.DaysHours.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de temps composés heures/minutes: $(($tempsCompositeTags.Values | Where-Object { $_.TempsTags.HoursMinutes.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches sans tags de temps: $(9 - $tempsCompositeTags.Count)" -ForegroundColor Yellow

Write-Host "`nTest terminé." -ForegroundColor Cyan
