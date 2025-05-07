# Encoding: UTF-8 with BOM
#Requires -Version 5.1
<#
.SYNOPSIS
    Teste l'affichage des caractères accentués.

.DESCRIPTION
    Ce script teste l'affichage des caractères accentués dans la console PowerShell.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-05-15
#>

# Définir l'encodage de sortie en UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Afficher des informations sur l'encodage
Write-Host "=== Informations sur l'encodage ===" -ForegroundColor Cyan
Write-Host "Encodage de la console en entrée: $([Console]::InputEncoding.WebName)" -ForegroundColor Yellow
Write-Host "Encodage de la console en sortie: $([Console]::OutputEncoding.WebName)" -ForegroundColor Yellow
Write-Host "Encodage par défaut: $([System.Text.Encoding]::Default.WebName)" -ForegroundColor Yellow
Write-Host "Page de code active: $([System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ANSICodePage)" -ForegroundColor Yellow
Write-Host ""

# Tester l'affichage des caractères accentués
Write-Host "=== Test d'affichage des caractères accentués ===" -ForegroundColor Cyan
Write-Host "àáâäæãåā èéêëēėę îïíīįì ôöòóœøōõ ûüùúū ÿ çćč ñń" -ForegroundColor Green
Write-Host "ÀÁÂÄÆÃÅĀ ÈÉÊËĒĖĘ ÎÏÍĪĮÌ ÔÖÒÓŒØŌÕ ÛÜÙÚŪ Ÿ ÇĆČ ÑŃ" -ForegroundColor Green
Write-Host ""

# Tester l'affichage des termes utilisés dans le module
Write-Host "=== Test d'affichage des termes du module ===" -ForegroundColor Cyan
Write-Host "Métriques de qualité pour les tests d'hypothèses" -ForegroundColor Green
Write-Host "Critères de puissance statistique" -ForegroundColor Green
Write-Host "Métriques de contrôle des erreurs de type I et II" -ForegroundColor Green
Write-Host "Critères de robustesse pour les tests paramétriques et non-paramétriques" -ForegroundColor Green
Write-Host "Métriques d'efficacité computationnelle" -ForegroundColor Green
Write-Host "Recherche exploratoire, Recherche standard, Recherche clinique" -ForegroundColor Green
Write-Host "Recherche critique, Recherche de haute précision" -ForegroundColor Green
Write-Host "Équilibré, Biaisé vers l'erreur de type I, Biaisé vers l'erreur de type II" -ForegroundColor Green
Write-Host ""

# Tester l'affichage des caractères spéciaux
Write-Host "=== Test d'affichage des caractères spéciaux ===" -ForegroundColor Cyan
Write-Host "€ £ ¥ © ® ™ ° ± × ÷ µ ¶ § ¿ ¡ « » " " ' '" -ForegroundColor Green
Write-Host ""

# Afficher un message de fin
Write-Host "Test d'encodage termine." -ForegroundColor Cyan
