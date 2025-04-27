#Requires -Version 5.1
<#
.SYNOPSIS
    Classifie automatiquement les scripts en fonction de leur contenu
.DESCRIPTION
    Ce script analyse le contenu des scripts et les classifie automatiquement
    en fonction de rÃ¨gles prÃ©dÃ©finies et de l'apprentissage Ã  partir des
    classifications existantes.
.PARAMETER Path
    Chemin du rÃ©pertoire Ã  analyser
.PARAMETER UpdateStructure
    Indique s'il faut mettre Ã  jour la structure des dossiers
.PARAMETER Force
    Indique s'il faut forcer la reclassification des scripts dÃ©jÃ  classifiÃ©s
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

# Importer les modules nÃ©cessaires
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\ScriptInventoryManager.psm1"
Import-Module $modulePath -Force

# DÃ©finir la taxonomie des scripts
$taxonomy = @{
    "Core" = @{
        Description = "Scripts fondamentaux du projet"
        SubCategories = @{
            "Initialisation" = "Scripts de dÃ©marrage et configuration"
            "Configuration" = "Scripts de configuration"
            "Utilitaires" = "Scripts utilitaires gÃ©nÃ©riques"
        }
    }
    "Analyse" = @{
        Description = "Scripts d'analyse et de traitement de donnÃ©es"
        SubCategories = @{
            "DonnÃ©es" = "Scripts de traitement de donnÃ©es"
            "Rapports" = "Scripts de gÃ©nÃ©ration de rapports"
            "Statistiques" = "Scripts de calcul de statistiques"
        }
    }
    "Gestion" = @{
        Description = "Scripts de gestion et d'administration"
        SubCategories = @{
            "Utilisateurs" = "Scripts de gestion des utilisateurs"
            "SystÃ¨me" = "Scripts de gestion du systÃ¨me"
            "RÃ©seau" = "Scripts de gestion du rÃ©seau"
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
    "IntÃ©gration" = @{
        Description = "Scripts d'intÃ©gration avec d'autres systÃ¨mes"
        SubCategories = @{
            "API" = "IntÃ©grations API"
            "Base de donnÃ©es" = "IntÃ©grations avec des bases de donnÃ©es"
            "Services" = "IntÃ©grations avec des services externes"
        }
    }
    "Tests" = @{
        Description = "Scripts de tests"
        SubCategories = @{
            "Unitaires" = "Tests unitaires"
            "IntÃ©gration" = "Tests d'intÃ©gration"
            "Performance" = "Tests de performance"
        }
    }
    "Documentation" = @{
        Description = "Scripts de documentation"
        SubCategories = @{
            "GÃ©nÃ©rateurs" = "GÃ©nÃ©rateurs de documentation"
            "Rapports" = "Rapports de documentation"
        }
    }
    "Automatisation" = @{
        Description = "Scripts d'automatisation"
        SubCategories = @{
            "TÃ¢ches" = "Automatisation de tÃ¢ches"
            "DÃ©ploiement" = "Automatisation de dÃ©ploiement"
            "Surveillance" = "Automatisation de surveillance"
        }
    }
}

# DÃ©finir les rÃ¨gles de classification
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
    "IntÃ©gration" = @{
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
    
    $classifiedScripts = $Scripts | Where-Object { $_.Category -ne "Non classÃ©" }
    
    if ($classifiedScripts.Count -eq 0) {
        Write-Host "Aucun script classifiÃ© trouvÃ© pour l'apprentissage." -ForegroundColor Yellow
        return $classificationRules
    }
    
    Write-Host "Apprentissage Ã  partir de $($classifiedScripts.Count) scripts classifiÃ©s..." -ForegroundColor Cyan
    
    # AmÃ©liorer les rÃ¨gles de classification en fonction des scripts dÃ©jÃ  classifiÃ©s
    foreach ($script in $classifiedScripts) {
        $category = $script.Category
        $content = Get-Content -Path $script.FullPath -Raw -ErrorAction SilentlyContinue
        
        if (-not $content) {
            continue
        }
        
        # Extraire les mots significatifs du contenu
        $words = $content -split '\W+' | Where-Object { $_.Length -gt 4 } | Select-Object -Unique
        
        # Ajouter les mots significatifs aux rÃ¨gles de classification
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

# Fonction pour suggÃ©rer une classification
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
            Category = "Non classÃ©"
            SubCategory = "Autre"
            Confidence = 0
        }
    }
    
    $scores = @{}
    
    # Calculer les scores pour chaque catÃ©gorie
    foreach ($category in $Rules.Keys) {
        $score = 0
        
        # VÃ©rifier les patterns dans le nom
        foreach ($pattern in $Rules[$category].Patterns) {
            if ($FileName -like "*$pattern*") {
                $score += 10
            }
        }
        
        # VÃ©rifier les keywords dans le contenu
        foreach ($keyword in $Rules[$category].Keywords) {
            if ($content -match $keyword) {
                $score += 5
            }
        }
        
        $scores[$category] = $score
    }
    
    # Trouver la catÃ©gorie avec le score le plus Ã©levÃ©
    $bestCategory = $scores.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1
    
    if ($bestCategory.Value -eq 0) {
        return @{
            Category = "Non classÃ©"
            SubCategory = "Autre"
            Confidence = 0
        }
    }
    
    # Trouver la sous-catÃ©gorie la plus appropriÃ©e
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

# RÃ©cupÃ©rer les scripts
Write-Host "RÃ©cupÃ©ration des scripts..." -ForegroundColor Cyan
$scripts = Get-ScriptInventory -Path $Path

# VÃ©rifier qu'il y a des scripts
if (-not $scripts -or $scripts.Count -eq 0) {
    Write-Host "Aucun script trouvÃ© dans le rÃ©pertoire spÃ©cifiÃ©." -ForegroundColor Red
    exit
}

# Apprendre des classifications existantes
$enhancedRules = Learn-Classifications -Scripts $scripts

# Classifier les scripts
$scriptsToClassify = if ($Force) { $scripts } else { $scripts | Where-Object { $_.Category -eq "Non classÃ©" } }

if ($scriptsToClassify.Count -eq 0) {
    Write-Host "Aucun script Ã  classifier." -ForegroundColor Yellow
    exit
}

Write-Host "Classification de $($scriptsToClassify.Count) scripts..." -ForegroundColor Cyan

$classified = 0
$moved = 0
$results = @()

foreach ($script in $scriptsToClassify) {
    # SuggÃ©rer une classification
    $suggestion = Get-SuggestedClassification -FilePath $script.FullPath -FileName $script.FileName -Rules $enhancedRules
    
    # Mettre Ã  jour la classification du script
    if ($suggestion.Category -ne "Non classÃ©" -and $suggestion.Confidence -gt 50) {
        $script.Category = $suggestion.Category
        $script.SubCategory = $suggestion.SubCategory
        $classified++
        
        # CrÃ©er un objet rÃ©sultat
        $result = [PSCustomObject]@{
            FileName = $script.FileName
            OldCategory = "Non classÃ©"
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
        
        # DÃ©placer le script si demandÃ©
        if ($UpdateStructure) {
            $newDir = Join-Path -Path $Path -ChildPath "$($suggestion.Category)\$($suggestion.SubCategory)"
            $newPath = Join-Path -Path $newDir -ChildPath $script.FileName
            
            # CrÃ©er le rÃ©pertoire s'il n'existe pas
            if (-not (Test-Path $newDir)) {
                New-Item -ItemType Directory -Path $newDir -Force | Out-Null
            }
            
            # DÃ©placer le fichier
            if ($script.FullPath -ne $newPath) {
                try {
                    Move-Item -Path $script.FullPath -Destination $newPath -Force
                    $moved++
                    Write-Host "Script dÃ©placÃ©: $($script.FullPath) -> $newPath" -ForegroundColor Green
                }
                catch {
                    Write-Host "Erreur lors du dÃ©placement du script: $_" -ForegroundColor Red
                }
            }
        }
    }
}

# Sauvegarder l'inventaire mis Ã  jour
if ($classified -gt 0) {
    [ScriptInventory]::SaveInventory()
}

# Afficher les rÃ©sultats
if ($results.Count -gt 0) {
    Write-Host "`nRÃ©sultats de la classification:" -ForegroundColor Cyan
    $results | Format-Table -Property FileName, NewCategory, SubCategory, Confidence -AutoSize
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ©:" -ForegroundColor Cyan
Write-Host "- $classified scripts classifiÃ©s" -ForegroundColor Green
if ($UpdateStructure) {
    Write-Host "- $moved scripts dÃ©placÃ©s" -ForegroundColor Green
}

# Exporter les rÃ©sultats
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputPath = Join-Path -Path $Path -ChildPath "reports\classification_$timestamp.csv"

# CrÃ©er le rÃ©pertoire de rapports s'il n'existe pas
$reportsDir = Split-Path -Parent $outputPath
if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

if ($results.Count -gt 0) {
    $results | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Rapport exportÃ©: $outputPath" -ForegroundColor Green
}
