# Tests for KernelDensity2D.psm1
# Run with Pester: Invoke-Pester -Path ".\KernelDensity2D.Tests.ps1"

BeforeAll {
    # Import the module to test directly
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensity2D.psm1"
    . $modulePath
}

Describe "Get-KernelDensity2D" {
    Context "Basic functionality" {
        BeforeAll {
            # Generate test data - bivariate normal distribution
            $numPoints = 100
            $testData = 1..$numPoints | ForEach-Object {
                # Box-Muller transform to generate normal random variables
                $u1 = Get-Random -Minimum 0.0001 -Maximum 0.9999
                $u2 = Get-Random -Minimum 0.0001 -Maximum 0.9999
                $z1 = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
                $z2 = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Sin(2 * [Math]::PI * $u2)

                # Add mean and scale
                $x = 50 + 10 * $z1
                $y = 50 + 10 * $z2

                [PSCustomObject]@{
                    X = $x
                    Y = $y
                }
            }
        }

        It "Should return a result object with the expected properties" {
            $result = Get-KernelDensity2D -Data $testData

            $result | Should -Not -BeNullOrEmpty
            $result.Data | Should -Not -BeNullOrEmpty
            $result.XData | Should -Not -BeNullOrEmpty
            $result.YData | Should -Not -BeNullOrEmpty
            $result.EvaluationGrid | Should -Not -BeNullOrEmpty
            $result.DensityEstimates | Should -Not -BeNullOrEmpty
            $result.Parameters | Should -Not -BeNullOrEmpty
            $result.Statistics | Should -Not -BeNullOrEmpty
            $result.Metadata | Should -Not -BeNullOrEmpty
        }

        It "Should handle custom property names" {
            # Create test data with custom property names
            $customData = $testData | ForEach-Object {
                [PSCustomObject]@{
                    Longitude = $_.X
                    Latitude  = $_.Y
                }
            }

            $result = Get-KernelDensity2D -Data $customData -XProperty "Longitude" -YProperty "Latitude"

            $result | Should -Not -BeNullOrEmpty
            $result.Parameters.XProperty | Should -Be "Longitude"
            $result.Parameters.YProperty | Should -Be "Latitude"
        }

        It "Should handle custom grid size" {
            $gridSize = @(30, 40)
            $result = Get-KernelDensity2D -Data $testData -GridSize $gridSize

            $result | Should -Not -BeNullOrEmpty
            $result.Parameters.GridSize | Should -Be $gridSize
            $result.EvaluationGrid.XGrid.Count | Should -Be $gridSize[0]
            $result.EvaluationGrid.YGrid.Count | Should -Be $gridSize[1]
        }

        It "Should handle custom bandwidth" {
            $bandwidth = @(5, 5)
            $result = Get-KernelDensity2D -Data $testData -Bandwidth $bandwidth

            $result | Should -Not -BeNullOrEmpty
            $result.Parameters.Bandwidth | Should -Be $bandwidth
        }

        It "Should handle single bandwidth value" {
            $bandwidth = 5
            $result = Get-KernelDensity2D -Data $testData -Bandwidth $bandwidth

            $result | Should -Not -BeNullOrEmpty
            $result.Parameters.Bandwidth.Count | Should -Be 2
            $result.Parameters.Bandwidth[0] | Should -Be $bandwidth
            $result.Parameters.Bandwidth[1] | Should -Be $bandwidth
        }
    }

    Context "Different kernel types" {
        BeforeAll {
            # Generate simple test data
            $testData = 1..50 | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 100
                    Y = Get-Random -Minimum 0 -Maximum 100
                }
            }
        }

        It "Should work with Gaussian kernel" {
            $result = Get-KernelDensity2D -Data $testData -KernelType "Gaussian"

            $result | Should -Not -BeNullOrEmpty
            $result.Parameters.KernelType | Should -Be "Gaussian"
        }

        It "Should work with Epanechnikov kernel" {
            $result = Get-KernelDensity2D -Data $testData -KernelType "Epanechnikov"

            $result | Should -Not -BeNullOrEmpty
            $result.Parameters.KernelType | Should -Be "Epanechnikov"
        }

        It "Should work with Uniform kernel" {
            $result = Get-KernelDensity2D -Data $testData -KernelType "Uniform"

            $result | Should -Not -BeNullOrEmpty
            $result.Parameters.KernelType | Should -Be "Uniform"
        }

        It "Should work with Triangular kernel" {
            $result = Get-KernelDensity2D -Data $testData -KernelType "Triangular"

            $result | Should -Not -BeNullOrEmpty
            $result.Parameters.KernelType | Should -Be "Triangular"
        }
    }

    Context "Different bandwidth methods" {
        BeforeAll {
            # Generate simple test data
            $testData = 1..50 | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 100
                    Y = Get-Random -Minimum 0 -Maximum 100
                }
            }
        }

        It "Should work with Silverman's rule" {
            $result = Get-KernelDensity2D -Data $testData -BandwidthMethod "Silverman"

            $result | Should -Not -BeNullOrEmpty
            $result.Parameters.BandwidthMethod | Should -Be "Silverman"
        }

        It "Should work with Scott's rule" {
            $result = Get-KernelDensity2D -Data $testData -BandwidthMethod "Scott"

            $result | Should -Not -BeNullOrEmpty
            $result.Parameters.BandwidthMethod | Should -Be "Scott"
        }

        It "Should work with CrossValidation method" {
            $result = Get-KernelDensity2D -Data $testData -BandwidthMethod "CrossValidation"

            $result | Should -Not -BeNullOrEmpty
            $result.Parameters.BandwidthMethod | Should -Be "CrossValidation"
        }

        It "Should work with Plugin method" {
            $result = Get-KernelDensity2D -Data $testData -BandwidthMethod "Plugin"

            $result | Should -Not -BeNullOrEmpty
            $result.Parameters.BandwidthMethod | Should -Be "Plugin"
        }

        It "Should work with Adaptive method" {
            $result = Get-KernelDensity2D -Data $testData -BandwidthMethod "Adaptive"

            $result | Should -Not -BeNullOrEmpty
            $result.Parameters.BandwidthMethod | Should -Be "Adaptive"
        }
    }

    Context "Error handling" {
        It "Should throw an error for insufficient data points" {
            $testData = @(
                [PSCustomObject]@{
                    X = 1
                    Y = 2
                }
            )

            { Get-KernelDensity2D -Data $testData } | Should -Throw "Kernel density estimation requires at least 2 data points."
        }

        It "Should throw an error for missing X property" {
            $testData = @(
                [PSCustomObject]@{
                    Y = 1
                },
                [PSCustomObject]@{
                    Y = 2
                }
            )

            { Get-KernelDensity2D -Data $testData } | Should -Throw "Data point does not have the specified X property: X"
        }

        It "Should throw an error for missing Y property" {
            $testData = @(
                [PSCustomObject]@{
                    X = 1
                },
                [PSCustomObject]@{
                    X = 2
                }
            )

            { Get-KernelDensity2D -Data $testData } | Should -Throw "Data point does not have the specified Y property: Y"
        }
    }

    Context "Statistical properties" {
        BeforeAll {
            # Generate test data from a known distribution
            $numPoints = 1000
            $mean1 = 50
            $mean2 = 50
            $stdDev1 = 10
            $stdDev2 = 10

            $testData = 1..$numPoints | ForEach-Object {
                # Box-Muller transform to generate normal random variables
                $u1 = Get-Random -Minimum 0.0001 -Maximum 0.9999
                $u2 = Get-Random -Minimum 0.0001 -Maximum 0.9999
                $z1 = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
                $z2 = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Sin(2 * [Math]::PI * $u2)

                # Add mean and scale
                $x = $mean1 + $stdDev1 * $z1
                $y = $mean2 + $stdDev2 * $z2

                [PSCustomObject]@{
                    X = $x
                    Y = $y
                }
            }

            $result = Get-KernelDensity2D -Data $testData -GridSize @(50, 50)
        }

        It "Should have maximum density near the mean of the distribution" {
            # Find the indices of the maximum density
            $maxDensity = 0
            $maxI = 0
            $maxJ = 0

            for ($i = 0; $i -lt $result.EvaluationGrid.XGrid.Count; $i++) {
                for ($j = 0; $j -lt $result.EvaluationGrid.YGrid.Count; $j++) {
                    if ($result.DensityEstimates[$i, $j] -gt $maxDensity) {
                        $maxDensity = $result.DensityEstimates[$i, $j]
                        $maxI = $i
                        $maxJ = $j
                    }
                }
            }

            # Get the coordinates of the maximum density
            $maxX = $result.EvaluationGrid.XGrid[$maxI]
            $maxY = $result.EvaluationGrid.YGrid[$maxJ]

            # The maximum density should be close to the mean of the distribution
            $maxX | Should -BeGreaterThan ($mean1 - 10)
            $maxX | Should -BeLessThan ($mean1 + 10)
            $maxY | Should -BeGreaterThan ($mean2 - 10)
            $maxY | Should -BeLessThan ($mean2 + 10)
        }

        It "Should have positive density values" {
            $allPositive = $true

            for ($i = 0; $i -lt $result.EvaluationGrid.XGrid.Count; $i++) {
                for ($j = 0; $j -lt $result.EvaluationGrid.YGrid.Count; $j++) {
                    if ($result.DensityEstimates[$i, $j] -lt 0) {
                        $allPositive = $false
                        break
                    }
                }
                if (-not $allPositive) {
                    break
                }
            }

            $allPositive | Should -Be $true
        }

        It "Should integrate to approximately 1" {
            # Calculate the approximate integral of the density
            $integral = 0
            $dx = ($result.Statistics.XMax - $result.Statistics.XMin) / ($result.EvaluationGrid.XGrid.Count - 1)
            $dy = ($result.Statistics.YMax - $result.Statistics.YMin) / ($result.EvaluationGrid.YGrid.Count - 1)

            for ($i = 0; $i -lt $result.EvaluationGrid.XGrid.Count; $i++) {
                for ($j = 0; $j -lt $result.EvaluationGrid.YGrid.Count; $j++) {
                    $integral += $result.DensityEstimates[$i, $j] * $dx * $dy
                }
            }

            # The integral should be approximately 1 (with some tolerance)
            $integral | Should -BeGreaterThan 0.8
            $integral | Should -BeLessThan 1.2
        }
    }
}

AfterAll {
    # Remove the module
    Remove-Module KernelDensity2D -ErrorAction SilentlyContinue
}
