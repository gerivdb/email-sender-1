<#
.SYNOPSIS
    Tests unitaires pour vÃ©rifier l'analyse de la frÃ©quence d'utilisation des compÃ©tences.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier que l'analyse de la frÃ©quence
    d'utilisation des compÃ©tences a Ã©tÃ© correctement crÃ©Ã©e et contient toutes les informations nÃ©cessaires.

.PARAMETER DocumentPath
    Chemin vers le document d'analyse de la frÃ©quence d'utilisation des compÃ©tences.

.EXAMPLE
    .\Test-SkillFrequency.ps1 -DocumentPath "..\..\data\planning\skill-frequency.md"
    ExÃ©cute les tests unitaires pour l'analyse de la frÃ©quence d'utilisation des compÃ©tences.

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
            return ($documentContent -match "# Analyse de la FrÃ©quence d'Utilisation des CompÃ©tences")
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
        Name = "Test de la prÃ©sence du nombre total d'amÃ©liorations"
        Test = {
            return ($documentContent -match "\*\*Nombre total d'amÃ©liorations :\*\* \d+")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la rÃ©partition globale"
        Test = {
            return ($documentContent -match "### RÃ©partition Globale")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de rÃ©partition globale"
        Test = {
            return ($documentContent -match "\| MÃ©trique \| Valeur \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la frÃ©quence par compÃ©tence"
        Test = {
            return ($documentContent -match "## <a name='frÃ©quence-par-compÃ©tence'></a>FrÃ©quence par CompÃ©tence")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de frÃ©quence par compÃ©tence"
        Test = {
            return ($documentContent -match "\| CompÃ©tence \| Occurrences \| % du Total \| AmÃ©liorations \| % des AmÃ©liorations \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la frÃ©quence par catÃ©gorie"
        Test = {
            return ($documentContent -match "## <a name='frÃ©quence-par-catÃ©gorie'></a>FrÃ©quence par CatÃ©gorie")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de frÃ©quence par catÃ©gorie"
        Test = {
            return ($documentContent -match "\| CatÃ©gorie \| Occurrences \| % du Total \| CompÃ©tences Uniques \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la frÃ©quence par niveau d'expertise"
        Test = {
            return ($documentContent -match "## <a name='frÃ©quence-par-niveau-dexpertise'></a>FrÃ©quence par Niveau d'Expertise")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de frÃ©quence par niveau d'expertise"
        Test = {
            return ($documentContent -match "\| Niveau \| Occurrences \| % du Total \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la frÃ©quence par gestionnaire"
        Test = {
            return ($documentContent -match "## <a name='frÃ©quence-par-gestionnaire'></a>FrÃ©quence par Gestionnaire")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de frÃ©quence par gestionnaire"
        Test = {
            return ($documentContent -match "\| Gestionnaire \| Occurrences \| % du Total \| CompÃ©tences Uniques \| AmÃ©liorations \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence des compÃ©tences les plus utilisÃ©es"
        Test = {
            return ($documentContent -match "## <a name='compÃ©tences-les-plus-utilisÃ©es'></a>CompÃ©tences les Plus UtilisÃ©es")
        }
    },
    @{
        Name = "Test de la prÃ©sence d'au moins une compÃ©tence dÃ©taillÃ©e"
        Test = {
            return ($documentContent -match "### [^`n]+`n`n\*\*Occurrences :\*\* \d+")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la distribution par niveau d'expertise"
        Test = {
            return ($documentContent -match "#### Distribution par Niveau d'Expertise")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la distribution par catÃ©gorie"
        Test = {
            return ($documentContent -match "#### Distribution par CatÃ©gorie")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la distribution par gestionnaire"
        Test = {
            return ($documentContent -match "#### Distribution par Gestionnaire")
        }
    },
    @{
        Name = "Test de la prÃ©sence des implications pour la planification"
        Test = {
            return ($documentContent -match "## <a name='implications-pour-la-planification'></a>Implications pour la Planification")
        }
    },
    @{
        Name = "Test de la prÃ©sence des prioritÃ©s de formation"
        Test = {
            return ($documentContent -match "### PrioritÃ©s de Formation")
        }
    },
    @{
        Name = "Test de la prÃ©sence du recrutement"
        Test = {
            return ($documentContent -match "### Recrutement")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'allocation des ressources"
        Test = {
            return ($documentContent -match "### Allocation des Ressources")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la gestion des connaissances"
        Test = {
            return ($documentContent -match "### Gestion des Connaissances")
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
