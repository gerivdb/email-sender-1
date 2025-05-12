# Extract-NumericValues.ps1
# Script pour extraire les valeurs numériques des tags dans les fichiers markdown de roadmap
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

# Fonction pour extraire les nombres simples (entiers)
function Get-SimpleNumbers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Host "Extraction des nombres simples..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $numericValues = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Pattern pour les nombres simples (entiers)
    $simpleNumberPattern = '(?<![0-9.,_])(\d+)(?![0-9.,_])'
    
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
                NumericValues = @{
                    SimpleNumbers = @()
                    NumbersWithSeparators = @()
                    DecimalNumbers = @()
                }
            }
        }
    }
    
    # Deuxième passe : extraire les nombres simples
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Extraire les nombres simples
            $matches = [regex]::Matches($taskLine, $simpleNumberPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                
                # Vérifier que ce n'est pas une partie d'un nombre avec séparateur ou décimal
                $isPartOfLargerNumber = $false
                if ($taskLine -match "[\d.,_]$numberValue" -or $taskLine -match "$numberValue[\d.,_]") {
                    $isPartOfLargerNumber = $true
                }
                
                if (-not $isPartOfLargerNumber) {
                    $numericValue = @{
                        Value = $numberValue
                        Type = "SimpleNumber"
                        Original = $numberValue
                        Position = $match.Index
                    }
                    
                    # Ajouter la valeur numérique à la tâche
                    $tasks[$taskId].NumericValues.SimpleNumbers += $numericValue
                    
                    # Ajouter la valeur numérique aux attributs numériques
                    if (-not $numericValues.ContainsKey($taskId)) {
                        $numericValues[$taskId] = @{
                            SimpleNumbers = @()
                            NumbersWithSeparators = @()
                            DecimalNumbers = @()
                        }
                    }
                    
                    $numericValues[$taskId].SimpleNumbers += $numericValue
                }
            }
        }
    }
    
    return @{
        Tasks = $tasks
        NumericValues = $numericValues
    }
}

