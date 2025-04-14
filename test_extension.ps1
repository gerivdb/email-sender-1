# Fichier de test pour l'extension Error Pattern Analyzer

# 1. Référence nulle - L'extension devrait détecter une référence potentiellement nulle
$user = $null
$name = $user.Name  # Erreur potentielle : référence nulle
Write-Host "Nom de l'utilisateur : $name"

# 2. Index hors limites - L'extension devrait détecter un accès potentiel hors des limites du tableau
$array = @(1, 2, 3)
$arrayValue = $array[5]  # Erreur potentielle : index hors limites
Write-Host "Valeur du tableau : $arrayValue"

# 3. Conversion de type - L'extension devrait détecter une conversion de type potentiellement invalide
$userInput = "abc"
$convertedNumber = [int]$userInput  # Erreur potentielle : conversion de type
Write-Host "Nombre converti : $convertedNumber"

# 4. Variable non initialisée - L'extension devrait détecter l'utilisation d'une variable non initialisée
$calculatedResult = $total + 10  # Erreur potentielle : $total n'est pas initialisé
Write-Host "Résultat calculé : $calculatedResult"

# 5. Division par zéro - L'extension devrait détecter une division potentielle par zéro
$divisor = 0
$divisionResult = 10 / $divisor  # Erreur potentielle : division par zéro
Write-Host "Résultat de la division : $divisionResult"

# 6. Accès à un membre inexistant - L'extension devrait détecter l'accès à une propriété inexistante
$obj = New-Object PSObject
$propertyValue = $obj.MissingProperty  # Erreur potentielle : propriété inexistante
Write-Host "Valeur de la propriété : $propertyValue"

# 7. Appel de fonction avec des paramètres incorrects - L'extension devrait détecter un paramètre obligatoire manquant
function Test-Function {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    Write-Host "Hello, $Name!"
}

Test-Function  # Erreur potentielle : paramètre obligatoire manquant

# 8. Utilisation d'une commande inexistante - L'extension devrait détecter une commande inexistante
try {
    Invoke-NonExistentCommand  # Erreur potentielle : commande inexistante
} catch {
    Write-Host "Erreur attendue : $($_.Exception.Message)"
}

# 9. Utilisation d'un opérateur de comparaison incorrect - L'extension devrait détecter un opérateur de comparaison incorrect
$testValue = 5
if ($testValue = 10) {
    # Erreur potentielle : utilisation de = au lieu de -eq
    Write-Host "Value is 10"
}
Write-Host "Valeur après l'assignation incorrecte : $testValue"

# 10. Utilisation d'une variable dans une chaîne sans guillemets doubles - L'extension devrait détecter une variable non interpolée
$welcomeMessage = 'Hello, $name!'  # Erreur potentielle : variable non interpolée dans une chaîne avec guillemets simples
Write-Host "Message de bienvenue : $welcomeMessage"
