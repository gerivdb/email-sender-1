# Test-RoundingRules.ps1
# Script pour tester les règles d'arrondi et de troncature
# Version: 1.0
# Date: 2025-05-15

# Créer un contenu de test avec différentes valeurs numériques à arrondir
$testContent = @"
# Test des règles d'arrondi et de troncature

## Tags de règle d'arrondi avec format #round:rule:precision
- [ ] **1.1** Tache avec tag de règle d'arrondi Round:2 #round:Round:2 et nombre 3.14159
- [ ] **1.2** Tache avec tag de règle d'arrondi Ceiling:2 #round:Ceiling:2 et nombre 3.14159
- [ ] **1.3** Tache avec tag de règle d'arrondi Floor:2 #round:Floor:2 et nombre 3.14159
- [ ] **1.4** Tache avec tag de règle d'arrondi Truncate:2 #round:Truncate:2 et nombre 3.14159

## Tags de règle d'arrondi avec format #round(rule:precision)
- [ ] **2.1** Tache avec tag de règle d'arrondi Round:3 #round(Round:3) et nombre 2.71828
- [ ] **2.2** Tache avec tag de règle d'arrondi Ceiling:3 #round(Ceiling:3) et nombre 2.71828
- [ ] **2.3** Tache avec tag de règle d'arrondi Floor:3 #round(Floor:3) et nombre 2.71828
- [ ] **2.4** Tache avec tag de règle d'arrondi Truncate:3 #round(Truncate:3) et nombre 2.71828

## Nombres avec virgule
- [ ] **3.1** Tache avec tag de règle d'arrondi Round:2 #round:Round:2 et nombre 3,14159
- [ ] **3.2** Tache avec tag de règle d'arrondi Ceiling:2 #round:Ceiling:2 et nombre 3,14159

## Taches sans tags de règle d'arrondi (utilisation de la règle par défaut)
- [ ] **4.1** Tache sans tag de règle d'arrondi mais avec nombre 3.14159
- [ ] **4.2** Tache sans tag de règle d'arrondi mais avec nombre 2.71828
"@

# Fonction pour appliquer une règle d'arrondi à un nombre
function Set-RoundingRule {
    param (
        [string]$Value,
        [ValidateSet("Round", "Ceiling", "Floor", "Truncate")]
        [string]$Rule,
        [int]$Precision
    )

    # Convertir la valeur en nombre
    $number = [double]$Value

    # Appliquer la règle d'arrondi
    switch ($Rule) {
        "Round" {
            # Arrondi standard (au plus proche)
            return [math]::Round($number, $Precision)
        }
        "Ceiling" {
            # Arrondi au plafond (vers le haut)
            $factor = [math]::Pow(10, $Precision)
            return [math]::Ceiling($number * $factor) / $factor
        }
        "Floor" {
            # Arrondi au plancher (vers le bas)
            $factor = [math]::Pow(10, $Precision)
            return [math]::Floor($number * $factor) / $factor
        }
        "Truncate" {
            # Troncature (suppression des décimales excédentaires)
            $factor = [math]::Pow(10, $Precision)
            return [math]::Truncate($number * $factor) / $factor
        }
    }
}

