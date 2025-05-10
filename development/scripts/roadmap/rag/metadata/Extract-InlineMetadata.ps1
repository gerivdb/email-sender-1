# Extract-InlineMetadata.ps1
# Script pour extraire les métadonnées inline des tâches dans les fichiers markdown de roadmap
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [string]$Content,
    
    [Parameter(Mandatory = $false)]
    [switch]$DetectTags,
    
    [Parameter(Mandatory = $false)]
    [switch]$DetectAttributes,
    
    [Parameter(Mandatory = $false)]
    [switch]$DetectDates,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown", "CSV")]
    [string]$OutputFormat = "JSON"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "utils"
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

# Fonction pour extraire les métadonnées inline
function Get-InlineMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $false)]
        [switch]$DetectTags,
        
        [Parameter(Mandatory = $false)]
        [switch]$DetectAttributes,
        
        [Parameter(Mandatory = $false)]
        [switch]$DetectDates
    )
    
    Write-Log "Extraction des métadonnées inline..." -Level "Debug"
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $analysis = @{
        Tasks = @{}
        Tags = @{}
        Attributes = @{}
        Dates = @{}
        Stats = @{
            TotalTasks = 0
            TasksWithTags = 0
            TasksWithAttributes = 0
            TasksWithDates = 0
            UniqueTags = 0
            UniqueAttributes = 0
        }
    }
    
    # Patterns pour détecter les tâches et les métadonnées
    $patterns = @{
        Task = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
        TaskWithoutId = '^\s*[-*+]\s*\[([ xX])\]\s*(.*)'
        Tag = '#([a-zA-Z0-9_\-:]+)'
        Attribute = '\(([^)]+)\)'
        Date = '(?:due|deadline|scheduled|start|end|date):\s*(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4}|\d{1,2}\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{4})'
    }
    
    # Analyser chaque ligne
    $lineNumber = 0
    
    foreach ($line in $lines) {
        $lineNumber++
        
        # Détecter les tâches avec identifiants
        $taskId = $null
        $taskTitle = $null
        $taskStatus = $null
        
        if ($line -match $patterns.Task) {
            $taskStatus = $matches[1]
            $taskId = $matches[2]
            $taskTitle = $matches[3].Trim()
            
            # Enregistrer la tâche
            $analysis.Tasks[$taskId] = @{
                Id = $taskId
                Title = $taskTitle
                Status = if ($taskStatus -match '[xX]') { "Completed" } else { "Pending" }
                LineNumber = $lineNumber
                Tags = @()
                Attributes = @{}
                Dates = @{}
                Line = $line
            }
            
            $analysis.Stats.TotalTasks++
        } elseif ($line -match $patterns.TaskWithoutId) {
            $taskStatus = $matches[1]
            $taskTitle = $matches[2].Trim()
            
            # Générer un ID temporaire pour cette tâche
            $taskId = "task_" + $lineNumber
            
            # Enregistrer la tâche
            $analysis.Tasks[$taskId] = @{
                Id = $taskId
                Title = $taskTitle
                Status = if ($taskStatus -match '[xX]') { "Completed" } else { "Pending" }
                LineNumber = $lineNumber
                Tags = @()
                Attributes = @{}
                Dates = @{}
                Line = $line
                IsTemporary = $true
            }
            
            $analysis.Stats.TotalTasks++
        } else {
            # Ligne qui n'est pas une tâche
            continue
        }
        
        # Extraire les tags si demandé
        if ($DetectTags) {
            $tagMatches = [regex]::Matches($taskTitle, $patterns.Tag)
            
            if ($tagMatches.Count -gt 0) {
                $analysis.Stats.TasksWithTags++
                
                foreach ($match in $tagMatches) {
                    $tag = $match.Groups[1].Value
                    
                    # Ajouter le tag à la tâche
                    if (-not $analysis.Tasks[$taskId].Tags.Contains($tag)) {
                        $analysis.Tasks[$taskId].Tags += $tag
                    }
                    
                    # Compter les occurrences de ce tag
                    if (-not $analysis.Tags.ContainsKey($tag)) {
                        $analysis.Tags[$tag] = @{
                            Count = 1
                            Tasks = @($taskId)
                        }
                        $analysis.Stats.UniqueTags++
                    } else {
                        $analysis.Tags[$tag].Count++
                        if (-not $analysis.Tags[$tag].Tasks.Contains($taskId)) {
                            $analysis.Tags[$tag].Tasks += $taskId
                        }
                    }
                }
                
                # Nettoyer le titre en supprimant les tags
                $analysis.Tasks[$taskId].CleanTitle = $taskTitle -replace $patterns.Tag, ""
            } else {
                $analysis.Tasks[$taskId].CleanTitle = $taskTitle
            }
        }
        
        # Extraire les attributs entre parenthèses si demandé
        if ($DetectAttributes) {
            $attributeMatches = [regex]::Matches($taskTitle, $patterns.Attribute)
            
            if ($attributeMatches.Count -gt 0) {
                $analysis.Stats.TasksWithAttributes++
                
                foreach ($match in $attributeMatches) {
                    $attributeText = $match.Groups[1].Value
                    
                    # Essayer de détecter les paires clé-valeur
                    if ($attributeText -match '([^:=]+)[:=]\s*(.+)') {
                        $key = $matches[1].Trim()
                        $value = $matches[2].Trim()
                        
                        # Ajouter l'attribut à la tâche
                        $analysis.Tasks[$taskId].Attributes[$key] = $value
                        
                        # Compter les occurrences de cet attribut
                        $attributeKey = "$key=$value"
                        if (-not $analysis.Attributes.ContainsKey($attributeKey)) {
                            $analysis.Attributes[$attributeKey] = @{
                                Key = $key
                                Value = $value
                                Count = 1
                                Tasks = @($taskId)
                            }
                            $analysis.Stats.UniqueAttributes++
                        } else {
                            $analysis.Attributes[$attributeKey].Count++
                            if (-not $analysis.Attributes[$attributeKey].Tasks.Contains($taskId)) {
                                $analysis.Attributes[$attributeKey].Tasks += $taskId
                            }
                        }
                    } else {
                        # Attribut simple sans valeur
                        $key = $attributeText.Trim()
                        
                        # Ajouter l'attribut à la tâche
                        $analysis.Tasks[$taskId].Attributes[$key] = $true
                        
                        # Compter les occurrences de cet attribut
                        if (-not $analysis.Attributes.ContainsKey($key)) {
                            $analysis.Attributes[$key] = @{
                                Key = $key
                                Value = $true
                                Count = 1
                                Tasks = @($taskId)
                            }
                            $analysis.Stats.UniqueAttributes++
                        } else {
                            $analysis.Attributes[$key].Count++
                            if (-not $analysis.Attributes[$key].Tasks.Contains($taskId)) {
                                $analysis.Attributes[$key].Tasks += $taskId
                            }
                        }
                    }
                }
                
                # Nettoyer le titre en supprimant les attributs
                if (-not $analysis.Tasks[$taskId].ContainsKey("CleanTitle")) {
                    $analysis.Tasks[$taskId].CleanTitle = $taskTitle
                }
                $analysis.Tasks[$taskId].CleanTitle = $analysis.Tasks[$taskId].CleanTitle -replace $patterns.Attribute, ""
            } elseif (-not $analysis.Tasks[$taskId].ContainsKey("CleanTitle")) {
                $analysis.Tasks[$taskId].CleanTitle = $taskTitle
            }
        }
        
        # Extraire les dates si demandé
        if ($DetectDates) {
            $dateMatches = [regex]::Matches($taskTitle, $patterns.Date, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            
            if ($dateMatches.Count -gt 0) {
                $analysis.Stats.TasksWithDates++
                
                foreach ($match in $dateMatches) {
                    $dateType = $match.Groups[0].Value.Split(':')[0].ToLower()
                    $dateValue = $match.Groups[1].Value
                    
                    # Normaliser la date au format ISO (YYYY-MM-DD)
                    try {
                        $parsedDate = [datetime]::Parse($dateValue)
                        $isoDate = $parsedDate.ToString("yyyy-MM-dd")
                        
                        # Ajouter la date à la tâche
                        $analysis.Tasks[$taskId].Dates[$dateType] = $isoDate
                        
                        # Compter les occurrences de cette date
                        $dateKey = "$dateType:$isoDate"
                        if (-not $analysis.Dates.ContainsKey($dateKey)) {
                            $analysis.Dates[$dateKey] = @{
                                Type = $dateType
                                Date = $isoDate
                                Count = 1
                                Tasks = @($taskId)
                            }
                        } else {
                            $analysis.Dates[$dateKey].Count++
                            if (-not $analysis.Dates[$dateKey].Tasks.Contains($taskId)) {
                                $analysis.Dates[$dateKey].Tasks += $taskId
                            }
                        }
                    } catch {
                        Write-Log "Impossible de parser la date '$dateValue' : $_" -Level "Warning"
                    }
                }
            }
        }
        
        # Nettoyer le titre final
        if ($analysis.Tasks[$taskId].ContainsKey("CleanTitle")) {
            $analysis.Tasks[$taskId].CleanTitle = $analysis.Tasks[$taskId].CleanTitle.Trim()
        }
    }
    
    return $analysis
}

