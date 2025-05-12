# Detect-TagsWithRegex.ps1
# Script pour détecter les tags dans les tâches en utilisant des expressions régulières configurables
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [string]$Content,
    
    [Parameter(Mandatory = $false)]
    [string[]]$TagTypes,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "development\scripts\roadmap\rag\config\tag-formats\TagFormats.config.json",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown", "CSV", "Text")]
    [string]$OutputFormat = "JSON",
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeTaskContent,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour charger la configuration des formats de tags
function Get-TagFormatsConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    
    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $ConfigPath)) {
            Write-Error "Le fichier de configuration n'existe pas: $ConfigPath"
            return $null
        }
        
        # Charger le fichier de configuration
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        
        return $config
    }
    catch {
        Write-Error "Erreur lors du chargement de la configuration: $_"
        return $null
    }
}

# Fonction pour détecter les tâches dans le contenu
function Get-TasksFromContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    try {
        # Diviser le contenu en lignes
        $lines = $Content -split "`r?`n"
        
        # Pattern pour détecter les tâches
        $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
        
        $tasks = @{}
        $lineNumber = 0
        
        foreach ($line in $lines) {
            $lineNumber++
            
            if ($line -match $taskPattern) {
                $status = $matches[1] -ne ' '
                $taskId = $matches[2]
                $taskTitle = $matches[3]
                
                if (-not $tasks.ContainsKey($taskId)) {
                    $tasks[$taskId] = @{
                        Id = $taskId
                        Title = $taskTitle
                        Status = $status
                        LineNumber = $lineNumber
                        Line = $line
                        Tags = @{}
                    }
                }
            }
        }
        
        return $tasks
    }
    catch {
        Write-Error "Erreur lors de la détection des tâches: $_"
        return @{}
    }
}

# Fonction pour détecter les tags dans les tâches
function Detect-TagsInTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Tasks,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$TagFormats,
        
        [Parameter(Mandatory = $false)]
        [string[]]$TagTypes
    )
    
    try {
        # Si aucun type de tag n'est spécifié, utiliser tous les types disponibles
        if (-not $TagTypes -or $TagTypes.Count -eq 0) {
            $TagTypes = $TagFormats.tag_formats.PSObject.Properties.Name
        }
        
        # Pour chaque type de tag
        foreach ($tagType in $TagTypes) {
            # Vérifier si le type de tag existe dans la configuration
            if (-not $TagFormats.tag_formats.$tagType) {
                Write-Warning "Le type de tag '$tagType' n'existe pas dans la configuration."
                continue
            }
            
            # Initialiser le dictionnaire pour ce type de tag
            foreach ($taskId in $Tasks.Keys) {
                if (-not $Tasks[$taskId].Tags.ContainsKey($tagType)) {
                    $Tasks[$taskId].Tags[$tagType] = @()
                }
            }
            
            # Pour chaque format de tag
            foreach ($format in $TagFormats.tag_formats.$tagType.formats) {
                $pattern = $format.pattern
                
                # Pour chaque tâche
                foreach ($taskId in $Tasks.Keys) {
                    $taskLine = $Tasks[$taskId].Line
                    
                    # Vérifier si le format est composite (plusieurs groupes de valeurs)
                    $isComposite = $format.PSObject.Properties.Name -contains "composite" -and $format.composite -eq $true
                    
                    if ($isComposite) {
                        # Traiter les formats composites (ex: jours et heures)
                        if ($taskLine -match $pattern) {
                            $values = @()
                            $units = @()
                            
                            # Extraire les valeurs des groupes spécifiés
                            foreach ($groupIndex in $format.value_groups) {
                                $values += $matches[$groupIndex]
                            }
                            
                            # Utiliser les unités spécifiées
                            $units = $format.units
                            
                            # Créer l'objet de tag
                            $tag = @{
                                Type = $tagType
                                Format = $format.name
                                Values = $values
                                Units = $units
                                Original = $matches[0]
                                IsComposite = $true
                            }
                            
                            # Ajouter le tag à la tâche
                            $Tasks[$taskId].Tags[$tagType] += $tag
                        }
                    }
                    else {
                        # Traiter les formats simples (ex: jours uniquement)
                        if ($taskLine -match $pattern) {
                            $value = $matches[$format.value_group]
                            
                            # Créer l'objet de tag
                            $tag = @{
                                Type = $tagType
                                Format = $format.name
                                Value = $value
                                Unit = $format.unit
                                Original = $matches[0]
                                IsComposite = $false
                            }
                            
                            # Ajouter le tag à la tâche
                            $Tasks[$taskId].Tags[$tagType] += $tag
                        }
                    }
                }
            }
        }
        
        return $Tasks
    }
    catch {
        Write-Error "Erreur lors de la détection des tags: $_"
        return $Tasks
    }
}

