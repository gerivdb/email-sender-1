# Extract-ContextualPrecision.ps1
# Script pour extraire les nombres avec précision contextuelle des tags dans les fichiers markdown de roadmap
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

# Fonction pour extraire les nombres avec précision contextuelle
function Get-ContextualPrecisionNumbers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Host "Extraction des nombres avec précision contextuelle..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $contextualPrecisionValues = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Patterns pour les contextes de précision
    $contextPatterns = @{
        # Contexte de prix (€, $, EUR, USD)
        "Price" = '(?:\d+(?:[.,]\d+)?)\s*(?:€|\$|EUR|USD)'
        
        # Contexte de pourcentage (%)
        "Percentage" = '(?:\d+(?:[.,]\d+)?)\s*%'
        
        # Contexte de mesure (m, km, cm, mm)
        "Measurement" = '(?:\d+(?:[.,]\d+)?)\s*(?:m|km|cm|mm)'
        
        # Contexte de temps (h, min, s, ms)
        "Time" = '(?:\d+(?:[.,]\d+)?)\s*(?:h|min|s|ms)'
        
        # Contexte de poids (kg, g, mg)
        "Weight" = '(?:\d+(?:[.,]\d+)?)\s*(?:kg|g|mg)'
        
        # Contexte de température (°C, °F)
        "Temperature" = '(?:\d+(?:[.,]\d+)?)\s*(?:°C|°F)'
    }
    
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
                ContextualPrecisionValues = @{
                    Price = @()
                    Percentage = @()
                    Measurement = @()
                    Time = @()
                    Weight = @()
                    Temperature = @()
                }
            }
        }
    }
    
    # Deuxième passe : extraire les nombres avec précision contextuelle
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Parcourir tous les contextes de précision
            foreach ($contextKey in $contextPatterns.Keys) {
                $contextPattern = $contextPatterns[$contextKey]
                
                # Extraire les nombres avec précision contextuelle
                $matches = [regex]::Matches($taskLine, $contextPattern)
                foreach ($match in $matches) {
                    $contextValue = $match.Value
                    
                    # Extraire la valeur numérique et l'unité
                    if ($contextValue -match '(\d+(?:[.,]\d+)?)\s*(€|\$|EUR|USD|%|m|km|cm|mm|h|min|s|ms|kg|g|mg|°C|°F)') {
                        $numberValue = $matches[1]
                        $unit = $matches[2]
                        
                        # Normaliser la valeur numérique (remplacer la virgule par un point)
                        $normalizedValue = $numberValue -replace ',', '.'
                        
                        # Déterminer la précision en fonction du contexte
                        $precision = 0
                        if ($normalizedValue -match '\.(\d+)') {
                            $precision = $matches[1].Length
                        }
                        
                        $contextualPrecisionValue = @{
                            Value = $normalizedValue
                            Type = $contextKey
                            Original = $contextValue
                            Unit = $unit
                            Precision = $precision
                            Position = $match.Index
                        }
                        
                        # Ajouter la valeur de précision contextuelle à la tâche
                        $tasks[$taskId].ContextualPrecisionValues[$contextKey] += $contextualPrecisionValue
                        
                        # Ajouter la valeur de précision contextuelle aux attributs de précision contextuelle
                        if (-not $contextualPrecisionValues.ContainsKey($taskId)) {
                            $contextualPrecisionValues[$taskId] = @{
                                Price = @()
                                Percentage = @()
                                Measurement = @()
                                Time = @()
                                Weight = @()
                                Temperature = @()
                            }
                        }
                        
                        $contextualPrecisionValues[$taskId][$contextKey] += $contextualPrecisionValue
                    }
                }
            }
        }
    }
    
    return @{
        Tasks = $tasks
        ContextualPrecisionValues = $contextualPrecisionValues
    }
}

