<#
.SYNOPSIS
    Tests unitaires pour vÃ©rifier la liste des compÃ©tences extraites.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier que la liste des compÃ©tences
    extraites a Ã©tÃ© correctement crÃ©Ã©e et contient toutes les informations nÃ©cessaires.

.PARAMETER DocumentPath
    Chemin vers la liste des compÃ©tences extraites.

.EXAMPLE
    .\Test-ExtractedSkills.ps1 -DocumentPath "..\..\data\planning\skills-list.md"
    ExÃ©cute les tests unitaires pour la liste des compÃ©tences extraites.

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
            return ($documentContent -match "# Liste des CompÃ©tences Requises")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la table des matiÃ¨res"
        Test = {
            return ($documentContent -match "## Table des MatiÃ¨res")
        }
    },
    @{
        Name = "Test de la prÃ©sence du rÃ©sumÃ© des compÃ©tences"
        Test = {
            return ($documentContent -match "## RÃ©sumÃ© des CompÃ©tences")
        }
    },
    @{
        Name = "Test de la prÃ©sence du nombre total de compÃ©tences uniques"
        Test = {
            return ($documentContent -match "\*\*Nombre total de compÃ©tences uniques :\*\* \d+")
        }
    },
    @{
        Name = "Test de la prÃ©sence du nombre total d'occurrences"
        Test = {
            return ($documentContent -match "\*\*Nombre total d'occurrences :\*\* \d+")
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
            return ($documentContent -match "\| CompÃ©tence \| Occurrences \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence des compÃ©tences par catÃ©gorie"
        Test = {
            return ($documentContent -match "## CompÃ©tences par CatÃ©gorie")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la catÃ©gorie DÃ©veloppement"
        Test = {
            return ($documentContent -match "### DÃ©veloppement")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau des compÃ©tences par catÃ©gorie"
        Test = {
            return ($documentContent -match "\| CompÃ©tence \| Occurrences \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence d'au moins un gestionnaire"
        Test = {
            return ($documentContent -match "## <a name='[^']+'></a>[^`n]+")
        }
    },
    @{
        Name = "Test de la prÃ©sence d'au moins une amÃ©lioration"
        Test = {
            return ($documentContent -match "### [^`n]+")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau des compÃ©tences par amÃ©lioration"
        Test = {
            return ($documentContent -match "\| CatÃ©gorie \| CompÃ©tence \| Niveau \| Justification \|")
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
