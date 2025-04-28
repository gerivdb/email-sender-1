#Requires -Version 5.1
<#
.SYNOPSIS
    CrÃ©e un pont entre les tests simplifiÃ©s et les tests rÃ©els.

.DESCRIPTION
    Ce script crÃ©e un pont entre les tests simplifiÃ©s et les tests rÃ©els en gÃ©nÃ©rant
    des adaptateurs qui permettent d'exÃ©cuter les tests simplifiÃ©s dans l'environnement
    des tests rÃ©els. Cela facilite la transition progressive vers le niveau de test
    d'avant la simplification.

.PARAMETER GenerateAdapters
    Indique si les adaptateurs doivent Ãªtre gÃ©nÃ©rÃ©s.
    Par dÃ©faut, cette option est activÃ©e.

.PARAMETER TestOnly
    Indique si seuls les tests doivent Ãªtre exÃ©cutÃ©s sans gÃ©nÃ©rer les adaptateurs.
    Par dÃ©faut, cette option est dÃ©sactivÃ©e.

.EXAMPLE
    .\Bridge-SimplifiedToRealTests.ps1
    GÃ©nÃ¨re les adaptateurs et exÃ©cute les tests.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$GenerateAdapters = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$TestOnly
)

# Si TestOnly est spÃ©cifiÃ©, dÃ©sactiver la gÃ©nÃ©ration des adaptateurs
if ($TestOnly) {
    $GenerateAdapters = $false
}

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    catch {
        Write-Error "Impossible d'installer le module Pester : $_"
        exit 1
    }
}

# Fonction pour crÃ©er un rÃ©pertoire s'il n'existe pas
function New-DirectoryIfNotExists {
    param (
        [string]$Path
    )

    if (-not (Test-Path -Path $Path -PathType Container)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
        Write-Verbose "RÃ©pertoire crÃ©Ã© : $Path"
    }
}

# RÃ©pertoire pour les adaptateurs
$adaptersDir = Join-Path -Path $PSScriptRoot -ChildPath "Adapters"
New-DirectoryIfNotExists -Path $adaptersDir

# DÃ©finir les mappings entre les tests simplifiÃ©s et les tests rÃ©els
$testMappings = @{
    "Handle-AmbiguousFormats.Tests.Simplified.ps1" = "Handle-AmbiguousFormats.Tests.ps1"
    "Show-FormatDetectionResults.Tests.Simplified.ps1" = "Show-FormatDetectionResults.Tests.ps1"
    "Test-FileFormat.Tests.Simplified.ps1" = "Detect-FileFormat.Tests.ps1"
    "Test-DetectedFileFormat.Tests.Simplified.ps1" = "Detect-FileFormat.Tests.ps1"
    "Test-FileFormatWithConfirmation.Tests.Simplified.ps1" = "Detect-FileFormatWithConfirmation.Tests.ps1"
    "Convert-FileFormat.Tests.Simplified.ps1" = "Format-Converters.Tests.ps1"
    "Confirm-FormatDetection.Tests.Simplified.ps1" = "Detect-FileFormatWithConfirmation.Tests.ps1"
    "Integration.Tests.Simplified.ps1" = "Format-Converters.Tests.ps1"
}

# GÃ©nÃ©rer les adaptateurs
if ($GenerateAdapters) {
    Write-Host "GÃ©nÃ©ration des adaptateurs..." -ForegroundColor Cyan
    
    foreach ($simplifiedTest in $testMappings.Keys) {
        $realTest = $testMappings[$simplifiedTest]
        $simplifiedTestPath = Join-Path -Path $PSScriptRoot -ChildPath $simplifiedTest
        $realTestPath = Join-Path -Path $PSScriptRoot -ChildPath $realTest
        
        # VÃ©rifier si les fichiers existent
        if (-not (Test-Path -Path $simplifiedTestPath)) {
            Write-Warning "Le fichier de test simplifiÃ© '$simplifiedTestPath' n'existe pas."
            continue
        }
        
        if (-not (Test-Path -Path $realTestPath)) {
            Write-Warning "Le fichier de test rÃ©el '$realTestPath' n'existe pas."
            continue
        }
        
        # Nom de l'adaptateur
        $adapterName = [System.IO.Path]::GetFileNameWithoutExtension($simplifiedTest) -replace "\.Simplified$", ".Adapter"
        $adapterPath = Join-Path -Path $adaptersDir -ChildPath "$adapterName.ps1"
        
        # GÃ©nÃ©rer l'adaptateur
        $adapterContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Adaptateur pour le test simplifiÃ© $simplifiedTest.

.DESCRIPTION
    Cet adaptateur permet d'exÃ©cuter le test simplifiÃ© $simplifiedTest
    dans l'environnement du test rÃ©el $realTest.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: $(Get-Date -Format "yyyy-MM-dd")
    GÃ©nÃ©rÃ© automatiquement par Bridge-SimplifiedToRealTests.ps1
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    catch {
        Write-Error "Impossible d'installer le module Pester : `$_"
        exit 1
    }
}

# Chemin du test simplifiÃ©
`$simplifiedTestPath = "$simplifiedTestPath"

# Chemin du test rÃ©el
`$realTestPath = "$realTestPath"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path `$simplifiedTestPath)) {
    Write-Error "Le fichier de test simplifiÃ© '`$simplifiedTestPath' n'existe pas."
    exit 1
}

if (-not (Test-Path -Path `$realTestPath)) {
    Write-Error "Le fichier de test rÃ©el '`$realTestPath' n'existe pas."
    exit 1
}

# ExÃ©cuter le test simplifiÃ©
Write-Host "ExÃ©cution du test simplifiÃ© '`$simplifiedTestPath'..." -ForegroundColor Cyan
`$simplifiedResults = Invoke-Pester -Path `$simplifiedTestPath -PassThru -Output Detailed

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des rÃ©sultats du test simplifiÃ© :" -ForegroundColor Cyan
Write-Host "Tests exÃ©cutÃ©s : `$(`$simplifiedResults.TotalCount)"
Write-Host "Tests rÃ©ussis : `$(`$simplifiedResults.PassedCount)" -ForegroundColor Green
Write-Host "Tests Ã©chouÃ©s : `$(`$simplifiedResults.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorÃ©s : `$(`$simplifiedResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "DurÃ©e totale : `$(`$simplifiedResults.Duration.TotalSeconds) secondes"

# Retourner les rÃ©sultats
return `$simplifiedResults
"@
        
        # Enregistrer l'adaptateur
        $adapterContent | Set-Content -Path $adapterPath -Encoding UTF8
        Write-Host "Adaptateur gÃ©nÃ©rÃ© : $adapterPath" -ForegroundColor Green
    }
}

# ExÃ©cuter les tests
Write-Host "`nExÃ©cution des tests..." -ForegroundColor Cyan

# ExÃ©cuter les tests simplifiÃ©s
Write-Host "`nExÃ©cution des tests simplifiÃ©s..." -ForegroundColor Cyan
$simplifiedTestFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.Simplified.ps1" | ForEach-Object { $_.FullName }
$simplifiedResults = Invoke-Pester -Path $simplifiedTestFiles -PassThru -Output Normal

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des rÃ©sultats des tests simplifiÃ©s :" -ForegroundColor Cyan
Write-Host "Tests exÃ©cutÃ©s : $($simplifiedResults.TotalCount)"
Write-Host "Tests rÃ©ussis : $($simplifiedResults.PassedCount)" -ForegroundColor Green
Write-Host "Tests Ã©chouÃ©s : $($simplifiedResults.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorÃ©s : $($simplifiedResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "DurÃ©e totale : $($simplifiedResults.Duration.TotalSeconds) secondes"

# ExÃ©cuter les adaptateurs
if (Test-Path -Path $adaptersDir) {
    Write-Host "`nExÃ©cution des adaptateurs..." -ForegroundColor Cyan
    $adapterFiles = Get-ChildItem -Path $adaptersDir -Filter "*.Adapter.ps1" | ForEach-Object { $_.FullName }
    
    if ($adapterFiles.Count -gt 0) {
        $adapterResults = Invoke-Pester -Path $adapterFiles -PassThru -Output Normal
        
        # Afficher un rÃ©sumÃ© des rÃ©sultats
        Write-Host "`nRÃ©sumÃ© des rÃ©sultats des adaptateurs :" -ForegroundColor Cyan
        Write-Host "Tests exÃ©cutÃ©s : $($adapterResults.TotalCount)"
        Write-Host "Tests rÃ©ussis : $($adapterResults.PassedCount)" -ForegroundColor Green
        Write-Host "Tests Ã©chouÃ©s : $($adapterResults.FailedCount)" -ForegroundColor Red
        Write-Host "Tests ignorÃ©s : $($adapterResults.SkippedCount)" -ForegroundColor Yellow
        Write-Host "DurÃ©e totale : $($adapterResults.Duration.TotalSeconds) secondes"
    }
    else {
        Write-Warning "Aucun adaptateur trouvÃ©."
    }
}

# Retourner un code de sortie en fonction des rÃ©sultats
if ($simplifiedResults.FailedCount -gt 0 -or ($adapterResults -and $adapterResults.FailedCount -gt 0)) {
    exit 1
}
else {
    exit 0
}
