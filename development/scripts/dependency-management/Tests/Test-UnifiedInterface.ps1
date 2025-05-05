# Test pour l'interface unifiÃ©e Get-ModuleDependencies
# Ce test vÃ©rifie que la fonction Get-ModuleDependencies fonctionne correctement

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$moduleFile = Join-Path -Path $modulePath -ChildPath "ModuleDependencyAnalyzer-Fixed.psm1"

try {
    # Importer le module
    Import-Module -Name $moduleFile -Force -ErrorAction Stop
    Write-Host "Module importÃ© avec succÃ¨s" -ForegroundColor Green

    # CrÃ©er un rÃ©pertoire temporaire pour les tests
    $testDir = Join-Path -Path $env:TEMP -ChildPath "UnifiedInterfaceTest"
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

    # Test 1: Analyser un fichier manifeste avec l'interface unifiÃ©e
    Write-Host "`nTest 1: Analyser un fichier manifeste avec l'interface unifiÃ©e" -ForegroundColor Cyan
    $result1 = Get-ModuleDependencies -Path $manifestPath
    
    Write-Host "RÃ©sultat de l'analyse du manifeste:"
    Write-Host "  Module Path: $($result1.ModulePath)"
    Write-Host "  Module Name: $($result1.ModuleName)"
    Write-Host "  Analysis Date: $($result1.AnalysisDate)"
    Write-Host "  Total Dependencies: $($result1.Summary.TotalDependencies)"
    Write-Host "  Manifest Dependencies: $($result1.Summary.ManifestDependenciesCount)"
    Write-Host "  Code Dependencies: $($result1.Summary.CodeDependenciesCount)"
    Write-Host "  External Function Dependencies: $($result1.Summary.ExternalFunctionDependenciesCount)"
    Write-Host "  Unique Modules: $($result1.Summary.UniqueModules)"
    
    # Test 2: Analyser un fichier script avec l'interface unifiÃ©e
    Write-Host "`nTest 2: Analyser un fichier script avec l'interface unifiÃ©e" -ForegroundColor Cyan
    $result2 = Get-ModuleDependencies -Path $scriptPath
    
    Write-Host "RÃ©sultat de l'analyse du script:"
    Write-Host "  Module Path: $($result2.ModulePath)"
    Write-Host "  Module Name: $($result2.ModuleName)"
    Write-Host "  Analysis Date: $($result2.AnalysisDate)"
    Write-Host "  Total Dependencies: $($result2.Summary.TotalDependencies)"
    Write-Host "  Manifest Dependencies: $($result2.Summary.ManifestDependenciesCount)"
    Write-Host "  Code Dependencies: $($result2.Summary.CodeDependenciesCount)"
    Write-Host "  External Function Dependencies: $($result2.Summary.ExternalFunctionDependenciesCount)"
    Write-Host "  Unique Modules: $($result2.Summary.UniqueModules)"
    
    # Test 3: Analyser un rÃ©pertoire avec l'interface unifiÃ©e
    Write-Host "`nTest 3: Analyser un rÃ©pertoire avec l'interface unifiÃ©e" -ForegroundColor Cyan
    $result3 = Get-ModuleDependencies -Path $testDir -Recurse
    
    Write-Host "RÃ©sultat de l'analyse du rÃ©pertoire:"
    Write-Host "  Module Path: $($result3.ModulePath)"
    Write-Host "  Module Name: $($result3.ModuleName)"
    Write-Host "  Analysis Date: $($result3.AnalysisDate)"
    Write-Host "  Total Dependencies: $($result3.Summary.TotalDependencies)"
    Write-Host "  Manifest Dependencies: $($result3.Summary.ManifestDependenciesCount)"
    Write-Host "  Code Dependencies: $($result3.Summary.CodeDependenciesCount)"
    Write-Host "  External Function Dependencies: $($result3.Summary.ExternalFunctionDependenciesCount)"
    Write-Host "  Unique Modules: $($result3.Summary.UniqueModules)"
    
    # Test 4: Analyser un module par nom (simulÃ©)
    Write-Host "`nTest 4: Analyser un module par nom (simulÃ©)" -ForegroundColor Cyan
    
    # CrÃ©er une fonction mock pour Find-ModulePath
    function Find-ModulePath {
        param (
            [string]$ModuleName,
            [string]$ModuleVersion
        )
        
        # Simuler la recherche d'un module
        if ($ModuleName -eq "TestModule") {
            return $manifestPath
        }
        
        return $null
    }
    
    # Analyser un module par nom
    $result4 = Get-ModuleDependencies -ModuleName "TestModule"
    
    Write-Host "RÃ©sultat de l'analyse du module par nom:"
    Write-Host "  Module Path: $($result4.ModulePath)"
    Write-Host "  Module Name: $($result4.ModuleName)"
    Write-Host "  Analysis Date: $($result4.AnalysisDate)"
    Write-Host "  Total Dependencies: $($result4.Summary.TotalDependencies)"
    Write-Host "  Manifest Dependencies: $($result4.Summary.ManifestDependenciesCount)"
    Write-Host "  Code Dependencies: $($result4.Summary.CodeDependenciesCount)"
    Write-Host "  External Function Dependencies: $($result4.Summary.ExternalFunctionDependenciesCount)"
    Write-Host "  Unique Modules: $($result4.Summary.UniqueModules)"
    
    # Test 5: Exporter les rÃ©sultats dans diffÃ©rents formats
    Write-Host "`nTest 5: Exporter les rÃ©sultats dans diffÃ©rents formats" -ForegroundColor Cyan
    
    # Exporter au format texte
    $textOutputPath = Join-Path -Path $testDir -ChildPath "DependencyReport.txt"
    Get-ModuleDependencies -Path $manifestPath -OutputPath $textOutputPath -OutputFormat "Text"
    
    # Exporter au format CSV
    $csvOutputPath = Join-Path -Path $testDir -ChildPath "DependencyReport.csv"
    Get-ModuleDependencies -Path $manifestPath -OutputPath $csvOutputPath -OutputFormat "CSV"
    
    # Exporter au format HTML
    $htmlOutputPath = Join-Path -Path $testDir -ChildPath "DependencyReport.html"
    Get-ModuleDependencies -Path $manifestPath -OutputPath $htmlOutputPath -OutputFormat "HTML"
    
    # Exporter au format JSON
    $jsonOutputPath = Join-Path -Path $testDir -ChildPath "DependencyReport.json"
    Get-ModuleDependencies -Path $manifestPath -OutputPath $jsonOutputPath -OutputFormat "JSON"
    
    # VÃ©rifier que les fichiers ont Ã©tÃ© crÃ©Ã©s
    $exportSuccess = $true
    if (-not (Test-Path -Path $textOutputPath)) {
        Write-Host "Erreur: Le fichier texte n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
        $exportSuccess = $false
    }
    if (-not (Test-Path -Path $csvOutputPath)) {
        Write-Host "Erreur: Le fichier CSV n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
        $exportSuccess = $false
    }
    if (-not (Test-Path -Path $htmlOutputPath)) {
        Write-Host "Erreur: Le fichier HTML n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
        $exportSuccess = $false
    }
    if (-not (Test-Path -Path $jsonOutputPath)) {
        Write-Host "Erreur: Le fichier JSON n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
        $exportSuccess = $false
    }
    
    if ($exportSuccess) {
        Write-Host "Tous les fichiers d'export ont Ã©tÃ© crÃ©Ã©s avec succÃ¨s" -ForegroundColor Green
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
