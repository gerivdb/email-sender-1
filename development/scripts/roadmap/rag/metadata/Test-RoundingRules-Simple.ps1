# Test-RoundingRules-Simple.ps1
# Script simplifié pour tester les règles d'arrondi et de troncature
# Version: 1.0
# Date: 2025-05-15

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

# Tester les différentes règles d'arrondi
Write-Host "Test des règles d'arrondi et de troncature..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Valeurs de test
$testValues = @(
    @{ Value = "3.14159"; Rule = "Round"; Precision = 2 },
    @{ Value = "3.14159"; Rule = "Ceiling"; Precision = 2 },
    @{ Value = "3.14159"; Rule = "Floor"; Precision = 2 },
    @{ Value = "3.14159"; Rule = "Truncate"; Precision = 2 },
    @{ Value = "2.71828"; Rule = "Round"; Precision = 3 },
    @{ Value = "2.71828"; Rule = "Ceiling"; Precision = 3 },
    @{ Value = "2.71828"; Rule = "Floor"; Precision = 3 },
    @{ Value = "2.71828"; Rule = "Truncate"; Precision = 3 }
)

# Appliquer les règles d'arrondi
foreach ($test in $testValues) {
    $value = $test.Value
    $rule = $test.Rule
    $precision = $test.Precision
    
    $result = Set-RoundingRule -Value $value -Rule $rule -Precision $precision
    
    Write-Host "Valeur: $value, Règle: $rule, Précision: $precision => Résultat: $result" -ForegroundColor Green
}

Write-Host "`nTest terminé." -ForegroundColor Cyan
