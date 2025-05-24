# Format-Converters.psm1
# Module pour convertir differents formats de texte en format roadmap et vice versa

# Fonction pour convertir du Markdown en format roadmap
function ConvertFrom-Markdown {
    param (
        [Parameter(Mandatory = $true)]
        [string]$MarkdownText
    )
    
    # Initialiser le resultat
    $result = @()
    
    # Diviser le texte en lignes
    $lines = $MarkdownText -split "`r?`n"
    
    # Variables pour suivre le niveau d'indentation actuel
    $currentLevel = 0
    $inCodeBlock = $false
    
    # Traiter chaque ligne
    foreach ($line in $lines) {
        # Ignorer les lignes vides
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        
        # Gerer les blocs de code
        if ($line -match "^```") {
            $inCodeBlock = -not $inCodeBlock
            continue
        }
        
        if ($inCodeBlock) {
            continue
        }
        
        # Detecter les titres
        if ($line -match "^(#+)\s+(.*)$") {
            $headerLevel = $matches[1].Length
            $headerText = $matches[2].Trim()
            
            # Ajouter le titre comme une phase
            $indent = "  " * ($headerLevel - 1)
            $result += "$indent$headerText"
            $currentLevel = $headerLevel
            continue
        }
        
        # Detecter les listes a puces
        if ($line -match "^(\s*)[-*+]\s+(.*)$") {
            $indent = $matches[1]
            $listItem = $matches[2].Trim()
            
            # Calculer le niveau d'indentation
            $indentLevel = [Math]::Floor($indent.Length / 2) + 1
            
            # Ajouter l'element de liste
            $indentStr = "  " * $indentLevel
            $result += "$indentStr$listItem"
            continue
        }
        
        # Detecter les listes numerotees
        if ($line -match "^(\s*)\d+\.\s+(.*)$") {
            $indent = $matches[1]
            $listItem = $matches[2].Trim()
            
            # Calculer le niveau d'indentation
            $indentLevel = [Math]::Floor($indent.Length / 2) + 1
            
            # Ajouter l'element de liste
            $indentStr = "  " * $indentLevel
            $result += "$indentStr$listItem"
            continue
        }
        
        # Traiter les lignes normales
        $result += $line.Trim()
    }
    
    # Joindre les lignes avec des sauts de ligne
    return $result -join "`n"
}

# Fonction pour convertir du CSV en format roadmap
function ConvertFrom-Csv {
    param (
        [Parameter(Mandatory = $true)]
        [string]$CsvText,
        
        [Parameter(Mandatory = $false)]
        [string]$TaskColumn = "Task",
        
        [Parameter(Mandatory = $false)]
        [string]$LevelColumn = "Level",
        
        [Parameter(Mandatory = $false)]
        [string]$PriorityColumn = "Priority",
        
        [Parameter(Mandatory = $false)]
        [string]$TimeEstimateColumn = "TimeEstimate"
    )
    
    # Initialiser le resultat
    $result = @()
    
    try {
        # Convertir le texte CSV en objets
        $csvData = $CsvText | ConvertFrom-Csv
        
        # Verifier si les colonnes requises existent
        if (-not ($csvData | Get-Member -Name $TaskColumn -MemberType NoteProperty)) {
            throw "La colonne '$TaskColumn' n'existe pas dans le CSV"
        }
        
        # Traiter chaque ligne du CSV
        foreach ($row in $csvData) {
            $task = $row.$TaskColumn
            
            # Ignorer les lignes vides
            if ([string]::IsNullOrWhiteSpace($task)) {
                continue
            }
            
            # Determiner le niveau d'indentation
            $level = 0
            if (($csvData | Get-Member -Name $LevelColumn -MemberType NoteProperty) -and 
                -not [string]::IsNullOrWhiteSpace($row.$LevelColumn)) {
                $level = [int]$row.$LevelColumn
            }
            
            # Determiner si la tache est prioritaire
            $priority = ""
            if (($csvData | Get-Member -Name $PriorityColumn -MemberType NoteProperty) -and 
                -not [string]::IsNullOrWhiteSpace($row.$PriorityColumn)) {
                $priorityValue = $row.$PriorityColumn
                if ($priorityValue -eq "1" -or 
                    $priorityValue -eq "True" -or 
                    $priorityValue -eq "Yes" -or 
                    $priorityValue -eq "High" -or 
                    $priorityValue -eq "Urgent") {
                    $priority = " prioritaire"
                }
            }
            
            # Determiner l'estimation de temps
            $timeEstimate = ""
            if (($csvData | Get-Member -Name $TimeEstimateColumn -MemberType NoteProperty) -and 
                -not [string]::IsNullOrWhiteSpace($row.$TimeEstimateColumn)) {
                $timeEstimate = " (" + $row.$TimeEstimateColumn + ")"
            }
            
            # Ajouter la tache au resultat
            $indent = "  " * $level
            $result += "$indent$task$priority$timeEstimate"
        }
    }
    catch {
        Write-Error "Erreur lors de la conversion du CSV: $_"
        return $CsvText
    }
    
    # Joindre les lignes avec des sauts de ligne
    return $result -join "`n"
}

