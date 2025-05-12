# Extract-PrecisionVariables.ps1
# Script pour extraire les nombres avec précisions variables des tags dans les fichiers markdown de roadmap
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

# Fonction pour extraire les nombres avec 1 décimale
function Get-NumbersWithOneDecimal {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Host "Extraction des nombres avec 1 décimale..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $precisionValues = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Pattern pour les nombres avec 1 décimale
    $oneDecimalPattern = '(?<!\d)(\d+\.\d{1})(?!\d)'  # 1.5, 2.7, etc.
    $oneDecimalCommaPattern = '(?<!\d)(\d+,\d{1})(?!\d)'  # 1,5, 2,7, etc. (format européen)
    
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
                PrecisionValues = @{
                    OneDecimal = @()
                    TwoDecimals = @()
                    ThreePlusDecimals = @()
                }
            }
        }
    }
    
    # Deuxième passe : extraire les nombres avec 1 décimale
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Extraire les nombres avec 1 décimale (point)
            $matches = [regex]::Matches($taskLine, $oneDecimalPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                
                # Vérifier que ce n'est pas une partie d'un identifiant de tâche
                if ($taskId -ne $numberValue) {
                    $precisionValue = @{
                        Value = $numberValue
                        Type = "OneDecimal"
                        Original = $numberValue
                        Separator = "."
                        Precision = 1
                        Position = $match.Index
                    }
                    
                    # Ajouter la valeur de précision à la tâche
                    $tasks[$taskId].PrecisionValues.OneDecimal += $precisionValue
                    
                    # Ajouter la valeur de précision aux attributs de précision
                    if (-not $precisionValues.ContainsKey($taskId)) {
                        $precisionValues[$taskId] = @{
                            OneDecimal = @()
                            TwoDecimals = @()
                            ThreePlusDecimals = @()
                        }
                    }
                    
                    $precisionValues[$taskId].OneDecimal += $precisionValue
                }
            }
            
            # Extraire les nombres avec 1 décimale (virgule)
            $matches = [regex]::Matches($taskLine, $oneDecimalCommaPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $normalizedValue = $numberValue -replace ',', '.'
                
                # Vérifier que ce n'est pas une partie d'un identifiant de tâche
                if ($taskId -ne $numberValue) {
                    $precisionValue = @{
                        Value = $normalizedValue
                        Type = "OneDecimal"
                        Original = $numberValue
                        Separator = ","
                        Precision = 1
                        Position = $match.Index
                    }
                    
                    # Ajouter la valeur de précision à la tâche
                    $tasks[$taskId].PrecisionValues.OneDecimal += $precisionValue
                    
                    # Ajouter la valeur de précision aux attributs de précision
                    if (-not $precisionValues.ContainsKey($taskId)) {
                        $precisionValues[$taskId] = @{
                            OneDecimal = @()
                            TwoDecimals = @()
                            ThreePlusDecimals = @()
                        }
                    }
                    
                    $precisionValues[$taskId].OneDecimal += $precisionValue
                }
            }
        }
    }
    
    return @{
        Tasks = $tasks
        PrecisionValues = $precisionValues
    }
}

