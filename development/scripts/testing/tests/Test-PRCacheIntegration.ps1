#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intÃ©gration pour le systÃ¨me de cache PRAnalysisCache.
.DESCRIPTION
    Ce script teste l'intÃ©gration du systÃ¨me de cache PRAnalysisCache avec d'autres parties de l'application.
.PARAMETER TestType
    Type de test Ã  exÃ©cuter. Valeurs possibles : FileAnalysis, SyntaxAnalysis, FormatDetection, All.
.EXAMPLE
    .\Test-PRCacheIntegration.ps1 -TestType FileAnalysis
.NOTES
    Author: Augment Agent
    Version: 1.0
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("FileAnalysis", "SyntaxAnalysis", "FormatDetection", "All")]
    [string]$TestType = "All"
)

# Importer les modules nÃ©cessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$cacheModulePath = Join-Path -Path $modulesPath -ChildPath "PRAnalysisCache.psm1"

if (-not (Test-Path -Path $cacheModulePath)) {
    Write-Error "Module PRAnalysisCache.psm1 non trouvÃ© Ã  l'emplacement: $cacheModulePath"
    exit 1
}

Import-Module $cacheModulePath -Force

# Chemin du script d'intÃ©gration
$integrationScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Integrate-PRAnalysisCache.ps1"

if (-not (Test-Path -Path $integrationScriptPath)) {
    Write-Error "Script Integrate-PRAnalysisCache.ps1 non trouvÃ© Ã  l'emplacement: $integrationScriptPath"
    exit 1
}

# CrÃ©er un rÃ©pertoire de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "PRCacheIntegrationTest"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er quelques fichiers de test
$testFiles = @{
    "test1.ps1" = @"
# Test PowerShell script
function Test-Function {
    param(
        [string]`$param1,
        [int]`$param2
    )
    
    if (`$param2 -gt 0) {
        return `$param1 * `$param2
    }
    else {
        return `$param1
    }
}

for (`$i = 0; `$i -lt 10; `$i++) {
    Write-Host "Iteration `$i"
}
"@
    "test2.py" = @"
# Test Python script
def test_function(param1, param2):
    if param2 > 0:
        return param1 * param2
    else:
        return param1

class TestClass:
    def __init__(self, name):
        self.name = name
    
    def get_name(self):
        return self.name

for i in range(10):
    print(f"Iteration {i}")
"@
    "test3.js" = @"
// Test JavaScript script
function testFunction(param1, param2) {
    if (param2 > 0) {
        return param1 * param2;
    } else {
        return param1;
    }
}

class TestClass {
    constructor(name) {
        this.name = name;
    }
    
    getName() {
        return this.name;
    }
}

for (let i = 0; i < 10; i++) {
    console.log(`Iteration ${i}`);
}
"@
}

# CrÃ©er les fichiers de test
foreach ($file in $testFiles.Keys) {
    $filePath = Join-Path -Path $testDir -ChildPath $file
    Set-Content -Path $filePath -Value $testFiles[$file]
    Write-Host "Fichier de test crÃ©Ã©: $filePath" -ForegroundColor Green
}

# Fonction pour mesurer le temps d'exÃ©cution
function Measure-ExecutionTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [string]$Description = "OpÃ©ration"
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = & $ScriptBlock
    $stopwatch.Stop()
    
    Write-Host "$Description terminÃ© en $($stopwatch.ElapsedMilliseconds) ms" -ForegroundColor Cyan
    
    return @{
        Result = $result
        ElapsedMilliseconds = $stopwatch.ElapsedMilliseconds
    }
}

