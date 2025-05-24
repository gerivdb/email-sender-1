# Parse-Roadmap.ps1
# Module pour parser les fichiers de roadmap au format markdown
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Parse les fichiers de roadmap au format markdown.

.DESCRIPTION
    Ce module fournit des fonctions pour parser les fichiers de roadmap au format markdown,
    extraire la structure hiérarchique des tâches, les statuts, les métadonnées, etc.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Fonction pour parser un fichier de roadmap
function ConvertFrom-RoadmapFile {
    <#
    .SYNOPSIS
        Parse un fichier de roadmap au format markdown.

    .DESCRIPTION
        Cette fonction parse un fichier de roadmap au format markdown et extrait
        la structure hiérarchique des tâches, les statuts, les métadonnées, etc.

    .PARAMETER FilePath
        Le chemin vers le fichier de roadmap à parser.

    .PARAMETER IncludeContent
        Si spécifié, inclut le contenu brut du fichier dans le résultat.

    .EXAMPLE
        ConvertFrom-RoadmapFile -FilePath "C:\Roadmaps\plan-dev-v8.md"
        Parse le fichier de roadmap spécifié et retourne sa structure.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent
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
    
    # Extraire le titre de la roadmap
    $titleMatch = [regex]::Match($content, "^#\s+(.+)$", [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value.Trim() } else { "Roadmap sans titre" }
    
    # Extraire les tâches
    $tasks = @()
    $taskRegex = [regex]::new("- \[([ x])\]\s+\*\*([0-9.]+)\*\*\s+(.+?)(?:\n|$)(?:\s+(.+?)(?:\n|$))?", [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $matches = $taskRegex.Matches($content)
    
    foreach ($match in $matches) {
        $status = if ($match.Groups[1].Value -eq "x") { "Completed" } else { "Pending" }
        $id = $match.Groups[2].Value.Trim()
        $title = $match.Groups[3].Value.Trim()
        $description = if ($match.Groups[4].Success) { $match.Groups[4].Value.Trim() } else { "" }
        
        # Déterminer le parent ID
        $parentId = $null
        $idParts = $id -split "\."
        if ($idParts.Count -gt 1) {
            $parentId = [string]::Join(".", $idParts[0..($idParts.Count - 2)])
        }
        
        # Créer l'objet tâche
        $task = [PSCustomObject]@{
            Id = $id
            ParentId = $parentId
            Title = $title
            Description = $description
            Status = $status
            Children = @()
            Level = $idParts.Count
        }
        
        $tasks += $task
    }
    
    # Établir les relations parent-enfant
    foreach ($task in $tasks) {
        if ($task.ParentId) {
            $parent = $tasks | Where-Object { $_.Id -eq $task.ParentId } | Select-Object -First 1
            if ($parent) {
                $parent.Children += $task.Id
            }
        }
    }
    
    # Extraire les métadonnées (catégories, priorités, etc.)
    $categoryRegex = [regex]::new("Category:\s*(.+?)(?:\n|$)", [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $priorityRegex = [regex]::new("Priority:\s*(.+?)(?:\n|$)", [System.Text.RegularExpressions.RegexOptions]::Multiline)
    
    foreach ($task in $tasks) {
        # Rechercher des métadonnées dans la description
        $categoryMatch = $categoryRegex.Match($task.Description)
        if ($categoryMatch.Success) {
            Add-Member -InputObject $task -MemberType NoteProperty -Name "Category" -Value $categoryMatch.Groups[1].Value.Trim()
            $task.Description = $task.Description -replace "Category:\s*(.+?)(?:\n|$)", ""
        }
        
        $priorityMatch = $priorityRegex.Match($task.Description)
        if ($priorityMatch.Success) {
            Add-Member -InputObject $task -MemberType NoteProperty -Name "Priority" -Value $priorityMatch.Groups[1].Value.Trim()
            $task.Description = $task.Description -replace "Priority:\s*(.+?)(?:\n|$)", ""
        }
        
        # Nettoyer la description
        $task.Description = $task.Description.Trim()
    }
    
    # Extraire les dépendances
    $dependencyRegex = [regex]::new("Depends on:\s*(.+?)(?:\n|$)", [System.Text.RegularExpressions.RegexOptions]::Multiline)
    
    foreach ($task in $tasks) {
        $dependencyMatch = $dependencyRegex.Match($task.Description)
        if ($dependencyMatch.Success) {
            $dependencies = $dependencyMatch.Groups[1].Value.Trim() -split ",\s*" | ForEach-Object { $_.Trim() }
            Add-Member -InputObject $task -MemberType NoteProperty -Name "Dependencies" -Value $dependencies
            $task.Description = $task.Description -replace "Depends on:\s*(.+?)(?:\n|$)", ""
            $task.Description = $task.Description.Trim()
        }
    }
    
    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        Title = $title
        FilePath = $FilePath
        Tasks = $tasks
    }
    
    # Inclure le contenu brut si demandé
    if ($IncludeContent) {
        Add-Member -InputObject $result -MemberType NoteProperty -Name "Content" -Value $content
    }
    
    return $result
}

# Fonction pour extraire les métadonnées d'une roadmap
function Get-RoadmapMetadata {
    <#
    .SYNOPSIS
        Extrait les métadonnées d'une roadmap.

    .DESCRIPTION
        Cette fonction extrait les métadonnées d'une roadmap, comme le titre,
        la date de création, la version, etc.

    .PARAMETER FilePath
        Le chemin vers le fichier de roadmap.

    .EXAMPLE
        Get-RoadmapMetadata -FilePath "C:\Roadmaps\plan-dev-v8.md"
        Extrait les métadonnées de la roadmap spécifiée.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
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
    
    # Extraire le titre
    $titleMatch = [regex]::Match($content, "^#\s+(.+)$", [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value.Trim() } else { "Roadmap sans titre" }
    
    # Extraire la version
    $versionMatch = [regex]::Match($title, "v([0-9]+)", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $version = if ($versionMatch.Success) { $versionMatch.Groups[1].Value } else { "0" }
    
    # Extraire la date de création/modification
    $dateMatch = [regex]::Match($content, "Date:\s*(.+?)(?:\n|$)", [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $date = if ($dateMatch.Success) { $dateMatch.Groups[1].Value.Trim() } else { $null }
    
    # Extraire l'auteur
    $authorMatch = [regex]::Match($content, "Auteur:\s*(.+?)(?:\n|$)", [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $author = if ($authorMatch.Success) { $authorMatch.Groups[1].Value.Trim() } else { $null }
    
    # Extraire les tags/thèmes
    $tagsMatch = [regex]::Match($content, "Tags:\s*(.+?)(?:\n|$)", [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $tags = if ($tagsMatch.Success) { 
        $tagsMatch.Groups[1].Value.Trim() -split ",\s*" | ForEach-Object { $_.Trim() } 
    } else { 
        @() 
    }
    
    # Extraire la description
    $descriptionMatch = [regex]::Match($content, "^##\s+Description\s*\n+(.+?)(?:\n##|\n$)", [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $description = if ($descriptionMatch.Success) { $descriptionMatch.Groups[1].Value.Trim() } else { $null }
    
    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        Title = $title
        Version = $version
        Date = $date
        Author = $author
        Tags = $tags
        Description = $description
        FilePath = $FilePath
    }
    
    return $result
}

# Fonction pour extraire les statistiques d'une roadmap
function Get-RoadmapStatistics {
    <#
    .SYNOPSIS
        Extrait les statistiques d'une roadmap.

    .DESCRIPTION
        Cette fonction extrait les statistiques d'une roadmap, comme le nombre total de tâches,
        le nombre de tâches complétées, le taux de complétion, etc.

    .PARAMETER FilePath
        Le chemin vers le fichier de roadmap.

    .PARAMETER ParsedRoadmap
        Une roadmap déjà parsée par ConvertFrom-RoadmapFile.

    .EXAMPLE
        Get-RoadmapStatistics -FilePath "C:\Roadmaps\plan-dev-v8.md"
        Extrait les statistiques de la roadmap spécifiée.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "FromFile")]
        [string]$FilePath,

        [Parameter(Mandatory = $true, ParameterSetName = "FromParsed")]
        [PSObject]$ParsedRoadmap
    )

    # Parser la roadmap si nécessaire
    if ($PSCmdlet.ParameterSetName -eq "FromFile") {
        $roadmap = ConvertFrom-RoadmapFile -FilePath $FilePath
        
        if ($null -eq $roadmap) {
            return $null
        }
    } else {
        $roadmap = $ParsedRoadmap
    }
    
    # Calculer les statistiques
    $totalTasks = $roadmap.Tasks.Count
    $completedTasks = ($roadmap.Tasks | Where-Object { $_.Status -eq "Completed" }).Count
    $pendingTasks = $totalTasks - $completedTasks
    $completionRate = if ($totalTasks -gt 0) { [math]::Round(($completedTasks / $totalTasks) * 100, 2) } else { 0 }
    
    # Calculer la profondeur maximale
    $maxDepth = ($roadmap.Tasks | ForEach-Object { $_.Id.Split('.').Count } | Measure-Object -Maximum).Maximum
    
    # Calculer le nombre de tâches par niveau
    $tasksByLevel = @{}
    for ($i = 1; $i -le $maxDepth; $i++) {
        $tasksByLevel[$i] = ($roadmap.Tasks | Where-Object { $_.Id.Split('.').Count -eq $i }).Count
    }
    
    # Calculer le nombre de tâches par statut et niveau
    $tasksByStatusAndLevel = @{}
    foreach ($status in @("Completed", "Pending")) {
        $tasksByStatusAndLevel[$status] = @{}
        for ($i = 1; $i -le $maxDepth; $i++) {
            $tasksByStatusAndLevel[$status][$i] = ($roadmap.Tasks | Where-Object { $_.Status -eq $status -and $_.Id.Split('.').Count -eq $i }).Count
        }
    }
    
    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        Title = $roadmap.Title
        TotalTasks = $totalTasks
        CompletedTasks = $completedTasks
        PendingTasks = $pendingTasks
        CompletionRate = $completionRate
        MaxDepth = $maxDepth
        TasksByLevel = $tasksByLevel
        TasksByStatusAndLevel = $tasksByStatusAndLevel
    }
    
    return $result
}

