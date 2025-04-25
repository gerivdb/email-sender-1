#Requires -Version 5.1
<#
.SYNOPSIS
    Adaptateur pour intÃ©grer Confirm-FormatDetection.Tests.Simplified.ps1 avec les tests rÃ©els.

.DESCRIPTION
    Cet adaptateur permet d'exÃ©cuter les tests simplifiÃ©s dans l'environnement des tests rÃ©els
    en faisant le pont entre les fonctions simplifiÃ©es et les fonctions rÃ©elles.

.NOTES
    GÃ©nÃ©rÃ© automatiquement par Generate-TestAdapters.ps1
    Date de gÃ©nÃ©ration : 2025-04-11 14:28:04
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

# CrÃ©er un adaptateur pour la fonction Confirm-FormatDetection
function Confirm-FormatDetection {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Position = 0)]
        [object[]]$InputObject,
        
        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$RemainingArgs
    )
    
    process {
        # VÃ©rifier si la fonction rÃ©elle existe
        if (Get-Command -Name "Confirm-FormatDetection" -ErrorAction SilentlyContinue) {
            # Appeler la fonction rÃ©elle avec les paramÃ¨tres adaptÃ©s
            $result = & "Confirm-FormatDetection" @PSBoundParameters
            
            # Retourner le rÃ©sultat
            return $result
        }
        else {
            Write-Error "La fonction Confirm-FormatDetection n'existe pas dans le module."
            return $null
        }
    }
}

# Exporter la fonction adaptÃ©e
Export-ModuleMember -Function Confirm-FormatDetection

# ExÃ©cuter les tests simplifiÃ©s avec l'adaptateur
$simplifiedTestPath = Join-Path -Path $PSScriptRoot -ChildPath "..\\Confirm-FormatDetection.Tests.Simplified.ps1"

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
    Write-Host "
RÃ©sumÃ© des rÃ©sultats :" -ForegroundColor Cyan
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
