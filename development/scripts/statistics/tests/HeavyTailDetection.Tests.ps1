# Tests pour les fonctions de détection des distributions à queues lourdes
# Run with Pester: Invoke-Pester -Path ".\HeavyTailDetection.Tests.ps1"

# Importer le module à tester
$scriptPath = Split-Path -Parent $PSScriptRoot
. "$scriptPath\HeavyTailDetection.ps1"

# Fonction utilitaire pour générer des échantillons de distribution normale
function Get-NormalSample {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$NumPoints,

        [Parameter(Mandatory = $false)]
        [double]$Mean = 0,

        [Parameter(Mandatory = $false)]
        [double]$StdDev = 1
    )

    $sample = @()
    for ($i = 0; $i -lt $NumPoints; $i++) {
        # Méthode Box-Muller pour générer des nombres aléatoires suivant une distribution normale
        $u1 = [Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1)
        $u2 = Get-Random -Minimum 0 -Maximum 1
        $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
        $sample += $Mean + $StdDev * $z
    }

    return $sample
}

# Fonction utilitaire pour générer des échantillons de distribution à queue lourde (Pareto)
function Get-ParetoSample {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$NumPoints,

        [Parameter(Mandatory = $false)]
        [double]$Alpha = 1.5,

        [Parameter(Mandatory = $false)]
        [double]$Scale = 1
    )

    $sample = @()
    for ($i = 0; $i -lt $NumPoints; $i++) {
        $u = Get-Random -Minimum 0 -Maximum 1
        $x = $Scale / [Math]::Pow(1 - $u, 1 / $Alpha)
        $sample += $x
    }

    return $sample
}

# Fonction utilitaire pour générer des échantillons de distribution à queue lourde (t de Student)
function Get-StudentTSample {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$NumPoints,

        [Parameter(Mandatory = $false)]
        [double]$Df = 3
    )

    $sample = @()
    for ($i = 0; $i -lt $NumPoints; $i++) {
        # Générer un échantillon suivant une distribution t de Student
        $u1 = [Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1)
        $u2 = Get-Random -Minimum 0 -Maximum 1
        $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)  # Distribution normale standard
        $chi2 = 0
        for ($j = 0; $j -lt $Df; $j++) {
            $v = [Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1)
            $chi2 -= 2 * [Math]::Log($v)
        }
        $t = $z / [Math]::Sqrt($chi2 / $Df)  # Distribution t de Student
        $sample += $t
    }

    return $sample
}

Describe "Tests pour Get-NormalQuantile" {
    Context "Tests de base" {
        It "Devrait retourner 0 pour P = 0.5" {
            $result = Get-NormalQuantile -P 0.5
            $result | Should -BeApproximately 0 0.01
        }

        It "Devrait retourner 1.96 pour P = 0.975" {
            $result = Get-NormalQuantile -P 0.975
            $result | Should -BeApproximately 1.96 0.01
        }

        It "Devrait retourner -1.96 pour P = 0.025" {
            $result = Get-NormalQuantile -P 0.025
            $result | Should -BeApproximately -1.96 0.01
        }

        It "Devrait retourner l'infini négatif pour P = 0" {
            $result = Get-NormalQuantile -P 0
            $result | Should -Be ([double]::NegativeInfinity)
        }

        It "Devrait retourner l'infini positif pour P = 1" {
            $result = Get-NormalQuantile -P 1
            $result | Should -Be ([double]::PositiveInfinity)
        }
    }
}

