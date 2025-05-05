<#
.SYNOPSIS
    Tests unitaires pour vÃ©rifier le guide des critÃ¨res d'estimation.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier que le guide des critÃ¨res
    d'estimation a Ã©tÃ© correctement crÃ©Ã© et contient toutes les informations nÃ©cessaires.

.PARAMETER DocumentPath
    Chemin vers le guide des critÃ¨res d'estimation.

.EXAMPLE
    .\Test-EstimationCriteriaGuide.ps1 -DocumentPath "..\..\data\planning\estimation-criteria-guide.md"
    ExÃ©cute les tests unitaires pour le guide des critÃ¨res d'estimation.

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
            return ($documentContent -match "# Guide des CritÃ¨res d'Estimation")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'objectif du guide"
        Test = {
            return ($documentContent -match "## Objectif du Guide")
        }
    },
    @{
        Name = "Test de la prÃ©sence des documents de rÃ©fÃ©rence"
        Test = {
            return ($documentContent -match "## Documents de RÃ©fÃ©rence")
        }
    },
    @{
        Name = "Test de la prÃ©sence du processus d'estimation complet"
        Test = {
            return ($documentContent -match "## Processus d'Estimation Complet")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'analyse prÃ©liminaire"
        Test = {
            return ($documentContent -match "### 1\. Analyse PrÃ©liminaire")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'Ã©valuation de la complexitÃ©"
        Test = {
            return ($documentContent -match "### 2\. Ã‰valuation de la ComplexitÃ©")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'estimation des ressources"
        Test = {
            return ($documentContent -match "### 3\. Estimation des Ressources")
        }
    },
    @{
        Name = "Test de la prÃ©sence du calcul de l'effort"
        Test = {
            return ($documentContent -match "### 4\. Calcul de l'Effort")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la validation et documentation"
        Test = {
            return ($documentContent -match "### 5\. Validation et Documentation")
        }
    },
    @{
        Name = "Test de la prÃ©sence des critÃ¨res d'estimation dÃ©taillÃ©s"
        Test = {
            return ($documentContent -match "## CritÃ¨res d'Estimation DÃ©taillÃ©s")
        }
    },
    @{
        Name = "Test de la prÃ©sence des critÃ¨res de complexitÃ© technique"
        Test = {
            return ($documentContent -match "### CritÃ¨res de ComplexitÃ© Technique")
        }
    },
    @{
        Name = "Test de la prÃ©sence des critÃ¨res de ressources humaines"
        Test = {
            return ($documentContent -match "### CritÃ¨res de Ressources Humaines")
        }
    },
    @{
        Name = "Test de la prÃ©sence des critÃ¨res de durÃ©e"
        Test = {
            return ($documentContent -match "### CritÃ¨res de DurÃ©e")
        }
    },
    @{
        Name = "Test de la prÃ©sence des critÃ¨res d'ajustement"
        Test = {
            return ($documentContent -match "### CritÃ¨res d'Ajustement")
        }
    },
    @{
        Name = "Test de la prÃ©sence du formulaire d'estimation"
        Test = {
            return ($documentContent -match "## Formulaire d'Estimation")
        }
    },
    @{
        Name = "Test de la prÃ©sence des bonnes pratiques"
        Test = {
            return ($documentContent -match "## Bonnes Pratiques")
        }
    },
    @{
        Name = "Test de la prÃ©sence des conseils pour des estimations prÃ©cises"
        Test = {
            return ($documentContent -match "### Conseils pour des Estimations PrÃ©cises")
        }
    },
    @{
        Name = "Test de la prÃ©sence des piÃ¨ges Ã  Ã©viter"
        Test = {
            return ($documentContent -match "### PiÃ¨ges Ã  Ã‰viter")
        }
    },
    @{
        Name = "Test de la prÃ©sence du processus d'amÃ©lioration continue"
        Test = {
            return ($documentContent -match "## Processus d'AmÃ©lioration Continue")
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
