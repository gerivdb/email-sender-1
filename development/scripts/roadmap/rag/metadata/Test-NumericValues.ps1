# Test-NumericValues.ps1
# Script pour tester l'extraction des valeurs numériques
# Version: 1.0
# Date: 2025-05-15

# Créer un contenu de test avec différentes valeurs numériques
$testContent = @"
# Test de l'extraction des valeurs numériques

## Nombres simples (entiers)
- [ ] **1.1** Tâche avec nombre simple 42
- [ ] **1.2** Tâche avec plusieurs nombres simples 10 20 30
- [ ] **1.3** Tâche avec nombre dans un tag #duration:7d
- [ ] **1.4** Tâche avec nombre dans un identifiant 1.4 (ne devrait pas être extrait)

## Nombres avec séparateurs
- [ ] **2.1** Tâche avec nombre séparé par virgules 1,000
- [ ] **2.2** Tâche avec grand nombre séparé par virgules 1,000,000
- [ ] **2.3** Tâche avec nombre séparé par underscores 1_000
- [ ] **2.4** Tâche avec grand nombre séparé par underscores 1_000_000
- [ ] **2.5** Tâche avec nombre séparé par points (format européen) 1.000
- [ ] **2.6** Tâche avec grand nombre séparé par points (format européen) 1.000.000

## Nombres décimaux
- [ ] **3.1** Tâche avec nombre décimal avec point 3.14
- [ ] **3.2** Tâche avec nombre décimal avec virgule 3,14
- [ ] **3.3** Tâche avec nombre décimal dans un tag #duration:2.5d
- [ ] **3.4** Tâche avec nombre décimal dans un identifiant 3.4 (ne devrait pas être extrait)

## Tâches sans valeurs numériques
- [ ] **5.1** Tâche sans valeur numérique
"@

