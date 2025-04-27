#Requires -Version 5.1
<#
.SYNOPSIS
    Adaptateur pour intÃ©grer Test-FileFormat.Tests.Simplified.ps1 avec Detect-FileFormat.Tests.ps1.

.DESCRIPTION
    Cet adaptateur permet d'exÃ©cuter les tests simplifiÃ©s dans l'environnement des tests rÃ©els
    en faisant le pont entre les fonctions simplifiÃ©es et les fonctions rÃ©elles.
#>

# Importer les fonctions rÃ©elles du module
$moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulePath = Join-Path -Path $moduleRoot -ChildPath "Format-Converters.psm1"

if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
}
else {
    Write-Error "Le module Format-Converters n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement : $modulePath"
    exit 1
}

# CrÃ©er un adaptateur pour la fonction Test-FileFormat
function Test-FileFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeAllFormats
    )
    
    # VÃ©rifier si la fonction rÃ©elle existe
    if (Get-Command -Name "Detect-FileFormat" -ErrorAction SilentlyContinue) {
        # Appeler la fonction rÃ©elle avec les paramÃ¨tres adaptÃ©s
        $result = Detect-FileFormat -FilePath $FilePath -IncludeAllFormats:$IncludeAllFormats
        
        # Adapter le rÃ©sultat au format attendu par les tests simplifiÃ©s
        return $result
    }
    else {
        Write-Error "La fonction Detect-FileFormat n'existe pas dans le module."
        return $null
    }
}

# Exporter la fonction adaptÃ©e
Export-ModuleMember -Function Test-FileFormat

# ExÃ©cuter les tests simplifiÃ©s avec l'adaptateur
$simplifiedTestPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Test-FileFormat.Tests.Simplified.ps1"

if (Test-Path -Path $simplifiedTestPath) {
    Write-Host "ExÃ©cution des tests simplifiÃ©s avec l'adaptateur..." -ForegroundColor Cyan
    
    # CrÃ©er un contexte d'exÃ©cution isolÃ©
    $scriptBlock = {
        param($TestPath, $AdapterPath)
        
        # Importer l'adaptateur
        . $AdapterPath
        
        # ExÃ©cuter les tests
        Invoke-Pester -Path $TestPath -PassThru
    }
    
    # ExÃ©cuter les tests dans un nouveau contexte
    $results = & $scriptBlock $simplifiedTestPath $PSCommandPath
    
    # Afficher un rÃ©sumÃ© des rÃ©sultats
    Write-Host "`nRÃ©sumÃ© des rÃ©sultats :" -ForegroundColor Cyan
    Write-Host "Tests exÃ©cutÃ©s : $($results.TotalCount)"
    Write-Host "Tests rÃ©ussis : $($results.PassedCount)" -ForegroundColor Green
    Write-Host "Tests Ã©chouÃ©s : $($results.FailedCount)" -ForegroundColor Red
    Write-Host "Tests ignorÃ©s : $($results.SkippedCount)" -ForegroundColor Yellow
    
    # Retourner les rÃ©sultats
    return $results
}
else {
    Write-Error "Le fichier de test simplifiÃ© n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement : $simplifiedTestPath"
    exit 1
}
