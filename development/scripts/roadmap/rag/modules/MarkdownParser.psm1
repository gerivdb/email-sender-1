#Requires -Version 5.1
<#
.SYNOPSIS
    Module pour l'analyse et le traitement des fichiers Markdown.
.DESCRIPTION
    Ce module fournit des fonctions pour analyser et traiter les fichiers Markdown,
    notamment pour extraire les tâches et les métadonnées.
.NOTES
    Nom: MarkdownParser.psm1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-06-10
#>

# Fonction pour extraire les tâches d'un fichier Markdown
function Get-MarkdownTasks {
    <#
    .SYNOPSIS
        Extrait les tâches d'un fichier Markdown.
    .DESCRIPTION
        Cette fonction analyse un fichier Markdown et extrait les tâches au format
        "- [ ] **X.X.X** Titre de la tâche".
    .PARAMETER FilePath
        Chemin du fichier Markdown à analyser.
    .PARAMETER Content
        Contenu du fichier Markdown à analyser. Si spécifié, FilePath est ignoré.
    .PARAMETER IncludeLineNumbers
        Indique si les numéros de ligne doivent être inclus dans les résultats.
    .PARAMETER IncludeMetadata
        Indique si les métadonnées des tâches doivent être extraites.
    .EXAMPLE
        Get-MarkdownTasks -FilePath "projet\roadmaps\plans\consolidated\plan-dev-v25.md"
        Extrait les tâches du fichier spécifié.
    .EXAMPLE
        $content = Get-Content -Path "projet\roadmaps\plans\consolidated\plan-dev-v25.md" -Raw
        Get-MarkdownTasks -Content $content
        Extrait les tâches du contenu spécifié.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = "FilePath")]
        [string]$FilePath,

        [Parameter(Mandatory = $false, ParameterSetName = "Content")]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeLineNumbers,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata
    )

    # Si le contenu n'est pas spécifié, lire le fichier
    if (-not $Content) {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Error "Le fichier spécifié n'existe pas: $FilePath"
            return $null
        }

        $Content = Get-Content -Path $FilePath -Raw
    }

    # Extraire les tâches
    $tasks = @()
    $taskPattern = '- \[([ xX])\]\s+(?:\*\*)?(\d+(?:\.\d+)*)(?:\*\*)?\s+(.*?)(?:\r?\n|$)'

    $regexMatches = [regex]::Matches($Content, $taskPattern)

    # Si IncludeLineNumbers est spécifié, calculer les numéros de ligne
    $lineNumbers = @{}

    if ($IncludeLineNumbers) {
        $lines = $Content -split "`n"

        for ($i = 0; $i -lt $lines.Length; $i++) {
            $line = $lines[$i]

            if ($line -match $taskPattern) {
                $lineMatches = $matches
                $taskId = $lineMatches[2]
                $lineNumbers[$taskId] = $i + 1
            }
        }
    }

    # Utiliser les correspondances déjà trouvées
    $taskMatches = $regexMatches

    foreach ($match in $taskMatches) {
        $status = if ($match.Groups[1].Value -match '[xX]') { "Completed" } else { "Pending" }
        $id = $match.Groups[2].Value
        $title = $match.Groups[3].Value.Trim()

        $task = [PSCustomObject]@{
            Id         = $id
            Title      = $title
            Status     = $status
            LineNumber = if ($IncludeLineNumbers -and $lineNumbers.ContainsKey($id)) { $lineNumbers[$id] } else { 0 }
            Metadata   = @{}
        }

        # Extraire les métadonnées si demandé
        if ($IncludeMetadata -and $title) {
            $task.Metadata = Get-TaskMetadata -TaskTitle $title
        }

        $tasks += $task
    }

    return $tasks
}

