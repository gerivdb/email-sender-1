<#
.SYNOPSIS
    Tests unitaires pour vÃ©rifier le document des justifications des Ã©valuations de complexitÃ© technique.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier que le document des justifications
    des Ã©valuations de complexitÃ© technique a Ã©tÃ© correctement crÃ©Ã© et contient toutes les informations nÃ©cessaires.

.PARAMETER DocumentPath
    Chemin vers le document des justifications des Ã©valuations de complexitÃ© technique.

.EXAMPLE
    .\Test-ComplexityJustifications.ps1 -DocumentPath "..\..\data\planning\complexity-evaluation-justifications.md"
    ExÃ©cute les tests unitaires pour le document des justifications des Ã©valuations de complexitÃ© technique.

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
            return ($documentContent -match "# Justifications des Ã‰valuations de ComplexitÃ© Technique")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'objectif"
        Test = {
            return ($documentContent -match "## Objectif")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la mÃ©thodologie d'Ã©valuation"
        Test = {
            return ($documentContent -match "## MÃ©thodologie d'Ã‰valuation")
        }
    },
    @{
        Name = "Test de la prÃ©sence des critÃ¨res d'Ã©valuation dÃ©taillÃ©s"
        Test = {
            return ($documentContent -match "## CritÃ¨res d'Ã‰valuation DÃ©taillÃ©s")
        }
    },
    @{
        Name = "Test de la prÃ©sence du type d'amÃ©lioration"
        Test = {
            return ($documentContent -match "### Type d'AmÃ©lioration")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau du type d'amÃ©lioration"
        Test = {
            return ($documentContent -match "\| Type \| Score \| Justification \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'effort requis"
        Test = {
            return ($documentContent -match "### Effort Requis")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de l'effort requis"
        Test = {
            return ($documentContent -match "\| Niveau \| Score \| Justification \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la difficultÃ© d'implÃ©mentation"
        Test = {
            return ($documentContent -match "### DifficultÃ© d'ImplÃ©mentation")
        }
    },
    @{
        Name = "Test de la prÃ©sence des risques techniques"
        Test = {
            return ($documentContent -match "### Risques Techniques")
        }
    },
    @{
        Name = "Test de la prÃ©sence des justifications par gestionnaire"
        Test = {
            return ($documentContent -match "## Justifications par Gestionnaire")
        }
    },
    @{
        Name = "Test de la prÃ©sence du Process Manager"
        Test = {
            return ($documentContent -match "### Process Manager")
        }
    },
    @{
        Name = "Test de la prÃ©sence du Mode Manager"
        Test = {
            return ($documentContent -match "### Mode Manager")
        }
    },
    @{
        Name = "Test de la prÃ©sence des justifications dÃ©taillÃ©es"
        Test = {
            return ($documentContent -match "\*\*Justification dÃ©taillÃ©e :\*\*")
        }
    },
    @{
        Name = "Test de la prÃ©sence des recommandations"
        Test = {
            return ($documentContent -match "## Recommandations pour l'Utilisation des Ã‰valuations")
        }
    },
    @{
        Name = "Test de la prÃ©sence du processus de mise Ã  jour"
        Test = {
            return ($documentContent -match "## Processus de Mise Ã  Jour")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la conclusion"
        Test = {
            return ($documentContent -match "## Conclusion")
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
