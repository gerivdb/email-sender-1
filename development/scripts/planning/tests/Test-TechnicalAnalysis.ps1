<#
.SYNOPSIS
    Tests unitaires pour vÃ©rifier le rapport d'analyse technique.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier que le rapport d'analyse
    technique a Ã©tÃ© correctement crÃ©Ã© et contient toutes les informations nÃ©cessaires.

.PARAMETER DocumentPath
    Chemin vers le rapport d'analyse technique.

.EXAMPLE
    .\Test-TechnicalAnalysis.ps1 -DocumentPath "..\..\data\planning\technical-analysis.md"
    ExÃ©cute les tests unitaires pour le rapport d'analyse technique.

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
            return ($documentContent -match "# Analyse des Aspects Techniques des AmÃ©liorations")
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
        Name = "Test de la prÃ©sence des composants techniques"
        Test = {
            return ($documentContent -match "#### Composants Techniques")
        }
    },
    @{
        Name = "Test de la prÃ©sence des technologies impliquÃ©es"
        Test = {
            return ($documentContent -match "#### Technologies ImpliquÃ©es")
        }
    },
    @{
        Name = "Test de la prÃ©sence des interfaces"
        Test = {
            return ($documentContent -match "#### Interfaces")
        }
    },
    @{
        Name = "Test de la prÃ©sence des dÃ©pendances techniques"
        Test = {
            return ($documentContent -match "#### DÃ©pendances Techniques")
        }
    },
    @{
        Name = "Test de la prÃ©sence du rÃ©sumÃ©"
        Test = {
            return ($documentContent -match "## RÃ©sumÃ©")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la rÃ©partition par type"
        Test = {
            return ($documentContent -match "### RÃ©partition par Type")
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
    },
    @{
        Name = "Test de la prÃ©sence du Integrated Manager"
        Test = {
            return ($documentContent -match "## <a name='integrated-manager'></a>Integrated Manager")
        }
    },
    @{
        Name = "Test de la prÃ©sence du Script Manager"
        Test = {
            return ($documentContent -match "## <a name='script-manager'></a>Script Manager")
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
