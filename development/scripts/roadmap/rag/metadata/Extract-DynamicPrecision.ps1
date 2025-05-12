# Extract-DynamicPrecision.ps1
# Script pour extraire les nombres avec precision dynamique des tags dans les fichiers markdown de roadmap
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [string]$Content,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown", "CSV")]
    [string]$OutputFormat = "JSON"
)

# Fonction pour extraire les nombres avec précision dynamique
function Get-DynamicPrecisionNumbers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Host "Extraction des nombres avec precision dynamique..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $dynamicPrecisionValues = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Pattern pour les tags de précision dynamique
    # Format: #dynamic-precision:min-max ou #dynamic-precision(min-max)
    $dynamicPrecisionTagPattern = '#dynamic-precision:(\d+)-(\d+)'
    $dynamicPrecisionParenTagPattern = '#dynamic-precision\((\d+)-(\d+)\)'
    
    # Pattern pour les nombres décimaux
    $decimalNumberPattern = '(\d+\.\d+)'
    $commaDecimalNumberPattern = '(\d+,\d+)'
    
    # Première passe : identifier toutes les tâches
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskTitle = $matches[3]
            $taskStatus = if ($matches[1] -match '[xX]') { "Completed" } else { "Pending" }
            
            $tasks[$taskId] = @{
                Id = $taskId
                Title = $taskTitle
                Status = $taskStatus
                LineNumber = $lineNumber
                DynamicPrecisionValues = @{
                    TaggedDynamicPrecision = @()
                    DynamicNumbers = @()
                }
            }
        }
    }
    
    # Deuxième passe : extraire les tags de précision dynamique et les nombres associés
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Extraire les tags de précision dynamique
            $minPrecision = $null
            $maxPrecision = $null
            
            # Format #dynamic-precision:min-max
            if ($taskLine -match $dynamicPrecisionTagPattern) {
                $minPrecision = [int]$matches[1]
                $maxPrecision = [int]$matches[2]
                
                $dynamicPrecisionTag = @{
                    MinValue = $minPrecision
                    MaxValue = $maxPrecision
                    Type = "DynamicPrecisionTag"
                    Original = "#dynamic-precision:$minPrecision-$maxPrecision"
                }
                
                # Ajouter le tag de précision dynamique à la tâche
                $tasks[$taskId].DynamicPrecisionValues.TaggedDynamicPrecision += $dynamicPrecisionTag
                
                # Ajouter le tag de précision dynamique aux attributs de précision dynamique
                if (-not $dynamicPrecisionValues.ContainsKey($taskId)) {
                    $dynamicPrecisionValues[$taskId] = @{
                        TaggedDynamicPrecision = @()
                        DynamicNumbers = @()
                    }
                }
                
                $dynamicPrecisionValues[$taskId].TaggedDynamicPrecision += $dynamicPrecisionTag
            }
            
            # Format #dynamic-precision(min-max)
            if ($taskLine -match $dynamicPrecisionParenTagPattern) {
                $minPrecision = [int]$matches[1]
                $maxPrecision = [int]$matches[2]
                
                $dynamicPrecisionTag = @{
                    MinValue = $minPrecision
                    MaxValue = $maxPrecision
                    Type = "DynamicPrecisionParenTag"
                    Original = "#dynamic-precision($minPrecision-$maxPrecision)"
                }
                
                # Ajouter le tag de précision dynamique à la tâche
                $tasks[$taskId].DynamicPrecisionValues.TaggedDynamicPrecision += $dynamicPrecisionTag
                
                # Ajouter le tag de précision dynamique aux attributs de précision dynamique
                if (-not $dynamicPrecisionValues.ContainsKey($taskId)) {
                    $dynamicPrecisionValues[$taskId] = @{
                        TaggedDynamicPrecision = @()
                        DynamicNumbers = @()
                    }
                }
                
                $dynamicPrecisionValues[$taskId].TaggedDynamicPrecision += $dynamicPrecisionTag
            }
            
            # Si un tag de précision dynamique a été trouvé, extraire les nombres décimaux et les adapter
            if ($minPrecision -ne $null -and $maxPrecision -ne $null) {
                # Extraire les nombres décimaux avec point
                $matches = [regex]::Matches($taskLine, $decimalNumberPattern)
                foreach ($match in $matches) {
                    $numberValue = $match.Groups[1].Value
                    $originalPrecision = ($numberValue -split '\.')[1].Length
                    
                    # Déterminer la précision dynamique en fonction de la valeur du nombre
                    $dynamicPrecision = Get-DynamicPrecision -Value $numberValue -MinPrecision $minPrecision -MaxPrecision $maxPrecision
                    
                    # Adapter la précision du nombre
                    $adaptedValue = [math]::Round([double]$numberValue, $dynamicPrecision)
                    
                    $dynamicNumber = @{
                        Value = $adaptedValue
                        Type = "DynamicNumber"
                        Original = $numberValue
                        OriginalPrecision = $originalPrecision
                        DynamicPrecision = $dynamicPrecision
                        MinPrecision = $minPrecision
                        MaxPrecision = $maxPrecision
                        Position = $match.Index
                    }
                    
                    # Ajouter le nombre dynamique à la tâche
                    $tasks[$taskId].DynamicPrecisionValues.DynamicNumbers += $dynamicNumber
                    
                    # Ajouter le nombre dynamique aux attributs de précision dynamique
                    if (-not $dynamicPrecisionValues.ContainsKey($taskId)) {
                        $dynamicPrecisionValues[$taskId] = @{
                            TaggedDynamicPrecision = @()
                            DynamicNumbers = @()
                        }
                    }
                    
                    $dynamicPrecisionValues[$taskId].DynamicNumbers += $dynamicNumber
                }
                
                # Extraire les nombres décimaux avec virgule
                $matches = [regex]::Matches($taskLine, $commaDecimalNumberPattern)
                foreach ($match in $matches) {
                    $numberValue = $match.Groups[1].Value
                    $normalizedValue = $numberValue -replace ',', '.'
                    $originalPrecision = ($normalizedValue -split '\.')[1].Length
                    
                    # Déterminer la précision dynamique en fonction de la valeur du nombre
                    $dynamicPrecision = Get-DynamicPrecision -Value $normalizedValue -MinPrecision $minPrecision -MaxPrecision $maxPrecision
                    
                    # Adapter la précision du nombre
                    $adaptedValue = [math]::Round([double]$normalizedValue, $dynamicPrecision)
                    
                    $dynamicNumber = @{
                        Value = $adaptedValue
                        Type = "DynamicNumber"
                        Original = $numberValue
                        OriginalPrecision = $originalPrecision
                        DynamicPrecision = $dynamicPrecision
                        MinPrecision = $minPrecision
                        MaxPrecision = $maxPrecision
                        Position = $match.Index
                    }
                    
                    # Ajouter le nombre dynamique à la tâche
                    $tasks[$taskId].DynamicPrecisionValues.DynamicNumbers += $dynamicNumber
                    
                    # Ajouter le nombre dynamique aux attributs de précision dynamique
                    if (-not $dynamicPrecisionValues.ContainsKey($taskId)) {
                        $dynamicPrecisionValues[$taskId] = @{
                            TaggedDynamicPrecision = @()
                            DynamicNumbers = @()
                        }
                    }
                    
                    $dynamicPrecisionValues[$taskId].DynamicNumbers += $dynamicNumber
                }
            }
        }
    }
    
    return @{
        Tasks = $tasks
        DynamicPrecisionValues = $dynamicPrecisionValues
    }
}

