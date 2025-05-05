# Test pour l'intÃ©gration avec le module ModuleDependencyDetector
# Ce test vÃ©rifie que les fonctions d'intÃ©gration fonctionnent correctement

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$moduleFile = Join-Path -Path $modulePath -ChildPath "ModuleDependencyAnalyzer-Fixed.psm1"

try {
    # Importer le module
    Import-Module -Name $moduleFile -Force -ErrorAction Stop
    Write-Host "Module importÃ© avec succÃ¨s" -ForegroundColor Green

    # CrÃ©er un rÃ©pertoire temporaire pour les tests
    $testDir = Join-Path -Path $env:TEMP -ChildPath "ModuleDependencyDetectorIntegrationTest"
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

    # Test 1: Convertir une analyse de dÃ©pendances au format ModuleDependencyDetector
    Write-Host "`nTest 1: Convertir une analyse de dÃ©pendances au format ModuleDependencyDetector" -ForegroundColor Cyan
    
    # Effectuer une analyse de dÃ©pendances
    $analysis = Get-CompleteDependencyAnalysis -ModulePath $manifestPath
    
    # Convertir au format ModuleDependencyDetector
    $result1 = ConvertTo-ModuleDependencyDetectorFormat -DependencyAnalysis $analysis -Format "Simple"
    
    Write-Host "RÃ©sultat de la conversion au format Simple:"
    Write-Host "  Module Name: $($result1.ModuleName)"
    Write-Host "  Module Path: $($result1.ModulePath)"
    Write-Host "  Analysis Date: $($result1.AnalysisDate)"
    Write-Host "  Dependencies Count: $($result1.Dependencies.Count)"
    
    # Test 2: Convertir une analyse de dÃ©pendances au format ModuleDependencyDetector dÃ©taillÃ©
    Write-Host "`nTest 2: Convertir une analyse de dÃ©pendances au format ModuleDependencyDetector dÃ©taillÃ©" -ForegroundColor Cyan
    
    # Convertir au format ModuleDependencyDetector dÃ©taillÃ©
    $result2 = ConvertTo-ModuleDependencyDetectorFormat -DependencyAnalysis $analysis -Format "Detailed"
    
    Write-Host "RÃ©sultat de la conversion au format Detailed:"
    Write-Host "  Module Name: $($result2.ModuleName)"
    Write-Host "  Module Path: $($result2.ModulePath)"
    Write-Host "  Analysis Date: $($result2.AnalysisDate)"
    Write-Host "  Dependencies Count: $($result2.Dependencies.Count)"
    
    # VÃ©rifier que les propriÃ©tÃ©s supplÃ©mentaires sont prÃ©sentes
    $hasDetailedProperties = $false
    if ($result2.Dependencies.Count -gt 0) {
        $firstDependency = $result2.Dependencies[0]
        if ($firstDependency.Path -ne $null -or $firstDependency.GUID -ne $null -or $firstDependency.DependencyType -ne $null) {
            $hasDetailedProperties = $true
        }
    }
    
    if ($hasDetailedProperties) {
        Write-Host "  Les propriÃ©tÃ©s dÃ©taillÃ©es sont prÃ©sentes - OK" -ForegroundColor Green
    } else {
        Write-Host "  Erreur: Les propriÃ©tÃ©s dÃ©taillÃ©es ne sont pas prÃ©sentes" -ForegroundColor Red
    }
    
    # Test 3: Utiliser Invoke-ModuleDependencyDetector
    Write-Host "`nTest 3: Utiliser Invoke-ModuleDependencyDetector" -ForegroundColor Cyan
    
    # CrÃ©er un chemin de sortie pour le rapport
    $outputPath = Join-Path -Path $testDir -ChildPath "DependencyReport.html"
    
    # Appeler Invoke-ModuleDependencyDetector
    $result3 = Invoke-ModuleDependencyDetector -ModulePath $manifestPath -Format "Detailed" -OutputPath $outputPath -OutputFormat "HTML"
    
    Write-Host "RÃ©sultat de Invoke-ModuleDependencyDetector:"
    Write-Host "  Module Name: $($result3.ModuleName)"
    Write-Host "  Module Path: $($result3.ModulePath)"
    Write-Host "  Analysis Date: $($result3.AnalysisDate)"
    Write-Host "  Dependencies Count: $($result3.Dependencies.Count)"
    
    # VÃ©rifier que le fichier de sortie a Ã©tÃ© crÃ©Ã©
    if (Test-Path -Path $outputPath) {
        Write-Host "  Le fichier de sortie a Ã©tÃ© crÃ©Ã© - OK" -ForegroundColor Green
        
        # Afficher le dÃ©but du fichier HTML
        $htmlContent = Get-Content -Path $outputPath -Raw
        Write-Host "  AperÃ§u du fichier HTML (premiÃ¨res lignes):"
        Write-Host ($htmlContent.Substring(0, [Math]::Min(500, $htmlContent.Length)))
    } else {
        Write-Host "  Erreur: Le fichier de sortie n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
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