# Fonction pour extraire les nombres avec séparateurs
function Get-NumbersWithSeparators {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Host "Extraction des nombres avec séparateurs..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $numericValues = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Patterns pour les nombres avec séparateurs
    $commaThousandPattern = '(\d{1,3}(?:,\d{3})+)(?!\d)'  # 1,000 / 1,000,000
    $underscoreThousandPattern = '(\d{1,3}(?:_\d{3})+)(?!\d)'  # 1_000 / 1_000_000
    $dotThousandPattern = '(\d{1,3}(?:\.\d{3})+)(?!\d)'  # 1.000 / 1.000.000 (format européen)
    
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
                    NumericValues = @{
                        SimpleNumbers = @()
                        NumbersWithSeparators = @()
                        DecimalNumbers = @()
                    }
                }
            }
        }
    }
    
    # Deuxième passe : extraire les nombres avec séparateurs
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Extraire les nombres avec séparateurs de milliers (virgule)
            $matches = [regex]::Matches($taskLine, $commaThousandPattern)
            foreach ($match in $matches) {
                $numberWithSeparator = $match.Groups[1].Value
                $normalizedValue = $numberWithSeparator -replace ',', ''
                
                $numericValue = @{
                    Value = $normalizedValue
                    Type = "NumberWithSeparator"
                    Original = $numberWithSeparator
                    Separator = ","
                    Position = $match.Index
                }
                
                # Ajouter la valeur numérique à la tâche
                $tasks[$taskId].NumericValues.NumbersWithSeparators += $numericValue
                
                # Ajouter la valeur numérique aux attributs numériques
                if (-not $numericValues.ContainsKey($taskId)) {
                    $numericValues[$taskId] = @{
                        SimpleNumbers = @()
                        NumbersWithSeparators = @()
                        DecimalNumbers = @()
                    }
                }
                
                $numericValues[$taskId].NumbersWithSeparators += $numericValue
            }
            
            # Extraire les nombres avec séparateurs de milliers (underscore)
            $matches = [regex]::Matches($taskLine, $underscoreThousandPattern)
            foreach ($match in $matches) {
                $numberWithSeparator = $match.Groups[1].Value
                $normalizedValue = $numberWithSeparator -replace '_', ''
                
                $numericValue = @{
                    Value = $normalizedValue
                    Type = "NumberWithSeparator"
                    Original = $numberWithSeparator
                    Separator = "_"
                    Position = $match.Index
                }
                
                # Ajouter la valeur numérique à la tâche
                $tasks[$taskId].NumericValues.NumbersWithSeparators += $numericValue
                
                # Ajouter la valeur numérique aux attributs numériques
                if (-not $numericValues.ContainsKey($taskId)) {
                    $numericValues[$taskId] = @{
                        SimpleNumbers = @()
                        NumbersWithSeparators = @()
                        DecimalNumbers = @()
                    }
                }
                
                $numericValues[$taskId].NumbersWithSeparators += $numericValue
            }
            
            # Extraire les nombres avec séparateurs de milliers (point - format européen)
            $matches = [regex]::Matches($taskLine, $dotThousandPattern)
            foreach ($match in $matches) {
                $numberWithSeparator = $match.Groups[1].Value
                $normalizedValue = $numberWithSeparator -replace '\.', ''
                
                $numericValue = @{
                    Value = $normalizedValue
                    Type = "NumberWithSeparator"
                    Original = $numberWithSeparator
                    Separator = "."
                    Position = $match.Index
                }
                
                # Ajouter la valeur numérique à la tâche
                $tasks[$taskId].NumericValues.NumbersWithSeparators += $numericValue
                
                # Ajouter la valeur numérique aux attributs numériques
                if (-not $numericValues.ContainsKey($taskId)) {
                    $numericValues[$taskId] = @{
                        SimpleNumbers = @()
                        NumbersWithSeparators = @()
                        DecimalNumbers = @()
                    }
                }
                
                $numericValues[$taskId].NumbersWithSeparators += $numericValue
            }
        }
    }
    
    return @{
        Tasks = $tasks
        NumericValues = $numericValues
    }
}

# Fonction pour extraire les nombres décimaux
function Get-DecimalNumbers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Host "Extraction des nombres décimaux..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $numericValues = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Patterns pour les nombres décimaux
    $dotDecimalPattern = '(\d+\.\d+)'  # 1.5 / 2.75
    $commaDecimalPattern = '(\d+,\d+)'  # 1,5 / 2,75 (format européen)
    
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
                    NumericValues = @{
                        SimpleNumbers = @()
                        NumbersWithSeparators = @()
                        DecimalNumbers = @()
                    }
                }
            }
        }
    }
    
    # Deuxième passe : extraire les nombres décimaux
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Extraire les nombres décimaux avec point
            $matches = [regex]::Matches($taskLine, $dotDecimalPattern)
            foreach ($match in $matches) {
                $decimalNumber = $match.Groups[1].Value
                
                $numericValue = @{
                    Value = $decimalNumber
                    Type = "DecimalNumber"
                    Original = $decimalNumber
                    Separator = "."
                    Position = $match.Index
                }
                
                # Ajouter la valeur numérique à la tâche
                $tasks[$taskId].NumericValues.DecimalNumbers += $numericValue
                
                # Ajouter la valeur numérique aux attributs numériques
                if (-not $numericValues.ContainsKey($taskId)) {
                    $numericValues[$taskId] = @{
                        SimpleNumbers = @()
                        NumbersWithSeparators = @()
                        DecimalNumbers = @()
                    }
                }
                
                $numericValues[$taskId].DecimalNumbers += $numericValue
            }
            
            # Extraire les nombres décimaux avec virgule
            $matches = [regex]::Matches($taskLine, $commaDecimalPattern)
            foreach ($match in $matches) {
                $decimalNumber = $match.Groups[1].Value
                $normalizedValue = $decimalNumber -replace ',', '.'
                
                $numericValue = @{
                    Value = $normalizedValue
                    Type = "DecimalNumber"
                    Original = $decimalNumber
                    Separator = ","
                    Position = $match.Index
                }
                
                # Ajouter la valeur numérique à la tâche
                $tasks[$taskId].NumericValues.DecimalNumbers += $numericValue
                
                # Ajouter la valeur numérique aux attributs numériques
                if (-not $numericValues.ContainsKey($taskId)) {
                    $numericValues[$taskId] = @{
                        SimpleNumbers = @()
                        NumbersWithSeparators = @()
                        DecimalNumbers = @()
                    }
                }
                
                $numericValues[$taskId].DecimalNumbers += $numericValue
            }
        }
    }
    
    return @{
        Tasks = $tasks
        NumericValues = $numericValues
    }
}

