# Test-PrecisionVariables.ps1
# Script pour tester l'extraction des nombres avec précisions variables
# Version: 1.0
# Date: 2025-05-15

# Créer un contenu de test avec différentes valeurs numériques à précisions variables
$testContent = @"
# Test de l'extraction des nombres avec précisions variables

## Nombres avec 1 décimale
- [ ] **1.1** Tâche avec nombre à 1 décimale (point) 3.5
- [ ] **1.2** Tâche avec nombre à 1 décimale (virgule) 3,5
- [ ] **1.3** Tâche avec nombre à 1 décimale dans un tag #duration:2.5d
- [ ] **1.4** Tâche avec nombre à 1 décimale dans un identifiant 1.4 (ne devrait pas être extrait)

## Nombres avec 2 décimales
- [ ] **2.1** Tâche avec nombre à 2 décimales (point) 3.14
- [ ] **2.2** Tâche avec nombre à 2 décimales (virgule) 3,14
- [ ] **2.3** Tâche avec nombre à 2 décimales dans un tag #duration:2.75d
- [ ] **2.4** Tâche avec nombre à 2 décimales dans un identifiant 2.45 (ne devrait pas être extrait)

## Nombres avec 3+ décimales
- [ ] **3.1** Tâche avec nombre à 3 décimales (point) 3.142
- [ ] **3.2** Tâche avec nombre à 4 décimales (point) 3.1416
- [ ] **3.3** Tâche avec nombre à 3 décimales (virgule) 3,142
- [ ] **3.4** Tâche avec nombre à 4 décimales (virgule) 3,1416
- [ ] **3.5** Tâche avec nombre à 3+ décimales dans un tag #duration:2.718d

## Tâches sans valeurs numériques à précisions variables
- [ ] **5.1** Tâche sans valeur numérique à précision variable
"@

