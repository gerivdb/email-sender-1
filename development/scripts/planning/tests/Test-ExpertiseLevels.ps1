<#
.SYNOPSIS
    Tests unitaires pour vÃ©rifier le document de dÃ©finition des niveaux d'expertise.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier que le document de dÃ©finition
    des niveaux d'expertise a Ã©tÃ© correctement crÃ©Ã© et contient toutes les informations nÃ©cessaires.

.PARAMETER DocumentPath
    Chemin vers le document de dÃ©finition des niveaux d'expertise.

.EXAMPLE
    .\Test-ExpertiseLevels.ps1 -DocumentPath "..\..\data\planning\expertise-levels.md"
    ExÃ©cute les tests unitaires pour le document de dÃ©finition des niveaux d'expertise.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-09
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
            return ($documentContent -match "# DÃ©finition des Niveaux d'Expertise")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'objectif"
        Test = {
            return ($documentContent -match "## Objectif")
        }
    },
    @{
        Name = "Test de la prÃ©sence des niveaux d'expertise"
        Test = {
            return ($documentContent -match "## Niveaux d'Expertise")
        }
    },
    @{
        Name = "Test de la prÃ©sence du niveau dÃ©butant"
        Test = {
            return ($documentContent -match "### Niveau 1 : DÃ©butant")
        }
    },
    @{
        Name = "Test de la prÃ©sence du niveau intermÃ©diaire"
        Test = {
            return ($documentContent -match "### Niveau 2 : IntermÃ©diaire")
        }
    },
    @{
        Name = "Test de la prÃ©sence du niveau avancÃ©"
        Test = {
            return ($documentContent -match "### Niveau 3 : AvancÃ©")
        }
    },
    @{
        Name = "Test de la prÃ©sence du niveau expert"
        Test = {
            return ($documentContent -match "### Niveau 4 : Expert")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la matrice d'Ã©valuation"
        Test = {
            return ($documentContent -match "## Matrice d'Ã‰valuation des CompÃ©tences")
        }
    },
    @{
        Name = "Test de la prÃ©sence du tableau de la matrice d'Ã©valuation"
        Test = {
            return ($documentContent -match "\| CritÃ¨re \| DÃ©butant \(1\) \| IntermÃ©diaire \(2\) \| AvancÃ© \(3\) \| Expert \(4\) \|")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'application aux compÃ©tences spÃ©cifiques"
        Test = {
            return ($documentContent -match "## Application aux CompÃ©tences SpÃ©cifiques")
        }
    },
    @{
        Name = "Test de la prÃ©sence de PowerShell"
        Test = {
            return ($documentContent -match "### PowerShell")
        }
    },
    @{
        Name = "Test de la prÃ©sence du dÃ©veloppement web"
        Test = {
            return ($documentContent -match "### DÃ©veloppement Web")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la sÃ©curitÃ© informatique"
        Test = {
            return ($documentContent -match "### SÃ©curitÃ© Informatique")
        }
    },
    @{
        Name = "Test de la prÃ©sence de l'utilisation dans le contexte du projet"
        Test = {
            return ($documentContent -match "## Utilisation dans le Contexte du Projet")
        }
    },
    @{
        Name = "Test de la prÃ©sence du processus d'Ã©valuation"
        Test = {
            return ($documentContent -match "## Processus d'Ã‰valuation")
        }
    },
    @{
        Name = "Test de la prÃ©sence de la conclusion"
        Test = {
            return ($documentContent -match "## Conclusion")
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