# Fonction pour convertir du JSON en format roadmap
function ConvertFrom-Json {
    param (
        [Parameter(Mandatory = $true)]
        [string]$JsonText,
        
        [Parameter(Mandatory = $false)]
        [string]$TaskProperty = "name",
        
        [Parameter(Mandatory = $false)]
        [string]$SubtasksProperty = "subtasks",
        
        [Parameter(Mandatory = $false)]
        [string]$PriorityProperty = "priority",
        
        [Parameter(Mandatory = $false)]
        [string]$TimeEstimateProperty = "timeEstimate"
    )
    
    # Fonction recursive pour traiter les taches
    function Invoke-Tasks {
        param (
            [Parameter(Mandatory = $true)]
            [PSCustomObject]$Tasks,
            
            [Parameter(Mandatory = $false)]
            [int]$Level = 0
        )
        
        $result = @()
        
        # Si Tasks est un tableau, traiter chaque element
        if ($Tasks -is [array]) {
            foreach ($task in $Tasks) {
                $result += Invoke-Task -Task $task -Level $Level
            }
        }
        # Si Tasks est un objet unique, le traiter directement
        elseif ($Tasks -is [PSCustomObject]) {
            $result += Invoke-Task -Task $Tasks -Level $Level
        }
        
        return $result
    }
    
    # Fonction pour traiter une tache individuelle
    function Invoke-Task {
        param (
            [Parameter(Mandatory = $true)]
            [PSCustomObject]$Task,
            
            [Parameter(Mandatory = $false)]
            [int]$Level = 0
        )
        
        $result = @()
        
        # Verifier si la tache a un nom
        if (-not (Get-Member -InputObject $Task -Name $TaskProperty -MemberType NoteProperty)) {
            return $result
        }
        
        $taskName = $Task.$TaskProperty
        
        # Ignorer les taches sans nom
        if ([string]::IsNullOrWhiteSpace($taskName)) {
            return $result
        }
        
        # Determiner si la tache est prioritaire
        $priority = ""
        if ((Get-Member -InputObject $Task -Name $PriorityProperty -MemberType NoteProperty) -and 
            -not [string]::IsNullOrWhiteSpace($Task.$PriorityProperty)) {
            $priorityValue = $Task.$PriorityProperty
            if ($priorityValue -eq 1 -or 
                $priorityValue -eq $true -or 
                $priorityValue -eq "True" -or 
                $priorityValue -eq "Yes" -or 
                $priorityValue -eq "High" -or 
                $priorityValue -eq "Urgent") {
                $priority = " prioritaire"
            }
        }
        
        # Determiner l'estimation de temps
        $timeEstimate = ""
        if ((Get-Member -InputObject $Task -Name $TimeEstimateProperty -MemberType NoteProperty) -and 
            -not [string]::IsNullOrWhiteSpace($Task.$TimeEstimateProperty)) {
            $timeEstimate = " (" + $Task.$TimeEstimateProperty + ")"
        }
        
        # Ajouter la tache au resultat
        $indent = "  " * $Level
        $result += "$indent$taskName$priority$timeEstimate"
        
        # Traiter les sous-taches si elles existent
        if ((Get-Member -InputObject $Task -Name $SubtasksProperty -MemberType NoteProperty) -and 
            $Task.$SubtasksProperty) {
            $result += Invoke-Tasks -Tasks $Task.$SubtasksProperty -Level ($Level + 1)
        }
        
        return $result
    }
    
    # Initialiser le resultat
    $result = @()
    
    try {
        # Convertir le texte JSON en objets
        $jsonData = Microsoft.PowerShell.Utility\ConvertFrom-Json -InputObject $JsonText
        
        # Traiter les taches
        $result = Invoke-Tasks -Tasks $jsonData
    }
    catch {
        Write-Error "Erreur lors de la conversion du JSON: $_"
        return $JsonText
    }
    
    # Joindre les lignes avec des sauts de ligne
    return $result -join "`n"
}

