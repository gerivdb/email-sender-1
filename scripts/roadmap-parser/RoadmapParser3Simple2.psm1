# RoadmapParser3Simple2.psm1
# Version simplifiee du module RoadmapParser3

# Enumeration pour representer le statut d'une tache
Add-Type -TypeDefinition @"
    public enum TaskStatus {
        Incomplete,
        InProgress,
        Complete,
        Blocked
    }
"@

# Variables de preference pour la journalisation
$script:RoadmapLogLevel = "Info"  # Valeurs possibles: "Debug", "Info", "Warning", "Error"
$script:RoadmapLogFile = $null    # Chemin du fichier de journal, ou $null pour desactiver la journalisation dans un fichier
$script:RoadmapLogToConsole = $true  # Indique si les messages de journal doivent etre affiches dans la console

function ConvertFrom-MarkdownToRoadmapTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("UTF8", "UTF7", "ASCII", "Unicode", "UTF32")]
        [string]$Encoding = "UTF8"
    )

    # Verifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    # Lire le contenu du fichier
    try {
        $content = Get-Content -Path $FilePath -Encoding $Encoding -Raw
        $lines = $content -split "`n"
    }
    catch {
        throw "Erreur lors de la lecture du fichier '$FilePath': $_"
    }

    # Extraire le titre et la description
    $title = "Roadmap"
    $description = ""
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^#\s+(.+)$') {
            $title = $matches[1]
            
            # Extraire la description (lignes non vides apres le titre jusqu'a la premiere section)
            $descLines = @()
            $j = $i + 1
            while ($j -lt $lines.Count -and -not ($lines[$j] -match '^#{2,}\s+')) {
                if (-not [string]::IsNullOrWhiteSpace($lines[$j])) {
                    $descLines += $lines[$j]
                }
                $j++
            }
            
            if ($descLines.Count -gt 0) {
                $description = $descLines -join "`n"
            }
            
            break
        }
    }

    # Creer l'arbre de roadmap
    $tree = New-RoadmapTree -Title $title -Description $description
    $tree.FilePath = $FilePath

    # Parser les taches
    $currentParent = $tree.Root
    $currentLevel = 0
    $idCounter = 1
    $taskMap = @{}

    foreach ($line in $lines) {
        if ($line -match '^(\s*)[-*+]\s*(?:\[([ xX~!])\])?\s*(?:\*\*([^*]+)\*\*)?\s*(.*)$') {
            $indent = $matches[1].Length
            $statusMark = $matches[2]
            $id = $matches[3]
            $title = $matches[4]

            # Determiner le statut
            $status = ConvertFrom-MarkdownTaskStatus -StatusMarker $statusMark

            # Si l'ID n'est pas specifie, en generer un
            if ([string]::IsNullOrEmpty($id)) {
                $id = "$idCounter"
                $idCounter++
            }

            # Creer la tache
            $task = New-RoadmapTask -Id $id -Title $title -Status $status
            $task.OriginalMarkdown = $line

            # Determiner le parent en fonction de l'indentation
            if ($indent -gt $currentLevel) {
                # Niveau d'indentation superieur, le parent est la derniere tache ajoutee
                $currentParent = $taskMap[$currentLevel]
                $currentLevel = $indent
            } elseif ($indent -lt $currentLevel) {
                # Niveau d'indentation inferieur, remonter dans l'arborescence
                while ($indent -lt $currentLevel -and $currentParent.Parent -ne $tree.Root) {
                    $currentParent = $currentParent.Parent
                    $currentLevel -= 2  # Supposer 2 espaces par niveau
                }
            }

            # Ajouter la tache a l'arbre
            Add-RoadmapTask -RoadmapTree $tree -Task $task -ParentTask $currentParent
            $taskMap[$indent] = $task
        }
    }

    return $tree
}

function ConvertFrom-MarkdownTaskStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$StatusMarker
    )

    # Convertir le marqueur en valeur de l'enumeration TaskStatus
    switch ($StatusMarker) {
        'x' { return [TaskStatus]::Complete }
        'X' { return [TaskStatus]::Complete }
        '~' { return [TaskStatus]::InProgress }
        '!' { return [TaskStatus]::Blocked }
        default { return [TaskStatus]::Incomplete }
    }
}

