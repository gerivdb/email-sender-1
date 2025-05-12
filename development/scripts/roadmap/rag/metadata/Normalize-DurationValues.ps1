# Normalize-DurationValues.ps1
# Script pour normaliser les durées en format standard
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
    [ValidateSet("JSON", "Markdown", "CSV", "Text")]
    [string]$OutputFormat = "JSON",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Hours", "Days", "Weeks", "Months")]
    [string]$StandardUnit = "Hours"
)

# Fonction pour convertir une durée vers une unité standard
function Convert-ToStandardUnit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$Value,
        
        [Parameter(Mandatory = $true)]
        [string]$SourceUnit,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Hours", "Days", "Weeks", "Months")]
        [string]$TargetUnit = "Hours"
    )
    
    # Convertir d'abord en heures (unité de base)
    $hoursValue = switch -Regex ($SourceUnit) {
        '^minutes?$' { $Value / 60 }
        '^heures?$' { $Value }
        '^jours?$' { $Value * 8 }  # 8 heures par jour
        '^semaines?$' { $Value * 40 }  # 40 heures par semaine (5 jours * 8 heures)
        '^mois$' { $Value * 160 }  # 160 heures par mois (4 semaines * 40 heures)
        '^années?$' { $Value * 1920 }  # 1920 heures par année (12 mois * 160 heures)
        default { $Value }  # Par défaut, on suppose que c'est déjà en heures
    }
    
    # Convertir des heures vers l'unité cible
    $result = switch ($TargetUnit) {
        'Minutes' { $hoursValue * 60 }
        'Hours' { $hoursValue }
        'Days' { $hoursValue / 8 }
        'Weeks' { $hoursValue / 40 }
        'Months' { $hoursValue / 160 }
        default { $hoursValue }  # Par défaut, on retourne en heures
    }
    
    return $result
}

# Fonction pour normaliser une liste de durées
function Normalize-Durations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Durations,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Hours", "Days", "Weeks", "Months")]
        [string]$StandardUnit = "Hours"
    )
    
    $normalizedDurations = @()
    
    foreach ($duration in $Durations) {
        # Vérifier si la durée a une valeur et une unité
        if ($null -ne $duration.Value -and $null -ne $duration.Unit) {
            $normalizedValue = Convert-ToStandardUnit -Value $duration.Value -SourceUnit $duration.Unit -TargetUnit $StandardUnit
            
            # Créer un nouvel objet avec la valeur normalisée
            $normalizedDuration = [PSCustomObject]@{
                OriginalValue = $duration.Value
                OriginalUnit = $duration.Unit
                NormalizedValue = $normalizedValue
                StandardUnit = $StandardUnit
                Source = $duration.Source
                Type = $duration.Type
                Confidence = $duration.Confidence
            }
            
            $normalizedDurations += $normalizedDuration
        }
    }
    
    return $normalizedDurations
}

