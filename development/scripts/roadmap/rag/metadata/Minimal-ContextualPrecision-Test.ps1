# Minimal-ContextualPrecision-Test.ps1
# Script de test minimal pour l'extraction des nombres avec précision contextuelle
# Version: 1.0
# Date: 2025-05-15

# Créer un contenu de test avec quelques valeurs numériques à précision contextuelle
$testContent = @"
# Test minimal de l'extraction des nombres avec précision contextuelle

## Valeurs de prix
- [ ] **1.1** Tache avec prix en dollars 15.75$
- [ ] **1.2** Tache avec prix en euros 10.50 EUR

## Valeurs de pourcentage
- [ ] **2.1** Tache avec pourcentage simple 75%
- [ ] **2.2** Tache avec pourcentage decimal 33.33%

## Valeurs de mesure
- [ ] **3.1** Tache avec mesure en metres 1.85m
- [ ] **3.2** Tache avec mesure en kilometres 5.5km
"@

# Fonction pour extraire les nombres avec précision contextuelle
function Get-ContextualPrecision {
    param (
        [string]$Content
    )
    
    Write-Host "Extraction des nombres avec precision contextuelle..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Patterns pour les contextes de précision
    $pricePattern = '(\d+(?:[.,]\d+)?)\s*(\$|EUR)'
    $percentagePattern = '(\d+(?:[.,]\d+)?)\s*%'
    $measurementPattern = '(\d+(?:[.,]\d+)?)\s*(m|km)'
    
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
                    Original = "$numberValue $unit"
                    Precision = $precision
                }
                
                Write-Host "Tache ${taskId}: Prix ${normalizedValue} ${unit} (precision: ${precision})" -ForegroundColor Green
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
                
                Write-Host "Tache ${taskId}: Pourcentage ${normalizedValue} ${unit} (precision: ${precision})" -ForegroundColor Green
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
                
                Write-Host "Tache ${taskId}: Mesure ${normalizedValue} ${unit} (precision: ${precision})" -ForegroundColor Green
            }
        }
    }
    
    return $tasks
}

# Exécuter la fonction d'extraction des nombres avec précision contextuelle
Write-Host "Test minimal d'extraction des nombres avec precision contextuelle..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$contextualPrecision = Get-ContextualPrecision -Content $testContent

# Afficher les résultats
Write-Host "`nResume des resultats:" -ForegroundColor Yellow
Write-Host "- Taches avec valeurs de prix: $(($contextualPrecision.Values | Where-Object { $_.ContextualPrecisionValues.Price.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Taches avec valeurs de pourcentage: $(($contextualPrecision.Values | Where-Object { $_.ContextualPrecisionValues.Percentage.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Taches avec valeurs de mesure: $(($contextualPrecision.Values | Where-Object { $_.ContextualPrecisionValues.Measurement.Count -gt 0 }).Count)" -ForegroundColor Yellow

Write-Host "`nTest termine." -ForegroundColor Cyan
