# Standardize-NumericPrecision.ps1
# Script pour standardiser les précisions numériques dans les fichiers markdown de roadmap
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
    [string]$OutputFormat = "JSON",
    
    [Parameter(Mandatory = $false)]
    [int]$DefaultPrecision = 2
)

# Fonction pour standardiser les précisions numériques
function Get-StandardizedPrecisionNumbers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $false)]
        [int]$DefaultPrecision = 2
    )
    
    Write-Host "Standardisation des précisions numériques..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $standardizedPrecisionValues = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Pattern pour les tags de précision standard
    # Format: #standard-precision:X ou #standard-precision(X)
    $standardPrecisionTagPattern = '#standard-precision:(\d+)'
    $standardPrecisionParenTagPattern = '#standard-precision\((\d+)\)'
    
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
                StandardizedPrecisionValues = @{
                    TaggedStandardPrecision = @()
                    StandardizedNumbers = @()
                }
            }
        }
    }
    
    # Deuxième passe : extraire les tags de précision standard et les nombres associés
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Extraire les tags de précision standard
            $standardPrecision = $null
            
            # Format #standard-precision:X
            if ($taskLine -match $standardPrecisionTagPattern) {
                $standardPrecision = [int]$matches[1]
                
                $standardPrecisionTag = @{
                    Value = $standardPrecision
                    Type = "StandardPrecisionTag"
                    Original = "#standard-precision:$standardPrecision"
                }
                
                # Ajouter le tag de précision standard à la tâche
                $tasks[$taskId].StandardizedPrecisionValues.TaggedStandardPrecision += $standardPrecisionTag
                
                # Ajouter le tag de précision standard aux attributs de précision standard
                if (-not $standardizedPrecisionValues.ContainsKey($taskId)) {
                    $standardizedPrecisionValues[$taskId] = @{
                        TaggedStandardPrecision = @()
                        StandardizedNumbers = @()
                    }
                }
                
                $standardizedPrecisionValues[$taskId].TaggedStandardPrecision += $standardPrecisionTag
            }
            
            # Format #standard-precision(X)
            if ($taskLine -match $standardPrecisionParenTagPattern) {
                $standardPrecision = [int]$matches[1]
                
                $standardPrecisionTag = @{
                    Value = $standardPrecision
                    Type = "StandardPrecisionParenTag"
                    Original = "#standard-precision($standardPrecision)"
                }
                
                # Ajouter le tag de précision standard à la tâche
                $tasks[$taskId].StandardizedPrecisionValues.TaggedStandardPrecision += $standardPrecisionTag
                
                # Ajouter le tag de précision standard aux attributs de précision standard
                if (-not $standardizedPrecisionValues.ContainsKey($taskId)) {
                    $standardizedPrecisionValues[$taskId] = @{
                        TaggedStandardPrecision = @()
                        StandardizedNumbers = @()
                    }
                }
                
                $standardizedPrecisionValues[$taskId].TaggedStandardPrecision += $standardPrecisionTag
            }
            
            # Si aucun tag de précision standard n'a été trouvé, utiliser la précision par défaut
            if ($standardPrecision -eq $null) {
                $standardPrecision = $DefaultPrecision
            }
            
            # Extraire les nombres décimaux et les standardiser
            # Extraire les nombres décimaux avec point
            $matches = [regex]::Matches($taskLine, $decimalNumberPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $originalPrecision = ($numberValue -split '\.')[1].Length
                
                # Standardiser la précision du nombre
                $standardizedValue = [math]::Round([double]$numberValue, $standardPrecision)
                
                $standardizedNumber = @{
                    Value = $standardizedValue
                    Type = "StandardizedNumber"
                    Original = $numberValue
                    OriginalPrecision = $originalPrecision
                    StandardizedPrecision = $standardPrecision
                    Position = $match.Index
                }
                
                # Ajouter le nombre standardisé à la tâche
                $tasks[$taskId].StandardizedPrecisionValues.StandardizedNumbers += $standardizedNumber
                
                # Ajouter le nombre standardisé aux attributs de précision standard
                if (-not $standardizedPrecisionValues.ContainsKey($taskId)) {
                    $standardizedPrecisionValues[$taskId] = @{
                        TaggedStandardPrecision = @()
                        StandardizedNumbers = @()
                    }
                }
                
                $standardizedPrecisionValues[$taskId].StandardizedNumbers += $standardizedNumber
            }
            
            # Extraire les nombres décimaux avec virgule
            $matches = [regex]::Matches($taskLine, $commaDecimalNumberPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $normalizedValue = $numberValue -replace ',', '.'
                $originalPrecision = ($normalizedValue -split '\.')[1].Length
                
                # Standardiser la précision du nombre
                $standardizedValue = [math]::Round([double]$normalizedValue, $standardPrecision)
                
                $standardizedNumber = @{
                    Value = $standardizedValue
                    Type = "StandardizedNumber"
                    Original = $numberValue
                    OriginalPrecision = $originalPrecision
                    StandardizedPrecision = $standardPrecision
                    Position = $match.Index
                }
                
                # Ajouter le nombre standardisé à la tâche
                $tasks[$taskId].StandardizedPrecisionValues.StandardizedNumbers += $standardizedNumber
                
                # Ajouter le nombre standardisé aux attributs de précision standard
                if (-not $standardizedPrecisionValues.ContainsKey($taskId)) {
                    $standardizedPrecisionValues[$taskId] = @{
                        TaggedStandardPrecision = @()
                        StandardizedNumbers = @()
                    }
                }
                
                $standardizedPrecisionValues[$taskId].StandardizedNumbers += $standardizedNumber
            }
        }
    }
    
    return @{
        Tasks = $tasks
        StandardizedPrecisionValues = $standardizedPrecisionValues
    }
}

