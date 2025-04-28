# Script de test simple
Write-Host "Test simple exÃ©cutÃ© avec succÃ¨s"
Write-Host "RÃ©pertoire courant : $(Get-Location)"
Write-Host "Fichiers dans le rÃ©pertoire courant :"
Get-ChildItem | Select-Object Name, Length | Format-Table