Describe "Tests pour Get-HillTailIndex" {
    Context "Tests de base" {
        BeforeAll {
            # Générer des échantillons de différentes distributions
            $normalSample = Get-NormalSample -NumPoints 1000 -Mean 0 -StdDev 1
            $paretoSample = Get-ParetoSample -NumPoints 1000 -Alpha 1.5 -Scale 1
            $studentTSample = Get-StudentTSample -NumPoints 1000 -Df 3
        }

        It "Devrait calculer l'indice de queue de Hill pour une distribution normale" {
            $result = Get-HillTailIndex -Data $normalSample -K 50

            $result | Should -Not -BeNullOrEmpty
            $result.Index | Should -BeOfType [double]
            $result.Index | Should -BeGreaterThan 2
            $result.IsHeavyTailed | Should -Be $false
        }

        It "Devrait calculer l'indice de queue de Hill pour une distribution de Pareto" {
            $result = Get-HillTailIndex -Data $paretoSample -K 50

            $result | Should -Not -BeNullOrEmpty
            $result.Index | Should -BeOfType [double]
            $result.Index | Should -BeApproximately 1.5 0.5
            $result.IsHeavyTailed | Should -Be $true
        }

        It "Devrait calculer l'indice de queue de Hill pour une distribution t de Student" {
            $result = Get-HillTailIndex -Data $studentTSample -K 50

            $result | Should -Not -BeNullOrEmpty
            $result.Index | Should -BeOfType [double]
            $result.Index | Should -BeApproximately 3 1
            $result.IsHeavyTailed | Should -Be ($result.Index -lt 2)
        }

        It "Devrait calculer l'indice de queue de Hill pour différentes valeurs de K" {
            $result1 = Get-HillTailIndex -Data $paretoSample -K 20
            $result2 = Get-HillTailIndex -Data $paretoSample -K 50
            $result3 = Get-HillTailIndex -Data $paretoSample -K 100

            $result1.Index | Should -BeOfType [double]
            $result2.Index | Should -BeOfType [double]
            $result3.Index | Should -BeOfType [double]

            # Les indices devraient être similaires pour différentes valeurs de K
            $result1.Index | Should -BeApproximately $result2.Index 0.5
            $result2.Index | Should -BeApproximately $result3.Index 0.5
        }

        It "Devrait calculer l'indice de queue de Hill pour différentes queues" {
            $result1 = Get-HillTailIndex -Data $paretoSample -K 50 -Tail "Right"
            $result2 = Get-HillTailIndex -Data $paretoSample -K 50 -Tail "Left"
            $result3 = Get-HillTailIndex -Data $paretoSample -K 50 -Tail "Both"

            $result1.Index | Should -BeOfType [double]
            $result2.Index | Should -BeOfType [double]
            $result3.Index | Should -BeOfType [double]

            # L'indice pour la queue droite devrait être plus petit (queue plus lourde)
            $result1.Index | Should -BeLessThan $result2.Index
        }
    }
}

Describe "Tests pour Get-HillTailIndexPlot" {
    Context "Tests de base" {
        BeforeAll {
            # Générer des échantillons de différentes distributions
            $normalSample = Get-NormalSample -NumPoints 1000 -Mean 0 -StdDev 1
            $paretoSample = Get-ParetoSample -NumPoints 1000 -Alpha 1.5 -Scale 1
        }

        It "Devrait calculer l'indice de queue de Hill pour différentes valeurs de K" {
            $result = Get-HillTailIndexPlot -Data $paretoSample -MinK 10 -MaxK 100

            $result | Should -Not -BeNullOrEmpty
            $result.KValues | Should -Not -BeNullOrEmpty
            $result.IndexValues | Should -Not -BeNullOrEmpty
            $result.OptimalK | Should -BeOfType [int]
            $result.OptimalIndex | Should -Not -BeNullOrEmpty

            $result.KValues.Count | Should -Be 91
            $result.IndexValues.Count | Should -Be 91
            $result.OptimalK | Should -BeGreaterThan 10
            $result.OptimalK | Should -BeLessThan 100
            $result.OptimalIndex.Index | Should -BeApproximately 1.5 0.5
        }

        It "Devrait déterminer la valeur optimale de K" {
            $result = Get-HillTailIndexPlot -Data $paretoSample -MinK 10 -MaxK 100

            $result.OptimalK | Should -BeOfType [int]
            $result.OptimalIndex | Should -Not -BeNullOrEmpty

            # La valeur optimale de K devrait être dans la plage spécifiée
            $result.OptimalK | Should -BeGreaterThan 10
            $result.OptimalK | Should -BeLessThan 100
        }
    }
}

Describe "Tests pour Test-HeavyTail" {
    Context "Tests de base" {
        BeforeAll {
            # Générer des échantillons de différentes distributions
            $normalSample = Get-NormalSample -NumPoints 1000 -Mean 0 -StdDev 1
            $paretoSample1 = Get-ParetoSample -NumPoints 1000 -Alpha 0.8 -Scale 1  # Queue très lourde (indice < 1)
            $paretoSample2 = Get-ParetoSample -NumPoints 1000 -Alpha 1.5 -Scale 1  # Queue lourde (1 <= indice < 2)
            $studentTSample = Get-StudentTSample -NumPoints 1000 -Df 3  # Queue modérément lourde (2 <= indice < 3)
        }

        It "Devrait détecter une distribution normale comme n'ayant pas de queue lourde" {
            $result = Test-HeavyTail -Data $normalSample

            $result | Should -Not -BeNullOrEmpty
            $result.IsHeavyTailed | Should -Be $false
            $result.HillIndex | Should -BeGreaterThan 2
            $result.Interpretation | Should -Match "n'a pas de queue lourde"
        }

        It "Devrait détecter une distribution de Pareto avec alpha = 0.8 comme ayant une queue très lourde" {
            $result = Test-HeavyTail -Data $paretoSample1

            $result | Should -Not -BeNullOrEmpty
            $result.IsHeavyTailed | Should -Be $true
            $result.HillIndex | Should -BeLessThan 1
            $result.Interpretation | Should -Match "queue très lourde"
        }

        It "Devrait détecter une distribution de Pareto avec alpha = 1.5 comme ayant une queue lourde" {
            $result = Test-HeavyTail -Data $paretoSample2

            $result | Should -Not -BeNullOrEmpty
            $result.IsHeavyTailed | Should -Be $true
            $result.HillIndex | Should -BeGreaterThan 1
            $result.HillIndex | Should -BeLessThan 2
            $result.Interpretation | Should -Match "queue lourde"
        }

        It "Devrait détecter une distribution t de Student avec df = 3 comme ayant une queue modérément lourde" {
            $result = Test-HeavyTail -Data $studentTSample

            $result | Should -Not -BeNullOrEmpty
            $result.IsHeavyTailed | Should -Be ($result.HillIndex -lt 2)
            $result.HillIndex | Should -BeApproximately 3 1
            $result.Interpretation | Should -Match ($result.HillIndex -lt 2 ? "queue lourde" : "queue modérément lourde")
        }
    }
}

Describe "Tests pour Test-KolmogorovSmirnov" {
    Context "Tests de base" {
        BeforeAll {
            # Générer des échantillons de différentes distributions
            $normalSample = Get-NormalSample -NumPoints 1000 -Mean 0 -StdDev 1
            $paretoSample = Get-ParetoSample -NumPoints 1000 -Alpha 1.5 -Scale 1
            $exponentialSample = @()
            for ($i = 0; $i -lt 1000; $i++) {
                $u = Get-Random -Minimum 0 -Maximum 1
                $exponentialSample += - [Math]::Log(1 - $u) / 2  # Taux = 2
            }
        }

        It "Devrait détecter une distribution normale" {
            $result = Test-KolmogorovSmirnov -Data $normalSample -Distribution "Normal"

            $result | Should -Not -BeNullOrEmpty
            $result.TestStatistic | Should -BeOfType [double]
            $result.PValue | Should -BeOfType [double]
            $result.CriticalValue | Should -BeOfType [double]
            $result.IsHeavyTailed | Should -Be $false
            $result.BestFitDistribution | Should -Be "Normal"
            $result.Interpretation | Should -Match "normale"
        }

        It "Devrait détecter une distribution de Pareto" {
            $result = Test-KolmogorovSmirnov -Data $paretoSample -Distribution "Pareto"

            $result | Should -Not -BeNullOrEmpty
            $result.TestStatistic | Should -BeOfType [double]
            $result.PValue | Should -BeOfType [double]
            $result.CriticalValue | Should -BeOfType [double]
            $result.IsHeavyTailed | Should -Be $true
            $result.BestFitDistribution | Should -Be "Pareto"
            $result.Parameters["Alpha"] | Should -BeApproximately 1.5 0.5
            $result.Interpretation | Should -Match "queue lourde"
        }

        It "Devrait détecter une distribution exponentielle" {
            $result = Test-KolmogorovSmirnov -Data $exponentialSample -Distribution "Exponential"

            $result | Should -Not -BeNullOrEmpty
            $result.TestStatistic | Should -BeOfType [double]
            $result.PValue | Should -BeOfType [double]
            $result.CriticalValue | Should -BeOfType [double]
            $result.IsHeavyTailed | Should -Be $false
            $result.BestFitDistribution | Should -Be "Exponential"
            $result.Parameters["Rate"] | Should -BeApproximately 2 0.5
            $result.Interpretation | Should -Match "exponentielle"
        }

        It "Devrait détecter une distribution normale comme n'étant pas une distribution de Pareto" {
            $result = Test-KolmogorovSmirnov -Data $normalSample -Distribution "Pareto"

            $result | Should -Not -BeNullOrEmpty
            $result.TestStatistic | Should -BeOfType [double]
            $result.PValue | Should -BeOfType [double]
            $result.CriticalValue | Should -BeOfType [double]
            $result.TestStatistic | Should -BeGreaterThan $result.CriticalValue
            $result.Interpretation | Should -Match "ne correspond pas"
        }

        It "Devrait détecter une distribution de Pareto comme n'étant pas une distribution normale" {
            $result = Test-KolmogorovSmirnov -Data $paretoSample -Distribution "Normal"

            $result | Should -Not -BeNullOrEmpty
            $result.TestStatistic | Should -BeOfType [double]
            $result.PValue | Should -BeOfType [double]
            $result.CriticalValue | Should -BeOfType [double]
            $result.TestStatistic | Should -BeGreaterThan $result.CriticalValue
            $result.BestFitDistribution | Should -BeIn @("Pareto", "LogNormal")
            $result.IsHeavyTailed | Should -Be $true
        }
    }
}