# Fonction pour appliquer des règles d'arrondi et de troncature
function Get-RoundedValues {
    param (
        [string]$Content,
        [ValidateSet("Round", "Ceiling", "Floor", "Truncate")]
        [string]$DefaultRoundingRule = "Round",
        [int]$DefaultPrecision = 2
    )

    Write-Host "Application des règles d'arrondi et de troncature..." -ForegroundColor Cyan

    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"

    # Initialiser les variables d'analyse
    $tasks = @{}

    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'

    # Pattern pour les tags de règle d'arrondi
    $roundTagPattern = '#round:([a-zA-Z]+):(\d+)'
    $roundParenTagPattern = '#round\(([a-zA-Z]+):(\d+)\)'

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
                    Id            = $taskId
                    RoundedValues = @{
                        TaggedRoundingRules = @()
                        RoundedNumbers      = @()
                    }
                }
            }

            # Extraire les tags de règle d'arrondi
            $roundingRule = $null
            $precision = $null

            # Format #round:rule:precision
            if ($taskLine -match $roundTagPattern) {
                $roundingRule = $matches[1]
                $precision = [int]$matches[2]

                $tasks[$taskId].RoundedValues.TaggedRoundingRules += @{
                    Rule      = $roundingRule
                    Precision = $precision
                    Type      = "RoundingTag"
                    Original  = "#round:${roundingRule}:${precision}"
                }

                Write-Host "Tache ${taskId}: Tag de règle d'arrondi ${roundingRule}:${precision} (#round:${roundingRule}:${precision})" -ForegroundColor Green
            }

            # Format #round(rule:precision)
            if ($taskLine -match $roundParenTagPattern) {
                $roundingRule = $matches[1]
                $precision = [int]$matches[2]

                $tasks[$taskId].RoundedValues.TaggedRoundingRules += @{
                    Rule      = $roundingRule
                    Precision = $precision
                    Type      = "RoundingParenTag"
                    Original  = "#round(${roundingRule}:${precision})"
                }

                Write-Host "Tache ${taskId}: Tag de règle d'arrondi ${roundingRule}:${precision} (#round(${roundingRule}:${precision}))" -ForegroundColor Green
            }

            # Si aucun tag de règle d'arrondi n'a été trouvé, utiliser les valeurs par défaut
            if ($null -eq $roundingRule -or $null -eq $precision) {
                $roundingRule = $DefaultRoundingRule
                $precision = $DefaultPrecision

                Write-Host "Tache ${taskId}: Utilisation de la règle d'arrondi par défaut ${roundingRule}:${precision}" -ForegroundColor Yellow
            }

            # Extraire les nombres décimaux et les arrondir
            # Extraire les nombres décimaux avec point
            $regexMatches = [regex]::Matches($taskLine, $decimalNumberPattern)
            foreach ($match in $regexMatches) {
                $numberValue = $match.Groups[1].Value
                $originalPrecision = ($numberValue -split '\.')[1].Length

                # Appliquer la règle d'arrondi
                $roundedValue = Set-RoundingRule -Value $numberValue -Rule $roundingRule -Precision $precision

                $tasks[$taskId].RoundedValues.RoundedNumbers += @{
                    Value             = $roundedValue
                    Original          = $numberValue
                    OriginalPrecision = $originalPrecision
                    RoundingRule      = $roundingRule
                    Precision         = $precision
                }

                Write-Host "Tache ${taskId}: Nombre arrondi ${roundedValue} (original: ${numberValue}, règle: ${roundingRule}, précision: ${precision})" -ForegroundColor Green
            }

            # Extraire les nombres décimaux avec virgule
            $regexMatches = [regex]::Matches($taskLine, $commaDecimalNumberPattern)
            foreach ($match in $regexMatches) {
                $numberValue = $match.Groups[1].Value
                $normalizedValue = $numberValue -replace ',', '.'
                $originalPrecision = ($normalizedValue -split '\.')[1].Length

                # Appliquer la règle d'arrondi
                $roundedValue = Set-RoundingRule -Value $normalizedValue -Rule $roundingRule -Precision $precision

                $tasks[$taskId].RoundedValues.RoundedNumbers += @{
                    Value             = $roundedValue
                    Original          = $numberValue
                    OriginalPrecision = $originalPrecision
                    RoundingRule      = $roundingRule
                    Precision         = $precision
                }

                Write-Host "Tache ${taskId}: Nombre arrondi ${roundedValue} (original: ${numberValue}, règle: ${roundingRule}, précision: ${precision})" -ForegroundColor Green
            }
        }
    }

    return $tasks
}

# Exécuter la fonction d'application des règles d'arrondi et de troncature
Write-Host "Test des règles d'arrondi et de troncature..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$roundedValues = Get-RoundedValues -Content $testContent -DefaultRoundingRule "Round" -DefaultPrecision 2

# Afficher les résultats
Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
Write-Host "- Taches avec tags de règle d'arrondi: $(($roundedValues.Values | Where-Object { $_.RoundedValues.TaggedRoundingRules.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Taches avec nombres arrondis: $(($roundedValues.Values | Where-Object { $_.RoundedValues.RoundedNumbers.Count -gt 0 }).Count)" -ForegroundColor Yellow
Write-Host "- Taches sans tags de règle d'arrondi (utilisant la règle par défaut): $(($roundedValues.Values | Where-Object { $_.RoundedValues.TaggedRoundingRules.Count -eq 0 -and $_.RoundedValues.RoundedNumbers.Count -gt 0 }).Count)" -ForegroundColor Yellow

Write-Host "`nTest terminé." -ForegroundColor Cyan
