#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour les fonctions de gestion de la base de donnÃ©es de correspondance entre cmdlets/types/variables et modules.

.DESCRIPTION
    Ce script teste les fonctions New-ModuleMappingDatabase, Update-ModuleMappingDatabase et Import-ModuleMappingDatabase
    du module ImplicitModuleDependencyDetector.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-12-15
#>

# Importer le module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ImplicitModuleDependencyDetector.psm1"
Import-Module $modulePath -Force

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$tempDir = Join-Path -Path $env:TEMP -ChildPath "ModuleMappingTests_$(Get-Random)"
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# DÃ©finir les chemins des fichiers de test
$databasePath = Join-Path -Path $tempDir -ChildPath "ModuleMapping.psd1"
$updatedDatabasePath = Join-Path -Path $tempDir -ChildPath "ModuleMapping_Updated.psd1"

Write-Host "=== Test des fonctions de gestion de la base de donnÃ©es de correspondance ===" -ForegroundColor Cyan

# Test 1: CrÃ©er une base de donnÃ©es de correspondance
Write-Host "`nTest 1: CrÃ©er une base de donnÃ©es de correspondance" -ForegroundColor Cyan
$moduleNames = @("Microsoft.PowerShell.Management", "Microsoft.PowerShell.Utility")
$database = New-ModuleMappingDatabase -ModuleNames $moduleNames -OutputPath $databasePath -Verbose

if (Test-Path -Path $databasePath) {
    Write-Host "  Base de donnÃ©es crÃ©Ã©e avec succÃ¨s: $databasePath" -ForegroundColor Green
    
    # VÃ©rifier le contenu de la base de donnÃ©es
    $content = Get-Content -Path $databasePath -Raw
    if ($content -match "CmdletToModuleMapping" -and $content -match "TypeToModuleMapping" -and $content -match "VariableToModuleMapping") {
        Write-Host "  La base de donnÃ©es contient les sections attendues" -ForegroundColor Green
    } else {
        Write-Host "  La base de donnÃ©es ne contient pas les sections attendues" -ForegroundColor Red
    }
} else {
    Write-Host "  Ã‰chec de la crÃ©ation de la base de donnÃ©es" -ForegroundColor Red
}

# Test 2: Mettre Ã  jour la base de donnÃ©es de correspondance
Write-Host "`nTest 2: Mettre Ã  jour la base de donnÃ©es de correspondance" -ForegroundColor Cyan
$additionalModules = @("Microsoft.PowerShell.Security")
$updatedDatabase = Update-ModuleMappingDatabase -DatabasePath $databasePath -ModuleNames $additionalModules -OutputPath $updatedDatabasePath -Verbose

if (Test-Path -Path $updatedDatabasePath) {
    Write-Host "  Base de donnÃ©es mise Ã  jour avec succÃ¨s: $updatedDatabasePath" -ForegroundColor Green
    
    # VÃ©rifier le contenu de la base de donnÃ©es mise Ã  jour
    $content = Get-Content -Path $updatedDatabasePath -Raw
    if ($content -match "Microsoft.PowerShell.Security") {
        Write-Host "  La base de donnÃ©es mise Ã  jour contient le module ajoutÃ©" -ForegroundColor Green
    } else {
        Write-Host "  La base de donnÃ©es mise Ã  jour ne contient pas le module ajoutÃ©" -ForegroundColor Red
    }
} else {
    Write-Host "  Ã‰chec de la mise Ã  jour de la base de donnÃ©es" -ForegroundColor Red
}

# Test 3: Importer la base de donnÃ©es de correspondance
Write-Host "`nTest 3: Importer la base de donnÃ©es de correspondance" -ForegroundColor Cyan
$importedDatabase = Import-ModuleMappingDatabase -DatabasePath $updatedDatabasePath -UpdateGlobalMappings:$false

