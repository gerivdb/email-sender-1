# Test-TempsTags.ps1
# Script pour tester l'extraction des tags de type #temps
# Version: 1.0
# Date: 2025-05-15

# Créer un contenu de test avec différents tags de type #temps
$testContent = @"
# Test de l'extraction des tags de type #temps

## Tags de temps en jours
- [ ] **1.1** Tâche avec tag de temps en jours #temps:5j
- [ ] **1.2** Tâche avec tag de temps en jours décimaux #temps:2.5j
- [ ] **1.3** Tâche avec tag de temps en jours et autre texte #temps:7j (estimation)
- [ ] **1.4** Tâche avec plusieurs tags de temps en jours #temps:3j #temps:4j

## Tags de temps en semaines
- [ ] **2.1** Tâche avec tag de temps en semaines #temps:2s
- [ ] **2.2** Tâche avec tag de temps en semaines décimales #temps:1.5s
- [ ] **2.3** Tâche avec tag de temps en semaines et autre texte #temps:3s (estimation)
- [ ] **2.4** Tâche avec plusieurs tags de temps en semaines #temps:1s #temps:2s

## Tags de temps en mois
- [ ] **3.1** Tâche avec tag de temps en mois #temps:1m
- [ ] **3.2** Tâche avec tag de temps en mois décimaux #temps:1.5m
- [ ] **3.3** Tâche avec tag de temps en mois et autre texte #temps:2m (estimation)
- [ ] **3.4** Tâche avec plusieurs tags de temps en mois #temps:1m #temps:3m

## Tags de temps avec format parenthèses
- [ ] **4.1** Tâche avec tag de temps en jours #temps(5j)
- [ ] **4.2** Tâche avec tag de temps en semaines #temps(2s)
- [ ] **4.3** Tâche avec tag de temps en mois #temps(1m)

## Tâches sans tags de temps
- [ ] **5.1** Tâche sans tag de temps
- [ ] **5.2** Tâche avec texte mentionnant temps mais sans tag
"@

# Fonction pour extraire les tags de type #temps
function Get-TempsTags {
    param (
        [string]$Content
    )
    
    Write-Host "Extraction des tags de type #temps..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Patterns pour les tags de type #temps
    $tempsDaysPattern = '#temps:(\d+(?:\.\d+)?)j\b'
    $tempsWeeksPattern = '#temps:(\d+(?:\.\d+)?)s\b'
    $tempsMonthsPattern = '#temps:(\d+(?:\.\d+)?)m\b'
    $tempsParenDaysPattern = '#temps\((\d+(?:\.\d+)?)j\)'
    $tempsParenWeeksPattern = '#temps\((\d+(?:\.\d+)?)s\)'
    $tempsParenMonthsPattern = '#temps\((\d+(?:\.\d+)?)m\)'
    
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
                        Days = @()
                        Weeks = @()
                        Months = @()
                    }
                }
            }
            
            # Extraire les tags de temps en jours
            if ($taskLine -match $tempsDaysPattern) {
                $tempsValue = $matches[1]
                
                $tasks[$taskId].TempsTags.Days += @{
                    Value = $tempsValue
                    Unit = "jours"
                    Original = "#temps:${tempsValue}j"
                }
                
                Write-Host "Tache ${taskId}: ${tempsValue} jours (#temps:${tempsValue}j)" -ForegroundColor Green
            }
            
            # Extraire les tags de temps en semaines
            if ($taskLine -match $tempsWeeksPattern) {
                $tempsValue = $matches[1]
                
                $tasks[$taskId].TempsTags.Weeks += @{
                    Value = $tempsValue
                    Unit = "semaines"
                    Original = "#temps:${tempsValue}s"
                }
                
                Write-Host "Tache ${taskId}: ${tempsValue} semaines (#temps:${tempsValue}s)" -ForegroundColor Green
            }
            
            # Extraire les tags de temps en mois
            if ($taskLine -match $tempsMonthsPattern) {
                $tempsValue = $matches[1]
                
                $tasks[$taskId].TempsTags.Months += @{
                    Value = $tempsValue
                    Unit = "mois"
                    Original = "#temps:${tempsValue}m"
                }
                
                Write-Host "Tache ${taskId}: ${tempsValue} mois (#temps:${tempsValue}m)" -ForegroundColor Green
            }
            
            # Extraire les tags de temps en jours (format parenthèses)
            if ($taskLine -match $tempsParenDaysPattern) {
                $tempsValue = $matches[1]
                
                $tasks[$taskId].TempsTags.Days += @{
                    Value = $tempsValue
                    Unit = "jours"
                    Original = "#temps(${tempsValue}j)"
                }
                
                Write-Host "Tache ${taskId}: ${tempsValue} jours (#temps(${tempsValue}j))" -ForegroundColor Green
            }
            
            # Extraire les tags de temps en semaines (format parenthèses)
            if ($taskLine -match $tempsParenWeeksPattern) {
                $tempsValue = $matches[1]
                
                $tasks[$taskId].TempsTags.Weeks += @{
                    Value = $tempsValue
                    Unit = "semaines"
                    Original = "#temps(${tempsValue}s)"
                }
                
                Write-Host "Tache ${taskId}: ${tempsValue} semaines (#temps(${tempsValue}s))" -ForegroundColor Green
            }
            
            # Extraire les tags de temps en mois (format parenthèses)
            if ($taskLine -match $tempsParenMonthsPattern) {
                $tempsValue = $matches[1]
                
                $tasks[$taskId].TempsTags.Months += @{
                    Value = $tempsValue
                    Unit = "mois"
                    Original = "#temps(${tempsValue}m)"
                }
                
                Write-Host "Tache ${taskId}: ${tempsValue} mois (#temps(${tempsValue}m))" -ForegroundColor Green
            }
        }
    }
    
    return $tasks
}

# Exécuter la fonction d'extraction des tags de temps
Write-Host "Test d'extraction des tags de type #temps..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$tempsTags = Get-TempsTags -Content $testContent

# Afficher les résultats
Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de temps en jours: $(($tempsTags.Values | Where-Object { $_.TempsTags.Days.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de temps en semaines: $(($tempsTags.Values | Where-Object { $_.TempsTags.Weeks.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de temps en mois: $(($tempsTags.Values | Where-Object { $_.TempsTags.Months.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches sans tags de temps: $(17 - $tempsTags.Count)" -ForegroundColor Yellow

Write-Host "`nTest terminé." -ForegroundColor Cyan