# Fonction pour extraire les métadonnées d'une tâche
function Get-TaskMetadata {
    <#
    .SYNOPSIS
        Extrait les métadonnées d'une tâche.
    .DESCRIPTION
        Cette fonction analyse le titre d'une tâche et extrait les métadonnées
        comme la priorité, le statut MVP, etc.
    .PARAMETER TaskTitle
        Titre de la tâche à analyser.
    .EXAMPLE
        Get-TaskMetadata -TaskTitle "Implémenter la fonctionnalité X [MVP] [P0]"
        Extrait les métadonnées de la tâche spécifiée.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskTitle
    )

    $metadata = @{
        IsMVP          = $false
        Priority       = "P3"  # Priorité par défaut
        EstimatedHours = 0
        Tags           = @()
    }

    # Détecter si la tâche est MVP
    if ($TaskTitle -match '\[MVP\]') {
        $metadata.IsMVP = $true
    }

    # Détecter la priorité
    if ($TaskTitle -match '\[P([0-3])\]') {
        $metadata.Priority = "P$($matches[1])"
    }

    # Détecter l'estimation de temps
    if ($TaskTitle -match '\[(\d+(?:\.\d+)?)h\]') {
        $metadata.EstimatedHours = [double]$matches[1]
    }

    # Détecter les tags
    $tagMatches = [regex]::Matches($TaskTitle, '\[([^\]]+)\]')

    foreach ($match in $tagMatches) {
        $tag = $match.Groups[1].Value

        # Ignorer les tags déjà traités
        if ($tag -ne "MVP" -and -not ($tag -match '^P[0-3]$') -and -not ($tag -match '^\d+(?:\.\d+)?h$')) {
            $metadata.Tags += $tag
        }
    }

    return $metadata
}

# Fonction pour extraire les métadonnées d'un fichier Markdown
function Get-MarkdownMetadata {
    <#
    .SYNOPSIS
        Extrait les métadonnées d'un fichier Markdown.
    .DESCRIPTION
        Cette fonction analyse un fichier Markdown et extrait les métadonnées
        comme le titre, la description, la version, etc.
    .PARAMETER FilePath
        Chemin du fichier Markdown à analyser.
    .PARAMETER Content
        Contenu du fichier Markdown à analyser. Si spécifié, FilePath est ignoré.
    .EXAMPLE
        Get-MarkdownMetadata -FilePath "projet\roadmaps\plans\consolidated\plan-dev-v25.md"
        Extrait les métadonnées du fichier spécifié.
    .EXAMPLE
        $content = Get-Content -Path "projet\roadmaps\plans\consolidated\plan-dev-v25.md" -Raw
        Get-MarkdownMetadata -Content $content
        Extrait les métadonnées du contenu spécifié.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = "FilePath")]
        [string]$FilePath,

        [Parameter(Mandatory = $false, ParameterSetName = "Content")]
        [string]$Content
    )

    # Si le contenu n'est pas spécifié, lire le fichier
    if (-not $Content) {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Error "Le fichier spécifié n'existe pas: $FilePath"
            return $null
        }

        $Content = Get-Content -Path $FilePath -Raw
    }

    # Extraire les métadonnées
    $metadata = @{
        Title       = ""
        Description = ""
        Version     = ""
        Date        = ""
        Progress    = 0
        Tags        = @()
    }

    # Extraire le titre (première ligne commençant par #)
    if ($Content -match '(?m)^#\s+(.+)$') {
        $metadata.Title = $matches[1].Trim()
    }

    # Extraire la version et la date (ligne commençant par *)
    if ($Content -match '(?m)^\*Version\s+([^\s]+)\s+-\s+(\d{4}-\d{2}-\d{2})') {
        $metadata.Version = $matches[1].Trim()
        $metadata.Date = $matches[2].Trim()
    }

    # Extraire la progression
    if ($Content -match '(?m)Progression globale\s*:\s*(\d+)%') {
        $metadata.Progress = [int]$matches[1]
    }

    # Extraire la description (paragraphe après le titre)
    if ($Content -match '(?m)^#\s+.+\r?\n\*.*\*\r?\n\r?\n(.+?)(?:\r?\n\r?\n|$)') {
        $metadata.Description = $matches[1].Trim()
    }

    # Extraire les tags
    $tagMatches = [regex]::Matches($Content, '(?m)^Tags\s*:\s*(.+?)(?:\r?\n|$)')

    if ($tagMatches.Count -gt 0) {
        $tagsLine = $tagMatches[0].Groups[1].Value
        $metadata.Tags = $tagsLine -split ',' | ForEach-Object { $_.Trim() }
    }

    return $metadata
}

