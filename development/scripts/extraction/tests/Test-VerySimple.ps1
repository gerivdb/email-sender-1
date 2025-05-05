# Script de test trÃ¨s simple
Write-Host "Test simple en cours d'exÃ©cution..."

# DÃ©finir une fonction simple
function Test-Function {
    param (
        [string]$Message = "Hello, World!"
    )
    
    Write-Host $Message
}

# Appeler la fonction
Test-Function

Write-Host "Test terminÃ© avec succÃ¨s!" -ForegroundColor Green
