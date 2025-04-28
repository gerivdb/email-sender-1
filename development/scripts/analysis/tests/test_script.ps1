# Test script with known issues
function Test-Function {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Parameter
    )
    
    # TODO: Add more robust error handling
    
    # This line has trailing whitespace    
    
    # FIXME: Fix performance issue
    
    Write-Host "This is a test message"
    
    # HACK: Temporary workaround for bug #123
    
    # NOTE: This function could be improved
}

# Missing BOM encoding
