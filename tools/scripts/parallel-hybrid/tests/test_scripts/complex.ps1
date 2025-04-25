#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test complexe.
.DESCRIPTION
    Ce script est utilisÃ© pour tester l'analyseur de scripts avec des structures plus complexes.
.NOTES
    Version: 1.0
    Auteur: Test
    Date: 2025-04-10
#>

# Variables
$maxItems = 10
$processingEnabled = $true

# Fonction avec gestion d'erreurs
function Process-Items {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Count,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    try {
        # Boucle for
        for ($i = 1; $i -le $Count; $i++) {
            # Structure conditionnelle
            if ($i % 2 -eq 0) {
                Write-Output "Item $i est pair"
            }
            else {
                Write-Output "Item $i est impair"
            }
            
            # Structure switch
            switch ($i % 3) {
                0 { Write-Verbose "Divisible par 3" }
                1 { Write-Verbose "Reste 1" }
                2 { Write-Verbose "Reste 2" }
            }
        }
    }
    catch {
        Write-Error "Une erreur s'est produite : $_"
    }
}

# Fonction avec boucle foreach
function Get-ItemsReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Items
    )
    
    $results = @()
    
    # Boucle foreach
    foreach ($item in $Items) {
        $results += @{
            Name = $item
            Length = $item.Length
            UpperCase = $item.ToUpper()
        }
    }
    
    return $results
}

# Appel des fonctions
if ($processingEnabled) {
    Process-Items -Count $maxItems
    Get-ItemsReport -Items @("Apple", "Banana", "Cherry")
}
