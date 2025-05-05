# Test d'intÃ©gration pour le systÃ¨me complet
# Ce test vÃ©rifie que toutes les fonctionnalitÃ©s du module fonctionnent correctement ensemble

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$moduleFile = Join-Path -Path $modulePath -ChildPath "ModuleDependencyAnalyzer-Fixed.psm1"

try {
    # Importer le module
    Import-Module -Name $moduleFile -Force -ErrorAction Stop
    Write-Host "Module importÃ© avec succÃ¨s" -ForegroundColor Green

    # CrÃ©er un rÃ©pertoire temporaire pour les tests
    $testDir = Join-Path -Path $env:TEMP -ChildPath "IntegrationTest"
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null

    # CrÃ©er une structure de module de test
    $moduleDir = Join-Path -Path $testDir -ChildPath "TestModule"
    New-Item -Path $moduleDir -ItemType Directory -Force | Out-Null

    # CrÃ©er un fichier manifeste de test
    $manifestContent = @"
@{
    ModuleVersion = '1.0.0'
    GUID = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
    Author = 'Test Author'
    Description = 'Test Module'
    RootModule = 'TestModule.psm1'
    RequiredModules = @(
        'Module1',
        @{
            ModuleName = 'Module2'
            ModuleVersion = '2.0.0'
        }
    )
    NestedModules = @(
        'NestedModule1.psm1',
        @{
            ModuleName = 'NestedModule2'
            ModuleVersion = '2.0.0'
        }
    )
}
"@

    $manifestPath = Join-Path -Path $moduleDir -ChildPath "TestModule.psd1"
    Set-Content -Path $manifestPath -Value $manifestContent

    # CrÃ©er un fichier de module principal
    $moduleContent = @"
# Module principal
function Get-TestData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Path
    )
    
    # Utilisation de fonctions internes
    `$data = Get-InternalData -Path `$Path
    
    # Utilisation de fonctions externes
    Get-ChildItem -Path `$Path
    Get-Process | Where-Object { `$_.Name -eq "explorer" }
    
    return `$data
}

function Get-InternalData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Path
    )
    
    # Utilisation de fonctions externes
    `$date = Get-Date
    
    return "Data from `$Path at `$date"
}

# Exporter les fonctions
Export-ModuleMember -Function Get-TestData
"@

    $moduleFilePath = Join-Path -Path $moduleDir -ChildPath "TestModule.psm1"
    Set-Content -Path $moduleFilePath -Value $moduleContent

    # CrÃ©er un module imbriquÃ©
    $nestedModuleContent = @"
