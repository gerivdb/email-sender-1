# Test-QueryParser.ps1
# Script pour tester le parser du langage de requête personnalisé
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$RunAllTests,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Tokenizer", "AST", "FilterFunction", "All")]
    [string]$TestComponent = "All",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Simple", "Complex", "Edge", "All")]
    [string]$TestComplexity = "All",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent $rootPath) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        if ($LogLevel -eq "None") {
            return
        }
        
        $logLevels = @{
            "Error" = 0
            "Warning" = 1
            "Info" = 2
            "Debug" = 3
        }
        
        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Importer le parser
$parserPath = Join-Path -Path $scriptPath -ChildPath "Parse-QueryLanguage.ps1"
if (-not (Test-Path -Path $parserPath)) {
    Write-Log "Parser script not found at: $parserPath" -Level "Error"
    exit 1
}

. $parserPath

# Définir les cas de test
$testCases = @{
    "Simple" = @(
        @{
            Name = "Simple Equality"
            Query = "status:todo"
            ExpectedTokenCount = 3
            ExpectedASTType = "Condition"
            TestData = @(
                @{ status = "todo"; priority = "high" }
                @{ status = "in_progress"; priority = "medium" }
            )
            ExpectedResults = @(0)
        },
        @{
            Name = "Simple Inequality"
            Query = "status!=done"
            ExpectedTokenCount = 3
            ExpectedASTType = "Condition"
            TestData = @(
                @{ status = "todo"; priority = "high" }
                @{ status = "done"; priority = "low" }
            )
            ExpectedResults = @(0)
        },
        @{
            Name = "Simple Contains"
            Query = "title~interface"
            ExpectedTokenCount = 3
            ExpectedASTType = "Condition"
            TestData = @(
                @{ title = "User Interface"; priority = "high" }
                @{ title = "Database"; priority = "medium" }
            )
            ExpectedResults = @(0)
        },
        @{
            Name = "Simple StartsWith"
            Query = "title^Impl"
            ExpectedTokenCount = 3
            ExpectedASTType = "Condition"
            TestData = @(
                @{ title = "Implementation"; priority = "high" }
                @{ title = "Design"; priority = "medium" }
            )
            ExpectedResults = @(0)
        },
        @{
            Name = "Simple EndsWith"
            Query = "title$tion"
            ExpectedTokenCount = 3
            ExpectedASTType = "Condition"
            TestData = @(
                @{ title = "Implementation"; priority = "high" }
                @{ title = "Design"; priority = "medium" }
            )
            ExpectedResults = @(0)
        },
        @{
            Name = "Simple GreaterThan"
            Query = "priority>medium"
            ExpectedTokenCount = 3
            ExpectedASTType = "Condition"
            TestData = @(
                @{ status = "todo"; priority = "high" }
                @{ status = "in_progress"; priority = "medium" }
            )
            ExpectedResults = @(0)
        },
        @{
            Name = "Simple LessThan"
            Query = "priority<high"
            ExpectedTokenCount = 3
            ExpectedASTType = "Condition"
            TestData = @(
                @{ status = "todo"; priority = "medium" }
                @{ status = "in_progress"; priority = "high" }
            )
            ExpectedResults = @(0)
        }
    ),
    "Complex" = @(
        @{
            Name = "AND Operator"
            Query = "status:todo AND priority:high"
            ExpectedTokenCount = 5
            ExpectedASTType = "LogicalExpression"
            TestData = @(
                @{ status = "todo"; priority = "high" }
                @{ status = "todo"; priority = "medium" }
                @{ status = "in_progress"; priority = "high" }
            )
            ExpectedResults = @(0)
        },
        @{
            Name = "OR Operator"
            Query = "status:todo OR status:in_progress"
            ExpectedTokenCount = 7
            ExpectedASTType = "LogicalExpression"
            TestData = @(
                @{ status = "todo"; priority = "high" }
                @{ status = "in_progress"; priority = "medium" }
                @{ status = "done"; priority = "low" }
            )
            ExpectedResults = @(0, 1)
        },
        @{
            Name = "NOT Operator"
            Query = "NOT status:done"
            ExpectedTokenCount = 4
            ExpectedASTType = "UnaryExpression"
            TestData = @(
                @{ status = "todo"; priority = "high" }
                @{ status = "done"; priority = "low" }
            )
            ExpectedResults = @(0)
        },
        @{
            Name = "Parentheses"
            Query = "(status:todo OR status:in_progress) AND priority:high"
            ExpectedTokenCount = 11
            ExpectedASTType = "LogicalExpression"
            TestData = @(
                @{ status = "todo"; priority = "high" }
                @{ status = "in_progress"; priority = "high" }
                @{ status = "todo"; priority = "medium" }
                @{ status = "done"; priority = "high" }
            )
            ExpectedResults = @(0, 1)
        },
        @{
            Name = "Complex Nested"
            Query = "status:todo AND (priority:high OR (category:development AND has_blockers:true))"
            ExpectedTokenCount = 15
            ExpectedASTType = "LogicalExpression"
            TestData = @(
                @{ status = "todo"; priority = "high"; category = "testing"; has_blockers = $false }
                @{ status = "todo"; priority = "medium"; category = "development"; has_blockers = $true }
                @{ status = "in_progress"; priority = "high"; category = "development"; has_blockers = $true }
            )
            ExpectedResults = @(0, 1)
        }
    ),
    "Edge" = @(
        @{
            Name = "Quoted Value"
            Query = 'title:"User Interface"'
            ExpectedTokenCount = 3
            ExpectedASTType = "Condition"
            TestData = @(
                @{ title = "User Interface"; priority = "high" }
                @{ title = "Database Interface"; priority = "medium" }
            )
            ExpectedResults = @(0)
        },
        @{
            Name = "Escaped Quotes"
            Query = 'description:"Contains \"quoted\" text"'
            ExpectedTokenCount = 3
            ExpectedASTType = "Condition"
            TestData = @(
                @{ description = 'Contains "quoted" text'; priority = "high" }
                @{ description = "Regular text"; priority = "medium" }
            )
            ExpectedResults = @(0)
        },
        @{
            Name = "Special Characters"
            Query = 'title:"Interface: Version 1.0"'
            ExpectedTokenCount = 3
            ExpectedASTType = "Condition"
            TestData = @(
                @{ title = "Interface: Version 1.0"; priority = "high" }
                @{ title = "Database"; priority = "medium" }
            )
            ExpectedResults = @(0)
        },
        @{
            Name = "Empty Value"
            Query = 'description:""'
            ExpectedTokenCount = 3
            ExpectedASTType = "Condition"
            TestData = @(
                @{ description = ""; priority = "high" }
                @{ description = "Some text"; priority = "medium" }
            )
            ExpectedResults = @(0)
        }
    )
}

# Fonction pour exécuter les tests
function Invoke-QueryParserTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$TestCases,
        
        [Parameter(Mandatory = $true)]
        [string]$TestComponent,
        
        [Parameter(Mandatory = $true)]
        [string]$TestComplexity
    )
    
    $results = @{
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
        Errors = @()
        Details = @()
    }
    
    # Déterminer quels groupes de tests exécuter
    $testGroups = @()
    if ($TestComplexity -eq "All") {
        $testGroups = @("Simple", "Complex", "Edge")
    } else {
        $testGroups = @($TestComplexity)
    }
    
    foreach ($group in $testGroups) {
        Write-Log "Running $group tests..." -Level "Info"
        
        foreach ($testCase in $TestCases[$group]) {
            $results.TotalTests++
            
            Write-Log "Test: $($testCase.Name)" -Level "Debug"
            Write-Log "Query: $($testCase.Query)" -Level "Debug"
            
            try {
                $testPassed = $true
                $testResult = [PSCustomObject]@{
                    Name = $testCase.Name
                    Query = $testCase.Query
                    Group = $group
                    Component = $TestComponent
                    Passed = $true
                    Error = $null
                    Details = @{}
                }
                
                # Tester le tokenizer
                if ($TestComponent -eq "All" -or $TestComponent -eq "Tokenizer") {
                    $tokens = Parse-Query -QueryString $testCase.Query -ReturnTokens
                    
                    if ($tokens.Count -ne $testCase.ExpectedTokenCount) {
                        $testPassed = $false
                        $testResult.Passed = $false
                        $testResult.Error = "Expected $($testCase.ExpectedTokenCount) tokens, got $($tokens.Count)"
                    }
                    
                    $testResult.Details.Tokens = $tokens
                }
                
                # Tester l'AST
                if ($TestComponent -eq "All" -or $TestComponent -eq "AST") {
                    $ast = Parse-Query -QueryString $testCase.Query -ReturnAST
                    
                    if ($ast.Type -ne $testCase.ExpectedASTType) {
                        $testPassed = $false
                        $testResult.Passed = $false
                        $testResult.Error = "Expected AST type $($testCase.ExpectedASTType), got $($ast.Type)"
                    }
                    
                    $testResult.Details.AST = $ast
                }
                
                # Tester la fonction de filtre
                if ($TestComponent -eq "All" -or $TestComponent -eq "FilterFunction") {
                    $filterFunction = Parse-Query -QueryString $testCase.Query -ReturnFilterFunction
                    
                    $filteredResults = @()
                    for ($i = 0; $i -lt $testCase.TestData.Count; $i++) {
                        $item = $testCase.TestData[$i]
                        if (& $filterFunction $item) {
                            $filteredResults += $i
                        }
                    }
                    
                    $expectedResults = $testCase.ExpectedResults
                    $expectedResultsStr = $expectedResults -join ", "
                    $filteredResultsStr = $filteredResults -join ", "
                    
                    if (Compare-Object -ReferenceObject $expectedResults -DifferenceObject $filteredResults) {
                        $testPassed = $false
                        $testResult.Passed = $false
                        $testResult.Error = "Expected filtered results [$expectedResultsStr], got [$filteredResultsStr]"
                    }
                    
                    $testResult.Details.FilterFunction = $filterFunction
                    $testResult.Details.FilteredResults = $filteredResults
                    $testResult.Details.ExpectedResults = $expectedResults
                }
                
                if ($testPassed) {
                    $results.PassedTests++
                    Write-Log "Test passed: $($testCase.Name)" -Level "Info"
                } else {
                    $results.FailedTests++
                    $results.Errors += $testResult.Error
                    Write-Log "Test failed: $($testCase.Name) - $($testResult.Error)" -Level "Error"
                }
                
                $results.Details += $testResult
                
            } catch {
                $results.FailedTests++
                $results.Errors += $_.Exception.Message
                
                $testResult = [PSCustomObject]@{
                    Name = $testCase.Name
                    Query = $testCase.Query
                    Group = $group
                    Component = $TestComponent
                    Passed = $false
                    Error = $_.Exception.Message
                    Details = @{}
                }
                
                $results.Details += $testResult
                
                Write-Log "Test error: $($testCase.Name) - $($_.Exception.Message)" -Level "Error"
            }
        }
    }
    
    return $results
}

