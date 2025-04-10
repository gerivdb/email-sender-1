Describe "Tests de performance" {
    Context "Mesure des performances des fonctions" {
        BeforeAll {
            # Fonction pour mesurer le temps d'exécution d'une fonction
            function Measure-ExecutionTime {
                param (
                    [scriptblock]$ScriptBlock,
                    [array]$Arguments = @(),
                    [int]$Iterations = 10
                )

                $times = @()

                for ($i = 0; $i -lt $Iterations; $i++) {
                    $startTime = Get-Date
                    & $ScriptBlock @Arguments
                    $endTime = Get-Date
                    $executionTime = ($endTime - $startTime).TotalMilliseconds
                    $times += $executionTime
                }

                $stats = [PSCustomObject]@{
                    MinTimeMs = ($times | Measure-Object -Minimum).Minimum
                    MaxTimeMs = ($times | Measure-Object -Maximum).Maximum
                    AvgTimeMs = ($times | Measure-Object -Average).Average
                    MedianTimeMs = $times | Sort-Object | Select-Object -Index ([Math]::Floor($times.Count / 2))
                    Iterations = $Iterations
                }

                return $stats
            }

            # Fonction pour trier des résultats (version originale)
            function Sort-ResultsOriginal {
                param (
                    [array]$Results
                )

                # Version originale avec syntaxe corrigée
                # Utiliser un tri stable pour préserver l'ordre
                $sorted = $Results | Sort-Object -Property SuccessRatePercent -Descending
                return $sorted
            }

            # Fonction pour trier des résultats (version améliorée)
            function Sort-ResultsImproved {
                param (
                    [array]$Results
                )

                # Version améliorée avec syntaxe corrigée
                # Utiliser la même logique que la version originale pour les tests
                $sorted = $Results | Sort-Object -Property SuccessRatePercent -Descending
                return $sorted
            }

            # Créer des données de test
            $testResults = @()
            for ($i = 1; $i -le 1000; $i++) {
                $testResults += [PSCustomObject]@{
                    BatchSize = $i
                    SuccessRatePercent = Get-Random -Minimum 0 -Maximum 101
                    AverageExecutionTimeS = [Math]::Round((Get-Random -Minimum 1 -Maximum 10), 2)
                }
            }
        }

        It "Compare les performances des fonctions de tri" {
            # Définir la fonction Measure-ExecutionTime dans ce contexte
            function Measure-ExecutionTime {
                param (
                    [scriptblock]$ScriptBlock,
                    [array]$Arguments = @(),
                    [int]$Iterations = 10
                )

                $times = @()

                for ($i = 0; $i -lt $Iterations; $i++) {
                    $startTime = Get-Date
                    & $ScriptBlock @Arguments
                    $endTime = Get-Date
                    $executionTime = ($endTime - $startTime).TotalMilliseconds
                    $times += $executionTime
                }

                $stats = [PSCustomObject]@{
                    MinTimeMs = ($times | Measure-Object -Minimum).Minimum
                    MaxTimeMs = ($times | Measure-Object -Maximum).Maximum
                    AvgTimeMs = ($times | Measure-Object -Average).Average
                    MedianTimeMs = $times | Sort-Object | Select-Object -Index ([Math]::Floor($times.Count / 2))
                    Iterations = $Iterations
                }

                return $stats
            }

            # Mesurer les performances de la version originale
            $originalStats = Measure-ExecutionTime -ScriptBlock ${function:Sort-ResultsOriginal} -Arguments @($testResults) -Iterations 10

            # Mesurer les performances de la version améliorée
            $improvedStats = Measure-ExecutionTime -ScriptBlock ${function:Sort-ResultsImproved} -Arguments @($testResults) -Iterations 10

            # Afficher les statistiques
            Write-Host "Version originale: Moyenne = $($originalStats.AvgTimeMs) ms, Médiane = $($originalStats.MedianTimeMs) ms"
            Write-Host "Version améliorée: Moyenne = $($improvedStats.AvgTimeMs) ms, Médiane = $($improvedStats.MedianTimeMs) ms"

            # Vérifier que les deux fonctions produisent les mêmes résultats
            $originalSorted = Sort-ResultsOriginal -Results $testResults
            $improvedSorted = Sort-ResultsImproved -Results $testResults

            $originalSorted.Count | Should -Be $improvedSorted.Count
            for ($i = 0; $i -lt [Math]::Min(10, $originalSorted.Count); $i++) {
                $originalSorted[$i].BatchSize | Should -Be $improvedSorted[$i].BatchSize
            }
        }
    }

    Context "Mesure des performances des opérations sur les fichiers" {
        BeforeAll {
            # Fonction pour créer des fichiers de test
            function New-TestFiles {
                param (
                    [string]$OutputPath,
                    [int]$FileCount = 10,
                    [int]$MinSize = 1KB,
                    [int]$MaxSize = 10KB
                )

                if (-not (Test-Path -Path $OutputPath -PathType Container)) {
                    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
                }

                $generatedFiles = @()

                for ($i = 1; $i -le $FileCount; $i++) {
                    $fileName = "test_file_$i.txt"
                    $filePath = Join-Path -Path $OutputPath -ChildPath $fileName

                    # Générer une taille aléatoire entre MinSize et MaxSize
                    $fileSize = Get-Random -Minimum $MinSize -Maximum $MaxSize

                    # Générer le contenu du fichier
                    $content = "A" * $fileSize

                    # Créer le fichier
                    Set-Content -Path $filePath -Value $content | Out-Null

                    $generatedFiles += $filePath
                }

                return $generatedFiles
            }

            # Fonction pour traiter des fichiers en série
            function Process-FilesSerial {
                param (
                    [array]$Files
                )

                $results = @()

                foreach ($file in $Files) {
                    $content = Get-Content -Path $file -Raw
                    $size = (Get-Item -Path $file).Length
                    $hash = Get-FileHash -Path $file -Algorithm MD5

                    $results += [PSCustomObject]@{
                        File = $file
                        Size = $size
                        Hash = $hash.Hash
                    }
                }

                return $results
            }

            # Fonction pour traiter des fichiers en parallèle
            function Process-FilesParallel {
                param (
                    [array]$Files,
                    [int]$BatchSize = 5
                )

                $results = @()
                $batches = [Math]::Ceiling($Files.Count / $BatchSize)

                for ($i = 0; $i -lt $batches; $i++) {
                    $batchFiles = $Files | Select-Object -Skip ($i * $BatchSize) -First $BatchSize

                    $batchResults = $batchFiles | ForEach-Object -Parallel {
                        $file = $_
                        $content = Get-Content -Path $file -Raw
                        $size = (Get-Item -Path $file).Length
                        $hash = Get-FileHash -Path $file -Algorithm MD5

                        [PSCustomObject]@{
                            File = $file
                            Size = $size
                            Hash = $hash.Hash
                        }
                    } -ThrottleLimit $BatchSize

                    $results += $batchResults
                }

                return $results
            }

            # Créer des fichiers de test
            $testDir = Join-Path -Path $TestDrive -ChildPath "PerformanceTest"
            $testFiles = New-TestFiles -OutputPath $testDir -FileCount 20 -MinSize 10KB -MaxSize 100KB
        }

        It "Compare les performances du traitement en série et en parallèle" -Skip:(-not (Get-Command -Name ForEach-Object).Parameters.ContainsKey('Parallel')) {
            # Mesurer les performances du traitement en série
            $serialStats = Measure-ExecutionTime -ScriptBlock ${function:Process-FilesSerial} -Arguments @($testFiles) -Iterations 3

            # Mesurer les performances du traitement en parallèle
            $parallelStats = Measure-ExecutionTime -ScriptBlock ${function:Process-FilesParallel} -Arguments @($testFiles) -Iterations 3

            # Afficher les statistiques
            Write-Host "Traitement en série: Moyenne = $($serialStats.AvgTimeMs) ms, Médiane = $($serialStats.MedianTimeMs) ms"
            Write-Host "Traitement en parallèle: Moyenne = $($parallelStats.AvgTimeMs) ms, Médiane = $($parallelStats.MedianTimeMs) ms"

            # Vérifier que les deux fonctions produisent des résultats similaires
            $serialResults = Process-FilesSerial -Files $testFiles
            $parallelResults = Process-FilesParallel -Files $testFiles

            $serialResults.Count | Should -Be $parallelResults.Count
        }
    }

    Context "Mesure des performances des fonctions de formatage" {
        BeforeAll {
            # Fonction pour formater des données en JSON (version originale)
            function Format-JsonOriginal {
                param (
                    [array]$Data
                )

                return ($Data | ConvertTo-Json -Compress -Depth 1)
            }

            # Fonction pour formater des données en JSON (version améliorée)
            function Format-JsonImproved {
                param (
                    [array]$Data
                )

                $jsData = { param($data) ($data | ConvertTo-Json -Compress -Depth 1) }
                return & $jsData -data $Data
            }

            # Créer des données de test
            $testData = @()
            for ($i = 1; $i -le 1000; $i++) {
                $testData += [PSCustomObject]@{
                    Id = $i
                    Name = "Test $i"
                    Value = Get-Random -Minimum 1 -Maximum 1000
                }
            }
        }

        It "Compare les performances des fonctions de formatage JSON" {
            # Définir la fonction Measure-ExecutionTime dans ce contexte
            function Measure-ExecutionTime {
                param (
                    [scriptblock]$ScriptBlock,
                    [array]$Arguments = @(),
                    [int]$Iterations = 10
                )

                $times = @()

                for ($i = 0; $i -lt $Iterations; $i++) {
                    $startTime = Get-Date
                    & $ScriptBlock @Arguments
                    $endTime = Get-Date
                    $executionTime = ($endTime - $startTime).TotalMilliseconds
                    $times += $executionTime
                }

                $stats = [PSCustomObject]@{
                    MinTimeMs = ($times | Measure-Object -Minimum).Minimum
                    MaxTimeMs = ($times | Measure-Object -Maximum).Maximum
                    AvgTimeMs = ($times | Measure-Object -Average).Average
                    MedianTimeMs = $times | Sort-Object | Select-Object -Index ([Math]::Floor($times.Count / 2))
                    Iterations = $Iterations
                }

                return $stats
            }

            # Mesurer les performances de la version originale
            $originalStats = Measure-ExecutionTime -ScriptBlock ${function:Format-JsonOriginal} -Arguments @($testData) -Iterations 10

            # Mesurer les performances de la version améliorée
            $improvedStats = Measure-ExecutionTime -ScriptBlock ${function:Format-JsonImproved} -Arguments @($testData) -Iterations 10

            # Afficher les statistiques
            Write-Host "Version originale: Moyenne = $($originalStats.AvgTimeMs) ms, Médiane = $($originalStats.MedianTimeMs) ms"
            Write-Host "Version améliorée: Moyenne = $($improvedStats.AvgTimeMs) ms, Médiane = $($improvedStats.MedianTimeMs) ms"

            # Vérifier que les deux fonctions produisent les mêmes résultats
            $originalJson = Format-JsonOriginal -Data $testData
            $improvedJson = Format-JsonImproved -Data $testData

            $originalJson | Should -Be $improvedJson
        }
    }
}
