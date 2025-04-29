<#
.SYNOPSIS
    Tests unitaires pour vérifier la matrice de compétences par gestionnaire.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier que la matrice de compétences
    par gestionnaire a été correctement créée et contient toutes les informations nécessaires.

.PARAMETER DocumentPath
    Chemin vers le document de la matrice de compétences par gestionnaire.

.EXAMPLE
    .\Test-SkillsMatrix.ps1 -DocumentPath "..\..\data\planning\skills-matrix.md"
    Exécute les tests unitaires pour la matrice de compétences par gestionnaire.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de création: 2025-05-10
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$DocumentPath
)

# Vérifier que le document existe
if (-not (Test-Path -Path $DocumentPath)) {
    Write-Error "Le document est introuvable : $DocumentPath"
    exit 1
}

# Fonction pour exécuter un test
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
            Write-Host "  Résultat : Succès" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Résultat : Échec" -ForegroundColor Red
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
        Name = "Test de la présence du titre principal"
        Test = {
            return ($documentContent -match "# Matrice de Compétences par Gestionnaire")
        }
    },
    @{
        Name = "Test de la présence de la table des matières"
        Test = {
            return ($documentContent -match "## Table des Matières")
        }
    },
    @{
        Name = "Test de la présence du résumé"
        Test = {
            return ($documentContent -match "## <a name='résumé'></a>Résumé")
        }
    },
    @{
        Name = "Test de la présence du nombre total de compétences uniques"
        Test = {
            return ($documentContent -match "\*\*Nombre total de compétences uniques :\*\* \d+")
        }
    },
    @{
        Name = "Test de la présence du nombre de catégories"
        Test = {
            return ($documentContent -match "\*\*Nombre de catégories :\*\* \d+")
        }
    },
    @{
        Name = "Test de la présence du nombre de niveaux d'expertise"
        Test = {
            return ($documentContent -match "\*\*Nombre de niveaux d'expertise :\*\* \d+")
        }
    },
    @{
        Name = "Test de la présence de la répartition des compétences par gestionnaire"
        Test = {
            return ($documentContent -match "### Répartition des Compétences par Gestionnaire")
        }
    },
    @{
        Name = "Test de la présence du tableau de répartition des compétences par gestionnaire"
        Test = {
            return ($documentContent -match "\| Gestionnaire \| Nombre de Compétences \| % du Total \|")
        }
    },
    @{
        Name = "Test de la présence de la matrice de compétences"
        Test = {
            return ($documentContent -match "## <a name='matrice-de-compétences'></a>Matrice de Compétences")
        }
    },
    @{
        Name = "Test de la présence de la matrice par catégorie"
        Test = {
            return ($documentContent -match "## <a name='matrice-par-catégorie'></a>Matrice par Catégorie")
        }
    },
    @{
        Name = "Test de la présence du tableau de la matrice par catégorie"
        Test = {
            return ($documentContent -match "\| Catégorie \| Nombre de Compétences \|")
        }
    },
    @{
        Name = "Test de la présence de la matrice par niveau d'expertise"
        Test = {
            return ($documentContent -match "## <a name='matrice-par-niveau-dexpertise'></a>Matrice par Niveau d'Expertise")
        }
    },
    @{
        Name = "Test de la présence du tableau de la matrice par niveau d'expertise"
        Test = {
            return ($documentContent -match "\| Niveau d'Expertise \|")
        }
    },
    @{
        Name = "Test de la présence des synergies entre gestionnaires"
        Test = {
            return ($documentContent -match "## <a name='synergies-entre-gestionnaires'></a>Synergies entre Gestionnaires")
        }
    },
    @{
        Name = "Test de la présence du tableau des synergies entre gestionnaires"
        Test = {
            return ($documentContent -match "\| Gestionnaire 1 \| Gestionnaire 2 \| Compétences Communes \| % des Compétences de G1 \| % des Compétences de G2 \|")
        }
    },
    @{
        Name = "Test de la présence des détails des synergies"
        Test = {
            return ($documentContent -match "### Détails des Synergies")
        }
    },
    @{
        Name = "Test de la présence des améliorations par gestionnaire"
        Test = {
            return ($documentContent -match "## <a name='améliorations-par-gestionnaire'></a>Améliorations par Gestionnaire")
        }
    },
    @{
        Name = "Test de la présence d'au moins un gestionnaire dans les améliorations"
        Test = {
            return ($documentContent -match "### [^`n]+`n`n")
        }
    },
    @{
        Name = "Test de la présence des implications pour la planification"
        Test = {
            return ($documentContent -match "## <a name='implications-pour-la-planification'></a>Implications pour la Planification")
        }
    },
    @{
        Name = "Test de la présence de l'allocation des ressources"
        Test = {
            return ($documentContent -match "### Allocation des Ressources")
        }
    },
    @{
        Name = "Test de la présence de la formation et du développement"
        Test = {
            return ($documentContent -match "### Formation et Développement")
        }
    },
    @{
        Name = "Test de la présence du recrutement"
        Test = {
            return ($documentContent -match "### Recrutement")
        }
    }
)

# Exécuter les tests
$totalTests = $tests.Count
$passedTests = 0

foreach ($test in $tests) {
    $result = Test-Function -Name $test.Name -Test $test.Test
    
    if ($result) {
        $passedTests++
    }
}

# Afficher le résumé
Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
Write-Host "  Tests exécutés : $totalTests" -ForegroundColor Cyan
Write-Host "  Tests réussis : $passedTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Yellow" })
Write-Host "  Tests échoués : $($totalTests - $passedTests)" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })

# Retourner le résultat
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont réussi." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
