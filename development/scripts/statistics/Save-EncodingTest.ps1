# Encoding: UTF-8 with BOM
#Requires -Version 5.1

# Chemin du fichier de sortie
$outputFile = Join-Path -Path $PSScriptRoot -ChildPath "encoding-test-results.txt"

# Créer un StringBuilder pour stocker les résultats
$output = New-Object System.Text.StringBuilder

# Ajouter des informations sur l'encodage
$output.AppendLine("=== Informations sur l'encodage ===") | Out-Null
$output.AppendLine("Encodage de la console en entree: $([Console]::InputEncoding.WebName)") | Out-Null
$output.AppendLine("Encodage de la console en sortie: $([Console]::OutputEncoding.WebName)") | Out-Null
$output.AppendLine("Encodage par defaut: $([System.Text.Encoding]::Default.WebName)") | Out-Null
$output.AppendLine("Page de code active: $([System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ANSICodePage)") | Out-Null
$output.AppendLine() | Out-Null

# Ajouter des tests d'affichage des caractères ASCII
$output.AppendLine("=== Test d'affichage des caracteres ASCII ===") | Out-Null
$output.AppendLine("ABCDEFGHIJKLMNOPQRSTUVWXYZ") | Out-Null
$output.AppendLine("abcdefghijklmnopqrstuvwxyz") | Out-Null
$output.AppendLine("0123456789") | Out-Null
$output.AppendLine("!@#$%^&*()_+-=[]{}|;:,.<>/?") | Out-Null
$output.AppendLine() | Out-Null

# Ajouter des tests d'affichage des caractères accentués
$output.AppendLine("=== Test d'affichage des caracteres accentues ===") | Out-Null
$output.AppendLine("àáâäæãåā èéêëēėę îïíīįì ôöòóœøōõ ûüùúū ÿ çćč ñń") | Out-Null
$output.AppendLine("ÀÁÂÄÆÃÅĀ ÈÉÊËĒĖĘ ÎÏÍĪĮÌ ÔÖÒÓŒØŌÕ ÛÜÙÚŪ Ÿ ÇĆČ ÑŃ") | Out-Null
$output.AppendLine() | Out-Null

# Ajouter des tests d'affichage des termes utilisés dans le module
$output.AppendLine("=== Test d'affichage des termes du module ===") | Out-Null
$output.AppendLine("Metriques de qualite pour les tests d'hypotheses") | Out-Null
$output.AppendLine("Criteres de puissance statistique") | Out-Null
$output.AppendLine("Metriques de controle des erreurs de type I et II") | Out-Null
$output.AppendLine("Criteres de robustesse pour les tests parametriques et non-parametriques") | Out-Null
$output.AppendLine("Metriques d'efficacite computationnelle") | Out-Null
$output.AppendLine("Recherche exploratoire, Recherche standard, Recherche clinique") | Out-Null
$output.AppendLine("Recherche critique, Recherche de haute precision") | Out-Null
$output.AppendLine("Equilibre, Biaise vers l'erreur de type I, Biaise vers l'erreur de type II") | Out-Null
$output.AppendLine() | Out-Null

# Ajouter un message de fin
$output.AppendLine("Test d'encodage termine.") | Out-Null

# Écrire les résultats dans un fichier avec l'encodage UTF-8 avec BOM
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($outputFile, $output.ToString(), $utf8WithBom)

# Afficher un message de confirmation
Write-Host "Les resultats du test d'encodage ont ete enregistres dans le fichier: $outputFile" -ForegroundColor Green
