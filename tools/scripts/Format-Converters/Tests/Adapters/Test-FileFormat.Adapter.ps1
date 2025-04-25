#Requires -Version 5.1
<#
.SYNOPSIS
    Adaptateur pour intégrer Test-FileFormat.Tests.Simplified.ps1 avec Detect-FileFormat.Tests.ps1.

.DESCRIPTION
    Cet adaptateur permet d'exécuter les tests simplifiés dans l'environnement des tests réels
    en faisant le pont entre les fonctions simplifiées et les fonctions réelles.
#>

# Importer les fonctions réelles du module
$moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulePath = Join-Path -Path $moduleRoot -ChildPath "Format-Converters.psm1"

if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
}
else {
    Write-Error "Le module Format-Converters n'a pas été trouvé à l'emplacement : $modulePath"
    exit 1
}

# Créer un adaptateur pour la fonction Test-FileFormat
function Test-FileFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeAllFormats
    )
    
    # Vérifier si la fonction réelle existe
    if (Get-Command -Name "Detect-FileFormat" -ErrorAction SilentlyContinue) {
        # Appeler la fonction réelle avec les paramètres adaptés
        $result = Detect-FileFormat -FilePath $FilePath -IncludeAllFormats:$IncludeAllFormats
        
        # Adapter le résultat au format attendu par les tests simplifiés
        return $result
    }
    else {
        Write-Error "La fonction Detect-FileFormat n'existe pas dans le module."
        return $null
    }
}

# Exporter la fonction adaptée
Export-ModuleMember -Function Test-FileFormat

# Exécuter les tests simplifiés avec l'adaptateur
$simplifiedTestPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Test-FileFormat.Tests.Simplified.ps1"

if (Test-Path -Path $simplifiedTestPath) {
    Write-Host "Exécution des tests simplifiés avec l'adaptateur..." -ForegroundColor Cyan
    
    # Créer un contexte d'exécution isolé
    $scriptBlock = {
        param($TestPath, $AdapterPath)
        
        # Importer l'adaptateur
        . $AdapterPath
        
        # Exécuter les tests
        Invoke-Pester -Path $TestPath -PassThru
    }
    
    # Exécuter les tests dans un nouveau contexte
    $results = & $scriptBlock $simplifiedTestPath $PSCommandPath
    
    # Afficher un résumé des résultats
    Write-Host "`nRésumé des résultats :" -ForegroundColor Cyan
    Write-Host "Tests exécutés : $($results.TotalCount)"
    Write-Host "Tests réussis : $($results.PassedCount)" -ForegroundColor Green
    Write-Host "Tests échoués : $($results.FailedCount)" -ForegroundColor Red
    Write-Host "Tests ignorés : $($results.SkippedCount)" -ForegroundColor Yellow
    
    # Retourner les résultats
    return $results
}
else {
    Write-Error "Le fichier de test simplifié n'a pas été trouvé à l'emplacement : $simplifiedTestPath"
    exit 1
}
