# Test-StandardizedPrecision-New.ps1
# Script pour tester la standardisation des précisions numériques
# Version: 1.0
# Date: 2025-05-15

# Fonction pour extraire les tags de précision standard
function Get-PrecisionFromTag {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskLine,

        [Parameter(Mandatory = $false)]
        [int]$DefaultPrecision = 2
    )

    # Pattern pour les tags de précision standard
    $standardPrecisionTagPattern = '#standard-precision:(\d+)'
    $standardPrecisionParenTagPattern = '#standard-precision\((\d+)\)'

    $precision = $DefaultPrecision
    $tagFound = $false

    # Format #standard-precision:X
    if ($TaskLine -match $standardPrecisionTagPattern) {
        $precision = [int]$matches[1]
        $tagFound = $true
    }
    # Format #standard-precision(X)
    elseif ($TaskLine -match $standardPrecisionParenTagPattern) {
        $precision = [int]$matches[1]
        $tagFound = $true
    }

    return @{
        Precision = $precision
        TagFound  = $tagFound
    }
}

# Fonction pour extraire et standardiser les nombres dans une ligne
function Get-StandardizedNumbers {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskLine,

        [Parameter(Mandatory = $true)]
        [int]$Precision
    )

    # Pattern pour les nombres décimaux
    $decimalNumberPattern = '(\d+\.\d+)'
    $commaDecimalNumberPattern = '(\d+,\d+)'

    $standardizedNumbers = @()

    # Extraire les nombres décimaux avec point
    $regexMatches = [regex]::Matches($TaskLine, $decimalNumberPattern)
    foreach ($match in $regexMatches) {
        $numberValue = $match.Groups[1].Value
        $originalPrecision = ($numberValue -split '\.')[1].Length

        # Standardiser la précision du nombre
        $standardizedValue = [math]::Round([double]$numberValue, $Precision)

        $standardizedNumbers += @{
            Value                 = $standardizedValue
            Original              = $numberValue
            OriginalPrecision     = $originalPrecision
            StandardizedPrecision = $Precision
        }
    }

    # Extraire les nombres décimaux avec virgule
    $regexMatches = [regex]::Matches($TaskLine, $commaDecimalNumberPattern)
    foreach ($match in $regexMatches) {
        $numberValue = $match.Groups[1].Value
        $normalizedValue = $numberValue -replace ',', '.'
        $originalPrecision = ($normalizedValue -split '\.')[1].Length

        # Standardiser la précision du nombre
        $standardizedValue = [math]::Round([double]$normalizedValue, $Precision)

        $standardizedNumbers += @{
            Value                 = $standardizedValue
            Original              = $numberValue
            OriginalPrecision     = $originalPrecision
            StandardizedPrecision = $Precision
        }
    }

    return $standardizedNumbers
}

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

# Fonction principale pour tester la standardisation des précisions numériques
function Test-StandardizedPrecision {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [int]$DefaultPrecision = 2
    )

    Write-Host "Test de standardisation des précisions numériques..." -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan

    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"

    # Pattern pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'

    # Initialiser les variables d'analyse
    $tasks = @{}
    $tasksWithTags = 0
    $tasksWithNumbers = 0
    $tasksWithDefaultPrecision = 0

    # Analyser chaque ligne
    foreach ($line in $lines) {
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line

            # Extraire les tags de précision standard
            $precisionInfo = Get-PrecisionFromTag -TaskLine $taskLine -DefaultPrecision $DefaultPrecision
            $precision = $precisionInfo.Precision

            if ($precisionInfo.TagFound) {
                Write-Host "Tache ${taskId}: Tag de précision standard ${precision}" -ForegroundColor Green
                $tasksWithTags++
            } else {
                Write-Host "Tache ${taskId}: Utilisation de la précision par défaut ${precision}" -ForegroundColor Yellow
                $tasksWithDefaultPrecision++
            }

            # Extraire et standardiser les nombres
            $standardizedNumbers = Get-StandardizedNumbers -TaskLine $taskLine -Precision $precision

            if ($standardizedNumbers.Count -gt 0) {
                $tasksWithNumbers++

                foreach ($number in $standardizedNumbers) {
                    Write-Host "Tache ${taskId}: Nombre standardisé $($number.Value) (original: $($number.Original), précision originale: $($number.OriginalPrecision), précision standardisée: $($number.StandardizedPrecision))" -ForegroundColor Green
                }
            }

            # Ajouter la tâche aux résultats
            $tasks[$taskId] = @{
                Id                  = $taskId
                Precision           = $precision
                TagFound            = $precisionInfo.TagFound
                StandardizedNumbers = $standardizedNumbers
            }
        }
    }

    # Afficher les résultats
    Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
    Write-Host "- Taches avec tags de précision standard: ${tasksWithTags}" -ForegroundColor Yellow
    Write-Host "- Taches avec nombres standardisés: ${tasksWithNumbers}" -ForegroundColor Yellow
    Write-Host "- Taches sans tags de précision standard (utilisant la précision par défaut): ${tasksWithDefaultPrecision}" -ForegroundColor Yellow

    Write-Host "`nTest terminé." -ForegroundColor Cyan

    return $tasks
}

# Exécuter le test
Test-StandardizedPrecision -Content $testContent -DefaultPrecision 2
