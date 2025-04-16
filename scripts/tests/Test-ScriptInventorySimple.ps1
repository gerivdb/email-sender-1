#Requires -Version 5.1
<#
.SYNOPSIS
    Tests simplifiés pour le système d'inventaire et de classification des scripts
.DESCRIPTION
    Ce script exécute des tests simplifiés pour vérifier le bon fonctionnement
    du système d'inventaire et de classification des scripts.
.EXAMPLE
    .\Test-ScriptInventorySimple.ps1
.NOTES
    Auteur: Augment Agent
    Version: 1.0
#>
[CmdletBinding()]
param()

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\ScriptInventoryManager.psm1"
Import-Module $modulePath -Force

# Créer un répertoire de test temporaire
$testDir = Join-Path -Path $env:TEMP -ChildPath "ScriptInventoryTest_$(Get-Random)"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

Write-Host "Préparation des tests..." -ForegroundColor Cyan
Write-Host "Répertoire de test: $testDir" -ForegroundColor White

# Créer des fichiers de test
$testFiles = @{
    "Test-Core.ps1"       = @"
<#
.SYNOPSIS
    Script de test pour la catégorie Core
.DESCRIPTION
    Ce script est utilisé pour tester la classification des scripts
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
    Script de test pour la catégorie Gestion
.DESCRIPTION
    Ce script est utilisé pour tester la classification des scripts
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
# Script dupliqué pour les tests
function Test-Duplicate {
    Write-Host "Test de duplication"
}
"@
    "Test-Duplicate2.ps1" = @"
# Script dupliqué pour les tests
function Test-Duplicate {
    Write-Host "Test de duplication"
}
"@
}

# Créer les fichiers de test
foreach ($file in $testFiles.Keys) {
    $filePath = Join-Path -Path $testDir -ChildPath $file
    Set-Content -Path $filePath -Value $testFiles[$file]
    Write-Host "Fichier créé: $filePath" -ForegroundColor Green
}

# Définir la taxonomie et les règles de classification pour les tests
$taxonomy = @{
    "Core"    = @{
        Description   = "Scripts fondamentaux du projet"
        SubCategories = @{
            "Initialisation" = "Scripts de démarrage et configuration"
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

# Exécuter les tests manuellement
Write-Host "`nTest 1: Scan du répertoire" -ForegroundColor Cyan
$scripts = Get-ScriptInventory -Path $testDir -ForceRescan
Write-Host "Nombre de scripts trouvés: $($scripts.Count)" -ForegroundColor White
if ($scripts.Count -eq 4) {
    Write-Host "✓ Test réussi: Le scan a trouvé le bon nombre de scripts" -ForegroundColor Green
} else {
    Write-Host "✗ Test échoué: Le scan n'a pas trouvé le bon nombre de scripts" -ForegroundColor Red
}

Write-Host "`nTest 2: Extraction des métadonnées" -ForegroundColor Cyan
$coreScript = $scripts | Where-Object { $_.FileName -eq "Test-Core.ps1" }
Write-Host "Métadonnées du script Core:" -ForegroundColor White
Write-Host "  Auteur: $($coreScript.Author)" -ForegroundColor White
Write-Host "  Version: $($coreScript.Version)" -ForegroundColor White
Write-Host "  Description: $($coreScript.Description)" -ForegroundColor White

if ($coreScript.Author -eq "Test Author" -and $coreScript.Version -eq "1.0") {
    Write-Host "✓ Test réussi: Les métadonnées ont été correctement extraites" -ForegroundColor Green
} else {
    Write-Host "✗ Test échoué: Les métadonnées n'ont pas été correctement extraites" -ForegroundColor Red
}

Write-Host "`nTest 3: Détection des scripts dupliqués" -ForegroundColor Cyan
$duplicates = Get-ScriptDuplicates -SimilarityThreshold 100
$duplicateCount = ($duplicates | Where-Object { $_.Type -eq "Duplicate" }).Count
Write-Host "Nombre de scripts dupliqués détectés: $duplicateCount" -ForegroundColor White

if ($duplicateCount -ge 1) {
    Write-Host "✓ Test réussi: Les scripts dupliqués ont été détectés" -ForegroundColor Green
} else {
    Write-Host "✗ Test échoué: Les scripts dupliqués n'ont pas été détectés" -ForegroundColor Red
}

Write-Host "`nTest 4: Classification des scripts" -ForegroundColor Cyan
$classified = Invoke-ScriptClassification -Taxonomy $taxonomy -ClassificationRules $classificationRules
$coreClassified = ($classified | Where-Object { $_.FileName -eq "Test-Core.ps1" }).Category
$gestionClassified = ($classified | Where-Object { $_.FileName -eq "Test-Gestion.ps1" }).Category

Write-Host "Classification du script Core: $coreClassified" -ForegroundColor White
Write-Host "Classification du script Gestion: $gestionClassified" -ForegroundColor White

if ($coreClassified -eq "Core" -and $gestionClassified -eq "Gestion") {
    Write-Host "✓ Test réussi: Les scripts ont été correctement classifiés" -ForegroundColor Green
} else {
    Write-Host "✗ Test échoué: Les scripts n'ont pas été correctement classifiés" -ForegroundColor Red
}

Write-Host "`nTest 5: Export de l'inventaire" -ForegroundColor Cyan
$csvPath = Join-Path -Path $testDir -ChildPath "inventory.csv"
$htmlPath = Join-Path -Path $testDir -ChildPath "inventory.html"

Export-ScriptInventory -Path $csvPath -Format "CSV"
Export-ScriptInventory -Path $htmlPath -Format "HTML"

if ((Test-Path $csvPath) -and (Test-Path $htmlPath)) {
    Write-Host "✓ Test réussi: L'inventaire a été exporté dans les formats demandés" -ForegroundColor Green
} else {
    Write-Host "✗ Test échoué: L'inventaire n'a pas été exporté correctement" -ForegroundColor Red
}

# Nettoyer les fichiers de test
Write-Host "`nNettoyage des fichiers de test..." -ForegroundColor Cyan
Remove-Item -Path $testDir -Recurse -Force
Write-Host "Répertoire de test supprimé: $testDir" -ForegroundColor Green

# Afficher un résumé
Write-Host "`nTests terminés." -ForegroundColor Green
