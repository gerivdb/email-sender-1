# Test avec des commandes PowerShell de base
Write-Host "Test de base en cours d'exÃ©cution..."

# Afficher des informations sur l'environnement
Write-Host "Version PowerShell: $($PSVersionTable.PSVersion)"
Write-Host "RÃ©pertoire courant: $(Get-Location)"

# CrÃ©er un objet simple
$obj = New-Object -TypeName PSObject -Property @{
    Name = "Test"
    Value = 123
}

Write-Host "Objet crÃ©Ã©: $($obj.Name), $($obj.Value)"

Write-Host "Test terminÃ© avec succÃ¨s!" -ForegroundColor Green
