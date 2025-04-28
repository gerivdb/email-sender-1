#Requires -Version 5.1
<#
.SYNOPSIS
    GÃ©nÃ¨re des adaptateurs pour les tests simplifiÃ©s.

.DESCRIPTION
    Ce script gÃ©nÃ¨re automatiquement des adaptateurs pour tous les tests simplifiÃ©s
    afin de faciliter leur intÃ©gration avec les tests rÃ©els.

.PARAMETER Force
    Force la rÃ©gÃ©nÃ©ration des adaptateurs existants.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Mappings entre les tests simplifiÃ©s et les fonctions rÃ©elles
$functionMappings = @{
    "Test-FileFormat" = "Detect-FileFormat"
    "Test-DetectedFileFormat" = "Detect-FileFormat"
    "Test-FileFormatWithConfirmation" = "Detect-FileFormatWithConfirmation"
    "Handle-AmbiguousFormats" = "Handle-AmbiguousFormats"
    "Show-FormatDetectionResults" = "Show-FormatDetectionResults"
    "Convert-FileFormat" = "Convert-FileFormat"
    "Confirm-FormatDetection" = "Confirm-FormatDetection"
}

# CrÃ©er le rÃ©pertoire des adaptateurs s'il n'existe pas
$adaptersDir = Join-Path -Path $PSScriptRoot -ChildPath "Adapters"
if (-not (Test-Path -Path $adaptersDir -PathType Container)) {
    New-Item -Path $adaptersDir -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire des adaptateurs crÃ©Ã© : $adaptersDir" -ForegroundColor Green
}

# Obtenir tous les fichiers de test simplifiÃ©s
$simplifiedTests = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.Simplified.ps1"

foreach ($test in $simplifiedTests) {
    # Extraire le nom de la fonction testÃ©e
    $functionName = $test.BaseName -replace "\.Tests\.Simplified$", ""
    
    # VÃ©rifier si un mapping existe pour cette fonction
    if ($functionMappings.ContainsKey($functionName)) {
        $realFunctionName = $functionMappings[$functionName]
        
        # Chemin de l'adaptateur
        $adapterPath = Join-Path -Path $adaptersDir -ChildPath "$functionName.Adapter.ps1"
        
        # VÃ©rifier si l'adaptateur existe dÃ©jÃ 
        if ((Test-Path -Path $adapterPath) -and -not $Force) {
            Write-Host "L'adaptateur pour $functionName existe dÃ©jÃ . Utilisez -Force pour le rÃ©gÃ©nÃ©rer." -ForegroundColor Yellow
            continue
        }
        
        # GÃ©nÃ©rer le contenu de l'adaptateur
        $adapterContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Adaptateur pour intÃ©grer $functionName.Tests.Simplified.ps1 avec les tests rÃ©els.

.DESCRIPTION
    Cet adaptateur permet d'exÃ©cuter les tests simplifiÃ©s dans l'environnement des tests rÃ©els
    en faisant le pont entre les fonctions simplifiÃ©es et les fonctions rÃ©elles.

.NOTES
    GÃ©nÃ©rÃ© automatiquement par Generate-TestAdapters.ps1
    Date de gÃ©nÃ©ration : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
#>

# Importer les fonctions rÃ©elles du module
`$moduleRoot = Split-Path -Parent (Split-Path -Parent `$PSScriptRoot)
`$modulePath = Join-Path -Path `$moduleRoot -ChildPath "Format-Converters.psm1"

if (Test-Path -Path `$modulePath) {
    Import-Module `$modulePath -Force
}
else {
    Write-Error "Le module Format-Converters n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement : `$modulePath"
    exit 1
}

# CrÃ©er un adaptateur pour la fonction $functionName
function $functionName {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = `$true, ValueFromPipelineByPropertyName = `$true)]
        [Parameter(Position = 0)]
        [object[]]`$InputObject,
        
        [Parameter(ValueFromRemainingArguments = `$true)]
        [object[]]`$RemainingArgs
    )
    
    process {
        # VÃ©rifier si la fonction rÃ©elle existe
        if (Get-Command -Name "$realFunctionName" -ErrorAction SilentlyContinue) {
            # Appeler la fonction rÃ©elle avec les paramÃ¨tres adaptÃ©s
            `$result = & "$realFunctionName" @PSBoundParameters
            
            # Retourner le rÃ©sultat
            return `$result
        }
        else {
            Write-Error "La fonction $realFunctionName n'existe pas dans le module."
            return `$null
        }
    }
}

# Exporter la fonction adaptÃ©e
Export-ModuleMember -Function $functionName

# ExÃ©cuter les tests simplifiÃ©s avec l'adaptateur
`$simplifiedTestPath = Join-Path -Path `$PSScriptRoot -ChildPath "..\\$($test.Name)"

if (Test-Path -Path `$simplifiedTestPath) {
    Write-Host "ExÃ©cution des tests simplifiÃ©s avec l'adaptateur..." -ForegroundColor Cyan
    
    # CrÃ©er un contexte d'exÃ©cution isolÃ©
    `$scriptBlock = {
        param(`$TestPath, `$AdapterPath)
        
        # Importer l'adaptateur
        . `$AdapterPath
        
        # ExÃ©cuter les tests
        Invoke-Pester -Path `$TestPath -PassThru
    }
    
    # ExÃ©cuter les tests dans un nouveau contexte
    `$results = & `$scriptBlock `$simplifiedTestPath `$PSCommandPath
    
    # Afficher un rÃ©sumÃ© des rÃ©sultats
    Write-Host "`nRÃ©sumÃ© des rÃ©sultats :" -ForegroundColor Cyan
    Write-Host "Tests exÃ©cutÃ©s : `$(`$results.TotalCount)"
    Write-Host "Tests rÃ©ussis : `$(`$results.PassedCount)" -ForegroundColor Green
    Write-Host "Tests Ã©chouÃ©s : `$(`$results.FailedCount)" -ForegroundColor Red
    Write-Host "Tests ignorÃ©s : `$(`$results.SkippedCount)" -ForegroundColor Yellow
    
    # Retourner les rÃ©sultats
    return `$results
}
else {
    Write-Error "Le fichier de test simplifiÃ© n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement : `$simplifiedTestPath"
    exit 1
}
"@
        
        # Enregistrer l'adaptateur
        $adapterContent | Set-Content -Path $adapterPath -Encoding UTF8
        Write-Host "Adaptateur gÃ©nÃ©rÃ© pour $functionName : $adapterPath" -ForegroundColor Green
    }
    else {
        Write-Warning "Aucun mapping trouvÃ© pour la fonction $functionName. Adaptateur non gÃ©nÃ©rÃ©."
    }
}

Write-Host "`nGÃ©nÃ©ration des adaptateurs terminÃ©e." -ForegroundColor Cyan
Write-Host "Pour exÃ©cuter les tests avec les adaptateurs, utilisez :" -ForegroundColor Cyan
Write-Host "Invoke-Pester -Path '$adaptersDir'" -ForegroundColor Yellow
