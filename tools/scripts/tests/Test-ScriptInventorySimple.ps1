#Requires -Version 5.1
<#
.SYNOPSIS
    Tests simplifiÃ©s pour le systÃ¨me d'inventaire et de classification des scripts
.DESCRIPTION
    Ce script exÃ©cute des tests simplifiÃ©s pour vÃ©rifier le bon fonctionnement
    du systÃ¨me d'inventaire et de classification des scripts.
.EXAMPLE
    .\Test-ScriptInventorySimple.ps1
.NOTES
    Auteur: Augment Agent
    Version: 1.0
#>
[CmdletBinding()]
param()

# Importer le module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\ScriptInventoryManager.psm1"
Import-Module $modulePath -Force

# CrÃ©er un rÃ©pertoire de test temporaire
$testDir = Join-Path -Path $env:TEMP -ChildPath "ScriptInventoryTest_$(Get-Random)"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

Write-Host "PrÃ©paration des tests..." -ForegroundColor Cyan
Write-Host "RÃ©pertoire de test: $testDir" -ForegroundColor White

# CrÃ©er des fichiers de test
$testFiles = @{
    "Test-Core.ps1"       = @"
<#
.SYNOPSIS
    Script de test pour la catÃ©gorie Core
.DESCRIPTION
    Ce script est utilisÃ© pour tester la classification des scripts
.AUTHOR
    Test Author
.VERSION
    1.0
.TAGS
    Test, Core, Initialisation
#>

function Initialize-TestEnvironment {
    # Fonction de test
}
"@
    "Test-Gestion.ps1"    = @"
<#
.SYNOPSIS
    Script de test pour la catÃ©gorie Gestion
.DESCRIPTION
    Ce script est utilisÃ© pour tester la classification des scripts
.AUTHOR
    Test Author
.VERSION
    1.0
.TAGS
    Test, Gestion, Admin
#>

function Manage-TestProject {
    # Fonction de test
}
"@
    "Test-Duplicate1.ps1" = @"
# Script dupliquÃ© pour les tests
function Test-Duplicate {
    Write-Host "Test de duplication"
}
"@
    "Test-Duplicate2.ps1" = @"
# Script dupliquÃ© pour les tests
function Test-Duplicate {
    Write-Host "Test de duplication"
}
"@
}

# CrÃ©er les fichiers de test
foreach ($file in $testFiles.Keys) {
    $filePath = Join-Path -Path $testDir -ChildPath $file
    Set-Content -Path $filePath -Value $testFiles[$file]
    Write-Host "Fichier crÃ©Ã©: $filePath" -ForegroundColor Green
}

# DÃ©finir la taxonomie et les rÃ¨gles de classification pour les tests
$taxonomy = @{
    "Core"    = @{
        Description   = "Scripts fondamentaux du projet"
        SubCategories = @{
            "Initialisation" = "Scripts de dÃ©marrage et configuration"
        }
    }
    "Gestion" = @{
        Description   = "Scripts de gestion et administration"
        SubCategories = @{
            "Admin" = "Administration"
        }
    }
}

$classificationRules = @{
    "Core"    = @{
        Patterns = @("Core")
        Keywords = @("Initialize")
    }
    "Gestion" = @{
        Patterns = @("Gestion")
        Keywords = @("Manage")
    }
}

# ExÃ©cuter les tests manuellement
Write-Host "`nTest 1: Scan du rÃ©pertoire" -ForegroundColor Cyan
$scripts = Get-ScriptInventory -Path $testDir -ForceRescan
Write-Host "Nombre de scripts trouvÃ©s: $($scripts.Count)" -ForegroundColor White
if ($scripts.Count -eq 4) {
    Write-Host "âœ“ Test rÃ©ussi: Le scan a trouvÃ© le bon nombre de scripts" -ForegroundColor Green
} else {
    Write-Host "âœ— Test Ã©chouÃ©: Le scan n'a pas trouvÃ© le bon nombre de scripts" -ForegroundColor Red
}