Describe "Tests pour Test-HeavyTailComprehensive" {
    Context "Tests de base" {
        BeforeAll {
            # Générer des échantillons de différentes distributions
            $normalSample = Get-NormalSample -NumPoints 1000 -Mean 0 -StdDev 1
            $paretoSample = Get-ParetoSample -NumPoints 1000 -Alpha 1.5 -Scale 1
            $studentTSample = Get-StudentTSample -NumPoints 1000 -Df 3
        }

        It "Devrait détecter une distribution normale comme n'ayant pas de queue lourde" {
            $result = Test-HeavyTailComprehensive -Data $normalSample -Methods "All"

            $result | Should -Not -BeNullOrEmpty
            $result.IsHeavyTailed | Should -Be $false
            $result.HillIndex | Should -BeGreaterThan 2
            $result.Interpretation | Should -Match "Aucune des méthodes"
        }

        It "Devrait détecter une distribution de Pareto comme ayant une queue lourde" {
            $result = Test-HeavyTailComprehensive -Data $paretoSample -Methods "All"

            $result | Should -Not -BeNullOrEmpty
            $result.IsHeavyTailed | Should -Be $true
            $result.HillIndex | Should -BeApproximately 1.5 0.5
            $result.Interpretation | Should -Match "queue lourde"
        }

        It "Devrait fonctionner avec la méthode de Hill uniquement" {
            $result = Test-HeavyTailComprehensive -Data $paretoSample -Methods "Hill"

            $result | Should -Not -BeNullOrEmpty
            $result.IsHeavyTailed | Should -Be $true
            $result.HillIndex | Should -BeApproximately 1.5 0.5
            $result.KSTestStatistic | Should -Be $null
            $result.BestFitDistribution | Should -Be $null
        }

        It "Devrait fonctionner avec la méthode de Kolmogorov-Smirnov uniquement" {
            $result = Test-HeavyTailComprehensive -Data $paretoSample -Methods "KS"

            $result | Should -Not -BeNullOrEmpty
            $result.IsHeavyTailed | Should -Be $true
            $result.HillIndex | Should -Be $null
            $result.KSTestStatistic | Should -BeOfType [double]
            $result.BestFitDistribution | Should -BeIn @("Pareto", "LogNormal")
        }

        It "Devrait analyser différentes queues" {
            $result1 = Test-HeavyTailComprehensive -Data $studentTSample -Methods "All" -Tail "Right"
            $result2 = Test-HeavyTailComprehensive -Data $studentTSample -Methods "All" -Tail "Left"
            $result3 = Test-HeavyTailComprehensive -Data $studentTSample -Methods "All" -Tail "Both"

            $result1 | Should -Not -BeNullOrEmpty
            $result2 | Should -Not -BeNullOrEmpty
            $result3 | Should -Not -BeNullOrEmpty

            $result1.Tail | Should -Be "Right"
            $result2.Tail | Should -Be "Left"
            $result3.Tail | Should -Be "Both"
        }
    }
}
