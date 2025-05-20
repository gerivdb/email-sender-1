BeforeAll {
    # Importer le module UnifiedParallel
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\development\tools\parallelization\UnifiedParallel.psm1"
    Import-Module $modulePath -Force
}

Describe "Wait-ForCompletedRunspace - Tests d'exceptions pour les collections" {
    Context "Gestion des erreurs avec des tableaux vides" {
        It "Ne devrait pas générer d'erreur avec un tableau vide et un timeout" {
            # Arrange
            $runspaces = @()

            # Act & Assert
            { Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -TimeoutSeconds 0.5 -NoProgress } | Should -Not -Throw
        }

        It "Ne devrait pas générer d'erreur avec un tableau vide et un timeout de runspace" {
            # Arrange
            $runspaces = @()

            # Act & Assert
            { Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -RunspaceTimeoutSeconds 1 -NoProgress } | Should -Not -Throw
        }

        It "Ne devrait pas générer d'erreur avec un tableau vide et la détection de deadlock" {
            # Arrange
            $runspaces = @()

            # Act & Assert
            { Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -DeadlockDetectionSeconds 1 -NoProgress } | Should -Not -Throw
        }

        It "Ne devrait pas générer d'erreur avec un tableau vide et CleanupOnTimeout" {
            # Arrange
            $runspaces = @()

            # Act & Assert
            { Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -CleanupOnTimeout -NoProgress } | Should -Not -Throw
        }
    }

    Context "Gestion des erreurs avec des tableaux contenant des éléments invalides" {
        It "Ne devrait pas générer d'erreur avec un tableau contenant des chaînes" {
            # Arrange
            $runspaces = @("test1", "test2")

            # Act & Assert
            { Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 0.5 } | Should -Not -Throw
        }

        It "Ne devrait pas générer d'erreur avec un tableau contenant des nombres" {
            # Arrange
            $runspaces = @(1, 2, 3)

            # Act & Assert
            { Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 0.5 } | Should -Not -Throw
        }

        It "Ne devrait pas générer d'erreur avec un tableau contenant des objets sans Handle" {
            # Arrange
            $runspaces = @(
                [PSCustomObject]@{ Name = "Test1" },
                [PSCustomObject]@{ Name = "Test2" }
            )

            # Act & Assert
            { Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 0.5 } | Should -Not -Throw
        }

        It "Ne devrait pas générer d'erreur avec un tableau mixte sans valeurs null" {
            # Arrange
            $runspaces = @(
                "test",
                123,
                [PSCustomObject]@{ Name = "Test" }
            )

            # Act & Assert
            { Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 0.5 } | Should -Not -Throw
        }
    }

    Context "Gestion des erreurs avec des paramètres extrêmes" {
        It "Ne devrait pas générer d'erreur avec un tableau vide et un SleepMilliseconds minimal" {
            # Arrange
            $runspaces = @()

            # Act & Assert
            { Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -SleepMilliseconds 1 -NoProgress -TimeoutSeconds 0.5 } | Should -Not -Throw
        }

        It "Ne devrait pas générer d'erreur avec un tableau vide et un SleepMilliseconds maximal" {
            # Arrange
            $runspaces = @()

            # Act & Assert
            { Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -SleepMilliseconds 1000 -NoProgress -TimeoutSeconds 0.5 } | Should -Not -Throw
        }

        It "Ne devrait pas générer d'erreur avec un tableau vide et un TimeoutSeconds très grand" {
            # Arrange
            $runspaces = @()

            # Act & Assert
            { Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -TimeoutSeconds 2147483647 -NoProgress } | Should -Not -Throw
        }
    }
}