function New-RoadmapTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )

    # Creer l'objet RoadmapTree
    $tree = [PSCustomObject]@{
        Title                = $Title
        Description          = $Description
        FilePath             = $null
        Root                 = [PSCustomObject]@{
            Id               = "root"
            Title            = "Root"
            Description      = ""
            Status           = [TaskStatus]::Incomplete
            Level            = -1
            Parent           = $null
            Children         = New-Object System.Collections.ArrayList
            Dependencies     = New-Object System.Collections.ArrayList
            DependentTasks   = New-Object System.Collections.ArrayList
            OriginalMarkdown = $null
        }
        AllTasks             = New-Object System.Collections.ArrayList
        TasksById            = @{}
    }

    return $tree
}

function New-RoadmapTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Id,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [string]$Description = "",

        [Parameter(Mandatory = $false)]
        [TaskStatus]$Status = [TaskStatus]::Incomplete
    )

    # Creer l'objet RoadmapTask
    $task = [PSCustomObject]@{
        Id               = $Id
        Title            = $Title
        Description      = $Description
        Status           = $Status
        Level            = 0
        Parent           = $null
        Children         = New-Object System.Collections.ArrayList
        Dependencies     = New-Object System.Collections.ArrayList
        DependentTasks   = New-Object System.Collections.ArrayList
        OriginalMarkdown = $null
    }

    return $task
}

function Add-RoadmapTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$RoadmapTree,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$Task,

        [Parameter(Mandatory = $false)]
        [PSCustomObject]$ParentTask = $null
    )

    if ($null -eq $ParentTask) {
        $ParentTask = $RoadmapTree.Root
    }

    $Task.Parent = $ParentTask
    $ParentTask.Children.Add($Task) | Out-Null
    $RoadmapTree.AllTasks.Add($Task) | Out-Null
    $RoadmapTree.TasksById[$Task.Id] = $Task
    $Task.Level = if ($ParentTask -eq $RoadmapTree.Root) { 0 } else { $ParentTask.Level + 1 }
}

function Export-RoadmapTreeToJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$RoadmapTree,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("UTF8", "UTF7", "ASCII", "Unicode", "UTF32")]
        [string]$Encoding = "UTF8",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 8)]
        [int]$Indent = 4
    )

    # Creer un objet JSON a partir de l'arbre de roadmap
    $jsonObject = [PSCustomObject]@{
        Title = $RoadmapTree.Title
        Description = $RoadmapTree.Description
        CreatedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Tasks = @()
    }

    # Ajouter les taches a l'objet JSON
    foreach ($task in $RoadmapTree.AllTasks) {
        $jsonTask = ConvertTo-JsonTask -Task $task
        $jsonObject.Tasks += $jsonTask
    }

    # Convertir l'objet JSON en chaine JSON
    $jsonString = ConvertTo-Json -InputObject $jsonObject -Depth 10 -Compress:$false

    # Ecrire la chaine JSON dans le fichier
    try {
        $jsonString | Out-File -FilePath $FilePath -Encoding $Encoding
    } catch {
        Write-Error "Error writing JSON file: $_"
    }
}

function ConvertTo-JsonTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$Task
    )

    # Creer un objet JSON a partir de la tache
    $jsonTask = [PSCustomObject]@{
        Id = $Task.Id
        Title = $Task.Title
        Description = $Task.Description
        Status = $Task.Status.ToString()
        Level = $Task.Level
        ParentId = if ($null -ne $Task.Parent -and $Task.Parent.Id -ne "root") { $Task.Parent.Id } else { $null }
        ChildrenIds = @($Task.Children | ForEach-Object { $_.Id })
        DependencyIds = @($Task.Dependencies | ForEach-Object { $_.Id })
        DependentTaskIds = @($Task.DependentTasks | ForEach-Object { $_.Id })
        OriginalMarkdown = $Task.OriginalMarkdown
    }

    return $jsonTask
}

function Export-RoadmapTreeToMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$RoadmapTree,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("UTF8", "UTF7", "ASCII", "Unicode", "UTF32")]
        [string]$Encoding = "UTF8"
    )

    # Creer le contenu Markdown
    $markdown = "# $($RoadmapTree.Title)`n`n"

    if (-not [string]::IsNullOrEmpty($RoadmapTree.Description)) {
        $markdown += "$($RoadmapTree.Description)`n`n"
    }

    # Ajouter les taches au contenu Markdown
    foreach ($task in $RoadmapTree.AllTasks | Where-Object { $_.Level -eq 0 }) {
        $markdown += ConvertTo-MarkdownTask -Task $task -IncludeChildren $true
    }

    # Ecrire le contenu Markdown dans le fichier
    try {
        $markdown | Out-File -FilePath $FilePath -Encoding $Encoding
    } catch {
        Write-Error "Error writing Markdown file: $_"
    }
}

