<#
.SYNOPSIS
    Tests unitaires pour vÃ©rifier le document des mÃ©triques pour l'estimation des ressources.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier que le document des mÃ©triques
    pour l'estimation des ressources a Ã©tÃ© correctement crÃ©Ã© et contient toutes les informations nÃ©cessaires.

.PARAMETER DocumentPath
    Chemin vers le document des mÃ©triques pour l'estimation des ressources.

.EXAMPLE
    .\Test-ResourceMetrics.ps1 -DocumentPath "..\..\data\planning\resource-metrics.md"
    ExÃ©cute les tests unitaires pour le document des mÃ©triques pour l'estimation des ressources.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-07
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$DocumentPath
)

# VÃ©rifier que le document existe
if (-not (Test-Path -Path $DocumentPath)) {
    Write-Error "Le document est introuvable : $DocumentPath"
    exit 1
}

# Fonction pour exÃ©cuter un test
function Test-Function {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Test
    )

    Write-Host "`nTest : $Name" -ForegroundColor Cyan
    
    try {
        $result = & $Test
        
        if ($result -eq $true) {
            Write-Host "  RÃ©sultat : SuccÃ¨s" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  RÃ©sultat : Ã‰chec" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  Erreur : $_" -ForegroundColor Red
        return $false
    }
}

# Charger le contenu du document
$documentContent = Get-Content -Path $DocumentPath -Raw

# Tests unitaires
$tests = @(
    @{
        Name = "Test de l'existence du document"
        Test = {
            return (Test-Path -Path $DocumentPath -PathType Leaf)
        }
    },
    @{
        Name = "Test de la prÃ©sence du titre principal"
        Test = {
            return ($documentContent -match "# MÃ©triques pour l'Estimation des Ressources")
        }
    },
    @{
        Name = "Test de la prÃ©sence des catÃ©gories de ressources"
        Test = {
            return ($documentContent -match "## CatÃ©gories de Ressources")
        }
    },
    @{
        Name = "Test de la prÃ©sence des mÃ©triques des ressources humaines"
        Test = {
            return ($documentContent -match "## MÃ©triques des Ressources Humaines")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la taille de l'Ã©quipe"
        Test = {
            return ($documentContent -match "### Taille de l'Ã‰quipe")
        }
    },
    @{
        Name = "Test de la prÃ©sence des rÃ´les nÃ©cessaires"
        Test = {
            return ($documentContent -match "### RÃ´les NÃ©cessaires")
        }
    },
    @{
        Name = "Test de la prÃ©sence des mÃ©triques des compÃ©tences techniques"
        Test = {
            return ($documentContent -match "## MÃ©triques des CompÃ©tences Techniques")
        }
    },
    @{
        Name = "Test de la prÃ©sence du niveau d'expertise requis"
        Test = {
            return ($documentContent -match "### Niveau d'Expertise Requis")
        }
    },
    @{
        Name = "Test de la prÃ©sence des domaines de compÃ©tence"
        Test = {
            return ($documentContent -match "### Domaines de CompÃ©tence")
        }
    },
    @{
        Name = "Test de la prÃ©sence des mÃ©triques des ressources matÃ©rielles"
        Test = {
            return ($documentContent -match "## MÃ©triques des Ressources MatÃ©rielles")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'infrastructure requise"
        Test = {
            return ($documentContent -match "### Infrastructure Requise")
        }
    },
    @{
        Name = "Test de la prÃ©sence des environnements nÃ©cessaires"
        Test = {
            return ($documentContent -match "### Environnements NÃ©cessaires")
        }
    },
    @{
        Name = "Test de la prÃ©sence des mÃ©triques des ressources temporelles"
        Test = {
            return ($documentContent -match "## MÃ©triques des Ressources Temporelles")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la durÃ©e d'implÃ©mentation"
        Test = {
            return ($documentContent -match "### DurÃ©e d'ImplÃ©mentation")
        }
    },
    @{
        Name = "Test de la prÃ©sence des phases du projet"
        Test = {
            return ($documentContent -match "### Phases du Projet")
        }
    },
    @{
        Name = "Test de la prÃ©sence des mÃ©triques des ressources financiÃ¨res"
        Test = {
            return ($documentContent -match "## MÃ©triques des Ressources FinanciÃ¨res")
        }
    },
    @{
        Name = "Test de la prÃ©sence des coÃ»ts directs"
        Test = {
            return ($documentContent -match "### CoÃ»ts Directs")
        }
    },
    @{
        Name = "Test de la prÃ©sence du modÃ¨le de calcul des coÃ»ts"
        Test = {
            return ($documentContent -match "### ModÃ¨le de Calcul des CoÃ»ts")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'application des mÃ©triques"
        Test = {
            return ($documentContent -match "## Application des MÃ©triques")
        }
    },
    @{
        Name = "Test de la prÃ©sence du processus d'estimation"
        Test = {
            return ($documentContent -match "### Processus d'Estimation")
        }
    }
)

# ExÃ©cuter les tests
$totalTests = $tests.Count
$passedTests = 0

foreach ($test in $tests) {
    $result = Test-Function -Name $test.Name -Test $test.Test
    
    if ($result) {
        $passedTests++
    }
}

# Afficher le rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des tests :" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s : $totalTests" -ForegroundColor Cyan
Write-Host "  Tests rÃ©ussis : $passedTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Yellow" })
Write-Host "  Tests Ã©chouÃ©s : $($totalTests - $passedTests)" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })

# Retourner le rÃ©sultat
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont rÃ©ussi." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
