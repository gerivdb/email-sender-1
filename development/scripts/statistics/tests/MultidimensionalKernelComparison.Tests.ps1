# Tests de comparaison entre les différents noyaux pour l'estimation de densité par noyau multidimensionnelle
# Run with Pester: Invoke-Pester -Path ".\MultidimensionalKernelComparison.Tests.ps1"

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $PSScriptRoot
. "$scriptPath\GaussianKernel.ps1"
. "$scriptPath\EpanechnikovKernel.ps1"
. "$scriptPath\TriangularKernel.ps1"
. "$scriptPath\UniformKernel.ps1"
. "$scriptPath\BiweightKernel.ps1"
. "$scriptPath\TriweightKernel.ps1"
. "$scriptPath\CosineKernel.ps1"
. "$scriptPath\MultidimensionalKernels.ps1"

Describe "Tests pour l'estimation de densité par noyau multidimensionnelle" {
    Context "Tests de base pour différentes distributions" {
        BeforeAll {
            # Créer des données de test bidimensionnelles
            $data2D = @(
                [PSCustomObject]@{ X = 0; Y = 0 },
                [PSCustomObject]@{ X = 1; Y = 1 },
                [PSCustomObject]@{ X = 2; Y = 2 },
                [PSCustomObject]@{ X = 3; Y = 3 },
                [PSCustomObject]@{ X = 4; Y = 4 }
            )

            # Définir le point d'évaluation
            $evaluationPoint2D = [PSCustomObject]@{
                X = 2
                Y = 2
            }

            # Définir les noyaux à tester
            $kernelTypes = @("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine")
        }

        It "Tous les noyaux devraient fonctionner pour des données bidimensionnelles" {
            foreach ($kernelType in $kernelTypes) {
                $density = $null

                # Utiliser un bloc try-catch pour gérer les erreurs potentielles
                try {
                    switch ($kernelType) {
                        "Gaussian" {
                            $density = Get-GaussianKernelDensityND -Point $evaluationPoint2D -Data $data2D
                        }
                        "Epanechnikov" {
                            $density = Get-EpanechnikovKernelDensityND -Point $evaluationPoint2D -Data $data2D
                        }
                        "Triangular" {
                            $density = Get-TriangularKernelDensityND -Point $evaluationPoint2D -Data $data2D
                        }
                        "Uniform" {
                            $density = Get-UniformKernelDensityND -Point $evaluationPoint2D -Data $data2D
                        }
                        "Biweight" {
                            $density = Get-BiweightKernelDensityND -Point $evaluationPoint2D -Data $data2D
                        }
                        "Triweight" {
                            $density = Get-TriweightKernelDensityND -Point $evaluationPoint2D -Data $data2D
                        }
                        "Cosine" {
                            $density = Get-CosineKernelDensityND -Point $evaluationPoint2D -Data $data2D
                        }
                    }

                    # Vérifier que la densité est un nombre positif
                    $density | Should -Not -BeNullOrEmpty
                    $density | Should -BeOfType [double]
                    $density | Should -BeGreaterThan 0

                    Write-Host "Densité pour le noyau $kernelType : $density"
                } catch {
                    Write-Host "Erreur pour le noyau $kernelType : $_"
                    $_ | Should -BeNullOrEmpty -Because "Le noyau $kernelType devrait fonctionner sans erreur"
                }
            }
        }
    }

    Context "Tests de performance pour différentes dimensions" {
        BeforeAll {
            # Créer des données de test bidimensionnelles
            $data2D = @(
                [PSCustomObject]@{ X = 0; Y = 0 },
                [PSCustomObject]@{ X = 1; Y = 1 },
                [PSCustomObject]@{ X = 2; Y = 2 },
                [PSCustomObject]@{ X = 3; Y = 3 },
                [PSCustomObject]@{ X = 4; Y = 4 }
            )

            # Créer des données de test tridimensionnelles
            $data3D = @(
                [PSCustomObject]@{ X = 0; Y = 0; Z = 0 },
                [PSCustomObject]@{ X = 1; Y = 1; Z = 1 },
                [PSCustomObject]@{ X = 2; Y = 2; Z = 2 },
                [PSCustomObject]@{ X = 3; Y = 3; Z = 3 },
                [PSCustomObject]@{ X = 4; Y = 4; Z = 4 }
            )

            # Définir les points d'évaluation
            $evaluationPoint2D = [PSCustomObject]@{
                X = 2
                Y = 2
            }

            $evaluationPoint3D = [PSCustomObject]@{
                X = 2
                Y = 2
                Z = 2
            }

            # Définir les noyaux à tester
            $kernelTypes = @("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine")
        }

        It "Comparaison des performances des noyaux pour des données bidimensionnelles" {
            $results = @{}

            foreach ($kernelType in $kernelTypes) {
                try {
                    $startTime = Get-Date

                    switch ($kernelType) {
                        "Gaussian" {
                            $density = Get-GaussianKernelDensityND -Point $evaluationPoint2D -Data $data2D
                        }
                        "Epanechnikov" {
                            $density = Get-EpanechnikovKernelDensityND -Point $evaluationPoint2D -Data $data2D
                        }
                        "Triangular" {
                            $density = Get-TriangularKernelDensityND -Point $evaluationPoint2D -Data $data2D
                        }
                        "Uniform" {
                            $density = Get-UniformKernelDensityND -Point $evaluationPoint2D -Data $data2D
                        }
                        "Biweight" {
                            $density = Get-BiweightKernelDensityND -Point $evaluationPoint2D -Data $data2D
                        }
                        "Triweight" {
                            $density = Get-TriweightKernelDensityND -Point $evaluationPoint2D -Data $data2D
                        }
                        "Cosine" {
                            $density = Get-CosineKernelDensityND -Point $evaluationPoint2D -Data $data2D
                        }
                    }

                    $endTime = Get-Date
                    $executionTime = ($endTime - $startTime).TotalMilliseconds

                    $results[$kernelType] = $executionTime
                } catch {
                    Write-Host "Erreur pour le noyau $kernelType : $_"
                }
            }

            # Afficher les résultats
            Write-Host "Temps d'exécution (ms) pour des données bidimensionnelles:"
            $sortedKernels = $results.GetEnumerator() | Sort-Object -Property Value
            foreach ($kernel in $sortedKernels) {
                Write-Host "  $($kernel.Name): $([Math]::Round($kernel.Value, 2))"
            }

            # Vérifier que les résultats sont cohérents
            $results.Count | Should -BeGreaterThan 0
        }

        It "Comparaison des performances des noyaux pour des données tridimensionnelles" {
            $results = @{}

            foreach ($kernelType in $kernelTypes) {
                try {
                    $startTime = Get-Date

                    switch ($kernelType) {
                        "Gaussian" {
                            $density = Get-GaussianKernelDensityND -Point $evaluationPoint3D -Data $data3D
                        }
                        "Epanechnikov" {
                            $density = Get-EpanechnikovKernelDensityND -Point $evaluationPoint3D -Data $data3D
                        }
                        "Triangular" {
                            $density = Get-TriangularKernelDensityND -Point $evaluationPoint3D -Data $data3D
                        }
                        "Uniform" {
                            $density = Get-UniformKernelDensityND -Point $evaluationPoint3D -Data $data3D
                        }
                        "Biweight" {
                            $density = Get-BiweightKernelDensityND -Point $evaluationPoint3D -Data $data3D
                        }
                        "Triweight" {
                            $density = Get-TriweightKernelDensityND -Point $evaluationPoint3D -Data $data3D
                        }
                        "Cosine" {
                            $density = Get-CosineKernelDensityND -Point $evaluationPoint3D -Data $data3D
                        }
                    }

                    $endTime = Get-Date
                    $executionTime = ($endTime - $startTime).TotalMilliseconds

                    $results[$kernelType] = $executionTime
                } catch {
                    Write-Host "Erreur pour le noyau $kernelType : $_"
                }
            }

            # Afficher les résultats
            Write-Host "Temps d'exécution (ms) pour des données tridimensionnelles:"
            $sortedKernels = $results.GetEnumerator() | Sort-Object -Property Value
            foreach ($kernel in $sortedKernels) {
                Write-Host "  $($kernel.Name): $([Math]::Round($kernel.Value, 2))"
            }

            # Vérifier que les résultats sont cohérents
            $results.Count | Should -BeGreaterThan 0
        }
    }
}
