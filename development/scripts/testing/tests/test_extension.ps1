# Fichier de test pour l'extension Error Pattern Analyzer

# 1. RÃ©fÃ©rence nulle - L'extension devrait dÃ©tecter une rÃ©fÃ©rence potentiellement nulle
$user = $null
$name = $user.Name  # Erreur potentielle : rÃ©fÃ©rence nulle
Write-Host "Nom de l'utilisateur : $name"

# 2. Index hors limites - L'extension devrait dÃ©tecter un accÃ¨s potentiel hors des limites du tableau
$array = @(1, 2, 3)
$arrayValue = $array[5]  # Erreur potentielle : index hors limites
Write-Host "Valeur du tableau : $arrayValue"

# 3. Conversion de type - L'extension devrait dÃ©tecter une conversion de type potentiellement invalide
$userInput = "abc"
$convertedNumber = [int]$userInput  # Erreur potentielle : conversion de type
Write-Host "Nombre converti : $convertedNumber"

# 4. Variable non initialisÃ©e - L'extension devrait dÃ©tecter l'utilisation d'une variable non initialisÃ©e
$calculatedResult = $total + 10  # Erreur potentielle : $total n'est pas initialisÃ©
Write-Host "RÃ©sultat calculÃ© : $calculatedResult"

# 5. Division par zÃ©ro - L'extension devrait dÃ©tecter une division potentielle par zÃ©ro
$divisor = 0
$divisionResult = 10 / $divisor  # Erreur potentielle : division par zÃ©ro
Write-Host "RÃ©sultat de la division : $divisionResult"

# 6. AccÃ¨s Ã  un membre inexistant - L'extension devrait dÃ©tecter l'accÃ¨s Ã  une propriÃ©tÃ© inexistante
$obj = New-Object PSObject
$propertyValue = $obj.MissingProperty  # Erreur potentielle : propriÃ©tÃ© inexistante
Write-Host "Valeur de la propriÃ©tÃ© : $propertyValue"

# 7. Appel de fonction avec des paramÃ¨tres incorrects - L'extension devrait dÃ©tecter un paramÃ¨tre obligatoire manquant
function Test-Function {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    Write-Host "Hello, $Name!"
}

Test-Function  # Erreur potentielle : paramÃ¨tre obligatoire manquant

# 8. Utilisation d'une commande inexistante - L'extension devrait dÃ©tecter une commande inexistante
try {
    Invoke-NonExistentCommand  # Erreur potentielle : commande inexistante
} catch {
    Write-Host "Erreur attendue : $($_.Exception.Message)"
}

# 9. Utilisation d'un opÃ©rateur de comparaison incorrect - L'extension devrait dÃ©tecter un opÃ©rateur de comparaison incorrect
$testValue = 5
if ($testValue = 10) {
    # Erreur potentielle : utilisation de = au lieu de -eq
    Write-Host "Value is 10"
}
Write-Host "Valeur aprÃ¨s l'assignation incorrecte : $testValue"

# 10. Utilisation d'une variable dans une chaÃ®ne sans guillemets doubles - L'extension devrait dÃ©tecter une variable non interpolÃ©e
$welcomeMessage = 'Hello, $name!'  # Erreur potentielle : variable non interpolÃ©e dans une chaÃ®ne avec guillemets simples
Write-Host "Message de bienvenue : $welcomeMessage"
