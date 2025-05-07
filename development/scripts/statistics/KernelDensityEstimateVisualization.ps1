# KernelDensityEstimateVisualization.ps1
# Functions to visualize kernel density estimation results

# Function to create a histogram of data
function New-Histogram {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [int]$NumBins = 20,

        [Parameter(Mandatory = $false)]
        [double]$Min = $null,

        [Parameter(Mandatory = $false)]
        [double]$Max = $null
    )

    # Determine the min and max values if not provided
    if ($null -eq $Min) {
        $Min = ($Data | Measure-Object -Minimum).Minimum
    }

    if ($null -eq $Max) {
        $Max = ($Data | Measure-Object -Maximum).Maximum
    }

    # Calculate the bin width
    $binWidth = ($Max - $Min) / $NumBins

    # Initialize the bins
    $bins = New-Object double[] $NumBins
    $binCenters = New-Object double[] $NumBins

    # Calculate the bin centers
    for ($i = 0; $i -lt $NumBins; $i++) {
        $binCenters[$i] = $Min + ($i + 0.5) * $binWidth
    }

    # Count the data points in each bin
    foreach ($value in $Data) {
        if ($value -ge $Min -and $value -lt $Max) {
            $binIndex = [Math]::Floor(($value - $Min) / $binWidth)

            # Handle the case where the value is exactly equal to the max
            if ($binIndex -eq $NumBins) {
                $binIndex = $NumBins - 1
            }

            $bins[$binIndex]++
        }
    }

    # Normalize the histogram to get a probability density
    $totalCount = ($bins | Measure-Object -Sum).Sum
    $normalizedBins = $bins | ForEach-Object { $_ / ($totalCount * $binWidth) }

    # Create the result object
    $result = [PSCustomObject]@{
        BinCenters     = $binCenters
        BinCounts      = $bins
        NormalizedBins = $normalizedBins
        BinWidth       = $binWidth
        Min            = $Min
        Max            = $Max
        NumBins        = $NumBins
    }

    return $result
}

# Function to create a text-based histogram plot
function Show-TextHistogram {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Histogram,

        [Parameter(Mandatory = $false)]
        [int]$Width = 50,

        [Parameter(Mandatory = $false)]
        [int]$Height = 10,

        [Parameter(Mandatory = $false)]
        [switch]$Normalized = $false
    )

    # Determine the maximum bin count
    if ($Normalized) {
        $maxBinValue = ($Histogram.NormalizedBins | Measure-Object -Maximum).Maximum
        $binValues = $Histogram.NormalizedBins
    } else {
        $maxBinValue = ($Histogram.BinCounts | Measure-Object -Maximum).Maximum
        $binValues = $Histogram.BinCounts
    }

    # Create the plot
    $plot = @()

    # Add the title
    $title = "Histogram"
    $padding = [Math]::Max(0, ($Width - $title.Length) / 2)
    $plot += " " * [Math]::Floor($padding) + $title

    # Add the y-axis labels and bars
    for ($i = $Height; $i -gt 0; $i--) {
        $threshold = $maxBinValue * $i / $Height
        $line = ""

        # Add the y-axis label
        if ($i -eq $Height) {
            $yLabel = [Math]::Round($maxBinValue, 2).ToString()
            $line += $yLabel.PadLeft(8) + " |"
        } elseif ($i -eq 1) {
            $yLabel = [Math]::Round($maxBinValue / $Height, 2).ToString()
            $line += $yLabel.PadLeft(8) + " |"
        } elseif ($i -eq [Math]::Ceiling($Height / 2)) {
            $yLabel = [Math]::Round($maxBinValue * $i / $Height, 2).ToString()
            $line += $yLabel.PadLeft(8) + " |"
        } else {
            $line += " " * 8 + " |"
        }

        # Add the bars
        for ($j = 0; $j -lt $Histogram.NumBins; $j++) {
            $binValue = $binValues[$j]
            if ($binValue -ge $threshold) {
                $line += "#"
            } else {
                $line += " "
            }
        }

        $plot += $line
    }

    # Add the x-axis
    $xAxis = " " * 8 + " +" + "-" * $Histogram.NumBins
    $plot += $xAxis

    # Add the x-axis labels
    $xLabels = " " * 8 + "  "
    for ($i = 0; $i -lt $Histogram.NumBins; $i += [Math]::Max(1, [Math]::Floor($Histogram.NumBins / 5))) {
        $xLabel = [Math]::Round($Histogram.BinCenters[$i], 1).ToString()
        $xLabels += $xLabel.PadRight([Math]::Max(1, [Math]::Floor($Histogram.NumBins / 5)))
    }
    $plot += $xLabels

    # Display the plot
    $plot | ForEach-Object { Write-Host $_ }
}

