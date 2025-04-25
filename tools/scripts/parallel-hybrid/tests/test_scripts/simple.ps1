#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test simple.
.DESCRIPTION
    Ce script est utilisÃ© pour tester l'analyseur de scripts.
#>

# Fonction simple
function Test-Function {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputString
    )
    
    Write-Output $InputString
}

# Appel de la fonction
Test-Function -InputString "Hello, World!"