# Fonction pour normaliser les durées extraites d'un fichier ou d'un contenu
function Normalize-ExtractedDurations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$Content,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Hours", "Days", "Weeks", "Months")]
        [string]$StandardUnit = "Hours"
    )
    
    # Charger le contenu si un chemin de fichier est spécifié
    if (-not [string]::IsNullOrEmpty($FilePath)) {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Error "Le fichier spécifié n'existe pas: $FilePath"
            return $null
        }
        
        $Content = Get-Content -Path $FilePath -Raw
    }
    
    # Extraire les durées
    $extractDurationScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Extract-DurationAttributes.ps1"
    $extractActualDurationScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Extract-ActualDurationValues.ps1"
    
    if (-not (Test-Path -Path $extractDurationScriptPath)) {
        Write-Error "Le script d'extraction des durées n'existe pas: $extractDurationScriptPath"
        return $null
    }
    
    if (-not (Test-Path -Path $extractActualDurationScriptPath)) {
        Write-Error "Le script d'extraction des durées réelles n'existe pas: $extractActualDurationScriptPath"
        return $null
    }
    
    # Extraire les durées estimées
    $estimatedDurationsJson = & $extractDurationScriptPath -Content $Content -OutputFormat "JSON"
    $estimatedDurations = $estimatedDurationsJson | ConvertFrom-Json
    
    # Extraire les durées réelles
    $actualDurationsJson = & $extractActualDurationScriptPath -Content $Content -OutputFormat "JSON"
    $actualDurations = $actualDurationsJson | ConvertFrom-Json
    
    # Normaliser les durées estimées
    $normalizedEstimatedDurations = @{}
    
    if ($null -ne $estimatedDurations.DayWeekMonthDurations) {
        foreach ($taskId in $estimatedDurations.DayWeekMonthDurations.PSObject.Properties.Name) {
            $durations = $estimatedDurations.DayWeekMonthDurations.$taskId
            $normalizedDurations = Normalize-Durations -Durations $durations -StandardUnit $StandardUnit
            $normalizedEstimatedDurations[$taskId] = $normalizedDurations
        }
    }
    
    if ($null -ne $estimatedDurations.HourMinuteDurations) {
        foreach ($taskId in $estimatedDurations.HourMinuteDurations.PSObject.Properties.Name) {
            $durations = $estimatedDurations.HourMinuteDurations.$taskId
            $normalizedDurations = Normalize-Durations -Durations $durations -StandardUnit $StandardUnit
            
            if ($normalizedEstimatedDurations.ContainsKey($taskId)) {
                $normalizedEstimatedDurations[$taskId] += $normalizedDurations
            }
            else {
                $normalizedEstimatedDurations[$taskId] = $normalizedDurations
            }
        }
    }
    
    if ($null -ne $estimatedDurations.CompositeDurations) {
        foreach ($taskId in $estimatedDurations.CompositeDurations.PSObject.Properties.Name) {
            $durations = $estimatedDurations.CompositeDurations.$taskId
            $normalizedDurations = Normalize-Durations -Durations $durations -StandardUnit $StandardUnit
            
            if ($normalizedEstimatedDurations.ContainsKey($taskId)) {
                $normalizedEstimatedDurations[$taskId] += $normalizedDurations
            }
            else {
                $normalizedEstimatedDurations[$taskId] = $normalizedDurations
            }
        }
    }
    
    # Normaliser les durées réelles
    $normalizedActualDurations = @{}
    
    if ($null -ne $actualDurations.Tasks) {
        foreach ($taskId in $actualDurations.Tasks.PSObject.Properties.Name) {
            $task = $actualDurations.Tasks.$taskId
            $allDurations = @()
            
            if ($null -ne $task.ActualDurations.Explicit) {
                $allDurations += $task.ActualDurations.Explicit
            }
            
            if ($null -ne $task.ActualDurations.Tags) {
                $allDurations += $task.ActualDurations.Tags
            }
            
            if ($null -ne $task.ActualDurations.Calculated) {
                $allDurations += $task.ActualDurations.Calculated
            }
            
            if ($allDurations.Count -gt 0) {
                $normalizedDurations = Normalize-Durations -Durations $allDurations -StandardUnit $StandardUnit
                $normalizedActualDurations[$taskId] = $normalizedDurations
            }
        }
    }
    
    # Créer l'objet de résultat
    $result = [PSCustomObject]@{
        NormalizedEstimatedDurations = $normalizedEstimatedDurations
        NormalizedActualDurations = $normalizedActualDurations
        StandardUnit = $StandardUnit
        Stats = [PSCustomObject]@{
            TasksWithNormalizedEstimatedDurations = $normalizedEstimatedDurations.Count
            TasksWithNormalizedActualDurations = $normalizedActualDurations.Count
        }
    }
    
    return $result
}

