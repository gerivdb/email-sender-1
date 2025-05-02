# Test pour la fonction Resolve-ExternalFunctionPath
# Ce test vérifie que la fonction résout correctement les chemins des fonctions externes

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$moduleFile = Join-Path -Path $modulePath -ChildPath "ModuleDependencyAnalyzer-Fixed.psm1"

try {
    # Importer le module
    Import-Module -Name $moduleFile -Force -ErrorAction Stop
    Write-Host "Module importé avec succès" -ForegroundColor Green

    # Test 1: Résoudre le chemin d'une fonction avec le module spécifié
    Write-Host "`nTest 1: Résoudre le chemin d'une fonction avec le module spécifié" -ForegroundColor Cyan
    $result1 = Resolve-ExternalFunctionPath -FunctionName "Get-ChildItem" -ModuleName "Microsoft.PowerShell.Management"
    
    Write-Host "Fonction: $($result1.FunctionName)"
    Write-Host "Module: $($result1.ModuleName)"
    Write-Host "Chemin du module: $($result1.ModulePath)"
    Write-Host "Type de commande: $($result1.CommandType)"
    
    # Vérifier que le résultat est correct
    if ($result1.ModuleName -eq "Microsoft.PowerShell.Management" -and $result1.FunctionName -eq "Get-ChildItem") {
        Write-Host "Test 1 réussi" -ForegroundColor Green
    } else {
        Write-Host "Test 1 échoué" -ForegroundColor Red
    }
    
    # Test 2: Résoudre le chemin d'une fonction sans spécifier le module
    Write-Host "`nTest 2: Résoudre le chemin d'une fonction sans spécifier le module" -ForegroundColor Cyan
    $result2 = Resolve-ExternalFunctionPath -FunctionName "Get-Date"
    
    Write-Host "Fonction: $($result2.FunctionName)"
    Write-Host "Module: $($result2.ModuleName)"
    Write-Host "Chemin du module: $($result2.ModulePath)"
    Write-Host "Type de commande: $($result2.CommandType)"
    
    # Vérifier que le résultat est correct
    if ($result2.ModuleName -eq "Microsoft.PowerShell.Utility" -and $result2.FunctionName -eq "Get-Date") {
        Write-Host "Test 2 réussi" -ForegroundColor Green
    } else {
        Write-Host "Test 2 échoué" -ForegroundColor Red
    }
    
    # Test 3: Résoudre le chemin d'une fonction qui n'existe pas
    Write-Host "`nTest 3: Résoudre le chemin d'une fonction qui n'existe pas" -ForegroundColor Cyan
    $result3 = Resolve-ExternalFunctionPath -FunctionName "Get-NonExistentFunction"
    
    Write-Host "Fonction: $($result3.FunctionName)"
    Write-Host "Module: $($result3.ModuleName)"
    Write-Host "Chemin du module: $($result3.ModulePath)"
    Write-Host "Type de commande: $($result3.CommandType)"
    
    # Vérifier que le résultat est correct
    if ($null -eq $result3.ModuleName -and $result3.FunctionName -eq "Get-NonExistentFunction") {
        Write-Host "Test 3 réussi" -ForegroundColor Green
    } else {
        Write-Host "Test 3 échoué" -ForegroundColor Red
    }

    # Nettoyer
    Remove-Module -Name "ModuleDependencyAnalyzer-Fixed" -Force -ErrorAction SilentlyContinue

    # Tout est OK
    Write-Host "`nTest terminé avec succès !" -ForegroundColor Green
    exit 0
} catch {
    # Une erreur s'est produite
    Write-Host "Erreur : $_" -ForegroundColor Red
    exit 1
}
