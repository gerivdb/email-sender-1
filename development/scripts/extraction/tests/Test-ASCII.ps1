# Simple test script
Write-Host "Running simple test..."

# Define a simple function
function Test-Function {
    param (
        [string]$Message = "Hello, World!"
    )
    
    Write-Host $Message
}

# Call the function
Test-Function

Write-Host "Test completed successfully!" -ForegroundColor Green