# Fonction principale pour extraire les nombres avec précision contextuelle
function Get-ContextualPrecision {
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
    
    # Extraire les nombres avec précision contextuelle
    $contextualPrecision = Get-ContextualPrecisionNumbers -Content $Content
    
    # Combiner les résultats
    $analysis = @{
        ContextualPrecisionValues = $contextualPrecision.ContextualPrecisionValues
        Tasks = @{}
        Stats = @{
            TotalTasks = 0
            TasksWithPriceValues = 0
            TasksWithPercentageValues = 0
            TasksWithMeasurementValues = 0
            TasksWithTimeValues = 0
            TasksWithWeightValues = 0
            TasksWithTemperatureValues = 0
        }
    }
    
    # Fusionner les informations des tâches
    $allTaskIds = @($contextualPrecision.Tasks.Keys) | Select-Object -Unique
    
    foreach ($taskId in $allTaskIds) {
        $task = @{
            Id = $taskId
            Title = ""
            Status = ""
            LineNumber = 0
            ContextualPrecisionAttributes = @{
                Price = @()
                Percentage = @()
                Measurement = @()
                Time = @()
                Weight = @()
                Temperature = @()
            }
        }
        
        if ($contextualPrecision.Tasks.ContainsKey($taskId)) {
            $task.Title = $contextualPrecision.Tasks[$taskId].Title
            $task.Status = $contextualPrecision.Tasks[$taskId].Status
            $task.LineNumber = $contextualPrecision.Tasks[$taskId].LineNumber
            $task.ContextualPrecisionAttributes.Price = $contextualPrecision.Tasks[$taskId].ContextualPrecisionValues.Price
            $task.ContextualPrecisionAttributes.Percentage = $contextualPrecision.Tasks[$taskId].ContextualPrecisionValues.Percentage
            $task.ContextualPrecisionAttributes.Measurement = $contextualPrecision.Tasks[$taskId].ContextualPrecisionValues.Measurement
            $task.ContextualPrecisionAttributes.Time = $contextualPrecision.Tasks[$taskId].ContextualPrecisionValues.Time
            $task.ContextualPrecisionAttributes.Weight = $contextualPrecision.Tasks[$taskId].ContextualPrecisionValues.Weight
            $task.ContextualPrecisionAttributes.Temperature = $contextualPrecision.Tasks[$taskId].ContextualPrecisionValues.Temperature
        }
        
        $analysis.Tasks[$taskId] = $task
    }
    
    # Calculer les statistiques
    $analysis.Stats.TotalTasks = $allTaskIds.Count
    $analysis.Stats.TasksWithPriceValues = ($analysis.Tasks.Values | Where-Object { $_.ContextualPrecisionAttributes.Price.Count -gt 0 }).Count
    $analysis.Stats.TasksWithPercentageValues = ($analysis.Tasks.Values | Where-Object { $_.ContextualPrecisionAttributes.Percentage.Count -gt 0 }).Count
    $analysis.Stats.TasksWithMeasurementValues = ($analysis.Tasks.Values | Where-Object { $_.ContextualPrecisionAttributes.Measurement.Count -gt 0 }).Count
    $analysis.Stats.TasksWithTimeValues = ($analysis.Tasks.Values | Where-Object { $_.ContextualPrecisionAttributes.Time.Count -gt 0 }).Count
    $analysis.Stats.TasksWithWeightValues = ($analysis.Tasks.Values | Where-Object { $_.ContextualPrecisionAttributes.Weight.Count -gt 0 }).Count
    $analysis.Stats.TasksWithTemperatureValues = ($analysis.Tasks.Values | Where-Object { $_.ContextualPrecisionAttributes.Temperature.Count -gt 0 }).Count
    
    # Formater les résultats selon le format demandé
    $output = Format-ContextualPrecisionOutput -Analysis $analysis -Format $OutputFormat
    
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
function Format-ContextualPrecisionOutput {
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
            $markdown = "# Analyse des nombres avec précision contextuelle`n`n"
            
            $markdown += "## Statistiques`n`n"
            $markdown += "- Nombre total de tâches: $($Analysis.Stats.TotalTasks)`n"
            $markdown += "- Tâches avec valeurs de prix: $($Analysis.Stats.TasksWithPriceValues)`n"
            $markdown += "- Tâches avec valeurs de pourcentage: $($Analysis.Stats.TasksWithPercentageValues)`n"
            $markdown += "- Tâches avec valeurs de mesure: $($Analysis.Stats.TasksWithMeasurementValues)`n"
            $markdown += "- Tâches avec valeurs de temps: $($Analysis.Stats.TasksWithTimeValues)`n"
            $markdown += "- Tâches avec valeurs de poids: $($Analysis.Stats.TasksWithWeightValues)`n"
            $markdown += "- Tâches avec valeurs de température: $($Analysis.Stats.TasksWithTemperatureValues)`n`n"
            
            $markdown += "## Tâches avec nombres à précision contextuelle`n`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                $hasContextualPrecisionAttributes = $task.ContextualPrecisionAttributes.Price.Count -gt 0 -or 
                                                  $task.ContextualPrecisionAttributes.Percentage.Count -gt 0 -or
                                                  $task.ContextualPrecisionAttributes.Measurement.Count -gt 0 -or
                                                  $task.ContextualPrecisionAttributes.Time.Count -gt 0 -or
                                                  $task.ContextualPrecisionAttributes.Weight.Count -gt 0 -or
                                                  $task.ContextualPrecisionAttributes.Temperature.Count -gt 0
                
                if ($hasContextualPrecisionAttributes) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"
                    
                    if ($task.ContextualPrecisionAttributes.Price.Count -gt 0) {
                        $markdown += "- Valeurs de prix:`n"
                        foreach ($value in $task.ContextualPrecisionAttributes.Price) {
                            $markdown += "  - $($value.Value) $($value.Unit) (original: $($value.Original), précision: $($value.Precision))`n"
                        }
                    }
                    
                    if ($task.ContextualPrecisionAttributes.Percentage.Count -gt 0) {
                        $markdown += "- Valeurs de pourcentage:`n"
                        foreach ($value in $task.ContextualPrecisionAttributes.Percentage) {
                            $markdown += "  - $($value.Value) $($value.Unit) (original: $($value.Original), précision: $($value.Precision))`n"
                        }
                    }
                    
                    if ($task.ContextualPrecisionAttributes.Measurement.Count -gt 0) {
                        $markdown += "- Valeurs de mesure:`n"
                        foreach ($value in $task.ContextualPrecisionAttributes.Measurement) {
                            $markdown += "  - $($value.Value) $($value.Unit) (original: $($value.Original), précision: $($value.Precision))`n"
                        }
                    }
                    
                    if ($task.ContextualPrecisionAttributes.Time.Count -gt 0) {
                        $markdown += "- Valeurs de temps:`n"
                        foreach ($value in $task.ContextualPrecisionAttributes.Time) {
                            $markdown += "  - $($value.Value) $($value.Unit) (original: $($value.Original), précision: $($value.Precision))`n"
                        }
                    }
                    
                    if ($task.ContextualPrecisionAttributes.Weight.Count -gt 0) {
                        $markdown += "- Valeurs de poids:`n"
                        foreach ($value in $task.ContextualPrecisionAttributes.Weight) {
                            $markdown += "  - $($value.Value) $($value.Unit) (original: $($value.Original), précision: $($value.Precision))`n"
                        }
                    }
                    
                    if ($task.ContextualPrecisionAttributes.Temperature.Count -gt 0) {
                        $markdown += "- Valeurs de température:`n"
                        foreach ($value in $task.ContextualPrecisionAttributes.Temperature) {
                            $markdown += "  - $($value.Value) $($value.Unit) (original: $($value.Original), précision: $($value.Precision))`n"
                        }
                    }
                    
                    $markdown += "`n"
                }
            }
            
            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,PriceValues,PercentageValues,MeasurementValues,TimeValues,WeightValues,TemperatureValues`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                
                $priceValues = ""
                if ($task.ContextualPrecisionAttributes.Price.Count -gt 0) {
                    $priceValues = ($task.ContextualPrecisionAttributes.Price | ForEach-Object { "$($_.Value) $($_.Unit) (précision: $($_.Precision))" }) -join '; '
                }
                
                $percentageValues = ""
                if ($task.ContextualPrecisionAttributes.Percentage.Count -gt 0) {
                    $percentageValues = ($task.ContextualPrecisionAttributes.Percentage | ForEach-Object { "$($_.Value) $($_.Unit) (précision: $($_.Precision))" }) -join '; '
                }
                
                $measurementValues = ""
                if ($task.ContextualPrecisionAttributes.Measurement.Count -gt 0) {
                    $measurementValues = ($task.ContextualPrecisionAttributes.Measurement | ForEach-Object { "$($_.Value) $($_.Unit) (précision: $($_.Precision))" }) -join '; '
                }
                
                $timeValues = ""
                if ($task.ContextualPrecisionAttributes.Time.Count -gt 0) {
                    $timeValues = ($task.ContextualPrecisionAttributes.Time | ForEach-Object { "$($_.Value) $($_.Unit) (précision: $($_.Precision))" }) -join '; '
                }
                
                $weightValues = ""
                if ($task.ContextualPrecisionAttributes.Weight.Count -gt 0) {
                    $weightValues = ($task.ContextualPrecisionAttributes.Weight | ForEach-Object { "$($_.Value) $($_.Unit) (précision: $($_.Precision))" }) -join '; '
                }
                
                $temperatureValues = ""
                if ($task.ContextualPrecisionAttributes.Temperature.Count -gt 0) {
                    $temperatureValues = ($task.ContextualPrecisionAttributes.Temperature | ForEach-Object { "$($_.Value) $($_.Unit) (précision: $($_.Precision))" }) -join '; '
                }
                
                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'
                
                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$priceValues`",`"$percentageValues`",`"$measurementValues`",`"$timeValues`",`"$weightValues`",`"$temperatureValues`"`n"
            }
            
            return $csv
        }
    }
}

# Exécuter la fonction principale avec les paramètres fournis
Get-ContextualPrecision -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat
