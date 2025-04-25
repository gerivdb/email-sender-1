# Script avec erreurs

# Fonction mal nommÃ©e
function badFunction {
    param($input)
    
    # Variable non dÃ©clarÃ©e
    $result = $undeclaredVar + 10
    
    return $result
}

# Boucle while infinie (commentÃ©e pour Ã©viter les problÃ¨mes)
# while ($true) {
#     Write-Host "Boucle infinie"
# }

# Appel de fonction inexistante
# NonExistentFunction

# Syntaxe incorrecte
if ($x = 10) {
    Write-Output "Erreur de syntaxe"
}
