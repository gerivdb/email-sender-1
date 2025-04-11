#Requires -Version 5.1
<#
.SYNOPSIS
    Génère des adaptateurs pour les tests simplifiés.

.DESCRIPTION
    Ce script génère automatiquement des adaptateurs pour tous les tests simplifiés
    afin de faciliter leur intégration avec les tests réels.

.PARAMETER Force
    Force la régénération des adaptateurs existants.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Mappings entre les tests simplifiés et les fonctions réelles
$functionMappings = @{
    "Test-FileFormat" = "Detect-FileFormat"
    "Test-DetectedFileFormat" = "Detect-FileFormat"
    "Test-FileFormatWithConfirmation" = "Detect-FileFormatWithConfirmation"
    "Handle-AmbiguousFormats" = "Handle-AmbiguousFormats"
    "Show-FormatDetectionResults" = "Show-FormatDetectionResults"
    "Convert-FileFormat" = "Convert-FileFormat"
    "Confirm-FormatDetection" = "Confirm-FormatDetection"
}

# Créer le répertoire des adaptateurs s'il n'existe pas
$adaptersDir = Join-Path -Path $PSScriptRoot -ChildPath "Adapters"
if (-not (Test-Path -Path $adaptersDir -PathType Container)) {
    New-Item -Path $adaptersDir -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire des adaptateurs créé : $adaptersDir" -ForegroundColor Green
}

# Obtenir tous les fichiers de test simplifiés
$simplifiedTests = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.Simplified.ps1"

foreach ($test in $simplifiedTests) {
    # Extraire le nom de la fonction testée
    $functionName = $test.BaseName -replace "\.Tests\.Simplified$", ""
    
    # Vérifier si un mapping existe pour cette fonction
    if ($functionMappings.ContainsKey($functionName)) {
        $realFunctionName = $functionMappings[$functionName]
        
        # Chemin de l'adaptateur
        $adapterPath = Join-Path -Path $adaptersDir -ChildPath "$functionName.Adapter.ps1"
        
        # Vérifier si l'adaptateur existe déjà
        if ((Test-Path -Path $adapterPath) -and -not $Force) {
            Write-Host "L'adaptateur pour $functionName existe déjà. Utilisez -Force pour le régénérer." -ForegroundColor Yellow
            continue
        }
        
        # Générer le contenu de l'adaptateur
        $adapterContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Adaptateur pour intégrer $functionName.Tests.Simplified.ps1 avec les tests réels.

.DESCRIPTION
    Cet adaptateur permet d'exécuter les tests simplifiés dans l'environnement des tests réels
    en faisant le pont entre les fonctions simplifiées et les fonctions réelles.

.NOTES
    Généré automatiquement par Generate-TestAdapters.ps1
    Date de génération : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
#>

# Importer les fonctions réelles du module
`$moduleRoot = Split-Path -Parent (Split-Path -Parent `$PSScriptRoot)
`$modulePath = Join-Path -Path `$moduleRoot -ChildPath "Format-Converters.psm1"

if (Test-Path -Path `$modulePath) {
    Import-Module `$modulePath -Force
}
else {
    Write-Error "Le module Format-Converters n'a pas été trouvé à l'emplacement : `$modulePath"
    exit 1
}

# Créer un adaptateur pour la fonction $functionName
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
        # Vérifier si la fonction réelle existe
        if (Get-Command -Name "$realFunctionName" -ErrorAction SilentlyContinue) {
            # Appeler la fonction réelle avec les paramètres adaptés
            `$result = & "$realFunctionName" @PSBoundParameters
            
            # Retourner le résultat
            return `$result
        }
        else {
            Write-Error "La fonction $realFunctionName n'existe pas dans le module."
            return `$null
        }
    }
}

# Exporter la fonction adaptée
Export-ModuleMember -Function $functionName

# Exécuter les tests simplifiés avec l'adaptateur
`$simplifiedTestPath = Join-Path -Path `$PSScriptRoot -ChildPath "..\\$($test.Name)"

if (Test-Path -Path `$simplifiedTestPath) {
    Write-Host "Exécution des tests simplifiés avec l'adaptateur..." -ForegroundColor Cyan
    
    # Créer un contexte d'exécution isolé
    `$scriptBlock = {
        param(`$TestPath, `$AdapterPath)
        
        # Importer l'adaptateur
        . `$AdapterPath
        
        # Exécuter les tests
        Invoke-Pester -Path `$TestPath -PassThru
    }
    
    # Exécuter les tests dans un nouveau contexte
    `$results = & `$scriptBlock `$simplifiedTestPath `$PSCommandPath
    
    # Afficher un résumé des résultats
    Write-Host "`nRésumé des résultats :" -ForegroundColor Cyan
    Write-Host "Tests exécutés : `$(`$results.TotalCount)"
    Write-Host "Tests réussis : `$(`$results.PassedCount)" -ForegroundColor Green
    Write-Host "Tests échoués : `$(`$results.FailedCount)" -ForegroundColor Red
    Write-Host "Tests ignorés : `$(`$results.SkippedCount)" -ForegroundColor Yellow
    
    # Retourner les résultats
    return `$results
}
else {
    Write-Error "Le fichier de test simplifié n'a pas été trouvé à l'emplacement : `$simplifiedTestPath"
    exit 1
}
"@
        
        # Enregistrer l'adaptateur
        $adapterContent | Set-Content -Path $adapterPath -Encoding UTF8
        Write-Host "Adaptateur généré pour $functionName : $adapterPath" -ForegroundColor Green
    }
    else {
        Write-Warning "Aucun mapping trouvé pour la fonction $functionName. Adaptateur non généré."
    }
}

Write-Host "`nGénération des adaptateurs terminée." -ForegroundColor Cyan
Write-Host "Pour exécuter les tests avec les adaptateurs, utilisez :" -ForegroundColor Cyan
Write-Host "Invoke-Pester -Path '$adaptersDir'" -ForegroundColor Yellow
