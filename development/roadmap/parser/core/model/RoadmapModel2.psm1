# RoadmapModel.psm1
# Module pour reprÃ©senter le modÃ¨le objet de la roadmap

# Ã‰numÃ©ration pour reprÃ©senter le statut d'une tÃ¢che
Add-Type -TypeDefinition @"
    public enum TaskStatus {
        Incomplete,
        InProgress,
        Complete,
        Blocked
    }
"@

# Fonction pour crÃ©er une nouvelle tÃ¢che
function New-RoadmapTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [string]$Description = "",

        [Parameter(Mandatory = $false)]
        [TaskStatus]$Status = [TaskStatus]::Incomplete
    )

    $task = [PSCustomObject]@{
        # PropriÃ©tÃ©s essentielles
        Id               = $Id
        Title            = $Title
        Description      = $Description
        Status           = $Status

        # PropriÃ©tÃ©s de relation
        Parent           = $null
        Children         = New-Object System.Collections.ArrayList
        Dependencies     = New-Object System.Collections.ArrayList
        DependentTasks   = New-Object System.Collections.ArrayList

        # PropriÃ©tÃ©s additionnelles
        Level            = 0
        Order            = 0
        CreatedDate      = Get-Date
        ModifiedDate     = Get-Date
        OriginalMarkdown = ""

        # MÃ©thodes
        ChangeStatus     = {
            param([TaskStatus]$newStatus)
            $this.Status = $newStatus
            $this.ModifiedDate = Get-Date
        }

        AddChild         = {
            param([PSCustomObject]$child)
            $child.Parent = $this
            $child.Level = $this.Level + 1
            $child.Order = $this.Children.Count
            [void]$this.Children.Add($child)
            $this.ModifiedDate = Get-Date
        }

        RemoveChild      = {
            param([PSCustomObject]$child)
            $index = $this.Children.IndexOf($child)
            if ($index -ge 0) {
                $this.Children.RemoveAt($index)
                $child.Parent = $null

                # RÃ©organiser les ordres des enfants restants
                for ($i = $index; $i -lt $this.Children.Count; $i++) {
                    $this.Children[$i].Order = $i
                }

                $this.ModifiedDate = Get-Date
            }
        }

        AddDependency    = {
            param([PSCustomObject]$dependency)
            if (-not $this.Dependencies.Contains($dependency)) {
                [void]$this.Dependencies.Add($dependency)
                [void]$dependency.DependentTasks.Add($this)
                $this.ModifiedDate = Get-Date
            }
        }

        RemoveDependency = {
            param([PSCustomObject]$dependency)
            $index = $this.Dependencies.IndexOf($dependency)
            if ($index -ge 0) {
                $this.Dependencies.RemoveAt($index)
                $dependencyIndex = $dependency.DependentTasks.IndexOf($this)
                if ($dependencyIndex -ge 0) {
                    $dependency.DependentTasks.RemoveAt($dependencyIndex)
                }
                $this.ModifiedDate = Get-Date
            }
        }

        ToMarkdown       = {
            $indent = "  " * $this.Level
            $statusMark = switch ($this.Status) {
                ([TaskStatus]::Complete) { "[x]" }
                ([TaskStatus]::InProgress) { "[~]" }
                ([TaskStatus]::Blocked) { "[!]" }
                default { "[ ]" }
            }

            $markdown = "$indent- $statusMark **$($this.Id)** $($this.Title)"
            if (-not [string]::IsNullOrEmpty($this.Description)) {
                $markdown += "`n$indent  $($this.Description)"
            }

            return $markdown
        }

        Clone            = {
            $clone = New-RoadmapTask -Id $this.Id -Title $this.Title -Description $this.Description -Status $this.Status
            $clone.Level = $this.Level
            $clone.Order = $this.Order
            $clone.CreatedDate = $this.CreatedDate
            $clone.ModifiedDate = $this.ModifiedDate
            $clone.OriginalMarkdown = $this.OriginalMarkdown

            return $clone
        }
    }

    return $task
}

