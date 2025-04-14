# Fichier de test pour les tests unitaires

# 1. Référence nulle
$user = $null
$name = $user.Name  # Erreur potentielle : référence nulle

# 2. Index hors limites
$array = @(1, 2, 3)
$value = $array[5]  # Erreur potentielle : index hors limites

# 3. Conversion de type
$userInput = "abc"
$number = [int]$userInput  # Erreur potentielle : conversion de type

# 4. Variable non initialisée
$result = $total + 10  # Erreur potentielle : $total n'est pas initialisé

# 5. Division par zéro
$divisor = 0
$quotient = 10 / $divisor  # Erreur potentielle : division par zéro
