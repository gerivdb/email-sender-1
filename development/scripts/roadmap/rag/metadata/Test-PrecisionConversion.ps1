# Test-PrecisionConversion.ps1
# Script pour tester la conversion entre différentes précisions
# Version: 1.0
# Date: 2025-05-15

# Créer un contenu de test avec différentes valeurs numériques à convertir
$testContent = @"
# Test de la conversion entre différentes précisions

## Tags de conversion de précision avec format #convert-precision:source-target
- [ ] **1.1** Tache avec tag de conversion de précision 2-4 #convert-precision:2-4 et nombre 3.14159
- [ ] **1.2** Tache avec tag de conversion de précision 4-2 #convert-precision:4-2 et nombre 3.14159
- [ ] **1.3** Tache avec tag de conversion de précision 3-5 #convert-precision:3-5 et nombre 2.71828
- [ ] **1.4** Tache avec tag de conversion de précision 5-3 #convert-precision:5-3 et nombre 2.71828

## Tags de conversion de précision avec format #convert-precision(source-target)
- [ ] **2.1** Tache avec tag de conversion de précision 2-4 #convert-precision(2-4) et nombre 3.14159
- [ ] **2.2** Tache avec tag de conversion de précision 4-2 #convert-precision(4-2) et nombre 3.14159
- [ ] **2.3** Tache avec tag de conversion de précision 3-5 #convert-precision(3-5) et nombre 2.71828
- [ ] **2.4** Tache avec tag de conversion de précision 5-3 #convert-precision(5-3) et nombre 2.71828

## Nombres avec virgule
- [ ] **3.1** Tache avec tag de conversion de précision 2-4 #convert-precision:2-4 et nombre 3,14159
- [ ] **3.2** Tache avec tag de conversion de précision 4-2 #convert-precision:4-2 et nombre 3,14159

## Taches sans tags de conversion de précision (utilisation des valeurs par défaut)
- [ ] **4.1** Tache sans tag de conversion de précision mais avec nombre 3.14159
- [ ] **4.2** Tache sans tag de conversion de précision mais avec nombre 2.71828
"@

# Fonction pour convertir un nombre entre différentes précisions
function Convert-PrecisionFormat {
    param (
        [string]$Value,
        [int]$SourcePrecision,
        [int]$TargetPrecision
    )

    # Convertir la valeur en nombre
    $number = [double]$Value

    # Arrondir le nombre à la précision source
    $sourceNumber = [math]::Round($number, $SourcePrecision)

    # Convertir le nombre à la précision cible
    $targetNumber = [math]::Round($sourceNumber, $TargetPrecision)

    return $targetNumber
}

