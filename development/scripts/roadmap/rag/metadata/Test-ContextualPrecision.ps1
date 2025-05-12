# Test-ContextualPrecision.ps1
# Script pour tester l'extraction des nombres avec précision contextuelle
# Version: 1.0
# Date: 2025-05-15

# Créer un contenu de test avec différentes valeurs numériques à précision contextuelle
$testContent = @"
# Test de l'extraction des nombres avec précision contextuelle

## Valeurs de prix
- [ ] **1.1** Tâche avec prix en euros 10.50€
- [ ] **1.2** Tâche avec prix en dollars 15.75$
- [ ] **1.3** Tâche avec prix en euros avec code 20.99 EUR
- [ ] **1.4** Tâche avec prix en dollars avec code 25.49 USD

## Valeurs de pourcentage
- [ ] **2.1** Tâche avec pourcentage simple 75%
- [ ] **2.2** Tâche avec pourcentage décimal 33.33%
- [ ] **2.3** Tâche avec pourcentage et espace 50 %

## Valeurs de mesure
- [ ] **3.1** Tâche avec mesure en mètres 1.85m
- [ ] **3.2** Tâche avec mesure en kilomètres 5.5km
- [ ] **3.3** Tâche avec mesure en centimètres 175.5cm
- [ ] **3.4** Tâche avec mesure en millimètres 250.75mm

## Valeurs de temps
- [ ] **4.1** Tâche avec temps en heures 2.5h
- [ ] **4.2** Tâche avec temps en minutes 45.5min
- [ ] **4.3** Tâche avec temps en secondes 30.25s
- [ ] **4.4** Tâche avec temps en millisecondes 500.75ms

## Valeurs de poids
- [ ] **5.1** Tâche avec poids en kilogrammes 75.5kg
- [ ] **5.2** Tâche avec poids en grammes 500.25g
- [ ] **5.3** Tâche avec poids en milligrammes 250.5mg

## Valeurs de température
- [ ] **6.1** Tâche avec température en Celsius 25.5°C
- [ ] **6.2** Tâche avec température en Fahrenheit 98.6°F
"@