# Fonction pour extraire les valeurs numériques
function Get-NumericValues {
    param (
        [string]$Content
    )
    
    Write-Host "Extraction des valeurs numériques..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Patterns pour les valeurs numériques
    $simpleNumberPattern = '(?<![0-9.,_])(\d+)(?![0-9.,_])'
    $commaThousandPattern = '(\d{1,3}(?:,\d{3})+)(?!\d)'
    $underscoreThousandPattern = '(\d{1,3}(?:_\d{3})+)(?!\d)'
    $dotThousandPattern = '(\d{1,3}(?:\.\d{3})+)(?!\d)'
    $dotDecimalPattern = '(\d+\.\d+)'
    $commaDecimalPattern = '(\d+,\d+)'
    
    # Analyser chaque ligne
    foreach ($line in $lines) {
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Initialiser la tâche si elle n'existe pas déjà
            if (-not $tasks.ContainsKey($taskId)) {
                $tasks[$taskId] = @{
                    Id = $taskId
                    NumericValues = @{
                        SimpleNumbers = @()
                        NumbersWithSeparators = @()
                        DecimalNumbers = @()
                    }
                }
            }
            
            # Extraire les nombres simples
            $matches = [regex]::Matches($taskLine, $simpleNumberPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                
                # Vérifier que ce n'est pas une partie d'un nombre avec séparateur ou décimal
                $isPartOfLargerNumber = $false
                if ($taskLine -match "[\d.,_]$numberValue" -or $taskLine -match "$numberValue[\d.,_]") {
                    $isPartOfLargerNumber = $true
                }
                
                # Vérifier que ce n'est pas une partie d'un identifiant de tâche
                if ($taskId -match $numberValue) {
                    $isPartOfLargerNumber = $true
                }
                
                if (-not $isPartOfLargerNumber) {
                    $tasks[$taskId].NumericValues.SimpleNumbers += @{
                        Value = $numberValue
                        Original = $numberValue
                    }
                    
                    Write-Host "Tache ${taskId}: Nombre simple ${numberValue}" -ForegroundColor Green
                }
            }
            
            # Extraire les nombres avec séparateurs de milliers (virgule)
            $matches = [regex]::Matches($taskLine, $commaThousandPattern)
            foreach ($match in $matches) {
                $numberWithSeparator = $match.Groups[1].Value
                $normalizedValue = $numberWithSeparator -replace ',', ''
                
                $tasks[$taskId].NumericValues.NumbersWithSeparators += @{
                    Value = $normalizedValue
                    Original = $numberWithSeparator
                    Separator = ","
                }
                
                Write-Host "Tache ${taskId}: Nombre avec séparateurs ${numberWithSeparator} (normalisé: ${normalizedValue})" -ForegroundColor Green
            }
            
            # Extraire les nombres avec séparateurs de milliers (underscore)
            $matches = [regex]::Matches($taskLine, $underscoreThousandPattern)
            foreach ($match in $matches) {
                $numberWithSeparator = $match.Groups[1].Value
                $normalizedValue = $numberWithSeparator -replace '_', ''
                
                $tasks[$taskId].NumericValues.NumbersWithSeparators += @{
                    Value = $normalizedValue
                    Original = $numberWithSeparator
                    Separator = "_"
                }
                
                Write-Host "Tache ${taskId}: Nombre avec séparateurs ${numberWithSeparator} (normalisé: ${normalizedValue})" -ForegroundColor Green
            }
            
            # Extraire les nombres avec séparateurs de milliers (point - format européen)
            $matches = [regex]::Matches($taskLine, $dotThousandPattern)
            foreach ($match in $matches) {
                $numberWithSeparator = $match.Groups[1].Value
                $normalizedValue = $numberWithSeparator -replace '\.', ''
                
                $tasks[$taskId].NumericValues.NumbersWithSeparators += @{
                    Value = $normalizedValue
                    Original = $numberWithSeparator
                    Separator = "."
                }
                
                Write-Host "Tache ${taskId}: Nombre avec séparateurs ${numberWithSeparator} (normalisé: ${normalizedValue})" -ForegroundColor Green
            }
            
            # Extraire les nombres décimaux avec point
            $matches = [regex]::Matches($taskLine, $dotDecimalPattern)
            foreach ($match in $matches) {
                $decimalNumber = $match.Groups[1].Value
                
                # Vérifier que ce n'est pas une partie d'un identifiant de tâche
                if ($taskId -ne $decimalNumber) {
                    $tasks[$taskId].NumericValues.DecimalNumbers += @{
                        Value = $decimalNumber
                        Original = $decimalNumber
                        Separator = "."
                    }
                    
                    Write-Host "Tache ${taskId}: Nombre décimal ${decimalNumber}" -ForegroundColor Green
                }
            }
            
            # Extraire les nombres décimaux avec virgule
            $matches = [regex]::Matches($taskLine, $commaDecimalPattern)
            foreach ($match in $matches) {
                $decimalNumber = $match.Groups[1].Value
                $normalizedValue = $decimalNumber -replace ',', '.'
                
                $tasks[$taskId].NumericValues.DecimalNumbers += @{
                    Value = $normalizedValue
                    Original = $decimalNumber
                    Separator = ","
                }
                
                Write-Host "Tache ${taskId}: Nombre décimal ${decimalNumber} (normalisé: ${normalizedValue})" -ForegroundColor Green
            }
        }
    }
    
    return $tasks
}

# Exécuter la fonction d'extraction des valeurs numériques
Write-Host "Test d'extraction des valeurs numériques..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$numericValues = Get-NumericValues -Content $testContent

# Afficher les résultats
Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
Write-Host "- Tâches avec nombres simples: $(($numericValues.Values | Where-Object { $_.NumericValues.SimpleNumbers.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec nombres avec séparateurs: $(($numericValues.Values | Where-Object { $_.NumericValues.NumbersWithSeparators.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches avec nombres décimaux: $(($numericValues.Values | Where-Object { $_.NumericValues.DecimalNumbers.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Tâches sans valeurs numériques: $(15 - $numericValues.Count)" -ForegroundColor Yellow

Write-Host "`nTest terminé." -ForegroundColor Cyan
