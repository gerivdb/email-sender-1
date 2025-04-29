<#
.SYNOPSIS
    Tests unitaires pour vérifier le document de la matrice d'estimation d'effort.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier que le document de la matrice
    d'estimation d'effort a été correctement créé et contient toutes les informations nécessaires.

.PARAMETER DocumentPath
    Chemin vers le document de la matrice d'estimation d'effort.

.EXAMPLE
    .\Test-EffortEstimationMatrix.ps1 -DocumentPath "..\..\data\planning\effort-estimation-matrix.md"
    Exécute les tests unitaires pour le document de la matrice d'estimation d'effort.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de création: 2025-05-07
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
            return ($documentContent -match "# Matrice d'Estimation d'Effort")
        }
    },
    @{
        Name = "Test de la présence du principe de la matrice"
        Test = {
            return ($documentContent -match "## Principe de la Matrice")
        }
    },
    @{
        Name = "Test de la présence de la structure de la matrice"
        Test = {
            return ($documentContent -match "## Structure de la Matrice")
        }
    },
    @{
        Name = "Test de la présence de la matrice d'estimation d'effort"
        Test = {
            return ($documentContent -match "## Matrice d'Estimation d'Effort \(en jours-personnes\)")
        }
    },
    @{
        Name = "Test de la présence du tableau de la matrice"
        Test = {
            return ($documentContent -match "\| Taille de l'équipe \| Complexité 1 \(Très faible\) \| Complexité 2 \(Faible\) \| Complexité 3 \(Moyen\) \| Complexité 4 \(Élevé\) \| Complexité 5 \(Très élevé\) \|")
        }
    },
    @{
        Name = "Test de la présence des facteurs d'ajustement"
        Test = {
            return ($documentContent -match "## Facteurs d'Ajustement")
        }
    },
    @{
        Name = "Test de la présence du tableau des facteurs d'ajustement"
        Test = {
            return ($documentContent -match "\| Facteur d'ajustement \| Impact \| Multiplicateur \|")
        }
    },
    @{
        Name = "Test de la présence de la formule de calcul"
        Test = {
            return ($documentContent -match "## Formule de Calcul")
        }
    },
    @{
        Name = "Test de la présence des exemples d'application"
        Test = {
            return ($documentContent -match "## Exemples d'Application")
        }
    },
    @{
        Name = "Test de la présence de l'exemple 1"
        Test = {
            return ($documentContent -match "### Exemple 1 : Amélioration de complexité faible")
        }
    },
    @{
        Name = "Test de la présence de l'exemple 2"
        Test = {
            return ($documentContent -match "### Exemple 2 : Amélioration de complexité moyenne")
        }
    },
    @{
        Name = "Test de la présence de l'exemple 3"
        Test = {
            return ($documentContent -match "### Exemple 3 : Amélioration de complexité élevée")
        }
    },
    @{
        Name = "Test de la présence de la conversion en durée calendaire"
        Test = {
            return ($documentContent -match "## Conversion en Durée Calendaire")
        }
    },
    @{
        Name = "Test de la présence des considérations importantes"
        Test = {
            return ($documentContent -match "## Considérations Importantes")
        }
    },
    @{
        Name = "Test de la présence des limites de la matrice"
        Test = {
            return ($documentContent -match "## Limites de la Matrice")
        }
    },
    @{
        Name = "Test de la présence du processus d'utilisation recommandé"
        Test = {
            return ($documentContent -match "## Processus d'Utilisation Recommandé")
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
