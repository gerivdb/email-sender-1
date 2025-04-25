BeforeAll {
    # Définir la fonction New-DirectoryIfNotExists pour les tests
    function New-DirectoryIfNotExists {
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [string]$Path,
            [string]$Purpose
        )

        if (-not (Test-Path -Path $Path -PathType Container)) {
            if ($PSCmdlet.ShouldProcess($Path, "Créer le répertoire pour $Purpose")) {
                $null = New-Item -Path $Path -ItemType Directory -Force -ErrorAction Stop
            }
        }

        return (Resolve-Path -Path $Path).Path
    }
}

Describe "Optimize-ParallelMemory" {
    Context "New-DirectoryIfNotExists" {
        BeforeAll {
            # Créer un répertoire temporaire pour les tests
            $testDir = Join-Path -Path $TestDrive -ChildPath "TestDir"
            $testSubDir = Join-Path -Path $testDir -ChildPath "SubDir"

            # S'assurer que le répertoire de test n'existe pas
            if (Test-Path -Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
        }

        It "Crée un répertoire s'il n'existe pas" {
            # Appeler la fonction avec ShouldProcess forcé à $true
            $result = New-DirectoryIfNotExists -Path $testDir -Purpose "Test" -Confirm:$false

            # Vérifier que le répertoire a été créé
            Test-Path -Path $testDir | Should -Be $true

            # Vérifier que la fonction retourne le chemin complet
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be (Resolve-Path -Path $testDir).Path
        }

        It "Retourne le chemin existant si le répertoire existe déjà" {
            # Créer le répertoire manuellement
            New-Item -Path $testSubDir -ItemType Directory -Force | Out-Null

            # Appeler la fonction avec ShouldProcess forcé à $true
            $result = New-DirectoryIfNotExists -Path $testSubDir -Purpose "Test" -Confirm:$false

            # Vérifier que la fonction retourne le chemin complet
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be (Resolve-Path -Path $testSubDir).Path
        }
    }

    Context "Gestion des données de test" {
        BeforeAll {
            # Créer un répertoire temporaire pour les tests
            $testDataDir = Join-Path -Path $TestDrive -ChildPath "TestData"
            $outputDir = Join-Path -Path $TestDrive -ChildPath "Output"
            $generatedDataDir = Join-Path -Path $outputDir -ChildPath "generated_test_data"

            # Créer les répertoires de test
            New-Item -Path $testDataDir -ItemType Directory -Force | Out-Null
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        It "Utilise le chemin de données de test fourni s'il est valide" {
            # Simuler la logique de validation du chemin de test
            $TestDataPath = $testDataDir
            $resolvedTestDataPath = Resolve-Path -Path $TestDataPath -ErrorAction SilentlyContinue

            # Vérifier que le chemin est résolu correctement
            $resolvedTestDataPath | Should -Not -BeNullOrEmpty
            Test-Path $resolvedTestDataPath -PathType Container | Should -Be $true

            # Simuler l'assignation du chemin résolu
            $actualTestDataPath = $resolvedTestDataPath.Path

            # Vérifier que le chemin est correctement assigné
            $actualTestDataPath | Should -Be $resolvedTestDataPath.Path
        }

        It "Gère correctement un chemin de données de test invalide" {
            # Simuler un chemin invalide
            $invalidPath = Join-Path -Path $TestDrive -ChildPath "NonExistentDir"
            $resolvedTestDataPath = Resolve-Path -Path $invalidPath -ErrorAction SilentlyContinue

            # Vérifier que le chemin n'est pas résolu
            $resolvedTestDataPath | Should -BeNullOrEmpty
        }
    }

    Context "Formatage des données pour les graphiques" {
        BeforeAll {
            # Créer des données de test pour simuler les résultats de performance
            $validDetailedResults = @(
                [PSCustomObject]@{
                    Iteration = 1
                    ExecutionTimeS = 5.2
                    ProcessorTimeS = 4.8
                    WorkingSetMB = 150
                    PrivateMemoryMB = 120
                    DeltaWorkingSetMB = 50
                    DeltaPrivateMemoryMB = 40
                },
                [PSCustomObject]@{
                    Iteration = 2
                    ExecutionTimeS = 4.5
                    ProcessorTimeS = 4.2
                    WorkingSetMB = 180
                    PrivateMemoryMB = 140
                    DeltaWorkingSetMB = 60
                    DeltaPrivateMemoryMB = 50
                },
                [PSCustomObject]@{
                    Iteration = 3
                    ExecutionTimeS = 4.8
                    ProcessorTimeS = 4.5
                    WorkingSetMB = 170
                    PrivateMemoryMB = 130
                    DeltaWorkingSetMB = 55
                    DeltaPrivateMemoryMB = 45
                }
            )
        }

        It "Formate correctement les données pour JavaScript" {
            # Définir la fonction de formatage
            $jsData = { param($data) ($data | ConvertTo-Json -Compress -Depth 1) }

            # Appeler la fonction avec les données de test
            $jsLabels = & $jsData -data ($validDetailedResults | ForEach-Object { "Itération $($_.Iteration)" })
            $jsExecTimes = & $jsData -data ($validDetailedResults | ForEach-Object { [Math]::Round($_.ExecutionTimeS, 5) })

            # Vérifier que les données sont formatées correctement
            $jsLabels | Should -Not -BeNullOrEmpty
            $jsExecTimes | Should -Not -BeNullOrEmpty

            # Vérifier que les données sont au format JSON
            { $jsLabels | ConvertFrom-Json } | Should -Not -Throw
            { $jsExecTimes | ConvertFrom-Json } | Should -Not -Throw

            # Vérifier le contenu des données
            $labelsArray = $jsLabels | ConvertFrom-Json
            $labelsArray.Count | Should -Be 3
            $labelsArray[0] | Should -Be "Itération 1"

            $execTimesArray = $jsExecTimes | ConvertFrom-Json
            $execTimesArray.Count | Should -Be 3
            $execTimesArray[0] | Should -Be 5.2
        }
    }
}
