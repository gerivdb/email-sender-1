<#
.SYNOPSIS
    Tests unitaires pour vérifier la liste des compétences extraites.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier que la liste des compétences
    extraites a été correctement créée et contient toutes les informations nécessaires.

.PARAMETER DocumentPath
    Chemin vers la liste des compétences extraites.

.EXAMPLE
    .\Test-ExtractedSkills.ps1 -DocumentPath "..\..\data\planning\skills-list.md"
    Exécute les tests unitaires pour la liste des compétences extraites.

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
            return ($documentContent -match "# Liste des Compétences Requises")
        }
    },
    @{
        Name = "Test de la présence de la table des matières"
        Test = {
            return ($documentContent -match "## Table des Matières")
        }
    },
    @{
        Name = "Test de la présence du résumé des compétences"
        Test = {
            return ($documentContent -match "## Résumé des Compétences")
        }
    },
    @{
        Name = "Test de la présence du nombre total de compétences uniques"
        Test = {
            return ($documentContent -match "\*\*Nombre total de compétences uniques :\*\* \d+")
        }
    },
    @{
        Name = "Test de la présence du nombre total d'occurrences"
        Test = {
            return ($documentContent -match "\*\*Nombre total d'occurrences :\*\* \d+")
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
            return ($documentContent -match "\| Compétence \| Occurrences \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la présence des compétences par catégorie"
        Test = {
            return ($documentContent -match "## Compétences par Catégorie")
        }
    },
    @{
        Name = "Test de la présence de la catégorie Développement"
        Test = {
            return ($documentContent -match "### Développement")
        }
    },
    @{
        Name = "Test de la présence du tableau des compétences par catégorie"
        Test = {
            return ($documentContent -match "\| Compétence \| Occurrences \|")
        }
    },
    @{
        Name = "Test de la présence d'au moins un gestionnaire"
        Test = {
            return ($documentContent -match "## <a name='[^']+'></a>[^`n]+")
        }
    },
    @{
        Name = "Test de la présence d'au moins une amélioration"
        Test = {
            return ($documentContent -match "### [^`n]+")
        }
    },
    @{
        Name = "Test de la présence du tableau des compétences par amélioration"
        Test = {
            return ($documentContent -match "\| Catégorie \| Compétence \| Niveau \| Justification \|")
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
