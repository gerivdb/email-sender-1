# Find-EmailSenderCircularDependencies.ps1
# Algorithm 3: PowerShell Orchestration for EMAIL_SENDER_1 Dependency Analysis
# Executes Go-based dependency analyzer and provides actionable recommendations

[CmdletBinding()]
param(
    [string]$ProjectPath = $PWD,
    [string]$OutputDir = "dependency-analysis-results",
    [switch]$DetailedAnalysis,
    [switch]$AutoFix,
    [switch]$GenerateGraph,
    [string]$ComponentFilter = "",
    [int]$MaxDepth = 10
)

# EMAIL_SENDER_1 Dependency Analysis Configuration
$Script:Config = @{
    ProjectName = "EMAIL_SENDER_1"
    AnalysisVersion = "3.0.0"
    CriticalComponents = @(
        "n8n-workflows",
        "rag-engine", 
        "notion-integration",
        "gmail-processor",
        "powershell-scripts"
    )
    ComponentPriority = @{
        "rag_engine" = 1
        "n8n_workflow" = 2
        "notion_integration" = 3
        "gmail_processor" = 4
        "powershell_script" = 5
        "configuration" = 6
        "documentation" = 7
    }
    CircularityThresholds = @{
        High = 3      # Cycles <= 3 components
        Medium = 6    # Cycles 4-6 components  
        Low = 10      # Cycles 7+ components
    }
}

# Analysis Results Storage
$Script:Results = @{
    StartTime = Get-Date
    ProjectPath = ""
    TotalComponents = 0
    CircularDependencies = @()
    CriticalIssues = @()
    Recommendations = @()
    FixActions = @()
    AnalysisSuccess = $false
}

function Write-Header {
    param([string]$Title, [string]$Color = "Cyan")
    
    $border = "=" * 70
    Write-Host $border -ForegroundColor $Color
    Write-Host "  🔗 $Title" -ForegroundColor $Color
    Write-Host $border -ForegroundColor $Color
    Write-Host ""
}

function Write-Section {
    param([string]$Title, [string]$Color = "Yellow")
    
    Write-Host ""
    Write-Host "📋 $Title" -ForegroundColor $Color
    Write-Host ("-" * 50) -ForegroundColor $Color
}

function Write-Progress {
    param([string]$Activity, [string]$Status, [int]$PercentComplete = -1)
    
    if ($PercentComplete -ge 0) {
        Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    } else {
        Write-Host "⏳ $Activity - $Status" -ForegroundColor Blue
    }
}

function Test-Prerequisites {
    Write-Section "Testing Prerequisites"
    
    $prerequisites = @()
    
    # Test Go installation
    try {
        $goVersion = & go version 2>$null
        if ($goVersion) {
            Write-Host "✅ Go: $goVersion" -ForegroundColor Green
        } else {
            $prerequisites += "Go runtime not found"
        }
    } catch {
        $prerequisites += "Go runtime not found"
    }
    
    # Test project structure
    $requiredPaths = @(
        "scripts",
        "src", 
        ".github",
        "n8n"
    )
    
    foreach ($path in $requiredPaths) {
        $fullPath = Join-Path $ProjectPath $path
        if (Test-Path $fullPath) {
            Write-Host "✅ Project structure: $path found" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Project structure: $path not found" -ForegroundColor Yellow
        }
    }
    
    # Test output directory
    if (-not (Test-Path $OutputDir)) {
        try {
            New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
            Write-Host "✅ Output directory created: $OutputDir" -ForegroundColor Green
        } catch {
            $prerequisites += "Cannot create output directory: $OutputDir"
        }
    } else {
        Write-Host "✅ Output directory exists: $OutputDir" -ForegroundColor Green
    }
    
    if ($prerequisites.Count -gt 0) {
        Write-Host ""
        Write-Host "❌ Prerequisites failed:" -ForegroundColor Red
        foreach ($prereq in $prerequisites) {
            Write-Host "   • $prereq" -ForegroundColor Red
        }
        return $false
    }
    
    Write-Host ""
    Write-Host "✅ All prerequisites satisfied!" -ForegroundColor Green
    return $true
}

