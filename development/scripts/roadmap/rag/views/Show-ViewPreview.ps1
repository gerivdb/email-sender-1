# Show-ViewPreview.ps1
# Script pour prévisualiser une vue personnalisée
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,
    
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "HTML", "Markdown")]
    [string]$OutputFormat = "Console",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        $color = switch ($Level) {
            "Info" { "White" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            "Success" { "Green" }
            "Debug" { "Gray" }
        }
        
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Fonction pour charger une configuration de vue
function Get-ViewConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    
    Write-Log "Chargement de la configuration depuis : $ConfigPath" -Level "Info"
    
    if (-not (Test-Path -Path $ConfigPath)) {
        Write-Log "Le fichier de configuration n'existe pas : $ConfigPath" -Level "Error"
        return $null
    }
    
    try {
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json -AsHashtable
        Write-Log "Configuration chargée avec succès." -Level "Success"
        return $config
    } catch {
        Write-Log "Erreur lors du chargement de la configuration : $_" -Level "Error"
        return $null
    }
}

# Fonction pour charger un fichier de roadmap
function Get-RoadmapContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath
    )
    
    Write-Log "Chargement du fichier de roadmap : $RoadmapPath" -Level "Info"
    
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Log "Le fichier de roadmap n'existe pas : $RoadmapPath" -Level "Error"
        return $null
    }
    
    try {
        $content = Get-Content -Path $RoadmapPath -Raw
        Write-Log "Fichier de roadmap chargé avec succès." -Level "Success"
        return $content
    } catch {
        Write-Log "Erreur lors du chargement du fichier de roadmap : $_" -Level "Error"
        return $null
    }
}

# Fonction pour extraire les tâches d'un fichier markdown
function Get-TasksFromMarkdown {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Log "Extraction des tâches du fichier markdown..." -Level "Info"
    
    $tasks = @()
    $lines = $Content -split "`r?`n"
    $currentSection = ""
    $currentIndentLevel = 0
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Détecter les sections (titres)
        if ($line -match '^#+\s+(.+)$') {
            $currentSection = $matches[1].Trim()
            continue
        }
        
        # Détecter les tâches (lignes avec cases à cocher)
        if ($line -match '^\s*-\s+\[([ xX])\]\s+(?:\*\*([^*]+)\*\*)?\s*(.+)$') {
            $indentation = $line -replace '^(\s*).*$', '$1'
            $indentLevel = $indentation.Length
            $status = if ($matches[1] -match '[xX]') { "Terminé" } else { "À faire" }
            $id = if ($matches[2]) { $matches[2].Trim() } else { "" }
            $description = $matches[3].Trim()
            
            # Extraire les métadonnées
            $priority = "Moyenne"  # Valeur par défaut
            $category = "Non classé"  # Valeur par défaut
            $tags = @()
            
            # Détecter la priorité
            if ($description -match '#priority:(high|haute)') {
                $priority = "Haute"
            } elseif ($description -match '#priority:(low|basse)') {
                $priority = "Basse"
            }
            
            # Détecter la catégorie
            if ($description -match '#category:(\w+)') {
                $category = $matches[1]
            } elseif ($description -match '\(category:(\w+)\)') {
                $category = $matches[1]
            }
            
            # Détecter les tags
            $tagMatches = [regex]::Matches($description, '#(\w+)')
            foreach ($match in $tagMatches) {
                $tag = $match.Groups[1].Value
                if ($tag -notmatch '^(priority|category):') {
                    $tags += $tag
                }
            }
            
            # Créer l'objet tâche
            $task = @{
                ID = $id
                Description = $description -replace '#\w+', '' -replace '\([^)]+\)', ''  # Nettoyer la description
                Status = $status
                Priority = $priority
                Category = $category
                Tags = $tags
                Section = $currentSection
                IndentLevel = $indentLevel
                LineNumber = $i + 1
            }
            
            $tasks += $task
        }
    }
    
    Write-Log "Extraction terminée. $($tasks.Count) tâches trouvées." -Level "Success"
    
    return $tasks
}