# Fonction pour déterminer la précision dynamique en fonction de la valeur du nombre
function Get-DynamicPrecision {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Value,
        
        [Parameter(Mandatory = $true)]
        [int]$MinPrecision,
        
        [Parameter(Mandatory = $true)]
        [int]$MaxPrecision
    )
    
    # Convertir la valeur en nombre
    $number = [double]$Value
    
    # Déterminer la précision dynamique en fonction de la valeur du nombre
    # Règle : Plus le nombre est grand, moins il a besoin de précision
    # Règle : Plus le nombre est petit, plus il a besoin de précision
    
    # Calculer la précision dynamique
    $precision = $null
    
    if ($number -ge 1000) {
        # Grands nombres : précision minimale
        $precision = $MinPrecision
    }
    elseif ($number -ge 100) {
        # Nombres moyens : précision intermédiaire basse
        $precision = [math]::Min($MinPrecision + 1, $MaxPrecision)
    }
    elseif ($number -ge 10) {
        # Petits nombres : précision intermédiaire haute
        $precision = [math]::Min($MinPrecision + 2, $MaxPrecision)
    }
    else {
        # Très petits nombres : précision maximale
        $precision = $MaxPrecision
    }
    
    return $precision
}

# Fonction principale pour extraire les nombres avec précision dynamique
function Get-DynamicPrecision {
    [CmdletBinding()]
    param (
        [string]$FilePath,
        [string]$Content,
        [string]$OutputPath,
        [string]$OutputFormat
    )
    
    # Vérifier les paramètres
    if ([string]::IsNullOrEmpty($Content) -and [string]::IsNullOrEmpty($FilePath)) {
        Write-Host "Vous devez specifier soit un chemin de fichier, soit un contenu a analyser." -ForegroundColor Red
        return $null
    }
    
    # Vérifier si le contenu est vide après avoir été passé
    if (-not [string]::IsNullOrEmpty($Content) -and $Content.Trim().Length -eq 0) {
        Write-Host "Le contenu fourni est vide." -ForegroundColor Red
        return $null
    }
    
    # Charger le contenu si un chemin de fichier est spécifié
    if (-not [string]::IsNullOrEmpty($FilePath)) {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Host "Le fichier specifie n'existe pas: $FilePath" -ForegroundColor Red
            return $null
        }
        
        $Content = Get-Content -Path $FilePath -Raw
    }
    
    # Extraire les nombres avec précision dynamique
    $dynamicPrecision = Get-DynamicPrecisionNumbers -Content $Content
    
    # Combiner les résultats
    $analysis = @{
        DynamicPrecisionValues = $dynamicPrecision.DynamicPrecisionValues
        Tasks = @{}
        Stats = @{
            TotalTasks = 0
            TasksWithTaggedDynamicPrecision = 0
            TasksWithDynamicNumbers = 0
        }
    }
    
    # Fusionner les informations des tâches
    $allTaskIds = @($dynamicPrecision.Tasks.Keys) | Select-Object -Unique
    
    foreach ($taskId in $allTaskIds) {
        $task = @{
            Id = $taskId
            Title = ""
            Status = ""
            LineNumber = 0
            DynamicPrecisionAttributes = @{
                TaggedDynamicPrecision = @()
                DynamicNumbers = @()
            }
        }
        
        if ($dynamicPrecision.Tasks.ContainsKey($taskId)) {
            $task.Title = $dynamicPrecision.Tasks[$taskId].Title
            $task.Status = $dynamicPrecision.Tasks[$taskId].Status
            $task.LineNumber = $dynamicPrecision.Tasks[$taskId].LineNumber
            $task.DynamicPrecisionAttributes.TaggedDynamicPrecision = $dynamicPrecision.Tasks[$taskId].DynamicPrecisionValues.TaggedDynamicPrecision
            $task.DynamicPrecisionAttributes.DynamicNumbers = $dynamicPrecision.Tasks[$taskId].DynamicPrecisionValues.DynamicNumbers
        }
        
        $analysis.Tasks[$taskId] = $task
    }
    
    # Calculer les statistiques
    $analysis.Stats.TotalTasks = $allTaskIds.Count
    $analysis.Stats.TasksWithTaggedDynamicPrecision = ($analysis.Tasks.Values | Where-Object { $_.DynamicPrecisionAttributes.TaggedDynamicPrecision.Count -gt 0 }).Count
    $analysis.Stats.TasksWithDynamicNumbers = ($analysis.Tasks.Values | Where-Object { $_.DynamicPrecisionAttributes.DynamicNumbers.Count -gt 0 }).Count
    
    # Formater les résultats selon le format demandé
    $output = Format-DynamicPrecisionOutput -Analysis $analysis -Format $OutputFormat
    
    # Enregistrer les résultats si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $outputDirectory = Split-Path -Path $OutputPath -Parent
        
        if (-not [string]::IsNullOrEmpty($outputDirectory) -and -not (Test-Path -Path $outputDirectory)) {
            New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
        }
        
        Set-Content -Path $OutputPath -Value $output
        Write-Host "Resultats enregistres dans $OutputPath" -ForegroundColor Green
    }
    
    return $output
}