# Fonction pour convertir du YAML en format roadmap
function ConvertFrom-Yaml {
    param (
        [Parameter(Mandatory = $true)]
        [string]$YamlText
    )
    
    # Verifier si le module PowerShell-Yaml est installe
    if (-not (Get-Module -ListAvailable -Name "powershell-yaml")) {
        Write-Warning "Le module PowerShell-Yaml n'est pas installe. Utilisation de la methode alternative."
        
        # Methode alternative: traiter le YAML comme une liste indentee
        $result = @()
        $lines = $YamlText -split "`r?`n"
        
        foreach ($line in $lines) {
            # Ignorer les lignes vides et les commentaires
            if ([string]::IsNullOrWhiteSpace($line) -or $line.Trim().StartsWith("#")) {
                continue
            }
            
            # Detecter le niveau d'indentation
            if ($line -match "^(\s*)(.+?):\s*(.*)$") {
                $indent = $matches[1]
                $key = $matches[2].Trim()
                $value = $matches[3].Trim()
                
                # Calculer le niveau d'indentation
                $level = [Math]::Floor($indent.Length / 2)
                
                # Ajouter la ligne au resultat
                $indentStr = "  " * $level
                if ([string]::IsNullOrWhiteSpace($value)) {
                    $result += "$indentStr$key"
                } else {
                    $result += "$indentStr$key: $value"
                }
            }
            # Detecter les elements de liste
            elseif ($line -match "^(\s*)-\s+(.*)$") {
                $indent = $matches[1]
                $item = $matches[2].Trim()
                
                # Calculer le niveau d'indentation
                $level = [Math]::Floor($indent.Length / 2) + 1
                
                # Ajouter l'element de liste au resultat
                $indentStr = "  " * $level
                $result += "$indentStr$item"
            }
            # Autres lignes
            else {
                $result += $line.Trim()
            }
        }
        
        return $result -join "`n"
    }
    
    try {
        # Convertir le YAML en objets PowerShell
        $yamlData = ConvertFrom-Yaml -Yaml $YamlText
        
        # Convertir les objets PowerShell en JSON
        $jsonText = ConvertTo-Json -InputObject $yamlData -Depth 10
        
        # Utiliser la fonction ConvertFrom-Json existante
        return ConvertFrom-Json -JsonText $jsonText
    }
    catch {
        Write-Error "Erreur lors de la conversion du YAML: $_"
        return $YamlText
    }
}

