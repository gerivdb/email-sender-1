# SimpleModule.psm1
# Module simple pour tester l'importation

function Test-SimpleFunction {
    [CmdletBinding()]
    param()
    
    Write-Host "La fonction Test-SimpleFunction fonctionne correctement."
}

Export-ModuleMember -Function Test-SimpleFunction