# Fonction principale pour standardiser les précisions numériques
function Get-StandardizedPrecision {
    [CmdletBinding()]
    param (
        [string]$FilePath,
        [string]$Content,
        [string]$OutputPath,
        [string]$OutputFormat,
        [int]$DefaultPrecision
    )
    
    # Vérifier les paramètres
    if ([string]::IsNullOrEmpty($Content) -and [string]::IsNullOrEmpty($FilePath)) {
        Write-Host "Vous devez spécifier soit un chemin de fichier, soit un contenu à analyser." -ForegroundColor Red
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
            Write-Host "Le fichier spécifié n'existe pas: $FilePath" -ForegroundColor Red
            return $null
        }
        
        $Content = Get-Content -Path $FilePath -Raw
    }
    
    # Standardiser les précisions numériques
    $standardizedPrecision = Get-StandardizedPrecisionNumbers -Content $Content -DefaultPrecision $DefaultPrecision
    
    # Combiner les résultats
    $analysis = @{
        StandardizedPrecisionValues = $standardizedPrecision.StandardizedPrecisionValues
        Tasks = @{}
        Stats = @{
            TotalTasks = 0
            TasksWithTaggedStandardPrecision = 0
            TasksWithStandardizedNumbers = 0
        }
    }
    
    # Fusionner les informations des tâches
    $allTaskIds = @($standardizedPrecision.Tasks.Keys) | Select-Object -Unique
    
    foreach ($taskId in $allTaskIds) {
        $task = @{
            Id = $taskId
            Title = ""
            Status = ""
            LineNumber = 0
            StandardizedPrecisionAttributes = @{
                TaggedStandardPrecision = @()
                StandardizedNumbers = @()
            }
        }
        
        if ($standardizedPrecision.Tasks.ContainsKey($taskId)) {
            $task.Title = $standardizedPrecision.Tasks[$taskId].Title
            $task.Status = $standardizedPrecision.Tasks[$taskId].Status
            $task.LineNumber = $standardizedPrecision.Tasks[$taskId].LineNumber
            $task.StandardizedPrecisionAttributes.TaggedStandardPrecision = $standardizedPrecision.Tasks[$taskId].StandardizedPrecisionValues.TaggedStandardPrecision
            $task.StandardizedPrecisionAttributes.StandardizedNumbers = $standardizedPrecision.Tasks[$taskId].StandardizedPrecisionValues.StandardizedNumbers
        }
        
        $analysis.Tasks[$taskId] = $task
    }
    
    # Calculer les statistiques
    $analysis.Stats.TotalTasks = $allTaskIds.Count
    $analysis.Stats.TasksWithTaggedStandardPrecision = ($analysis.Tasks.Values | Where-Object { $_.StandardizedPrecisionAttributes.TaggedStandardPrecision.Count -gt 0 }).Count
    $analysis.Stats.TasksWithStandardizedNumbers = ($analysis.Tasks.Values | Where-Object { $_.StandardizedPrecisionAttributes.StandardizedNumbers.Count -gt 0 }).Count
    
    # Formater les résultats selon le format demandé
    $output = Format-StandardizedPrecisionOutput -Analysis $analysis -Format $OutputFormat
    
    # Enregistrer les résultats si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $outputDirectory = Split-Path -Path $OutputPath -Parent
        
        if (-not [string]::IsNullOrEmpty($outputDirectory) -and -not (Test-Path -Path $outputDirectory)) {
            New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
        }
        
        Set-Content -Path $OutputPath -Value $output
        Write-Host "Résultats enregistrés dans $OutputPath" -ForegroundColor Green
    }
    
    return $output
}

