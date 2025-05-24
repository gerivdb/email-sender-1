# Script de test simple pour les modules
param([string]$TestPath = ".")

try {
    Write-Host "🔧 Testing PowerShell Module Structure" -ForegroundColor Cyan
      # Test import of VerbMapping module
    $VerbMappingPath = "..\core\modules\PowerShellVerbMapping\PowerShellVerbMapping.psm1"
    Write-Host "Testing VerbMapping module at: $VerbMappingPath"
    
    if (Test-Path $VerbMappingPath) {
        Import-Module $VerbMappingPath -Force
        Write-Host "✅ VerbMapping module imported successfully" -ForegroundColor Green
        
        # Test functions
        $approvedVerbs = Get-ApprovedVerbs
        Write-Host "  - Approved verbs count: $($approvedVerbs.Count)" -ForegroundColor White
        
        $mappings = Get-VerbMappings  
        Write-Host "  - Verb mappings count: $($mappings.Count)" -ForegroundColor White
        
        $isApproved = Test-VerbApproved -Verb "Get"
        Write-Host "  - Test-VerbApproved 'Get': $isApproved" -ForegroundColor White
        
        $suggestion = Get-VerbSuggestion -Verb "Create"
        Write-Host "  - Suggestion for 'Create': $suggestion" -ForegroundColor White
    } else {
        Write-Host "❌ VerbMapping module not found" -ForegroundColor Red
        exit 1
    }
      # Test import of FunctionValidator module
    $ValidatorPath = "..\core\modules\PowerShellFunctionValidator\PowerShellFunctionValidator.psm1"
    Write-Host "`nTesting FunctionValidator module at: $ValidatorPath"
    
    if (Test-Path $ValidatorPath) {
        Import-Module $ValidatorPath -Force
        Write-Host "✅ FunctionValidator module imported successfully" -ForegroundColor Green
        
        # Test with sample content
        $testContent = @"
function Create-TestFile {
    param([string]`$Path)
    Write-Host "Test"
}

function Get-ValidData {
    return "Valid"
}
"@
        
        $violations = Test-PowerShellFunctionNames -Content $testContent -FilePath "test.ps1"
        Write-Host "  - Violations found in test content: $($violations.Count)" -ForegroundColor White
        
        if ($violations.Count -gt 0) {
            foreach ($violation in $violations) {
                Write-Host "    • $($violation.FunctionName): $($violation.Issue)" -ForegroundColor Yellow
                if ($violation.SuggestedFunction) {
                    Write-Host "      Suggested: $($violation.SuggestedFunction)" -ForegroundColor Green
                }
            }
        }
    } else {
        Write-Host "❌ FunctionValidator module not found" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "`n🎉 Module testing completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Error during module testing: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
