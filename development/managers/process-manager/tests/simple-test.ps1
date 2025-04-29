[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Command = "Test"
)

Write-Host "Test exÃ©cutÃ© avec succÃ¨s : $Command"
exit 0