# Fonction principale pour normaliser les durées
function Normalize-DurationValues {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$Content,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "Markdown", "CSV", "Text")]
        [string]$OutputFormat = "JSON",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Hours", "Days", "Weeks", "Months")]
        [string]$StandardUnit = "Hours"
    )
    
    # Normaliser les durées
    $normalizedDurations = Normalize-ExtractedDurations -FilePath $FilePath -Content $Content -StandardUnit $StandardUnit
    
    # Formater la sortie selon le format demandé
    switch ($OutputFormat) {
        "JSON" {
            $output = $normalizedDurations | ConvertTo-Json -Depth 10
        }
        "Markdown" {
            $output = "# Durées normalisées`n`n"
            $output += "## Statistiques`n`n"
            $output += "- Tâches avec durées estimées normalisées: $($normalizedDurations.Stats.TasksWithNormalizedEstimatedDurations)`n"
            $output += "- Tâches avec durées réelles normalisées: $($normalizedDurations.Stats.TasksWithNormalizedActualDurations)`n"
            $output += "- Unité standard: $($normalizedDurations.StandardUnit)`n`n"
            
            $output += "## Durées estimées normalisées`n`n"
            foreach ($taskId in $normalizedDurations.NormalizedEstimatedDurations.Keys) {
                $durations = $normalizedDurations.NormalizedEstimatedDurations[$taskId]
                $output += "### Tâche $($taskId)`n`n"
                
                foreach ($duration in $durations) {
                    $output += "- Original: $($duration.OriginalValue) $($duration.OriginalUnit) → Normalisé: $($duration.NormalizedValue.ToString('F2')) $($duration.StandardUnit) (Source: $($duration.Source), Type: $($duration.Type))`n"
                }
                
                $output += "`n"
            }
            
            $output += "## Durées réelles normalisées`n`n"
            foreach ($taskId in $normalizedDurations.NormalizedActualDurations.Keys) {
                $durations = $normalizedDurations.NormalizedActualDurations[$taskId]
                $output += "### Tâche $($taskId)`n`n"
                
                foreach ($duration in $durations) {
                    $output += "- Original: $($duration.OriginalValue) $($duration.OriginalUnit) → Normalisé: $($duration.NormalizedValue.ToString('F2')) $($duration.StandardUnit) (Source: $($duration.Source), Type: $($duration.Type))`n"
                }
                
                $output += "`n"
            }
        }
        "CSV" {
            $output = "TaskId,DurationType,OriginalValue,OriginalUnit,NormalizedValue,StandardUnit,Source,Type`n"
            
            foreach ($taskId in $normalizedDurations.NormalizedEstimatedDurations.Keys) {
                $durations = $normalizedDurations.NormalizedEstimatedDurations[$taskId]
                
                foreach ($duration in $durations) {
                    $output += "$taskId,Estimated,$($duration.OriginalValue),$($duration.OriginalUnit),$($duration.NormalizedValue.ToString('F2')),$($duration.StandardUnit),$($duration.Source),$($duration.Type)`n"
                }
            }
            
            foreach ($taskId in $normalizedDurations.NormalizedActualDurations.Keys) {
                $durations = $normalizedDurations.NormalizedActualDurations[$taskId]
                
                foreach ($duration in $durations) {
                    $output += "$taskId,Actual,$($duration.OriginalValue),$($duration.OriginalUnit),$($duration.NormalizedValue.ToString('F2')),$($duration.StandardUnit),$($duration.Source),$($duration.Type)`n"
                }
            }
        }
        "Text" {
            $output = "Durées normalisées`n`n"
            $output += "Statistiques:`n"
            $output += "  Tâches avec durées estimées normalisées: $($normalizedDurations.Stats.TasksWithNormalizedEstimatedDurations)`n"
            $output += "  Tâches avec durées réelles normalisées: $($normalizedDurations.Stats.TasksWithNormalizedActualDurations)`n"
            $output += "  Unité standard: $($normalizedDurations.StandardUnit)`n`n"
            
            $output += "Durées estimées normalisées:`n`n"
            foreach ($taskId in $normalizedDurations.NormalizedEstimatedDurations.Keys) {
                $durations = $normalizedDurations.NormalizedEstimatedDurations[$taskId]
                $output += "Tâche $($taskId):`n"
                
                foreach ($duration in $durations) {
                    $output += "  - Original: $($duration.OriginalValue) $($duration.OriginalUnit) → Normalisé: $($duration.NormalizedValue.ToString('F2')) $($duration.StandardUnit) (Source: $($duration.Source), Type: $($duration.Type))`n"
                }
                
                $output += "`n"
            }
            
            $output += "Durées réelles normalisées:`n`n"
            foreach ($taskId in $normalizedDurations.NormalizedActualDurations.Keys) {
                $durations = $normalizedDurations.NormalizedActualDurations[$taskId]
                $output += "Tâche $($taskId):`n"
                
                foreach ($duration in $durations) {
                    $output += "  - Original: $($duration.OriginalValue) $($duration.OriginalUnit) → Normalisé: $($duration.NormalizedValue.ToString('F2')) $($duration.StandardUnit) (Source: $($duration.Source), Type: $($duration.Type))`n"
                }
                
                $output += "`n"
            }
        }
    }
    
    # Sauvegarder la sortie si un chemin est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $output | Out-File -FilePath $OutputPath -Encoding utf8
    }
    
    return $output
}

# Exécuter la fonction principale avec les paramètres fournis
Normalize-DurationValues -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat -StandardUnit $StandardUnit
