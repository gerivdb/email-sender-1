# Convert-PrecisionFormat.ps1
# Script pour convertir les nombres entre différentes précisions dans les fichiers markdown de roadmap
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
    [int]$DefaultSourcePrecision = 2,
    
    [Parameter(Mandatory = $false)]
    [int]$DefaultTargetPrecision = 2
)

# Fonction pour convertir les nombres entre différentes précisions
function Get-ConvertedPrecisionNumbers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $false)]
        [int]$DefaultSourcePrecision = 2,
        
        [Parameter(Mandatory = $false)]
        [int]$DefaultTargetPrecision = 2
    )
    
    Write-Host "Conversion des nombres entre différentes précisions..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $convertedPrecisionValues = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Pattern pour les tags de conversion de précision
    # Format: #convert-precision:source-target ou #convert-precision(source-target)
    $convertPrecisionTagPattern = '#convert-precision:(\d+)-(\d+)'
    $convertPrecisionParenTagPattern = '#convert-precision\((\d+)-(\d+)\)'
    
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
                ConvertedPrecisionValues = @{
                    TaggedConversionRules = @()
                    ConvertedNumbers = @()
                }
            }
        }
    }
    
    # Deuxième passe : extraire les tags de conversion de précision et les nombres associés
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Extraire les tags de conversion de précision
            $sourcePrecision = $null
            $targetPrecision = $null
            
            # Format #convert-precision:source-target
            if ($taskLine -match $convertPrecisionTagPattern) {
                $sourcePrecision = [int]$matches[1]
                $targetPrecision = [int]$matches[2]
                
                $conversionTag = @{
                    SourcePrecision = $sourcePrecision
                    TargetPrecision = $targetPrecision
                    Type = "ConversionTag"
                    Original = "#convert-precision:$sourcePrecision-$targetPrecision"
                }
                
                # Ajouter le tag de conversion de précision à la tâche
                $tasks[$taskId].ConvertedPrecisionValues.TaggedConversionRules += $conversionTag
                
                # Ajouter le tag de conversion de précision aux attributs de valeurs converties
                if (-not $convertedPrecisionValues.ContainsKey($taskId)) {
                    $convertedPrecisionValues[$taskId] = @{
                        TaggedConversionRules = @()
                        ConvertedNumbers = @()
                    }
                }
                
                $convertedPrecisionValues[$taskId].TaggedConversionRules += $conversionTag
            }
            
            # Format #convert-precision(source-target)
            if ($taskLine -match $convertPrecisionParenTagPattern) {
                $sourcePrecision = [int]$matches[1]
                $targetPrecision = [int]$matches[2]
                
                $conversionTag = @{
                    SourcePrecision = $sourcePrecision
                    TargetPrecision = $targetPrecision
                    Type = "ConversionParenTag"
                    Original = "#convert-precision($sourcePrecision-$targetPrecision)"
                }
                
                # Ajouter le tag de conversion de précision à la tâche
                $tasks[$taskId].ConvertedPrecisionValues.TaggedConversionRules += $conversionTag
                
                # Ajouter le tag de conversion de précision aux attributs de valeurs converties
                if (-not $convertedPrecisionValues.ContainsKey($taskId)) {
                    $convertedPrecisionValues[$taskId] = @{
                        TaggedConversionRules = @()
                        ConvertedNumbers = @()
                    }
                }
                
                $convertedPrecisionValues[$taskId].TaggedConversionRules += $conversionTag
            }
            
            # Si aucun tag de conversion de précision n'a été trouvé, utiliser les valeurs par défaut
            if ($sourcePrecision -eq $null -or $targetPrecision -eq $null) {
                $sourcePrecision = $DefaultSourcePrecision
                $targetPrecision = $DefaultTargetPrecision
            }
            
            # Extraire les nombres décimaux et les convertir
            # Extraire les nombres décimaux avec point
            $matches = [regex]::Matches($taskLine, $decimalNumberPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $originalPrecision = ($numberValue -split '\.')[1].Length
                
                # Convertir la précision du nombre
                $convertedValue = Convert-PrecisionFormat -Value $numberValue -SourcePrecision $sourcePrecision -TargetPrecision $targetPrecision
                
                $convertedNumber = @{
                    Value = $convertedValue
                    Type = "ConvertedNumber"
                    Original = $numberValue
                    OriginalPrecision = $originalPrecision
                    SourcePrecision = $sourcePrecision
                    TargetPrecision = $targetPrecision
                    Position = $match.Index
                }
                
                # Ajouter le nombre converti à la tâche
                $tasks[$taskId].ConvertedPrecisionValues.ConvertedNumbers += $convertedNumber
                
                # Ajouter le nombre converti aux attributs de valeurs converties
                if (-not $convertedPrecisionValues.ContainsKey($taskId)) {
                    $convertedPrecisionValues[$taskId] = @{
                        TaggedConversionRules = @()
                        ConvertedNumbers = @()
                    }
                }
                
                $convertedPrecisionValues[$taskId].ConvertedNumbers += $convertedNumber
            }
            
            # Extraire les nombres décimaux avec virgule
            $matches = [regex]::Matches($taskLine, $commaDecimalNumberPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $normalizedValue = $numberValue -replace ',', '.'
                $originalPrecision = ($normalizedValue -split '\.')[1].Length
                
                # Convertir la précision du nombre
                $convertedValue = Convert-PrecisionFormat -Value $normalizedValue -SourcePrecision $sourcePrecision -TargetPrecision $targetPrecision
                
                $convertedNumber = @{
                    Value = $convertedValue
                    Type = "ConvertedNumber"
                    Original = $numberValue
                    OriginalPrecision = $originalPrecision
                    SourcePrecision = $sourcePrecision
                    TargetPrecision = $targetPrecision
                    Position = $match.Index
                }
                
                # Ajouter le nombre converti à la tâche
                $tasks[$taskId].ConvertedPrecisionValues.ConvertedNumbers += $convertedNumber
                
                # Ajouter le nombre converti aux attributs de valeurs converties
                if (-not $convertedPrecisionValues.ContainsKey($taskId)) {
                    $convertedPrecisionValues[$taskId] = @{
                        TaggedConversionRules = @()
                        ConvertedNumbers = @()
                    }
                }
                
                $convertedPrecisionValues[$taskId].ConvertedNumbers += $convertedNumber
            }
        }
    }
    
    return @{
        Tasks = $tasks
        ConvertedPrecisionValues = $convertedPrecisionValues
    }
}

