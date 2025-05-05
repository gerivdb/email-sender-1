# Module PowerShell minimal
function Get-HelloWorld {
    Write-Output "Hello, World!"
}

Export-ModuleMember -Function Get-HelloWorld