function ConvertTo-MarkdownTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$Task,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeChildren = $false
    )

    # Creer l'indentation
    $indent = "  " * $Task.Level

    # Creer le marqueur de statut
    $statusMark = switch ($Task.Status) {
        ([TaskStatus]::Complete) { "[x]" }
        ([TaskStatus]::InProgress) { "[~]" }
        ([TaskStatus]::Blocked) { "[!]" }
        default { "[ ]" }
    }

    # Creer la ligne Markdown pour la tache
    $markdown = "$indent- $statusMark"

    # Ajouter l'ID s'il existe
    if (-not [string]::IsNullOrEmpty($Task.Id)) {
        $markdown += " **$($Task.Id)**"
    }

    # Ajouter le titre
    $markdown += " $($Task.Title)`n"

    # Ajouter la description s'il existe
    if (-not [string]::IsNullOrEmpty($Task.Description)) {
        $descLines = $Task.Description -split "`n"
        foreach ($line in $descLines) {
            $markdown += "$indent  $line`n"
        }
    }

    # Ajouter les enfants si demande
    if ($IncludeChildren -and $Task.Children.Count -gt 0) {
        foreach ($child in $Task.Children) {
            $markdown += ConvertTo-MarkdownTask -Task $child -IncludeChildren $true
        }
    }

    return $markdown
}

function Import-RoadmapTreeFromJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("UTF8", "UTF7", "ASCII", "Unicode", "UTF32")]
        [string]$Encoding = "UTF8"
    )

    # Verifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    # Lire le contenu du fichier
    try {
        $jsonString = Get-Content -Path $FilePath -Encoding $Encoding -Raw
        $jsonObject = ConvertFrom-Json -InputObject $jsonString
    } catch {
        Write-Error "Error reading JSON file: $_"
        return $null
    }

    # Creer un nouvel arbre de roadmap
    $roadmap = New-RoadmapTree -Title $jsonObject.Title -Description $jsonObject.Description
    $roadmap.FilePath = $FilePath

    # Creer un dictionnaire pour stocker les taches
    $taskDict = @{}

    # Creer les taches
    foreach ($jsonTask in $jsonObject.Tasks) {
        $status = [Enum]::Parse([TaskStatus], $jsonTask.Status)
        $task = New-RoadmapTask -Id $jsonTask.Id -Title $jsonTask.Title -Description $jsonTask.Description -Status $status
        $task.Level = $jsonTask.Level
        $task.OriginalMarkdown = $jsonTask.OriginalMarkdown
        $taskDict[$jsonTask.Id] = $task
    }

    # Etablir les relations entre les taches
    foreach ($jsonTask in $jsonObject.Tasks) {
        $task = $taskDict[$jsonTask.Id]

        # Ajouter la tache a l'arbre
        if ([string]::IsNullOrEmpty($jsonTask.ParentId)) {
            Add-RoadmapTask -RoadmapTree $roadmap -Task $task
        } else {
            $parentTask = $taskDict[$jsonTask.ParentId]
            Add-RoadmapTask -RoadmapTree $roadmap -Task $task -ParentTask $parentTask
        }

        # Ajouter les dependances
        foreach ($dependencyId in $jsonTask.DependencyIds) {
            $dependency = $taskDict[$dependencyId]
            Add-RoadmapTaskDependency -Task $task -DependsOn $dependency
        }
    }

    return $roadmap
}

function Add-RoadmapTaskDependency {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$Task,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$DependsOn
    )

    $Task.Dependencies.Add($DependsOn) | Out-Null
    $DependsOn.DependentTasks.Add($Task) | Out-Null
}

