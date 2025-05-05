# Test-FileEncoding.ps1
# Script to check file encoding

# Function to check file encoding
function Test-FileEncoding {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        # Read the first few bytes to detect encoding
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        
        # Check for UTF-8 BOM
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            Write-Host "File $FilePath has UTF-8 BOM encoding" -ForegroundColor Yellow
            return "UTF-8-BOM"
        }
        
        # Check for UTF-16 LE BOM
        if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            Write-Host "File $FilePath has UTF-16 LE encoding" -ForegroundColor Yellow
            return "UTF-16-LE"
        }
        
        # Check for UTF-16 BE BOM
        if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
            Write-Host "File $FilePath has UTF-16 BE encoding" -ForegroundColor Yellow
            return "UTF-16-BE"
        }
        
        # If no BOM detected, assume UTF-8 without BOM or ASCII
        Write-Host "File $FilePath has UTF-8 without BOM or ASCII encoding" -ForegroundColor Green
        return "UTF-8-NoBOM-or-ASCII"
    }
    catch {
        Write-Host "Error checking encoding for file $FilePath : $_" -ForegroundColor Red
        return "Unknown"
    }
}

# Check encoding of the module file
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
$encoding = Test-FileEncoding -FilePath $modulePath

# Output result
Write-Host "Module file encoding: $encoding" -ForegroundColor Cyan

# Exit with success code
exit 0
