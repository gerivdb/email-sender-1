<#
.SYNOPSIS
    Tests unitaires pour le script prioritize-improvements.ps1.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier le bon fonctionnement
    du script prioritize-improvements.ps1.

.PARAMETER ScriptPath
    Chemin vers le script prioritize-improvements.ps1.

.EXAMPLE
    .\Test-PrioritizeImprovements.ps1 -ScriptPath "..\prioritize-improvements.ps1"
    ExÃ©cute les tests unitaires pour le script prioritize-improvements.ps1.

.NOTES
    Auteur: Analysis Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-06
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ScriptPath = "..\prioritize-improvements.ps1"
)

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $ScriptPath)) {
    Write-Error "Le script est introuvable : $ScriptPath"
    exit 1
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PrioritizeImprovementsTests"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier JSON de test
$testInputFile = Join-Path -Path $testDir -ChildPath "test-improvements.json"
$testOutputFile = Join-Path -Path $testDir -ChildPath "test-improvement-priorities.md"

$testData = @{
    Criteria = @{
        Impact = @{
            Description = "Impact potentiel de l'amÃ©lioration sur la qualitÃ© du code et la productivitÃ©"
            Weight = 0.5
        }
        Effort = @{
            Description = "Effort requis pour implÃ©menter l'amÃ©lioration (inversement proportionnel)"
            Weight = 0.5
        }
    }
    Thresholds = @{
        HighPriorityThreshold = 8.0
        MediumPriorityThreshold = 6.0
    }
    Managers = @(
        @{
            Name = "Test Manager 1"
            Category = "Test"
            Improvements = @(
                @{
                    Name = "Test Improvement 1"
                    Description = "Test improvement 1 description"
                    Type = "FonctionnalitÃ©"
                    Effort = "Faible"
                    Impact = "Ã‰levÃ©"
                    Dependencies = @()
                    Scores = @{
                        Impact = 9
                        Effort = 3
                    }
                },
                @{
                    Name = "Test Improvement 2"
                    Description = "Test improvement 2 description"
                    Type = "AmÃ©lioration"
                    Effort = "Moyen"
                    Impact = "Moyen"
                    Dependencies = @()
                    Scores = @{
                        Impact = 6
                        Effort = 5
                    }
                }
            )
        },
        @{
            Name = "Test Manager 2"
            Category = "Test"
            Improvements = @(
                @{
                    Name = "Test Improvement 3"
                    Description = "Test improvement 3 description"
                    Type = "Optimisation"
                    Effort = "Ã‰levÃ©"
                    Impact = "Ã‰levÃ©"
                    Dependencies = @()
                    Scores = @{
                        Impact = 8
                        Effort = 7
                    }
                }
            )
        }
    )
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
                return ($content -match "Test Improvement 1" -and $content -match "Test Improvement 2" -and $content -match "Test Improvement 3")
            } catch {
                Write-Error "Erreur lors de la vÃ©rification du contenu du rapport : $_"
                return $false
            }
        }
    },
    @{
        Name = "Test de la priorisation correcte"
        Test = {
            try {
                $content = Get-Content -Path $testOutputFile -Raw
                # Test Improvement 1 devrait avoir un score plus Ã©levÃ© que Test Improvement 2
                $improvement1Index = $content.IndexOf("Test Improvement 1")
                $improvement2Index = $content.IndexOf("Test Improvement 2")
                return ($improvement1Index -lt $improvement2Index)
            } catch {
                Write-Error "Erreur lors de la vÃ©rification de la priorisation : $_"
                return $false
            }
        }
    },
    @{
        Name = "Test de l'exÃ©cution du script avec le format HTML"
        Test = {
            try {
                $testHtmlOutputFile = Join-Path -Path $testDir -ChildPath "test-improvement-priorities.html"
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
                $testCsvOutputFile = Join-Path -Path $testDir -ChildPath "test-improvement-priorities.csv"
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
                $testJsonOutputFile = Join-Path -Path $testDir -ChildPath "test-improvement-priorities.json"
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