# Fonction pour tester l'analyse de fichier
function Test-FileAnalysis {
    [CmdletBinding()]
    param()
    
    Write-Host "`n=== Test d'analyse de fichier ===" -ForegroundColor Cyan
    
    # Premier passage sans cache
    Write-Host "`nPremier passage (sans cache):" -ForegroundColor Yellow
    $firstPassResult = Measure-ExecutionTime -ScriptBlock {
        & $integrationScriptPath -DemoType FileAnalysis -Path $testDir -UseCache:$false
    } -Description "Premier passage (sans cache)"
    
    # DeuxiÃ¨me passage avec cache
    Write-Host "`nDeuxiÃ¨me passage (avec cache):" -ForegroundColor Yellow
    $secondPassResult = Measure-ExecutionTime -ScriptBlock {
        & $integrationScriptPath -DemoType FileAnalysis -Path $testDir -UseCache
    } -Description "DeuxiÃ¨me passage (avec cache)"
    
    # TroisiÃ¨me passage avec cache
    Write-Host "`nTroisiÃ¨me passage (avec cache):" -ForegroundColor Yellow
    $thirdPassResult = Measure-ExecutionTime -ScriptBlock {
        & $integrationScriptPath -DemoType FileAnalysis -Path $testDir -UseCache
    } -Description "TroisiÃ¨me passage (avec cache)"
    
    # Afficher les statistiques
    Write-Host "`nStatistiques:" -ForegroundColor Cyan
    Write-Host "Temps sans cache: $($firstPassResult.ElapsedMilliseconds) ms" -ForegroundColor White
    Write-Host "Temps avec cache (premier accÃ¨s): $($secondPassResult.ElapsedMilliseconds) ms" -ForegroundColor White
    Write-Host "Temps avec cache (deuxiÃ¨me accÃ¨s): $($thirdPassResult.ElapsedMilliseconds) ms" -ForegroundColor White
    
    $speedup1 = [math]::Round(($firstPassResult.ElapsedMilliseconds / $secondPassResult.ElapsedMilliseconds), 2)
    $speedup2 = [math]::Round(($firstPassResult.ElapsedMilliseconds / $thirdPassResult.ElapsedMilliseconds), 2)
    
    Write-Host "AccÃ©lÃ©ration (premier accÃ¨s au cache): ${speedup1}x" -ForegroundColor Green
    Write-Host "AccÃ©lÃ©ration (deuxiÃ¨me accÃ¨s au cache): ${speedup2}x" -ForegroundColor Green
    
    # VÃ©rifier que le cache fonctionne correctement
    if ($thirdPassResult.ElapsedMilliseconds -lt $firstPassResult.ElapsedMilliseconds) {
        Write-Host "Test rÃ©ussi: Le cache amÃ©liore les performances." -ForegroundColor Green
    }
    else {
        Write-Host "Test Ã©chouÃ©: Le cache n'amÃ©liore pas les performances." -ForegroundColor Red
    }
}

# Fonction pour tester l'analyse syntaxique
function Test-SyntaxAnalysis {
    [CmdletBinding()]
    param()
    
    Write-Host "`n=== Test d'analyse syntaxique ===" -ForegroundColor Cyan
    
    # Premier passage sans cache
    Write-Host "`nPremier passage (sans cache):" -ForegroundColor Yellow
    $firstPassResult = Measure-ExecutionTime -ScriptBlock {
        & $integrationScriptPath -DemoType SyntaxAnalysis -Path $testDir -UseCache:$false
    } -Description "Premier passage (sans cache)"
    
    # DeuxiÃ¨me passage avec cache
    Write-Host "`nDeuxiÃ¨me passage (avec cache):" -ForegroundColor Yellow
    $secondPassResult = Measure-ExecutionTime -ScriptBlock {
        & $integrationScriptPath -DemoType SyntaxAnalysis -Path $testDir -UseCache
    } -Description "DeuxiÃ¨me passage (avec cache)"
    
    # TroisiÃ¨me passage avec cache
    Write-Host "`nTroisiÃ¨me passage (avec cache):" -ForegroundColor Yellow
    $thirdPassResult = Measure-ExecutionTime -ScriptBlock {
        & $integrationScriptPath -DemoType SyntaxAnalysis -Path $testDir -UseCache
    } -Description "TroisiÃ¨me passage (avec cache)"
    
    # Afficher les statistiques
    Write-Host "`nStatistiques:" -ForegroundColor Cyan
    Write-Host "Temps sans cache: $($firstPassResult.ElapsedMilliseconds) ms" -ForegroundColor White
    Write-Host "Temps avec cache (premier accÃ¨s): $($secondPassResult.ElapsedMilliseconds) ms" -ForegroundColor White
    Write-Host "Temps avec cache (deuxiÃ¨me accÃ¨s): $($thirdPassResult.ElapsedMilliseconds) ms" -ForegroundColor White
    
    $speedup1 = [math]::Round(($firstPassResult.ElapsedMilliseconds / $secondPassResult.ElapsedMilliseconds), 2)
    $speedup2 = [math]::Round(($firstPassResult.ElapsedMilliseconds / $thirdPassResult.ElapsedMilliseconds), 2)
    
    Write-Host "AccÃ©lÃ©ration (premier accÃ¨s au cache): ${speedup1}x" -ForegroundColor Green
    Write-Host "AccÃ©lÃ©ration (deuxiÃ¨me accÃ¨s au cache): ${speedup2}x" -ForegroundColor Green
    
    # VÃ©rifier que le cache fonctionne correctement
    if ($thirdPassResult.ElapsedMilliseconds -lt $firstPassResult.ElapsedMilliseconds) {
        Write-Host "Test rÃ©ussi: Le cache amÃ©liore les performances." -ForegroundColor Green
    }
    else {
        Write-Host "Test Ã©chouÃ©: Le cache n'amÃ©liore pas les performances." -ForegroundColor Red
    }
}

