# Fichier de test pour l'extension Error Pattern Analyzer

# 1. Référence nulle
$user = $null
$name = $user.Name  # Erreur potentielle : référence nulle

# 2. Index hors limites
$array = @(1, 2, 3)
$value = $array[5]  # Erreur potentielle : index hors limites

# 3. Conversion de type
$input = "abc"
$number = [int]$input  # Erreur potentielle : conversion de type

# 4. Variable non initialisée
$result = $total + 10  # Erreur potentielle : $total n'est pas initialisé

# 5. Division par zéro
$divisor = 0
$quotient = 10 / $divisor  # Erreur potentielle : division par zéro

# 6. Accès à un membre inexistant
$obj = New-Object PSObject
$value = $obj.MissingProperty  # Erreur potentielle : propriété inexistante

# 7. Appel de fonction avec des paramètres incorrects
function Test-Function {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    Write-Host "Hello, $Name!"
}

Test-Function  # Erreur potentielle : paramètre obligatoire manquant