# Function to create a text-based line plot
function Show-TextLinePlot {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$X,

        [Parameter(Mandatory = $true)]
        [double[]]$Y,

        [Parameter(Mandatory = $false)]
        [int]$Width = 50,

        [Parameter(Mandatory = $false)]
        [int]$Height = 10,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Line Plot"
    )

    # Validate parameters
    if ($X.Count -ne $Y.Count) {
        throw "The X and Y arrays must have the same length."
    }

    # Determine the min and max values
    $minX = ($X | Measure-Object -Minimum).Minimum
    $maxX = ($X | Measure-Object -Maximum).Maximum
    $minY = ($Y | Measure-Object -Minimum).Minimum
    $maxY = ($Y | Measure-Object -Maximum).Maximum

    # Create the plot
    $plot = @()

    # Add the title
    $padding = [Math]::Max(0, ($Width - $Title.Length) / 2)
    $plot += " " * [Math]::Floor($padding) + $Title

    # Create a 2D grid for the plot
    $grid = New-Object 'char[,]' ($Height + 1), ($Width + 1)

    # Initialize the grid with spaces
    for ($i = 0; $i -le $Height; $i++) {
        for ($j = 0; $j -le $Width; $j++) {
            $grid[$i, $j] = ' '
        }
    }

    # Add the y-axis
    for ($i = 0; $i -le $Height; $i++) {
        $grid[$i, 0] = '|'
    }

    # Add the x-axis
    for ($j = 0; $j -le $Width; $j++) {
        $grid[$Height, $j] = '-'
    }

    # Add the origin
    $grid[$Height, 0] = '+'

    # Add the data points
    for ($i = 0; $i -lt $X.Count; $i++) {
        $x = $X[$i]
        $y = $Y[$i]

        # Scale the x and y values to the grid
        $xScaled = [Math]::Floor(($x - $minX) / ($maxX - $minX) * $Width)
        $yScaled = [Math]::Floor(($y - $minY) / ($maxY - $minY) * $Height)

        # Ensure the scaled values are within the grid
        $xScaled = [Math]::Max(0, [Math]::Min($Width, $xScaled))
        $yScaled = [Math]::Max(0, [Math]::Min($Height, $yScaled))

        # Invert the y-axis (0 is at the top in the grid)
        $yScaled = $Height - $yScaled

        # Add the data point to the grid
        $grid[$yScaled, $xScaled] = '*'
    }

    # Convert the grid to strings
    for ($i = 0; $i -le $Height; $i++) {
        $line = ""

        # Add the y-axis label
        if ($i -eq 0) {
            $yLabel = [Math]::Round($maxY, 2).ToString()
            $line += $yLabel.PadLeft(8) + " "
        } elseif ($i -eq $Height) {
            $yLabel = [Math]::Round($minY, 2).ToString()
            $line += $yLabel.PadLeft(8) + " "
        } elseif ($i -eq [Math]::Floor($Height / 2)) {
            $yLabel = [Math]::Round($minY + ($maxY - $minY) * ($Height - $i) / $Height, 2).ToString()
            $line += $yLabel.PadLeft(8) + " "
        } else {
            $line += " " * 8 + " "
        }

        # Add the grid row
        for ($j = 0; $j -le $Width; $j++) {
            $line += $grid[$i, $j]
        }

        $plot += $line
    }

    # Add the x-axis labels
    $xLabels = " " * 8 + "  "
    for ($i = 0; $i -le $Width; $i += [Math]::Max(1, [Math]::Floor($Width / 5))) {
        $xValue = $minX + ($maxX - $minX) * $i / $Width
        $xLabel = [Math]::Round($xValue, 1).ToString()
        $xLabels += $xLabel.PadRight([Math]::Max(1, [Math]::Floor($Width / 5)))
    }
    $plot += $xLabels

    # Display the plot
    $plot | ForEach-Object { Write-Host $_ }
}

