# Test-DureeParenTags.ps1
# Script pour tester l'extraction des tags de type #durée avec format parenthèses
# Version: 1.0
# Date: 2025-05-15

# Créer un contenu de test avec différents tags de type #durée avec format parenthèses
$testContent = @"
# Test de l'extraction des tags de type #durée avec format parenthèses

## Tags de durée en jours (format parenthèses)
- [ ] **1.1** Tâche avec tag de durée en jours #durée(5j)
- [ ] **1.2** Tâche avec tag de durée en jours décimaux #durée(2.5j)
- [ ] **1.3** Tâche avec tag de durée en jours et autre texte #durée(7j) (estimation)
- [ ] **1.4** Tâche avec plusieurs tags de durée en jours #durée(3j) #durée(4j)

## Tags de durée en semaines (format parenthèses)
- [ ] **2.1** Tâche avec tag de durée en semaines #durée(2s)
- [ ] **2.2** Tâche avec tag de durée en semaines décimales #durée(1.5s)
- [ ] **2.3** Tâche avec tag de durée en semaines et autre texte #durée(3s) (estimation)
- [ ] **2.4** Tâche avec plusieurs tags de durée en semaines #durée(1s) #durée(2s)

## Tags de durée en mois (format parenthèses)
- [ ] **3.1** Tâche avec tag de durée en mois #durée(1m)
- [ ] **3.2** Tâche avec tag de durée en mois décimaux #durée(1.5m)
- [ ] **3.3** Tâche avec tag de durée en mois et autre texte #durée(2m) (estimation)
- [ ] **3.4** Tâche avec plusieurs tags de durée en mois #durée(1m) #durée(3m)

## Tâches sans tags de durée
- [ ] **5.1** Tâche sans tag de durée
- [ ] **5.2** Tâche avec texte mentionnant durée mais sans tag
"@

# Fonction pour extraire les tags de type #durée avec format parenthèses
function Get-DureeParenTags {
    param (
        [string]$Content
    )
    
    Write-Host "Extraction des tags de type #durée avec format parenthèses..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Patterns pour les tags de type #durée avec format parenthèses
    $dureeParenDaysPattern = '#durée\((\d+(?:\.\d+)?)j\)'
    $dureeParenWeeksPattern = '#durée\((\d+(?:\.\d+)?)s\)'
    $dureeParenMonthsPattern = '#durée\((\d+(?:\.\d+)?)m\)'
    
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
                        Days = @()
                        Weeks = @()
                        Months = @()
                    }
                }
            }
            
            # Extraire les tags de durée en jours (format parenthèses)
            if ($taskLine -match $dureeParenDaysPattern) {
                $dureeValue = $matches[1]
                
                $tasks[$taskId].DureeTags.Days += @{
                    Value = $dureeValue
                    Unit = "jours"
                    Original = "#durée(${dureeValue}j)"
                }
                
                Write-Host "Tache ${taskId}: ${dureeValue} jours (#durée(${dureeValue}j))" -ForegroundColor Green
            }
            
            # Extraire les tags de durée en semaines (format parenthèses)
            if ($taskLine -match $dureeParenWeeksPattern) {
                $dureeValue = $matches[1]
                
                $tasks[$taskId].DureeTags.Weeks += @{
                    Value = $dureeValue
                    Unit = "semaines"
                    Original = "#durée(${dureeValue}s)"
                }
                
                Write-Host "Tache ${taskId}: ${dureeValue} semaines (#durée(${dureeValue}s))" -ForegroundColor Green
            }
            
            # Extraire les tags de durée en mois (format parenthèses)
            if ($taskLine -match $dureeParenMonthsPattern) {
                $dureeValue = $matches[1]
                
                $tasks[$taskId].DureeTags.Months += @{
                    Value = $dureeValue
                    Unit = "mois"
                    Original = "#durée(${dureeValue}m)"
                }
                
                Write-Host "Tache ${taskId}: ${dureeValue} mois (#durée(${dureeValue}m))" -ForegroundColor Green
            }
        }
    }
    
    return $tasks
}

# Exécuter la fonction d'extraction des tags de durée avec format parenthèses
Write-Host "Test d'extraction des tags de type #durée avec format parenthèses..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$dureeParenTags = Get-DureeParenTags -Content $testContent

# Afficher les résultats
Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de durée en jours (format parenthèses): $(($dureeParenTags.Values | Where-Object { $_.DureeTags.Days.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de durée en semaines (format parenthèses): $(($dureeParenTags.Values | Where-Object { $_.DureeTags.Weeks.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de durée en mois (format parenthèses): $(($dureeParenTags.Values | Where-Object { $_.DureeTags.Months.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches sans tags de durée: $(14 - $dureeParenTags.Count)" -ForegroundColor Yellow

Write-Host "`nTest terminé." -ForegroundColor Cyan
