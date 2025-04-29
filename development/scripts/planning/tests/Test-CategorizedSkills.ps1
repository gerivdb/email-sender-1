<#
.SYNOPSIS
    Tests unitaires pour vérifier les compétences catégorisées.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier que les compétences
    catégorisées ont été correctement créées et contiennent toutes les informations nécessaires.

.PARAMETER DocumentPath
    Chemin vers le document des compétences catégorisées.

.EXAMPLE
    .\Test-CategorizedSkills.ps1 -DocumentPath "..\..\data\planning\skills-categorized.md"
    Exécute les tests unitaires pour les compétences catégorisées.

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
            return ($documentContent -match "# Compétences Catégorisées par Domaine")
        }
    },
    @{
        Name = "Test de la présence de la table des matières"
        Test = {
            return ($documentContent -match "## Table des Matières")
        }
    },
    @{
        Name = "Test de la présence d'au moins un domaine"
        Test = {
            return ($documentContent -match "## <a name='[^']+'></a>[^`n]+")
        }
    },
    @{
        Name = "Test de la présence d'au moins une catégorie"
        Test = {
            return ($documentContent -match "### [^`n]+")
        }
    },
    @{
        Name = "Test de la présence du tableau des compétences"
        Test = {
            return ($documentContent -match "\| Compétence \| Niveau \| Justification \|")
        }
    },
    @{
        Name = "Test de la présence du résumé"
        Test = {
            return ($documentContent -match "## <a name='résumé'></a>Résumé")
        }
    },
    @{
        Name = "Test de la présence du nombre total de compétences"
        Test = {
            return ($documentContent -match "\*\*Nombre total de compétences :\*\* \d+")
        }
    },
    @{
        Name = "Test de la présence du nombre de compétences uniques"
        Test = {
            return ($documentContent -match "\*\*Nombre de compétences uniques :\*\* \d+")
        }
    },
    @{
        Name = "Test de la présence de la répartition par domaine"
        Test = {
            return ($documentContent -match "### Répartition par Domaine")
        }
    },
    @{
        Name = "Test de la présence du tableau de répartition par domaine"
        Test = {
            return ($documentContent -match "\| Domaine \| Nombre de Compétences \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la présence de la répartition par niveau d'expertise"
        Test = {
            return ($documentContent -match "### Répartition par Niveau d'Expertise")
        }
    },
    @{
        Name = "Test de la présence du tableau de répartition par niveau d'expertise"
        Test = {
            return ($documentContent -match "\| Niveau \| Nombre de Compétences \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la présence des compétences les plus demandées"
        Test = {
            return ($documentContent -match "### Compétences les Plus Demandées")
        }
    },
    @{
        Name = "Test de la présence du tableau des compétences les plus demandées"
        Test = {
            return ($documentContent -match "\| Compétence \| Domaine \| Occurrences \| Pourcentage \|")
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