# Fonction pour convertir du texte en format roadmap
function ConvertFrom-TextFormat {
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputText,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Auto", "Plain", "Markdown", "CSV", "JSON", "YAML")]
        [string]$Format = "Auto"
    )
    
    # Si le format est Auto, essayer de detecter le format
    if ($Format -eq "Auto") {
        # Verifier si c'est du JSON
        if ($InputText.Trim().StartsWith("{") -or $InputText.Trim().StartsWith("[")) {
            try {
                $null = Microsoft.PowerShell.Utility\ConvertFrom-Json -InputObject $InputText
                $Format = "JSON"
            }
            catch {
                # Ce n'est pas du JSON valide
            }
        }
        
        # Verifier si c'est du CSV
        if ($Format -eq "Auto" -and $InputText.Contains(",") -and ($InputText.Split("`n")[0].Split(",").Count -gt 1)) {
            try {
                $null = $InputText | ConvertFrom-Csv
                $Format = "CSV"
            }
            catch {
                # Ce n'est pas du CSV valide
            }
        }
        
        # Verifier si c'est du Markdown
        if ($Format -eq "Auto" -and ($InputText.Contains("#") -or $InputText.Contains("```") -or $InputText.Contains("*"))) {
            $Format = "Markdown"
        }
        
        # Verifier si c'est du YAML
        if ($Format -eq "Auto" -and $InputText.Contains(":") -and $InputText.Contains("  ")) {
            $Format = "YAML"
        }
        
        # Si aucun format n'a ete detecte, utiliser Plain
        if ($Format -eq "Auto") {
            $Format = "Plain"
        }
    }
    
    # Convertir le texte en fonction du format
    switch ($Format) {
        "Plain" {
            return $InputText
        }
        "Markdown" {
            return ConvertFrom-Markdown -MarkdownText $InputText
        }
        "CSV" {
            return ConvertFrom-Csv -CsvText $InputText
        }
        "JSON" {
            return ConvertFrom-Json -JsonText $InputText
        }
        "YAML" {
            return ConvertFrom-Yaml -YamlText $InputText
        }
    }
}

# Fonction pour convertir le format roadmap en Markdown
function ConvertTo-Markdown {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapText,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeCheckboxes
    )
    
    # Initialiser le resultat
    $result = @()
    
    # Diviser le texte en lignes
    $lines = $RoadmapText -split "`r?`n"
    
    # Traiter chaque ligne
    foreach ($line in $lines) {
        # Ignorer les lignes vides
        if ([string]::IsNullOrWhiteSpace($line)) {
            $result += ""
            continue
        }
        
        # Detecter les titres de section
        if ($line -match "^## (.*)$") {
            $sectionTitle = $matches[1].Trim()
            $result += "# $sectionTitle"
            continue
        }
        
        # Detecter les metadonnees
        if ($line -match "^\*\*([^:]+):\*\* (.*)$") {
            $metaKey = $matches[1].Trim()
            $metaValue = $matches[2].Trim()
            $result += "**$metaKey:** $metaValue"
            continue
        }
        
        # Detecter les taches
        if ($line -match "^(\s*)- \[([ x])\] (.*)$") {
            $indent = $matches[1]
            $checked = $matches[2] -eq "x"
            $taskText = $matches[3].Trim()
            
            # Calculer le niveau d'indentation
            $level = [Math]::Floor($indent.Length / 2) + 1
            
            # Formater la tache en Markdown
            $indentStr = "  " * ($level - 1)
            
            if ($IncludeCheckboxes) {
                $checkbox = $checked ? "[x]" : "[ ]"
                $result += "$indentStr- $checkbox $taskText"
            } else {
                $result += "$indentStr- $taskText"
            }
            
            continue
        }
        
        # Autres lignes
        $result += $line
    }
    
    # Joindre les lignes avec des sauts de ligne
    return $result -join "`n"
}

# Fonction pour convertir le format roadmap en CSV
function ConvertTo-CsvFormat {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapText,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata
    )
    
    # Initialiser le resultat
    $tasks = @()
    $metadata = @{}
    
    # Diviser le texte en lignes
    $lines = $RoadmapText -split "`r?`n"
    
    # Variables pour suivre la section actuelle
    $currentSection = ""
    
    # Traiter chaque ligne
    foreach ($line in $lines) {
        # Ignorer les lignes vides
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        
        # Detecter les titres de section
        if ($line -match "^## (.*)$") {
            $currentSection = $matches[1].Trim()
            continue
        }
        
        # Detecter les metadonnees
        if ($line -match "^\*\*([^:]+):\*\* (.*)$") {
            $metaKey = $matches[1].Trim()
            $metaValue = $matches[2].Trim()
            $metadata[$metaKey] = $metaValue
            continue
        }
        
        # Detecter les taches
        if ($line -match "^(\s*)- \[([ x])\] (.*)$") {
            $indent = $matches[1]
            $checked = $matches[2] -eq "x"
            $taskText = $matches[3].Trim()
            
            # Calculer le niveau d'indentation
            $level = [Math]::Floor($indent.Length / 2)
            
            # Detecter si la tache est prioritaire
            $isPriority = $taskText -match "\[PRIORITAIRE\]|\*\*.*\*\*.*ðŸ”´"
            $taskText = $taskText -replace "\s*\[PRIORITAIRE\]|\s*ðŸ”´", ""
            
            # Detecter l'estimation de temps
            $timeEstimate = ""
            if ($taskText -match "\s*\(([\d\w\s-]+)\)$") {
                $timeEstimate = $matches[1].Trim()
                $taskText = $taskText -replace "\s*\([\d\w\s-]+\)$", ""
            }
            
            # Detecter si c'est une phase
            $isPhase = $taskText -match "^\*\*Phase: (.*)\*\*$"
            if ($isPhase) {
                $taskText = $matches[1].Trim()
            }
            
            # Creer un objet pour la tache
            $task = [PSCustomObject]@{
                "Section" = $currentSection
                "Level" = $level
                "Task" = $taskText
                "IsCompleted" = $checked
                "IsPhase" = $isPhase
                "IsPriority" = $isPriority
                "TimeEstimate" = $timeEstimate
            }
            
            # Ajouter la tache au resultat
            $tasks += $task
        }
    }
    
    # Convertir les taches en CSV
    if ($IncludeMetadata -and $metadata.Count -gt 0) {
        # Ajouter les metadonnees comme des colonnes supplementaires
        foreach ($task in $tasks) {
            foreach ($key in $metadata.Keys) {
                $task | Add-Member -NotePropertyName $key -NotePropertyValue $metadata[$key]
            }
        }
    }
    
    return $tasks | ConvertTo-Csv -NoTypeInformation
}

# Fonction pour convertir le format roadmap en JSON
function ConvertTo-JsonFormat {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapText,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,
        
        [Parameter(Mandatory = $false)]
        [switch]$Hierarchical
    )
    
    # Initialiser le resultat
    $tasks = @()
    $metadata = @{}
    
    # Diviser le texte en lignes
    $lines = $RoadmapText -split "`r?`n"
    
    # Variables pour suivre la section actuelle
    $currentSection = ""
    
    # Traiter chaque ligne
    foreach ($line in $lines) {
        # Ignorer les lignes vides
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        
        # Detecter les titres de section
        if ($line -match "^## (.*)$") {
            $currentSection = $matches[1].Trim()
            continue
        }
        
        # Detecter les metadonnees
        if ($line -match "^\*\*([^:]+):\*\* (.*)$") {
            $metaKey = $matches[1].Trim()
            $metaValue = $matches[2].Trim()
            $metadata[$metaKey] = $metaValue
            continue
        }
        
        # Detecter les taches
        if ($line -match "^(\s*)- \[([ x])\] (.*)$") {
            $indent = $matches[1]
            $checked = $matches[2] -eq "x"
            $taskText = $matches[3].Trim()
            
            # Calculer le niveau d'indentation
            $level = [Math]::Floor($indent.Length / 2)
            
            # Detecter si la tache est prioritaire
            $isPriority = $taskText -match "\[PRIORITAIRE\]|\*\*.*\*\*.*ðŸ”´"
            $taskText = $taskText -replace "\s*\[PRIORITAIRE\]|\s*ðŸ”´", ""
            
            # Detecter l'estimation de temps
            $timeEstimate = ""
            if ($taskText -match "\s*\(([\d\w\s-]+)\)$") {
                $timeEstimate = $matches[1].Trim()
                $taskText = $taskText -replace "\s*\([\d\w\s-]+\)$", ""
            }
            
            # Detecter si c'est une phase
            $isPhase = $taskText -match "^\*\*Phase: (.*)\*\*$"
            if ($isPhase) {
                $taskText = $matches[1].Trim()
            }
            
            # Creer un objet pour la tache
            $task = [PSCustomObject]@{
                "section" = $currentSection
                "level" = $level
                "name" = $taskText
                "isCompleted" = $checked
                "isPhase" = $isPhase
                "priority" = $isPriority
                "timeEstimate" = $timeEstimate
            }
            
            # Ajouter la tache au resultat
            $tasks += $task
        }
    }
    
    # Si hierarchical est specifie, convertir en structure hierarchique
    if ($Hierarchical) {
        $hierarchicalTasks = @()
        $taskStack = @()
        
        foreach ($task in $tasks) {
            $level = $task.level
            
            # Creer un nouvel objet pour la tache
            $newTask = [PSCustomObject]@{
                "name" = $task.name
                "isCompleted" = $task.isCompleted
                "isPhase" = $task.isPhase
                "priority" = $task.priority
                "timeEstimate" = $task.timeEstimate
                "subtasks" = @()
            }
            
            # Si c'est une tache de niveau 0, l'ajouter directement au resultat
            if ($level -eq 0) {
                $hierarchicalTasks += $newTask
                $taskStack = @($newTask)
            }
            # Sinon, l'ajouter comme sous-tache de la tache parente
            else {
                # S'assurer que le niveau parent existe
                if ($level -gt $taskStack.Count) {
                    $level = $taskStack.Count
                }
                
                $parent = $taskStack[$level - 1]
                $parent.subtasks += $newTask
                
                # Mettre a jour la pile de taches
                if ($level -ge $taskStack.Count) {
                    $taskStack += $newTask
                } else {
                    $taskStack[$level] = $newTask
                }
            }
        }
        
        # Convertir en JSON
        if ($IncludeMetadata -and $metadata.Count -gt 0) {
            $result = [PSCustomObject]@{
                "metadata" = $metadata
                "tasks" = $hierarchicalTasks
            }
        } else {
            $result = $hierarchicalTasks
        }
        
        return ConvertTo-Json -InputObject $result -Depth 10
    }
    
    # Convertir en JSON
    if ($IncludeMetadata -and $metadata.Count -gt 0) {
        $result = [PSCustomObject]@{
            "metadata" = $metadata
            "tasks" = $tasks
        }
    } else {
        $result = $tasks
    }
    
    return ConvertTo-Json -InputObject $result -Depth 10
}

