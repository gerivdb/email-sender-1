function Test-Function {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    Write-Output "Hello, $Name!"
}

$value = 42
$name = "Test"

Test-Function -Name $name
