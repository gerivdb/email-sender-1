<#
.SYNOPSIS
    Tests unitaires pour vÃ©rifier la matrice de compÃ©tences par gestionnaire.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier que la matrice de compÃ©tences
    par gestionnaire a Ã©tÃ© correctement crÃ©Ã©e et contient toutes les informations nÃ©cessaires.

.PARAMETER DocumentPath
    Chemin vers le document de la matrice de compÃ©tences par gestionnaire.

.EXAMPLE
    .\Test-SkillsMatrix.ps1 -DocumentPath "..\..\data\planning\skills-matrix.md"
    ExÃ©cute les tests unitaires pour la matrice de compÃ©tences par gestionnaire.

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
            return ($documentContent -match "# Matrice de CompÃ©tences par Gestionnaire")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la table des matiÃ¨res"
        Test = {
            return ($documentContent -match "## Table des MatiÃ¨res")
        }
    },
    @{
        Name = "Test de la prÃ©sence du rÃ©sumÃ©"
        Test = {
            return ($documentContent -match "## <a name='rÃ©sumÃ©'></a>RÃ©sumÃ©")
        }
    },
    @{
        Name = "Test de la prÃ©sence du nombre total de compÃ©tences uniques"
        Test = {
            return ($documentContent -match "\*\*Nombre total de compÃ©tences uniques :\*\* \d+")
        }
    },
    @{
        Name = "Test de la prÃ©sence du nombre de catÃ©gories"
        Test = {
            return ($documentContent -match "\*\*Nombre de catÃ©gories :\*\* \d+")
        }
    },
    @{
        Name = "Test de la prÃ©sence du nombre de niveaux d'expertise"
        Test = {
            return ($documentContent -match "\*\*Nombre de niveaux d'expertise :\*\* \d+")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la rÃ©partition des compÃ©tences par gestionnaire"
        Test = {
            return ($documentContent -match "### RÃ©partition des CompÃ©tences par Gestionnaire")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de rÃ©partition des compÃ©tences par gestionnaire"
        Test = {
            return ($documentContent -match "\| Gestionnaire \| Nombre de CompÃ©tences \| % du Total \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la matrice de compÃ©tences"
        Test = {
            return ($documentContent -match "## <a name='matrice-de-compÃ©tences'></a>Matrice de CompÃ©tences")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la matrice par catÃ©gorie"
        Test = {
            return ($documentContent -match "## <a name='matrice-par-catÃ©gorie'></a>Matrice par CatÃ©gorie")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de la matrice par catÃ©gorie"
        Test = {
            return ($documentContent -match "\| CatÃ©gorie \| Nombre de CompÃ©tences \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la matrice par niveau d'expertise"
        Test = {
            return ($documentContent -match "## <a name='matrice-par-niveau-dexpertise'></a>Matrice par Niveau d'Expertise")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de la matrice par niveau d'expertise"
        Test = {
            return ($documentContent -match "\| Niveau d'Expertise \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence des synergies entre gestionnaires"
        Test = {
            return ($documentContent -match "## <a name='synergies-entre-gestionnaires'></a>Synergies entre Gestionnaires")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau des synergies entre gestionnaires"
        Test = {
            return ($documentContent -match "\| Gestionnaire 1 \| Gestionnaire 2 \| CompÃ©tences Communes \| % des CompÃ©tences de G1 \| % des CompÃ©tences de G2 \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence des dÃ©tails des synergies"
        Test = {
            return ($documentContent -match "### DÃ©tails des Synergies")
        }
    },
    @{
        Name = "Test de la prÃ©sence des amÃ©liorations par gestionnaire"
        Test = {
            return ($documentContent -match "## <a name='amÃ©liorations-par-gestionnaire'></a>AmÃ©liorations par Gestionnaire")
        }
    },
    @{
        Name = "Test de la prÃ©sence d'au moins un gestionnaire dans les amÃ©liorations"
        Test = {
            return ($documentContent -match "### [^`n]+`n`n")
        }
    },
    @{
        Name = "Test de la prÃ©sence des implications pour la planification"
        Test = {
            return ($documentContent -match "## <a name='implications-pour-la-planification'></a>Implications pour la Planification")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'allocation des ressources"
        Test = {
            return ($documentContent -match "### Allocation des Ressources")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la formation et du dÃ©veloppement"
        Test = {
            return ($documentContent -match "### Formation et DÃ©veloppement")
        }
    },
    @{
        Name = "Test de la prÃ©sence du recrutement"
        Test = {
            return ($documentContent -match "### Recrutement")
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
