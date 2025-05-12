# Extract-AdaptivePrecision.ps1
# Script pour extraire les nombres avec précision adaptative des tags dans les fichiers markdown de roadmap
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

# Fonction pour extraire les nombres avec précision adaptative
function Get-AdaptivePrecisionNumbers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Host "Extraction des nombres avec precision adaptative..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $adaptivePrecisionValues = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Pattern pour les nombres avec précision adaptative
    # Format: #precision:X ou #precision(X) où X est le nombre de décimales
    $precisionTagPattern = '#precision:(\d+)'
    $precisionParenTagPattern = '#precision\((\d+)\)'
    
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
                AdaptivePrecisionValues = @{
                    TaggedPrecision = @()
                    AdaptedNumbers = @()
                }
            }
        }
    }
    
    # Deuxième passe : extraire les tags de précision et les nombres associés
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Extraire les tags de précision
            $precisionValue = $null
            
            # Format #precision:X
            if ($taskLine -match $precisionTagPattern) {
                $precisionValue = [int]$matches[1]
                
                $precisionTag = @{
                    Value = $precisionValue
                    Type = "PrecisionTag"
                    Original = "#precision:$precisionValue"
                }
                
                # Ajouter le tag de précision à la tâche
                $tasks[$taskId].AdaptivePrecisionValues.TaggedPrecision += $precisionTag
                
                # Ajouter le tag de précision aux attributs de précision adaptative
                if (-not $adaptivePrecisionValues.ContainsKey($taskId)) {
                    $adaptivePrecisionValues[$taskId] = @{
                        TaggedPrecision = @()
                        AdaptedNumbers = @()
                    }
                }
                
                $adaptivePrecisionValues[$taskId].TaggedPrecision += $precisionTag
            }
            
            # Format #precision(X)
            if ($taskLine -match $precisionParenTagPattern) {
                $precisionValue = [int]$matches[1]
                
                $precisionTag = @{
                    Value = $precisionValue
                    Type = "PrecisionParenTag"
                    Original = "#precision($precisionValue)"
                }
                
                # Ajouter le tag de précision à la tâche
                $tasks[$taskId].AdaptivePrecisionValues.TaggedPrecision += $precisionTag
                
                # Ajouter le tag de précision aux attributs de précision adaptative
                if (-not $adaptivePrecisionValues.ContainsKey($taskId)) {
                    $adaptivePrecisionValues[$taskId] = @{
                        TaggedPrecision = @()
                        AdaptedNumbers = @()
                    }
                }
                
                $adaptivePrecisionValues[$taskId].TaggedPrecision += $precisionTag
            }
            
            # Si un tag de précision a été trouvé, extraire les nombres décimaux et les adapter
            if ($precisionValue -ne $null) {
                # Extraire les nombres décimaux avec point
                $matches = [regex]::Matches($taskLine, $decimalNumberPattern)
                foreach ($match in $matches) {
                    $numberValue = $match.Groups[1].Value
                    $originalPrecision = ($numberValue -split '\.')[1].Length
                    
                    # Adapter la précision du nombre
                    $adaptedValue = [math]::Round([double]$numberValue, $precisionValue)
                    
                    $adaptedNumber = @{
                        Value = $adaptedValue
                        Type = "AdaptedNumber"
                        Original = $numberValue
                        OriginalPrecision = $originalPrecision
                        AdaptedPrecision = $precisionValue
                        Position = $match.Index
                    }
                    
                    # Ajouter le nombre adapté à la tâche
                    $tasks[$taskId].AdaptivePrecisionValues.AdaptedNumbers += $adaptedNumber
                    
                    # Ajouter le nombre adapté aux attributs de précision adaptative
                    if (-not $adaptivePrecisionValues.ContainsKey($taskId)) {
                        $adaptivePrecisionValues[$taskId] = @{
                            TaggedPrecision = @()
                            AdaptedNumbers = @()
                        }
                    }
                    
                    $adaptivePrecisionValues[$taskId].AdaptedNumbers += $adaptedNumber
                }
                
                # Extraire les nombres décimaux avec virgule
                $matches = [regex]::Matches($taskLine, $commaDecimalNumberPattern)
                foreach ($match in $matches) {
                    $numberValue = $match.Groups[1].Value
                    $normalizedValue = $numberValue -replace ',', '.'
                    $originalPrecision = ($normalizedValue -split '\.')[1].Length
                    
                    # Adapter la précision du nombre
                    $adaptedValue = [math]::Round([double]$normalizedValue, $precisionValue)
                    
                    $adaptedNumber = @{
                        Value = $adaptedValue
                        Type = "AdaptedNumber"
                        Original = $numberValue
                        OriginalPrecision = $originalPrecision
                        AdaptedPrecision = $precisionValue
                        Position = $match.Index
                    }
                    
                    # Ajouter le nombre adapté à la tâche
                    $tasks[$taskId].AdaptivePrecisionValues.AdaptedNumbers += $adaptedNumber
                    
                    # Ajouter le nombre adapté aux attributs de précision adaptative
                    if (-not $adaptivePrecisionValues.ContainsKey($taskId)) {
                        $adaptivePrecisionValues[$taskId] = @{
                            TaggedPrecision = @()
                            AdaptedNumbers = @()
                        }
                    }
                    
                    $adaptivePrecisionValues[$taskId].AdaptedNumbers += $adaptedNumber
                }
            }
        }
    }
    
    return @{
        Tasks = $tasks
        AdaptivePrecisionValues = $adaptivePrecisionValues
    }
}