# Fonction pour générer un rapport de test
function New-TestReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = (Join-Path -Path $scriptPath -ChildPath "TestReport.html")
    )
    
    $passRate = if ($Results.TotalTests -gt 0) { [math]::Round(($Results.PassedTests / $Results.TotalTests) * 100, 2) } else { 0 }
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Query Parser Test Report</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .summary {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .pass-rate {
            font-size: 24px;
            font-weight: bold;
            color: $(if ($passRate -eq 100) { "#27ae60" } elseif ($passRate -ge 80) { "#f39c12" } else { "#e74c3c" });
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f8f9fa;
            font-weight: bold;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .passed {
            color: #27ae60;
        }
        .failed {
            color: #e74c3c;
        }
        .details-toggle {
            cursor: pointer;
            color: #3498db;
            text-decoration: underline;
        }
        .details {
            display: none;
            background-color: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            margin-top: 10px;
            white-space: pre-wrap;
            font-family: monospace;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Query Parser Test Report</h1>
        
        <div class="summary">
            <h2>Summary</h2>
            <p>Total Tests: $($Results.TotalTests)</p>
            <p>Passed Tests: $($Results.PassedTests)</p>
            <p>Failed Tests: $($Results.FailedTests)</p>
            <p>Pass Rate: <span class="pass-rate">$passRate%</span></p>
        </div>
        
        <h2>Test Details</h2>
        <table>
            <thead>
                <tr>
                    <th>Name</th>
                    <th>Group</th>
                    <th>Component</th>
                    <th>Query</th>
                    <th>Status</th>
                    <th>Details</th>
                </tr>
            </thead>
            <tbody>
"@

    foreach ($test in $Results.Details) {
        $status = if ($test.Passed) { "Passed" } else { "Failed" }
        $statusClass = if ($test.Passed) { "passed" } else { "failed" }
        
        $html += @"
                <tr>
                    <td>$($test.Name)</td>
                    <td>$($test.Group)</td>
                    <td>$($test.Component)</td>
                    <td><code>$($test.Query)</code></td>
                    <td class="$statusClass">$status</td>
                    <td>
"@

        if (-not $test.Passed) {
            $html += @"
                        <div>Error: $($test.Error)</div>
"@
        }

        $html += @"
                        <div class="details-toggle" onclick="toggleDetails('details-$($Results.Details.IndexOf($test))')">Show Details</div>
                        <div id="details-$($Results.Details.IndexOf($test))" class="details">
"@

        foreach ($key in $test.Details.Keys) {
            $html += @"
                            <h4>$key</h4>
                            <pre>$($test.Details[$key] | ConvertTo-Json -Depth 10)</pre>
"@
        }

        $html += @"
                        </div>
                    </td>
                </tr>
"@
    }

    $html += @"
            </tbody>
        </table>
    </div>
    
    <script>
        function toggleDetails(id) {
            var element = document.getElementById(id);
            if (element.style.display === "block") {
                element.style.display = "none";
            } else {
                element.style.display = "block";
            }
        }
    </script>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    
    Write-Log "Test report generated at: $OutputPath" -Level "Info"
    
    return $OutputPath
}

# Exécuter les tests
$testResults = @{}

if ($TestComponent -eq "All") {
    $components = @("Tokenizer", "AST", "FilterFunction")
} else {
    $components = @($TestComponent)
}

foreach ($component in $components) {
    $testResults[$component] = Invoke-QueryParserTests -TestCases $testCases -TestComponent $component -TestComplexity $TestComplexity
}

# Afficher les résultats
foreach ($component in $testResults.Keys) {
    $results = $testResults[$component]
    
    Write-Log "Results for $component tests:" -Level "Info"
    Write-Log "Total Tests: $($results.TotalTests)" -Level "Info"
    Write-Log "Passed Tests: $($results.PassedTests)" -Level "Info"
    Write-Log "Failed Tests: $($results.FailedTests)" -Level "Info"
    
    if ($results.FailedTests -gt 0) {
        Write-Log "Errors:" -Level "Error"
        foreach ($error in $results.Errors) {
            Write-Log "- $error" -Level "Error"
        }
    }
}

# Générer un rapport si demandé
if ($GenerateReport) {
    $allResults = @{
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
        Errors = @()
        Details = @()
    }
    
    foreach ($component in $testResults.Keys) {
        $results = $testResults[$component]
        
        $allResults.TotalTests += $results.TotalTests
        $allResults.PassedTests += $results.PassedTests
        $allResults.FailedTests += $results.FailedTests
        $allResults.Errors += $results.Errors
        $allResults.Details += $results.Details
    }
    
    $reportPath = New-TestReport -Results $allResults
    
    # Ouvrir le rapport dans le navigateur par défaut
    Start-Process $reportPath
}

# Retourner les résultats
return $testResults