# Fonction pour crÃ©er un nouvel arbre de roadmap
function New-RoadmapTree {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Title = "Roadmap",

        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )

    $root = New-RoadmapTask -Id "0" -Title "Root"
    $root.Level = -1

    $tree = [PSCustomObject]@{
        # PropriÃ©tÃ©s
        Root                        = $root
        AllTasks                    = New-Object System.Collections.ArrayList
        TasksById                   = @{}
        Title                       = $Title
        Description                 = $Description
        CreatedDate                 = Get-Date
        ModifiedDate                = Get-Date
        FilePath                    = ""

        # MÃ©thodes
        AddTask                     = {
            param(
                [Parameter(Mandatory = $true)]
                [PSCustomObject]$task,

                [Parameter(Mandatory = $false)]
                [PSCustomObject]$parent = $null
            )

            if ($null -eq $parent) {
                $parent = $this.Root
            }

            $parent.AddChild.Invoke($task)
            [void]$this.AllTasks.Add($task)
            $this.TasksById[$task.Id] = $task
            $this.ModifiedDate = Get-Date
        }

        RemoveTask                  = {
            param([PSCustomObject]$task)

            if ($null -ne $task.Parent) {
                $task.Parent.RemoveChild.Invoke($task)
            }

            # Supprimer rÃ©cursivement tous les enfants
            foreach ($child in $task.Children.ToArray()) {
                $this.RemoveTask.Invoke($child)
            }

            # Supprimer les rÃ©fÃ©rences dans les dÃ©pendances
            foreach ($dependency in $task.Dependencies.ToArray()) {
                $task.RemoveDependency.Invoke($dependency)
            }

            foreach ($dependent in $task.DependentTasks.ToArray()) {
                $dependent.RemoveDependency.Invoke($task)
            }

            $this.AllTasks.Remove($task)
            $this.TasksById.Remove($task.Id)
            $this.ModifiedDate = Get-Date
        }

        GetTaskById                 = {
            param([string]$id)

            return $this.TasksById[$id]
        }

        TraverseDepthFirst          = {
            $result = New-Object System.Collections.ArrayList
            $this.TraverseDepthFirstRecursive.Invoke($this.Root, $result)
            return $result
        }

        TraverseDepthFirstRecursive = {
            param(
                [PSCustomObject]$node,
                [System.Collections.ArrayList]$result
            )

            if ($node -ne $this.Root) {
                [void]$result.Add($node)
            }

            foreach ($child in $node.Children) {
                $this.TraverseDepthFirstRecursive.Invoke($child, $result)
            }
        }

        TraverseBreadthFirst        = {
            $result = New-Object System.Collections.ArrayList
            $queue = New-Object System.Collections.Queue

            foreach ($child in $this.Root.Children) {
                $queue.Enqueue($child)
            }

            while ($queue.Count -gt 0) {
                $node = $queue.Dequeue()
                [void]$result.Add($node)

                foreach ($child in $node.Children) {
                    $queue.Enqueue($child)
                }
            }

            return $result
        }

        FilterTasks                 = {
            param([scriptblock]$filter)

            $result = New-Object System.Collections.ArrayList

            foreach ($task in $this.AllTasks) {
                if (& $filter $task) {
                    [void]$result.Add($task)
                }
            }

            return $result
        }

        SearchTasks                 = {
            param([string]$searchText)

            $result = New-Object System.Collections.ArrayList
            $searchText = $searchText.ToLower()

            foreach ($task in $this.AllTasks) {
                if ($task.Title.ToLower().Contains($searchText) -or
                    $task.Description.ToLower().Contains($searchText) -or
                    $task.Id.ToLower().Contains($searchText)) {
                    [void]$result.Add($task)
                }
            }

            return $result
        }

        ValidateStructure           = {
            # VÃ©rifier que tous les IDs sont uniques
            $uniqueIds = @{}
            foreach ($task in $this.AllTasks) {
                if ($uniqueIds.ContainsKey($task.Id)) {
                    return $false
                }
                $uniqueIds[$task.Id] = $true
            }

            # VÃ©rifier que chaque tÃ¢che a un parent correct
            foreach ($task in $this.AllTasks) {
                if ($null -eq $task.Parent) {
                    return $false
                }

                if ($task.Parent -ne $this.Root -and -not $this.AllTasks.Contains($task.Parent)) {
                    return $false
                }
            }

            # VÃ©rifier la cohÃ©rence des niveaux
            foreach ($task in $this.AllTasks) {
                if ($task.Parent -eq $this.Root) {
                    if ($task.Level -ne 0) {
                        return $false
                    }
                } else {
                    if ($task.Level -ne $task.Parent.Level + 1) {
                        return $false
                    }
                }
            }

            return $true
        }

        ToMarkdown                  = {
            $markdown = "# $($this.Title)`n`n"

            if (-not [string]::IsNullOrEmpty($this.Description)) {
                $markdown += "$($this.Description)`n`n"
            }

            foreach ($task in $this.Root.Children) {
                $markdown += $this.TaskToMarkdownRecursive.Invoke($task)
            }

            return $markdown
        }

        TaskToMarkdownRecursive     = {
            param([PSCustomObject]$task)

            $markdown = $task.ToMarkdown.Invoke() + "`n"

            foreach ($child in $task.Children) {
                $markdown += $this.TaskToMarkdownRecursive.Invoke($child)
            }

            return $markdown
        }
    }

    return $tree
}

