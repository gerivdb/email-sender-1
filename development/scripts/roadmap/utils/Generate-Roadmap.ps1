# Generate-Roadmap.ps1
# Module pour générer des roadmaps au format markdown
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Génère des roadmaps au format markdown.

.DESCRIPTION
    Ce module fournit des fonctions pour générer des roadmaps au format markdown,
    en créant la structure hiérarchique des tâches, les statuts, les métadonnées, etc.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parseRoadmapPath = Join-Path -Path $scriptPath -ChildPath "Parse-Roadmap.ps1"

if (Test-Path $parseRoadmapPath) {
    . $parseRoadmapPath
} else {
    Write-Warning "Module Parse-Roadmap.ps1 introuvable à l'emplacement: $parseRoadmapPath"
}

# Fonction pour générer une roadmap vide
function New-EmptyRoadmap {
    <#
    .SYNOPSIS
        Génère une roadmap vide au format markdown.

    .DESCRIPTION
        Cette fonction génère une roadmap vide au format markdown,
        avec un titre, une description et une structure de base.

    .PARAMETER Title
        Le titre de la roadmap.

    .PARAMETER Description
        La description de la roadmap.

    .PARAMETER Author
        L'auteur de la roadmap.

    .PARAMETER Tags
        Les tags/thèmes de la roadmap.

    .PARAMETER OutputPath
        Le chemin où sauvegarder la roadmap générée.

    .EXAMPLE
        New-EmptyRoadmap -Title "Plan de développement v10" -Description "Plan pour la version 10" -Author "Équipe de développement" -Tags "Développement", "Planification" -OutputPath "C:\Roadmaps\plan-dev-v10.md"
        Génère une roadmap vide avec les paramètres spécifiés.

    .OUTPUTS
        String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [string]$Description = "",

        [Parameter(Mandatory = $false)]
        [string]$Author = "Équipe de développement",

        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @(),

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Générer le contenu de la roadmap
    $date = Get-Date -Format "yyyy-MM-dd"
    $tagsString = if ($Tags.Count -gt 0) { $Tags -join ", " } else { "" }
    
    $content = @"
# $Title

**Date:** $date  
**Auteur:** $Author  
**Tags:** $tagsString

## Description

$Description

## 1. Première section
- [ ] **1.1** Première tâche
  - [ ] **1.1.1** Première sous-tâche
  - [ ] **1.1.2** Deuxième sous-tâche
- [ ] **1.2** Deuxième tâche
  - [ ] **1.2.1** Première sous-tâche
  - [ ] **1.2.2** Deuxième sous-tâche

## 2. Deuxième section
- [ ] **2.1** Première tâche
  - [ ] **2.1.1** Première sous-tâche
  - [ ] **2.1.2** Deuxième sous-tâche
- [ ] **2.2** Deuxième tâche
  - [ ] **2.2.1** Première sous-tâche
  - [ ] **2.2.2** Deuxième sous-tâche
"@
    
    # Sauvegarder la roadmap si un chemin est spécifié
    if ($OutputPath) {
        # Créer le dossier de sortie s'il n'existe pas
        $outputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Écrire le contenu dans le fichier
        $content | Out-File -FilePath $OutputPath -Encoding utf8
        
        Write-Host "Roadmap vide générée et sauvegardée dans: $OutputPath"
    }
    
    return $content
}

# Fonction pour générer une roadmap à partir d'une structure de tâches
function New-RoadmapFromTasks {
    <#
    .SYNOPSIS
        Génère une roadmap à partir d'une structure de tâches.

    .DESCRIPTION
        Cette fonction génère une roadmap au format markdown à partir d'une structure de tâches,
        en créant la hiérarchie, les statuts, les métadonnées, etc.

    .PARAMETER Title
        Le titre de la roadmap.

    .PARAMETER Tasks
        Les tâches à inclure dans la roadmap.

    .PARAMETER Description
        La description de la roadmap.

    .PARAMETER Author
        L'auteur de la roadmap.

    .PARAMETER Tags
        Les tags/thèmes de la roadmap.

    .PARAMETER OutputPath
        Le chemin où sauvegarder la roadmap générée.

    .EXAMPLE
        New-RoadmapFromTasks -Title "Plan de développement v10" -Tasks $tasks -OutputPath "C:\Roadmaps\plan-dev-v10.md"
        Génère une roadmap à partir des tâches spécifiées.

    .OUTPUTS
        String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [PSObject[]]$Tasks,

        [Parameter(Mandatory = $false)]
        [string]$Description = "",

        [Parameter(Mandatory = $false)]
        [string]$Author = "Équipe de développement",

        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @(),

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Générer l'en-tête de la roadmap
    $date = Get-Date -Format "yyyy-MM-dd"
    $tagsString = if ($Tags.Count -gt 0) { $Tags -join ", " } else { "" }
    
    $content = @"
# $Title

**Date:** $date  
**Auteur:** $Author  
**Tags:** $tagsString

## Description

$Description

"@
    
    # Trier les tâches par ID
    $sortedTasks = $Tasks | Sort-Object -Property Id
    
    # Regrouper les tâches de niveau 1 (sections principales)
    $sections = $sortedTasks | Where-Object { $_.Level -eq 1 -or $_.Id.Split('.').Count -eq 1 }
    
    foreach ($section in $sections) {
        $content += "## $($section.Id) $($section.Title)`n"
        
        if ($section.Description) {
            $content += "$($section.Description)`n`n"
        }
        
        # Fonction récursive pour ajouter les sous-tâches
        function Add-TasksToContent {
            param (
                [PSObject]$ParentTask,
                [PSObject[]]$AllTasks,
                [int]$Indent = 0
            )
            
            $childrenIds = $ParentTask.Children
            if (-not $childrenIds -and $ParentTask.Id) {
                # Si les enfants ne sont pas explicitement définis, les trouver par ID
                $childrenIds = $AllTasks | 
                    Where-Object { $_.ParentId -eq $ParentTask.Id } | 
                    Select-Object -ExpandProperty Id
            }
            
            $childTasks = $AllTasks | 
                Where-Object { $childrenIds -contains $_.Id } | 
                Sort-Object -Property Id
            
            $result = ""
            
            foreach ($childTask in $childTasks) {
                $indentation = "  " * $Indent
                $checkbox = if ($childTask.Status -eq "Completed") { "[x]" } else { "[ ]" }
                
                $result += "$indentation- $checkbox **$($childTask.Id)** $($childTask.Title)`n"
                
                if ($childTask.Description) {
                    $result += "$indentation  $($childTask.Description)`n"
                }
                
                # Ajouter les métadonnées si présentes
                if ($childTask.PSObject.Properties.Name -contains "Category") {
                    $result += "$indentation  Category: $($childTask.Category)`n"
                }
                
                if ($childTask.PSObject.Properties.Name -contains "Priority") {
                    $result += "$indentation  Priority: $($childTask.Priority)`n"
                }
                
                if ($childTask.PSObject.Properties.Name -contains "Dependencies" -and $childTask.Dependencies.Count -gt 0) {
                    $result += "$indentation  Depends on: $($childTask.Dependencies -join ", ")`n"
                }
                
                # Ajouter récursivement les sous-tâches
                $result += Add-TasksToContent -ParentTask $childTask -AllTasks $AllTasks -Indent ($Indent + 1)
            }
            
            return $result
        }
        
        # Ajouter les sous-tâches de cette section
        $content += Add-TasksToContent -ParentTask $section -AllTasks $sortedTasks -Indent 0
        
        $content += "`n"
    }
    
    # Sauvegarder la roadmap si un chemin est spécifié
    if ($OutputPath) {
        # Créer le dossier de sortie s'il n'existe pas
        $outputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Écrire le contenu dans le fichier
        $content | Out-File -FilePath $OutputPath -Encoding utf8
        
        Write-Host "Roadmap générée et sauvegardée dans: $OutputPath"
    }
    
    return $content
}

# Fonction pour générer une roadmap à partir d'un template
function New-RoadmapFromTemplate {
    <#
    .SYNOPSIS
        Génère une roadmap à partir d'un template.

    .DESCRIPTION
        Cette fonction génère une roadmap au format markdown à partir d'un template,
        en remplaçant les placeholders par les valeurs spécifiées.

    .PARAMETER TemplatePath
        Le chemin vers le fichier de template.

    .PARAMETER Title
        Le titre de la roadmap.

    .PARAMETER Description
        La description de la roadmap.

    .PARAMETER Author
        L'auteur de la roadmap.

    .PARAMETER Tags
        Les tags/thèmes de la roadmap.

    .PARAMETER Replacements
        Un hashtable de remplacements supplémentaires à effectuer dans le template.

    .PARAMETER OutputPath
        Le chemin où sauvegarder la roadmap générée.

    .EXAMPLE
        New-RoadmapFromTemplate -TemplatePath "C:\Templates\roadmap-template.md" -Title "Plan de développement v10" -OutputPath "C:\Roadmaps\plan-dev-v10.md"
        Génère une roadmap à partir du template spécifié.

    .OUTPUTS
        String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TemplatePath,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [string]$Description = "",

        [Parameter(Mandatory = $false)]
        [string]$Author = "Équipe de développement",

        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @(),

        [Parameter(Mandatory = $false)]
        [hashtable]$Replacements = @{},

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Vérifier que le fichier de template existe
    if (-not (Test-Path $TemplatePath)) {
        Write-Error "Le fichier de template n'existe pas: $TemplatePath"
        return $null
    }
    
    # Lire le contenu du template
    $template = Get-Content -Path $TemplatePath -Raw
    
    if ([string]::IsNullOrEmpty($template)) {
        Write-Error "Le fichier de template est vide: $TemplatePath"
        return $null
    }
    
    # Préparer les remplacements de base
    $date = Get-Date -Format "yyyy-MM-dd"
    $tagsString = if ($Tags.Count -gt 0) { $Tags -join ", " } else { "" }
    
    $baseReplacements = @{
        "{{TITLE}}" = $Title
        "{{DESCRIPTION}}" = $Description
        "{{AUTHOR}}" = $Author
        "{{DATE}}" = $date
        "{{TAGS}}" = $tagsString
    }
    
    # Combiner les remplacements de base avec les remplacements supplémentaires
    $allReplacements = $baseReplacements + $Replacements
    
    # Effectuer les remplacements
    $content = $template
    foreach ($key in $allReplacements.Keys) {
        $content = $content -replace [regex]::Escape($key), $allReplacements[$key]
    }
    
    # Sauvegarder la roadmap si un chemin est spécifié
    if ($OutputPath) {
        # Créer le dossier de sortie s'il n'existe pas
        $outputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Écrire le contenu dans le fichier
        $content | Out-File -FilePath $OutputPath -Encoding utf8
        
        Write-Host "Roadmap générée et sauvegardée dans: $OutputPath"
    }
    
    return $content
}

# Fonction pour mettre à jour le statut des tâches dans une roadmap
function Update-RoadmapTaskStatus {
    <#
    .SYNOPSIS
        Met à jour le statut des tâches dans une roadmap.

    .DESCRIPTION
        Cette fonction met à jour le statut des tâches dans une roadmap,
        en modifiant les checkboxes dans le fichier markdown.

    .PARAMETER FilePath
        Le chemin vers le fichier de roadmap.

    .PARAMETER TaskUpdates
        Un hashtable contenant les mises à jour de statut, avec les IDs des tâches comme clés
        et les nouveaux statuts comme valeurs ("Completed" ou "Pending").

    .PARAMETER OutputPath
        Le chemin où sauvegarder la roadmap mise à jour. Si non spécifié,
        le fichier original est mis à jour.

    .EXAMPLE
        Update-RoadmapTaskStatus -FilePath "C:\Roadmaps\plan-dev-v8.md" -TaskUpdates @{"1.1" = "Completed"; "1.2" = "Pending"}
        Met à jour le statut des tâches spécifiées dans la roadmap.

    .OUTPUTS
        String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [hashtable]$TaskUpdates,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Vérifier que le fichier existe
    if (-not (Test-Path $FilePath)) {
        Write-Error "Le fichier de roadmap n'existe pas: $FilePath"
        return $null
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw
    
    if ([string]::IsNullOrEmpty($content)) {
        Write-Error "Le fichier de roadmap est vide: $FilePath"
        return $null
    }
    
    # Mettre à jour le statut des tâches
    foreach ($taskId in $TaskUpdates.Keys) {
        $status = $TaskUpdates[$taskId]
        $checkbox = if ($status -eq "Completed") { "[x]" } else { "[ ]" }
        
        # Échapper les caractères spéciaux dans l'ID pour la regex
        $escapedId = [regex]::Escape($taskId)
        
        # Remplacer le statut de la tâche
        $pattern = "- \[[ x]\](\s+\*\*$escapedId\*\*)"
        $replacement = "- $checkbox`$1"
        
        $content = [regex]::Replace($content, $pattern, $replacement)
    }
    
    # Sauvegarder la roadmap mise à jour
    if ($OutputPath) {
        # Créer le dossier de sortie s'il n'existe pas
        $outputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Écrire le contenu dans le fichier
        $content | Out-File -FilePath $OutputPath -Encoding utf8
        
        Write-Host "Roadmap mise à jour et sauvegardée dans: $OutputPath"
    } else {
        # Mettre à jour le fichier original
        $content | Out-File -FilePath $FilePath -Encoding utf8
        
        Write-Host "Roadmap mise à jour: $FilePath"
    }
    
    return $content
}