# Fonction pour tester la dÃ©tection de format
function Test-FormatDetection {
    [CmdletBinding()]
    param()
    
    Write-Host "`n=== Test de dÃ©tection de format ===" -ForegroundColor Cyan
    
    # Premier passage sans cache
    Write-Host "`nPremier passage (sans cache):" -ForegroundColor Yellow
    $firstPassResult = Measure-ExecutionTime -ScriptBlock {
        & $integrationScriptPath -DemoType FormatDetection -Path $testDir -UseCache:$false
    } -Description "Premier passage (sans cache)"
    
    # DeuxiÃ¨me passage avec cache
    Write-Host "`nDeuxiÃ¨me passage (avec cache):" -ForegroundColor Yellow
    $secondPassResult = Measure-ExecutionTime -ScriptBlock {
        & $integrationScriptPath -DemoType FormatDetection -Path $testDir -UseCache
    } -Description "DeuxiÃ¨me passage (avec cache)"
    
    # TroisiÃ¨me passage avec cache
    Write-Host "`nTroisiÃ¨me passage (avec cache):" -ForegroundColor Yellow
    $thirdPassResult = Measure-ExecutionTime -ScriptBlock {
        & $integrationScriptPath -DemoType FormatDetection -Path $testDir -UseCache
    } -Description "TroisiÃ¨me passage (avec cache)"
    
    # Afficher les statistiques
    Write-Host "`nStatistiques:" -ForegroundColor Cyan
    Write-Host "Temps sans cache: $($firstPassResult.ElapsedMilliseconds) ms" -ForegroundColor White
    Write-Host "Temps avec cache (premier accÃ¨s): $($secondPassResult.ElapsedMilliseconds) ms" -ForegroundColor White
    Write-Host "Temps avec cache (deuxiÃ¨me accÃ¨s): $($thirdPassResult.ElapsedMilliseconds) ms" -ForegroundColor White
    
    $speedup1 = [math]::Round(($firstPassResult.ElapsedMilliseconds / $secondPassResult.ElapsedMilliseconds), 2)
    $speedup2 = [math]::Round(($firstPassResult.ElapsedMilliseconds / $thirdPassResult.ElapsedMilliseconds), 2)
    
    Write-Host "AccÃ©lÃ©ration (premier accÃ¨s au cache): ${speedup1}x" -ForegroundColor Green
    Write-Host "AccÃ©lÃ©ration (deuxiÃ¨me accÃ¨s au cache): ${speedup2}x" -ForegroundColor Green
    
    # VÃ©rifier que le cache fonctionne correctement
    if ($thirdPassResult.ElapsedMilliseconds -lt $firstPassResult.ElapsedMilliseconds) {
        Write-Host "Test rÃ©ussi: Le cache amÃ©liore les performances." -ForegroundColor Green
    }
    else {
        Write-Host "Test Ã©chouÃ©: Le cache n'amÃ©liore pas les performances." -ForegroundColor Red
    }
}

# ExÃ©cuter les tests
if ($TestType -eq "All" -or $TestType -eq "FileAnalysis") {
    Test-FileAnalysis
}

if ($TestType -eq "All" -or $TestType -eq "SyntaxAnalysis") {
    Test-SyntaxAnalysis
}

if ($TestType -eq "All" -or $TestType -eq "FormatDetection") {
    Test-FormatDetection
}

# Nettoyer les fichiers de test
Write-Host "`nNettoyage des fichiers de test..." -ForegroundColor Cyan
Remove-Item -Path $testDir -Recurse -Force
Write-Host "Fichiers de test supprimÃ©s." -ForegroundColor Green