# Fonction pour formater les résultats
function Format-DetectionResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Tasks,
        
        [Parameter(Mandatory = $true)]
        [string]$Format,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeTaskContent
    )
    
    try {
        switch ($Format) {
            "JSON" {
                # Convertir les résultats en JSON
                $output = $Tasks | ConvertTo-Json -Depth 10
                return $output
            }
            "Markdown" {
                # Créer un rapport Markdown
                $output = "# Rapport de détection des tags`n`n"
                $output += "## Résumé`n`n"
                $output += "- Nombre de tâches analysées: $($Tasks.Count)`n"
                
                # Compter les tags par type
                $tagCounts = @{}
                
                foreach ($taskId in $Tasks.Keys) {
                    foreach ($tagType in $Tasks[$taskId].Tags.Keys) {
                        if (-not $tagCounts.ContainsKey($tagType)) {
                            $tagCounts[$tagType] = 0
                        }
                        
                        $tagCounts[$tagType] += $Tasks[$taskId].Tags[$tagType].Count
                    }
                }
                
                $output += "- Tags détectés par type:`n"
                
                foreach ($tagType in $tagCounts.Keys) {
                    $output += "  - $tagType: $($tagCounts[$tagType])`n"
                }
                
                $output += "`n## Détails par tâche`n`n"
                
                foreach ($taskId in $Tasks.Keys) {
                    $task = $Tasks[$taskId]
                    $output += "### Tâche $($task.Id)`n`n"
                    $output += "- Titre: $($task.Title)`n"
                    $output += "- Statut: $($task.Status -eq $true ? 'Complété' : 'À faire')`n"
                    $output += "- Ligne: $($task.LineNumber)`n"
                    
                    if ($IncludeTaskContent) {
                        $output += "- Contenu: `$($task.Line)`n"
                    }
                    
                    $output += "- Tags:`n"
                    
                    $hasTags = $false
                    
                    foreach ($tagType in $task.Tags.Keys) {
                        if ($task.Tags[$tagType].Count -gt 0) {
                            $hasTags = $true
                            $output += "  - $tagType:`n"
                            
                            foreach ($tag in $task.Tags[$tagType]) {
                                if ($tag.IsComposite) {
                                    $valueUnits = @()
                                    
                                    for ($i = 0; $i -lt $tag.Values.Count; $i++) {
                                        $valueUnits += "$($tag.Values[$i]) $($tag.Units[$i])"
                                    }
                                    
                                    $output += "    - Format: $($tag.Format), Valeurs: $($valueUnits -join ', '), Original: $($tag.Original)`n"
                                }
                                else {
                                    $output += "    - Format: $($tag.Format), Valeur: $($tag.Value) $($tag.Unit), Original: $($tag.Original)`n"
                                }
                            }
                        }
                    }
                    
                    if (-not $hasTags) {
                        $output += "  - Aucun tag détecté`n"
                    }
                    
                    $output += "`n"
                }
                
                return $output
            }
            "CSV" {
                # Créer un rapport CSV
                $output = "TaskId,Title,Status,LineNumber,TagType,Format,Value,Unit,Original`n"
                
                foreach ($taskId in $Tasks.Keys) {
                    $task = $Tasks[$taskId]
                    $hasTags = $false
                    
                    foreach ($tagType in $task.Tags.Keys) {
                        foreach ($tag in $task.Tags[$tagType]) {
                            $hasTags = $true
                            
                            if ($tag.IsComposite) {
                                $valueUnits = @()
                                
                                for ($i = 0; $i -lt $tag.Values.Count; $i++) {
                                    $valueUnits += "$($tag.Values[$i]) $($tag.Units[$i])"
                                }
                                
                                $output += "$($task.Id),`"$($task.Title -replace '"', '""')`",$($task.Status),$($task.LineNumber),$tagType,$($tag.Format),`"$($valueUnits -join ', ')`",`"Multiple`",`"$($tag.Original -replace '"', '""')`"`n"
                            }
                            else {
                                $output += "$($task.Id),`"$($task.Title -replace '"', '""')`",$($task.Status),$($task.LineNumber),$tagType,$($tag.Format),$($tag.Value),$($tag.Unit),`"$($tag.Original -replace '"', '""')`"`n"
                            }
                        }
                    }
                    
                    if (-not $hasTags) {
                        $output += "$($task.Id),`"$($task.Title -replace '"', '""')`",$($task.Status),$($task.LineNumber),,,,,`n"
                    }
                }
                
                return $output
            }
            "Text" {
                # Créer un rapport texte simple
                $output = "Rapport de détection des tags`n`n"
                $output += "Résumé:`n"
                $output += "- Nombre de tâches analysées: $($Tasks.Count)`n"
                
                # Compter les tags par type
                $tagCounts = @{}
                
                foreach ($taskId in $Tasks.Keys) {
                    foreach ($tagType in $Tasks[$taskId].Tags.Keys) {
                        if (-not $tagCounts.ContainsKey($tagType)) {
                            $tagCounts[$tagType] = 0
                        }
                        
                        $tagCounts[$tagType] += $Tasks[$taskId].Tags[$tagType].Count
                    }
                }
                
                $output += "- Tags détectés par type:`n"
                
                foreach ($tagType in $tagCounts.Keys) {
                    $output += "  - $tagType: $($tagCounts[$tagType])`n"
                }
                
                $output += "`nDétails par tâche:`n`n"
                
                foreach ($taskId in $Tasks.Keys) {
                    $task = $Tasks[$taskId]
                    $output += "Tâche $($task.Id):`n"
                    $output += "- Titre: $($task.Title)`n"
                    $output += "- Statut: $($task.Status -eq $true ? 'Complété' : 'À faire')`n"
                    $output += "- Ligne: $($task.LineNumber)`n"
                    
                    if ($IncludeTaskContent) {
                        $output += "- Contenu: $($task.Line)`n"
                    }
                    
                    $output += "- Tags:`n"
                    
                    $hasTags = $false
                    
                    foreach ($tagType in $task.Tags.Keys) {
                        if ($task.Tags[$tagType].Count -gt 0) {
                            $hasTags = $true
                            $output += "  - $tagType:`n"
                            
                            foreach ($tag in $task.Tags[$tagType]) {
                                if ($tag.IsComposite) {
                                    $valueUnits = @()
                                    
                                    for ($i = 0; $i -lt $tag.Values.Count; $i++) {
                                        $valueUnits += "$($tag.Values[$i]) $($tag.Units[$i])"
                                    }
                                    
                                    $output += "    - Format: $($tag.Format), Valeurs: $($valueUnits -join ', '), Original: $($tag.Original)`n"
                                }
                                else {
                                    $output += "    - Format: $($tag.Format), Valeur: $($tag.Value) $($tag.Unit), Original: $($tag.Original)`n"
                                }
                            }
                        }
                    }
                    
                    if (-not $hasTags) {
                        $output += "  - Aucun tag détecté`n"
                    }
                    
                    $output += "`n"
                }
                
                return $output
            }
            default {
                Write-Error "Format de sortie non pris en charge: $Format"
                return $null
            }
        }
    }
    catch {
        Write-Error "Erreur lors du formatage des résultats: $_"
        return $null
    }
}