# Fonction pour extraire les nombres avec précisions variables
function Get-PrecisionVariables {
    param (
        [string]$Content
    )
    
    Write-Host "Extraction des nombres avec précisions variables..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Patterns pour les nombres avec précisions variables
    $oneDecimalPattern = '(?<!\d)(\d+\.\d{1})(?!\d)'
    $oneDecimalCommaPattern = '(?<!\d)(\d+,\d{1})(?!\d)'
    $twoDecimalsPattern = '(?<!\d)(\d+\.\d{2})(?!\d)'
    $twoDecimalsCommaPattern = '(?<!\d)(\d+,\d{2})(?!\d)'
    $threePlusDecimalsPattern = '(?<!\d)(\d+\.\d{3,})(?!\d)'
    $threePlusDecimalsCommaPattern = '(?<!\d)(\d+,\d{3,})(?!\d)'
    
    # Analyser chaque ligne
    foreach ($line in $lines) {
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Initialiser la tâche si elle n'existe pas déjà
            if (-not $tasks.ContainsKey($taskId)) {
                $tasks[$taskId] = @{
                    Id = $taskId
                    PrecisionValues = @{
                        OneDecimal = @()
                        TwoDecimals = @()
                        ThreePlusDecimals = @()
                    }
                }
            }
            
            # Extraire les nombres avec 1 décimale (point)
            $matches = [regex]::Matches($taskLine, $oneDecimalPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                
                # Vérifier que ce n'est pas une partie d'un identifiant de tâche
                if ($taskId -ne $numberValue) {
                    $tasks[$taskId].PrecisionValues.OneDecimal += @{
                        Value = $numberValue
                        Original = $numberValue
                        Separator = "."
                        Precision = 1
                    }
                    
                    Write-Host "Tache ${taskId}: Nombre à 1 décimale ${numberValue} (précision: 1)" -ForegroundColor Green
                }
            }
            
            # Extraire les nombres avec 1 décimale (virgule)
            $matches = [regex]::Matches($taskLine, $oneDecimalCommaPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $normalizedValue = $numberValue -replace ',', '.'
                
                # Vérifier que ce n'est pas une partie d'un identifiant de tâche
                if ($taskId -ne $numberValue) {
                    $tasks[$taskId].PrecisionValues.OneDecimal += @{
                        Value = $normalizedValue
                        Original = $numberValue
                        Separator = ","
                        Precision = 1
                    }
                    
                    Write-Host "Tache ${taskId}: Nombre à 1 décimale ${numberValue} (normalisé: ${normalizedValue}, précision: 1)" -ForegroundColor Green
                }
            }
            
            # Extraire les nombres avec 2 décimales (point)
            $matches = [regex]::Matches($taskLine, $twoDecimalsPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                
                # Vérifier que ce n'est pas une partie d'un identifiant de tâche
                if ($taskId -ne $numberValue) {
                    $tasks[$taskId].PrecisionValues.TwoDecimals += @{
                        Value = $numberValue
                        Original = $numberValue
                        Separator = "."
                        Precision = 2
                    }
                    
                    Write-Host "Tache ${taskId}: Nombre à 2 décimales ${numberValue} (précision: 2)" -ForegroundColor Green
                }
            }
            
            # Extraire les nombres avec 2 décimales (virgule)
            $matches = [regex]::Matches($taskLine, $twoDecimalsCommaPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $normalizedValue = $numberValue -replace ',', '.'
                
                # Vérifier que ce n'est pas une partie d'un identifiant de tâche
                if ($taskId -ne $numberValue) {
                    $tasks[$taskId].PrecisionValues.TwoDecimals += @{
                        Value = $normalizedValue
                        Original = $numberValue
                        Separator = ","
                        Precision = 2
                    }
                    
                    Write-Host "Tache ${taskId}: Nombre à 2 décimales ${numberValue} (normalisé: ${normalizedValue}, précision: 2)" -ForegroundColor Green
                }
            }
            
            # Extraire les nombres avec 3+ décimales (point)
            $matches = [regex]::Matches($taskLine, $threePlusDecimalsPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $precision = ($numberValue -split '\.')[1].Length
                
                # Vérifier que ce n'est pas une partie d'un identifiant de tâche
                if ($taskId -ne $numberValue) {
                    $tasks[$taskId].PrecisionValues.ThreePlusDecimals += @{
                        Value = $numberValue
                        Original = $numberValue
                        Separator = "."
                        Precision = $precision
                    }
                    
                    Write-Host "Tache ${taskId}: Nombre à ${precision} décimales ${numberValue} (précision: ${precision})" -ForegroundColor Green
                }
            }
            
            # Extraire les nombres avec 3+ décimales (virgule)
            $matches = [regex]::Matches($taskLine, $threePlusDecimalsCommaPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $normalizedValue = $numberValue -replace ',', '.'
                $precision = ($normalizedValue -split '\.')[1].Length
                
                # Vérifier que ce n'est pas une partie d'un identifiant de tâche
                if ($taskId -ne $numberValue) {
                    $tasks[$taskId].PrecisionValues.ThreePlusDecimals += @{
                        Value = $normalizedValue
                        Original = $numberValue
                        Separator = ","
                        Precision = $precision
                    }
                    
                    Write-Host "Tache ${taskId}: Nombre à ${precision} décimales ${numberValue} (normalisé: ${normalizedValue}, précision: ${precision})" -ForegroundColor Green
                }
            }
        }
    }
    
    return $tasks
}

# Exécuter la fonction d'extraction des nombres avec précisions variables
Write-Host "Test d'extraction des nombres avec précisions variables..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$precisionVariables = Get-PrecisionVariables -Content $testContent

# Afficher les résultats
Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
Write-Host "- Tâches avec nombres à 1 décimale: $(($precisionVariables.Values | Where-Object { $_.PrecisionValues.OneDecimal.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec nombres à 2 décimales: $(($precisionVariables.Values | Where-Object { $_.PrecisionValues.TwoDecimals.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec nombres à 3+ décimales: $(($precisionVariables.Values | Where-Object { $_.PrecisionValues.ThreePlusDecimals.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches sans valeurs numériques à précisions variables: $(14 - $precisionVariables.Count)" -ForegroundColor Yellow

Write-Host "`nTest terminé." -ForegroundColor Cyan
