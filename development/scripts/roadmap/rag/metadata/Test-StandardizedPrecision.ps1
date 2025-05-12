# Test-StandardizedPrecision.ps1
# Script pour tester la standardisation des précisions numériques
# Version: 1.0
# Date: 2025-05-15

# Créer un contenu de test avec différentes valeurs numériques à standardiser
$testContent = @"
# Test de la standardisation des précisions numériques

## Tags de précision standard avec format #standard-precision:X
- [ ] **1.1** Tache avec tag de précision standard 3 #standard-precision:3 et nombre 3.14159
- [ ] **1.2** Tache avec tag de précision standard 4 #standard-precision:4 et nombre 2.71828
- [ ] **1.3** Tache avec tag de précision standard 1 #standard-precision:1 et nombre 1.61803

## Tags de précision standard avec format #standard-precision(X)
- [ ] **2.1** Tache avec tag de précision standard 3 #standard-precision(3) et nombre 3.14159
- [ ] **2.2** Tache avec tag de précision standard 4 #standard-precision(4) et nombre 2.71828
- [ ] **2.3** Tache avec tag de précision standard 1 #standard-precision(1) et nombre 1.61803

## Nombres avec virgule
- [ ] **3.1** Tache avec tag de précision standard 3 #standard-precision:3 et nombre 3,14159
- [ ] **3.2** Tache avec tag de précision standard 4 #standard-precision:4 et nombre 2,71828

## Taches sans tags de précision standard (utilisation de la précision par défaut)
- [ ] **4.1** Tache sans tag de précision standard mais avec nombre 3.14159
- [ ] **4.2** Tache sans tag de précision standard mais avec nombre 2.71828
"@

# Fonction pour standardiser les précisions numériques
function Get-StandardizedPrecision {
    param (
        [string]$Content,
        [int]$DefaultPrecision = 2
    )
    
    Write-Host "Standardisation des précisions numériques..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Pattern pour les tags de précision standard
    $standardPrecisionTagPattern = '#standard-precision:(\d+)'
    $standardPrecisionParenTagPattern = '#standard-precision\((\d+)\)'
    
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
                    StandardizedPrecisionValues = @{
                        TaggedStandardPrecision = @()
                        StandardizedNumbers = @()
                    }
                }
            }
            
            # Extraire les tags de précision standard
            $standardPrecision = $null
            
            # Format #standard-precision:X
            if ($taskLine -match $standardPrecisionTagPattern) {
                $standardPrecision = [int]$matches[1]
                
                $tasks[$taskId].StandardizedPrecisionValues.TaggedStandardPrecision += @{
                    Value = $standardPrecision
                    Type = "StandardPrecisionTag"
                    Original = "#standard-precision:$standardPrecision"
                }
                
                Write-Host "Tache ${taskId}: Tag de précision standard ${standardPrecision} (#standard-precision:${standardPrecision})" -ForegroundColor Green
            }
            
            # Format #standard-precision(X)
            if ($taskLine -match $standardPrecisionParenTagPattern) {
                $standardPrecision = [int]$matches[1]
                
                $tasks[$taskId].StandardizedPrecisionValues.TaggedStandardPrecision += @{
                    Value = $standardPrecision
                    Type = "StandardPrecisionParenTag"
                    Original = "#standard-precision($standardPrecision)"
                }
                
                Write-Host "Tache ${taskId}: Tag de précision standard ${standardPrecision} (#standard-precision(${standardPrecision}))" -ForegroundColor Green
            }
            
            # Si aucun tag de précision standard n'a été trouvé, utiliser la précision par défaut
            if ($standardPrecision -eq $null) {
                $standardPrecision = $DefaultPrecision
                
                Write-Host "Tache ${taskId}: Utilisation de la précision par défaut ${standardPrecision}" -ForegroundColor Yellow
            }
            
            # Extraire les nombres décimaux et les standardiser
            # Extraire les nombres décimaux avec point
            $matches = [regex]::Matches($taskLine, $decimalNumberPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $originalPrecision = ($numberValue -split '\.')[1].Length
                
                # Standardiser la précision du nombre
                $standardizedValue = [math]::Round([double]$numberValue, $standardPrecision)
                
                $tasks[$taskId].StandardizedPrecisionValues.StandardizedNumbers += @{
                    Value = $standardizedValue
                    Original = $numberValue
                    OriginalPrecision = $originalPrecision
                    StandardizedPrecision = $standardPrecision
                }
                
                Write-Host "Tache ${taskId}: Nombre standardisé ${standardizedValue} (original: ${numberValue}, précision originale: ${originalPrecision}, précision standardisée: ${standardPrecision})" -ForegroundColor Green
            }
            
            # Extraire les nombres décimaux avec virgule
            $matches = [regex]::Matches($taskLine, $commaDecimalNumberPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $normalizedValue = $numberValue -replace ',', '.'
                $originalPrecision = ($normalizedValue -split '\.')[1].Length
                
                # Standardiser la précision du nombre
                $standardizedValue = [math]::Round([double]$normalizedValue, $standardPrecision)
                
                $tasks[$taskId].StandardizedPrecisionValues.StandardizedNumbers += @{
                    Value = $standardizedValue
                    Original = $numberValue
                    OriginalPrecision = $originalPrecision
                    StandardizedPrecision = $standardPrecision
                }
                
                Write-Host "Tache ${taskId}: Nombre standardisé ${standardizedValue} (original: ${numberValue}, précision originale: ${originalPrecision}, précision standardisée: ${standardPrecision})" -ForegroundColor Green
            }
        }
    }
    
    return $tasks
}

# Exécuter la fonction de standardisation des précisions numériques
Write-Host "Test de standardisation des précisions numériques..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$standardizedPrecision = Get-StandardizedPrecision -Content $testContent -DefaultPrecision 2

# Afficher les résultats
Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
Write-Host "- Taches avec tags de précision standard: $(($standardizedPrecision.Values | Where-Object { $_.StandardizedPrecisionValues.TaggedStandardPrecision.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Taches avec nombres standardisés: $(($standardizedPrecision.Values | Where-Object { $_.StandardizedPrecisionValues.StandardizedNumbers.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Taches sans tags de précision standard (utilisant la précision par défaut): $(($standardizedPrecision.Values | Where-Object { $_.StandardizedPrecisionValues.TaggedStandardPrecision.Count -eq 0 -and $_.StandardizedPrecisionValues.StandardizedNumbers.Count -gt 0 }).Count)" -ForegroundColor Yellow

Write-Host "`nTest terminé." -ForegroundColor Cyan