# Fonction pour générer la sortie au format demandé
function Format-MetadataOutput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "Markdown", "CSV")]
        [string]$Format = "JSON"
    )
    
    Write-Log "Génération de la sortie au format $Format..." -Level "Debug"
    
    switch ($Format) {
        "JSON" {
            return $Analysis | ConvertTo-Json -Depth 10
        }
        "Markdown" {
            $markdown = "# Analyse des métadonnées inline`n`n"
            
            # Statistiques générales
            $markdown += "## Statistiques`n`n"
            $markdown += "- Tâches totales : $($Analysis.Stats.TotalTasks)`n"
            $markdown += "- Tâches avec tags : $($Analysis.Stats.TasksWithTags)`n"
            $markdown += "- Tâches avec attributs : $($Analysis.Stats.TasksWithAttributes)`n"
            $markdown += "- Tâches avec dates : $($Analysis.Stats.TasksWithDates)`n"
            $markdown += "- Tags uniques : $($Analysis.Stats.UniqueTags)`n"
            $markdown += "- Attributs uniques : $($Analysis.Stats.UniqueAttributes)`n`n"
            
            # Tags
            if ($Analysis.Tags.Count -gt 0) {
                $markdown += "## Tags`n`n"
                $markdown += "| Tag | Occurrences | Tâches |`n"
                $markdown += "|-----|------------|--------|`n"
                
                foreach ($tag in $Analysis.Tags.Keys | Sort-Object) {
                    $tagInfo = $Analysis.Tags[$tag]
                    $markdown += "| #$tag | $($tagInfo.Count) | $($tagInfo.Tasks -join ", ") |`n"
                }
                
                $markdown += "`n"
            }
            
            # Attributs
            if ($Analysis.Attributes.Count -gt 0) {
                $markdown += "## Attributs`n`n"
                $markdown += "| Attribut | Valeur | Occurrences | Tâches |`n"
                $markdown += "|----------|--------|------------|--------|`n"
                
                foreach ($attrKey in $Analysis.Attributes.Keys | Sort-Object) {
                    $attrInfo = $Analysis.Attributes[$attrKey]
                    $value = if ($attrInfo.Value -eq $true) { "✓" } else { $attrInfo.Value }
                    $markdown += "| $($attrInfo.Key) | $value | $($attrInfo.Count) | $($attrInfo.Tasks -join ", ") |`n"
                }
                
                $markdown += "`n"
            }
            
            # Dates
            if ($Analysis.Dates.Count -gt 0) {
                $markdown += "## Dates`n`n"
                $markdown += "| Type | Date | Occurrences | Tâches |`n"
                $markdown += "|------|------|------------|--------|`n"
                
                foreach ($dateKey in $Analysis.Dates.Keys | Sort-Object) {
                    $dateInfo = $Analysis.Dates[$dateKey]
                    $markdown += "| $($dateInfo.Type) | $($dateInfo.Date) | $($dateInfo.Count) | $($dateInfo.Tasks -join ", ") |`n"
                }
                
                $markdown += "`n"
            }
            
            # Tâches avec métadonnées
            $markdown += "## Tâches avec métadonnées`n`n"
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                
                # Ne pas inclure les tâches temporaires sans métadonnées
                if ($task.ContainsKey("IsTemporary") -and $task.IsTemporary -and 
                    $task.Tags.Count -eq 0 -and $task.Attributes.Count -eq 0 -and $task.Dates.Count -eq 0) {
                    continue
                }
                
                $markdown += "### $taskId : $($task.Title)`n`n"
                $markdown += "- Statut : $($task.Status)`n"
                $markdown += "- Ligne : $($task.LineNumber)`n"
                
                if ($task.ContainsKey("CleanTitle") -and $task.CleanTitle -ne $task.Title) {
                    $markdown += "- Titre nettoyé : $($task.CleanTitle)`n"
                }
                
                if ($task.Tags.Count -gt 0) {
                    $markdown += "- Tags : $($task.Tags | ForEach-Object { "#$_" } | Join-String -Separator ", ")`n"
                }
                
                if ($task.Attributes.Count -gt 0) {
                    $markdown += "- Attributs :`n"
                    foreach ($key in $task.Attributes.Keys | Sort-Object) {
                        $value = $task.Attributes[$key]
                        if ($value -eq $true) {
                            $markdown += "  - $key`n"
                        } else {
                            $markdown += "  - $key : $value`n"
                        }
                    }
                }
                
                if ($task.Dates.Count -gt 0) {
                    $markdown += "- Dates :`n"
                    foreach ($dateType in $task.Dates.Keys | Sort-Object) {
                        $dateValue = $task.Dates[$dateType]
                        $markdown += "  - $dateType : $dateValue`n"
                    }
                }
                
                $markdown += "`n"
            }
            
            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,LineNumber,Tags,Attributes,Dates`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                
                # Ne pas inclure les tâches temporaires sans métadonnées
                if ($task.ContainsKey("IsTemporary") -and $task.IsTemporary -and 
                    $task.Tags.Count -eq 0 -and $task.Attributes.Count -eq 0 -and $task.Dates.Count -eq 0) {
                    continue
                }
                
                $tags = $task.Tags -join ";"
                
                $attributes = ($task.Attributes.GetEnumerator() | ForEach-Object {
                    if ($_.Value -eq $true) {
                        $_.Key
                    } else {
                        "$($_.Key)=$($_.Value)"
                    }
                }) -join ";"
                
                $dates = ($task.Dates.GetEnumerator() | ForEach-Object {
                    "$($_.Key)=$($_.Value)"
                }) -join ";"
                
                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'
                
                $csv += "$taskId,`"$escapedTitle`",$($task.Status),$($task.LineNumber),`"$tags`",`"$attributes`",`"$dates`"`n"
            }
            
            return $csv
        }
    }
}

# Fonction principale
function Extract-InlineMetadata {
    [CmdletBinding()]
    param (
        [string]$FilePath,
        [string]$Content,
        [switch]$DetectTags,
        [switch]$DetectAttributes,
        [switch]$DetectDates,
        [string]$OutputPath,
        [string]$OutputFormat
    )
    
    # Vérifier les paramètres
    if ([string]::IsNullOrEmpty($Content) -and [string]::IsNullOrEmpty($FilePath)) {
        Write-Log "Vous devez spécifier soit un chemin de fichier, soit un contenu à analyser." -Level "Error"
        return $null
    }
    
    # Lire le contenu du fichier si nécessaire
    if ([string]::IsNullOrEmpty($Content) -and -not [string]::IsNullOrEmpty($FilePath)) {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Log "Le fichier spécifié n'existe pas : $FilePath" -Level "Error"
            return $null
        }
        
        try {
            $Content = Get-Content -Path $FilePath -Raw
        } catch {
            Write-Log "Erreur lors de la lecture du fichier : $_" -Level "Error"
            return $null
        }
    }
    
    # Extraire les métadonnées inline
    $analysis = Get-InlineMetadata -Content $Content -DetectTags:$DetectTags -DetectAttributes:$DetectAttributes -DetectDates:$DetectDates
    
    # Afficher les résultats de l'analyse
    Write-Log "Extraction des métadonnées inline terminée :" -Level "Info"
    Write-Log "  - Tâches totales : $($analysis.Stats.TotalTasks)" -Level "Info"
    Write-Log "  - Tâches avec tags : $($analysis.Stats.TasksWithTags)" -Level "Info"
    Write-Log "  - Tâches avec attributs : $($analysis.Stats.TasksWithAttributes)" -Level "Info"
    Write-Log "  - Tâches avec dates : $($analysis.Stats.TasksWithDates)" -Level "Info"
    Write-Log "  - Tags uniques : $($analysis.Stats.UniqueTags)" -Level "Info"
    Write-Log "  - Attributs uniques : $($analysis.Stats.UniqueAttributes)" -Level "Info"
    
    # Générer la sortie au format demandé
    $output = Format-MetadataOutput -Analysis $analysis -Format $OutputFormat
    
    # Enregistrer la sortie si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        try {
            $output | Set-Content -Path $OutputPath -Encoding UTF8
            Write-Log "Sortie enregistrée dans : $OutputPath" -Level "Success"
        } catch {
            Write-Log "Erreur lors de l'enregistrement de la sortie : $_" -Level "Error"
        }
    }
    
    return @{
        Analysis = $analysis
        Output = $output
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Extract-InlineMetadata -FilePath $FilePath -Content $Content -DetectTags:$DetectTags -DetectAttributes:$DetectAttributes -DetectDates:$DetectDates -OutputPath $OutputPath -OutputFormat $OutputFormat
}
