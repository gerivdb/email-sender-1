# Apply-RoundingRules.ps1
# Script pour appliquer des règles d'arrondi et de troncature aux nombres dans les fichiers markdown de roadmap
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
    [ValidateSet("Round", "Ceiling", "Floor", "Truncate")]
    [string]$DefaultRoundingRule = "Round",
    
    [Parameter(Mandatory = $false)]
    [int]$DefaultPrecision = 2
)

# Fonction pour appliquer des règles d'arrondi et de troncature
function Get-RoundedNumbers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Round", "Ceiling", "Floor", "Truncate")]
        [string]$DefaultRoundingRule = "Round",
        
        [Parameter(Mandatory = $false)]
        [int]$DefaultPrecision = 2
    )
    
    Write-Host "Application des règles d'arrondi et de troncature..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $roundedValues = @{}
    
    # Patterns pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Pattern pour les tags de règle d'arrondi
    # Format: #round:rule:precision ou #round(rule:precision)
    $roundTagPattern = '#round:([a-zA-Z]+):(\d+)'
    $roundParenTagPattern = '#round\(([a-zA-Z]+):(\d+)\)'
    
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
                RoundedValues = @{
                    TaggedRoundingRules = @()
                    RoundedNumbers = @()
                }
            }
        }
    }
    
    # Deuxième passe : extraire les tags de règle d'arrondi et les nombres associés
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskLine = $line
            
            # Extraire les tags de règle d'arrondi
            $roundingRule = $null
            $precision = $null
            
            # Format #round:rule:precision
            if ($taskLine -match $roundTagPattern) {
                $roundingRule = $matches[1]
                $precision = [int]$matches[2]
                
                $roundingTag = @{
                    Rule = $roundingRule
                    Precision = $precision
                    Type = "RoundingTag"
                    Original = "#round:$roundingRule:$precision"
                }
                
                # Ajouter le tag de règle d'arrondi à la tâche
                $tasks[$taskId].RoundedValues.TaggedRoundingRules += $roundingTag
                
                # Ajouter le tag de règle d'arrondi aux attributs de valeurs arrondies
                if (-not $roundedValues.ContainsKey($taskId)) {
                    $roundedValues[$taskId] = @{
                        TaggedRoundingRules = @()
                        RoundedNumbers = @()
                    }
                }
                
                $roundedValues[$taskId].TaggedRoundingRules += $roundingTag
            }
            
            # Format #round(rule:precision)
            if ($taskLine -match $roundParenTagPattern) {
                $roundingRule = $matches[1]
                $precision = [int]$matches[2]
                
                $roundingTag = @{
                    Rule = $roundingRule
                    Precision = $precision
                    Type = "RoundingParenTag"
                    Original = "#round($roundingRule:$precision)"
                }
                
                # Ajouter le tag de règle d'arrondi à la tâche
                $tasks[$taskId].RoundedValues.TaggedRoundingRules += $roundingTag
                
                # Ajouter le tag de règle d'arrondi aux attributs de valeurs arrondies
                if (-not $roundedValues.ContainsKey($taskId)) {
                    $roundedValues[$taskId] = @{
                        TaggedRoundingRules = @()
                        RoundedNumbers = @()
                    }
                }
                
                $roundedValues[$taskId].TaggedRoundingRules += $roundingTag
            }
            
            # Si aucun tag de règle d'arrondi n'a été trouvé, utiliser les valeurs par défaut
            if ($roundingRule -eq $null -or $precision -eq $null) {
                $roundingRule = $DefaultRoundingRule
                $precision = $DefaultPrecision
            }
            
            # Extraire les nombres décimaux et les arrondir
            # Extraire les nombres décimaux avec point
            $matches = [regex]::Matches($taskLine, $decimalNumberPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $originalPrecision = ($numberValue -split '\.')[1].Length
                
                # Appliquer la règle d'arrondi
                $roundedValue = Set-RoundingRule -Value $numberValue -Rule $roundingRule -Precision $precision
                
                $roundedNumber = @{
                    Value = $roundedValue
                    Type = "RoundedNumber"
                    Original = $numberValue
                    OriginalPrecision = $originalPrecision
                    RoundingRule = $roundingRule
                    Precision = $precision
                    Position = $match.Index
                }
                
                # Ajouter le nombre arrondi à la tâche
                $tasks[$taskId].RoundedValues.RoundedNumbers += $roundedNumber
                
                # Ajouter le nombre arrondi aux attributs de valeurs arrondies
                if (-not $roundedValues.ContainsKey($taskId)) {
                    $roundedValues[$taskId] = @{
                        TaggedRoundingRules = @()
                        RoundedNumbers = @()
                    }
                }
                
                $roundedValues[$taskId].RoundedNumbers += $roundedNumber
            }
            
            # Extraire les nombres décimaux avec virgule
            $matches = [regex]::Matches($taskLine, $commaDecimalNumberPattern)
            foreach ($match in $matches) {
                $numberValue = $match.Groups[1].Value
                $normalizedValue = $numberValue -replace ',', '.'
                $originalPrecision = ($normalizedValue -split '\.')[1].Length
                
                # Appliquer la règle d'arrondi
                $roundedValue = Set-RoundingRule -Value $normalizedValue -Rule $roundingRule -Precision $precision
                
                $roundedNumber = @{
                    Value = $roundedValue
                    Type = "RoundedNumber"
                    Original = $numberValue
                    OriginalPrecision = $originalPrecision
                    RoundingRule = $roundingRule
                    Precision = $precision
                    Position = $match.Index
                }
                
                # Ajouter le nombre arrondi à la tâche
                $tasks[$taskId].RoundedValues.RoundedNumbers += $roundedNumber
                
                # Ajouter le nombre arrondi aux attributs de valeurs arrondies
                if (-not $roundedValues.ContainsKey($taskId)) {
                    $roundedValues[$taskId] = @{
                        TaggedRoundingRules = @()
                        RoundedNumbers = @()
                    }
                }
                
                $roundedValues[$taskId].RoundedNumbers += $roundedNumber
            }
        }
    }
    
    return @{
        Tasks = $tasks
        RoundedValues = $roundedValues
    }
}