# Fonction principale pour extraire les nombres avec précision adaptative
function Get-AdaptivePrecision {
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
    
    # Extraire les nombres avec précision adaptative
    $adaptivePrecision = Get-AdaptivePrecisionNumbers -Content $Content
    
    # Combiner les résultats
    $analysis = @{
        AdaptivePrecisionValues = $adaptivePrecision.AdaptivePrecisionValues
        Tasks = @{}
        Stats = @{
            TotalTasks = 0
            TasksWithTaggedPrecision = 0
            TasksWithAdaptedNumbers = 0
        }
    }
    
    # Fusionner les informations des tâches
    $allTaskIds = @($adaptivePrecision.Tasks.Keys) | Select-Object -Unique
    
    foreach ($taskId in $allTaskIds) {
        $task = @{
            Id = $taskId
            Title = ""
            Status = ""
            LineNumber = 0
            AdaptivePrecisionAttributes = @{
                TaggedPrecision = @()
                AdaptedNumbers = @()
            }
        }
        
        if ($adaptivePrecision.Tasks.ContainsKey($taskId)) {
            $task.Title = $adaptivePrecision.Tasks[$taskId].Title
            $task.Status = $adaptivePrecision.Tasks[$taskId].Status
            $task.LineNumber = $adaptivePrecision.Tasks[$taskId].LineNumber
            $task.AdaptivePrecisionAttributes.TaggedPrecision = $adaptivePrecision.Tasks[$taskId].AdaptivePrecisionValues.TaggedPrecision
            $task.AdaptivePrecisionAttributes.AdaptedNumbers = $adaptivePrecision.Tasks[$taskId].AdaptivePrecisionValues.AdaptedNumbers
        }
        
        $analysis.Tasks[$taskId] = $task
    }
    
    # Calculer les statistiques
    $analysis.Stats.TotalTasks = $allTaskIds.Count
    $analysis.Stats.TasksWithTaggedPrecision = ($analysis.Tasks.Values | Where-Object { $_.AdaptivePrecisionAttributes.TaggedPrecision.Count -gt 0 }).Count
    $analysis.Stats.TasksWithAdaptedNumbers = ($analysis.Tasks.Values | Where-Object { $_.AdaptivePrecisionAttributes.AdaptedNumbers.Count -gt 0 }).Count
    
    # Formater les résultats selon le format demandé
    $output = Format-AdaptivePrecisionOutput -Analysis $analysis -Format $OutputFormat
    
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
function Format-AdaptivePrecisionOutput {
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
            $markdown = "# Analyse des nombres avec precision adaptative`n`n"
            
            $markdown += "## Statistiques`n`n"
            $markdown += "- Nombre total de taches: $($Analysis.Stats.TotalTasks)`n"
            $markdown += "- Taches avec tags de precision: $($Analysis.Stats.TasksWithTaggedPrecision)`n"
            $markdown += "- Taches avec nombres adaptes: $($Analysis.Stats.TasksWithAdaptedNumbers)`n`n"
            
            $markdown += "## Taches avec nombres a precision adaptative`n`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                $hasAdaptivePrecisionAttributes = $task.AdaptivePrecisionAttributes.TaggedPrecision.Count -gt 0 -or 
                                                $task.AdaptivePrecisionAttributes.AdaptedNumbers.Count -gt 0
                
                if ($hasAdaptivePrecisionAttributes) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"
                    
                    if ($task.AdaptivePrecisionAttributes.TaggedPrecision.Count -gt 0) {
                        $markdown += "- Tags de precision:`n"
                        foreach ($tag in $task.AdaptivePrecisionAttributes.TaggedPrecision) {
                            $markdown += "  - Precision: $($tag.Value) (original: $($tag.Original))`n"
                        }
                    }
                    
                    if ($task.AdaptivePrecisionAttributes.AdaptedNumbers.Count -gt 0) {
                        $markdown += "- Nombres adaptes:`n"
                        foreach ($number in $task.AdaptivePrecisionAttributes.AdaptedNumbers) {
                            $markdown += "  - $($number.Value) (original: $($number.Original), precision originale: $($number.OriginalPrecision), precision adaptee: $($number.AdaptedPrecision))`n"
                        }
                    }
                    
                    $markdown += "`n"
                }
            }
            
            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,TaggedPrecision,AdaptedNumbers`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                
                $taggedPrecision = ""
                if ($task.AdaptivePrecisionAttributes.TaggedPrecision.Count -gt 0) {
                    $taggedPrecision = ($task.AdaptivePrecisionAttributes.TaggedPrecision | ForEach-Object { "Precision: $($_.Value) (original: $($_.Original))" }) -join '; '
                }
                
                $adaptedNumbers = ""
                if ($task.AdaptivePrecisionAttributes.AdaptedNumbers.Count -gt 0) {
                    $adaptedNumbers = ($task.AdaptivePrecisionAttributes.AdaptedNumbers | ForEach-Object { "$($_.Value) (original: $($_.Original), precision adaptee: $($_.AdaptedPrecision))" }) -join '; '
                }
                
                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'
                
                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$taggedPrecision`",`"$adaptedNumbers`"`n"
            }
            
            return $csv
        }
    }
}

# Exécuter la fonction principale avec les paramètres fournis
Get-AdaptivePrecision -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat
