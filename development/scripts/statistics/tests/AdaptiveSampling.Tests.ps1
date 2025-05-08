BeforeAll {
    # Charger les modules nécessaires
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\AdaptiveSampling.ps1"
    . $modulePath
    
    $kdePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimation.psm1"
    Import-Module $kdePath -Force
}

Describe "Tests pour l'échantillonnage adaptatif" {
    Context "Tests de base pour Get-AdaptiveSampling" {
        It "Devrait retourner les données d'origine si elles sont plus petites que la taille maximale de l'échantillon" {
            $data = 1..10
            $result = Get-AdaptiveSampling -Data $data -MaxSampleSize 20
            $result.Count | Should -Be 10
            $result | Should -Be $data
        }
        
        It "Devrait échantillonner les données si elles sont plus grandes que la taille maximale de l'échantillon" {
            $data = 1..2000
            $result = Get-AdaptiveSampling -Data $data -MaxSampleSize 500
            $result.Count | Should -BeLessOrEqual 500
        }
        
        It "Devrait préserver les valeurs extrêmes si demandé" {
            $data = 1..1000
            $result = Get-AdaptiveSampling -Data $data -MaxSampleSize 100 -PreserveExtremes $true
            $result | Should -Contain 1
            $result | Should -Contain 1000
        }
        
        It "Devrait utiliser la méthode de stratification spécifiée" {
            $data = 1..1000
            $result1 = Get-AdaptiveSampling -Data $data -MaxSampleSize 100 -StratificationMethod "Quantile"
            $result2 = Get-AdaptiveSampling -Data $data -MaxSampleSize 100 -StratificationMethod "Uniform"
            
            # Les résultats devraient être différents
            $diff = Compare-Object -ReferenceObject $result1 -DifferenceObject $result2
            $diff | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Tests d'intégration avec Get-OptimalBandwidthMethod" {
        It "Devrait utiliser l'échantillonnage adaptatif pour les grands ensembles de données" {
            # Générer un grand ensemble de données
            $data = 1..2000 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            
            # Appeler Get-OptimalBandwidthMethod avec l'échantillonnage adaptatif
            $result = Get-OptimalBandwidthMethod -Data $data -UseSampling $true -MaxSampleSize 500
            
            # Vérifier que l'échantillonnage a été utilisé
            $result.UsedSampling | Should -Be $true
            $result.SampledDataCount | Should -BeLessOrEqual 500
            $result.OriginalDataCount | Should -Be 2000
        }
        
        It "Devrait produire des résultats similaires avec et sans échantillonnage pour des données normales" {
            # Générer des données normales
            $data = 1..1000 | ForEach-Object {
                $u1 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
                $u2 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
                if ($u1 -eq 0) { $u1 = 0.0001 }
                
                $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
                50 + 10 * $z
            }
            
            # Calculer la largeur de bande sans échantillonnage
            $resultWithoutSampling = Get-OptimalBandwidthMethod -Data $data -UseSampling $false
            
            # Calculer la largeur de bande avec échantillonnage
            $resultWithSampling = Get-OptimalBandwidthMethod -Data $data -UseSampling $true -MaxSampleSize 200
            
            # Les largeurs de bande devraient être similaires (à 20% près)
            $relativeDifference = [Math]::Abs(($resultWithSampling.Bandwidth - $resultWithoutSampling.Bandwidth) / $resultWithoutSampling.Bandwidth)
            $relativeDifference | Should -BeLessOrEqual 0.2
        }
    }
    
    Context "Tests de performance pour l'échantillonnage adaptatif" {
        It "Devrait être plus rapide avec l'échantillonnage pour les grands ensembles de données" {
            # Générer un grand ensemble de données
            $data = 1..3000 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            
            # Mesurer le temps sans échantillonnage (limité à un petit sous-ensemble pour éviter des tests trop longs)
            $startTime = Get-Date
            $resultWithoutSampling = Get-OptimalBandwidthMethod -Data $data[0..999] -UseSampling $false
            $endTime = Get-Date
            $timeWithoutSampling = ($endTime - $startTime).TotalSeconds
            
            # Mesurer le temps avec échantillonnage
            $startTime = Get-Date
            $resultWithSampling = Get-OptimalBandwidthMethod -Data $data -UseSampling $true -MaxSampleSize 200
            $endTime = Get-Date
            $timeWithSampling = ($endTime - $startTime).TotalSeconds
            
            # Le temps avec échantillonnage devrait être similaire ou inférieur au temps sans échantillonnage
            # même si l'ensemble de données est 3 fois plus grand
            $timeWithSampling | Should -BeLessOrEqual ($timeWithoutSampling * 1.5)
        }
    }
}

Describe "Tests pour le traitement parallèle" {
    Context "Tests de base pour le traitement parallèle" {
        It "Devrait fonctionner avec le traitement parallèle activé" {
            # Vérifier si PowerShell 7+ est utilisé
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                # Générer des données
                $data = 1..500 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
                
                # Appeler Get-OptimalBandwidthMethod avec le traitement parallèle
                $result = Get-OptimalBandwidthMethod -Data $data -UseParallel $true -MaxParallelJobs 2
                
                # Vérifier que le résultat est valide
                $result.Bandwidth | Should -BeGreaterThan 0
            }
            else {
                Set-ItResult -Skipped -Because "PowerShell 7+ est requis pour le traitement parallèle"
            }
        }
        
        It "Devrait produire des résultats similaires avec et sans traitement parallèle" {
            # Vérifier si PowerShell 7+ est utilisé
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                # Générer des données
                $data = 1..500 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
                
                # Calculer la largeur de bande sans traitement parallèle
                $resultWithoutParallel = Get-OptimalBandwidthMethod -Data $data -UseParallel $false
                
                # Calculer la largeur de bande avec traitement parallèle
                $resultWithParallel = Get-OptimalBandwidthMethod -Data $data -UseParallel $true -MaxParallelJobs 2
                
                # Les largeurs de bande devraient être identiques
                $resultWithParallel.Bandwidth | Should -Be $resultWithoutParallel.Bandwidth
            }
            else {
                Set-ItResult -Skipped -Because "PowerShell 7+ est requis pour le traitement parallèle"
            }
        }
    }
    
    Context "Tests de performance pour le traitement parallèle" {
        It "Devrait être plus rapide avec le traitement parallèle pour les méthodes multiples" {
            # Vérifier si PowerShell 7+ est utilisé
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                # Générer des données
                $data = 1..500 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
                
                # Mesurer le temps sans traitement parallèle
                $startTime = Get-Date
                $resultWithoutParallel = Get-BandwidthMethodScores -Data $data -Methods @("Silverman", "Scott", "LeaveOneOut", "KFold") -UseParallel $false
                $endTime = Get-Date
                $timeWithoutParallel = ($endTime - $startTime).TotalSeconds
                
                # Mesurer le temps avec traitement parallèle
                $startTime = Get-Date
                $resultWithParallel = Get-BandwidthMethodScores -Data $data -Methods @("Silverman", "Scott", "LeaveOneOut", "KFold") -UseParallel $true -MaxParallelJobs 4
                $endTime = Get-Date
                $timeWithParallel = ($endTime - $startTime).TotalSeconds
                
                # Le temps avec traitement parallèle devrait être inférieur au temps sans traitement parallèle
                # sur un système multi-cœurs, mais nous permettons une marge car les tests peuvent s'exécuter
                # dans des environnements variés
                $timeWithParallel | Should -BeLessOrEqual ($timeWithoutParallel * 1.5)
            }
            else {
                Set-ItResult -Skipped -Because "PowerShell 7+ est requis pour le traitement parallèle"
            }
        }
    }
}
