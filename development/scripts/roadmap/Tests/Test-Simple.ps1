# Test-Simple.ps1
# Script de test simple pour vérifier le fonctionnement de base
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Teste le fonctionnement de base des modules de roadmap.

.DESCRIPTION
    Ce script teste le fonctionnement de base des modules de roadmap,
    en vérifiant que les fonctions principales fonctionnent correctement.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
$generationPath = Join-Path -Path $parentPath -ChildPath "generation"
$analysisPath = Join-Path -Path $parentPath -ChildPath "analysis"

$parseRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Parse-Roadmap.ps1"
$generateRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Generate-Roadmap.ps1"
$analyzeRoadmapPath = Join-Path -Path $analysisPath -ChildPath "Analyze-RoadmapStructure.ps1"
$generateRealisticRoadmapPath = Join-Path -Path $generationPath -ChildPath "Generate-RealisticRoadmap.ps1"

Write-Host "Chargement des modules..." -ForegroundColor Cyan

if (Test-Path $parseRoadmapPath) {
    Write-Host "  Chargement de Parse-Roadmap.ps1..." -ForegroundColor Gray
    . $parseRoadmapPath
    Write-Host "  Module Parse-Roadmap.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Parse-Roadmap.ps1 introuvable à l'emplacement: $parseRoadmapPath" -ForegroundColor Red
}

if (Test-Path $generateRoadmapPath) {
    Write-Host "  Chargement de Generate-Roadmap.ps1..." -ForegroundColor Gray
    . $generateRoadmapPath
    Write-Host "  Module Generate-Roadmap.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Generate-Roadmap.ps1 introuvable à l'emplacement: $generateRoadmapPath" -ForegroundColor Red
}

if (Test-Path $analyzeRoadmapPath) {
    Write-Host "  Chargement de Analyze-RoadmapStructure.ps1..." -ForegroundColor Gray
    . $analyzeRoadmapPath
    Write-Host "  Module Analyze-RoadmapStructure.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Analyze-RoadmapStructure.ps1 introuvable à l'emplacement: $analyzeRoadmapPath" -ForegroundColor Red
}

if (Test-Path $generateRealisticRoadmapPath) {
    Write-Host "  Chargement de Generate-RealisticRoadmap.ps1..." -ForegroundColor Gray
    . $generateRealisticRoadmapPath
    Write-Host "  Module Generate-RealisticRoadmap.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Generate-RealisticRoadmap.ps1 introuvable à l'emplacement: $generateRealisticRoadmapPath" -ForegroundColor Red
}

# Créer un dossier de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapTests"
if (-not (Test-Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

Write-Host "Dossier de test créé: $testDir" -ForegroundColor Cyan

# Test 1: Générer une roadmap vide
Write-Host "`nTest 1: Générer une roadmap vide" -ForegroundColor Yellow
$emptyRoadmapPath = Join-Path -Path $testDir -ChildPath "empty-roadmap.md"

try {
    $result = New-EmptyRoadmap -Title "Roadmap de test vide" -Description "Une roadmap vide pour les tests" -OutputPath $emptyRoadmapPath
    
    if (Test-Path $emptyRoadmapPath) {
        Write-Host "  Succès: Roadmap vide générée correctement." -ForegroundColor Green
        Write-Host "  Fichier: $emptyRoadmapPath" -ForegroundColor Gray
    } else {
        Write-Host "  Échec: Le fichier de roadmap n'a pas été créé." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur lors de la génération de la roadmap vide: $_" -ForegroundColor Red
}

# Test 2: Parser une roadmap
Write-Host "`nTest 2: Parser une roadmap" -ForegroundColor Yellow

try {
    if (Test-Path $emptyRoadmapPath) {
        $result = Parse-RoadmapFile -FilePath $emptyRoadmapPath
        
        if ($null -ne $result) {
            Write-Host "  Succès: Roadmap parsée correctement." -ForegroundColor Green
            Write-Host "  Titre: $($result.Title)" -ForegroundColor Gray
            Write-Host "  Nombre de tâches: $($result.Tasks.Count)" -ForegroundColor Gray
        } else {
            Write-Host "  Échec: Échec du parsing de la roadmap." -ForegroundColor Red
        }
    } else {
        Write-Host "  Ignoré: Le fichier de roadmap n'existe pas." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Erreur lors du parsing de la roadmap: $_" -ForegroundColor Red
}

# Test 3: Analyser une roadmap
Write-Host "`nTest 3: Analyser une roadmap" -ForegroundColor Yellow

try {
    if (Test-Path $emptyRoadmapPath) {
        $result = Get-RoadmapStructuralStatistics -RoadmapPath $emptyRoadmapPath
        
        if ($null -ne $result) {
            Write-Host "  Succès: Roadmap analysée correctement." -ForegroundColor Green
            Write-Host "  Nombre total de tâches: $($result.TotalTasks)" -ForegroundColor Gray
            Write-Host "  Profondeur maximale: $($result.MaxDepth)" -ForegroundColor Gray
        } else {
            Write-Host "  Échec: Échec de l'analyse de la roadmap." -ForegroundColor Red
        }
    } else {
        Write-Host "  Ignoré: Le fichier de roadmap n'existe pas." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Erreur lors de l'analyse de la roadmap: $_" -ForegroundColor Red
}

# Test 4: Générer une roadmap réaliste
Write-Host "`nTest 4: Générer une roadmap réaliste" -ForegroundColor Yellow

try {
    if (Test-Path $emptyRoadmapPath) {
        $modelOutputDir = Join-Path -Path $testDir -ChildPath "Models"
        $realisticRoadmapPath = Join-Path -Path $testDir -ChildPath "realistic-roadmap.md"
        
        # Créer un modèle statistique
        $model = New-RoadmapStatisticalModel -RoadmapPaths @($emptyRoadmapPath) -ModelName "TestModel" -OutputPath $modelOutputDir
        
        if ($null -ne $model) {
            Write-Host "  Succès: Modèle statistique créé correctement." -ForegroundColor Green
            
            # Générer une roadmap réaliste
            $result = New-RealisticRoadmap -Model $model -Title "Roadmap réaliste de test" -OutputPath $realisticRoadmapPath -ThematicContext "Système de test"
            
            if (Test-Path $realisticRoadmapPath) {
                Write-Host "  Succès: Roadmap réaliste générée correctement." -ForegroundColor Green
                Write-Host "  Fichier: $realisticRoadmapPath" -ForegroundColor Gray
            } else {
                Write-Host "  Échec: Le fichier de roadmap réaliste n'a pas été créé." -ForegroundColor Red
            }
        } else {
            Write-Host "  Échec: Échec de la création du modèle statistique." -ForegroundColor Red
        }
    } else {
        Write-Host "  Ignoré: Le fichier de roadmap n'existe pas." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Erreur lors de la génération de la roadmap réaliste: $_" -ForegroundColor Red
}

# Nettoyer les fichiers de test
Write-Host "`nNettoyage des fichiers de test..." -ForegroundColor Cyan
if (Test-Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
    Write-Host "Nettoyage terminé." -ForegroundColor Green
}

Write-Host "`nTests terminés." -ForegroundColor Cyan