function New-RoadmapReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$RoadmapTree,

        [Parameter(Mandatory = $false)]
        [string]$FilePath = $null,

        [Parameter(Mandatory = $false)]
        [ValidateSet("UTF8", "UTF7", "ASCII", "Unicode", "UTF32")]
        [string]$Encoding = "UTF8"
    )

    # Calculer les statistiques
    $stats = Get-RoadmapStatistics -RoadmapTree $RoadmapTree

    # Creer le rapport
    $report = "# Rapport de la roadmap: $($RoadmapTree.Title)`n`n"
    $report += "## Statistiques generales`n`n"
    $report += "- Nombre total de taches: $($stats.TotalTasks)`n"
    $report += "- Taches completees: $($stats.CompleteTasks) ($($stats.CompletePercentage)%)`n"
    $report += "- Taches en cours: $($stats.InProgressTasks) ($($stats.InProgressPercentage)%)`n"
    $report += "- Taches bloquees: $($stats.BlockedTasks) ($($stats.BlockedPercentage)%)`n"
    $report += "- Taches incompletes: $($stats.IncompleteTasks) ($($stats.IncompletePercentage)%)`n`n"

    $report += "## Taches par niveau`n`n"
    foreach ($level in $stats.TasksByLevel.Keys | Sort-Object) {
        $report += "- Niveau $level : $($stats.TasksByLevel[$level]) taches`n"
    }
    $report += "`n"

    $report += "## Taches bloquees`n`n"
    if ($stats.BlockedTasks -gt 0) {
        foreach ($task in $RoadmapTree.AllTasks | Where-Object { $_.Status -eq [TaskStatus]::Blocked }) {
            $report += "- **$($task.Id)** $($task.Title)`n"
            if ($task.Dependencies.Count -gt 0) {
                $report += "  - Dependances: "
                $report += ($task.Dependencies | ForEach-Object { "**$($_.Id)**" }) -join ", "
                $report += "`n"
            }
        }
    } else {
        $report += "Aucune tache bloquee.`n"
    }
    $report += "`n"

    $report += "## Taches en cours`n`n"
    if ($stats.InProgressTasks -gt 0) {
        foreach ($task in $RoadmapTree.AllTasks | Where-Object { $_.Status -eq [TaskStatus]::InProgress }) {
            $report += "- **$($task.Id)** $($task.Title)`n"
        }
    } else {
        $report += "Aucune tache en cours.`n"
    }
    $report += "`n"

    $report += "## Prochaines taches a realiser`n`n"
    $incompleteTasks = $RoadmapTree.AllTasks | Where-Object { $_.Status -eq [TaskStatus]::Incomplete }
    $readyTasks = $incompleteTasks | Where-Object {
        $task = $_
        $task.Dependencies.Count -eq 0 -or ($task.Dependencies | ForEach-Object { $_.Status -eq [TaskStatus]::Complete }) -contains $false
    }

    if ($readyTasks.Count -gt 0) {
        foreach ($task in $readyTasks | Sort-Object -Property Level) {
            $report += "- **$($task.Id)** $($task.Title)`n"
        }
    } else {
        $report += "Aucune tache prete a etre realisee.`n"
    }

    # Ecrire le rapport dans un fichier si demande
    if (-not [string]::IsNullOrEmpty($FilePath)) {
        try {
            $report | Out-File -FilePath $FilePath -Encoding $Encoding
        } catch {
            Write-Error "Error writing report file: $_"
        }
    }

    return $report
}

function Get-RoadmapStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$RoadmapTree
    )

    # Calculer les statistiques
    $totalTasks = $RoadmapTree.AllTasks.Count
    $completeTasks = ($RoadmapTree.AllTasks | Where-Object { $_.Status -eq [TaskStatus]::Complete }).Count
    $inProgressTasks = ($RoadmapTree.AllTasks | Where-Object { $_.Status -eq [TaskStatus]::InProgress }).Count
    $blockedTasks = ($RoadmapTree.AllTasks | Where-Object { $_.Status -eq [TaskStatus]::Blocked }).Count
    $incompleteTasks = ($RoadmapTree.AllTasks | Where-Object { $_.Status -eq [TaskStatus]::Incomplete }).Count

    # Calculer les pourcentages
    $completePercentage = if ($totalTasks -gt 0) { [Math]::Round(($completeTasks / $totalTasks) * 100, 2) } else { 0 }
    $inProgressPercentage = if ($totalTasks -gt 0) { [Math]::Round(($inProgressTasks / $totalTasks) * 100, 2) } else { 0 }
    $blockedPercentage = if ($totalTasks -gt 0) { [Math]::Round(($blockedTasks / $totalTasks) * 100, 2) } else { 0 }
    $incompletePercentage = if ($totalTasks -gt 0) { [Math]::Round(($incompleteTasks / $totalTasks) * 100, 2) } else { 0 }

    # Calculer les taches par niveau
    $tasksByLevel = @{}
    foreach ($task in $RoadmapTree.AllTasks) {
        if (-not $tasksByLevel.ContainsKey($task.Level)) {
            $tasksByLevel[$task.Level] = 0
        }
        $tasksByLevel[$task.Level]++
    }

    # Creer l'objet de statistiques
    $stats = [PSCustomObject]@{
        TotalTasks = $totalTasks
        CompleteTasks = $completeTasks
        InProgressTasks = $inProgressTasks
        BlockedTasks = $blockedTasks
        IncompleteTasks = $incompleteTasks
        CompletePercentage = $completePercentage
        InProgressPercentage = $inProgressPercentage
        BlockedPercentage = $blockedPercentage
        IncompletePercentage = $incompletePercentage
        TasksByLevel = $tasksByLevel
    }

    return $stats
}