function Start-DependencyAnalysis {
    Write-Section "Starting Dependency Analysis"
    
    $Script:Results.ProjectPath = $ProjectPath
    
    # Prepare Go analyzer
    $analyzerPath = Join-Path $PSScriptRoot "email_sender_dependency_analyzer.go"
    if (-not (Test-Path $analyzerPath)) {
        Write-Host "❌ Go analyzer not found: $analyzerPath" -ForegroundColor Red
        return $false
    }
    
    # Prepare output file
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputFile = Join-Path $OutputDir "dependency_analysis_$timestamp.json"
    
    Write-Progress "Dependency Analysis" "Running Go analyzer..." 10
    
    try {
        # Execute Go analyzer
        $analyzerArgs = @($analyzerPath, $ProjectPath, $outputFile)
        
        Write-Host "🚀 Executing: go run $($analyzerArgs -join ' ')" -ForegroundColor Blue
        
        $analysisOutput = & go run @analyzerArgs 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Go analyzer completed successfully" -ForegroundColor Green
            
            # Display analyzer output
            if ($analysisOutput) {
                Write-Host ""
                Write-Host "📊 Analyzer Output:" -ForegroundColor Cyan
                $analysisOutput | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
            }
            
            # Load results
            if (Test-Path $outputFile) {
                return Import-AnalysisResults -ResultsFile $outputFile
            } else {
                Write-Host "❌ Output file not created: $outputFile" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "❌ Go analyzer failed with exit code: $LASTEXITCODE" -ForegroundColor Red
            if ($analysisOutput) {
                Write-Host "Error output:" -ForegroundColor Red
                $analysisOutput | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
            }
            return $false
        }
    } catch {
        Write-Host "❌ Failed to execute Go analyzer: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Import-AnalysisResults {
    param([string]$ResultsFile)
    
    Write-Progress "Analysis Import" "Loading dependency analysis results..." 30
    
    try {
        $analysisData = Get-Content $ResultsFile -Raw | ConvertFrom-Json
        
        $Script:Results.TotalComponents = $analysisData.stats.total_nodes
        $Script:Results.CircularDependencies = $analysisData.circular
        $Script:Results.AnalysisSuccess = $true
        
        Write-Host "✅ Analysis results loaded successfully" -ForegroundColor Green
        Write-Host "   • Total Components: $($Script:Results.TotalComponents)" -ForegroundColor White
        Write-Host "   • Circular Dependencies: $($Script:Results.CircularDependencies.Count)" -ForegroundColor White
        
        return $true
    } catch {
        Write-Host "❌ Failed to load analysis results: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-CircularDependencies {
    Write-Section "Analyzing Circular Dependencies"
    
    if ($Script:Results.CircularDependencies.Count -eq 0) {
        Write-Host "✅ No circular dependencies found!" -ForegroundColor Green
        return
    }
    
    Write-Progress "Circular Analysis" "Processing circular dependencies..." 50
    
    # Categorize by severity
    $highSeverity = $Script:Results.CircularDependencies | Where-Object { $_.severity -eq "high" }
    $mediumSeverity = $Script:Results.CircularDependencies | Where-Object { $_.severity -eq "medium" }
    $lowSeverity = $Script:Results.CircularDependencies | Where-Object { $_.severity -eq "low" }
    
    Write-Host "🔄 Circular Dependencies Summary:" -ForegroundColor Cyan
    Write-Host "   • High Severity: $($highSeverity.Count)" -ForegroundColor Red
    Write-Host "   • Medium Severity: $($mediumSeverity.Count)" -ForegroundColor Yellow
    Write-Host "   • Low Severity: $($lowSeverity.Count)" -ForegroundColor Blue
    
    # Process high severity first
    if ($highSeverity.Count -gt 0) {
        Write-Host ""
        Write-Host "⚠️  HIGH SEVERITY CIRCULAR DEPENDENCIES:" -ForegroundColor Red
        
        for ($i = 0; $i -lt [Math]::Min($highSeverity.Count, 5); $i++) {
            $circular = $highSeverity[$i]
            Write-Host "   $($i + 1). Length: $($circular.length)" -ForegroundColor Red
            Write-Host "      Cycle: $($circular.cycle -join ' → ')" -ForegroundColor White
            Write-Host "      Impact: $($circular.impact)" -ForegroundColor Yellow
            
            # Add to critical issues
            $Script:Results.CriticalIssues += @{
                Type = "CircularDependency"
                Severity = "High"
                Cycle = $circular.cycle
                Impact = $circular.impact
                RecommendedAction = Get-CircularDependencyRecommendation -Circular $circular
            }
        }
    }
    
    # Generate component-specific recommendations
    New-ComponentRecommendations
}

function Get-CircularDependencyRecommendation {
    param($Circular)
    
    $cycle = $Circular.cycle
    $length = $Circular.length
    
    # Analyze cycle components
    $componentTypes = @()
    foreach ($component in $cycle) {
        if ($component -match "\.ps1$") { $componentTypes += "PowerShell" }
        elseif ($component -match "\.py$") { $componentTypes += "Python" }
        elseif ($component -match "\.js$") { $componentTypes += "JavaScript" }
        elseif ($component -match "\.json$") { $componentTypes += "Configuration" }
        elseif ($component -match "n8n") { $componentTypes += "N8N Workflow" }
        elseif ($component -match "notion") { $componentTypes += "Notion Integration" }
        else { $componentTypes += "Other" }
    }
    
    # Generate specific recommendations
    $recommendations = @()
    
    if ($length -le 2) {
        $recommendations += "IMMEDIATE ACTION: Direct circular dependency detected"
        $recommendations += "• Extract shared functionality into a separate module"
        $recommendations += "• Use dependency injection pattern"
        $recommendations += "• Consider event-driven architecture"
    } elseif ($length -le 4) {
        $recommendations += "HIGH PRIORITY: Short circular dependency cycle"
        $recommendations += "• Refactor to introduce abstraction layers"
        $recommendations += "• Use interface segregation principle"
        $recommendations += "• Consider breaking into smaller components"
    } else {
        $recommendations += "MEDIUM PRIORITY: Complex dependency cycle"
        $recommendations += "• Review overall architecture design"
        $recommendations += "• Consider implementing mediator pattern"
        $recommendations += "• Evaluate component responsibilities"
    }
    
    # Component-specific recommendations
    if ($componentTypes -contains "N8N Workflow") {
        $recommendations += "• N8N-specific: Use webhook triggers instead of direct calls"
        $recommendations += "• Consider queue-based communication for N8N workflows"
    }
    
    if ($componentTypes -contains "Configuration") {
        $recommendations += "• Config-specific: Centralize configuration management"
        $recommendations += "• Use configuration hierarchy with defaults"
    }
    
    return $recommendations
}

function New-ComponentRecommendations {
    Write-Progress "Recommendations" "Generating component recommendations..." 70
    
    # EMAIL_SENDER_1 specific recommendations
    $emailSenderRecommendations = @(
        @{
            Component = "RAG Engine"
            Priority = "High"
            Actions = @(
                "Implement async processing for RAG operations",
                "Use message queues for N8N integration",
                "Cache frequently accessed embeddings"
            )
        },
        @{
            Component = "N8N Workflows"  
            Priority = "High"
            Actions = @(
                "Use webhook endpoints instead of direct file dependencies",
                "Implement error handling and retry mechanisms",
                "Store workflow state in external database"
            )
        },
        @{
            Component = "Notion Integration"
            Priority = "Medium"
            Actions = @(
                "Implement rate limiting for Notion API calls",
                "Use batch operations for bulk updates",
                "Cache database schema information"
            )
        },
        @{
            Component = "Gmail Processor"
            Priority = "Medium"
            Actions = @(
                "Use OAuth2 flow for authentication",
                "Implement email queue for processing",
                "Add attachment handling safeguards"
            )
        }
    )
    
    $Script:Results.Recommendations = $emailSenderRecommendations
}

function New-FixActions {
    Write-Section "Generating Fix Actions"
    
    if ($Script:Results.CriticalIssues.Count -eq 0) {
        Write-Host "✅ No critical issues requiring immediate fixes" -ForegroundColor Green
        return
    }
    
    Write-Progress "Fix Generation" "Creating automated fix actions..." 80
    
    $fixActions = @()
    
    foreach ($issue in $Script:Results.CriticalIssues) {
        if ($issue.Type -eq "CircularDependency") {
            $cycle = $issue.Cycle
            
            # Generate PowerShell fix script
            $fixScript = @"
# AUTO-GENERATED FIX: Circular Dependency Resolution
# Cycle: $($cycle -join ' → ')
# Generated: $(Get-Date)

# Step 1: Create abstraction layer
Write-Host "Creating abstraction layer for circular dependency..." -ForegroundColor Yellow

# Step 2: Extract shared interfaces
`$sharedInterfacePath = "src/shared/interfaces"
if (-not (Test-Path `$sharedInterfacePath)) {
    New-Item -ItemType Directory -Path `$sharedInterfacePath -Force
}

# Step 3: Refactor components
# TODO: Manual review required for component refactoring

Write-Host "✅ Abstraction layer created. Manual refactoring required." -ForegroundColor Green
"@
            
            $fixActions += @{
                IssueType = "CircularDependency"
                Cycle = $cycle
                Severity = $issue.Severity
                FixScript = $fixScript
                ManualSteps = $issue.RecommendedAction
                AutoFixable = $false
            }
        }
    }
    
    $Script:Results.FixActions = $fixActions
    
    if ($AutoFix) {
        Execute-AutoFixes
    }
}

function Execute-AutoFixes {
    Write-Section "Executing Automated Fixes"
    
    $autoFixableActions = $Script:Results.FixActions | Where-Object { $_.AutoFixable -eq $true }
    
    if ($autoFixableActions.Count -eq 0) {
        Write-Host "⚠️  No automatically fixable issues found" -ForegroundColor Yellow
        Write-Host "   Manual intervention required for all detected issues" -ForegroundColor White
        return
    }
    
    foreach ($action in $autoFixableActions) {
        Write-Host "🔧 Executing auto-fix for: $($action.IssueType)" -ForegroundColor Blue
        
        try {
            $scriptBlock = [ScriptBlock]::Create($action.FixScript)
            & $scriptBlock
            
            Write-Host "✅ Auto-fix completed for: $($action.IssueType)" -ForegroundColor Green
        } catch {
            Write-Host "❌ Auto-fix failed for: $($action.IssueType)" -ForegroundColor Red
            Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function New-DependencyReport {
    Write-Section "Generating Dependency Report"
    
    Write-Progress "Report Generation" "Creating comprehensive dependency report..." 90
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $reportFile = Join-Path $OutputDir "EMAIL_SENDER_1_Dependency_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    
    $report = @"
# 🔗 EMAIL_SENDER_1 Dependency Analysis Report

**Generated:** $timestamp  
**Project:** $($Script:Results.ProjectPath)  
**Analysis Version:** $($Script:Config.AnalysisVersion)

## 📊 Executive Summary

- **Total Components:** $($Script:Results.TotalComponents)
- **Circular Dependencies:** $($Script:Results.CircularDependencies.Count)
- **Critical Issues:** $($Script:Results.CriticalIssues.Count)
- **Analysis Status:** $(if ($Script:Results.AnalysisSuccess) { "✅ Success" } else { "❌ Failed" })

## 🔄 Circular Dependencies Analysis

$(if ($Script:Results.CircularDependencies.Count -eq 0) {
    "✅ **No circular dependencies detected!**"
} else {
    "⚠️  **$($Script:Results.CircularDependencies.Count) circular dependencies found:**"
    ""
    for ($i = 0; $i -lt [Math]::Min($Script:Results.CircularDependencies.Count, 10); $i++) {
        $circular = $Script:Results.CircularDependencies[$i]
        "### Cycle $($i + 1) - [$($circular.severity.ToUpper())] Severity"
        "- **Length:** $($circular.length) components"
        "- **Cycle:** ``$($circular.cycle -join ' → ')``"  
        "- **Impact:** $($circular.impact)"
        ""
    }
})

## 🎯 Component Recommendations

$(foreach ($rec in $Script:Results.Recommendations) {
    "### $($rec.Component) - Priority: $($rec.Priority)"
    ""
    foreach ($action in $rec.Actions) {
        "- $action"
    }
    ""
})

## 🔧 Fix Actions Required

$(if ($Script:Results.FixActions.Count -eq 0) {
    "✅ No immediate fix actions required"
} else {
    foreach ($fix in $Script:Results.FixActions) {
        "### $($fix.IssueType) - $($fix.Severity) Severity"
        "**Affected Cycle:** ``$($fix.Cycle -join ' → ')``"
        ""
        "**Recommended Actions:**"
        foreach ($step in $fix.ManualSteps) {
            "- $step"
        }
        ""
    }
})

## 📋 Next Steps

1. **Immediate Actions:**
   - Review high-severity circular dependencies
   - Implement recommended architectural changes
   - Test component isolation strategies

2. **Medium-term Goals:**
   - Refactor complex dependency cycles
   - Implement dependency injection patterns
   - Add automated dependency monitoring

3. **Long-term Architecture:**
   - Consider microservices architecture for EMAIL_SENDER_1
   - Implement event-driven communication
   - Add comprehensive integration testing

---
*Report generated by EMAIL_SENDER_1 Dependency Analysis System v$($Script:Config.AnalysisVersion)*
"@

    try {
        $report | Out-File -FilePath $reportFile -Encoding UTF8
        Write-Host "✅ Dependency report generated: $reportFile" -ForegroundColor Green
        
        # Open report if requested
        if ($DetailedAnalysis) {
            Start-Process $reportFile
        }
        
        return $reportFile
    } catch {
        Write-Host "❌ Failed to generate report: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Show-FinalSummary {
    Write-Header "EMAIL_SENDER_1 Dependency Analysis Complete" "Green"
    
    $duration = (Get-Date) - $Script:Results.StartTime
    
    Write-Host "🎯 ANALYSIS SUMMARY:" -ForegroundColor Cyan
    Write-Host "   • Duration: $($duration.TotalSeconds.ToString('0.0')) seconds" -ForegroundColor White
    Write-Host "   • Components Analyzed: $($Script:Results.TotalComponents)" -ForegroundColor White  
    Write-Host "   • Circular Dependencies: $($Script:Results.CircularDependencies.Count)" -ForegroundColor White
    Write-Host "   • Critical Issues: $($Script:Results.CriticalIssues.Count)" -ForegroundColor White
    
    if ($Script:Results.CircularDependencies.Count -eq 0) {
        Write-Host ""
        Write-Host "🎉 EXCELLENT! No circular dependencies found in EMAIL_SENDER_1!" -ForegroundColor Green
        Write-Host "   Your project architecture is well-structured." -ForegroundColor Green
    } else {
        $highSeverity = $Script:Results.CircularDependencies | Where-Object { $_.severity -eq "high" }
        
        Write-Host ""
        if ($highSeverity.Count -gt 0) {
            Write-Host "⚠️  ACTION REQUIRED: $($highSeverity.Count) high-severity circular dependencies detected!" -ForegroundColor Red
            Write-Host "   Immediate architectural review recommended." -ForegroundColor Red
        } else {
            Write-Host "✅ No high-severity issues detected." -ForegroundColor Green
            Write-Host "   Medium/low severity cycles can be addressed gradually." -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "📂 OUTPUTS:" -ForegroundColor Cyan
    Write-Host "   • Analysis results saved to: $OutputDir" -ForegroundColor White
    Write-Host "   • Dependency report available for review" -ForegroundColor White
    
    if ($Script:Results.Recommendations.Count -gt 0) {
        Write-Host ""
        Write-Host "🎯 TOP RECOMMENDATIONS:" -ForegroundColor Yellow
        
        $priorityRecs = $Script:Results.Recommendations | Where-Object { $_.Priority -eq "High" } | Select-Object -First 3
        foreach ($rec in $priorityRecs) {
            Write-Host "   • $($rec.Component): $($rec.Actions[0])" -ForegroundColor White
        }
    }
    
    Write-Host ""
    Write-Host "🚀 NEXT STEPS:" -ForegroundColor Cyan
    Write-Host "   1. Review generated dependency report" -ForegroundColor White
    Write-Host "   2. Implement high-priority architectural changes" -ForegroundColor White
    Write-Host "   3. Run Algorithm 4 (Progressive Build) for validation" -ForegroundColor White
    
    Write-Host ""
    Write-Host "=" * 70 -ForegroundColor Green
}

# ===================================
# MAIN EXECUTION FLOW
# ===================================

try {
    Write-Header "EMAIL_SENDER_1 Dependency Analysis (Algorithm 3)"
    
    Write-Host "📁 Project Path: $ProjectPath" -ForegroundColor White
    Write-Host "📂 Output Directory: $OutputDir" -ForegroundColor White
    Write-Host "🔍 Component Filter: $(if ($ComponentFilter) { $ComponentFilter } else { 'All components' })" -ForegroundColor White
    Write-Host "⚙️  Max Depth: $MaxDepth" -ForegroundColor White
    Write-Host ""
    
    # Step 1: Test Prerequisites
    if (-not (Test-Prerequisites)) {
        Write-Host "❌ Prerequisites check failed. Exiting..." -ForegroundColor Red
        exit 1
    }
    
    # Step 2: Start Dependency Analysis
    if (-not (Start-DependencyAnalysis)) {
        Write-Host "❌ Dependency analysis failed. Exiting..." -ForegroundColor Red
        exit 1
    }
    
    # Step 3: Analyze Circular Dependencies
    Test-CircularDependencies
    
    # Step 4: Generate Fix Actions
    New-FixActions
    
    # Step 5: Generate Report
    $reportFile = New-DependencyReport
    
    # Step 6: Show Final Summary
    Show-FinalSummary
    
    Write-Host "✅ EMAIL_SENDER_1 Dependency Analysis completed successfully!" -ForegroundColor Green
    
    if ($reportFile) {
        Write-Host "📋 View the full report: $reportFile" -ForegroundColor Cyan
    }
    
} catch {
    Write-Host ""
    Write-Host "❌ CRITICAL ERROR in dependency analysis:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    
    Write-Host ""
    Write-Host "🔧 TROUBLESHOOTING STEPS:" -ForegroundColor Yellow
    Write-Host "   1. Verify Go is installed: go version" -ForegroundColor White
    Write-Host "   2. Check project path permissions" -ForegroundColor White
    Write-Host "   3. Ensure output directory is writable" -ForegroundColor White
    Write-Host "   4. Review Go analyzer source code" -ForegroundColor White
    
    exit 1
}
