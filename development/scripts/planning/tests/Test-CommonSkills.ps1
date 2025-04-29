<#
.SYNOPSIS
    Tests unitaires pour vérifier les compétences communes identifiées.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier que les compétences
    communes identifiées ont été correctement créées et contiennent toutes les informations nécessaires.

.PARAMETER DocumentPath
    Chemin vers le document des compétences communes identifiées.

.EXAMPLE
    .\Test-CommonSkills.ps1 -DocumentPath "..\..\data\planning\common-skills.md"
    Exécute les tests unitaires pour les compétences communes identifiées.

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
            return ($documentContent -match "# Compétences Communes à Plusieurs Améliorations")
        }
    },
    @{
        Name = "Test de la présence des critères d'identification"
        Test = {
            return ($documentContent -match "## Critères d'Identification")
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
        Name = "Test de la présence du nombre total de compétences communes"
        Test = {
            return ($documentContent -match "\*\*Nombre total de compétences communes :\*\* \d+")
        }
    },
    @{
        Name = "Test de la présence du nombre total d'occurrences"
        Test = {
            return ($documentContent -match "\*\*Nombre total d'occurrences :\*\* \d+")
        }
    },
    @{
        Name = "Test de la présence des compétences les plus communes"
        Test = {
            return ($documentContent -match "### Compétences les Plus Communes")
        }
    },
    @{
        Name = "Test de la présence du tableau des compétences les plus communes"
        Test = {
            return ($documentContent -match "\| Compétence \| Occurrences \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la présence des compétences communes"
        Test = {
            return ($documentContent -match "## <a name='compétences-communes'></a>Compétences Communes")
        }
    },
    @{
        Name = "Test de la présence d'au moins une compétence commune"
        Test = {
            return ($documentContent -match "### <a name='[^']+'>")
        }
    },
    @{
        Name = "Test de la présence de la distribution par niveau d'expertise"
        Test = {
            return ($documentContent -match "#### Distribution par Niveau d'Expertise")
        }
    },
    @{
        Name = "Test de la présence du tableau de distribution par niveau d'expertise"
        Test = {
            return ($documentContent -match "\| Niveau \| Occurrences \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la présence de la distribution par catégorie"
        Test = {
            return ($documentContent -match "#### Distribution par Catégorie")
        }
    },
    @{
        Name = "Test de la présence du tableau de distribution par catégorie"
        Test = {
            return ($documentContent -match "\| Catégorie \| Occurrences \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la présence de la distribution par gestionnaire"
        Test = {
            return ($documentContent -match "#### Distribution par Gestionnaire")
        }
    },
    @{
        Name = "Test de la présence du tableau de distribution par gestionnaire"
        Test = {
            return ($documentContent -match "\| Gestionnaire \| Occurrences \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la présence des améliorations utilisant cette compétence"
        Test = {
            return ($documentContent -match "#### Améliorations Utilisant cette Compétence")
        }
    },
    @{
        Name = "Test de la présence du tableau des améliorations"
        Test = {
            return ($documentContent -match "\| Gestionnaire \| Amélioration \|")
        }
    },
    @{
        Name = "Test de la présence des implications pour la planification des ressources"
        Test = {
            return ($documentContent -match "## Implications pour la Planification des Ressources")
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
