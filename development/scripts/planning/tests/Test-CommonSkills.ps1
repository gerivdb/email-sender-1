<#
.SYNOPSIS
    Tests unitaires pour vÃ©rifier les compÃ©tences communes identifiÃ©es.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier que les compÃ©tences
    communes identifiÃ©es ont Ã©tÃ© correctement crÃ©Ã©es et contiennent toutes les informations nÃ©cessaires.

.PARAMETER DocumentPath
    Chemin vers le document des compÃ©tences communes identifiÃ©es.

.EXAMPLE
    .\Test-CommonSkills.ps1 -DocumentPath "..\..\data\planning\common-skills.md"
    ExÃ©cute les tests unitaires pour les compÃ©tences communes identifiÃ©es.

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
            return ($documentContent -match "# CompÃ©tences Communes Ã  Plusieurs AmÃ©liorations")
        }
    },
    @{
        Name = "Test de la prÃ©sence des critÃ¨res d'identification"
        Test = {
            return ($documentContent -match "## CritÃ¨res d'Identification")
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
        Name = "Test de la prÃ©sence du nombre total de compÃ©tences communes"
        Test = {
            return ($documentContent -match "\*\*Nombre total de compÃ©tences communes :\*\* \d+")
        }
    },
    @{
        Name = "Test de la prÃ©sence du nombre total d'occurrences"
        Test = {
            return ($documentContent -match "\*\*Nombre total d'occurrences :\*\* \d+")
        }
    },
    @{
        Name = "Test de la prÃ©sence des compÃ©tences les plus communes"
        Test = {
            return ($documentContent -match "### CompÃ©tences les Plus Communes")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau des compÃ©tences les plus communes"
        Test = {
            return ($documentContent -match "\| CompÃ©tence \| Occurrences \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence des compÃ©tences communes"
        Test = {
            return ($documentContent -match "## <a name='compÃ©tences-communes'></a>CompÃ©tences Communes")
        }
    },
    @{
        Name = "Test de la prÃ©sence d'au moins une compÃ©tence commune"
        Test = {
            return ($documentContent -match "### <a name='[^']+'>")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la distribution par niveau d'expertise"
        Test = {
            return ($documentContent -match "#### Distribution par Niveau d'Expertise")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de distribution par niveau d'expertise"
        Test = {
            return ($documentContent -match "\| Niveau \| Occurrences \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la distribution par catÃ©gorie"
        Test = {
            return ($documentContent -match "#### Distribution par CatÃ©gorie")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de distribution par catÃ©gorie"
        Test = {
            return ($documentContent -match "\| CatÃ©gorie \| Occurrences \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la distribution par gestionnaire"
        Test = {
            return ($documentContent -match "#### Distribution par Gestionnaire")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de distribution par gestionnaire"
        Test = {
            return ($documentContent -match "\| Gestionnaire \| Occurrences \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence des amÃ©liorations utilisant cette compÃ©tence"
        Test = {
            return ($documentContent -match "#### AmÃ©liorations Utilisant cette CompÃ©tence")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau des amÃ©liorations"
        Test = {
            return ($documentContent -match "\| Gestionnaire \| AmÃ©lioration \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence des implications pour la planification des ressources"
        Test = {
            return ($documentContent -match "## Implications pour la Planification des Ressources")
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
