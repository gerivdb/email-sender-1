# Encoding: UTF-8 with BOM
#Requires -Version 5.1

# Definir l'encodage de sortie en UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Afficher des informations sur l'encodage
Write-Host "=== Informations sur l'encodage ===" -ForegroundColor Cyan
Write-Host "Encodage de la console en entree: $([Console]::InputEncoding.WebName)" -ForegroundColor Yellow
Write-Host "Encodage de la console en sortie: $([Console]::OutputEncoding.WebName)" -ForegroundColor Yellow
Write-Host "Encodage par defaut: $([System.Text.Encoding]::Default.WebName)" -ForegroundColor Yellow
Write-Host "Page de code active: $([System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ANSICodePage)" -ForegroundColor Yellow
Write-Host ""

# Tester l'affichage des caracteres ASCII
Write-Host "=== Test d'affichage des caracteres ASCII ===" -ForegroundColor Cyan
Write-Host "ABCDEFGHIJKLMNOPQRSTUVWXYZ" -ForegroundColor Green
Write-Host "abcdefghijklmnopqrstuvwxyz" -ForegroundColor Green
Write-Host "0123456789" -ForegroundColor Green
Write-Host "!@#$%^&*()_+-=[]{}|;:,.<>/?" -ForegroundColor Green
Write-Host ""

# Afficher un message de fin
Write-Host "Test d'encodage termine." -ForegroundColor Cyan
