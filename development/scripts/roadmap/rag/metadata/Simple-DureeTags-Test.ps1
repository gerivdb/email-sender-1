# Simple-DureeTags-Test.ps1
# Script de test simplifié pour l'extraction des tags de type #durée
# Version: 1.0
# Date: 2025-05-15

# Créer un contenu de test avec différents tags de type #durée
$testContent = @"
# Test de l'extraction des tags de type #durée

## Tags de durée en jours
- [ ] **1.1** Tâche avec tag de durée en jours #durée:5j
- [ ] **1.2** Tâche avec tag de durée en jours décimaux #durée:2.5j

## Tags de durée en semaines
- [ ] **2.1** Tâche avec tag de durée en semaines #durée:2s
- [ ] **2.2** Tâche avec tag de durée en semaines décimales #durée:1.5s

## Tags de durée en mois
- [ ] **3.1** Tâche avec tag de durée en mois #durée:1m
- [ ] **3.2** Tâche avec tag de durée en mois décimaux #durée:1.5m

## Tâches sans tags de durée
- [ ] **5.1** Tâche sans tag de durée
"@

# Fonction pour extraire les tags de type #durée
function Get-DureeTags {
    param (
        [string]$Content
    )
    
    Write-Host "Extraction des tags de type #durée..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Patterns pour les tags de type #durée
    $dureeDaysPattern = '#durée:(\d+(?:\.\d+)?)j\b'
    $dureeWeeksPattern = '#durée:(\d+(?:\.\d+)?)s\b'
    $dureeMonthsPattern = '#durée:(\d+(?:\.\d+)?)m\b'
    
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
            
            # Extraire les tags de durée en jours
            if ($taskLine -match $dureeDaysPattern) {
                $dureeValue = $matches[1]
                
                $tasks[$taskId].DureeTags.Days += @{
                    Value = $dureeValue
                    Unit = "jours"
                    Original = "#durée:${dureeValue}j"
                }
                
                Write-Host "Tache ${taskId}: ${dureeValue} jours (#durée:${dureeValue}j)" -ForegroundColor Green
            }
            
            # Extraire les tags de durée en semaines
            if ($taskLine -match $dureeWeeksPattern) {
                $dureeValue = $matches[1]
                
                $tasks[$taskId].DureeTags.Weeks += @{
                    Value = $dureeValue
                    Unit = "semaines"
                    Original = "#durée:${dureeValue}s"
                }
                
                Write-Host "Tache ${taskId}: ${dureeValue} semaines (#durée:${dureeValue}s)" -ForegroundColor Green
            }
            
            # Extraire les tags de durée en mois
            if ($taskLine -match $dureeMonthsPattern) {
                $dureeValue = $matches[1]
                
                $tasks[$taskId].DureeTags.Months += @{
                    Value = $dureeValue
                    Unit = "mois"
                    Original = "#durée:${dureeValue}m"
                }
                
                Write-Host "Tache ${taskId}: ${dureeValue} mois (#durée:${dureeValue}m)" -ForegroundColor Green
            }
        }
    }
    
    return $tasks
}

# Exécuter la fonction d'extraction des tags de durée
Write-Host "Test d'extraction des tags de type #durée..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$dureeTags = Get-DureeTags -Content $testContent

# Afficher les résultats
Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de durée en jours: $(($dureeTags.Values | Where-Object { $_.DureeTags.Days.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de durée en semaines: $(($dureeTags.Values | Where-Object { $_.DureeTags.Weeks.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de durée en mois: $(($dureeTags.Values | Where-Object { $_.DureeTags.Months.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches sans tags de durée: $(7 - $dureeTags.Count)" -ForegroundColor Yellow

Write-Host "`nTest terminé." -ForegroundColor Cyan