# Fonction pour extraire les nombres avec 2 décimales
function Get-NumbersWithTwoDecimals {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Host "Extraction des nombres avec 2 décimales..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $precisionValues = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Pattern pour les nombres avec 2 décimales
    $twoDecimalsPattern = '(?<!\d)(\d+\.\d{2})(?!\d)'  # 1.25, 2.75, etc.
    $twoDecimalsCommaPattern = '(?<!\d)(\d+,\d{2})(?!\d)'  # 1,25, 2,75, etc. (format européen)
    
    # Première passe : identifier toutes les tâches
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskTitle = $matches[3]
            $taskStatus = if ($matches[1] -match '[xX]') { "Completed" } else { "Pending" }
            
            if (-not $tasks.ContainsKey($taskId)) {
                $tasks[$taskId] = @{
                    Id = $taskId
                    Title = $taskTitle
                    Status = $taskStatus
                    LineNumber = $lineNumber
                    PrecisionValues = @{
                        OneDecimal = @()
                        TwoDecimals = @()
                        ThreePlusDecimals = @()
                    }
                }
            }
        }
    }
    
    # Deuxième passe : extraire les nombres avec 2 décimales
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Extraire les nombres avec 2 décimales (point)
            $matches = [regex]::Matches($taskLine, $twoDecimalsPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                
                # Vérifier que ce n'est pas une partie d'un identifiant de tâche
                if ($taskId -ne $numberValue) {
                    $precisionValue = @{
                        Value = $numberValue
                        Type = "TwoDecimals"
                        Original = $numberValue
                        Separator = "."
                        Precision = 2
                        Position = $match.Index
                    }
                    
                    # Ajouter la valeur de précision à la tâche
                    $tasks[$taskId].PrecisionValues.TwoDecimals += $precisionValue
                    
                    # Ajouter la valeur de précision aux attributs de précision
                    if (-not $precisionValues.ContainsKey($taskId)) {
                        $precisionValues[$taskId] = @{
                            OneDecimal = @()
                            TwoDecimals = @()
                            ThreePlusDecimals = @()
                        }
                    }
                    
                    $precisionValues[$taskId].TwoDecimals += $precisionValue
                }
            }
            
            # Extraire les nombres avec 2 décimales (virgule)
            $matches = [regex]::Matches($taskLine, $twoDecimalsCommaPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $normalizedValue = $numberValue -replace ',', '.'
                
                # Vérifier que ce n'est pas une partie d'un identifiant de tâche
                if ($taskId -ne $numberValue) {
                    $precisionValue = @{
                        Value = $normalizedValue
                        Type = "TwoDecimals"
                        Original = $numberValue
                        Separator = ","
                        Precision = 2
                        Position = $match.Index
                    }
                    
                    # Ajouter la valeur de précision à la tâche
                    $tasks[$taskId].PrecisionValues.TwoDecimals += $precisionValue
                    
                    # Ajouter la valeur de précision aux attributs de précision
                    if (-not $precisionValues.ContainsKey($taskId)) {
                        $precisionValues[$taskId] = @{
                            OneDecimal = @()
                            TwoDecimals = @()
                            ThreePlusDecimals = @()
                        }
                    }
                    
                    $precisionValues[$taskId].TwoDecimals += $precisionValue
                }
            }
        }
    }
    
    return @{
        Tasks = $tasks
        PrecisionValues = $precisionValues
    }
}

# Fonction pour extraire les nombres avec 3+ décimales
function Get-NumbersWithThreePlusDecimals {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Host "Extraction des nombres avec 3+ décimales..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $precisionValues = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Pattern pour les nombres avec 3+ décimales
    $threePlusDecimalsPattern = '(?<!\d)(\d+\.\d{3,})(?!\d)'  # 1.234, 2.7589, etc.
    $threePlusDecimalsCommaPattern = '(?<!\d)(\d+,\d{3,})(?!\d)'  # 1,234, 2,7589, etc. (format européen)
    
    # Première passe : identifier toutes les tâches
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskTitle = $matches[3]
            $taskStatus = if ($matches[1] -match '[xX]') { "Completed" } else { "Pending" }
            
            if (-not $tasks.ContainsKey($taskId)) {
                $tasks[$taskId] = @{
                    Id = $taskId
                    Title = $taskTitle
                    Status = $taskStatus
                    LineNumber = $lineNumber
                    PrecisionValues = @{
                        OneDecimal = @()
                        TwoDecimals = @()
                        ThreePlusDecimals = @()
                    }
                }
            }
        }
    }
    
    # Deuxième passe : extraire les nombres avec 3+ décimales
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Extraire les nombres avec 3+ décimales (point)
            $matches = [regex]::Matches($taskLine, $threePlusDecimalsPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $precision = ($numberValue -split '\.')[1].Length
                
                # Vérifier que ce n'est pas une partie d'un identifiant de tâche
                if ($taskId -ne $numberValue) {
                    $precisionValue = @{
                        Value = $numberValue
                        Type = "ThreePlusDecimals"
                        Original = $numberValue
                        Separator = "."
                        Precision = $precision
                        Position = $match.Index
                    }
                    
                    # Ajouter la valeur de précision à la tâche
                    $tasks[$taskId].PrecisionValues.ThreePlusDecimals += $precisionValue
                    
                    # Ajouter la valeur de précision aux attributs de précision
                    if (-not $precisionValues.ContainsKey($taskId)) {
                        $precisionValues[$taskId] = @{
                            OneDecimal = @()
                            TwoDecimals = @()
                            ThreePlusDecimals = @()
                        }
                    }
                    
                    $precisionValues[$taskId].ThreePlusDecimals += $precisionValue
                }
            }
            
            # Extraire les nombres avec 3+ décimales (virgule)
            $matches = [regex]::Matches($taskLine, $threePlusDecimalsCommaPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $normalizedValue = $numberValue -replace ',', '.'
                $precision = ($normalizedValue -split '\.')[1].Length
                
                # Vérifier que ce n'est pas une partie d'un identifiant de tâche
                if ($taskId -ne $numberValue) {
                    $precisionValue = @{
                        Value = $normalizedValue
                        Type = "ThreePlusDecimals"
                        Original = $numberValue
                        Separator = ","
                        Precision = $precision
                        Position = $match.Index
                    }
                    
                    # Ajouter la valeur de précision à la tâche
                    $tasks[$taskId].PrecisionValues.ThreePlusDecimals += $precisionValue
                    
                    # Ajouter la valeur de précision aux attributs de précision
                    if (-not $precisionValues.ContainsKey($taskId)) {
                        $precisionValues[$taskId] = @{
                            OneDecimal = @()
                            TwoDecimals = @()
                            ThreePlusDecimals = @()
                        }
                    }
                    
                    $precisionValues[$taskId].ThreePlusDecimals += $precisionValue
                }
            }
        }
    }
    
    return @{
        Tasks = $tasks
        PrecisionValues = $precisionValues
    }
}