# Function to compare a kernel density estimate with a theoretical distribution
function Compare-KernelDensityEstimate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$KernelDensityEstimate,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$TheoreticalDistribution,

        [Parameter(Mandatory = $false)]
        [int]$NumPoints = 100,

        [Parameter(Mandatory = $false)]
        [switch]$ShowPlot = $false
    )

    # Get the evaluation points and density estimates from the kernel density estimate
    $evaluationPoints = $KernelDensityEstimate.EvaluationPoints
    $densityEstimates = $KernelDensityEstimate.DensityEstimates

    # Calculate the theoretical density at the evaluation points
    $theoreticalDensity = New-Object double[] $evaluationPoints.Count
    for ($i = 0; $i -lt $evaluationPoints.Count; $i++) {
        $theoreticalDensity[$i] = & $TheoreticalDistribution.TheoreticalFunction $evaluationPoints[$i] $TheoreticalDistribution.Parameters
    }

    # Calculate the mean squared error
    $mse = 0
    for ($i = 0; $i -lt $evaluationPoints.Count; $i++) {
        $mse += [Math]::Pow($densityEstimates[$i] - $theoreticalDensity[$i], 2)
    }
    $mse /= $evaluationPoints.Count

    # Calculate the mean absolute error
    $mae = 0
    for ($i = 0; $i -lt $evaluationPoints.Count; $i++) {
        $mae += [Math]::Abs($densityEstimates[$i] - $theoreticalDensity[$i])
    }
    $mae /= $evaluationPoints.Count

    # Calculate the maximum absolute error
    $maxError = 0
    for ($i = 0; $i -lt $evaluationPoints.Count; $i++) {
        $error = [Math]::Abs($densityEstimates[$i] - $theoreticalDensity[$i])
        if ($error -gt $maxError) {
            $maxError = $error
        }
    }

    # Create the result object
    $result = [PSCustomObject]@{
        EvaluationPoints       = $evaluationPoints
        KernelDensityEstimates = $densityEstimates
        TheoreticalDensity     = $theoreticalDensity
        MeanSquaredError       = $mse
        MeanAbsoluteError      = $mae
        MaximumAbsoluteError   = $maxError
    }

    # Show the plot if requested
    if ($ShowPlot) {
        # Create a line plot of the kernel density estimate and the theoretical density
        Write-Host "Kernel Density Estimate vs. Theoretical Density" -ForegroundColor Cyan
        Write-Host "Distribution Type: $($TheoreticalDistribution.DistributionType)" -ForegroundColor Cyan
        Write-Host "Parameters: $($TheoreticalDistribution.Parameters | ConvertTo-Json -Compress)" -ForegroundColor Cyan
        Write-Host "Mean Squared Error: $mse" -ForegroundColor Cyan
        Write-Host "Mean Absolute Error: $mae" -ForegroundColor Cyan
        Write-Host "Maximum Absolute Error: $maxError" -ForegroundColor Cyan

        # Create a histogram of the data
        $histogram = New-Histogram -Data $TheoreticalDistribution.Samples -NumBins 20
        Show-TextHistogram -Histogram $histogram -Normalized

        # Create a line plot of the kernel density estimate and the theoretical density
        $plotTitle = "KDE (*)  vs.  Theoretical (-)"
        Show-TextLinePlot -X $evaluationPoints -Y $densityEstimates -Title $plotTitle
        Show-TextLinePlot -X $evaluationPoints -Y $theoreticalDensity -Title "Theoretical Density"
    }

    return $result
}

# Export functions if the script is imported as a module
if ($MyInvocation.InvocationName -ne $MyInvocation.MyCommand.Name) {
    Export-ModuleMember -Function New-Histogram, Show-TextHistogram, Show-TextLinePlot, Compare-KernelDensityEstimate
}
