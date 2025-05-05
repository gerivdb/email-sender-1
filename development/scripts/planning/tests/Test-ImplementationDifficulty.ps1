<#
.SYNOPSIS
    Tests unitaires pour vÃ©rifier le rapport d'Ã©valuation de la difficultÃ© d'implÃ©mentation.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier que le rapport d'Ã©valuation
    de la difficultÃ© d'implÃ©mentation a Ã©tÃ© correctement crÃ©Ã© et contient toutes les informations nÃ©cessaires.

.PARAMETER DocumentPath
    Chemin vers le rapport d'Ã©valuation de la difficultÃ© d'implÃ©mentation.

.EXAMPLE
    .\Test-ImplementationDifficulty.ps1 -DocumentPath "..\..\data\planning\implementation-difficulty.md"
    ExÃ©cute les tests unitaires pour le rapport d'Ã©valuation de la difficultÃ© d'implÃ©mentation.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-08
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
            return ($documentContent -match "# Ã‰valuation de la DifficultÃ© d'ImplÃ©mentation des AmÃ©liorations")
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
        Name = "Test de la prÃ©sence des niveaux de difficultÃ©"
        Test = {
            return ($documentContent -match "### Niveaux de DifficultÃ©")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau des niveaux de difficultÃ©"
        Test = {
            return ($documentContent -match "\| Niveau \| Score \| Description \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'Ã©valuation de la difficultÃ©"
        Test = {
            return ($documentContent -match "#### Ã‰valuation de la DifficultÃ©")
        }
    },
    @{
        Name = "Test de la prÃ©sence des facteurs de difficultÃ©"
        Test = {
            return ($documentContent -match "\*\*Facteurs de difficultÃ© :\*\*")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau des facteurs"
        Test = {
            return ($documentContent -match "\| Facteur \| Poids \| Score \| Score pondÃ©rÃ© \|")
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
        Name = "Test de la prÃ©sence de la justification pour l'expertise requise"
        Test = {
            return ($documentContent -match "\*\*Expertise requise \(Score : \d+\) :\*\*")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la justification pour les contraintes de temps"
        Test = {
            return ($documentContent -match "\*\*Contraintes de temps \(Score : \d+\) :\*\*")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la justification pour les dÃ©pendances"
        Test = {
            return ($documentContent -match "\*\*DÃ©pendances \(Score : \d+\) :\*\*")
        }
    },
    @{
        Name = "Test de la prÃ©sence du rÃ©sumÃ©"
        Test = {
            return ($documentContent -match "## RÃ©sumÃ©")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la rÃ©partition par niveau de difficultÃ©"
        Test = {
            return ($documentContent -match "### RÃ©partition par Niveau de DifficultÃ©")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de rÃ©partition"
        Test = {
            return ($documentContent -match "\| Niveau \| Nombre \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence du Process Manager"
        Test = {
            return ($documentContent -match "## <a name='process-manager'></a>Process Manager")
        }
    },
    @{
        Name = "Test de la prÃ©sence du Mode Manager"
        Test = {
            return ($documentContent -match "## <a name='mode-manager'></a>Mode Manager")
        }
    },
    @{
        Name = "Test de la prÃ©sence du Roadmap Manager"
        Test = {
            return ($documentContent -match "## <a name='roadmap-manager'></a>Roadmap Manager")
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