# Fonction pour convertir un nombre entre différentes précisions
function Convert-PrecisionFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Value,
        
        [Parameter(Mandatory = $true)]
        [int]$SourcePrecision,
        
        [Parameter(Mandatory = $true)]
        [int]$TargetPrecision
    )
    
    # Convertir la valeur en nombre
    $number = [double]$Value
    
    # Arrondir le nombre à la précision source
    $sourceNumber = [math]::Round($number, $SourcePrecision)
    
    # Convertir le nombre à la précision cible
    $targetNumber = [math]::Round($sourceNumber, $TargetPrecision)
    
    return $targetNumber
}

# Fonction principale pour convertir les nombres entre différentes précisions
function Get-ConvertedPrecisionValues {
    [CmdletBinding()]
    param (
        [string]$FilePath,
        [string]$Content,
        [string]$OutputPath,
        [string]$OutputFormat,
        [int]$DefaultSourcePrecision,
        [int]$DefaultTargetPrecision
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
    
    # Convertir les nombres entre différentes précisions
    $convertedPrecision = Get-ConvertedPrecisionNumbers -Content $Content -DefaultSourcePrecision $DefaultSourcePrecision -DefaultTargetPrecision $DefaultTargetPrecision
    
    # Combiner les résultats
    $analysis = @{
        ConvertedPrecisionValues = $convertedPrecision.ConvertedPrecisionValues
        Tasks = @{}
        Stats = @{
            TotalTasks = 0
            TasksWithTaggedConversionRules = 0
            TasksWithConvertedNumbers = 0
        }
    }
    
    # Fusionner les informations des tâches
    $allTaskIds = @($convertedPrecision.Tasks.Keys) | Select-Object -Unique
    
    foreach ($taskId in $allTaskIds) {
        $task = @{
            Id = $taskId
            Title = ""
            Status = ""
            LineNumber = 0
            ConvertedPrecisionAttributes = @{
                TaggedConversionRules = @()
                ConvertedNumbers = @()
            }
        }
        
        if ($convertedPrecision.Tasks.ContainsKey($taskId)) {
            $task.Title = $convertedPrecision.Tasks[$taskId].Title
            $task.Status = $convertedPrecision.Tasks[$taskId].Status
            $task.LineNumber = $convertedPrecision.Tasks[$taskId].LineNumber
            $task.ConvertedPrecisionAttributes.TaggedConversionRules = $convertedPrecision.Tasks[$taskId].ConvertedPrecisionValues.TaggedConversionRules
            $task.ConvertedPrecisionAttributes.ConvertedNumbers = $convertedPrecision.Tasks[$taskId].ConvertedPrecisionValues.ConvertedNumbers
        }
        
        $analysis.Tasks[$taskId] = $task
    }
    
    # Calculer les statistiques
    $analysis.Stats.TotalTasks = $allTaskIds.Count
    $analysis.Stats.TasksWithTaggedConversionRules = ($analysis.Tasks.Values | Where-Object { $_.ConvertedPrecisionAttributes.TaggedConversionRules.Count -gt 0 }).Count
    $analysis.Stats.TasksWithConvertedNumbers = ($analysis.Tasks.Values | Where-Object { $_.ConvertedPrecisionAttributes.ConvertedNumbers.Count -gt 0 }).Count
    
    # Formater les résultats selon le format demandé
    $output = Format-ConvertedPrecisionOutput -Analysis $analysis -Format $OutputFormat
    
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
function Format-ConvertedPrecisionOutput {
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
            $markdown = "# Analyse des nombres avec conversion de précision`n`n"
            
            $markdown += "## Statistiques`n`n"
            $markdown += "- Nombre total de tâches: $($Analysis.Stats.TotalTasks)`n"
            $markdown += "- Tâches avec tags de conversion de précision: $($Analysis.Stats.TasksWithTaggedConversionRules)`n"
            $markdown += "- Tâches avec nombres convertis: $($Analysis.Stats.TasksWithConvertedNumbers)`n`n"
            
            $markdown += "## Tâches avec nombres convertis`n`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                $hasConvertedPrecisionAttributes = $task.ConvertedPrecisionAttributes.TaggedConversionRules.Count -gt 0 -or 
                                                 $task.ConvertedPrecisionAttributes.ConvertedNumbers.Count -gt 0
                
                if ($hasConvertedPrecisionAttributes) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"
                    
                    if ($task.ConvertedPrecisionAttributes.TaggedConversionRules.Count -gt 0) {
                        $markdown += "- Tags de conversion de précision:`n"
                        foreach ($tag in $task.ConvertedPrecisionAttributes.TaggedConversionRules) {
                            $markdown += "  - Source: $($tag.SourcePrecision), Cible: $($tag.TargetPrecision) (original: $($tag.Original))`n"
                        }
                    }
                    
                    if ($task.ConvertedPrecisionAttributes.ConvertedNumbers.Count -gt 0) {
                        $markdown += "- Nombres convertis:`n"
                        foreach ($number in $task.ConvertedPrecisionAttributes.ConvertedNumbers) {
                            $markdown += "  - $($number.Value) (original: $($number.Original), précision source: $($number.SourcePrecision), précision cible: $($number.TargetPrecision))`n"
                        }
                    }
                    
                    $markdown += "`n"
                }
            }
            
            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,TaggedConversionRules,ConvertedNumbers`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                
                $taggedConversionRules = ""
                if ($task.ConvertedPrecisionAttributes.TaggedConversionRules.Count -gt 0) {
                    $taggedConversionRules = ($task.ConvertedPrecisionAttributes.TaggedConversionRules | ForEach-Object { "Source: $($_.SourcePrecision), Cible: $($_.TargetPrecision) (original: $($_.Original))" }) -join '; '
                }
                
                $convertedNumbers = ""
                if ($task.ConvertedPrecisionAttributes.ConvertedNumbers.Count -gt 0) {
                    $convertedNumbers = ($task.ConvertedPrecisionAttributes.ConvertedNumbers | ForEach-Object { "$($_.Value) (original: $($_.Original), précision source: $($_.SourcePrecision), précision cible: $($_.TargetPrecision))" }) -join '; '
                }
                
                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'
                
                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$taggedConversionRules`",`"$convertedNumbers`"`n"
            }
            
            return $csv
        }
    }
}

# Exécuter la fonction principale avec les paramètres fournis
Get-ConvertedPrecisionValues -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat -DefaultSourcePrecision $DefaultSourcePrecision -DefaultTargetPrecision $DefaultTargetPrecision
