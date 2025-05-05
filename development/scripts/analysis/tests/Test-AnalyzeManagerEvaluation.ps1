<#
.SYNOPSIS
    Tests unitaires pour le script analyze-manager-evaluation.ps1.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier le bon fonctionnement
    du script analyze-manager-evaluation.ps1.

.PARAMETER ScriptPath
    Chemin vers le script analyze-manager-evaluation.ps1.

.EXAMPLE
    .\Test-AnalyzeManagerEvaluation.ps1 -ScriptPath "..\analyze-manager-evaluation.ps1"
    ExÃ©cute les tests unitaires pour le script analyze-manager-evaluation.ps1.

.NOTES
    Auteur: Analysis Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-05
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ScriptPath = "..\analyze-manager-evaluation.ps1"
)

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $ScriptPath)) {
    Write-Error "Le script est introuvable : $ScriptPath"
    exit 1
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "AnalyzeManagerEvaluationTests"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier JSON de test
$testInputFile = Join-Path -Path $testDir -ChildPath "test-manager-evaluation.json"
$testOutputFile = Join-Path -Path $testDir -ChildPath "test-manager-analysis.md"

$testData = @{
    EvaluationDate = Get-Date -Format "yyyy-MM-dd"
    Criteria = @{
        Modularity = @{
            Description = "CapacitÃ© du gestionnaire Ã  Ãªtre divisÃ© en modules indÃ©pendants"
            Weight = 0.15
        }
        Extensibility = @{
            Description = "FacilitÃ© avec laquelle le gestionnaire peut Ãªtre Ã©tendu"
            Weight = 0.15
        }
    }
    Pillars = @(
        @{
            Name = "Test Pillar 1"
            Description = "Test pillar 1 description"
        },
        @{
            Name = "Test Pillar 2"
            Description = "Test pillar 2 description"
        }
    )
    Managers = @(
        @{
            Name = "Test Manager 1"
            Description = "Test manager 1 description"
            Category = "Test"
            Scores = @{
                Modularity = 8
                Extensibility = 7
            }
            Strengths = @(
                "Strength 1",
                "Strength 2"
            )
            Weaknesses = @(
                "Weakness 1"
            )
            PillarCoverage = @{
                "Test Pillar 1" = 75
                "Test Pillar 2" = 65
            }
        },
        @{
            Name = "Test Manager 2"
            Description = "Test manager 2 description"
            Category = "Test"
            Scores = @{
                Modularity = 6
                Extensibility = 8
            }
            Strengths = @(
                "Strength 1"
            )
            Weaknesses = @(
                "Weakness 1",
                "Weakness 2"
            )
            PillarCoverage = @{
                "Test Pillar 1" = 60
                "Test Pillar 2" = 80
            }
        }
    )
    Thresholds = @{
        StrengthThreshold = 8
        WeaknessThreshold = 6
        TargetPillarCoverage = 80
        HighImpactThreshold = 20
        MediumImpactThreshold = 10
    }
    ImpactConsequences = @{
        "Ã‰levÃ©" = @(
            "ConsÃ©quence Ã©levÃ©e 1",
            "ConsÃ©quence Ã©levÃ©e 2"
        )
        "Moyen" = @(
            "ConsÃ©quence moyenne 1",
            "ConsÃ©quence moyenne 2"
        )
        "Faible" = @(
            "ConsÃ©quence faible 1",
            "ConsÃ©quence faible 2"
        )
    }
    RecommendedActions = @{
        "Ã‰levÃ©" = @(
            "Action Ã©levÃ©e 1",
            "Action Ã©levÃ©e 2"
        )
        "Moyen" = @(
            "Action moyenne 1",
            "Action moyenne 2"
        )
        "Faible" = @(
            "Action faible 1",
            "Action faible 2"
        )
    }
}

$testData | ConvertTo-Json -Depth 10 | Set-Content -Path $testInputFile -Encoding UTF8

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

# Tests unitaires
$tests = @(
    @{
        Name = "Test de l'existence du script"
        Test = {
            return (Test-Path -Path $ScriptPath -PathType Leaf)
        }
    },
    @{
        Name = "Test de la syntaxe du script"
        Test = {
            try {
                $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $ScriptPath -Raw), [ref]$null)
                return $true
            } catch {
                Write-Error "Erreur de syntaxe dans le script : $_"
                return $false
            }
        }
    },
    @{
        Name = "Test de l'exÃ©cution du script avec des donnÃ©es de test"
        Test = {
            try {
                $result = & $ScriptPath -InputFile $testInputFile -OutputFile $testOutputFile -Format "Markdown"
                return (Test-Path -Path $testOutputFile -PathType Leaf)
            } catch {
                Write-Error "Erreur lors de l'exÃ©cution du script : $_"
                return $false
            }
        }
    },
    @{
        Name = "Test du contenu du rapport gÃ©nÃ©rÃ©"
        Test = {
            try {
                $content = Get-Content -Path $testOutputFile -Raw
                return ($content -match "Test Manager 1" -and $content -match "Test Manager 2")
            } catch {
                Write-Error "Erreur lors de la vÃ©rification du contenu du rapport : $_"
                return $false
            }
        }
    },
    @{
        Name = "Test de l'exÃ©cution du script avec le format HTML"
        Test = {
            try {
                $testHtmlOutputFile = Join-Path -Path $testDir -ChildPath "test-manager-analysis.html"
                $result = & $ScriptPath -InputFile $testInputFile -OutputFile $testHtmlOutputFile -Format "HTML"
                return (Test-Path -Path $testHtmlOutputFile -PathType Leaf)
            } catch {
                Write-Error "Erreur lors de l'exÃ©cution du script avec le format HTML : $_"
                return $false
            }
        }
    },
    @{
        Name = "Test de l'exÃ©cution du script avec le format CSV"
        Test = {
            try {
                $testCsvOutputFile = Join-Path -Path $testDir -ChildPath "test-manager-analysis.csv"
                $result = & $ScriptPath -InputFile $testInputFile -OutputFile $testCsvOutputFile -Format "CSV"
                return (Test-Path -Path $testCsvOutputFile -PathType Leaf)
            } catch {
                Write-Error "Erreur lors de l'exÃ©cution du script avec le format CSV : $_"
                return $false
            }
        }
    },
    @{
        Name = "Test de l'exÃ©cution du script avec le format JSON"
        Test = {
            try {
                $testJsonOutputFile = Join-Path -Path $testDir -ChildPath "test-manager-analysis.json"
                $result = & $ScriptPath -InputFile $testInputFile -OutputFile $testJsonOutputFile -Format "JSON"
                return (Test-Path -Path $testJsonOutputFile -PathType Leaf)
            } catch {
                Write-Error "Erreur lors de l'exÃ©cution du script avec le format JSON : $_"
                return $false
            }
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

# Nettoyer les fichiers de test
Remove-Item -Path $testDir -Recurse -Force

# Retourner le rÃ©sultat
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont rÃ©ussi." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