# Fonction pour appliquer une règle d'arrondi à un nombre
function Set-RoundingRule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Value,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Round", "Ceiling", "Floor", "Truncate")]
        [string]$Rule,
        
        [Parameter(Mandatory = $true)]
        [int]$Precision
    )
    
    # Convertir la valeur en nombre
    $number = [double]$Value
    
    # Appliquer la règle d'arrondi
    switch ($Rule) {
        "Round" {
            # Arrondi standard (au plus proche)
            return [math]::Round($number, $Precision)
        }
        "Ceiling" {
            # Arrondi au plafond (vers le haut)
            $factor = [math]::Pow(10, $Precision)
            return [math]::Ceiling($number * $factor) / $factor
        }
        "Floor" {
            # Arrondi au plancher (vers le bas)
            $factor = [math]::Pow(10, $Precision)
            return [math]::Floor($number * $factor) / $factor
        }
        "Truncate" {
            # Troncature (suppression des décimales excédentaires)
            $factor = [math]::Pow(10, $Precision)
            return [math]::Truncate($number * $factor) / $factor
        }
    }
}

# Fonction principale pour appliquer des règles d'arrondi et de troncature
function Get-RoundedValues {
    [CmdletBinding()]
    param (
        [string]$FilePath,
        [string]$Content,
        [string]$OutputPath,
        [string]$OutputFormat,
        [string]$DefaultRoundingRule,
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
    
    # Appliquer les règles d'arrondi et de troncature
    $roundedNumbers = Get-RoundedNumbers -Content $Content -DefaultRoundingRule $DefaultRoundingRule -DefaultPrecision $DefaultPrecision
    
    # Combiner les résultats
    $analysis = @{
        RoundedValues = $roundedNumbers.RoundedValues
        Tasks = @{}
        Stats = @{
            TotalTasks = 0
            TasksWithTaggedRoundingRules = 0
            TasksWithRoundedNumbers = 0
        }
    }
    
    # Fusionner les informations des tâches
    $allTaskIds = @($roundedNumbers.Tasks.Keys) | Select-Object -Unique
    
    foreach ($taskId in $allTaskIds) {
        $task = @{
            Id = $taskId
            Title = ""
            Status = ""
            LineNumber = 0
            RoundedValueAttributes = @{
                TaggedRoundingRules = @()
                RoundedNumbers = @()
            }
        }
        
        if ($roundedNumbers.Tasks.ContainsKey($taskId)) {
            $task.Title = $roundedNumbers.Tasks[$taskId].Title
            $task.Status = $roundedNumbers.Tasks[$taskId].Status
            $task.LineNumber = $roundedNumbers.Tasks[$taskId].LineNumber
            $task.RoundedValueAttributes.TaggedRoundingRules = $roundedNumbers.Tasks[$taskId].RoundedValues.TaggedRoundingRules
            $task.RoundedValueAttributes.RoundedNumbers = $roundedNumbers.Tasks[$taskId].RoundedValues.RoundedNumbers
        }
        
        $analysis.Tasks[$taskId] = $task
    }
    
    # Calculer les statistiques
    $analysis.Stats.TotalTasks = $allTaskIds.Count
    $analysis.Stats.TasksWithTaggedRoundingRules = ($analysis.Tasks.Values | Where-Object { $_.RoundedValueAttributes.TaggedRoundingRules.Count -gt 0 }).Count
    $analysis.Stats.TasksWithRoundedNumbers = ($analysis.Tasks.Values | Where-Object { $_.RoundedValueAttributes.RoundedNumbers.Count -gt 0 }).Count
    
    # Formater les résultats selon le format demandé
    $output = Format-RoundedValuesOutput -Analysis $analysis -Format $OutputFormat
    
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
function Format-RoundedValuesOutput {
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
            $markdown = "# Analyse des nombres avec règles d'arrondi et de troncature`n`n"
            
            $markdown += "## Statistiques`n`n"
            $markdown += "- Nombre total de tâches: $($Analysis.Stats.TotalTasks)`n"
            $markdown += "- Tâches avec tags de règle d'arrondi: $($Analysis.Stats.TasksWithTaggedRoundingRules)`n"
            $markdown += "- Tâches avec nombres arrondis: $($Analysis.Stats.TasksWithRoundedNumbers)`n`n"
            
            $markdown += "## Tâches avec nombres arrondis`n`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                $hasRoundedValueAttributes = $task.RoundedValueAttributes.TaggedRoundingRules.Count -gt 0 -or 
                                           $task.RoundedValueAttributes.RoundedNumbers.Count -gt 0
                
                if ($hasRoundedValueAttributes) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"
                    
                    if ($task.RoundedValueAttributes.TaggedRoundingRules.Count -gt 0) {
                        $markdown += "- Tags de règle d'arrondi:`n"
                        foreach ($tag in $task.RoundedValueAttributes.TaggedRoundingRules) {
                            $markdown += "  - Règle: $($tag.Rule), Précision: $($tag.Precision) (original: $($tag.Original))`n"
                        }
                    }
                    
                    if ($task.RoundedValueAttributes.RoundedNumbers.Count -gt 0) {
                        $markdown += "- Nombres arrondis:`n"
                        foreach ($number in $task.RoundedValueAttributes.RoundedNumbers) {
                            $markdown += "  - $($number.Value) (original: $($number.Original), règle: $($number.RoundingRule), précision: $($number.Precision))`n"
                        }
                    }
                    
                    $markdown += "`n"
                }
            }
            
            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,TaggedRoundingRules,RoundedNumbers`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                
                $taggedRoundingRules = ""
                if ($task.RoundedValueAttributes.TaggedRoundingRules.Count -gt 0) {
                    $taggedRoundingRules = ($task.RoundedValueAttributes.TaggedRoundingRules | ForEach-Object { "Règle: $($_.Rule), Précision: $($_.Precision) (original: $($_.Original))" }) -join '; '
                }
                
                $roundedNumbers = ""
                if ($task.RoundedValueAttributes.RoundedNumbers.Count -gt 0) {
                    $roundedNumbers = ($task.RoundedValueAttributes.RoundedNumbers | ForEach-Object { "$($_.Value) (original: $($_.Original), règle: $($_.RoundingRule), précision: $($_.Precision))" }) -join '; '
                }
                
                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'
                
                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$taggedRoundingRules`",`"$roundedNumbers`"`n"
            }
            
            return $csv
        }
    }
}

# Exécuter la fonction principale avec les paramètres fournis
Get-RoundedValues -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat -DefaultRoundingRule $DefaultRoundingRule -DefaultPrecision $DefaultPrecision

