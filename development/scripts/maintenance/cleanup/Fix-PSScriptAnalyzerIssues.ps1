# Script pour corriger automatiquement les problÃ¨mes courants dÃ©tectÃ©s par PSScriptAnalyzer
# Ce script analyse les fichiers PowerShell et corrige automatiquement les problÃ¨mes courants


# Script pour corriger automatiquement les problÃ¨mes courants dÃ©tectÃ©s par PSScriptAnalyzer
# Ce script analyse les fichiers PowerShell et corrige automatiquement les problÃ¨mes courants

param (
    [Parameter(Mandatory = $false)]
    [string[]]$Path,

    [Parameter(Mandatory = $false)]
    [string[]]$Include = "*.ps1",

    [Parameter(Mandatory = $false)]
    [switch]$Recurse,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

try {
    # Verify if PSScriptAnalyzer module is installed
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        Write-Host "PSScriptAnalyzer module is not installed. Installing..." -ForegroundColor Yellow
        Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
    }

    # Import PSScriptAnalyzer module
    Import-Module PSScriptAnalyzer

    # Function to repair null comparisons
    function Repair-NullComparison {
        param (
            [string]$Content
        )

        $pattern = '(\$\w+)\s+-(?:eq|ne)\s+\$null'
        $replacement = '$null -$2 $1'
        $newContent = $Content -replace $pattern, $replacement

        return $newContent
    }

    # Function to repair unapproved verbs
    function Repair-UnapprovedVerbs {
        param (
            [string]$Content
        )

        # Dictionary of unapproved verbs and their replacements
        $verbMapping = @{
            'Analyze'  = 'Test'
            'Fix'      = 'Repair'
            'Create'   = 'New'
            'Generate' = 'New'
            'Verify'   = 'Test'
            'Block'    = 'Stop'
            'Save'     = 'Export'
            'Import'   = 'Import'
            'Set'      = 'Set'
            'Remove'   = 'Remove'
        }

        $newContent = $Content

        $matchResults = [regex]::Matches($Content, 'function\s+(\w+)-(\w+)')
        foreach ($match in $matchResults) {
            $verb = $match.Groups[1].Value
            $noun = $match.Groups[2].Value

            if ($verbMapping.ContainsKey($verb) -and $verbMapping[$verb] -ne $verb) {
                $approvedVerb = $verbMapping[$verb]
                $oldFunctionName = "$verb-$noun"
                $newFunctionName = "$approvedVerb-$noun"

                $newContent = $newContent -replace "function\s+$oldFunctionName", "function $newFunctionName"
                $newContent = $newContent -replace "(?<!\w)$oldFunctionName(?!\w)", $newFunctionName
            }
        }

        return $newContent
    }

    # Function to repair switch default values
    function Repair-SwitchDefaultValue {
        param (
            [string]$Content
        )

        $pattern = '\[switch\]\$(\w+)\s*=\s*\$true'
        $matchResults = [regex]::Matches($Content, $pattern)
        $newContent = $Content

        foreach ($match in $matchResults) {
            $paramName = $match.Groups[1].Value
            $checkCode = "    if (-not `$PSBoundParameters.ContainsKey('$paramName')) {`n        `$$paramName = `$true`n    }"

            $paramEndPattern = "param\s*\([^)]*\)\s*"
            $paramEndMatch = [regex]::Match($Content, $paramEndPattern)
            if ($paramEndMatch.Success) {
                $insertPosition = $paramEndMatch.Index + $paramEndMatch.Length
                $newContent = $newContent.Insert($insertPosition, "`n$checkCode`n")
            }
        }

        return $newContent
    }

    # Function to repair unused variables
    function Repair-UnusedVariables {
        param (
            [string]$Content
        )

        $pattern = '(\$\w+)\s*=\s*([^;]+)(?:;|\r?\n)'
        $matchResults = [regex]::Matches($Content, $pattern)

        $newContent = $Content
        foreach ($match in $matchResults) {
            $varName = $match.Groups[1].Value
            $varValue = $match.Groups[2].Value.Trim()

            $varUsagePattern = "(?<!\w)$([regex]::Escape($varName))(?!\w)"
            $varUsageMatches = [regex]::Matches($Content, $varUsagePattern)

            if ($varUsageMatches.Count -eq 1) {
                $newContent = $newContent -replace [regex]::Escape($match.Value), "`$null = $varValue`n"
            }
        }

        return $newContent
    }

    # Main function to repair PSScriptAnalyzer issues
    function Repair-PSScriptAnalyzerIssues {
        param (
            [string]$FilePath,
            [switch]$WhatIf
        )

        Write-Host "Analyzing file: $FilePath" -ForegroundColor Cyan

        $issues = Invoke-ScriptAnalyzer -Path $FilePath

        if ($issues.Count -eq 0) {
            Write-Host "  No issues detected." -ForegroundColor Green
            return
        }

        Write-Host "  $($issues.Count) issues detected." -ForegroundColor Yellow

        $content = Get-Content -Path $FilePath -Raw
        $originalContent = $content

        $issueTypes = $issues | Group-Object -Property RuleName

        foreach ($issueType in $issueTypes) {
            $ruleName = $issueType.Name
            $count = $issueType.Count

            Write-Host "  Repairing $count issues of type '$ruleName'..." -ForegroundColor Yellow

            switch ($ruleName) {
                "PSPossibleIncorrectComparisonWithNull" {
                    $content = Repair-NullComparison -Content $content
                }
                "PSUseApprovedVerbs" {
                    $content = Repair-UnapprovedVerbs -Content $content
                }
                "PSAvoidDefaultValueSwitchParameter" {
                    $content = Repair-SwitchDefaultValue -Content $content
                }
                "PSUseDeclaredVarsMoreThanAssignments" {
                    $content = Repair-UnusedVariables -Content $content
                }
                default {
                    Write-Host "    Issue type '$ruleName' is not supported for automatic repair." -ForegroundColor Yellow
                }
            }
        }

        if ($content -ne $originalContent) {
            if ($WhatIf) {
                Write-Host "  File would be modified (WhatIf)." -ForegroundColor Yellow
            }
            else {
                Set-Content -Path $FilePath -Value $content -Encoding UTF8
                Write-Host "  File has been modified." -ForegroundColor Green

                $remainingIssues = Invoke-ScriptAnalyzer -Path $FilePath
                if ($remainingIssues.Count -gt 0) {
                    Write-Host "  $($remainingIssues.Count) issues remain after repair." -ForegroundColor Yellow
                }
                else {
                    Write-Host "  All issues have been repaired." -ForegroundColor Green
                }
            }
        }
        else {
            Write-Host "  No modifications were made to the file." -ForegroundColor Yellow
        }
    }

    # Main execution
    function Start-PSScriptAnalyzerRepair {
        $files = Get-ChildItem -Path $Path -Include $Include -Recurse:$Recurse -File

        Write-Host "Analyzing $($files.Count) files..." -ForegroundColor Cyan

        foreach ($file in $files) {
            Repair-PSScriptAnalyzerIssues -FilePath $file.FullName -WhatIf:$WhatIf
        }

        Write-Host "Analysis complete." -ForegroundColor Green
    }

    # Start the analysis
    Start-PSScriptAnalyzerRepair

} catch {
    Write-Error "A critical error occurred: $_"
    exit 1
} finally {
    Write-Host "Script execution completed." -ForegroundColor Green
}

