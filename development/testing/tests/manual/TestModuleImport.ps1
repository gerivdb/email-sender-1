# Test d'importation des modules
Write-Host "Test d'importation des modules" -ForegroundColor Green

# Importer les modules
$scriptPath = $MyInvocation.MyCommand.Path
$testRoot = Split-Path -Parent $scriptPath
$manualTestRoot = Split-Path -Parent $testRoot
$projectRoot = Split-Path -Parent $manualTestRoot
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"

Write-Host "Chemin du projet : $projectRoot" -ForegroundColor Cyan

# Fonction pour tester l'importation d'un module
function Test-ModuleImport {
    param (
        [string]$ModuleName,
        [string]$ModulePath
    )
    
    Write-Host "Test d'importation du module $ModuleName..." -ForegroundColor Yellow
    
    if (-not (Test-Path -Path $ModulePath)) {
        Write-Host "Le module $ModuleName n'existe pas au chemin spÃ©cifiÃ© : $ModulePath" -ForegroundColor Red
        return $false
    }
    
    try {
        # CrÃ©er un nouveau processus PowerShell pour isoler l'importation
        $result = powershell.exe -Command "
            `$ErrorActionPreference = 'Stop'
            try {
                # Importer le module
                . '$ModulePath'
                Write-Output 'Success'
            } catch {
                Write-Output `$_.Exception.Message
                exit 1
            }
        "
        
        if ($result -eq "Success") {
            Write-Host "Module $ModuleName importÃ© avec succÃ¨s." -ForegroundColor Green
            return $true
        } else {
            Write-Host "Erreur lors de l'importation du module $ModuleName : $result" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Exception lors de l'importation du module $ModuleName : $_" -ForegroundColor Red
        return $false
    }
}

# Tester l'importation des modules
$modules = @{
    "EncryptionUtils" = Join-Path -Path $modulesPath -ChildPath "EncryptionUtils.ps1"
    "CacheManager" = Join-Path -Path $modulesPath -ChildPath "CacheManager.ps1"
    "UnifiedSegmenter" = Join-Path -Path $modulesPath -ChildPath "UnifiedSegmenter.ps1"
    "FileProcessingFacade" = Join-Path -Path $modulesPath -ChildPath "FileProcessingFacade.ps1"
    "ParallelProcessing" = Join-Path -Path $modulesPath -ChildPath "ParallelProcessing.ps1"
    "FileSecurityUtils" = Join-Path -Path $modulesPath -ChildPath "FileSecurityUtils.ps1"
    "UnifiedFileProcessor" = Join-Path -Path $modulesPath -ChildPath "UnifiedFileProcessor.ps1"
}

$results = @{}
foreach ($moduleName in $modules.Keys) {
    $modulePath = $modules[$moduleName]
    $results[$moduleName] = Test-ModuleImport -ModuleName $moduleName -ModulePath $modulePath
}

# Afficher les rÃ©sultats
Write-Host "`nRÃ©sultats des tests d'importation :" -ForegroundColor Cyan
foreach ($moduleName in $results.Keys) {
    $status = if ($results[$moduleName]) { "SuccÃ¨s" } else { "Ã‰chec" }
    $color = if ($results[$moduleName]) { "Green" } else { "Red" }
    Write-Host "  $moduleName : $status" -ForegroundColor $color
}

# VÃ©rifier si tous les modules ont Ã©tÃ© importÃ©s avec succÃ¨s
$allSuccess = $true
foreach ($success in $results.Values) {
    if (-not $success) {
        $allSuccess = $false
        break
    }
}

if ($allSuccess) {
    Write-Host "`nTous les modules ont Ã©tÃ© importÃ©s avec succÃ¨s." -ForegroundColor Green
} else {
    Write-Host "`nCertains modules n'ont pas pu Ãªtre importÃ©s. Veuillez corriger les erreurs." -ForegroundColor Red
}

Write-Host "Tests terminÃ©s." -ForegroundColor Green
