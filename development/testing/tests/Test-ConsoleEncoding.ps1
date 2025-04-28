# Script pour tester l'encodage de la console PowerShell

# Configurer l'encodage de la console
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Afficher les informations d'encodage
Write-Host "Informations sur l'encodage de la console :"
Write-Host "Console::OutputEncoding = $([Console]::OutputEncoding.WebName)"
Write-Host "OutputEncoding = $($OutputEncoding.WebName)"
Write-Host "PSDefaultParameterValues['Out-File:Encoding'] = $($PSDefaultParameterValues['Out-File:Encoding'])"
Write-Host ""

# Tester l'affichage des caractères accentués
Write-Host "Test d'affichage des caractères accentués :"
Write-Host "é è ê ë à â ù ü ç"
Write-Host "É È Ê Ë À Â Ù Ü Ç"
Write-Host ""

# Tester l'affichage des caractères accentués avec Write-Output
Write-Host "Test d'affichage des caractères accentués avec Write-Output :"
Write-Output "é è ê ë à â ù ü ç"
Write-Output "É È Ê Ë À Â Ù Ü Ç"
Write-Host ""

# Tester l'affichage des caractères accentués avec Out-File et Get-Content
$testFile = Join-Path -Path $PSScriptRoot -ChildPath "test_encoding.txt"
"é è ê ë à â ù ü ç" | Out-File -FilePath $testFile -Encoding utf8
"É È Ê Ë À Â Ù Ü Ç" | Out-File -FilePath $testFile -Encoding utf8 -Append

Write-Host "Contenu du fichier test_encoding.txt :"
Get-Content -Path $testFile
Write-Host ""

# Tester l'affichage des caractères accentués avec [System.IO.File]::WriteAllText et [System.IO.File]::ReadAllText
$testFile2 = Join-Path -Path $PSScriptRoot -ChildPath "test_encoding2.txt"
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($testFile2, "é è ê ë à â ù ü ç`r`nÉ È Ê Ë À Â Ù Ü Ç", $utf8WithBom)

Write-Host "Contenu du fichier test_encoding2.txt :"
[System.IO.File]::ReadAllText($testFile2)
Write-Host ""

# Tester l'affichage des caractères accentués avec chcp
Write-Host "Test d'affichage des caractères accentués avec chcp :"
Write-Host "Exécution de chcp 65001 (UTF-8) :"
cmd /c "chcp 65001 && echo é è ê ë à â ù ü ç && echo É È Ê Ë À Â Ù Ü Ç"
Write-Host ""

# Nettoyer les fichiers de test
Remove-Item -Path $testFile -Force
Remove-Item -Path $testFile2 -Force

Write-Host "Test d'encodage terminé"