# Fonction pour charger un arbre de roadmap Ã  partir d'un fichier JSON
function Import-RoadmapTreeFromJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    $json = Get-Content -Path $FilePath -Raw
    $treeData = ConvertFrom-Json -InputObject $json

    $tree = New-RoadmapTree -Title $treeData.Title
    $tree.Description = $treeData.Description

    if ($treeData.CreatedDate) {
        $tree.CreatedDate = $treeData.CreatedDate
    }

    if ($treeData.ModifiedDate) {
        $tree.ModifiedDate = $treeData.ModifiedDate
    }

    if ($treeData.FilePath) {
        $tree.FilePath = $treeData.FilePath
    }

    # Reconstruire l'arbre Ã  partir des tÃ¢ches sÃ©rialisÃ©es
    $taskMap = @{}

    # PremiÃ¨re passe : crÃ©er toutes les tÃ¢ches
    foreach ($taskData in $treeData.AllTasks) {
        $task = New-RoadmapTask -Id $taskData.Id -Title $taskData.Title -Description $taskData.Description -Status $taskData.Status
        $task.Level = $taskData.Level
        $task.Order = $taskData.Order

        if ($taskData.CreatedDate) {
            $task.CreatedDate = $taskData.CreatedDate
        }

        if ($taskData.ModifiedDate) {
            $task.ModifiedDate = $taskData.ModifiedDate
        }

        if ($taskData.OriginalMarkdown) {
            $task.OriginalMarkdown = $taskData.OriginalMarkdown
        }

        $taskMap[$task.Id] = $task
        [void]$tree.AllTasks.Add($task)
        $tree.TasksById[$task.Id] = $task
    }

    # DeuxiÃ¨me passe : Ã©tablir les relations parent-enfant
    foreach ($taskData in $treeData.AllTasks) {
        $task = $taskMap[$taskData.Id]

        if ($taskData.Parent -and $taskData.Parent.Id -ne "0") {
            $parentTask = $taskMap[$taskData.Parent.Id]
            $parentTask.AddChild.Invoke($task)
        } else {
            $tree.Root.AddChild.Invoke($task)
        }
    }

    # TroisiÃ¨me passe : Ã©tablir les dÃ©pendances
    foreach ($taskData in $treeData.AllTasks) {
        $task = $taskMap[$taskData.Id]

        foreach ($dependencyId in $taskData.Dependencies.Id) {
            if ($taskMap.ContainsKey($dependencyId)) {
                $dependency = $taskMap[$dependencyId]
                $task.AddDependency.Invoke($dependency)
            }
        }
    }

    $tree.FilePath = $FilePath
    return $tree
}

# Fonction pour enregistrer un arbre de roadmap dans un fichier JSON
function Export-RoadmapTreeToJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$RoadmapTree,

        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $json = ConvertTo-Json -InputObject $RoadmapTree -Depth 5
    $json | Out-File -FilePath $FilePath -Encoding UTF8
}

# Fonction pour exporter un arbre de roadmap en markdown
function Export-RoadmapTreeToMarkdown {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$RoadmapTree,

        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $markdown = $RoadmapTree.ToMarkdown.Invoke()
    $markdown | Out-File -FilePath $FilePath -Encoding UTF8
}

# Fonction pour parser un fichier markdown en arbre de roadmap
function ConvertFrom-MarkdownToRoadmapTree {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    $content = Get-Content -Path $FilePath -Encoding UTF8 -Raw
    $lines = $content -split "`n"

    # Extraire le titre et la description
    $title = "Roadmap"
    $description = ""

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^#\s+(.+)$') {
            $title = $matches[1]

            # Extraire la description (lignes non vides aprÃ¨s le titre jusqu'Ã  la premiÃ¨re section)
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

    # CrÃ©er l'arbre de roadmap
    $tree = New-RoadmapTree -Title $title -Description $description
    $tree.FilePath = $FilePath

    # Parser les tÃ¢ches
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

            # DÃ©terminer le statut
            $status = switch ($statusMark) {
                'x' { [TaskStatus]::Complete }
                'X' { [TaskStatus]::Complete }
                '~' { [TaskStatus]::InProgress }
                '!' { [TaskStatus]::Blocked }
                default { [TaskStatus]::Incomplete }
            }

            # Si l'ID n'est pas spÃ©cifiÃ©, en gÃ©nÃ©rer un
            if ([string]::IsNullOrEmpty($id)) {
                $id = "$idCounter"
                $idCounter++
            }

            # CrÃ©er la tÃ¢che
            $task = New-RoadmapTask -Id $id -Title $title -Status $status
            $task.OriginalMarkdown = $line

            # DÃ©terminer le parent en fonction de l'indentation
            if ($indent -gt $currentLevel) {
                # Niveau d'indentation supÃ©rieur, le parent est la derniÃ¨re tÃ¢che ajoutÃ©e
                $currentParent = $taskMap[$currentLevel]
                $currentLevel = $indent
            } elseif ($indent -lt $currentLevel) {
                # Niveau d'indentation infÃ©rieur, remonter dans l'arborescence
                while ($indent -lt $currentLevel -and $currentParent.Parent -ne $tree.Root) {
                    $currentParent = $currentParent.Parent
                    $currentLevel -= 2  # Supposer 2 espaces par niveau
                }
            }

            # Ajouter la tÃ¢che Ã  l'arbre
            $tree.AddTask.Invoke($task, $currentParent)
            $taskMap[$indent] = $task
        }
    }

    return $tree
}

# Exporter les fonctions
Export-ModuleMember -Function New-RoadmapTree, New-RoadmapTask, Import-RoadmapTreeFromJson, Export-RoadmapTreeToJson, Export-RoadmapTreeToMarkdown, ConvertFrom-MarkdownToRoadmapTree


