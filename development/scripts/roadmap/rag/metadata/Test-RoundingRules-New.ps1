# Test-RoundingRules-New.ps1
# Script pour tester les règles d'arrondi et de troncature
# Version: 1.0
# Date: 2025-05-15

# Fonction pour appliquer une règle d'arrondi à un nombre
function Set-RoundingRule {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Value,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Round", "Ceiling", "Floor", "Truncate")]
        [string]$Rule,

        [Parameter(Mandatory = $true)]
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

# Fonction pour extraire les règles d'arrondi des tags
function Get-RoundingRuleFromTag {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskLine,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Round", "Ceiling", "Floor", "Truncate")]
        [string]$DefaultRule = "Round",

        [Parameter(Mandatory = $false)]
        [int]$DefaultPrecision = 2
    )

    # Pattern pour les tags de règle d'arrondi
    $roundTagPattern = '#round:([a-zA-Z]+):(\d+)'
    $roundParenTagPattern = '#round\(([a-zA-Z]+):(\d+)\)'

    $roundingRule = $DefaultRule
    $precision = $DefaultPrecision
    $tagFound = $false

    # Format #round:rule:precision
    if ($TaskLine -match $roundTagPattern) {
        $roundingRule = $matches[1]
        $precision = [int]$matches[2]
        $tagFound = $true
    }
    # Format #round(rule:precision)
    elseif ($TaskLine -match $roundParenTagPattern) {
        $roundingRule = $matches[1]
        $precision = [int]$matches[2]
        $tagFound = $true
    }

    return @{
        Rule      = $roundingRule
        Precision = $precision
        TagFound  = $tagFound
    }
}

# Fonction pour extraire et arrondir les nombres dans une ligne
function Get-RoundedNumbers {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskLine,

        [Parameter(Mandatory = $true)]
        [string]$Rule,

        [Parameter(Mandatory = $true)]
        [int]$Precision
    )

    # Pattern pour les nombres décimaux
    $decimalNumberPattern = '(\d+\.\d+)'
    $commaDecimalNumberPattern = '(\d+,\d+)'

    $roundedNumbers = @()

    # Extraire les nombres décimaux avec point
    $regexMatches = [regex]::Matches($TaskLine, $decimalNumberPattern)
    foreach ($match in $regexMatches) {
        $numberValue = $match.Groups[1].Value
        $originalPrecision = ($numberValue -split '\.')[1].Length

        # Appliquer la règle d'arrondi
        $roundedValue = Set-RoundingRule -Value $numberValue -Rule $Rule -Precision $Precision

        $roundedNumbers += @{
            Value             = $roundedValue
            Original          = $numberValue
            OriginalPrecision = $originalPrecision
            RoundingRule      = $Rule
            Precision         = $Precision
        }
    }

    # Extraire les nombres décimaux avec virgule
    $regexMatches = [regex]::Matches($TaskLine, $commaDecimalNumberPattern)
    foreach ($match in $regexMatches) {
        $numberValue = $match.Groups[1].Value
        $normalizedValue = $numberValue -replace ',', '.'
        $originalPrecision = ($normalizedValue -split '\.')[1].Length

        # Appliquer la règle d'arrondi
        $roundedValue = Set-RoundingRule -Value $normalizedValue -Rule $Rule -Precision $Precision

        $roundedNumbers += @{
            Value             = $roundedValue
            Original          = $numberValue
            OriginalPrecision = $originalPrecision
            RoundingRule      = $Rule
            Precision         = $Precision
        }
    }

    return $roundedNumbers
}

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

# Fonction principale pour tester les règles d'arrondi
function Test-RoundingRules {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Round", "Ceiling", "Floor", "Truncate")]
        [string]$DefaultRule = "Round",

        [Parameter(Mandatory = $false)]
        [int]$DefaultPrecision = 2
    )

    Write-Host "Test des règles d'arrondi et de troncature..." -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan

    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"

    # Pattern pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'

    # Initialiser les variables d'analyse
    $tasks = @{}
    $tasksWithTags = 0
    $tasksWithNumbers = 0
    $tasksWithDefaultRule = 0

    # Analyser chaque ligne
    foreach ($line in $lines) {
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line

            # Extraire les règles d'arrondi des tags
            $roundingRuleInfo = Get-RoundingRuleFromTag -TaskLine $taskLine -DefaultRule $DefaultRule -DefaultPrecision $DefaultPrecision
            $roundingRule = $roundingRuleInfo.Rule
            $precision = $roundingRuleInfo.Precision

            if ($roundingRuleInfo.TagFound) {
                Write-Host "Tache ${taskId}: Tag de règle d'arrondi ${roundingRule}:${precision}" -ForegroundColor Green
                $tasksWithTags++
            } else {
                Write-Host "Tache ${taskId}: Utilisation de la règle d'arrondi par défaut ${roundingRule}:${precision}" -ForegroundColor Yellow
                $tasksWithDefaultRule++
            }

            # Extraire et arrondir les nombres
            $roundedNumbers = Get-RoundedNumbers -TaskLine $taskLine -Rule $roundingRule -Precision $precision

            if ($roundedNumbers.Count -gt 0) {
                $tasksWithNumbers++

                foreach ($number in $roundedNumbers) {
                    Write-Host "Tache ${taskId}: Nombre arrondi $($number.Value) (original: $($number.Original), règle: $($number.RoundingRule), précision: $($number.Precision))" -ForegroundColor Green
                }
            }

            # Ajouter la tâche aux résultats
            $tasks[$taskId] = @{
                Id             = $taskId
                RoundingRule   = $roundingRule
                Precision      = $precision
                TagFound       = $roundingRuleInfo.TagFound
                RoundedNumbers = $roundedNumbers
            }
        }
    }

    # Afficher les résultats
    Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
    Write-Host "- Taches avec tags de règle d'arrondi: ${tasksWithTags}" -ForegroundColor Yellow
    Write-Host "- Taches avec nombres arrondis: ${tasksWithNumbers}" -ForegroundColor Yellow
    Write-Host "- Taches sans tags de règle d'arrondi (utilisant la règle par défaut): ${tasksWithDefaultRule}" -ForegroundColor Yellow

    Write-Host "`nTest terminé." -ForegroundColor Cyan

    return $tasks
}

# Exécuter le test
Test-RoundingRules -Content $testContent -DefaultRule "Round" -DefaultPrecision 2
