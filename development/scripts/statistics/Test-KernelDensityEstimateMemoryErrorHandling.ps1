# Test-KernelDensityEstimateMemoryErrorHandling.ps1
# Script to test the memory error handling functions for kernel density estimation

# Add debug information
Write-Host "Starting test script..." -ForegroundColor Yellow
Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow

# Import the memory error handling functions
Write-Host "Importing memory error handling functions..." -ForegroundColor Yellow
. .\KernelDensityEstimateMemoryErrorHandling.ps1
Write-Host "Import completed." -ForegroundColor Yellow

# Function to test error handling
function Test-ErrorHandling {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestName,

        [Parameter(Mandatory = $true)]
        [scriptblock]$TestBlock,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedErrorCode
    )

    try {
        # Execute the test block
        & $TestBlock

        # If we get here, the test failed
        Write-Host "FAILED: $TestName - No exception was thrown" -ForegroundColor Red
        return $false
    } catch {
        $errorRecord = $_

        # Get the error code from the exception
        $actualErrorCode = $null
        if ($errorRecord.Exception.PSObject.Properties.Name -contains "ErrorCode") {
            $actualErrorCode = $errorRecord.Exception.ErrorCode
        }

        if ($actualErrorCode -eq $ExpectedErrorCode) {
            Write-Host "PASSED: $TestName" -ForegroundColor Green
            Write-Host "  Error code: $actualErrorCode" -ForegroundColor Green
            Write-Host "  Message: $($errorRecord.Exception.Message)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "FAILED: $TestName - Wrong error code" -ForegroundColor Red
            Write-Host "  Expected: $ExpectedErrorCode" -ForegroundColor Red
            Write-Host "  Actual: $actualErrorCode" -ForegroundColor Red
            Write-Host "  Message: $($errorRecord.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
}

# Test memory requirement estimation
Write-Host "Testing memory requirement estimation..." -ForegroundColor Cyan

# Test memory requirement estimation with normal parameters
try {
    $memoryRequirements = Get-KDEMemoryRequirements -DataCount 1000 -EvaluationPointsCount 100
    Write-Host "PASSED: Memory requirement estimation with normal parameters" -ForegroundColor Green
    Write-Host "  Total memory: $($memoryRequirements.TotalMemoryMB) MB" -ForegroundColor Green
    Write-Host "  Data memory: $($memoryRequirements.DataMemoryMB) MB" -ForegroundColor Green
    Write-Host "  Evaluation points memory: $($memoryRequirements.EvalPointsMemoryMB) MB" -ForegroundColor Green
    Write-Host "  Density estimates memory: $($memoryRequirements.DensityEstimatesMemoryMB) MB" -ForegroundColor Green
    Write-Host "  Intermediate memory: $($memoryRequirements.IntermediateMemoryMB) MB" -ForegroundColor Green
    $test1 = $true
} catch {
    Write-Host "FAILED: Memory requirement estimation with normal parameters - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test1 = $false
}

# Test memory requirement estimation with large parameters
try {
    $memoryRequirements = Get-KDEMemoryRequirements -DataCount 1000000 -EvaluationPointsCount 10000
    Write-Host "PASSED: Memory requirement estimation with large parameters" -ForegroundColor Green
    Write-Host "  Total memory: $($memoryRequirements.TotalMemoryMB) MB" -ForegroundColor Green
    $test2 = $true
} catch {
    Write-Host "FAILED: Memory requirement estimation with large parameters - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test2 = $false
}

# Test memory requirement estimation with parallel processing
try {
    $memoryRequirements = Get-KDEMemoryRequirements -DataCount 1000 -EvaluationPointsCount 100 -UseParallel
    Write-Host "PASSED: Memory requirement estimation with parallel processing" -ForegroundColor Green
    Write-Host "  Total memory: $($memoryRequirements.TotalMemoryMB) MB" -ForegroundColor Green
    Write-Host "  Use parallel: $($memoryRequirements.UseParallel)" -ForegroundColor Green
    $test3 = $true
} catch {
    Write-Host "FAILED: Memory requirement estimation with parallel processing - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test3 = $false
}

# Test memory requirement estimation with multiple dimensions
try {
    $memoryRequirements = Get-KDEMemoryRequirements -DataCount 1000 -EvaluationPointsCount 100 -Dimensions 3
    Write-Host "PASSED: Memory requirement estimation with multiple dimensions" -ForegroundColor Green
    Write-Host "  Total memory: $($memoryRequirements.TotalMemoryMB) MB" -ForegroundColor Green
    $test4 = $true
} catch {
    Write-Host "FAILED: Memory requirement estimation with multiple dimensions - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test4 = $false
}

# Test memory requirement checking
Write-Host "`nTesting memory requirement checking..." -ForegroundColor Cyan

# Test memory requirement checking with normal parameters
try {
    $memoryRequirements = Get-KDEMemoryRequirements -DataCount 1000 -EvaluationPointsCount 100
    $hasEnoughMemory = Test-KDEMemoryRequirements -MemoryRequirements $memoryRequirements
    Write-Host "PASSED: Memory requirement checking with normal parameters" -ForegroundColor Green
    Write-Host "  Has enough memory: $hasEnoughMemory" -ForegroundColor Green
    $test5 = $true
} catch {
    Write-Host "FAILED: Memory requirement checking with normal parameters - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test5 = $false
}

# Test memory requirement checking with large parameters
try {
    $memoryRequirements = Get-KDEMemoryRequirements -DataCount 1000000 -EvaluationPointsCount 10000
    $hasEnoughMemory = Test-KDEMemoryRequirements -MemoryRequirements $memoryRequirements
    Write-Host "PASSED: Memory requirement checking with large parameters" -ForegroundColor Green
    Write-Host "  Has enough memory: $hasEnoughMemory" -ForegroundColor Green
    $test6 = $true
} catch {
    Write-Host "FAILED: Memory requirement checking with large parameters - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test6 = $false
}

# Test chunked array creation
Write-Host "`nTesting chunked array creation..." -ForegroundColor Cyan

# Test chunked array creation with normal parameters
try {
    $array = 1..100
    $chunks = Get-ChunkedArray -Array $array -ChunkSize 10
    Write-Host "PASSED: Chunked array creation with normal parameters" -ForegroundColor Green
    Write-Host "  Number of chunks: $($chunks.Count)" -ForegroundColor Green
    Write-Host "  First chunk size: $($chunks[0].Count)" -ForegroundColor Green
    Write-Host "  Last chunk size: $($chunks[-1].Count)" -ForegroundColor Green
    $test7 = $true
} catch {
    Write-Host "FAILED: Chunked array creation with normal parameters - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test7 = $false
}

# Test chunked array creation with chunk size larger than array
try {
    $array = 1..100
    $chunks = Get-ChunkedArray -Array $array -ChunkSize 200
    Write-Host "PASSED: Chunked array creation with chunk size larger than array" -ForegroundColor Green
    Write-Host "  Number of chunks: $($chunks.Count)" -ForegroundColor Green
    Write-Host "  First chunk size: $($chunks[0].Count)" -ForegroundColor Green
    $test8 = $true
} catch {
    Write-Host "FAILED: Chunked array creation with chunk size larger than array - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test8 = $false
}

# Test chunked array creation with invalid chunk size
$test9 = Test-ErrorHandling -TestName "Chunked array creation with invalid chunk size" -TestBlock {
    $array = 1..100
    Get-ChunkedArray -Array $array -ChunkSize 0
} -ExpectedErrorCode $ErrorCodes.MemoryAllocationFailed

# Test kernel density estimation with memory optimization
Write-Host "`nTesting kernel density estimation with memory optimization..." -ForegroundColor Cyan

# Test kernel density estimation with normal parameters
try {
    $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
    $result = Get-KernelDensityEstimateMemoryOptimized -Data $data
    Write-Host "PASSED: Kernel density estimation with normal parameters" -ForegroundColor Green
    Write-Host "  Data count: $($result.Data.Count)" -ForegroundColor Green
    Write-Host "  Evaluation points count: $($result.EvaluationPoints.Count)" -ForegroundColor Green
    Write-Host "  Density estimates count: $($result.DensityEstimates.Count)" -ForegroundColor Green
    Write-Host "  Execution time: $($result.Statistics.ExecutionTime) seconds" -ForegroundColor Green
    $test10 = $true
} catch {
    Write-Host "FAILED: Kernel density estimation with normal parameters - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test10 = $false
}

# Test kernel density estimation with chunking
try {
    $data = 1..1000 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
    $result = Get-KernelDensityEstimateMemoryOptimized -Data $data -ChunkSize 100
    Write-Host "PASSED: Kernel density estimation with chunking" -ForegroundColor Green
    Write-Host "  Data count: $($result.Data.Count)" -ForegroundColor Green
    Write-Host "  Use chunking: $($result.Parameters.UseChunking)" -ForegroundColor Green
    Write-Host "  Chunk size: $($result.Parameters.ChunkSize)" -ForegroundColor Green
    Write-Host "  Execution time: $($result.Statistics.ExecutionTime) seconds" -ForegroundColor Green
    $test11 = $true
} catch {
    Write-Host "FAILED: Kernel density estimation with chunking - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test11 = $false
}

# Test kernel density estimation with memory checking
try {
    $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
    $result = Get-KernelDensityEstimateMemoryOptimized -Data $data -CheckMemory
    Write-Host "PASSED: Kernel density estimation with memory checking" -ForegroundColor Green
    Write-Host "  Data count: $($result.Data.Count)" -ForegroundColor Green
    Write-Host "  Estimated memory: $($result.MemoryStatistics.EstimatedMemoryMB) MB" -ForegroundColor Green
    Write-Host "  Available memory: $($result.MemoryStatistics.AvailableMemoryMB) MB" -ForegroundColor Green
    Write-Host "  Execution time: $($result.Statistics.ExecutionTime) seconds" -ForegroundColor Green
    $test12 = $true
} catch {
    Write-Host "FAILED: Kernel density estimation with memory checking - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test12 = $false
}

# Summary
$totalTests = 12
$passedTests = @($test1, $test2, $test3, $test4, $test5, $test6, $test7, $test8, $test9, $test10, $test11, $test12).Where({ $_ -eq $true }).Count

Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Total tests: $totalTests" -ForegroundColor Cyan
Write-Host "Passed tests: $passedTests" -ForegroundColor Cyan
Write-Host "Failed tests: $($totalTests - $passedTests)" -ForegroundColor Cyan

if ($passedTests -eq $totalTests) {
    Write-Host "All tests passed!" -ForegroundColor Green
} else {
    Write-Host "Some tests failed!" -ForegroundColor Red
}
