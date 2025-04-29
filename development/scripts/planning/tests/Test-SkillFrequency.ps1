<#
.SYNOPSIS
    Tests unitaires pour vérifier l'analyse de la fréquence d'utilisation des compétences.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier que l'analyse de la fréquence
    d'utilisation des compétences a été correctement créée et contient toutes les informations nécessaires.

.PARAMETER DocumentPath
    Chemin vers le document d'analyse de la fréquence d'utilisation des compétences.

.EXAMPLE
    .\Test-SkillFrequency.ps1 -DocumentPath "..\..\data\planning\skill-frequency.md"
    Exécute les tests unitaires pour l'analyse de la fréquence d'utilisation des compétences.

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
            return ($documentContent -match "# Analyse de la Fréquence d'Utilisation des Compétences")
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
        Name = "Test de la présence du nombre total d'améliorations"
        Test = {
            return ($documentContent -match "\*\*Nombre total d'améliorations :\*\* \d+")
        }
    },
    @{
        Name = "Test de la présence de la répartition globale"
        Test = {
            return ($documentContent -match "### Répartition Globale")
        }
    },
    @{
        Name = "Test de la présence du tableau de répartition globale"
        Test = {
            return ($documentContent -match "\| Métrique \| Valeur \|")
        }
    },
    @{
        Name = "Test de la présence de la fréquence par compétence"
        Test = {
            return ($documentContent -match "## <a name='fréquence-par-compétence'></a>Fréquence par Compétence")
        }
    },
    @{
        Name = "Test de la présence du tableau de fréquence par compétence"
        Test = {
            return ($documentContent -match "\| Compétence \| Occurrences \| % du Total \| Améliorations \| % des Améliorations \|")
        }
    },
    @{
        Name = "Test de la présence de la fréquence par catégorie"
        Test = {
            return ($documentContent -match "## <a name='fréquence-par-catégorie'></a>Fréquence par Catégorie")
        }
    },
    @{
        Name = "Test de la présence du tableau de fréquence par catégorie"
        Test = {
            return ($documentContent -match "\| Catégorie \| Occurrences \| % du Total \| Compétences Uniques \|")
        }
    },
    @{
        Name = "Test de la présence de la fréquence par niveau d'expertise"
        Test = {
            return ($documentContent -match "## <a name='fréquence-par-niveau-dexpertise'></a>Fréquence par Niveau d'Expertise")
        }
    },
    @{
        Name = "Test de la présence du tableau de fréquence par niveau d'expertise"
        Test = {
            return ($documentContent -match "\| Niveau \| Occurrences \| % du Total \|")
        }
    },
    @{
        Name = "Test de la présence de la fréquence par gestionnaire"
        Test = {
            return ($documentContent -match "## <a name='fréquence-par-gestionnaire'></a>Fréquence par Gestionnaire")
        }
    },
    @{
        Name = "Test de la présence du tableau de fréquence par gestionnaire"
        Test = {
            return ($documentContent -match "\| Gestionnaire \| Occurrences \| % du Total \| Compétences Uniques \| Améliorations \|")
        }
    },
    @{
        Name = "Test de la présence des compétences les plus utilisées"
        Test = {
            return ($documentContent -match "## <a name='compétences-les-plus-utilisées'></a>Compétences les Plus Utilisées")
        }
    },
    @{
        Name = "Test de la présence d'au moins une compétence détaillée"
        Test = {
            return ($documentContent -match "### [^`n]+`n`n\*\*Occurrences :\*\* \d+")
        }
    },
    @{
        Name = "Test de la présence de la distribution par niveau d'expertise"
        Test = {
            return ($documentContent -match "#### Distribution par Niveau d'Expertise")
        }
    },
    @{
        Name = "Test de la présence de la distribution par catégorie"
        Test = {
            return ($documentContent -match "#### Distribution par Catégorie")
        }
    },
    @{
        Name = "Test de la présence de la distribution par gestionnaire"
        Test = {
            return ($documentContent -match "#### Distribution par Gestionnaire")
        }
    },
    @{
        Name = "Test de la présence des implications pour la planification"
        Test = {
            return ($documentContent -match "## <a name='implications-pour-la-planification'></a>Implications pour la Planification")
        }
    },
    @{
        Name = "Test de la présence des priorités de formation"
        Test = {
            return ($documentContent -match "### Priorités de Formation")
        }
    },
    @{
        Name = "Test de la présence du recrutement"
        Test = {
            return ($documentContent -match "### Recrutement")
        }
    },
    @{
        Name = "Test de la présence de l'allocation des ressources"
        Test = {
            return ($documentContent -match "### Allocation des Ressources")
        }
    },
    @{
        Name = "Test de la présence de la gestion des connaissances"
        Test = {
            return ($documentContent -match "### Gestion des Connaissances")
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