# Fonction principale pour extraire les valeurs numériques
function Get-NumericValues {
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
    
    # Extraire les différents types de valeurs numériques
    $simpleNumbers = Get-SimpleNumbers -Content $Content
    $numbersWithSeparators = Get-NumbersWithSeparators -Content $Content
    $decimalNumbers = Get-DecimalNumbers -Content $Content
    
    # Combiner les résultats
    $analysis = @{
        SimpleNumbers = $simpleNumbers.NumericValues
        NumbersWithSeparators = $numbersWithSeparators.NumericValues
        DecimalNumbers = $decimalNumbers.NumericValues
        Tasks = @{}
        Stats = @{
            TotalTasks = 0
            TasksWithSimpleNumbers = 0
            TasksWithNumbersWithSeparators = 0
            TasksWithDecimalNumbers = 0
        }
    }
    
    # Fusionner les informations des tâches
    $allTaskIds = @($simpleNumbers.Tasks.Keys) + @($numbersWithSeparators.Tasks.Keys) + @($decimalNumbers.Tasks.Keys) | Select-Object -Unique
    
    foreach ($taskId in $allTaskIds) {
        $task = @{
            Id = $taskId
            Title = ""
            Status = ""
            LineNumber = 0
            NumericValueAttributes = @{
                SimpleNumbers = @()
                NumbersWithSeparators = @()
                DecimalNumbers = @()
            }
        }
        
        if ($simpleNumbers.Tasks.ContainsKey($taskId)) {
            $task.Title = $simpleNumbers.Tasks[$taskId].Title
            $task.Status = $simpleNumbers.Tasks[$taskId].Status
            $task.LineNumber = $simpleNumbers.Tasks[$taskId].LineNumber
            $task.NumericValueAttributes.SimpleNumbers = $simpleNumbers.Tasks[$taskId].NumericValues.SimpleNumbers
        }
        
        if ($numbersWithSeparators.Tasks.ContainsKey($taskId)) {
            if ([string]::IsNullOrEmpty($task.Title)) {
                $task.Title = $numbersWithSeparators.Tasks[$taskId].Title
                $task.Status = $numbersWithSeparators.Tasks[$taskId].Status
                $task.LineNumber = $numbersWithSeparators.Tasks[$taskId].LineNumber
            }
            
            $task.NumericValueAttributes.NumbersWithSeparators = $numbersWithSeparators.Tasks[$taskId].NumericValues.NumbersWithSeparators
        }
        
        if ($decimalNumbers.Tasks.ContainsKey($taskId)) {
            if ([string]::IsNullOrEmpty($task.Title)) {
                $task.Title = $decimalNumbers.Tasks[$taskId].Title
                $task.Status = $decimalNumbers.Tasks[$taskId].Status
                $task.LineNumber = $decimalNumbers.Tasks[$taskId].LineNumber
            }
            
            $task.NumericValueAttributes.DecimalNumbers = $decimalNumbers.Tasks[$taskId].NumericValues.DecimalNumbers
        }
        
        $analysis.Tasks[$taskId] = $task
    }
    
    # Calculer les statistiques
    $analysis.Stats.TotalTasks = $allTaskIds.Count
    $analysis.Stats.TasksWithSimpleNumbers = ($analysis.Tasks.Values | Where-Object { $_.NumericValueAttributes.SimpleNumbers.Count -gt 0 }).Count
    $analysis.Stats.TasksWithNumbersWithSeparators = ($analysis.Tasks.Values | Where-Object { $_.NumericValueAttributes.NumbersWithSeparators.Count -gt 0 }).Count
    $analysis.Stats.TasksWithDecimalNumbers = ($analysis.Tasks.Values | Where-Object { $_.NumericValueAttributes.DecimalNumbers.Count -gt 0 }).Count
    
    # Formater les résultats selon le format demandé
    $output = Format-NumericValuesOutput -Analysis $analysis -Format $OutputFormat
    
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
function Format-NumericValuesOutput {
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
            $markdown = "# Analyse des valeurs numériques`n`n"
            
            $markdown += "## Statistiques`n`n"
            $markdown += "- Nombre total de tâches: $($Analysis.Stats.TotalTasks)`n"
            $markdown += "- Tâches avec nombres simples: $($Analysis.Stats.TasksWithSimpleNumbers)`n"
            $markdown += "- Tâches avec nombres avec séparateurs: $($Analysis.Stats.TasksWithNumbersWithSeparators)`n"
            $markdown += "- Tâches avec nombres décimaux: $($Analysis.Stats.TasksWithDecimalNumbers)`n`n"
            
            $markdown += "## Tâches avec valeurs numériques`n`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                $hasNumericValueAttributes = $task.NumericValueAttributes.SimpleNumbers.Count -gt 0 -or 
                                           $task.NumericValueAttributes.NumbersWithSeparators.Count -gt 0 -or
                                           $task.NumericValueAttributes.DecimalNumbers.Count -gt 0
                
                if ($hasNumericValueAttributes) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"
                    
                    if ($task.NumericValueAttributes.SimpleNumbers.Count -gt 0) {
                        $markdown += "- Nombres simples:`n"
                        foreach ($value in $task.NumericValueAttributes.SimpleNumbers) {
                            $markdown += "  - $($value.Value) (original: $($value.Original))`n"
                        }
                    }
                    
                    if ($task.NumericValueAttributes.NumbersWithSeparators.Count -gt 0) {
                        $markdown += "- Nombres avec séparateurs:`n"
                        foreach ($value in $task.NumericValueAttributes.NumbersWithSeparators) {
                            $markdown += "  - $($value.Value) (original: $($value.Original), séparateur: $($value.Separator))`n"
                        }
                    }
                    
                    if ($task.NumericValueAttributes.DecimalNumbers.Count -gt 0) {
                        $markdown += "- Nombres décimaux:`n"
                        foreach ($value in $task.NumericValueAttributes.DecimalNumbers) {
                            $markdown += "  - $($value.Value) (original: $($value.Original), séparateur: $($value.Separator))`n"
                        }
                    }
                    
                    $markdown += "`n"
                }
            }
            
            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,SimpleNumbers,NumbersWithSeparators,DecimalNumbers`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                
                $simpleNumbers = ""
                if ($task.NumericValueAttributes.SimpleNumbers.Count -gt 0) {
                    $simpleNumbers = ($task.NumericValueAttributes.SimpleNumbers | ForEach-Object { $_.Value }) -join '; '
                }
                
                $numbersWithSeparators = ""
                if ($task.NumericValueAttributes.NumbersWithSeparators.Count -gt 0) {
                    $numbersWithSeparators = ($task.NumericValueAttributes.NumbersWithSeparators | ForEach-Object { "$($_.Value) (original: $($_.Original))" }) -join '; '
                }
                
                $decimalNumbers = ""
                if ($task.NumericValueAttributes.DecimalNumbers.Count -gt 0) {
                    $decimalNumbers = ($task.NumericValueAttributes.DecimalNumbers | ForEach-Object { "$($_.Value) (original: $($_.Original))" }) -join '; '
                }
                
                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'
                
                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$simpleNumbers`",`"$numbersWithSeparators`",`"$decimalNumbers`"`n"
            }
            
            return $csv
        }
    }
}

# Exécuter la fonction principale avec les paramètres fournis
Get-NumericValues -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat
