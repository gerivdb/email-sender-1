<#
.SYNOPSIS
    Exemple d'utilisation de la fonction ConvertFrom-MarkdownToObject.

.DESCRIPTION
    Ce script montre comment utiliser la fonction ConvertFrom-MarkdownToObject pour convertir
    un fichier markdown en structure d'objet PowerShell et effectuer diverses opÃ©rations sur cette structure.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-10
#>

# Importer la fonction
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToObject.ps1"
. $functionPath

# CrÃ©er un fichier markdown d'exemple
$exampleDir = Join-Path -Path $PSScriptRoot -ChildPath "data"
if (-not (Test-Path -Path $exampleDir)) {
    New-Item -Path $exampleDir -ItemType Directory | Out-Null
}

$exampleMarkdownPath = Join-Path -Path $exampleDir -ChildPath "example_roadmap.md"
@"
# Exemple de Roadmap

Ceci est un exemple de roadmap pour dÃ©montrer l'utilisation de la fonction ConvertFrom-MarkdownToObject.

## Planification

- [ ] **1** Analyse des besoins
  - [x] **1.1** Recueillir les exigences @john #important
  - [ ] **1.2** Analyser la faisabilitÃ©
    - [~] **1.2.1** Ã‰tude technique @date:2023-08-15
    - [!] **1.2.2** Ã‰valuation des coÃ»ts P1

## DÃ©veloppement

- [ ] **2** ImplÃ©mentation
  - [ ] **2.1** DÃ©velopper le backend @sarah
  - [ ] **2.2** CrÃ©er l'interface utilisateur
"@ | Out-File -FilePath $exampleMarkdownPath -Encoding UTF8

Write-Host "Fichier markdown d'exemple crÃ©Ã©: $exampleMarkdownPath" -ForegroundColor Green

# Exemple 1: Conversion simple
Write-Host "`nExemple 1: Conversion simple" -ForegroundColor Cyan
$roadmap = ConvertFrom-MarkdownToObject -FilePath $exampleMarkdownPath
Write-Host "Titre de la roadmap: $($roadmap.Title)" -ForegroundColor Yellow
Write-Host "Description: $($roadmap.Description)" -ForegroundColor Yellow
Write-Host "Nombre de sections: $($roadmap.Items.Count)" -ForegroundColor Yellow

# Exemple 2: Conversion avec extraction des mÃ©tadonnÃ©es
Write-Host "`nExemple 2: Conversion avec extraction des mÃ©tadonnÃ©es" -ForegroundColor Cyan
$roadmapWithMetadata = ConvertFrom-MarkdownToObject -FilePath $exampleMarkdownPath -IncludeMetadata

# Fonction pour afficher rÃ©cursivement les items
function Show-Items {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Item,
        
        [Parameter(Mandatory = $false)]
        [int]$Indent = 0
    )
    
    $indentation = " " * $Indent
    
    if ($Item.PSObject.Properties.Name -contains "Title") {
        Write-Host "$indentation- $($Item.Title)" -ForegroundColor White
    }
    
    if ($Item.PSObject.Properties.Name -contains "Status") {
        $statusColor = switch ($Item.Status) {
            "Complete" { "Green" }
            "InProgress" { "Yellow" }
            "Blocked" { "Red" }
            default { "Gray" }
        }
        Write-Host "$indentation  Status: $($Item.Status)" -ForegroundColor $statusColor
    }
    
    if ($Item.PSObject.Properties.Name -contains "Id") {
        Write-Host "$indentation  ID: $($Item.Id)" -ForegroundColor White
    }
    
    if ($Item.PSObject.Properties.Name -contains "Metadata" -and $Item.Metadata.Count -gt 0) {
        Write-Host "$indentation  MÃ©tadonnÃ©es:" -ForegroundColor Magenta
        foreach ($key in $Item.Metadata.Keys) {
            $value = $Item.Metadata[$key]
            if ($value -is [array]) {
                $value = $value -join ", "
            }
            Write-Host "$indentation    $key: $value" -ForegroundColor Magenta
        }
    }
    
    if ($Item.PSObject.Properties.Name -contains "Items" -and $Item.Items.Count -gt 0) {
        foreach ($subItem in $Item.Items) {
            Show-Items -Item $subItem -Indent ($Indent + 2)
        }
    }
}

# Afficher la structure avec mÃ©tadonnÃ©es
Write-Host "`nStructure de la roadmap avec mÃ©tadonnÃ©es:" -ForegroundColor Green
Show-Items -Item $roadmapWithMetadata

# Exemple 3: Recherche et filtrage
Write-Host "`nExemple 3: Recherche et filtrage" -ForegroundColor Cyan

# Fonction rÃ©cursive pour trouver tous les items correspondant Ã  un critÃ¨re
function Find-Items {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Item,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$Condition,
        
        [Parameter(Mandatory = $false)]
        [System.Collections.ArrayList]$Results = (New-Object System.Collections.ArrayList)
    )
    
    if ($Condition.Invoke($Item)) {
        $Results.Add($Item) | Out-Null
    }
    
    if ($Item.PSObject.Properties.Name -contains "Items" -and $Item.Items.Count -gt 0) {
        foreach ($subItem in $Item.Items) {
            Find-Items -Item $subItem -Condition $Condition -Results $Results
        }
    }
    
    return $Results
}

# Trouver toutes les tÃ¢ches complÃ©tÃ©es
$completedTasks = Find-Items -Item $roadmapWithMetadata -Condition { 
    $_.PSObject.Properties.Name -contains "Status" -and $_.Status -eq "Complete" 
}
Write-Host "TÃ¢ches complÃ©tÃ©es:" -ForegroundColor Green
foreach ($task in $completedTasks) {
    Write-Host "- $($task.Title) (ID: $($task.Id))" -ForegroundColor Green
}

# Trouver toutes les tÃ¢ches assignÃ©es Ã  John
$johnsTasks = Find-Items -Item $roadmapWithMetadata -Condition { 
    $_.PSObject.Properties.Name -contains "Metadata" -and 
    $_.Metadata.ContainsKey("Assignee") -and 
    $_.Metadata["Assignee"] -eq "john" 
}
Write-Host "`nTÃ¢ches assignÃ©es Ã  John:" -ForegroundColor Yellow
foreach ($task in $johnsTasks) {
    Write-Host "- $($task.Title) (ID: $($task.Id))" -ForegroundColor Yellow
}

# Trouver toutes les tÃ¢ches importantes
$importantTasks = Find-Items -Item $roadmapWithMetadata -Condition { 
    $_.PSObject.Properties.Name -contains "Metadata" -and 
    $_.Metadata.ContainsKey("Tags") -and 
    $_.Metadata["Tags"] -contains "important" 
}
Write-Host "`nTÃ¢ches importantes:" -ForegroundColor Magenta
foreach ($task in $importantTasks) {
    Write-Host "- $($task.Title) (ID: $($task.Id))" -ForegroundColor Magenta
}

# Exemple 4: Statistiques
Write-Host "`nExemple 4: Statistiques" -ForegroundColor Cyan

# Fonction pour calculer les statistiques
function Get-RoadmapStatistics {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Roadmap
    )
    
    $stats = @{
        TotalTasks = 0
        CompleteTasks = 0
        InProgressTasks = 0
        BlockedTasks = 0
        IncompleteTasks = 0
    }
    
    # Fonction rÃ©cursive pour compter les tÃ¢ches
    function Count-Tasks {
        param (
            [Parameter(Mandatory = $true)]
            [PSCustomObject]$Item
        )
        
        if ($Item.PSObject.Properties.Name -contains "Status") {
            $stats.TotalTasks++
            
            switch ($Item.Status) {
                "Complete" { $stats.CompleteTasks++ }
                "InProgress" { $stats.InProgressTasks++ }
                "Blocked" { $stats.BlockedTasks++ }
                "Incomplete" { $stats.IncompleteTasks++ }
            }
        }
        
        if ($Item.PSObject.Properties.Name -contains "Items" -and $Item.Items.Count -gt 0) {
            foreach ($subItem in $Item.Items) {
                Count-Tasks -Item $subItem
            }
        }
    }
    
    Count-Tasks -Item $Roadmap
    
    # Calculer les pourcentages
    if ($stats.TotalTasks -gt 0) {
        $stats.CompletePercentage = [Math]::Round(($stats.CompleteTasks / $stats.TotalTasks) * 100, 2)
        $stats.InProgressPercentage = [Math]::Round(($stats.InProgressTasks / $stats.TotalTasks) * 100, 2)
        $stats.BlockedPercentage = [Math]::Round(($stats.BlockedTasks / $stats.TotalTasks) * 100, 2)
        $stats.IncompletePercentage = [Math]::Round(($stats.IncompleteTasks / $stats.TotalTasks) * 100, 2)
    }
    else {
        $stats.CompletePercentage = 0
        $stats.InProgressPercentage = 0
        $stats.BlockedPercentage = 0
        $stats.IncompletePercentage = 0
    }
    
    return [PSCustomObject]$stats
}

$stats = Get-RoadmapStatistics -Roadmap $roadmapWithMetadata
Write-Host "Statistiques de la roadmap:" -ForegroundColor Cyan
Write-Host "- Nombre total de tÃ¢ches: $($stats.TotalTasks)" -ForegroundColor White
Write-Host "- TÃ¢ches complÃ©tÃ©es: $($stats.CompleteTasks) ($($stats.CompletePercentage)%)" -ForegroundColor Green
Write-Host "- TÃ¢ches en cours: $($stats.InProgressTasks) ($($stats.InProgressPercentage)%)" -ForegroundColor Yellow
Write-Host "- TÃ¢ches bloquÃ©es: $($stats.BlockedTasks) ($($stats.BlockedPercentage)%)" -ForegroundColor Red
Write-Host "- TÃ¢ches incomplÃ¨tes: $($stats.IncompleteTasks) ($($stats.IncompletePercentage)%)" -ForegroundColor Gray

Write-Host "`nExemples terminÃ©s. Vous pouvez explorer le fichier markdown et les rÃ©sultats." -ForegroundColor Green
