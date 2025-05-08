# Tests for BandwidthSelection.psm1
# Run with Pester: Invoke-Pester -Path ".\BandwidthSelection.Tests.ps1"

BeforeAll {
    # Import the module to test directly
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\BandwidthSelection.psm1"
    . $modulePath
}

Describe "Get-OptimalBandwidth" {
    Context "Univariate data" {
        BeforeAll {
            # Generate univariate test data - normal distribution
            $numPoints = 100
            $mean = 50
            $stdDev = 10

            $testData = 1..$numPoints | ForEach-Object {
                # Box-Muller transform to generate normal random variables
                $u1 = Get-Random -Minimum 0.0001 -Maximum 0.9999
                $u2 = Get-Random -Minimum 0.0001 -Maximum 0.9999
                $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)

                # Add mean and scale
                $mean + $stdDev * $z
            }
        }

        It "Should return a result object with the expected properties" {
            $result = Get-OptimalBandwidth -Data $testData -Method "Silverman"

            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be "Silverman"
            $result.KernelType | Should -Be "Gaussian"
            $result.NumDimensions | Should -Be 1
            $result.DataCount | Should -Be $numPoints
            $result.ExecutionTime | Should -Not -BeNullOrEmpty
            $result.Timestamp | Should -Not -BeNullOrEmpty
        }

        It "Should work with Silverman's rule" {
            $result = Get-OptimalBandwidth -Data $testData -Method "Silverman"

            $result | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be "Silverman"
            $result.Value | Should -BeGreaterThan 0
        }

        It "Should work with Scott's rule" {
            $result = Get-OptimalBandwidth -Data $testData -Method "Scott"

            $result | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be "Scott"
            $result.Value | Should -BeGreaterThan 0
        }

        It "Should work with CrossValidation method" {
            $result = Get-OptimalBandwidth -Data $testData -Method "CrossValidation"

            $result | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be "CrossValidation"
            $result.Value | Should -BeGreaterThan 0
        }

        It "Should work with Plugin method" {
            $result = Get-OptimalBandwidth -Data $testData -Method "Plugin"

            $result | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be "Plugin"
            $result.Value | Should -BeGreaterThan 0
        }

        It "Should work with Adaptive method" {
            $result = Get-OptimalBandwidth -Data $testData -Method "Adaptive"

            $result | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be "Adaptive"
            $result.Value | Should -BeGreaterThan 0
        }

        It "Should produce reasonable bandwidth values for normal data" {
            $result = Get-OptimalBandwidth -Data $testData -Method "Silverman"

            $result | Should -Not -BeNullOrEmpty

            # For normal data with n=100, stdDev=10, Silverman's rule gives approximately:
            # h = 0.9 * 10 * 100^(-1/5) ≈ 0.9 * 10 * 0.398 ≈ 3.58
            # Allow for some variation due to random sampling
            $result.Value | Should -BeGreaterThan 2
            $result.Value | Should -BeLessThan 6
        }
    }

    Context "Bivariate data" {
        BeforeAll {
            # Generate bivariate test data - normal distribution
            $numPoints = 100
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
        }

        It "Should return a result object with the expected properties" {
            $result = Get-OptimalBandwidth -Data $testData -Dimensions @("X", "Y") -Method "Silverman"

            $result | Should -Not -BeNullOrEmpty
            $result.X | Should -Not -BeNullOrEmpty
            $result.Y | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be "Silverman"
            $result.KernelType | Should -Be "Gaussian"
            $result.NumDimensions | Should -Be 2
            $result.DataCount | Should -Be $numPoints
            $result.ExecutionTime | Should -Not -BeNullOrEmpty
            $result.Timestamp | Should -Not -BeNullOrEmpty
        }

        It "Should work with Silverman's rule" {
            $result = Get-OptimalBandwidth -Data $testData -Dimensions @("X", "Y") -Method "Silverman"

            $result | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be "Silverman"
            $result.X | Should -BeGreaterThan 0
            $result.Y | Should -BeGreaterThan 0
        }

        It "Should work with Scott's rule" {
            $result = Get-OptimalBandwidth -Data $testData -Dimensions @("X", "Y") -Method "Scott"

            $result | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be "Scott"
            $result.X | Should -BeGreaterThan 0
            $result.Y | Should -BeGreaterThan 0
        }

        It "Should work with CrossValidation method" {
            $result = Get-OptimalBandwidth -Data $testData -Dimensions @("X", "Y") -Method "CrossValidation"

            $result | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be "CrossValidation"
            $result.X | Should -BeGreaterThan 0
            $result.Y | Should -BeGreaterThan 0
        }

        It "Should produce reasonable bandwidth values for normal data" {
            $result = Get-OptimalBandwidth -Data $testData -Dimensions @("X", "Y") -Method "Silverman"

            $result | Should -Not -BeNullOrEmpty

            # For bivariate normal data with n=100, stdDev=10, Silverman's rule gives approximately:
            # h = 0.9 * 10 * 100^(-1/6) ≈ 0.9 * 10 * 0.464 ≈ 4.18
            # Allow for some variation due to random sampling
            $result.X | Should -BeGreaterThan 2
            $result.X | Should -BeLessThan 7
            $result.Y | Should -BeGreaterThan 2
            $result.Y | Should -BeLessThan 7
        }
    }

    Context "Higher-dimensional data" {
        BeforeAll {
            # Generate 3D test data
            $numPoints = 50
            $testData = 1..$numPoints | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 100
                    Y = Get-Random -Minimum 0 -Maximum 100
                    Z = Get-Random -Minimum 0 -Maximum 100
                }
            }
        }

        It "Should handle 3D data" {
            $result = Get-OptimalBandwidth -Data $testData -Dimensions @("X", "Y", "Z") -Method "Silverman"

            $result | Should -Not -BeNullOrEmpty
            $result.X | Should -Not -BeNullOrEmpty
            $result.Y | Should -Not -BeNullOrEmpty
            $result.Z | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be "Silverman"
            $result.NumDimensions | Should -Be 3
        }

        It "Should handle 4D data" {
            # Add a fourth dimension to the test data
            $testDataWith4D = $testData | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name "W" -Value (Get-Random -Minimum 0 -Maximum 100) -PassThru
            }

            $result = Get-OptimalBandwidth -Data $testDataWith4D -Dimensions @("X", "Y", "Z", "W") -Method "Silverman"

            $result | Should -Not -BeNullOrEmpty
            $result.X | Should -Not -BeNullOrEmpty
            $result.Y | Should -Not -BeNullOrEmpty
            $result.Z | Should -Not -BeNullOrEmpty
            $result.W | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be "Silverman"
            $result.NumDimensions | Should -Be 4
        }
    }

    Context "Error handling" {
        It "Should throw an error for insufficient data points" {
            $testData = @(42)

            { Get-OptimalBandwidth -Data $testData } | Should -Throw "Bandwidth selection requires at least 2 data points."
        }

        It "Should throw an error for missing dimension" {
            $testData = @(
                [PSCustomObject]@{
                    X = 1
                    Y = 2
                },
                [PSCustomObject]@{
                    X = 3
                    Y = 4
                }
            )

            { Get-OptimalBandwidth -Data $testData -Dimensions @("X", "Y", "Z") } | Should -Throw "Data point does not have the specified dimension: Z"
        }
    }

    Context "Different kernel types" {
        BeforeAll {
            # Generate simple test data
            $testData = 1..50 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
        }

        It "Should work with different kernel types" {
            $kernelTypes = @("Gaussian", "Epanechnikov", "Uniform", "Triangular", "Biweight", "Triweight", "Cosine")

            foreach ($kernelType in $kernelTypes) {
                $result = Get-OptimalBandwidth -Data $testData -KernelType $kernelType

                $result | Should -Not -BeNullOrEmpty
                $result.KernelType | Should -Be $kernelType
                $result.Value | Should -BeGreaterThan 0
            }
        }
    }

    Context "Custom bandwidth range" {
        BeforeAll {
            # Generate simple test data
            $testData = 1..50 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
        }

        It "Should respect custom bandwidth range for cross-validation" {
            $bandwidthRange = @(1, 10)
            $result = Get-OptimalBandwidth -Data $testData -Method "CrossValidation" -BandwidthRange $bandwidthRange

            $result | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be "CrossValidation"
            $result.Value | Should -BeGreaterOrEqual $bandwidthRange[0]
            $result.Value | Should -BeLessOrEqual $bandwidthRange[1]
        }
    }
}

AfterAll {
    # Remove the module
    Remove-Module BandwidthSelection -ErrorAction SilentlyContinue
}