if ($importedDatabase) {
    Write-Host "  Base de donnÃ©es importÃ©e avec succÃ¨s" -ForegroundColor Green
    
    # VÃ©rifier le contenu de la base de donnÃ©es importÃ©e
    if ($importedDatabase.CmdletToModuleMapping -and $importedDatabase.TypeToModuleMapping -and $importedDatabase.VariableToModuleMapping) {
        Write-Host "  La base de donnÃ©es importÃ©e contient les sections attendues" -ForegroundColor Green
    } else {
        Write-Host "  La base de donnÃ©es importÃ©e ne contient pas les sections attendues" -ForegroundColor Red
    }
} else {
    Write-Host "  Ã‰chec de l'importation de la base de donnÃ©es" -ForegroundColor Red
}

# Test 4: Mettre Ã  jour les mappings globaux
Write-Host "`nTest 4: Mettre Ã  jour les mappings globaux" -ForegroundColor Cyan
$originalCmdletCount = $script:CmdletToModuleMapping.Count
$originalTypeCount = $script:TypeToModuleMapping.Count
$originalVariableCount = $script:GlobalVariableToModuleMapping.Count

Import-ModuleMappingDatabase -DatabasePath $updatedDatabasePath -UpdateGlobalMappings

$newCmdletCount = $script:CmdletToModuleMapping.Count
$newTypeCount = $script:TypeToModuleMapping.Count
$newVariableCount = $script:GlobalVariableToModuleMapping.Count

Write-Host "  Mappings de cmdlets: $originalCmdletCount -> $newCmdletCount" -ForegroundColor Gray
Write-Host "  Mappings de types: $originalTypeCount -> $newTypeCount" -ForegroundColor Gray
Write-Host "  Mappings de variables: $originalVariableCount -> $newVariableCount" -ForegroundColor Gray

if ($newCmdletCount -gt $originalCmdletCount -or $newTypeCount -gt $originalTypeCount -or $newVariableCount -gt $originalVariableCount) {
    Write-Host "  Les mappings globaux ont Ã©tÃ© mis Ã  jour avec succÃ¨s" -ForegroundColor Green
} else {
    Write-Host "  Les mappings globaux n'ont pas Ã©tÃ© mis Ã  jour correctement" -ForegroundColor Red
}

# Test 5: CrÃ©er une base de donnÃ©es sans spÃ©cifier de modules
Write-Host "`nTest 5: CrÃ©er une base de donnÃ©es sans spÃ©cifier de modules" -ForegroundColor Cyan
$allModulesDatabase = New-ModuleMappingDatabase -IncludeCmdlets -IncludeTypes:$false -IncludeVariables:$false

if ($allModulesDatabase) {
    Write-Host "  Base de donnÃ©es crÃ©Ã©e avec succÃ¨s sans spÃ©cifier de modules" -ForegroundColor Green
    
    # VÃ©rifier le contenu de la base de donnÃ©es
    if ($allModulesDatabase.CmdletToModuleMapping.Count -gt 0) {
        Write-Host "  La base de donnÃ©es contient des mappings de cmdlets ($($allModulesDatabase.CmdletToModuleMapping.Count))" -ForegroundColor Green
    } else {
        Write-Host "  La base de donnÃ©es ne contient pas de mappings de cmdlets" -ForegroundColor Red
    }
    
    if ($allModulesDatabase.TypeToModuleMapping.Count -eq 0) {
        Write-Host "  La base de donnÃ©es ne contient pas de mappings de types (comme demandÃ©)" -ForegroundColor Green
    } else {
        Write-Host "  La base de donnÃ©es contient des mappings de types alors qu'ils ne devraient pas Ãªtre inclus" -ForegroundColor Red
    }
    
    if ($allModulesDatabase.VariableToModuleMapping.Count -eq 0) {
        Write-Host "  La base de donnÃ©es ne contient pas de mappings de variables (comme demandÃ©)" -ForegroundColor Green
    } else {
        Write-Host "  La base de donnÃ©es contient des mappings de variables alors qu'ils ne devraient pas Ãªtre inclus" -ForegroundColor Red
    }
} else {
    Write-Host "  Ã‰chec de la crÃ©ation de la base de donnÃ©es sans spÃ©cifier de modules" -ForegroundColor Red
}

# Nettoyer
Write-Host "`nNettoyage..." -ForegroundColor Gray
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "`nTests terminÃ©s avec succÃ¨s!" -ForegroundColor Green
