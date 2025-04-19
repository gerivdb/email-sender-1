# Script pour corriger les modules
Write-Host "Correction des modules" -ForegroundColor Green

# Importer les modules
$scriptPath = $MyInvocation.MyCommand.Path
$testRoot = Split-Path -Parent $scriptPath
$manualTestRoot = Split-Path -Parent $testRoot
$projectRoot = Split-Path -Parent $manualTestRoot
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"

Write-Host "Chemin du projet : $projectRoot" -ForegroundColor Cyan

# Fonction pour corriger un module
function Fix-Module {
    param (
        [string]$ModuleName,
        [string]$ModulePath
    )
    
    Write-Host "Correction du module $ModuleName..." -ForegroundColor Yellow
    
    if (-not (Test-Path -Path $ModulePath)) {
        Write-Host "Le module $ModuleName n'existe pas au chemin spécifié : $ModulePath" -ForegroundColor Red
        return $false
    }
    
    try {
        # Lire le contenu du module
        $content = Get-Content -Path $ModulePath -Raw
        
        # Remplacer Export-ModuleMember par un commentaire
        $newContent = $content -replace "Export-ModuleMember.*", "# Export-ModuleMember est commenté pour permettre le chargement direct du script"
        
        # Écrire le contenu modifié
        Set-Content -Path $ModulePath -Value $newContent -Encoding UTF8
        
        Write-Host "Module $ModuleName corrigé avec succès." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Erreur lors de la correction du module $ModuleName : $_" -ForegroundColor Red
        return $false
    }
}

# Corriger les modules
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
    $results[$moduleName] = Fix-Module -ModuleName $moduleName -ModulePath $modulePath
}

# Afficher les résultats
Write-Host "`nRésultats des corrections :" -ForegroundColor Cyan
foreach ($moduleName in $results.Keys) {
    $status = if ($results[$moduleName]) { "Succès" } else { "Échec" }
    $color = if ($results[$moduleName]) { "Green" } else { "Red" }
    Write-Host "  $moduleName : $status" -ForegroundColor $color
}

# Vérifier si tous les modules ont été corrigés avec succès
$allSuccess = $true
foreach ($success in $results.Values) {
    if (-not $success) {
        $allSuccess = $false
        break
    }
}

if ($allSuccess) {
    Write-Host "`nTous les modules ont été corrigés avec succès." -ForegroundColor Green
} else {
    Write-Host "`nCertains modules n'ont pas pu être corrigés. Veuillez vérifier les erreurs." -ForegroundColor Red
}

Write-Host "Corrections terminées." -ForegroundColor Green
