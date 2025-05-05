<#
.SYNOPSIS
    Tests unitaires pour vÃ©rifier le rapport du personnel requis.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier que le rapport du personnel
    requis a Ã©tÃ© correctement crÃ©Ã© et contient toutes les informations nÃ©cessaires.

.PARAMETER DocumentPath
    Chemin vers le rapport du personnel requis.

.EXAMPLE
    .\Test-RequiredPersonnel.ps1 -DocumentPath "..\..\data\planning\required-personnel.md"
    ExÃ©cute les tests unitaires pour le rapport du personnel requis.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-09
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
            return ($documentContent -match "# DÃ©termination du Nombre de Personnes NÃ©cessaires pour les AmÃ©liorations")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la table des matiÃ¨res"
        Test = {
            return ($documentContent -match "## Table des MatiÃ¨res")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la mÃ©thodologie"
        Test = {
            return ($documentContent -match "## MÃ©thodologie")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'Ã©chelle de base du personnel"
        Test = {
            return ($documentContent -match "### Ã‰chelle de Base du Personnel")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de l'Ã©chelle de base"
        Test = {
            return ($documentContent -match "\| Score \| Nombre de Personnes \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'Ã©valuation du personnel nÃ©cessaire"
        Test = {
            return ($documentContent -match "#### Ã‰valuation du Personnel NÃ©cessaire")
        }
    },
    @{
        Name = "Test de la prÃ©sence des facteurs d'Ã©valuation"
        Test = {
            return ($documentContent -match "\*\*Facteurs d'Ã©valuation :\*\*")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau des facteurs"
        Test = {
            return ($documentContent -match "\| Facteur \| Poids \| Score \| Score pondÃ©rÃ© \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la rÃ©partition par rÃ´le"
        Test = {
            return ($documentContent -match "\*\*RÃ©partition par rÃ´le :\*\*")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau des rÃ´les"
        Test = {
            return ($documentContent -match "\| RÃ´le \| Nombre \| Justification \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la justification"
        Test = {
            return ($documentContent -match "#### Justification")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la justification pour la complexitÃ© technique"
        Test = {
            return ($documentContent -match "\*\*ComplexitÃ© technique \(Score : \d+\) :\*\*")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la justification pour le nombre de compÃ©tences requises"
        Test = {
            return ($documentContent -match "\*\*Nombre de compÃ©tences requises \(Score : \d+\) :\*\*")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la justification pour l'effort requis"
        Test = {
            return ($documentContent -match "\*\*Effort requis \(Score : \d+\) :\*\*")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la justification pour le type d'amÃ©lioration"
        Test = {
            return ($documentContent -match "\*\*Type d'amÃ©lioration \(Score : \d+\) :\*\*")
        }
    },
    @{
        Name = "Test de la prÃ©sence du rÃ©sumÃ©"
        Test = {
            return ($documentContent -match "## RÃ©sumÃ©")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la rÃ©partition par rÃ´le dans le rÃ©sumÃ©"
        Test = {
            return ($documentContent -match "### RÃ©partition par RÃ´le")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de rÃ©partition par rÃ´le"
        Test = {
            return ($documentContent -match "\| RÃ´le \| Nombre \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence des recommandations"
        Test = {
            return ($documentContent -match "### Recommandations")
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
