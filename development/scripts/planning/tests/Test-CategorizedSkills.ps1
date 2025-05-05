<#
.SYNOPSIS
    Tests unitaires pour vÃ©rifier les compÃ©tences catÃ©gorisÃ©es.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier que les compÃ©tences
    catÃ©gorisÃ©es ont Ã©tÃ© correctement crÃ©Ã©es et contiennent toutes les informations nÃ©cessaires.

.PARAMETER DocumentPath
    Chemin vers le document des compÃ©tences catÃ©gorisÃ©es.

.EXAMPLE
    .\Test-CategorizedSkills.ps1 -DocumentPath "..\..\data\planning\skills-categorized.md"
    ExÃ©cute les tests unitaires pour les compÃ©tences catÃ©gorisÃ©es.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-10
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
            return ($documentContent -match "# CompÃ©tences CatÃ©gorisÃ©es par Domaine")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la table des matiÃ¨res"
        Test = {
            return ($documentContent -match "## Table des MatiÃ¨res")
        }
    },
    @{
        Name = "Test de la prÃ©sence d'au moins un domaine"
        Test = {
            return ($documentContent -match "## <a name='[^']+'></a>[^`n]+")
        }
    },
    @{
        Name = "Test de la prÃ©sence d'au moins une catÃ©gorie"
        Test = {
            return ($documentContent -match "### [^`n]+")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau des compÃ©tences"
        Test = {
            return ($documentContent -match "\| CompÃ©tence \| Niveau \| Justification \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence du rÃ©sumÃ©"
        Test = {
            return ($documentContent -match "## <a name='rÃ©sumÃ©'></a>RÃ©sumÃ©")
        }
    },
    @{
        Name = "Test de la prÃ©sence du nombre total de compÃ©tences"
        Test = {
            return ($documentContent -match "\*\*Nombre total de compÃ©tences :\*\* \d+")
        }
    },
    @{
        Name = "Test de la prÃ©sence du nombre de compÃ©tences uniques"
        Test = {
            return ($documentContent -match "\*\*Nombre de compÃ©tences uniques :\*\* \d+")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la rÃ©partition par domaine"
        Test = {
            return ($documentContent -match "### RÃ©partition par Domaine")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de rÃ©partition par domaine"
        Test = {
            return ($documentContent -match "\| Domaine \| Nombre de CompÃ©tences \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la rÃ©partition par niveau d'expertise"
        Test = {
            return ($documentContent -match "### RÃ©partition par Niveau d'Expertise")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de rÃ©partition par niveau d'expertise"
        Test = {
            return ($documentContent -match "\| Niveau \| Nombre de CompÃ©tences \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence des compÃ©tences les plus demandÃ©es"
        Test = {
            return ($documentContent -match "### CompÃ©tences les Plus DemandÃ©es")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau des compÃ©tences les plus demandÃ©es"
        Test = {
            return ($documentContent -match "\| CompÃ©tence \| Domaine \| Occurrences \| Pourcentage \|")
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
