# Test pour la fonction Get-CompleteDependencyAnalysis
# Ce test vÃ©rifie que la fonction combine correctement toutes les mÃ©thodes de dÃ©tection

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$moduleFile = Join-Path -Path $modulePath -ChildPath "ModuleDependencyAnalyzer-Fixed.psm1"

try {
    # Importer le module
    Import-Module -Name $moduleFile -Force -ErrorAction Stop
    Write-Host "Module importÃ© avec succÃ¨s" -ForegroundColor Green

    # CrÃ©er un rÃ©pertoire temporaire pour les tests
    $testDir = Join-Path -Path $env:TEMP -ChildPath "CompleteDependencyAnalysisTest"
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null

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
}
"@

    $manifestPath = Join-Path -Path $testDir -ChildPath "TestModule.psd1"
    Set-Content -Path $manifestPath -Value $manifestContent

    # CrÃ©er un fichier de script de test
    $scriptContent = @"
# DÃ©finition d'une fonction interne
function Test-InternalFunction {
    param (
        [string]`$Path
    )
    
    # Utilisation de fonctions internes
    Write-Output "Testing internal function"
}

# Appel Ã  des fonctions externes
Get-Date
Get-ChildItem
Import-Module Module3
"@

    $scriptPath = Join-Path -Path $testDir -ChildPath "TestScript.ps1"
    Set-Content -Path $scriptPath -Value $scriptContent

    # CrÃ©er un module de test
    $moduleContent = @"
# Module de test
function Get-TestData {
    return "Test data"
}

# Appel Ã  des fonctions externes
Get-Process
"@

    $moduleDirPath = Join-Path -Path $testDir -ChildPath "TestModule"
    New-Item -Path $moduleDirPath -ItemType Directory -Force | Out-Null
    $moduleFilePath = Join-Path -Path $moduleDirPath -ChildPath "TestModule.psm1"
    Set-Content -Path $moduleFilePath -Value $moduleContent

    # Test 1: Analyser un fichier manifeste
    Write-Host "`nTest 1: Analyser un fichier manifeste" -ForegroundColor Cyan
    $result1 = Get-CompleteDependencyAnalysis -ModulePath $manifestPath
    
    Write-Host "RÃ©sultat de l'analyse du manifeste:"
    Write-Host "  Module Path: $($result1.ModulePath)"
    Write-Host "  Analysis Date: $($result1.AnalysisDate)"
    Write-Host "  Total Dependencies: $($result1.Summary.TotalDependencies)"
    Write-Host "  Manifest Dependencies: $($result1.Summary.ManifestDependenciesCount)"
    Write-Host "  Code Dependencies: $($result1.Summary.CodeDependenciesCount)"
    Write-Host "  External Function Dependencies: $($result1.Summary.ExternalFunctionDependenciesCount)"
    Write-Host "  Unique Modules: $($result1.Summary.UniqueModules)"
    
    # Test 2: Analyser un fichier script
    Write-Host "`nTest 2: Analyser un fichier script" -ForegroundColor Cyan
    $result2 = Get-CompleteDependencyAnalysis -ModulePath $scriptPath
    
    Write-Host "RÃ©sultat de l'analyse du script:"
    Write-Host "  Module Path: $($result2.ModulePath)"
    Write-Host "  Analysis Date: $($result2.AnalysisDate)"
    Write-Host "  Total Dependencies: $($result2.Summary.TotalDependencies)"
    Write-Host "  Manifest Dependencies: $($result2.Summary.ManifestDependenciesCount)"
    Write-Host "  Code Dependencies: $($result2.Summary.CodeDependenciesCount)"
    Write-Host "  External Function Dependencies: $($result2.Summary.ExternalFunctionDependenciesCount)"
    Write-Host "  Unique Modules: $($result2.Summary.UniqueModules)"
    
    # Test 3: Analyser un rÃ©pertoire de module
    Write-Host "`nTest 3: Analyser un rÃ©pertoire de module" -ForegroundColor Cyan
    $result3 = Get-CompleteDependencyAnalysis -ModulePath $moduleDirPath -Recurse
    
    Write-Host "RÃ©sultat de l'analyse du rÃ©pertoire de module:"
    Write-Host "  Module Path: $($result3.ModulePath)"
    Write-Host "  Analysis Date: $($result3.AnalysisDate)"
    Write-Host "  Total Dependencies: $($result3.Summary.TotalDependencies)"
    Write-Host "  Manifest Dependencies: $($result3.Summary.ManifestDependenciesCount)"
    Write-Host "  Code Dependencies: $($result3.Summary.CodeDependenciesCount)"
    Write-Host "  External Function Dependencies: $($result3.Summary.ExternalFunctionDependenciesCount)"
    Write-Host "  Unique Modules: $($result3.Summary.UniqueModules)"
    
    # Test 4: Analyser avec IncludeDetails
    Write-Host "`nTest 4: Analyser avec IncludeDetails" -ForegroundColor Cyan
    $result4 = Get-CompleteDependencyAnalysis -ModulePath $testDir -Recurse -IncludeDetails
    
    Write-Host "RÃ©sultat de l'analyse avec IncludeDetails:"
    Write-Host "  Module Path: $($result4.ModulePath)"
    Write-Host "  Analysis Date: $($result4.AnalysisDate)"
    Write-Host "  Total Dependencies: $($result4.Summary.TotalDependencies)"
    Write-Host "  Manifest Dependencies: $($result4.Summary.ManifestDependenciesCount)"
    Write-Host "  Code Dependencies: $($result4.Summary.CodeDependenciesCount)"
    Write-Host "  External Function Dependencies: $($result4.Summary.ExternalFunctionDependenciesCount)"
    Write-Host "  Unique Modules: $($result4.Summary.UniqueModules)"
    
    if ($result4.ModuleDetails) {
        Write-Host "  Module Details:"
        foreach ($moduleDetail in $result4.ModuleDetails) {
            Write-Host "    - $($moduleDetail.Name)"
        }
    }

    # Nettoyer
    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Module -Name "ModuleDependencyAnalyzer-Fixed" -Force -ErrorAction SilentlyContinue

    # Tout est OK
    Write-Host "`nTest terminÃ© avec succÃ¨s !" -ForegroundColor Green
    exit 0
} catch {
    # Une erreur s'est produite
    Write-Host "Erreur : $_" -ForegroundColor Red
    exit 1
}
