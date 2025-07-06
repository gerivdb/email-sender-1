<#
.SYNOPSIS
    This is a test function for PowerShell documentation.
.DESCRIPTION
    This function demonstrates how to document PowerShell functions.
.PARAMETER Name
    The name to greet.
.EXAMPLE
    Say-Hello -Name "World"
#>
function Say-Hello {
   param(
      [Parameter(Mandatory = $true)]
      [string]$Name
   )
   Write-Output "Hello, $Name!"
}

<#
.SYNOPSIS
    This is another test function.
.DESCRIPTION
    This function calculates the sum of two numbers.
.PARAMETER A
    The first number.
.PARAMETER B
    The second number.
.RETURNS
    The sum of A and B.
.EXAMPLE
    Add-Numbers -A 5 -B 3
#>
function Add-Numbers {
   param(
      [Parameter(Mandatory = $true)]
      [int]$A,
      [Parameter(Mandatory = $true)]
      [int]$B
   )
   return $A + $B
}