# Fonction principale pour extraire les nombres avec précisions variables
function Get-PrecisionVariables {
    [CmdletBinding()]
    param (
        [string]$FilePath,
        [string]$Content,
        [string]$OutputPath,
        [string]$OutputFormat
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
    
    # Extraire les différents types de nombres avec précisions variables
    $oneDecimal = Get-NumbersWithOneDecimal -Content $Content
    $twoDecimals = Get-NumbersWithTwoDecimals -Content $Content
    $threePlusDecimals = Get-NumbersWithThreePlusDecimals -Content $Content
    
    # Combiner les résultats
    $analysis = @{
        OneDecimal = $oneDecimal.PrecisionValues
        TwoDecimals = $twoDecimals.PrecisionValues
        ThreePlusDecimals = $threePlusDecimals.PrecisionValues
        Tasks = @{}
        Stats = @{
            TotalTasks = 0
            TasksWithOneDecimal = 0
            TasksWithTwoDecimals = 0
            TasksWithThreePlusDecimals = 0
        }
    }
    
    # Fusionner les informations des tâches
    $allTaskIds = @($oneDecimal.Tasks.Keys) + @($twoDecimals.Tasks.Keys) + @($threePlusDecimals.Tasks.Keys) | Select-Object -Unique
    
    foreach ($taskId in $allTaskIds) {
        $task = @{
            Id = $taskId
            Title = ""
            Status = ""
            LineNumber = 0
            PrecisionValueAttributes = @{
                OneDecimal = @()
                TwoDecimals = @()
                ThreePlusDecimals = @()
            }
        }
        
        if ($oneDecimal.Tasks.ContainsKey($taskId)) {
            $task.Title = $oneDecimal.Tasks[$taskId].Title
            $task.Status = $oneDecimal.Tasks[$taskId].Status
            $task.LineNumber = $oneDecimal.Tasks[$taskId].LineNumber
            $task.PrecisionValueAttributes.OneDecimal = $oneDecimal.Tasks[$taskId].PrecisionValues.OneDecimal
        }
        
        if ($twoDecimals.Tasks.ContainsKey($taskId)) {
            if ([string]::IsNullOrEmpty($task.Title)) {
                $task.Title = $twoDecimals.Tasks[$taskId].Title
                $task.Status = $twoDecimals.Tasks[$taskId].Status
                $task.LineNumber = $twoDecimals.Tasks[$taskId].LineNumber
            }
            
            $task.PrecisionValueAttributes.TwoDecimals = $twoDecimals.Tasks[$taskId].PrecisionValues.TwoDecimals
        }
        
        if ($threePlusDecimals.Tasks.ContainsKey($taskId)) {
            if ([string]::IsNullOrEmpty($task.Title)) {
                $task.Title = $threePlusDecimals.Tasks[$taskId].Title
                $task.Status = $threePlusDecimals.Tasks[$taskId].Status
                $task.LineNumber = $threePlusDecimals.Tasks[$taskId].LineNumber
            }
            
            $task.PrecisionValueAttributes.ThreePlusDecimals = $threePlusDecimals.Tasks[$taskId].PrecisionValues.ThreePlusDecimals
        }
        
        $analysis.Tasks[$taskId] = $task
    }
    
    # Calculer les statistiques
    $analysis.Stats.TotalTasks = $allTaskIds.Count
    $analysis.Stats.TasksWithOneDecimal = ($analysis.Tasks.Values | Where-Object { $_.PrecisionValueAttributes.OneDecimal.Count -gt 0 }).Count
    $analysis.Stats.TasksWithTwoDecimals = ($analysis.Tasks.Values | Where-Object { $_.PrecisionValueAttributes.TwoDecimals.Count -gt 0 }).Count
    $analysis.Stats.TasksWithThreePlusDecimals = ($analysis.Tasks.Values | Where-Object { $_.PrecisionValueAttributes.ThreePlusDecimals.Count -gt 0 }).Count
    
    # Formater les résultats selon le format demandé
    $output = Format-PrecisionVariablesOutput -Analysis $analysis -Format $OutputFormat
    
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
function Format-PrecisionVariablesOutput {
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
            $markdown = "# Analyse des nombres avec précisions variables`n`n"
            
            $markdown += "## Statistiques`n`n"
            $markdown += "- Nombre total de tâches: $($Analysis.Stats.TotalTasks)`n"
            $markdown += "- Tâches avec nombres à 1 décimale: $($Analysis.Stats.TasksWithOneDecimal)`n"
            $markdown += "- Tâches avec nombres à 2 décimales: $($Analysis.Stats.TasksWithTwoDecimals)`n"
            $markdown += "- Tâches avec nombres à 3+ décimales: $($Analysis.Stats.TasksWithThreePlusDecimals)`n`n"
            
            $markdown += "## Tâches avec nombres à précisions variables`n`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                $hasPrecisionValueAttributes = $task.PrecisionValueAttributes.OneDecimal.Count -gt 0 -or 
                                             $task.PrecisionValueAttributes.TwoDecimals.Count -gt 0 -or
                                             $task.PrecisionValueAttributes.ThreePlusDecimals.Count -gt 0
                
                if ($hasPrecisionValueAttributes) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"
                    
                    if ($task.PrecisionValueAttributes.OneDecimal.Count -gt 0) {
                        $markdown += "- Nombres à 1 décimale:`n"
                        foreach ($value in $task.PrecisionValueAttributes.OneDecimal) {
                            $markdown += "  - $($value.Value) (original: $($value.Original), séparateur: $($value.Separator), précision: $($value.Precision))`n"
                        }
                    }
                    
                    if ($task.PrecisionValueAttributes.TwoDecimals.Count -gt 0) {
                        $markdown += "- Nombres à 2 décimales:`n"
                        foreach ($value in $task.PrecisionValueAttributes.TwoDecimals) {
                            $markdown += "  - $($value.Value) (original: $($value.Original), séparateur: $($value.Separator), précision: $($value.Precision))`n"
                        }
                    }
                    
                    if ($task.PrecisionValueAttributes.ThreePlusDecimals.Count -gt 0) {
                        $markdown += "- Nombres à 3+ décimales:`n"
                        foreach ($value in $task.PrecisionValueAttributes.ThreePlusDecimals) {
                            $markdown += "  - $($value.Value) (original: $($value.Original), séparateur: $($value.Separator), précision: $($value.Precision))`n"
                        }
                    }
                    
                    $markdown += "`n"
                }
            }
            
            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,OneDecimal,TwoDecimals,ThreePlusDecimals`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                
                $oneDecimal = ""
                if ($task.PrecisionValueAttributes.OneDecimal.Count -gt 0) {
                    $oneDecimal = ($task.PrecisionValueAttributes.OneDecimal | ForEach-Object { "$($_.Value) (original: $($_.Original), précision: $($_.Precision))" }) -join '; '
                }
                
                $twoDecimals = ""
                if ($task.PrecisionValueAttributes.TwoDecimals.Count -gt 0) {
                    $twoDecimals = ($task.PrecisionValueAttributes.TwoDecimals | ForEach-Object { "$($_.Value) (original: $($_.Original), précision: $($_.Precision))" }) -join '; '
                }
                
                $threePlusDecimals = ""
                if ($task.PrecisionValueAttributes.ThreePlusDecimals.Count -gt 0) {
                    $threePlusDecimals = ($task.PrecisionValueAttributes.ThreePlusDecimals | ForEach-Object { "$($_.Value) (original: $($_.Original), précision: $($_.Precision))" }) -join '; '
                }
                
                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'
                
                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$oneDecimal`",`"$twoDecimals`",`"$threePlusDecimals`"`n"
            }
            
            return $csv
        }
    }
}

# Exécuter la fonction principale avec les paramètres fournis
Get-PrecisionVariables -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat
