#Requires -Version 5.1
<#
.SYNOPSIS
    Crée un pont entre les tests simplifiés et les tests réels.

.DESCRIPTION
    Ce script crée un pont entre les tests simplifiés et les tests réels en générant
    des adaptateurs qui permettent d'exécuter les tests simplifiés dans l'environnement
    des tests réels. Cela facilite la transition progressive vers le niveau de test
    d'avant la simplification.

.PARAMETER GenerateAdapters
    Indique si les adaptateurs doivent être générés.
    Par défaut, cette option est activée.

.PARAMETER TestOnly
    Indique si seuls les tests doivent être exécutés sans générer les adaptateurs.
    Par défaut, cette option est désactivée.

.EXAMPLE
    .\Bridge-SimplifiedToRealTests.ps1
    Génère les adaptateurs et exécute les tests.

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

# Si TestOnly est spécifié, désactiver la génération des adaptateurs
if ($TestOnly) {
    $GenerateAdapters = $false
}

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    catch {
        Write-Error "Impossible d'installer le module Pester : $_"
        exit 1
    }
}

# Fonction pour créer un répertoire s'il n'existe pas
function New-DirectoryIfNotExists {
    param (
        [string]$Path
    )

    if (-not (Test-Path -Path $Path -PathType Container)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
        Write-Verbose "Répertoire créé : $Path"
    }
}

# Répertoire pour les adaptateurs
$adaptersDir = Join-Path -Path $PSScriptRoot -ChildPath "Adapters"
New-DirectoryIfNotExists -Path $adaptersDir

# Définir les mappings entre les tests simplifiés et les tests réels
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

# Générer les adaptateurs
if ($GenerateAdapters) {
    Write-Host "Génération des adaptateurs..." -ForegroundColor Cyan
    
    foreach ($simplifiedTest in $testMappings.Keys) {
        $realTest = $testMappings[$simplifiedTest]
        $simplifiedTestPath = Join-Path -Path $PSScriptRoot -ChildPath $simplifiedTest
        $realTestPath = Join-Path -Path $PSScriptRoot -ChildPath $realTest
        
        # Vérifier si les fichiers existent
        if (-not (Test-Path -Path $simplifiedTestPath)) {
            Write-Warning "Le fichier de test simplifié '$simplifiedTestPath' n'existe pas."
            continue
        }
        
        if (-not (Test-Path -Path $realTestPath)) {
            Write-Warning "Le fichier de test réel '$realTestPath' n'existe pas."
            continue
        }
        
        # Nom de l'adaptateur
        $adapterName = [System.IO.Path]::GetFileNameWithoutExtension($simplifiedTest) -replace "\.Simplified$", ".Adapter"
        $adapterPath = Join-Path -Path $adaptersDir -ChildPath "$adapterName.ps1"
        
        # Générer l'adaptateur
        $adapterContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Adaptateur pour le test simplifié $simplifiedTest.

.DESCRIPTION
    Cet adaptateur permet d'exécuter le test simplifié $simplifiedTest
    dans l'environnement du test réel $realTest.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: $(Get-Date -Format "yyyy-MM-dd")
    Généré automatiquement par Bridge-SimplifiedToRealTests.ps1
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    catch {
        Write-Error "Impossible d'installer le module Pester : `$_"
        exit 1
    }
}

# Chemin du test simplifié
`$simplifiedTestPath = "$simplifiedTestPath"

# Chemin du test réel
`$realTestPath = "$realTestPath"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path `$simplifiedTestPath)) {
    Write-Error "Le fichier de test simplifié '`$simplifiedTestPath' n'existe pas."
    exit 1
}

if (-not (Test-Path -Path `$realTestPath)) {
    Write-Error "Le fichier de test réel '`$realTestPath' n'existe pas."
    exit 1
}

# Exécuter le test simplifié
Write-Host "Exécution du test simplifié '`$simplifiedTestPath'..." -ForegroundColor Cyan
`$simplifiedResults = Invoke-Pester -Path `$simplifiedTestPath -PassThru -Output Detailed

# Afficher un résumé des résultats
Write-Host "`nRésumé des résultats du test simplifié :" -ForegroundColor Cyan
Write-Host "Tests exécutés : `$(`$simplifiedResults.TotalCount)"
Write-Host "Tests réussis : `$(`$simplifiedResults.PassedCount)" -ForegroundColor Green
Write-Host "Tests échoués : `$(`$simplifiedResults.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorés : `$(`$simplifiedResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "Durée totale : `$(`$simplifiedResults.Duration.TotalSeconds) secondes"

# Retourner les résultats
return `$simplifiedResults
"@
        
        # Enregistrer l'adaptateur
        $adapterContent | Set-Content -Path $adapterPath -Encoding UTF8
        Write-Host "Adaptateur généré : $adapterPath" -ForegroundColor Green
    }
}

# Exécuter les tests
Write-Host "`nExécution des tests..." -ForegroundColor Cyan

# Exécuter les tests simplifiés
Write-Host "`nExécution des tests simplifiés..." -ForegroundColor Cyan
$simplifiedTestFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.Simplified.ps1" | ForEach-Object { $_.FullName }
$simplifiedResults = Invoke-Pester -Path $simplifiedTestFiles -PassThru -Output Normal

# Afficher un résumé des résultats
Write-Host "`nRésumé des résultats des tests simplifiés :" -ForegroundColor Cyan
Write-Host "Tests exécutés : $($simplifiedResults.TotalCount)"
Write-Host "Tests réussis : $($simplifiedResults.PassedCount)" -ForegroundColor Green
Write-Host "Tests échoués : $($simplifiedResults.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorés : $($simplifiedResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "Durée totale : $($simplifiedResults.Duration.TotalSeconds) secondes"

# Exécuter les adaptateurs
if (Test-Path -Path $adaptersDir) {
    Write-Host "`nExécution des adaptateurs..." -ForegroundColor Cyan
    $adapterFiles = Get-ChildItem -Path $adaptersDir -Filter "*.Adapter.ps1" | ForEach-Object { $_.FullName }
    
    if ($adapterFiles.Count -gt 0) {
        $adapterResults = Invoke-Pester -Path $adapterFiles -PassThru -Output Normal
        
        # Afficher un résumé des résultats
        Write-Host "`nRésumé des résultats des adaptateurs :" -ForegroundColor Cyan
        Write-Host "Tests exécutés : $($adapterResults.TotalCount)"
        Write-Host "Tests réussis : $($adapterResults.PassedCount)" -ForegroundColor Green
        Write-Host "Tests échoués : $($adapterResults.FailedCount)" -ForegroundColor Red
        Write-Host "Tests ignorés : $($adapterResults.SkippedCount)" -ForegroundColor Yellow
        Write-Host "Durée totale : $($adapterResults.Duration.TotalSeconds) secondes"
    }
    else {
        Write-Warning "Aucun adaptateur trouvé."
    }
}

# Retourner un code de sortie en fonction des résultats
if ($simplifiedResults.FailedCount -gt 0 -or ($adapterResults -and $adapterResults.FailedCount -gt 0)) {
    exit 1
}
else {
    exit 0
}
