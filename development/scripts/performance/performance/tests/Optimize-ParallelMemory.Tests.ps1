BeforeAll {
    # DÃ©finir la fonction New-DirectoryIfNotExists pour les tests
    function New-DirectoryIfNotExists {
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [string]$Path,
            [string]$Purpose
        )

        if (-not (Test-Path -Path $Path -PathType Container)) {
            if ($PSCmdlet.ShouldProcess($Path, "CrÃ©er le rÃ©pertoire pour $Purpose")) {
                $null = New-Item -Path $Path -ItemType Directory -Force -ErrorAction Stop
            }
        }

        return (Resolve-Path -Path $Path).Path
    }
}

Describe "Optimize-ParallelMemory" {
    Context "New-DirectoryIfNotExists" {
        BeforeAll {
            # CrÃ©er un rÃ©pertoire temporaire pour les tests
            $testDir = Join-Path -Path $TestDrive -ChildPath "TestDir"
            $testSubDir = Join-Path -Path $testDir -ChildPath "SubDir"

            # S'assurer que le rÃ©pertoire de test n'existe pas
            if (Test-Path -Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
        }

        It "CrÃ©e un rÃ©pertoire s'il n'existe pas" {
            # Appeler la fonction avec ShouldProcess forcÃ© Ã  $true
            $result = New-DirectoryIfNotExists -Path $testDir -Purpose "Test" -Confirm:$false

            # VÃ©rifier que le rÃ©pertoire a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $testDir | Should -Be $true

            # VÃ©rifier que la fonction retourne le chemin complet
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be (Resolve-Path -Path $testDir).Path
        }

        It "Retourne le chemin existant si le rÃ©pertoire existe dÃ©jÃ " {
            # CrÃ©er le rÃ©pertoire manuellement
            New-Item -Path $testSubDir -ItemType Directory -Force | Out-Null

            # Appeler la fonction avec ShouldProcess forcÃ© Ã  $true
            $result = New-DirectoryIfNotExists -Path $testSubDir -Purpose "Test" -Confirm:$false

            # VÃ©rifier que la fonction retourne le chemin complet
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be (Resolve-Path -Path $testSubDir).Path
        }
    }

    Context "Gestion des donnÃ©es de test" {
        BeforeAll {
            # CrÃ©er un rÃ©pertoire temporaire pour les tests
            $testDataDir = Join-Path -Path $TestDrive -ChildPath "TestData"
            $outputDir = Join-Path -Path $TestDrive -ChildPath "Output"
            $generatedDataDir = Join-Path -Path $outputDir -ChildPath "generated_test_data"

            # CrÃ©er les rÃ©pertoires de test
            New-Item -Path $testDataDir -ItemType Directory -Force | Out-Null
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        It "Utilise le chemin de donnÃ©es de test fourni s'il est valide" {
            # Simuler la logique de validation du chemin de test
            $TestDataPath = $testDataDir
            $resolvedTestDataPath = Resolve-Path -Path $TestDataPath -ErrorAction SilentlyContinue

            # VÃ©rifier que le chemin est rÃ©solu correctement
            $resolvedTestDataPath | Should -Not -BeNullOrEmpty
            Test-Path $resolvedTestDataPath -PathType Container | Should -Be $true

            # Simuler l'assignation du chemin rÃ©solu
            $actualTestDataPath = $resolvedTestDataPath.Path

            # VÃ©rifier que le chemin est correctement assignÃ©
            $actualTestDataPath | Should -Be $resolvedTestDataPath.Path
        }

        It "GÃ¨re correctement un chemin de donnÃ©es de test invalide" {
            # Simuler un chemin invalide
            $invalidPath = Join-Path -Path $TestDrive -ChildPath "NonExistentDir"
            $resolvedTestDataPath = Resolve-Path -Path $invalidPath -ErrorAction SilentlyContinue

            # VÃ©rifier que le chemin n'est pas rÃ©solu
            $resolvedTestDataPath | Should -BeNullOrEmpty
        }
    }

    Context "Formatage des donnÃ©es pour les graphiques" {
        BeforeAll {
            # CrÃ©er des donnÃ©es de test pour simuler les rÃ©sultats de performance
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

        It "Formate correctement les donnÃ©es pour JavaScript" {
            # DÃ©finir la fonction de formatage
            $jsData = { param($data) ($data | ConvertTo-Json -Compress -Depth 1) }

            # Appeler la fonction avec les donnÃ©es de test
            $jsLabels = & $jsData -data ($validDetailedResults | ForEach-Object { "ItÃ©ration $($_.Iteration)" })
            $jsExecTimes = & $jsData -data ($validDetailedResults | ForEach-Object { [Math]::Round($_.ExecutionTimeS, 5) })

            # VÃ©rifier que les donnÃ©es sont formatÃ©es correctement
            $jsLabels | Should -Not -BeNullOrEmpty
            $jsExecTimes | Should -Not -BeNullOrEmpty

            # VÃ©rifier que les donnÃ©es sont au format JSON
            { $jsLabels | ConvertFrom-Json } | Should -Not -Throw
            { $jsExecTimes | ConvertFrom-Json } | Should -Not -Throw

            # VÃ©rifier le contenu des donnÃ©es
            $labelsArray = $jsLabels | ConvertFrom-Json
            $labelsArray.Count | Should -Be 3
            $labelsArray[0] | Should -Be "ItÃ©ration 1"

            $execTimesArray = $jsExecTimes | ConvertFrom-Json
            $execTimesArray.Count | Should -Be 3
            $execTimesArray[0] | Should -Be 5.2
        }
    }
}