# Fonction pour formater les résultats
function Format-StandardizedPrecisionOutput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "Markdown", "CSV")]
        [string]$Format
    )
    
    Write-Host "Formatage des résultats en $Format..." -ForegroundColor Cyan
    
    switch ($Format) {
        "JSON" {
            return $Analysis | ConvertTo-Json -Depth 10
        }
        "Markdown" {
            $markdown = "# Analyse des nombres avec précision standardisée`n`n"
            
            $markdown += "## Statistiques`n`n"
            $markdown += "- Nombre total de tâches: $($Analysis.Stats.TotalTasks)`n"
            $markdown += "- Tâches avec tags de précision standard: $($Analysis.Stats.TasksWithTaggedStandardPrecision)`n"
            $markdown += "- Tâches avec nombres standardisés: $($Analysis.Stats.TasksWithStandardizedNumbers)`n`n"
            
            $markdown += "## Tâches avec nombres à précision standardisée`n`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                $hasStandardizedPrecisionAttributes = $task.StandardizedPrecisionAttributes.TaggedStandardPrecision.Count -gt 0 -or 
                                                    $task.StandardizedPrecisionAttributes.StandardizedNumbers.Count -gt 0
                
                if ($hasStandardizedPrecisionAttributes) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"
                    
                    if ($task.StandardizedPrecisionAttributes.TaggedStandardPrecision.Count -gt 0) {
                        $markdown += "- Tags de précision standard:`n"
                        foreach ($tag in $task.StandardizedPrecisionAttributes.TaggedStandardPrecision) {
                            $markdown += "  - Précision: $($tag.Value) (original: $($tag.Original))`n"
                        }
                    }
                    
                    if ($task.StandardizedPrecisionAttributes.StandardizedNumbers.Count -gt 0) {
                        $markdown += "- Nombres standardisés:`n"
                        foreach ($number in $task.StandardizedPrecisionAttributes.StandardizedNumbers) {
                            $markdown += "  - $($number.Value) (original: $($number.Original), précision originale: $($number.OriginalPrecision), précision standardisée: $($number.StandardizedPrecision))`n"
                        }
                    }
                    
                    $markdown += "`n"
                }
            }
            
            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,TaggedStandardPrecision,StandardizedNumbers`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                
                $taggedStandardPrecision = ""
                if ($task.StandardizedPrecisionAttributes.TaggedStandardPrecision.Count -gt 0) {
                    $taggedStandardPrecision = ($task.StandardizedPrecisionAttributes.TaggedStandardPrecision | ForEach-Object { "Précision: $($_.Value) (original: $($_.Original))" }) -join '; '
                }
                
                $standardizedNumbers = ""
                if ($task.StandardizedPrecisionAttributes.StandardizedNumbers.Count -gt 0) {
                    $standardizedNumbers = ($task.StandardizedPrecisionAttributes.StandardizedNumbers | ForEach-Object { "$($_.Value) (original: $($_.Original), précision standardisée: $($_.StandardizedPrecision))" }) -join '; '
                }
                
                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'
                
                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$taggedStandardPrecision`",`"$standardizedNumbers`"`n"
            }
            
            return $csv
        }
    }
}

# Exécuter la fonction principale avec les paramètres fournis
Get-StandardizedPrecision -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat -DefaultPrecision $DefaultPrecision