# Fonction pour formater les résultats
function Format-DynamicPrecisionOutput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "Markdown", "CSV")]
        [string]$Format
    )
    
    Write-Host "Formatage des resultats en $Format..." -ForegroundColor Cyan
    
    switch ($Format) {
        "JSON" {
            return $Analysis | ConvertTo-Json -Depth 10
        }
        "Markdown" {
            $markdown = "# Analyse des nombres avec precision dynamique`n`n"
            
            $markdown += "## Statistiques`n`n"
            $markdown += "- Nombre total de taches: $($Analysis.Stats.TotalTasks)`n"
            $markdown += "- Taches avec tags de precision dynamique: $($Analysis.Stats.TasksWithTaggedDynamicPrecision)`n"
            $markdown += "- Taches avec nombres dynamiques: $($Analysis.Stats.TasksWithDynamicNumbers)`n`n"
            
            $markdown += "## Taches avec nombres a precision dynamique`n`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                $hasDynamicPrecisionAttributes = $task.DynamicPrecisionAttributes.TaggedDynamicPrecision.Count -gt 0 -or 
                                               $task.DynamicPrecisionAttributes.DynamicNumbers.Count -gt 0
                
                if ($hasDynamicPrecisionAttributes) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"
                    
                    if ($task.DynamicPrecisionAttributes.TaggedDynamicPrecision.Count -gt 0) {
                        $markdown += "- Tags de precision dynamique:`n"
                        foreach ($tag in $task.DynamicPrecisionAttributes.TaggedDynamicPrecision) {
                            $markdown += "  - Precision min-max: $($tag.MinValue)-$($tag.MaxValue) (original: $($tag.Original))`n"
                        }
                    }
                    
                    if ($task.DynamicPrecisionAttributes.DynamicNumbers.Count -gt 0) {
                        $markdown += "- Nombres dynamiques:`n"
                        foreach ($number in $task.DynamicPrecisionAttributes.DynamicNumbers) {
                            $markdown += "  - $($number.Value) (original: $($number.Original), precision originale: $($number.OriginalPrecision), precision dynamique: $($number.DynamicPrecision))`n"
                        }
                    }
                    
                    $markdown += "`n"
                }
            }
            
            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,TaggedDynamicPrecision,DynamicNumbers`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                
                $taggedDynamicPrecision = ""
                if ($task.DynamicPrecisionAttributes.TaggedDynamicPrecision.Count -gt 0) {
                    $taggedDynamicPrecision = ($task.DynamicPrecisionAttributes.TaggedDynamicPrecision | ForEach-Object { "Precision min-max: $($_.MinValue)-$($_.MaxValue) (original: $($_.Original))" }) -join '; '
                }
                
                $dynamicNumbers = ""
                if ($task.DynamicPrecisionAttributes.DynamicNumbers.Count -gt 0) {
                    $dynamicNumbers = ($task.DynamicPrecisionAttributes.DynamicNumbers | ForEach-Object { "$($_.Value) (original: $($_.Original), precision dynamique: $($_.DynamicPrecision))" }) -join '; '
                }
                
                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'
                
                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$taggedDynamicPrecision`",`"$dynamicNumbers`"`n"
            }
            
            return $csv
        }
    }
}

# Exécuter la fonction principale avec les paramètres fournis
Get-DynamicPrecision -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat
