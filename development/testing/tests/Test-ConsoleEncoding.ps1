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

# Tester l'affichage des caractÃ¨res accentuÃ©s
Write-Host "Test d'affichage des caractÃ¨res accentuÃ©s :"
Write-Host "Ã© Ã¨ Ãª Ã« Ã  Ã¢ Ã¹ Ã¼ Ã§"
Write-Host "Ã‰ Ãˆ ÃŠ Ã‹ Ã€ Ã‚ Ã™ Ãœ Ã‡"
Write-Host ""

# Tester l'affichage des caractÃ¨res accentuÃ©s avec Write-Output
Write-Host "Test d'affichage des caractÃ¨res accentuÃ©s avec Write-Output :"
Write-Output "Ã© Ã¨ Ãª Ã« Ã  Ã¢ Ã¹ Ã¼ Ã§"
Write-Output "Ã‰ Ãˆ ÃŠ Ã‹ Ã€ Ã‚ Ã™ Ãœ Ã‡"
Write-Host ""

# Tester l'affichage des caractÃ¨res accentuÃ©s avec Out-File et Get-Content
$testFile = Join-Path -Path $PSScriptRoot -ChildPath "test_encoding.txt"
"Ã© Ã¨ Ãª Ã« Ã  Ã¢ Ã¹ Ã¼ Ã§" | Out-File -FilePath $testFile -Encoding utf8
"Ã‰ Ãˆ ÃŠ Ã‹ Ã€ Ã‚ Ã™ Ãœ Ã‡" | Out-File -FilePath $testFile -Encoding utf8 -Append

Write-Host "Contenu du fichier test_encoding.txt :"
Get-Content -Path $testFile
Write-Host ""

# Tester l'affichage des caractÃ¨res accentuÃ©s avec [System.IO.File]::WriteAllText et [System.IO.File]::ReadAllText
$testFile2 = Join-Path -Path $PSScriptRoot -ChildPath "test_encoding2.txt"
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($testFile2, "Ã© Ã¨ Ãª Ã« Ã  Ã¢ Ã¹ Ã¼ Ã§`r`nÃ‰ Ãˆ ÃŠ Ã‹ Ã€ Ã‚ Ã™ Ãœ Ã‡", $utf8WithBom)

Write-Host "Contenu du fichier test_encoding2.txt :"
[System.IO.File]::ReadAllText($testFile2)
Write-Host ""

# Tester l'affichage des caractÃ¨res accentuÃ©s avec chcp
Write-Host "Test d'affichage des caractÃ¨res accentuÃ©s avec chcp :"
Write-Host "ExÃ©cution de chcp 65001 (UTF-8) :"
cmd /c "chcp 65001 && echo Ã© Ã¨ Ãª Ã« Ã  Ã¢ Ã¹ Ã¼ Ã§ && echo Ã‰ Ãˆ ÃŠ Ã‹ Ã€ Ã‚ Ã™ Ãœ Ã‡"
Write-Host ""

# Nettoyer les fichiers de test
Remove-Item -Path $testFile -Force
Remove-Item -Path $testFile2 -Force

Write-Host "Test d'encodage terminÃ©"
