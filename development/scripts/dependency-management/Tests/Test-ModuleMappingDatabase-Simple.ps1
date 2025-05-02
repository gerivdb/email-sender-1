#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour les fonctions de gestion de la base de données de correspondance entre cmdlets/types/variables et modules.

.DESCRIPTION
    Ce script teste les fonctions New-ModuleMappingDatabase, Update-ModuleMappingDatabase et Import-ModuleMappingDatabase
    du module ImplicitModuleDependencyDetector.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-12-15
#>

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ImplicitModuleDependencyDetector.psm1"
Import-Module $modulePath -Force

# Créer un répertoire temporaire pour les tests
$tempDir = Join-Path -Path $env:TEMP -ChildPath "ModuleMappingTests_$(Get-Random)"
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Définir les chemins des fichiers de test
$databasePath = Join-Path -Path $tempDir -ChildPath "ModuleMapping.psd1"
$updatedDatabasePath = Join-Path -Path $tempDir -ChildPath "ModuleMapping_Updated.psd1"

Write-Host "=== Test des fonctions de gestion de la base de données de correspondance ===" -ForegroundColor Cyan

# Test 1: Créer une base de données de correspondance
Write-Host "`nTest 1: Créer une base de données de correspondance" -ForegroundColor Cyan
$moduleNames = @("Microsoft.PowerShell.Management", "Microsoft.PowerShell.Utility")
$database = New-ModuleMappingDatabase -ModuleNames $moduleNames -OutputPath $databasePath -Verbose

if (Test-Path -Path $databasePath) {
    Write-Host "  Base de données créée avec succès: $databasePath" -ForegroundColor Green
    
    # Vérifier le contenu de la base de données
    $content = Get-Content -Path $databasePath -Raw
    if ($content -match "CmdletToModuleMapping" -and $content -match "TypeToModuleMapping" -and $content -match "VariableToModuleMapping") {
        Write-Host "  La base de données contient les sections attendues" -ForegroundColor Green
    } else {
        Write-Host "  La base de données ne contient pas les sections attendues" -ForegroundColor Red
    }
} else {
    Write-Host "  Échec de la création de la base de données" -ForegroundColor Red
}

# Test 2: Mettre à jour la base de données de correspondance
Write-Host "`nTest 2: Mettre à jour la base de données de correspondance" -ForegroundColor Cyan
$additionalModules = @("Microsoft.PowerShell.Security")
$updatedDatabase = Update-ModuleMappingDatabase -DatabasePath $databasePath -ModuleNames $additionalModules -OutputPath $updatedDatabasePath -Verbose

if (Test-Path -Path $updatedDatabasePath) {
    Write-Host "  Base de données mise à jour avec succès: $updatedDatabasePath" -ForegroundColor Green
    
    # Vérifier le contenu de la base de données mise à jour
    $content = Get-Content -Path $updatedDatabasePath -Raw
    if ($content -match "Microsoft.PowerShell.Security") {
        Write-Host "  La base de données mise à jour contient le module ajouté" -ForegroundColor Green
    } else {
        Write-Host "  La base de données mise à jour ne contient pas le module ajouté" -ForegroundColor Red
    }
} else {
    Write-Host "  Échec de la mise à jour de la base de données" -ForegroundColor Red
}

# Test 3: Importer la base de données de correspondance
Write-Host "`nTest 3: Importer la base de données de correspondance" -ForegroundColor Cyan
$importedDatabase = Import-ModuleMappingDatabase -DatabasePath $updatedDatabasePath -UpdateGlobalMappings:$false

if ($importedDatabase) {
    Write-Host "  Base de données importée avec succès" -ForegroundColor Green
    
    # Vérifier le contenu de la base de données importée
    if ($importedDatabase.CmdletToModuleMapping -and $importedDatabase.TypeToModuleMapping -and $importedDatabase.VariableToModuleMapping) {
        Write-Host "  La base de données importée contient les sections attendues" -ForegroundColor Green
    } else {
        Write-Host "  La base de données importée ne contient pas les sections attendues" -ForegroundColor Red
    }
} else {
    Write-Host "  Échec de l'importation de la base de données" -ForegroundColor Red
}

# Test 4: Mettre à jour les mappings globaux
Write-Host "`nTest 4: Mettre à jour les mappings globaux" -ForegroundColor Cyan
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
    Write-Host "  Les mappings globaux ont été mis à jour avec succès" -ForegroundColor Green
} else {
    Write-Host "  Les mappings globaux n'ont pas été mis à jour correctement" -ForegroundColor Red
}

# Test 5: Créer une base de données sans spécifier de modules
Write-Host "`nTest 5: Créer une base de données sans spécifier de modules" -ForegroundColor Cyan
$allModulesDatabase = New-ModuleMappingDatabase -IncludeCmdlets -IncludeTypes:$false -IncludeVariables:$false

if ($allModulesDatabase) {
    Write-Host "  Base de données créée avec succès sans spécifier de modules" -ForegroundColor Green
    
    # Vérifier le contenu de la base de données
    if ($allModulesDatabase.CmdletToModuleMapping.Count -gt 0) {
        Write-Host "  La base de données contient des mappings de cmdlets ($($allModulesDatabase.CmdletToModuleMapping.Count))" -ForegroundColor Green
    } else {
        Write-Host "  La base de données ne contient pas de mappings de cmdlets" -ForegroundColor Red
    }
    
    if ($allModulesDatabase.TypeToModuleMapping.Count -eq 0) {
        Write-Host "  La base de données ne contient pas de mappings de types (comme demandé)" -ForegroundColor Green
    } else {
        Write-Host "  La base de données contient des mappings de types alors qu'ils ne devraient pas être inclus" -ForegroundColor Red
    }
    
    if ($allModulesDatabase.VariableToModuleMapping.Count -eq 0) {
        Write-Host "  La base de données ne contient pas de mappings de variables (comme demandé)" -ForegroundColor Green
    } else {
        Write-Host "  La base de données contient des mappings de variables alors qu'ils ne devraient pas être inclus" -ForegroundColor Red
    }
} else {
    Write-Host "  Échec de la création de la base de données sans spécifier de modules" -ForegroundColor Red
}

# Nettoyer
Write-Host "`nNettoyage..." -ForegroundColor Gray
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "`nTests terminés avec succès!" -ForegroundColor Green