# Fonction pour extraire les nombres avec précision contextuelle
function Get-ContextualPrecision {
    param (
        [string]$Content
    )
    
    Write-Host "Extraction des nombres avec précision contextuelle..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Patterns pour les contextes de précision
    $pricePattern = '(\d+(?:[.,]\d+)?)\s*(€|\$|EUR|USD)'
    $percentagePattern = '(\d+(?:[.,]\d+)?)\s*%'
    $measurementPattern = '(\d+(?:[.,]\d+)?)\s*(m|km|cm|mm)'
    $timePattern = '(\d+(?:[.,]\d+)?)\s*(h|min|s|ms)'
    $weightPattern = '(\d+(?:[.,]\d+)?)\s*(kg|g|mg)'
    $temperaturePattern = '(\d+(?:[.,]\d+)?)\s*(°C|°F)'
    
    # Analyser chaque ligne
    foreach ($line in $lines) {
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Initialiser la tâche si elle n'existe pas déjà
            if (-not $tasks.ContainsKey($taskId)) {
                $tasks[$taskId] = @{
                    Id = $taskId
                    ContextualPrecisionValues = @{
                        Price = @()
                        Percentage = @()
                        Measurement = @()
                        Time = @()
                        Weight = @()
                        Temperature = @()
                    }
                }
            }
            
            # Extraire les valeurs de prix
            $matches = [regex]::Matches($taskLine, $pricePattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $unit = $match.Groups[2].Value
                $normalizedValue = $numberValue -replace ',', '.'
                $precision = 0
                
                if ($normalizedValue -match '\.(\d+)') {
                    $precision = $matches[1].Length
                }
                
                $tasks[$taskId].ContextualPrecisionValues.Price += @{
                    Value = $normalizedValue
                    Unit = $unit
                    Original = "$numberValue$unit"
                    Precision = $precision
                }
                
                Write-Host "Tache ${taskId}: Prix ${normalizedValue} ${unit} (précision: ${precision})" -ForegroundColor Green
            }
            
            # Extraire les valeurs de pourcentage
            $matches = [regex]::Matches($taskLine, $percentagePattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $unit = "%"
                $normalizedValue = $numberValue -replace ',', '.'
                $precision = 0
                
                if ($normalizedValue -match '\.(\d+)') {
                    $precision = $matches[1].Length
                }
                
                $tasks[$taskId].ContextualPrecisionValues.Percentage += @{
                    Value = $normalizedValue
                    Unit = $unit
                    Original = "$numberValue$unit"
                    Precision = $precision
                }
                
                Write-Host "Tache ${taskId}: Pourcentage ${normalizedValue} ${unit} (précision: ${precision})" -ForegroundColor Green
            }
            
            # Extraire les valeurs de mesure
            $matches = [regex]::Matches($taskLine, $measurementPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $unit = $match.Groups[2].Value
                $normalizedValue = $numberValue -replace ',', '.'
                $precision = 0
                
                if ($normalizedValue -match '\.(\d+)') {
                    $precision = $matches[1].Length
                }
                
                $tasks[$taskId].ContextualPrecisionValues.Measurement += @{
                    Value = $normalizedValue
                    Unit = $unit
                    Original = "$numberValue$unit"
                    Precision = $precision
                }
                
                Write-Host "Tache ${taskId}: Mesure ${normalizedValue} ${unit} (précision: ${precision})" -ForegroundColor Green
            }
            
            # Extraire les valeurs de temps
            $matches = [regex]::Matches($taskLine, $timePattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $unit = $match.Groups[2].Value
                $normalizedValue = $numberValue -replace ',', '.'
                $precision = 0
                
                if ($normalizedValue -match '\.(\d+)') {
                    $precision = $matches[1].Length
                }
                
                $tasks[$taskId].ContextualPrecisionValues.Time += @{
                    Value = $normalizedValue
                    Unit = $unit
                    Original = "$numberValue$unit"
                    Precision = $precision
                }
                
                Write-Host "Tache ${taskId}: Temps ${normalizedValue} ${unit} (précision: ${precision})" -ForegroundColor Green
            }
            
            # Extraire les valeurs de poids
            $matches = [regex]::Matches($taskLine, $weightPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $unit = $match.Groups[2].Value
                $normalizedValue = $numberValue -replace ',', '.'
                $precision = 0
                
                if ($normalizedValue -match '\.(\d+)') {
                    $precision = $matches[1].Length
                }
                
                $tasks[$taskId].ContextualPrecisionValues.Weight += @{
                    Value = $normalizedValue
                    Unit = $unit
                    Original = "$numberValue$unit"
                    Precision = $precision
                }
                
                Write-Host "Tache ${taskId}: Poids ${normalizedValue} ${unit} (précision: ${precision})" -ForegroundColor Green
            }
            
            # Extraire les valeurs de température
            $matches = [regex]::Matches($taskLine, $temperaturePattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $unit = $match.Groups[2].Value
                $normalizedValue = $numberValue -replace ',', '.'
                $precision = 0
                
                if ($normalizedValue -match '\.(\d+)') {
                    $precision = $matches[1].Length
                }
                
                $tasks[$taskId].ContextualPrecisionValues.Temperature += @{
                    Value = $normalizedValue
                    Unit = $unit
                    Original = "$numberValue$unit"
                    Precision = $precision
                }
                
                Write-Host "Tache ${taskId}: Température ${normalizedValue} ${unit} (précision: ${precision})" -ForegroundColor Green
            }
        }
    }
    
    return $tasks
}

# Exécuter la fonction d'extraction des nombres avec précision contextuelle
Write-Host "Test d'extraction des nombres avec précision contextuelle..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$contextualPrecision = Get-ContextualPrecision -Content $testContent

# Afficher les résultats
Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
Write-Host "- Tâches avec valeurs de prix: $(($contextualPrecision.Values | Where-Object { $_.ContextualPrecisionValues.Price.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec valeurs de pourcentage: $(($contextualPrecision.Values | Where-Object { $_.ContextualPrecisionValues.Percentage.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec valeurs de mesure: $(($contextualPrecision.Values | Where-Object { $_.ContextualPrecisionValues.Measurement.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec valeurs de temps: $(($contextualPrecision.Values | Where-Object { $_.ContextualPrecisionValues.Time.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec valeurs de poids: $(($contextualPrecision.Values | Where-Object { $_.ContextualPrecisionValues.Weight.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec valeurs de température: $(($contextualPrecision.Values | Where-Object { $_.ContextualPrecisionValues.Temperature.Count -gt 0 }).Count)" -ForegroundColor Yellow

Write-Host "`nTest terminé." -ForegroundColor Cyan