# Fonction pour convertir le format roadmap en YAML
function ConvertTo-YamlFormat {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapText,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,
        
        [Parameter(Mandatory = $false)]
        [switch]$Hierarchical
    )
    
    # Verifier si le module PowerShell-Yaml est installe
    if (-not (Get-Module -ListAvailable -Name "powershell-yaml")) {
        Write-Warning "Le module PowerShell-Yaml n'est pas installe. Conversion en YAML non disponible."
        return $RoadmapText
    }
    
    # Convertir d'abord en JSON
    $jsonText = ConvertTo-JsonFormat -RoadmapText $RoadmapText -IncludeMetadata:$IncludeMetadata -Hierarchical:$Hierarchical
    
    # Convertir le JSON en objets PowerShell
    $jsonData = Microsoft.PowerShell.Utility\ConvertFrom-Json -InputObject $jsonText
    
    # Convertir les objets PowerShell en YAML
    return ConvertTo-Yaml -Data $jsonData -OutFile $null
}

# Fonction pour convertir le format roadmap vers un autre format
function ConvertTo-TextFormat {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapText,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Markdown", "CSV", "JSON", "YAML")]
        [string]$Format,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,
        
        [Parameter(Mandatory = $false)]
        [switch]$Hierarchical,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeCheckboxes
    )
    
    # Convertir le texte en fonction du format
    switch ($Format) {
        "Markdown" {
            return ConvertTo-Markdown -RoadmapText $RoadmapText -IncludeCheckboxes:$IncludeCheckboxes
        }
        "CSV" {
            return ConvertTo-CsvFormat -RoadmapText $RoadmapText -IncludeMetadata:$IncludeMetadata
        }
        "JSON" {
            return ConvertTo-JsonFormat -RoadmapText $RoadmapText -IncludeMetadata:$IncludeMetadata -Hierarchical:$Hierarchical
        }
        "YAML" {
            return ConvertTo-YamlFormat -RoadmapText $RoadmapText -IncludeMetadata:$IncludeMetadata -Hierarchical:$Hierarchical
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function ConvertFrom-TextFormat, ConvertTo-TextFormat