# Fonction pour convertir les nombres entre différentes précisions
function Get-ConvertedPrecisionValues {
    param (
        [string]$Content,
        [int]$DefaultSourcePrecision = 2,
        [int]$DefaultTargetPrecision = 2
    )

    Write-Host "Conversion des nombres entre différentes précisions..." -ForegroundColor Cyan

    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"

    # Initialiser les variables d'analyse
    $tasks = @{}

    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'

    # Pattern pour les tags de conversion de précision
    $convertPrecisionTagPattern = '#convert-precision:(\d+)-(\d+)'
    $convertPrecisionParenTagPattern = '#convert-precision\((\d+)-(\d+)\)'

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
                    Id                       = $taskId
                    ConvertedPrecisionValues = @{
                        TaggedConversionRules = @()
                        ConvertedNumbers      = @()
                    }
                }
            }

            # Extraire les tags de conversion de précision
            $sourcePrecision = $null
            $targetPrecision = $null

            # Format #convert-precision:source-target
            if ($taskLine -match $convertPrecisionTagPattern) {
                $sourcePrecision = [int]$matches[1]
                $targetPrecision = [int]$matches[2]

                $tasks[$taskId].ConvertedPrecisionValues.TaggedConversionRules += @{
                    SourcePrecision = $sourcePrecision
                    TargetPrecision = $targetPrecision
                    Type            = "ConversionTag"
                    Original        = "#convert-precision:$sourcePrecision-$targetPrecision"
                }

                Write-Host "Tache ${taskId}: Tag de conversion de précision ${sourcePrecision}-${targetPrecision} (#convert-precision:${sourcePrecision}-${targetPrecision})" -ForegroundColor Green
            }

            # Format #convert-precision(source-target)
            if ($taskLine -match $convertPrecisionParenTagPattern) {
                $sourcePrecision = [int]$matches[1]
                $targetPrecision = [int]$matches[2]

                $tasks[$taskId].ConvertedPrecisionValues.TaggedConversionRules += @{
                    SourcePrecision = $sourcePrecision
                    TargetPrecision = $targetPrecision
                    Type            = "ConversionParenTag"
                    Original        = "#convert-precision($sourcePrecision-$targetPrecision)"
                }

                Write-Host "Tache ${taskId}: Tag de conversion de précision ${sourcePrecision}-${targetPrecision} (#convert-precision(${sourcePrecision}-${targetPrecision}))" -ForegroundColor Green
            }

            # Si aucun tag de conversion de précision n'a été trouvé, utiliser les valeurs par défaut
            if ($null -eq $sourcePrecision -or $null -eq $targetPrecision) {
                $sourcePrecision = $DefaultSourcePrecision
                $targetPrecision = $DefaultTargetPrecision

                Write-Host "Tache ${taskId}: Utilisation des valeurs par défaut ${sourcePrecision}-${targetPrecision}" -ForegroundColor Yellow
            }

            # Extraire les nombres décimaux et les convertir
            # Extraire les nombres décimaux avec point
            $regexMatches = [regex]::Matches($taskLine, $decimalNumberPattern)
            foreach ($match in $regexMatches) {
                $numberValue = $match.Groups[1].Value
                $originalPrecision = ($numberValue -split '\.')[1].Length

                # Convertir la précision du nombre
                $convertedValue = Convert-PrecisionFormat -Value $numberValue -SourcePrecision $sourcePrecision -TargetPrecision $targetPrecision

                $tasks[$taskId].ConvertedPrecisionValues.ConvertedNumbers += @{
                    Value             = $convertedValue
                    Original          = $numberValue
                    OriginalPrecision = $originalPrecision
                    SourcePrecision   = $sourcePrecision
                    TargetPrecision   = $targetPrecision
                }

                Write-Host "Tache ${taskId}: Nombre converti ${convertedValue} (original: ${numberValue}, précision source: ${sourcePrecision}, précision cible: ${targetPrecision})" -ForegroundColor Green
            }

            # Extraire les nombres décimaux avec virgule
            $regexMatches = [regex]::Matches($taskLine, $commaDecimalNumberPattern)
            foreach ($match in $regexMatches) {
                $numberValue = $match.Groups[1].Value
                $normalizedValue = $numberValue -replace ',', '.'
                $originalPrecision = ($normalizedValue -split '\.')[1].Length

                # Convertir la précision du nombre
                $convertedValue = Convert-PrecisionFormat -Value $normalizedValue -SourcePrecision $sourcePrecision -TargetPrecision $targetPrecision

                $tasks[$taskId].ConvertedPrecisionValues.ConvertedNumbers += @{
                    Value             = $convertedValue
                    Original          = $numberValue
                    OriginalPrecision = $originalPrecision
                    SourcePrecision   = $sourcePrecision
                    TargetPrecision   = $targetPrecision
                }

                Write-Host "Tache ${taskId}: Nombre converti ${convertedValue} (original: ${numberValue}, précision source: ${sourcePrecision}, précision cible: ${targetPrecision})" -ForegroundColor Green
            }
        }
    }

    return $tasks
}

# Exécuter la fonction de conversion entre différentes précisions
Write-Host "Test de conversion entre différentes précisions..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$convertedPrecisionValues = Get-ConvertedPrecisionValues -Content $testContent -DefaultSourcePrecision 2 -DefaultTargetPrecision 2

# Afficher les résultats
Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
Write-Host "- Taches avec tags de conversion de précision: $(($convertedPrecisionValues.Values | Where-Object { $_.ConvertedPrecisionValues.TaggedConversionRules.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Taches avec nombres convertis: $(($convertedPrecisionValues.Values | Where-Object { $_.ConvertedPrecisionValues.ConvertedNumbers.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Taches sans tags de conversion de précision (utilisant les valeurs par défaut): $(($convertedPrecisionValues.Values | Where-Object { $_.ConvertedPrecisionValues.TaggedConversionRules.Count -eq 0 -and $_.ConvertedPrecisionValues.ConvertedNumbers.Count -gt 0 }).Count)" -ForegroundColor Yellow

Write-Host "`nTest terminé." -ForegroundColor Cyan
