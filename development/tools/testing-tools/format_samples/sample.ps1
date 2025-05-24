#Requires -Version 5.1
<#
.SYNOPSIS
    Sample PowerShell script.
.DESCRIPTION
    This is a sample PowerShell script for testing format detection.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter()]
    [string]$OutputPath = "output.txt"
)

function Invoke-File {
    param(
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        Write-Error "File not found: $Path"
        return $false
    }

    try {
        $content = Get-Content -Path $Path -Raw
        return $content
    }
    catch {
        Write-Error "Error processing file: $_"
        return $false
    }
}

# Main script
$result = Invoke-File -Path $InputPath
if ($result -ne $false) {
    Set-Content -Path $OutputPath -Value $result
    Write-Host "File processed successfully."
}

