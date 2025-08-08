# ========================================
# Validation Documentaire SOTA v3.0
# Architecture modulaire et robuste
# ========================================
param([string]$PlanFile)

#region Configuration
$Global:ValidationConfig = @{
    Colors   = @{ Error = "Red"; Warning = "Yellow"; Success = "Green"; Info = "Cyan"; FAILED = "Red" }
    Patterns = @{
        Phase         = "##\s+(Phase\s+\d+)"
        Task          = "- \[[x ]\]"
        CompletedTask = "- \[x\]"
        InternalLink  = "\[([^\]]+)\]\(#([^)]+)\)"
    }
    Limits   = @{ MaxIssues = 50; MaxDetails = 100 }
}
#endregion

#region Core Functions (KISS)
function Write-Status {
    param([string]$Message, [string]$Type = "Info")
    $color = $Global:ValidationConfig.Colors[$Type]
    $validColors = @("Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray", "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")
    if (-not $validColors -contains $color) { $color = "Gray" }
    $icon = @{Error = "❌"; Warning = "⚠️"; Success = "✅"; Info = "ℹ️" }[$Type]
    Write-Host "$icon $Message" -ForegroundColor $color
}

function New-Result {
    param([string]$TestName)
    return @{ TestName = $TestName; Status = "OK"; Issues = @(); Details = @() }
}
#endregion

#region Validation Tests (DRY)
function Test-Metadata {
    param([string]$Content)
    $result = New-Result -TestName "Métadonnées"
    
    if ($Content -match "^#\s+.+") {
        $result.Details += "Titre détecté"
    }
    else {
        $result.Issues += "Titre manquant"
        $result.Status = "WARNING"
    }
    
    if ($Content -match "Progression:\s*(\d+)%") {
        $result.Details += "Progression: $($Matches[1])%"
    }
    
    return $result
}

function Test-Structure {
    param([string]$Content)
    $result = New-Result -TestName "Structure"
    
    $phases = [regex]::Matches($Content, $Global:ValidationConfig.Patterns.Phase)
    if ($phases.Count -gt 0) {
        $result.Details += "Phases trouvées: $($phases.Count)"
    }
    else {
        $result.Issues += "Aucune phase détectée"
        $result.Status = "FAILED"
    }
    
    return $result
}

function Test-Tasks {
    param([string]$Content)
    $result = New-Result -TestName "Tâches"
    
    $totalTasks = [regex]::Matches($Content, $Global:ValidationConfig.Patterns.Task).Count
    $completedTasks = [regex]::Matches($Content, $Global:ValidationConfig.Patterns.CompletedTask).Count
    
    $result.Details += "Total: $totalTasks, Complétées: $completedTasks"
    
    if ($totalTasks -eq 0) {
        $result.Issues += "Aucune tâche détectée"
        $result.Status = "WARNING"
    }
    
    return $result
}
#endregion

#region Main Execution
function Invoke-Validation {
    param([string]$FilePath)
    
    Write-Status "Validation: $FilePath" -Type Info
    
    if (-not (Test-Path $FilePath)) {
        Write-Status "Fichier non trouvé" -Type Error
        return $false
    }
    
    $content = Get-Content $FilePath -Raw -Encoding UTF8
    
    $tests = @(
        { Test-Metadata $content },
        { Test-Structure $content },
        { Test-Tasks $content }
    )
    
    $allResults = @()
    $globalStatus = "OK"
    
    foreach ($test in $tests) {
        try {
            $result = & $test
            $allResults += $result
            
            if ($result.Status -eq "FAILED") { $globalStatus = "FAILED" }
            elseif ($result.Status -eq "WARNING" -and $globalStatus -eq "OK") { $globalStatus = "WARNING" }
            
            Write-Status "$($result.TestName): $($result.Status)" -Type $result.Status
        }
        catch {
            Write-Status "Erreur test: $($_.Exception.Message)" -Type Error
            $globalStatus = "FAILED"
        }
    }
    
    # Résumé final
    $totalIssues = ($allResults | ForEach-Object { $_.Issues.Count } | Measure-Object -Sum).Sum
    Write-Status "Statut global: $globalStatus - Issues: $totalIssues" -Type $globalStatus
    
    return $globalStatus -eq "OK"
}
#endregion


try {
    $success = Invoke-Validation -FilePath $PlanFile
    exit ($success ? 0 : 1)
}
catch {
    Write-Host "❌ Erreur fatale: $($_.Exception.Message)" -ForegroundColor "Red"
    exit 2
}
