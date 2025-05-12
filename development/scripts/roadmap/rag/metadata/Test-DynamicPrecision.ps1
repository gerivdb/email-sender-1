# Test-DynamicPrecision.ps1
# Script pour tester l'extraction des nombres avec precision dynamique
# Version: 1.0
# Date: 2025-05-15

# Créer un contenu de test avec différentes valeurs numériques à précision dynamique
$testContent = @"
# Test de l'extraction des nombres avec precision dynamique

## Tags de precision dynamique avec format #dynamic-precision:min-max
- [ ] **1.1** Tache avec tag de precision dynamique 1-3 #dynamic-precision:1-3 et nombre 1234.56789
- [ ] **1.2** Tache avec tag de precision dynamique 1-3 #dynamic-precision:1-3 et nombre 123.45678
- [ ] **1.3** Tache avec tag de precision dynamique 1-3 #dynamic-precision:1-3 et nombre 12.345678
- [ ] **1.4** Tache avec tag de precision dynamique 1-3 #dynamic-precision:1-3 et nombre 1.2345678

## Tags de precision dynamique avec format #dynamic-precision(min-max)
- [ ] **2.1** Tache avec tag de precision dynamique 2-4 #dynamic-precision(2-4) et nombre 1234.56789
- [ ] **2.2** Tache avec tag de precision dynamique 2-4 #dynamic-precision(2-4) et nombre 123.45678
- [ ] **2.3** Tache avec tag de precision dynamique 2-4 #dynamic-precision(2-4) et nombre 12.345678
- [ ] **2.4** Tache avec tag de precision dynamique 2-4 #dynamic-precision(2-4) et nombre 1.2345678

## Nombres avec virgule
- [ ] **3.1** Tache avec tag de precision dynamique 1-3 #dynamic-precision:1-3 et nombre 1234,56789
- [ ] **3.2** Tache avec tag de precision dynamique 1-3 #dynamic-precision:1-3 et nombre 123,45678

## Taches sans tags de precision dynamique
- [ ] **4.1** Tache sans tag de precision dynamique mais avec nombre 3.14159
- [ ] **4.2** Tache sans tag de precision dynamique mais avec nombre 2.71828
"@

# Fonction pour déterminer la précision dynamique en fonction de la valeur du nombre
function Get-DynamicPrecisionValue {
    param (
        [string]$Value,
        [int]$MinPrecision,
        [int]$MaxPrecision
    )
    
    # Convertir la valeur en nombre
    $number = [double]$Value
    
    # Déterminer la précision dynamique en fonction de la valeur du nombre
    # Règle : Plus le nombre est grand, moins il a besoin de précision
    # Règle : Plus le nombre est petit, plus il a besoin de précision
    
    # Calculer la précision dynamique
    $precision = $null
    
    if ($number -ge 1000) {
        # Grands nombres : précision minimale
        $precision = $MinPrecision
    }
    elseif ($number -ge 100) {
        # Nombres moyens : précision intermédiaire basse
        $precision = [math]::Min($MinPrecision + 1, $MaxPrecision)
    }
    elseif ($number -ge 10) {
        # Petits nombres : précision intermédiaire haute
        $precision = [math]::Min($MinPrecision + 2, $MaxPrecision)
    }
    else {
        # Très petits nombres : précision maximale
        $precision = $MaxPrecision
    }
    
    return $precision
}

