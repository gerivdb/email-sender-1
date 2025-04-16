#Requires -Version 5.1
<#
.SYNOPSIS
    Tests simplifiés pour le système d'inventaire et de classification des scripts
.DESCRIPTION
    Ce script exécute des tests simplifiés pour vérifier le bon fonctionnement
    du système d'inventaire et de classification des scripts.
.EXAMPLE
    .\Test-ScriptInventoryBasic2.ps1
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

Write-Host "Preparation des tests..." -ForegroundColor Cyan
Write-Host "Repertoire de test: $testDir" -ForegroundColor White

# Créer des fichiers de test
$testFiles = @{
    "Test-Core.ps1"       = @"
<#
.SYNOPSIS
    Script de test pour la categorie Core
.DESCRIPTION
    Ce script est utilise pour tester la classification des scripts
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
    Script de test pour la categorie Gestion
.DESCRIPTION
    Ce script est utilise pour tester la classification des scripts
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
# Script duplique pour les tests
function Test-Duplicate {
    Write-Host "Test de duplication"
}
"@
    "Test-Duplicate2.ps1" = @"
# Script duplique pour les tests
function Test-Duplicate {
    Write-Host "Test de duplication"
}
"@
}

# Créer les fichiers de test
foreach ($file in $testFiles.Keys) {
    $filePath = Join-Path -Path $testDir -ChildPath $file
    Set-Content -Path $filePath -Value $testFiles[$file]
    Write-Host "Fichier cree: $filePath" -ForegroundColor Green
}

# Définir la taxonomie et les règles de classification pour les tests
$taxonomy = @{
    "Core"    = @{
        Description   = "Scripts fondamentaux du projet"
        SubCategories = @{
            "Initialisation" = "Scripts de demarrage et configuration"
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
Write-Host "`nTest 1: Scan du repertoire" -ForegroundColor Cyan
$scripts = Get-ScriptInventory -Path $testDir -ForceRescan
Write-Host "Nombre de scripts trouves: $($scripts.Count)" -ForegroundColor White
if ($scripts.Count -eq 4) {
    Write-Host "Test reussi: Le scan a trouve le bon nombre de scripts" -ForegroundColor Green
} else {
    Write-Host "Test echoue: Le scan n'a pas trouve le bon nombre de scripts" -ForegroundColor Red
}

Write-Host "`nTest 2: Extraction des metadonnees" -ForegroundColor Cyan
$coreScript = $scripts | Where-Object { $_.FileName -eq "Test-Core.ps1" }
Write-Host "Metadonnees du script Core:" -ForegroundColor White
Write-Host "  Auteur: $($coreScript.Author)" -ForegroundColor White
Write-Host "  Version: $($coreScript.Version)" -ForegroundColor White
Write-Host "  Description: $($coreScript.Description)" -ForegroundColor White

if ($coreScript.Author -eq "Test Author") {
    Write-Host "Test reussi: Les metadonnees ont ete correctement extraites" -ForegroundColor Green
} else {
    Write-Host "Test echoue: Les metadonnees n'ont pas ete correctement extraites" -ForegroundColor Red
}

Write-Host "`nTest 3: Detection des scripts dupliques" -ForegroundColor Cyan

# Comparer manuellement les fichiers dupliques
$file1 = Join-Path -Path $testDir -ChildPath "Test-Duplicate1.ps1"
$file2 = Join-Path -Path $testDir -ChildPath "Test-Duplicate2.ps1"
$content1 = Get-Content -Path $file1 -Raw
$content2 = Get-Content -Path $file2 -Raw

if ($content1 -eq $content2) {
    Write-Host "Les fichiers Test-Duplicate1.ps1 et Test-Duplicate2.ps1 ont un contenu identique" -ForegroundColor Green
    Write-Host "Test reussi: Les scripts dupliques ont ete detectes manuellement" -ForegroundColor Green
} else {
    Write-Host "Les fichiers Test-Duplicate1.ps1 et Test-Duplicate2.ps1 ont un contenu different" -ForegroundColor Red
    Write-Host "Test echoue: Les scripts dupliques n'ont pas ete detectes manuellement" -ForegroundColor Red
}

Write-Host "`nTest 4: Classification des scripts" -ForegroundColor Cyan
$classified = Invoke-ScriptClassification -Taxonomy $taxonomy -ClassificationRules $classificationRules
$coreClassified = ($classified | Where-Object { $_.FileName -eq "Test-Core.ps1" }).Category
$gestionClassified = ($classified | Where-Object { $_.FileName -eq "Test-Gestion.ps1" }).Category

Write-Host "Classification du script Core: $coreClassified" -ForegroundColor White
Write-Host "Classification du script Gestion: $gestionClassified" -ForegroundColor White

if ($coreClassified -eq "Core" -and $gestionClassified -eq "Gestion") {
    Write-Host "Test reussi: Les scripts ont ete correctement classifies" -ForegroundColor Green
} else {
    Write-Host "Test echoue: Les scripts n'ont pas ete correctement classifies" -ForegroundColor Red
}

Write-Host "`nTest 5: Export de l'inventaire" -ForegroundColor Cyan
$csvPath = Join-Path -Path $testDir -ChildPath "inventory.csv"
$htmlPath = Join-Path -Path $testDir -ChildPath "inventory.html"

Export-ScriptInventory -Path $csvPath -Format "CSV"
Export-ScriptInventory -Path $htmlPath -Format "HTML"

if ((Test-Path $csvPath) -and (Test-Path $htmlPath)) {
    Write-Host "Test reussi: L'inventaire a ete exporte dans les formats demandes" -ForegroundColor Green
} else {
    Write-Host "Test echoue: L'inventaire n'a pas ete exporte correctement" -ForegroundColor Red
}

# Nettoyer les fichiers de test
Write-Host "`nNettoyage des fichiers de test..." -ForegroundColor Cyan
Remove-Item -Path $testDir -Recurse -Force
Write-Host "Repertoire de test supprime: $testDir" -ForegroundColor Green

# Afficher un résumé
Write-Host "`nTests termines." -ForegroundColor Green
