#Requires -Version 5.1
<#
.SYNOPSIS
    Classifie automatiquement les scripts en fonction de leur contenu
.DESCRIPTION
    Ce script analyse le contenu des scripts et les classifie automatiquement
    en fonction de règles prédéfinies et de l'apprentissage à partir des
    classifications existantes.
.PARAMETER Path
    Chemin du répertoire à analyser
.PARAMETER UpdateStructure
    Indique s'il faut mettre à jour la structure des dossiers
.PARAMETER Force
    Indique s'il faut forcer la reclassification des scripts déjà classifiés
.EXAMPLE
    .\Auto-ClassifyScripts.ps1 -Path "C:\Scripts" -UpdateStructure
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Tags: classification, scripts, automation
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [switch]$UpdateStructure,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer les modules nécessaires
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\ScriptInventoryManager.psm1"
Import-Module $modulePath -Force

# Définir la taxonomie des scripts
$taxonomy = @{
    "Core" = @{
        Description = "Scripts fondamentaux du projet"
        SubCategories = @{
            "Initialisation" = "Scripts de démarrage et configuration"
            "Configuration" = "Scripts de configuration"
            "Utilitaires" = "Scripts utilitaires génériques"
        }
    }
    "Analyse" = @{
        Description = "Scripts d'analyse et de traitement de données"
        SubCategories = @{
            "Données" = "Scripts de traitement de données"
            "Rapports" = "Scripts de génération de rapports"
            "Statistiques" = "Scripts de calcul de statistiques"
        }
    }
    "Gestion" = @{
        Description = "Scripts de gestion et d'administration"
        SubCategories = @{
            "Utilisateurs" = "Scripts de gestion des utilisateurs"
            "Système" = "Scripts de gestion du système"
            "Réseau" = "Scripts de gestion du réseau"
        }
    }
    "Interface" = @{
        Description = "Scripts d'interface utilisateur"
        SubCategories = @{
            "GUI" = "Interfaces graphiques"
            "Web" = "Interfaces web"
            "Console" = "Interfaces console"
        }
    }
    "Intégration" = @{
        Description = "Scripts d'intégration avec d'autres systèmes"
        SubCategories = @{
            "API" = "Intégrations API"
            "Base de données" = "Intégrations avec des bases de données"
            "Services" = "Intégrations avec des services externes"
        }
    }
    "Tests" = @{
        Description = "Scripts de tests"
        SubCategories = @{
            "Unitaires" = "Tests unitaires"
            "Intégration" = "Tests d'intégration"
            "Performance" = "Tests de performance"
        }
    }
    "Documentation" = @{
        Description = "Scripts de documentation"
        SubCategories = @{
            "Générateurs" = "Générateurs de documentation"
            "Rapports" = "Rapports de documentation"
        }
    }
    "Automatisation" = @{
        Description = "Scripts d'automatisation"
        SubCategories = @{
            "Tâches" = "Automatisation de tâches"
            "Déploiement" = "Automatisation de déploiement"
            "Surveillance" = "Automatisation de surveillance"
        }
    }
}

# Définir les règles de classification
$classificationRules = @{
    "Core" = @{
        Patterns = @("Init", "Config", "Setup", "Core", "Base", "Common", "Util")
        Keywords = @("Initialize", "Configuration", "Setup", "Core", "Base", "Common", "Utility")
    }
    "Analyse" = @{
        Patterns = @("Analyze", "Report", "Data", "Stat", "Process")
        Keywords = @("Analyze", "Report", "Data", "Statistics", "Process")
    }
    "Gestion" = @{
        Patterns = @("Manage", "Admin", "User", "System", "Network")
        Keywords = @("Manage", "Admin", "User", "System", "Network")
    }
    "Interface" = @{
        Patterns = @("GUI", "UI", "Interface", "Web", "Console", "Form")
        Keywords = @("GUI", "UI", "Interface", "Web", "Console", "Form", "Window", "Dialog")
    }
    "Intégration" = @{
        Patterns = @("API", "Integration", "Connect", "DB", "Database", "Service")
        Keywords = @("API", "Integration", "Connect", "Database", "Service", "External")
    }
    "Tests" = @{
        Patterns = @("Test", "Spec", "Mock", "Benchmark", "Performance")
        Keywords = @("Test", "Assert", "Mock", "Benchmark", "Performance")
    }
    "Documentation" = @{
        Patterns = @("Doc", "Documentation", "ReadMe", "Help")
        Keywords = @("Documentation", "Generate", "Help", "Manual")
    }
    "Automatisation" = @{
        Patterns = @("Auto", "Task", "Schedule", "Deploy", "Monitor")
        Keywords = @("Automation", "Task", "Schedule", "Deploy", "Monitor")
    }
}

