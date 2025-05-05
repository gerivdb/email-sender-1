# Test pour la fonction Resolve-ExternalFunctionPath
# Ce test vÃ©rifie que la fonction rÃ©sout correctement les chemins des fonctions externes

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$moduleFile = Join-Path -Path $modulePath -ChildPath "ModuleDependencyAnalyzer-Fixed.psm1"

try {
    # Importer le module
    Import-Module -Name $moduleFile -Force -ErrorAction Stop
    Write-Host "Module importÃ© avec succÃ¨s" -ForegroundColor Green

    # Test 1: RÃ©soudre le chemin d'une fonction avec le module spÃ©cifiÃ©
    Write-Host "`nTest 1: RÃ©soudre le chemin d'une fonction avec le module spÃ©cifiÃ©" -ForegroundColor Cyan
    $result1 = Resolve-ExternalFunctionPath -FunctionName "Get-ChildItem" -ModuleName "Microsoft.PowerShell.Management"
    
    Write-Host "Fonction: $($result1.FunctionName)"
    Write-Host "Module: $($result1.ModuleName)"
    Write-Host "Chemin du module: $($result1.ModulePath)"
    Write-Host "Type de commande: $($result1.CommandType)"
    
    # VÃ©rifier que le rÃ©sultat est correct
    if ($result1.ModuleName -eq "Microsoft.PowerShell.Management" -and $result1.FunctionName -eq "Get-ChildItem") {
        Write-Host "Test 1 rÃ©ussi" -ForegroundColor Green
    } else {
        Write-Host "Test 1 Ã©chouÃ©" -ForegroundColor Red
    }
    
    # Test 2: RÃ©soudre le chemin d'une fonction sans spÃ©cifier le module
    Write-Host "`nTest 2: RÃ©soudre le chemin d'une fonction sans spÃ©cifier le module" -ForegroundColor Cyan
    $result2 = Resolve-ExternalFunctionPath -FunctionName "Get-Date"
    
    Write-Host "Fonction: $($result2.FunctionName)"
    Write-Host "Module: $($result2.ModuleName)"
    Write-Host "Chemin du module: $($result2.ModulePath)"
    Write-Host "Type de commande: $($result2.CommandType)"
    
    # VÃ©rifier que le rÃ©sultat est correct
    if ($result2.ModuleName -eq "Microsoft.PowerShell.Utility" -and $result2.FunctionName -eq "Get-Date") {
        Write-Host "Test 2 rÃ©ussi" -ForegroundColor Green
    } else {
        Write-Host "Test 2 Ã©chouÃ©" -ForegroundColor Red
    }
    
    # Test 3: RÃ©soudre le chemin d'une fonction qui n'existe pas
    Write-Host "`nTest 3: RÃ©soudre le chemin d'une fonction qui n'existe pas" -ForegroundColor Cyan
    $result3 = Resolve-ExternalFunctionPath -FunctionName "Get-NonExistentFunction"
    
    Write-Host "Fonction: $($result3.FunctionName)"
    Write-Host "Module: $($result3.ModuleName)"
    Write-Host "Chemin du module: $($result3.ModulePath)"
    Write-Host "Type de commande: $($result3.CommandType)"
    
    # VÃ©rifier que le rÃ©sultat est correct
    if ($null -eq $result3.ModuleName -and $result3.FunctionName -eq "Get-NonExistentFunction") {
        Write-Host "Test 3 rÃ©ussi" -ForegroundColor Green
    } else {
        Write-Host "Test 3 Ã©chouÃ©" -ForegroundColor Red
    }

    # Nettoyer
    Remove-Module -Name "ModuleDependencyAnalyzer-Fixed" -Force -ErrorAction SilentlyContinue

    # Tout est OK
    Write-Host "`nTest terminÃ© avec succÃ¨s !" -ForegroundColor Green
    exit 0
} catch {
    # Une erreur s'est produite
    Write-Host "Erreur : $_" -ForegroundColor Red
    exit 1
}
