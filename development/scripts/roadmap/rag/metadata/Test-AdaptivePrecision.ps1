# Test-AdaptivePrecision.ps1
# Script pour tester l'extraction des nombres avec precision adaptative
# Version: 1.0
# Date: 2025-05-15

# Créer un contenu de test avec différentes valeurs numériques à précision adaptative
$testContent = @"
# Test de l'extraction des nombres avec precision adaptative

## Tags de precision avec format #precision:X
- [ ] **1.1** Tache avec tag de precision 2 #precision:2 et nombre 3.14159
- [ ] **1.2** Tache avec tag de precision 3 #precision:3 et nombre 2.71828
- [ ] **1.3** Tache avec tag de precision 1 #precision:1 et nombre 1.61803

## Tags de precision avec format #precision(X)
- [ ] **2.1** Tache avec tag de precision 2 #precision(2) et nombre 3.14159
- [ ] **2.2** Tache avec tag de precision 3 #precision(3) et nombre 2.71828
- [ ] **2.3** Tache avec tag de precision 1 #precision(1) et nombre 1.61803

## Nombres avec virgule
- [ ] **3.1** Tache avec tag de precision 2 #precision:2 et nombre 3,14159
- [ ] **3.2** Tache avec tag de precision 3 #precision:3 et nombre 2,71828
- [ ] **3.3** Tache avec tag de precision 1 #precision:1 et nombre 1,61803

## Taches sans tags de precision
- [ ] **4.1** Tache sans tag de precision mais avec nombre 3.14159
- [ ] **4.2** Tache sans tag de precision mais avec nombre 2.71828
"@

# Fonction pour extraire les nombres avec précision adaptative
function Get-AdaptivePrecision {
    param (
        [string]$Content
    )
    
    Write-Host "Extraction des nombres avec precision adaptative..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Pattern pour les tags de précision
    $precisionTagPattern = '#precision:(\d+)'
    $precisionParenTagPattern = '#precision\((\d+)\)'
    
    # Pattern pour les nombres décimaux
    $decimalNumberPattern = '(\d+\.\d+)'
    $commaDecimalNumberPattern = '(\d+,\d+)'
    
    # Analyser chaque ligne
    foreach ($line in $lines) {
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Initialiser la tâche si elle n'existe pas déjà
            if (-not $tasks.ContainsKey($taskId)) {
                $tasks[$taskId] = @{
                    Id = $taskId
                    AdaptivePrecisionValues = @{
                        TaggedPrecision = @()
                        AdaptedNumbers = @()
                    }
                }
            }
            
            # Extraire les tags de précision
            $precisionValue = $null
            
            # Format #precision:X
            if ($taskLine -match $precisionTagPattern) {
                $precisionValue = [int]$matches[1]
                
                $tasks[$taskId].AdaptivePrecisionValues.TaggedPrecision += @{
                    Value = $precisionValue
                    Type = "PrecisionTag"
                    Original = "#precision:$precisionValue"
                }
                
                Write-Host "Tache ${taskId}: Tag de precision ${precisionValue} (#precision:${precisionValue})" -ForegroundColor Green
            }
            
            # Format #precision(X)
            if ($taskLine -match $precisionParenTagPattern) {
                $precisionValue = [int]$matches[1]
                
                $tasks[$taskId].AdaptivePrecisionValues.TaggedPrecision += @{
                    Value = $precisionValue
                    Type = "PrecisionParenTag"
                    Original = "#precision($precisionValue)"
                }
                
                Write-Host "Tache ${taskId}: Tag de precision ${precisionValue} (#precision(${precisionValue}))" -ForegroundColor Green
            }
            
            # Si un tag de précision a été trouvé, extraire les nombres décimaux et les adapter
            if ($precisionValue -ne $null) {
                # Extraire les nombres décimaux avec point
                $matches = [regex]::Matches($taskLine, $decimalNumberPattern)
                foreach ($match in $matches) {
                    $numberValue = $match.Groups[1].Value
                    $originalPrecision = ($numberValue -split '\.')[1].Length
                    
                    # Adapter la précision du nombre
                    $adaptedValue = [math]::Round([double]$numberValue, $precisionValue)
                    
                    $tasks[$taskId].AdaptivePrecisionValues.AdaptedNumbers += @{
                        Value = $adaptedValue
                        Original = $numberValue
                        OriginalPrecision = $originalPrecision
                        AdaptedPrecision = $precisionValue
                    }
                    
                    Write-Host "Tache ${taskId}: Nombre adapte ${adaptedValue} (original: ${numberValue}, precision originale: ${originalPrecision}, precision adaptee: ${precisionValue})" -ForegroundColor Green
                }
                
                # Extraire les nombres décimaux avec virgule
                $matches = [regex]::Matches($taskLine, $commaDecimalNumberPattern)
                foreach ($match in $matches) {
                    $numberValue = $match.Groups[1].Value
                    $normalizedValue = $numberValue -replace ',', '.'
                    $originalPrecision = ($normalizedValue -split '\.')[1].Length
                    
                    # Adapter la précision du nombre
                    $adaptedValue = [math]::Round([double]$normalizedValue, $precisionValue)
                    
                    $tasks[$taskId].AdaptivePrecisionValues.AdaptedNumbers += @{
                        Value = $adaptedValue
                        Original = $numberValue
                        OriginalPrecision = $originalPrecision
                        AdaptedPrecision = $precisionValue
                    }
                    
                    Write-Host "Tache ${taskId}: Nombre adapte ${adaptedValue} (original: ${numberValue}, precision originale: ${originalPrecision}, precision adaptee: ${precisionValue})" -ForegroundColor Green
                }
            }
        }
    }
    
    return $tasks
}

# Exécuter la fonction d'extraction des nombres avec précision adaptative
Write-Host "Test d'extraction des nombres avec precision adaptative..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$adaptivePrecision = Get-AdaptivePrecision -Content $testContent

# Afficher les résultats
Write-Host "`nResume des resultats:" -ForegroundColor Yellow
Write-Host "- Taches avec tags de precision: $(($adaptivePrecision.Values | Where-Object { $_.AdaptivePrecisionValues.TaggedPrecision.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Taches avec nombres adaptes: $(($adaptivePrecision.Values | Where-Object { $_.AdaptivePrecisionValues.AdaptedNumbers.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Taches sans tags de precision: $(11 - ($adaptivePrecision.Values | Where-Object { $_.AdaptivePrecisionValues.TaggedPrecision.Count -gt 0 }).Count)" -ForegroundColor Yellow

Write-Host "`nTest termine." -ForegroundColor Cyan