# Fonction pour apprendre des classifications existantes
function Learn-Classifications {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Scripts
    )
    
    $classifiedScripts = $Scripts | Where-Object { $_.Category -ne "Non classé" }
    
    if ($classifiedScripts.Count -eq 0) {
        Write-Host "Aucun script classifié trouvé pour l'apprentissage." -ForegroundColor Yellow
        return $classificationRules
    }
    
    Write-Host "Apprentissage à partir de $($classifiedScripts.Count) scripts classifiés..." -ForegroundColor Cyan
    
    # Améliorer les règles de classification en fonction des scripts déjà classifiés
    foreach ($script in $classifiedScripts) {
        $category = $script.Category
        $content = Get-Content -Path $script.FullPath -Raw -ErrorAction SilentlyContinue
        
        if (-not $content) {
            continue
        }
        
        # Extraire les mots significatifs du contenu
        $words = $content -split '\W+' | Where-Object { $_.Length -gt 4 } | Select-Object -Unique
        
        # Ajouter les mots significatifs aux règles de classification
        if ($classificationRules.ContainsKey($category)) {
            # Ajouter le nom du fichier aux patterns
            $fileName = [System.IO.Path]::GetFileNameWithoutExtension($script.FileName)
            if (-not $classificationRules[$category].Patterns.Contains($fileName)) {
                $classificationRules[$category].Patterns += $fileName
            }
            
            # Ajouter les mots significatifs aux keywords
            foreach ($word in $words) {
                if (-not $classificationRules[$category].Keywords.Contains($word)) {
                    $classificationRules[$category].Keywords += $word
                }
            }
        }
    }
    
    return $classificationRules
}

# Fonction pour suggérer une classification
function Get-SuggestedClassification {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Rules
    )
    
    $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    
    if (-not $content) {
        return @{
            Category = "Non classé"
            SubCategory = "Autre"
            Confidence = 0
        }
    }
    
    $scores = @{}
    
    # Calculer les scores pour chaque catégorie
    foreach ($category in $Rules.Keys) {
        $score = 0
        
        # Vérifier les patterns dans le nom
        foreach ($pattern in $Rules[$category].Patterns) {
            if ($FileName -like "*$pattern*") {
                $score += 10
            }
        }
        
        # Vérifier les keywords dans le contenu
        foreach ($keyword in $Rules[$category].Keywords) {
            if ($content -match $keyword) {
                $score += 5
            }
        }
        
        $scores[$category] = $score
    }
    
    # Trouver la catégorie avec le score le plus élevé
    $bestCategory = $scores.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1
    
    if ($bestCategory.Value -eq 0) {
        return @{
            Category = "Non classé"
            SubCategory = "Autre"
            Confidence = 0
        }
    }
    
    # Trouver la sous-catégorie la plus appropriée
    $subCategory = "Autre"
    $subCategoryScore = 0
    
    if ($taxonomy[$bestCategory.Name].SubCategories) {
        foreach ($subCat in $taxonomy[$bestCategory.Name].SubCategories.Keys) {
            $subScore = 0
            
            if ($FileName -like "*$subCat*") {
                $subScore += 10
            }
            
            if ($content -match $subCat) {
                $subScore += 5
            }
            
            if ($subScore -gt $subCategoryScore) {
                $subCategory = $subCat
                $subCategoryScore = $subScore
            }
        }
    }
    
    # Calculer la confiance (0-100%)
    $confidence = [Math]::Min(100, ($bestCategory.Value / 20) * 100)
    
    return @{
        Category = $bestCategory.Name
        SubCategory = $subCategory
        Confidence = $confidence
    }
}

# Récupérer les scripts
Write-Host "Récupération des scripts..." -ForegroundColor Cyan
$scripts = Get-ScriptInventory -Path $Path

# Vérifier qu'il y a des scripts
if (-not $scripts -or $scripts.Count -eq 0) {
    Write-Host "Aucun script trouvé dans le répertoire spécifié." -ForegroundColor Red
    exit
}

# Apprendre des classifications existantes
$enhancedRules = Learn-Classifications -Scripts $scripts

# Classifier les scripts
$scriptsToClassify = if ($Force) { $scripts } else { $scripts | Where-Object { $_.Category -eq "Non classé" } }

if ($scriptsToClassify.Count -eq 0) {
    Write-Host "Aucun script à classifier." -ForegroundColor Yellow
    exit
}

Write-Host "Classification de $($scriptsToClassify.Count) scripts..." -ForegroundColor Cyan

$classified = 0
$moved = 0
$results = @()

foreach ($script in $scriptsToClassify) {
    # Suggérer une classification
    $suggestion = Get-SuggestedClassification -FilePath $script.FullPath -FileName $script.FileName -Rules $enhancedRules
    
    # Mettre à jour la classification du script
    if ($suggestion.Category -ne "Non classé" -and $suggestion.Confidence -gt 50) {
        $script.Category = $suggestion.Category
        $script.SubCategory = $suggestion.SubCategory
        $classified++
        
        # Créer un objet résultat
        $result = [PSCustomObject]@{
            FileName = $script.FileName
            OldCategory = "Non classé"
            NewCategory = $suggestion.Category
            SubCategory = $suggestion.SubCategory
            Confidence = "$($suggestion.Confidence)%"
            Path = $script.FullPath
            NewPath = if ($UpdateStructure) {
                Join-Path -Path $Path -ChildPath "$($suggestion.Category)\$($suggestion.SubCategory)\$($script.FileName)"
            } else {
                ""
            }
        }
        
        $results += $result
        
        # Déplacer le script si demandé
        if ($UpdateStructure) {
            $newDir = Join-Path -Path $Path -ChildPath "$($suggestion.Category)\$($suggestion.SubCategory)"
            $newPath = Join-Path -Path $newDir -ChildPath $script.FileName
            
            # Créer le répertoire s'il n'existe pas
            if (-not (Test-Path $newDir)) {
                New-Item -ItemType Directory -Path $newDir -Force | Out-Null
            }
            
            # Déplacer le fichier
            if ($script.FullPath -ne $newPath) {
                try {
                    Move-Item -Path $script.FullPath -Destination $newPath -Force
                    $moved++
                    Write-Host "Script déplacé: $($script.FullPath) -> $newPath" -ForegroundColor Green
                }
                catch {
                    Write-Host "Erreur lors du déplacement du script: $_" -ForegroundColor Red
                }
            }
        }
    }
}

# Sauvegarder l'inventaire mis à jour
if ($classified -gt 0) {
    [ScriptInventory]::SaveInventory()
}

# Afficher les résultats
if ($results.Count -gt 0) {
    Write-Host "`nRésultats de la classification:" -ForegroundColor Cyan
    $results | Format-Table -Property FileName, NewCategory, SubCategory, Confidence -AutoSize
}

# Afficher un résumé
Write-Host "`nRésumé:" -ForegroundColor Cyan
Write-Host "- $classified scripts classifiés" -ForegroundColor Green
if ($UpdateStructure) {
    Write-Host "- $moved scripts déplacés" -ForegroundColor Green
}

# Exporter les résultats
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputPath = Join-Path -Path $Path -ChildPath "reports\classification_$timestamp.csv"

# Créer le répertoire de rapports s'il n'existe pas
$reportsDir = Split-Path -Parent $outputPath
if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

if ($results.Count -gt 0) {
    $results | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Rapport exporté: $outputPath" -ForegroundColor Green
}