Write-Host "`nTest 2: Extraction des mÃ©tadonnÃ©es" -ForegroundColor Cyan
$coreScript = $scripts | Where-Object { $_.FileName -eq "Test-Core.ps1" }
Write-Host "MÃ©tadonnÃ©es du script Core:" -ForegroundColor White
Write-Host "  Auteur: $($coreScript.Author)" -ForegroundColor White
Write-Host "  Version: $($coreScript.Version)" -ForegroundColor White
Write-Host "  Description: $($coreScript.Description)" -ForegroundColor White

if ($coreScript.Author -eq "Test Author" -and $coreScript.Version -eq "1.0") {
    Write-Host "âœ“ Test rÃ©ussi: Les mÃ©tadonnÃ©es ont Ã©tÃ© correctement extraites" -ForegroundColor Green
} else {
    Write-Host "âœ— Test Ã©chouÃ©: Les mÃ©tadonnÃ©es n'ont pas Ã©tÃ© correctement extraites" -ForegroundColor Red
}

Write-Host "`nTest 3: DÃ©tection des scripts dupliquÃ©s" -ForegroundColor Cyan
$duplicates = Get-ScriptDuplicates -SimilarityThreshold 100
$duplicateCount = ($duplicates | Where-Object { $_.Type -eq "Duplicate" }).Count
Write-Host "Nombre de scripts dupliquÃ©s dÃ©tectÃ©s: $duplicateCount" -ForegroundColor White

if ($duplicateCount -ge 1) {
    Write-Host "âœ“ Test rÃ©ussi: Les scripts dupliquÃ©s ont Ã©tÃ© dÃ©tectÃ©s" -ForegroundColor Green
} else {
    Write-Host "âœ— Test Ã©chouÃ©: Les scripts dupliquÃ©s n'ont pas Ã©tÃ© dÃ©tectÃ©s" -ForegroundColor Red
}

Write-Host "`nTest 4: Classification des scripts" -ForegroundColor Cyan
$classified = Invoke-ScriptClassification -Taxonomy $taxonomy -ClassificationRules $classificationRules
$coreClassified = ($classified | Where-Object { $_.FileName -eq "Test-Core.ps1" }).Category
$gestionClassified = ($classified | Where-Object { $_.FileName -eq "Test-Gestion.ps1" }).Category

Write-Host "Classification du script Core: $coreClassified" -ForegroundColor White
Write-Host "Classification du script Gestion: $gestionClassified" -ForegroundColor White

if ($coreClassified -eq "Core" -and $gestionClassified -eq "Gestion") {
    Write-Host "âœ“ Test rÃ©ussi: Les scripts ont Ã©tÃ© correctement classifiÃ©s" -ForegroundColor Green
} else {
    Write-Host "âœ— Test Ã©chouÃ©: Les scripts n'ont pas Ã©tÃ© correctement classifiÃ©s" -ForegroundColor Red
}

Write-Host "`nTest 5: Export de l'inventaire" -ForegroundColor Cyan
$csvPath = Join-Path -Path $testDir -ChildPath "inventory.csv"
$htmlPath = Join-Path -Path $testDir -ChildPath "inventory.html"

Export-ScriptInventory -Path $csvPath -Format "CSV"
Export-ScriptInventory -Path $htmlPath -Format "HTML"

if ((Test-Path $csvPath) -and (Test-Path $htmlPath)) {
    Write-Host "âœ“ Test rÃ©ussi: L'inventaire a Ã©tÃ© exportÃ© dans les formats demandÃ©s" -ForegroundColor Green
} else {
    Write-Host "âœ— Test Ã©chouÃ©: L'inventaire n'a pas Ã©tÃ© exportÃ© correctement" -ForegroundColor Red
}

# Nettoyer les fichiers de test
Write-Host "`nNettoyage des fichiers de test..." -ForegroundColor Cyan
Remove-Item -Path $testDir -Recurse -Force
Write-Host "RÃ©pertoire de test supprimÃ©: $testDir" -ForegroundColor Green

# Afficher un rÃ©sumÃ©
Write-Host "`nTests terminÃ©s." -ForegroundColor Green