# Fonction pour filtrer les tâches selon les critères
function Get-FilteredTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Tasks,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Configuration
    )
    
    Write-Log "Filtrage des tâches selon les critères..." -Level "Info"
    
    # Vérifier si la configuration contient des critères
    if (-not $Configuration.ContainsKey("Criteria") -or $Configuration.Criteria.Count -eq 0) {
        Write-Log "La configuration ne contient pas de critères." -Level "Warning"
        return $Tasks
    }
    
    $filteredTasks = @()
    $criteria = $Configuration.Criteria
    $combinationMode = if ($Configuration.ContainsKey("Combination")) { $Configuration.Combination.Mode } else { "AND" }
    
    foreach ($task in $Tasks) {
        $matchesCriteria = $true
        $criteriaResults = @{}
        
        # Vérifier chaque type de critère
        foreach ($criteriaType in $criteria.Keys) {
            $criteriaValues = $criteria[$criteriaType]
            $taskValue = $null
            
            # Obtenir la valeur de la tâche pour ce critère
            switch ($criteriaType) {
                "Status" { $taskValue = $task.Status }
                "Priority" { $taskValue = $task.Priority }
                "Category" { $taskValue = $task.Category }
                "Tags" { $taskValue = $task.Tags }
                default { $taskValue = $null }
            }
            
            # Vérifier si la valeur de la tâche correspond à l'un des critères
            $matches = $false
            
            if ($null -ne $taskValue) {
                if ($taskValue -is [array]) {
                    # Pour les tableaux (comme les tags), vérifier s'il y a une intersection
                    foreach ($value in $criteriaValues) {
                        if ($taskValue -contains $value) {
                            $matches = $true
                            break
                        }
                    }
                } else {
                    # Pour les valeurs simples, vérifier si la valeur est dans la liste
                    $matches = $criteriaValues -contains $taskValue
                }
            }
            
            $criteriaResults[$criteriaType] = $matches
            
            # Si le mode est AND et un critère ne correspond pas, on peut arrêter
            if ($combinationMode -eq "AND" -and -not $matches) {
                $matchesCriteria = $false
                break
            }
        }
        
        # Si le mode est OR, vérifier si au moins un critère correspond
        if ($combinationMode -eq "OR") {
            $matchesCriteria = $criteriaResults.Values -contains $true
        }
        
        # Si le mode est CUSTOM, appliquer les règles personnalisées
        if ($combinationMode -eq "CUSTOM" -and $Configuration.ContainsKey("Combination") -and $Configuration.Combination.ContainsKey("Rules")) {
            $rules = $Configuration.Combination.Rules
            $criteriaTypes = $criteriaResults.Keys
            
            # Réinitialiser le résultat
            $matchesCriteria = $true
            
            # Appliquer les règles entre paires de critères
            for ($i = 0; $i -lt $criteriaTypes.Count; $i++) {
                for ($j = $i + 1; $j -lt $criteriaTypes.Count; $j++) {
                    $criteria1 = $criteriaTypes[$i]
                    $criteria2 = $criteriaTypes[$j]
                    $ruleName = "$criteria1-$criteria2"
                    
                    if ($rules.ContainsKey($ruleName)) {
                        $rule = $rules[$ruleName]
                        $result1 = $criteriaResults[$criteria1]
                        $result2 = $criteriaResults[$criteria2]
                        
                        $combinedResult = if ($rule -eq "AND") {
                            $result1 -and $result2
                        } else {
                            $result1 -or $result2
                        }
                        
                        # Si une règle n'est pas satisfaite, la tâche ne correspond pas
                        if (-not $combinedResult) {
                            $matchesCriteria = $false
                            break
                        }
                    }
                }
                
                if (-not $matchesCriteria) {
                    break
                }
            }
        }
        
        # Ajouter la tâche si elle correspond aux critères
        if ($matchesCriteria) {
            $filteredTasks += $task
        }
    }
    
    Write-Log "Filtrage terminé. $($filteredTasks.Count) tâches correspondent aux critères." -Level "Success"
    
    return $filteredTasks
}

# Fonction pour générer la prévisualisation au format console
function New-ConsolePreview {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Tasks,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Configuration
    )
    
    Write-Log "Génération de la prévisualisation au format console..." -Level "Info"
    
    # Afficher l'en-tête
    Write-Host "`n=== PRÉVISUALISATION DE LA VUE : $($Configuration.Name) ===`n" -ForegroundColor Cyan
    
    # Afficher les critères
    Write-Host "Critères :" -ForegroundColor Yellow
    foreach ($criteriaType in $Configuration.Criteria.Keys) {
        $values = $Configuration.Criteria[$criteriaType] -join ", "
        Write-Host "  $criteriaType : $values"
    }
    
    # Afficher le mode de combinaison
    if ($Configuration.ContainsKey("Combination")) {
        Write-Host "Mode de combinaison : $($Configuration.Combination.Mode)" -ForegroundColor Yellow
        
        if ($Configuration.Combination.Mode -eq "CUSTOM" -and $Configuration.Combination.ContainsKey("Rules")) {
            Write-Host "Règles personnalisées :"
            foreach ($ruleName in $Configuration.Combination.Rules.Keys) {
                $ruleValue = $Configuration.Combination.Rules[$ruleName]
                Write-Host "  $ruleName : $ruleValue"
            }
        }
    }
    
    # Afficher les tâches
    Write-Host "`nTâches correspondantes ($($Tasks.Count)) :" -ForegroundColor Yellow
    
    $currentSection = ""
    
    foreach ($task in $Tasks) {
        # Afficher la section si elle a changé
        if ($task.Section -ne $currentSection) {
            $currentSection = $task.Section
            Write-Host "`n## $currentSection" -ForegroundColor Green
        }
        
        # Calculer l'indentation
        $indent = "  " * [Math]::Max(0, [Math]::Floor($task.IndentLevel / 2))
        
        # Afficher la tâche
        $statusMark = if ($task.Status -eq "Terminé") { "[x]" } else { "[ ]" }
        $idText = if (-not [string]::IsNullOrEmpty($task.ID)) { "**$($task.ID)** " } else { "" }
        $priorityColor = switch ($task.Priority) {
            "Haute" { "Red" }
            "Moyenne" { "Yellow" }
            "Basse" { "Gray" }
            default { "White" }
        }
        
        Write-Host "$indent- $statusMark $idText" -NoNewline
        Write-Host $task.Description.Trim() -ForegroundColor $priorityColor
    }
    
    Write-Host "`n=== FIN DE LA PRÉVISUALISATION ===`n" -ForegroundColor Cyan
}

# Fonction pour générer la prévisualisation au format markdown
function New-MarkdownPreview {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Tasks,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Configuration,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    Write-Log "Génération de la prévisualisation au format markdown..." -Level "Info"
    
    # Créer le contenu markdown
    $markdown = "# Vue personnalisée : $($Configuration.Name)`n`n"
    $markdown += "Date de génération : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
    
    # Ajouter les critères
    $markdown += "## Critères`n`n"
    foreach ($criteriaType in $Configuration.Criteria.Keys) {
        $values = $Configuration.Criteria[$criteriaType] -join ", "
        $markdown += "- **$criteriaType** : $values`n"
    }
    
    # Ajouter le mode de combinaison
    if ($Configuration.ContainsKey("Combination")) {
        $markdown += "`n**Mode de combinaison** : $($Configuration.Combination.Mode)`n"
        
        if ($Configuration.Combination.Mode -eq "CUSTOM" -and $Configuration.Combination.ContainsKey("Rules")) {
            $markdown += "`nRègles personnalisées :`n"
            foreach ($ruleName in $Configuration.Combination.Rules.Keys) {
                $ruleValue = $Configuration.Combination.Rules[$ruleName]
                $markdown += "- $ruleName : $ruleValue`n"
            }
        }
    }
    
    # Ajouter les tâches
    $markdown += "`n## Tâches correspondantes ($($Tasks.Count))`n"
    
    $currentSection = ""
    
    foreach ($task in $Tasks) {
        # Ajouter la section si elle a changé
        if ($task.Section -ne $currentSection) {
            $currentSection = $task.Section
            $markdown += "`n### $currentSection`n"
        }
        
        # Calculer l'indentation
        $indent = "  " * [Math]::Max(0, [Math]::Floor($task.IndentLevel / 2))
        
        # Ajouter la tâche
        $statusMark = if ($task.Status -eq "Terminé") { "[x]" } else { "[ ]" }
        $idText = if (-not [string]::IsNullOrEmpty($task.ID)) { "**$($task.ID)** " } else { "" }
        
        $markdown += "$indent- $statusMark $idText$($task.Description.Trim())"
        
        # Ajouter les métadonnées
        $metadata = @()
        $metadata += "**Priorité** : $($task.Priority)"
        $metadata += "**Catégorie** : $($task.Category)"
        
        if ($task.Tags.Count -gt 0) {
            $metadata += "**Tags** : " + ($task.Tags -join ", ")
        }
        
        $markdown += " (" + ($metadata -join ", ") + ")`n"
    }
    
    # Sauvegarder le fichier markdown
    try {
        $markdown | Set-Content -Path $OutputPath -Encoding UTF8
        Write-Log "Prévisualisation markdown sauvegardée dans : $OutputPath" -Level "Success"
        return $true
    } catch {
        Write-Log "Erreur lors de la sauvegarde de la prévisualisation markdown : $_" -Level "Error"
        return $false
    }
}