function New-RoadmapVisualization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$RoadmapTree,

        [Parameter(Mandatory = $false)]
        [string]$FilePath = $null,

        [Parameter(Mandatory = $false)]
        [ValidateSet("UTF8", "UTF7", "ASCII", "Unicode", "UTF32")]
        [string]$Encoding = "UTF8",

        [Parameter(Mandatory = $false)]
        [ValidateSet("graph", "flowchart", "gantt")]
        [string]$DiagramType = "graph"
    )

    # Creer la visualisation
    $visualization = "```mermaid`n"
    
    if ($DiagramType -eq "graph" -or $DiagramType -eq "flowchart") {
        $visualization += "$DiagramType TD`n"
        
        # Ajouter les noeuds
        foreach ($task in $RoadmapTree.AllTasks) {
            $visualization += "    $($task.Id)[$($task.Id): $($task.Title)]:::$($task.Status)`n"
        }
        
        # Ajouter les relations parent-enfant
        foreach ($task in $RoadmapTree.AllTasks) {
            foreach ($child in $task.Children) {
                $visualization += "    $($task.Id) --> $($child.Id)`n"
            }
        }
        
        # Ajouter les dependances
        foreach ($task in $RoadmapTree.AllTasks) {
            foreach ($dependency in $task.Dependencies) {
                $visualization += "    $($dependency.Id) -.-> $($task.Id)`n"
            }
        }
        
        # Ajouter les styles
        $visualization += "    classDef Complete fill:#9f9,stroke:#6c6`n"
        $visualization += "    classDef InProgress fill:#ff9,stroke:#cc6`n"
        $visualization += "    classDef Blocked fill:#f99,stroke:#c66`n"
        $visualization += "    classDef Incomplete fill:#eee,stroke:#999`n"
    }
    elseif ($DiagramType -eq "gantt") {
        $visualization += "gantt`n"
        $visualization += "    title $($RoadmapTree.Title)`n"
        $visualization += "    dateFormat YYYY-MM-DD`n"
        $visualization += "    axisFormat %Y-%m-%d`n"
        
        # Ajouter les sections
        $sections = @{}
        foreach ($task in $RoadmapTree.AllTasks) {
            $level = $task.Level
            if (-not $sections.ContainsKey($level)) {
                $sections[$level] = @()
            }
            $sections[$level] += $task
        }
        
        foreach ($level in $sections.Keys | Sort-Object) {
            $visualization += "    section Niveau $level`n"
            foreach ($task in $sections[$level]) {
                $status = switch ($task.Status) {
                    ([TaskStatus]::Complete) { "done" }
                    ([TaskStatus]::InProgress) { "active" }
                    ([TaskStatus]::Blocked) { "crit" }
                    default { "" }
                }
                $visualization += "    $($task.Id): $status, $($task.Title), after $($task.Dependencies | ForEach-Object { $_.Id } | Join-String -Separator ',')`n"
            }
        }
    }
    
    $visualization += "```"

    # Ecrire la visualisation dans un fichier si demande
    if (-not [string]::IsNullOrEmpty($FilePath)) {
        try {
            $visualization | Out-File -FilePath $FilePath -Encoding $Encoding
        }
        catch {
            Write-Error "Error writing visualization file: $_"
        }
    }

    return $visualization
}

# Exporter les fonctions
Export-ModuleMember -Function ConvertFrom-MarkdownToRoadmapTree, ConvertFrom-MarkdownTaskStatus, New-RoadmapTree, New-RoadmapTask, Add-RoadmapTask, Export-RoadmapTreeToJson, ConvertTo-JsonTask, Export-RoadmapTreeToMarkdown, ConvertTo-MarkdownTask, Import-RoadmapTreeFromJson, Add-RoadmapTaskDependency, New-RoadmapReport, Get-RoadmapStatistics, New-RoadmapVisualization
