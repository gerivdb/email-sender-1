<#
.SYNOPSIS
    Tests unitaires pour vÃ©rifier le document de la matrice d'estimation d'effort.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier que le document de la matrice
    d'estimation d'effort a Ã©tÃ© correctement crÃ©Ã© et contient toutes les informations nÃ©cessaires.

.PARAMETER DocumentPath
    Chemin vers le document de la matrice d'estimation d'effort.

.EXAMPLE
    .\Test-EffortEstimationMatrix.ps1 -DocumentPath "..\..\data\planning\effort-estimation-matrix.md"
    ExÃ©cute les tests unitaires pour le document de la matrice d'estimation d'effort.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-07
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
            return ($documentContent -match "# Matrice d'Estimation d'Effort")
        }
    },
    @{
        Name = "Test de la prÃ©sence du principe de la matrice"
        Test = {
            return ($documentContent -match "## Principe de la Matrice")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la structure de la matrice"
        Test = {
            return ($documentContent -match "## Structure de la Matrice")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la matrice d'estimation d'effort"
        Test = {
            return ($documentContent -match "## Matrice d'Estimation d'Effort \(en jours-personnes\)")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de la matrice"
        Test = {
            return ($documentContent -match "\| Taille de l'Ã©quipe \| ComplexitÃ© 1 \(TrÃ¨s faible\) \| ComplexitÃ© 2 \(Faible\) \| ComplexitÃ© 3 \(Moyen\) \| ComplexitÃ© 4 \(Ã‰levÃ©\) \| ComplexitÃ© 5 \(TrÃ¨s Ã©levÃ©\) \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence des facteurs d'ajustement"
        Test = {
            return ($documentContent -match "## Facteurs d'Ajustement")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau des facteurs d'ajustement"
        Test = {
            return ($documentContent -match "\| Facteur d'ajustement \| Impact \| Multiplicateur \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la formule de calcul"
        Test = {
            return ($documentContent -match "## Formule de Calcul")
        }
    },
    @{
        Name = "Test de la prÃ©sence des exemples d'application"
        Test = {
            return ($documentContent -match "## Exemples d'Application")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'exemple 1"
        Test = {
            return ($documentContent -match "### Exemple 1 : AmÃ©lioration de complexitÃ© faible")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'exemple 2"
        Test = {
            return ($documentContent -match "### Exemple 2 : AmÃ©lioration de complexitÃ© moyenne")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'exemple 3"
        Test = {
            return ($documentContent -match "### Exemple 3 : AmÃ©lioration de complexitÃ© Ã©levÃ©e")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la conversion en durÃ©e calendaire"
        Test = {
            return ($documentContent -match "## Conversion en DurÃ©e Calendaire")
        }
    },
    @{
        Name = "Test de la prÃ©sence des considÃ©rations importantes"
        Test = {
            return ($documentContent -match "## ConsidÃ©rations Importantes")
        }
    },
    @{
        Name = "Test de la prÃ©sence des limites de la matrice"
        Test = {
            return ($documentContent -match "## Limites de la Matrice")
        }
    },
    @{
        Name = "Test de la prÃ©sence du processus d'utilisation recommandÃ©"
        Test = {
            return ($documentContent -match "## Processus d'Utilisation RecommandÃ©")
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
