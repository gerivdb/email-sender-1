# Test-DirectDecimal.ps1
# Script de test direct pour l'extraction des valeurs d'estimation décimales
# Version: 1.0
# Date: 2025-05-15

# Définir un exemple de texte contenant des expressions d'estimation avec des valeurs décimales
$testText = @"
Cette tâche prendra environ 3,5 jours.
Le développement durera à peu près 2.5 semaines.
La mise en place devrait prendre plus ou moins 5,5 heures.
Cette fonctionnalité nécessitera autour de 10.25 jours de travail.
Le temps de développement est estimé à 4,75 jours.
"@

# Fonction pour extraire les valeurs d'estimation décimales
function Get-DecimalEstimationValues {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text
    )
    
    $results = @()
    
    # Définir les patterns pour trouver les valeurs numériques décimales suivies d'unités de temps
    $patterns = @(
        # Nombre avec virgule + unité (ex: 3,5 jours)
        '(\d+,\d+)\s+(jours?)'
        # Nombre avec point + unité (ex: 3.5 jours)
        '(\d+\.\d+)\s+(jours?)'
        # Nombre avec virgule + unité (ex: 5,5 heures)
        '(\d+,\d+)\s+(heures?)'
        # Nombre avec point + unité (ex: 5.5 heures)
        '(\d+\.\d+)\s+(heures?)'
        # Nombre avec virgule + unité (ex: 2,5 semaines)
        '(\d+,\d+)\s+(semaines?)'
        # Nombre avec point + unité (ex: 2.5 semaines)
        '(\d+\.\d+)\s+(semaines?)'
    )
    
    # Parcourir chaque pattern
    foreach ($pattern in $patterns) {
        $matchResults = [regex]::Matches($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        foreach ($match in $matchResults) {
            $value = $match.Groups[1].Value
            $unit = $match.Groups[2].Value.ToLower().Trim()
            
            # Convertir la valeur en nombre
            $numericValue = 0
            if ($value -match ",") {
                $value = $value -replace ",", "."
            }
            
            if ([double]::TryParse($value, [ref]$numericValue)) {
                # Déterminer l'unité de temps et le multiplicateur
                $normalizedUnit = $unit
                $multiplier = 1
                
                # Unités en français
                switch -Regex ($unit) {
                    '^h(eure)?s?$' { $normalizedUnit = "heure"; $multiplier = 1 }
                    '^j(our)?s?$' { $normalizedUnit = "jour"; $multiplier = 8 }
                    '^s(emaine)?s?$' { $normalizedUnit = "semaine"; $multiplier = 40 }
                }
                
                # Calculer la valeur en heures
                $hoursValue = $numericValue * $multiplier
                
                # Déterminer la catégorie d'estimation
                $category = "precise"
                
                # Vérifier si l'expression est dans un contexte approximatif
                $contextStart = [Math]::Max(0, $match.Index - 20)
                $contextLength = [Math]::Min($Text.Length - $contextStart, $match.Index - $contextStart + $match.Length + 20)
                $context = $Text.Substring($contextStart, $contextLength)
                
                if ($context -match "(environ|approximativement|à peu près|autour de|aux alentours de|plus ou moins|±|~)") {
                    $category = "approximate"
                }
                
                $result = [PSCustomObject]@{
                    Category = $category
                    Value = $numericValue
                    Unit = $normalizedUnit
                    HoursValue = $hoursValue
                    Context = $context
                }
                
                $results += $result
            }
        }
    }
    
    return $results
}

# Extraire les valeurs d'estimation décimales
$results = Get-DecimalEstimationValues -Text $testText

# Afficher les résultats
Write-Host "Résultats de l'extraction des valeurs d'estimation décimales:" -ForegroundColor Cyan
Write-Host "Nombre total de valeurs trouvées: $($results.Count)" -ForegroundColor Green
Write-Host ""

foreach ($result in $results) {
    Write-Host "Valeur: $($result.Value) $($result.Unit) (= $($result.HoursValue) heures)" -ForegroundColor Gray
    Write-Host "Catégorie: $($result.Category)" -ForegroundColor Gray
    Write-Host "Contexte: $($result.Context)" -ForegroundColor Gray
    Write-Host ""
}