# Fonction pour extraire les nombres avec précision dynamique
function Get-DynamicPrecision {
    param (
        [string]$Content
    )
    
    Write-Host "Extraction des nombres avec precision dynamique..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Pattern pour les tags de précision dynamique
    $dynamicPrecisionTagPattern = '#dynamic-precision:(\d+)-(\d+)'
    $dynamicPrecisionParenTagPattern = '#dynamic-precision\((\d+)-(\d+)\)'
    
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
                    DynamicPrecisionValues = @{
                        TaggedDynamicPrecision = @()
                        DynamicNumbers = @()
                    }
                }
            }
            
            # Extraire les tags de précision dynamique
            $minPrecision = $null
            $maxPrecision = $null
            
            # Format #dynamic-precision:min-max
            if ($taskLine -match $dynamicPrecisionTagPattern) {
                $minPrecision = [int]$matches[1]
                $maxPrecision = [int]$matches[2]
                
                $tasks[$taskId].DynamicPrecisionValues.TaggedDynamicPrecision += @{
                    MinValue = $minPrecision
                    MaxValue = $maxPrecision
                    Type = "DynamicPrecisionTag"
                    Original = "#dynamic-precision:$minPrecision-$maxPrecision"
                }
                
                Write-Host "Tache ${taskId}: Tag de precision dynamique ${minPrecision}-${maxPrecision} (#dynamic-precision:${minPrecision}-${maxPrecision})" -ForegroundColor Green
            }
            
            # Format #dynamic-precision(min-max)
            if ($taskLine -match $dynamicPrecisionParenTagPattern) {
                $minPrecision = [int]$matches[1]
                $maxPrecision = [int]$matches[2]
                
                $tasks[$taskId].DynamicPrecisionValues.TaggedDynamicPrecision += @{
                    MinValue = $minPrecision
                    MaxValue = $maxPrecision
                    Type = "DynamicPrecisionParenTag"
                    Original = "#dynamic-precision($minPrecision-$maxPrecision)"
                }
                
                Write-Host "Tache ${taskId}: Tag de precision dynamique ${minPrecision}-${maxPrecision} (#dynamic-precision(${minPrecision}-${maxPrecision}))" -ForegroundColor Green
            }
            
            # Si un tag de précision dynamique a été trouvé, extraire les nombres décimaux et les adapter
            if ($minPrecision -ne $null -and $maxPrecision -ne $null) {
                # Extraire les nombres décimaux avec point
                $matches = [regex]::Matches($taskLine, $decimalNumberPattern)
                foreach ($match in $matches) {
                    $numberValue = $match.Groups[1].Value
                    $originalPrecision = ($numberValue -split '\.')[1].Length
                    
                    # Déterminer la précision dynamique en fonction de la valeur du nombre
                    $dynamicPrecision = Get-DynamicPrecisionValue -Value $numberValue -MinPrecision $minPrecision -MaxPrecision $maxPrecision
                    
                    # Adapter la précision du nombre
                    $adaptedValue = [math]::Round([double]$numberValue, $dynamicPrecision)
                    
                    $tasks[$taskId].DynamicPrecisionValues.DynamicNumbers += @{
                        Value = $adaptedValue
                        Original = $numberValue
                        OriginalPrecision = $originalPrecision
                        DynamicPrecision = $dynamicPrecision
                        MinPrecision = $minPrecision
                        MaxPrecision = $maxPrecision
                    }
                    
                    Write-Host "Tache ${taskId}: Nombre dynamique ${adaptedValue} (original: ${numberValue}, precision originale: ${originalPrecision}, precision dynamique: ${dynamicPrecision})" -ForegroundColor Green
                }
                
                # Extraire les nombres décimaux avec virgule
                $matches = [regex]::Matches($taskLine, $commaDecimalNumberPattern)
                foreach ($match in $matches) {
                    $numberValue = $match.Groups[1].Value
                    $normalizedValue = $numberValue -replace ',', '.'
                    $originalPrecision = ($normalizedValue -split '\.')[1].Length
                    
                    # Déterminer la précision dynamique en fonction de la valeur du nombre
                    $dynamicPrecision = Get-DynamicPrecisionValue -Value $normalizedValue -MinPrecision $minPrecision -MaxPrecision $maxPrecision
                    
                    # Adapter la précision du nombre
                    $adaptedValue = [math]::Round([double]$normalizedValue, $dynamicPrecision)
                    
                    $tasks[$taskId].DynamicPrecisionValues.DynamicNumbers += @{
                        Value = $adaptedValue
                        Original = $numberValue
                        OriginalPrecision = $originalPrecision
                        DynamicPrecision = $dynamicPrecision
                        MinPrecision = $minPrecision
                        MaxPrecision = $maxPrecision
                    }
                    
                    Write-Host "Tache ${taskId}: Nombre dynamique ${adaptedValue} (original: ${numberValue}, precision originale: ${originalPrecision}, precision dynamique: ${dynamicPrecision})" -ForegroundColor Green
                }
            }
        }
    }
    
    return $tasks
}

# Exécuter la fonction d'extraction des nombres avec précision dynamique
Write-Host "Test d'extraction des nombres avec precision dynamique..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$dynamicPrecision = Get-DynamicPrecision -Content $testContent

# Afficher les résultats
Write-Host "`nResume des resultats:" -ForegroundColor Yellow
Write-Host "- Taches avec tags de precision dynamique: $(($dynamicPrecision.Values | Where-Object { $_.DynamicPrecisionValues.TaggedDynamicPrecision.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Taches avec nombres dynamiques: $(($dynamicPrecision.Values | Where-Object { $_.DynamicPrecisionValues.DynamicNumbers.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Taches sans tags de precision dynamique: $(12 - ($dynamicPrecision.Values | Where-Object { $_.DynamicPrecisionValues.TaggedDynamicPrecision.Count -gt 0 }).Count)" -ForegroundColor Yellow

Write-Host "`nTest termine." -ForegroundColor Cyan
