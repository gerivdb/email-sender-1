<#
.SYNOPSIS
    Tests unitaires pour vÃ©rifier le document des niveaux de complexitÃ© technique.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier que le document des niveaux
    de complexitÃ© technique a Ã©tÃ© correctement crÃ©Ã© et contient toutes les informations nÃ©cessaires.

.PARAMETER DocumentPath
    Chemin vers le document des niveaux de complexitÃ© technique.

.EXAMPLE
    .\Test-ComplexityLevels.ps1 -DocumentPath "..\..\data\planning\complexity-levels.md"
    ExÃ©cute les tests unitaires pour le document des niveaux de complexitÃ© technique.

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
            return ($documentContent -match "# Niveaux de ComplexitÃ© Technique")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'Ã©chelle de complexitÃ©"
        Test = {
            return ($documentContent -match "## Ã‰chelle de ComplexitÃ©")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau des niveaux"
        Test = {
            return ($documentContent -match "\| Niveau \| Score \| Description \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence des critÃ¨res d'Ã©valuation"
        Test = {
            return ($documentContent -match "## CritÃ¨res d'Ã‰valuation par Niveau")
        }
    },
    @{
        Name = "Test de la prÃ©sence du niveau 1"
        Test = {
            return ($documentContent -match "### Niveau 1 : TrÃ¨s faible")
        }
    },
    @{
        Name = "Test de la prÃ©sence du niveau 2"
        Test = {
            return ($documentContent -match "### Niveau 2 : Faible")
        }
    },
    @{
        Name = "Test de la prÃ©sence du niveau 3"
        Test = {
            return ($documentContent -match "### Niveau 3 : Moyen")
        }
    },
    @{
        Name = "Test de la prÃ©sence du niveau 4"
        Test = {
            return ($documentContent -match "### Niveau 4 : Ã‰levÃ©")
        }
    },
    @{
        Name = "Test de la prÃ©sence du niveau 5"
        Test = {
            return ($documentContent -match "### Niveau 5 : TrÃ¨s Ã©levÃ©")
        }
    },
    @{
        Name = "Test de la prÃ©sence des caractÃ©ristiques"
        Test = {
            return ($documentContent -match "\*\*CaractÃ©ristiques :\*\*")
        }
    },
    @{
        Name = "Test de la prÃ©sence des exemples"
        Test = {
            return ($documentContent -match "\*\*Exemples :\*\*")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'effort typique"
        Test = {
            return ($documentContent -match "\*\*Effort typique :\*\*")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'application aux facteurs"
        Test = {
            return ($documentContent -match "## Application aux Facteurs de ComplexitÃ©")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'exemple d'Ã©valuation"
        Test = {
            return ($documentContent -match "### Exemple d'Ã‰valuation")
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
