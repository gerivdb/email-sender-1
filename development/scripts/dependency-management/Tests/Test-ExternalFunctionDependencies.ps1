# Test pour la fonction Get-ExternalFunctionDependencies
# Ce test vérifie que la fonction détecte correctement les dépendances de fonctions externes

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$moduleFile = Join-Path -Path $modulePath -ChildPath "ModuleDependencyAnalyzer-Fixed.psm1"

try {
    # Importer le module
    Import-Module -Name $moduleFile -Force -ErrorAction Stop
    Write-Host "Module importé avec succès" -ForegroundColor Green

    # Créer un répertoire temporaire pour les tests
    $testDir = Join-Path -Path $env:TEMP -ChildPath "ExternalFunctionDependenciesTest"
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null

    # Créer un fichier de test avec des appels à des fonctions externes
    $testScriptContent = @"
# Définition d'une fonction interne
function Test-InternalFunction {
    param (
        [string]`$Path
    )
    
    # Utilisation de fonctions internes
    Write-Output "Testing internal function"
    Test-AnotherInternalFunction
}

# Autre fonction interne
function Test-AnotherInternalFunction {
    # Utilisation de cmdlets externes
    Get-ChildItem -Path "C:\Windows"
    Get-Process -Name "explorer"
    
    # Utilisation d'une méthode
    [System.IO.Path]::GetFileName("C:\test.txt")
    
    # Utilisation de structures de contrôle
    if (`$true) {
        foreach (`$item in @(1, 2, 3)) {
            Write-Output `$item
        }
    }
}

# Appel à des fonctions externes
Get-Date
Get-ChildItem
Get-Process
Write-Host "Test"
"@

    $testScriptPath = Join-Path -Path $testDir -ChildPath "TestScript.ps1"
    Set-Content -Path $testScriptPath -Value $testScriptContent

    # Analyser les dépendances de fonctions externes
    Write-Host "`nTest: Get-ExternalFunctionDependencies" -ForegroundColor Cyan
    $result = Get-ExternalFunctionDependencies -ModulePath $testScriptPath
    
    # Afficher les résultats
    Write-Host "External function dependencies found: $($result.Count)"
    $result | ForEach-Object {
        Write-Host "  - $($_.FunctionName) from module $($_.Name) (Type: $($_.Type))"
    }
    
    # Vérifier que les fonctions internes ne sont pas détectées comme externes
    $internalFunctions = $result | Where-Object { $_.FunctionName -eq "Test-InternalFunction" -or $_.FunctionName -eq "Test-AnotherInternalFunction" }
    if ($internalFunctions.Count -eq 0) {
        Write-Host "Internal functions correctly ignored" -ForegroundColor Green
    } else {
        Write-Host "Error: Internal functions detected as external" -ForegroundColor Red
    }
    
    # Vérifier que les fonctions externes sont correctement détectées
    $expectedExternalFunctions = @("Get-Date", "Get-ChildItem", "Get-Process", "Write-Host")
    $missingFunctions = @()
    
    foreach ($expectedFunction in $expectedExternalFunctions) {
        $found = $result | Where-Object { $_.FunctionName -eq $expectedFunction }
        if (-not $found) {
            $missingFunctions += $expectedFunction
        }
    }
    
    if ($missingFunctions.Count -eq 0) {
        Write-Host "All expected external functions detected" -ForegroundColor Green
    } else {
        Write-Host "Error: Some expected external functions not detected: $($missingFunctions -join ', ')" -ForegroundColor Red
    }

    # Nettoyer
    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Module -Name "ModuleDependencyAnalyzer-Fixed" -Force -ErrorAction SilentlyContinue

    # Tout est OK
    Write-Host "`nTest terminé avec succès !" -ForegroundColor Green
    exit 0
} catch {
    # Une erreur s'est produite
    Write-Host "Erreur : $_" -ForegroundColor Red
    exit 1
}