# Fonction principale
function Invoke-TagDetection {
    [CmdletBinding()]
    param (
        [string]$FilePath,
        [string]$Content,
        [string[]]$TagTypes,
        [string]$ConfigPath,
        [string]$OutputPath,
        [string]$OutputFormat,
        [switch]$IncludeTaskContent,
        [switch]$Force
    )
    
    try {
        # Charger la configuration des formats de tags
        $tagFormats = Get-TagFormatsConfig -ConfigPath $ConfigPath
        
        if (-not $tagFormats) {
            return
        }
        
        # Charger le contenu si un chemin de fichier est spécifié
        if (-not [string]::IsNullOrEmpty($FilePath)) {
            if (-not (Test-Path -Path $FilePath)) {
                Write-Error "Le fichier spécifié n'existe pas: $FilePath"
                return
            }
            
            $Content = Get-Content -Path $FilePath -Raw
        }
        
        if ([string]::IsNullOrEmpty($Content)) {
            Write-Error "Aucun contenu à analyser. Spécifiez un fichier ou fournissez du contenu."
            return
        }
        
        # Détecter les tâches dans le contenu
        $tasks = Get-TasksFromContent -Content $Content
        
        if ($tasks.Count -eq 0) {
            Write-Warning "Aucune tâche détectée dans le contenu."
            return
        }
        
        # Détecter les tags dans les tâches
        $tasksWithTags = Detect-TagsInTasks -Tasks $tasks -TagFormats $tagFormats -TagTypes $TagTypes
        
        # Formater les résultats
        $output = Format-DetectionResults -Tasks $tasksWithTags -Format $OutputFormat -IncludeTaskContent:$IncludeTaskContent
        
        # Enregistrer les résultats si un chemin de sortie est spécifié
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            $output | Set-Content -Path $OutputPath -Encoding UTF8
            Write-Host "Résultats enregistrés dans $OutputPath" -ForegroundColor Green
        }
        else {
            # Afficher les résultats
            Write-Output $output
        }
        
        return $tasksWithTags
    }
    catch {
        Write-Error "Erreur lors de la détection des tags: $_"
        return $null
    }
}

# Exécuter la fonction principale
Invoke-TagDetection -FilePath $FilePath -Content $Content -TagTypes $TagTypes -ConfigPath $ConfigPath -OutputPath $OutputPath -OutputFormat $OutputFormat -IncludeTaskContent:$IncludeTaskContent -Force:$Force
