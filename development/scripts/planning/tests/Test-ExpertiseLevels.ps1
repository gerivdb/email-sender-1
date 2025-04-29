<#
.SYNOPSIS
    Tests unitaires pour vérifier le document de définition des niveaux d'expertise.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier que le document de définition
    des niveaux d'expertise a été correctement créé et contient toutes les informations nécessaires.

.PARAMETER DocumentPath
    Chemin vers le document de définition des niveaux d'expertise.

.EXAMPLE
    .\Test-ExpertiseLevels.ps1 -DocumentPath "..\..\data\planning\expertise-levels.md"
    Exécute les tests unitaires pour le document de définition des niveaux d'expertise.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de création: 2025-05-09
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
            return ($documentContent -match "# Définition des Niveaux d'Expertise")
        }
    },
    @{
        Name = "Test de la présence de l'objectif"
        Test = {
            return ($documentContent -match "## Objectif")
        }
    },
    @{
        Name = "Test de la présence des niveaux d'expertise"
        Test = {
            return ($documentContent -match "## Niveaux d'Expertise")
        }
    },
    @{
        Name = "Test de la présence du niveau débutant"
        Test = {
            return ($documentContent -match "### Niveau 1 : Débutant")
        }
    },
    @{
        Name = "Test de la présence du niveau intermédiaire"
        Test = {
            return ($documentContent -match "### Niveau 2 : Intermédiaire")
        }
    },
    @{
        Name = "Test de la présence du niveau avancé"
        Test = {
            return ($documentContent -match "### Niveau 3 : Avancé")
        }
    },
    @{
        Name = "Test de la présence du niveau expert"
        Test = {
            return ($documentContent -match "### Niveau 4 : Expert")
        }
    },
    @{
        Name = "Test de la présence de la matrice d'évaluation"
        Test = {
            return ($documentContent -match "## Matrice d'Évaluation des Compétences")
        }
    },
    @{
        Name = "Test de la présence du tableau de la matrice d'évaluation"
        Test = {
            return ($documentContent -match "\| Critère \| Débutant \(1\) \| Intermédiaire \(2\) \| Avancé \(3\) \| Expert \(4\) \|")
        }
    },
    @{
        Name = "Test de la présence de l'application aux compétences spécifiques"
        Test = {
            return ($documentContent -match "## Application aux Compétences Spécifiques")
        }
    },
    @{
        Name = "Test de la présence de PowerShell"
        Test = {
            return ($documentContent -match "### PowerShell")
        }
    },
    @{
        Name = "Test de la présence du développement web"
        Test = {
            return ($documentContent -match "### Développement Web")
        }
    },
    @{
        Name = "Test de la présence de la sécurité informatique"
        Test = {
            return ($documentContent -match "### Sécurité Informatique")
        }
    },
    @{
        Name = "Test de la présence de l'utilisation dans le contexte du projet"
        Test = {
            return ($documentContent -match "## Utilisation dans le Contexte du Projet")
        }
    },
    @{
        Name = "Test de la présence du processus d'évaluation"
        Test = {
            return ($documentContent -match "## Processus d'Évaluation")
        }
    },
    @{
        Name = "Test de la présence de la conclusion"
        Test = {
            return ($documentContent -match "## Conclusion")
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
