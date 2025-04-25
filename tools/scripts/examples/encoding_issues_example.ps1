# Exemple de script avec des problÃ¨mes potentiels d'encodage
# Ce script contient des rÃ©fÃ©rences de variables dans des chaÃ®nes accentuÃ©es

# ProblÃ¨me 1: Variable dans une chaÃ®ne avec caractÃ¨res accentuÃ©s
$nomUtilisateur = "Jean"
$message + ' = "Bonjour ' + $nomUtilisateur + ', bienvenue Ã  l'application!"

# ProblÃ¨me 2: Variable avec nom accentuÃ©
$r + 'Ã©sultat = 42
Write-Host "Le rÃ©sultat est: ' + $r + 'Ã©sultat"

# ProblÃ¨me 3: ConcatÃ©nation avec des caractÃ¨res accentuÃ©s
$chemin + ' = "C:\DonnÃ©es\"
$fichier + ' = ' + $chemin + ' + "rÃ©sultats.txt"

# ProblÃ¨me 4: Variable dans une chaÃ®ne multiligne avec accents
$texteMultiligne = @"
Ceci est un texte avec des caractÃ¨res accentuÃ©s:
- PremiÃ¨re ligne: ' + $nomUtilisateur
- DeuxiÃ¨me ligne: Ã©Ã¨ÃªÃ«
- TroisiÃ¨me ligne: Ã Ã¢Ã¤
- Valeur: ' + $r + 'Ã©sultat
"@

# Cas sans problÃ¨me: ChaÃ®ne avec accents mais sans variable
$texteSimple + ' = "Voici des caractÃ¨res accentuÃ©s: Ã©Ã¨ÃªÃ«Ã Ã¢Ã¤Ã¹Ã»Ã¼Ã´Ã¶"

# Cas sans problÃ¨me: Variable sans accent Ã  proximitÃ©
$value = 100
$text + ' = "Value: ' + $value + ' (pas d'accent Ã  proximitÃ©)"
