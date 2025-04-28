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

    # CrÃ©er une nouvelle tÃ¢che directement
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

    $json = Get-Content -Path $FilePath -Raw | ConvertFrom-Json

    # CrÃ©er un nouvel arbre
    $tree = New-RoadmapTree -Title $json.Title -Description $json.Description
    $tree.FilePath = $FilePath

    # Reconstruire l'arbre Ã  partir des donnÃ©es JSON
    foreach ($taskData in $json.Tasks) {
        $task = New-RoadmapTask -Id $taskData.Id -Title $taskData.Title -Description $taskData.Description -Status $taskData.Status
        $parentId = $taskData.ParentId

        if ([string]::IsNullOrEmpty($parentId) -or $parentId -eq "0") {
            $tree.AddTask.Invoke($task)
        } else {
            $parentTask = $tree.TasksById[$parentId]
            $tree.AddTask.Invoke($task, $parentTask)
        }
    }

    # Reconstruire les dÃ©pendances
    foreach ($taskData in $json.Tasks) {
        $task = $tree.TasksById[$taskData.Id]

        foreach ($dependencyId in $taskData.Dependencies) {
            $dependency = $tree.TasksById[$dependencyId]
            $task.AddDependency.Invoke($dependency)
        }
    }

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

    # Convertir l'arbre en structure JSON
    $jsonObj = [PSCustomObject]@{
        Title        = $RoadmapTree.Title
        Description  = $RoadmapTree.Description
        CreatedDate  = $RoadmapTree.CreatedDate
        ModifiedDate = $RoadmapTree.ModifiedDate
        Tasks        = @()
    }

    # Ajouter toutes les tÃ¢ches
    foreach ($task in $RoadmapTree.AllTasks) {
        $taskObj = [PSCustomObject]@{
            Id           = $task.Id
            Title        = $task.Title
            Description  = $task.Description
            Status       = $task.Status
            Level        = $task.Level
            Order        = $task.Order
            ParentId     = if ($task.Parent -eq $RoadmapTree.Root) { "0" } else { $task.Parent.Id }
            Dependencies = @()
        }

        # Ajouter les dÃ©pendances
        foreach ($dependency in $task.Dependencies) {
            $taskObj.Dependencies += $dependency.Id
        }

        $jsonObj.Tasks += $taskObj
    }

    # Convertir en JSON et enregistrer
    $json = $jsonObj | ConvertTo-Json -Depth 10
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

    # GÃ©nÃ©rer le markdown
    $markdown = "# $($RoadmapTree.Title)`n`n"

    if (-not [string]::IsNullOrEmpty($RoadmapTree.Description)) {
        $markdown += "$($RoadmapTree.Description)`n`n"
    }

    # Fonction rÃ©cursive pour gÃ©nÃ©rer le markdown des tÃ¢ches
    function Get-TaskMarkdown {
        param(
            [PSCustomObject]$Task
        )

        $indent = "  " * $Task.Level
        $statusMark = switch ($Task.Status) {
            ([TaskStatus]::Complete) { "[x]" }
            ([TaskStatus]::InProgress) { "[~]" }
            ([TaskStatus]::Blocked) { "[!]" }
            default { "[ ]" }
        }

        $result = "$indent- $statusMark **$($Task.Id)** $($Task.Title)`n"

        if (-not [string]::IsNullOrEmpty($Task.Description)) {
            $result += "$indent  $($Task.Description)`n"
        }

        foreach ($child in $Task.Children) {
            $result += Get-TaskMarkdown -Task $child
        }

        return $result
    }

    # Ajouter toutes les tÃ¢ches de premier niveau
    foreach ($task in $RoadmapTree.Root.Children) {
        $markdown += Get-TaskMarkdown -Task $task
    }

    # Enregistrer le markdown
    $markdown | Out-File -FilePath $FilePath -Encoding UTF8
}

# Exporter les classes et fonctions
Export-ModuleMember -Function New-RoadmapTree, New-RoadmapTask, Import-RoadmapTreeFromJson, Export-RoadmapTreeToJson, Export-RoadmapTreeToMarkdown
Export-ModuleMember -Variable TaskStatus