# Module imbriquÃ©
function Get-NestedData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Path
    )
    
    # Utilisation de fonctions externes
    `$content = Get-Content -Path `$Path
    
    return `$content
}

# Exporter les fonctions
Export-ModuleMember -Function Get-NestedData
"@

    $nestedModulePath = Join-Path -Path $moduleDir -ChildPath "NestedModule1.psm1"
    Set-Content -Path $nestedModulePath -Value $nestedModuleContent

    # CrÃ©er un script qui utilise le module
    $scriptContent = @"
# Script qui utilise le module
Import-Module .\TestModule.psd1

# Utilisation des fonctions du module
`$data = Get-TestData -Path "."
Write-Output `$data

# Utilisation de fonctions externes
Get-Date
Get-ChildItem
"@

    $scriptPath = Join-Path -Path $moduleDir -ChildPath "TestScript.ps1"
    Set-Content -Path $scriptPath -Value $scriptContent

    # Test 1: Analyser le manifeste du module
    Write-Host "`nTest 1: Analyser le manifeste du module" -ForegroundColor Cyan
    $manifestDependencies = Get-ModuleDependenciesFromManifest -ManifestPath $manifestPath
    
    Write-Host "DÃ©pendances du manifeste:"
    Write-Host "  Nombre de dÃ©pendances: $($manifestDependencies.Count)"
    $manifestDependencies | ForEach-Object {
        Write-Host "  - $($_.Name) (Type: $($_.Type))"
    }
    
    # Test 2: Analyser le code du module
    Write-Host "`nTest 2: Analyser le code du module" -ForegroundColor Cyan
    $codeDependencies = Get-ModuleDependenciesFromCode -ModulePath $moduleFilePath
    
    Write-Host "DÃ©pendances du code:"
    Write-Host "  Nombre de dÃ©pendances: $($codeDependencies.Count)"
    $codeDependencies | ForEach-Object {
        Write-Host "  - $($_.Name) (Type: $($_.Type))"
    }
    
    # Test 3: Analyser les fonctions externes
    Write-Host "`nTest 3: Analyser les fonctions externes" -ForegroundColor Cyan
    $externalFunctionDependencies = Get-ExternalFunctionDependencies -ModulePath $moduleFilePath
    
    Write-Host "DÃ©pendances des fonctions externes:"
    Write-Host "  Nombre de dÃ©pendances: $($externalFunctionDependencies.Count)"
    $externalFunctionDependencies | ForEach-Object {
        Write-Host "  - $($_.FunctionName) from $($_.Name) (Type: $($_.Type))"
    }
    
    # Test 4: RÃ©soudre le chemin d'une fonction
    Write-Host "`nTest 4: RÃ©soudre le chemin d'une fonction" -ForegroundColor Cyan
    $functionPath = Resolve-ExternalFunctionPath -FunctionName "Get-ChildItem"
    
    Write-Host "Chemin de la fonction Get-ChildItem:"
    Write-Host "  Fonction: $($functionPath.FunctionName)"
    Write-Host "  Module: $($functionPath.ModuleName)"
    Write-Host "  Chemin du module: $($functionPath.ModulePath)"
    
    # Test 5: Analyser le module complet
    Write-Host "`nTest 5: Analyser le module complet" -ForegroundColor Cyan
    $completeAnalysis = Get-CompleteDependencyAnalysis -ModulePath $moduleDir -Recurse -IncludeDetails
    
    Write-Host "Analyse complÃ¨te du module:"
    Write-Host "  Module Path: $($completeAnalysis.ModulePath)"
    Write-Host "  Analysis Date: $($completeAnalysis.AnalysisDate)"
    Write-Host "  Total Dependencies: $($completeAnalysis.Summary.TotalDependencies)"
    Write-Host "  Manifest Dependencies: $($completeAnalysis.Summary.ManifestDependenciesCount)"
    Write-Host "  Code Dependencies: $($completeAnalysis.Summary.CodeDependenciesCount)"
    Write-Host "  External Function Dependencies: $($completeAnalysis.Summary.ExternalFunctionDependenciesCount)"
    Write-Host "  Unique Modules: $($completeAnalysis.Summary.UniqueModules)"
    
    # Test 6: Convertir l'analyse au format ModuleDependencyDetector
    Write-Host "`nTest 6: Convertir l'analyse au format ModuleDependencyDetector" -ForegroundColor Cyan
    $mddFormat = ConvertTo-ModuleDependencyDetectorFormat -DependencyAnalysis $completeAnalysis -Format "Detailed"
    
    Write-Host "Format ModuleDependencyDetector:"
    Write-Host "  Module Name: $($mddFormat.ModuleName)"
    Write-Host "  Module Path: $($mddFormat.ModulePath)"
    Write-Host "  Dependencies Count: $($mddFormat.Dependencies.Count)"
    
    # Test 7: Utiliser l'interface unifiÃ©e
    Write-Host "`nTest 7: Utiliser l'interface unifiÃ©e" -ForegroundColor Cyan
    $unifiedResult = Get-ModuleDependencies -Path $moduleDir -Recurse -IncludeDetails
    
    Write-Host "RÃ©sultat de l'interface unifiÃ©e:"
    Write-Host "  Module Path: $($unifiedResult.ModulePath)"
    Write-Host "  Module Name: $($unifiedResult.ModuleName)"
    Write-Host "  Total Dependencies: $($unifiedResult.Summary.TotalDependencies)"
    Write-Host "  Manifest Dependencies: $($unifiedResult.Summary.ManifestDependenciesCount)"
    Write-Host "  Code Dependencies: $($unifiedResult.Summary.CodeDependenciesCount)"
    Write-Host "  External Function Dependencies: $($unifiedResult.Summary.ExternalFunctionDependenciesCount)"
    Write-Host "  Unique Modules: $($unifiedResult.Summary.UniqueModules)"
    
    # Test 8: Exporter un rapport
    Write-Host "`nTest 8: Exporter un rapport" -ForegroundColor Cyan
    $reportPath = Join-Path -Path $testDir -ChildPath "DependencyReport.html"
    $exportResult = Export-DependencyReport -ModulePath $moduleDir -OutputPath $reportPath -Format "HTML" -IncludeDetails -Recurse
    
    if ($exportResult -and (Test-Path -Path $reportPath)) {
        Write-Host "Rapport exportÃ© avec succÃ¨s: $reportPath" -ForegroundColor Green
    } else {
        Write-Host "Erreur: Ã‰chec de l'exportation du rapport" -ForegroundColor Red
    }
    
    # Test 9: Utiliser le systÃ¨me de cache
    Write-Host "`nTest 9: Utiliser le systÃ¨me de cache" -ForegroundColor Cyan
    
    # Vider le cache
    Clear-DependencyCache
    
    # VÃ©rifier que le cache est vide
    $initialCache = Get-DependencyCache
    if ($initialCache.Manifests.Count -eq 0 -and 
        $initialCache.Code.Count -eq 0 -and 
        $initialCache.ExternalFunctions.Count -eq 0 -and 
        $initialCache.FunctionPaths.Count -eq 0) {
        Write-Host "Cache initialement vide - OK" -ForegroundColor Green
    } else {
        Write-Host "Erreur: Le cache n'est pas vide initialement" -ForegroundColor Red
    }
    
    # Activer les messages de dÃ©bogage
    $VerbosePreference = "Continue"
    
    # Analyser les dÃ©pendances
    $result1 = Get-ModuleDependenciesFromCode -ModulePath $moduleFilePath
    $result2 = Get-ExternalFunctionDependencies -ModulePath $moduleFilePath
    $result3 = Resolve-ExternalFunctionPath -FunctionName "Get-Date"
    
    # DÃ©sactiver les messages de dÃ©bogage
    $VerbosePreference = "SilentlyContinue"
    
    # VÃ©rifier que le cache est rempli
    $cacheAfterAnalysis = Get-DependencyCache
    
    if ($cacheAfterAnalysis.Code.Count -gt 0 -and 
        $cacheAfterAnalysis.ExternalFunctions.Count -gt 0 -and 
        $cacheAfterAnalysis.FunctionPaths.Count -gt 0) {
        Write-Host "Cache rempli aprÃ¨s analyse - OK" -ForegroundColor Green
    } else {
        Write-Host "Erreur: Le cache n'est pas rempli aprÃ¨s analyse" -ForegroundColor Red
    }
    
    # Test 10: Utiliser Invoke-ModuleDependencyDetector
    Write-Host "`nTest 10: Utiliser Invoke-ModuleDependencyDetector" -ForegroundColor Cyan
    $mddOutputPath = Join-Path -Path $testDir -ChildPath "MddReport.html"
    $mddResult = Invoke-ModuleDependencyDetector -ModulePath $moduleDir -Format "Detailed" -OutputPath $mddOutputPath -OutputFormat "HTML" -Recurse
    
    Write-Host "RÃ©sultat de Invoke-ModuleDependencyDetector:"
    Write-Host "  Module Name: $($mddResult.ModuleName)"
    Write-Host "  Module Path: $($mddResult.ModulePath)"
    Write-Host "  Dependencies Count: $($mddResult.Dependencies.Count)"
    
    if (Test-Path -Path $mddOutputPath) {
        Write-Host "Rapport MDD exportÃ© avec succÃ¨s: $mddOutputPath" -ForegroundColor Green
    } else {
        Write-Host "Erreur: Ã‰chec de l'exportation du rapport MDD" -ForegroundColor Red
    }

    # Nettoyer
    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Module -Name "ModuleDependencyAnalyzer-Fixed" -Force -ErrorAction SilentlyContinue

    # Tout est OK
    Write-Host "`nTest d'intÃ©gration terminÃ© avec succÃ¨s !" -ForegroundColor Green
    exit 0
} catch {
    # Une erreur s'est produite
    Write-Host "Erreur : $_" -ForegroundColor Red
    exit 1
}
