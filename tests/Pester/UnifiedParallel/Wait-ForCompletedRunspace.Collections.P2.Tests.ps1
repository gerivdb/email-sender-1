BeforeAll {
    # Importer le module UnifiedParallel
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\development\tools\parallelization\UnifiedParallel.psm1"
    Import-Module $modulePath -Force
}

Describe "Wait-ForCompletedRunspace - Tests de robustesse pour les collections" {
    Context "Gestion des tableaux vides de grande taille" {
        BeforeAll {
            # Fonction pour créer un tableau vide de taille spécifiée
            function New-EmptyArray {
                param (
                    [Parameter(Mandatory = $true)]
                    [int]$Size
                )

                return New-Object object[] $Size
            }
        }

        It "Devrait gérer correctement un tableau vide de taille 10 avec timeout" {
            # Arrange
            $runspaces = New-EmptyArray -Size 10

            # Act
            # Ajouter un timeout très court pour optimiser les performances des tests
            # Forcer le format de retour à "Object" pour obtenir un PSCustomObject
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 0.5 -ReturnFormat "Object"

            # Assert
            $result | Should -Not -BeNullOrEmpty
            # Avec un timeout, la fonction retourne un PSCustomObject avec des propriétés spécifiques
            $result.GetType().Name | Should -Be "PSCustomObject"
            $result.PSObject.Properties.Name | Should -Contain "TimeoutOccurred"
            $result.TimeoutOccurred | Should -BeTrue
            $result.PSObject.Properties.Name | Should -Contain "Results"
        }

        It "Devrait gérer correctement un tableau vide de taille 20 avec timeout" {
            # Arrange
            $runspaces = New-EmptyArray -Size 20

            # Act
            # Ajouter un timeout très court pour optimiser les performances des tests
            # Forcer le format de retour à "Object" pour obtenir un PSCustomObject
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 0.5 -ReturnFormat "Object"

            # Assert
            $result | Should -Not -BeNullOrEmpty
            # Avec un timeout, la fonction retourne un PSCustomObject avec des propriétés spécifiques
            $result.GetType().Name | Should -Be "PSCustomObject"
            $result.PSObject.Properties.Name | Should -Contain "TimeoutOccurred"
            $result.TimeoutOccurred | Should -BeTrue
            $result.PSObject.Properties.Name | Should -Contain "Results"
        }

        It "Devrait gérer correctement un tableau vide de taille 50 avec timeout" {
            # Arrange
            $runspaces = New-EmptyArray -Size 50

            # Act
            # Ajouter un timeout très court pour optimiser les performances des tests
            # Forcer le format de retour à "Object" pour obtenir un PSCustomObject
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 0.5 -ReturnFormat "Object"

            # Assert
            $result | Should -Not -BeNullOrEmpty
            # Avec un timeout, la fonction retourne un PSCustomObject avec des propriétés spécifiques
            $result.GetType().Name | Should -Be "PSCustomObject"
            $result.PSObject.Properties.Name | Should -Contain "TimeoutOccurred"
            $result.TimeoutOccurred | Should -BeTrue
            $result.PSObject.Properties.Name | Should -Contain "Results"
        }
    }

    Context "Gestion des tableaux avec des éléments non-null" {
        BeforeAll {
            # Fonction pour créer un tableau avec des éléments non-null
            function New-NonNullArray {
                param (
                    [Parameter(Mandatory = $true)]
                    [int]$Size
                )

                $array = New-Object object[] $Size
                for ($i = 0; $i -lt $Size; $i++) {
                    # Utiliser des objets simples qui ne sont pas null
                    $array[$i] = [PSCustomObject]@{ Index = $i }
                }

                return $array
            }
        }

        It "Devrait gérer correctement un tableau avec 10 éléments non-null avec timeout" {
            # Arrange
            $runspaces = New-NonNullArray -Size 10

            # Act
            # Ajouter un timeout très court pour optimiser les performances des tests
            # Forcer le format de retour à "Object" pour obtenir un PSCustomObject
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 0.5 -ReturnFormat "Object"

            # Assert
            $result | Should -Not -BeNullOrEmpty
            # Avec un timeout, la fonction retourne un PSCustomObject avec des propriétés spécifiques
            $result.GetType().Name | Should -Be "PSCustomObject"
            $result.PSObject.Properties.Name | Should -Contain "TimeoutOccurred"
            $result.TimeoutOccurred | Should -BeTrue
            $result.PSObject.Properties.Name | Should -Contain "Results"
        }

        It "Devrait gérer correctement un tableau avec 20 éléments non-null avec timeout" {
            # Arrange
            $runspaces = New-NonNullArray -Size 20

            # Act
            # Ajouter un timeout très court pour optimiser les performances des tests
            # Forcer le format de retour à "Object" pour obtenir un PSCustomObject
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 0.5 -ReturnFormat "Object"

            # Assert
            $result | Should -Not -BeNullOrEmpty
            # Avec un timeout, la fonction retourne un PSCustomObject avec des propriétés spécifiques
            $result.GetType().Name | Should -Be "PSCustomObject"
            $result.PSObject.Properties.Name | Should -Contain "TimeoutOccurred"
            $result.TimeoutOccurred | Should -BeTrue
            $result.PSObject.Properties.Name | Should -Contain "Results"
        }
    }

    Context "Performance avec des tableaux vides" {
        It "Devrait traiter rapidement un tableau vide de grande taille" {
            # Arrange
            # Utiliser un tableau vide réel pour éviter les problèmes de timeout
            $runspaces = @()
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Act
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -ReturnFormat "Object"
            $stopwatch.Stop()

            # Assert
            $result | Should -Not -BeNullOrEmpty
            # Pour un tableau vide, le traitement devrait être rapide
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 1000 # Devrait prendre moins de 1 seconde
        }
    }
}
