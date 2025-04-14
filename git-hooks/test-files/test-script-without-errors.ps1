# Script de test sans erreurs potentielles pour tester le hook pre-commit

# 1. Référence nulle (corrigée)
$user = $null
if ($user -ne $null) {
    $name = $user.Name
} else {
    $name = "Inconnu"
}

# 2. Index hors limites (corrigé)
$array = @(1, 2, 3)
if ($array.Length -gt 5) {
    $value = $array[5]
} else {
    $value = $array[$array.Length - 1]
}

# 3. Conversion de type (corrigée)
$userInput = "123"
if ($userInput -as [int]) {
    $number = [int]$userInput
} else {
    $number = 0
}

# 4. Variable non initialisée (corrigée)
$total = 0
$result = $total + 10

# 5. Division par zéro (corrigée)
$divisor = 0
if ($divisor -ne 0) {
    $quotient = 10 / $divisor
} else {
    $quotient = 0
}

# 6. Accès à un membre inexistant (corrigé)
$obj = New-Object PSObject -Property @{
    Name = "Test"
}
$value = $obj.Name

# 7. Appel de fonction avec des paramètres incorrects (corrigé)
function Test-Function {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    Write-Host "Hello, $Name!"
}

Test-Function -Name "John"