# Fonction pour générer la prévisualisation au format HTML
function New-HtmlPreview {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Tasks,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Configuration,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    Write-Log "Génération de la prévisualisation au format HTML..." -Level "Info"
    
    # Créer le contenu HTML
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vue personnalisée : $($Configuration.Name)</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .criteria {
            background-color: #f8f9fa;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .task {
            margin-bottom: 10px;
            padding-left: 20px;
        }
        .task-completed {
            text-decoration: line-through;
            color: #7f8c8d;
        }
        .priority-high {
            color: #e74c3c;
            font-weight: bold;
        }
        .priority-medium {
            color: #f39c12;
        }
        .priority-low {
            color: #7f8c8d;
        }
        .metadata {
            font-size: 0.9em;
            color: #7f8c8d;
            margin-left: 10px;
        }
        .section {
            margin-top: 20px;
            border-bottom: 1px solid #eee;
            padding-bottom: 5px;
        }
        .timestamp {
            color: #7f8c8d;
            font-size: 0.9em;
            margin-top: 30px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Vue personnalisée : $($Configuration.Name)</h1>
        <p>Date de génération : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        
        <div class="criteria">
            <h2>Critères</h2>
            <ul>
"@

    # Ajouter les critères
    foreach ($criteriaType in $Configuration.Criteria.Keys) {
        $values = $Configuration.Criteria[$criteriaType] -join ", "
        $html += "                <li><strong>$criteriaType</strong> : $values</li>`n"
    }

    $html += @"
            </ul>
            
"@

    # Ajouter le mode de combinaison
    if ($Configuration.ContainsKey("Combination")) {
        $html += "            <p><strong>Mode de combinaison</strong> : $($Configuration.Combination.Mode)</p>`n"
        
        if ($Configuration.Combination.Mode -eq "CUSTOM" -and $Configuration.Combination.ContainsKey("Rules")) {
            $html += "            <p>Règles personnalisées :</p>`n"
            $html += "            <ul>`n"
            
            foreach ($ruleName in $Configuration.Combination.Rules.Keys) {
                $ruleValue = $Configuration.Combination.Rules[$ruleName]
                $html += "                <li>$ruleName : $ruleValue</li>`n"
            }
            
            $html += "            </ul>`n"
        }
    }

    $html += @"
        </div>
        
        <h2>Tâches correspondantes ($($Tasks.Count))</h2>
        
"@

    # Ajouter les tâches
    $currentSection = ""
    
    foreach ($task in $Tasks) {
        # Ajouter la section si elle a changé
        if ($task.Section -ne $currentSection) {
            $currentSection = $task.Section
            $html += "        <div class='section'>`n"
            $html += "            <h3>$currentSection</h3>`n"
            $html += "        </div>`n"
        }
        
        # Calculer l'indentation
        $indentLevel = [Math]::Max(0, [Math]::Floor($task.IndentLevel / 2))
        $indentPx = $indentLevel * 20
        
        # Déterminer les classes CSS
        $taskClass = if ($task.Status -eq "Terminé") { "task task-completed" } else { "task" }
        $priorityClass = switch ($task.Priority) {
            "Haute" { "priority-high" }
            "Moyenne" { "priority-medium" }
            "Basse" { "priority-low" }
            default { "" }
        }
        
        # Ajouter la tâche
        $statusMark = if ($task.Status -eq "Terminé") { "☑" } else { "☐" }
        $idText = if (-not [string]::IsNullOrEmpty($task.ID)) { "<strong>$($task.ID)</strong> " } else { "" }
        
        $html += "        <div class='$taskClass' style='margin-left: ${indentPx}px;'>`n"
        $html += "            <span>$statusMark $idText<span class='$priorityClass'>$($task.Description.Trim())</span></span>`n"
        
        # Ajouter les métadonnées
        $html += "            <span class='metadata'>["
        $html += "Priorité: $($task.Priority), "
        $html += "Catégorie: $($task.Category)"
        
        if ($task.Tags.Count -gt 0) {
            $html += ", Tags: " + ($task.Tags -join ", ")
        }
        
        $html += "]</span>`n"
        $html += "        </div>`n"
    }

    $html += @"
        
        <p class="timestamp">Généré le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
</body>
</html>
"@

    # Sauvegarder le fichier HTML
    try {
        $html | Set-Content -Path $OutputPath -Encoding UTF8
        Write-Log "Prévisualisation HTML sauvegardée dans : $OutputPath" -Level "Success"
        return $true
    } catch {
        Write-Log "Erreur lors de la sauvegarde de la prévisualisation HTML : $_" -Level "Error"
        return $false
    }
}

# Fonction principale
function Show-ViewPreview {
    [CmdletBinding()]
    param (
        [string]$ConfigPath,
        [string]$RoadmapPath,
        [string]$OutputFormat,
        [string]$OutputPath
    )
    
    Write-Log "Démarrage de la prévisualisation de vue personnalisée..." -Level "Info"
    
    # Charger la configuration
    $config = if (-not [string]::IsNullOrEmpty($ConfigPath) -and (Test-Path -Path $ConfigPath)) {
        Get-ViewConfiguration -ConfigPath $ConfigPath
    } else {
        Write-Log "Aucune configuration fournie, création d'une configuration de test." -Level "Warning"
        
        @{
            Name = "Vue de test"
            Criteria = @{
                Status = @("À faire", "En cours")
                Priority = @("Haute", "Moyenne")
                Category = @("Développement")
            }
            Combination = @{
                Mode = "AND"
            }
            CreatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Type = "Console"
        }
    }
    
    if ($null -eq $config) {
        Write-Log "Impossible de charger ou créer une configuration." -Level "Error"
        return $false
    }
    
    # Charger le fichier de roadmap
    $roadmapContent = if (-not [string]::IsNullOrEmpty($RoadmapPath) -and (Test-Path -Path $RoadmapPath)) {
        Get-RoadmapContent -RoadmapPath $RoadmapPath
    } else {
        Write-Log "Aucun fichier de roadmap fourni, création d'un contenu de test." -Level "Warning"
        
        @"
# Roadmap de test

## Développement

- [ ] **1** Tâche de développement prioritaire #priority:high #important
  - [ ] **1.1** Sous-tâche de développement #category:development
  - [x] **1.2** Sous-tâche terminée #category:development

## Documentation

- [ ] **2** Tâche de documentation (category:documentation)
  - [ ] **2.1** Sous-tâche de documentation #priority:low

## Tests

- [ ] **3** Tâche de test #category:testing #priority:medium
  - [ ] **3.1** Sous-tâche de test
"@
    }
    
    if ($null -eq $roadmapContent) {
        Write-Log "Impossible de charger ou créer un contenu de roadmap." -Level "Error"
        return $false
    }
    
    # Extraire les tâches du fichier markdown
    $tasks = Get-TasksFromMarkdown -Content $roadmapContent
    
    if ($tasks.Count -eq 0) {
        Write-Log "Aucune tâche trouvée dans le fichier de roadmap." -Level "Warning"
        return $false
    }
    
    # Filtrer les tâches selon les critères
    $filteredTasks = Get-FilteredTasks -Tasks $tasks -Configuration $config
    
    if ($filteredTasks.Count -eq 0) {
        Write-Log "Aucune tâche ne correspond aux critères." -Level "Warning"
    }
    
    # Générer la prévisualisation selon le format demandé
    switch ($OutputFormat) {
        "Console" {
            New-ConsolePreview -Tasks $filteredTasks -Configuration $config
        }
        "Markdown" {
            if ([string]::IsNullOrEmpty($OutputPath)) {
                $OutputPath = Join-Path -Path (Get-Location) -ChildPath "view_preview_$([DateTime]::Now.ToString('yyyyMMdd_HHmmss')).md"
            }
            
            New-MarkdownPreview -Tasks $filteredTasks -Configuration $config -OutputPath $OutputPath
        }
        "HTML" {
            if ([string]::IsNullOrEmpty($OutputPath)) {
                $OutputPath = Join-Path -Path (Get-Location) -ChildPath "view_preview_$([DateTime]::Now.ToString('yyyyMMdd_HHmmss')).html"
            }
            
            New-HtmlPreview -Tasks $filteredTasks -Configuration $config -OutputPath $OutputPath
        }
    }
    
    return $true
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Show-ViewPreview -ConfigPath $ConfigPath -RoadmapPath $RoadmapPath -OutputFormat $OutputFormat -OutputPath $OutputPath
}