# Fonction pour calculer la progression d'un ensemble de tâches
function Get-TasksProgress {
    <#
    .SYNOPSIS
        Calcule la progression d'un ensemble de tâches.
    .DESCRIPTION
        Cette fonction calcule la progression d'un ensemble de tâches en fonction
        de leur statut (complété ou non).
    .PARAMETER Tasks
        Tableau de tâches à analyser.
    .EXAMPLE
        $tasks = Get-MarkdownTasks -FilePath "projet\roadmaps\plans\consolidated\plan-dev-v25.md"
        Get-TasksProgress -Tasks $tasks
        Calcule la progression des tâches du fichier spécifié.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Tasks
    )

    if ($Tasks.Count -eq 0) {
        return 0
    }

    $completedTasks = $Tasks | Where-Object { $_.Status -eq "Completed" }
    $progress = ($completedTasks.Count / $Tasks.Count) * 100

    return [math]::Round($progress, 2)
}

# Fonction pour mettre à jour le statut d'une tâche dans un fichier Markdown
function Update-TaskStatus {
    <#
    .SYNOPSIS
        Met à jour le statut d'une tâche dans un fichier Markdown.
    .DESCRIPTION
        Cette fonction met à jour le statut d'une tâche dans un fichier Markdown
        en modifiant la case à cocher ([ ] ou [x]).
    .PARAMETER FilePath
        Chemin du fichier Markdown à modifier.
    .PARAMETER TaskId
        Identifiant de la tâche à mettre à jour.
    .PARAMETER Status
        Nouveau statut de la tâche (Completed ou Pending).
    .PARAMETER UpdateParents
        Indique si les tâches parentes doivent être mises à jour en fonction
        du statut des tâches enfants.
    .EXAMPLE
        Update-TaskStatus -FilePath "projet\roadmaps\plans\consolidated\plan-dev-v25.md" -TaskId "1.1.1" -Status "Completed"
        Met à jour le statut de la tâche spécifiée.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$TaskId,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Completed", "Pending")]
        [string]$Status,

        [Parameter(Mandatory = $false)]
        [switch]$UpdateParents
    )

    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier spécifié n'existe pas: $FilePath"
        return $false
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw

    # Définir le caractère de remplacement
    $replacement = if ($Status -eq "Completed") { "x" } else { " " }

    # Mettre à jour le statut de la tâche
    $pattern = "- \[([ xX])\]\s+(?:\*\*)?$TaskId(?:\*\*)?\s+"
    $newContent = $content -replace $pattern, "- [$replacement] **$TaskId** "

    # Si le contenu n'a pas changé, la tâche n'a pas été trouvée
    if ($newContent -eq $content) {
        Write-Warning "Tâche non trouvée: $TaskId"
        return $false
    }

    # Mettre à jour les tâches parentes si demandé
    if ($UpdateParents) {
        $tasks = Get-MarkdownTasks -Content $newContent

        # Extraire les identifiants des tâches parentes
        $parentIds = @()
        $parts = $TaskId -split '\.'

        for ($i = 1; $i -lt $parts.Length; $i++) {
            $parentIds += ($parts[0..($i - 1)] -join '.')
        }

        # Mettre à jour chaque tâche parente
        foreach ($parentId in $parentIds) {
            # Obtenir toutes les tâches enfants
            $childTasks = $tasks | Where-Object { $_.Id -match "^$parentId\.\d+" }

            # Déterminer le statut de la tâche parente
            $allCompleted = $true

            foreach ($childTask in $childTasks) {
                if ($childTask.Status -ne "Completed") {
                    $allCompleted = $false
                    break
                }
            }

            # Mettre à jour le statut de la tâche parente
            $parentStatus = if ($allCompleted) { "Completed" } else { "Pending" }
            $parentReplacement = if ($parentStatus -eq "Completed") { "x" } else { " " }

            $parentPattern = "- \[([ xX])\]\s+(?:\*\*)?$parentId(?:\*\*)?\s+"
            $newContent = $newContent -replace $parentPattern, "- [$parentReplacement] **$parentId** "
        }
    }

    # Enregistrer le contenu modifié
    $newContent | Set-Content -Path $FilePath -Encoding UTF8

    return $true
}

# Exporter les fonctions
Export-ModuleMember -Function Get-MarkdownTasks, Get-TaskMetadata, Get-MarkdownMetadata, Get-TasksProgress, Update-TaskStatus
