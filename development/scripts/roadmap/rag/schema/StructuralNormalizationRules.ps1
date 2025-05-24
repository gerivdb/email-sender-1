# StructuralNormalizationRules.ps1
# Script définissant les règles de normalisation structurelle pour les tâches de roadmap
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Définit les règles de normalisation structurelle pour les tâches de roadmap.

.DESCRIPTION
    Ce script définit les règles de normalisation structurelle pour les tâches de roadmap,
    notamment la standardisation des formats de dates, la normalisation des références et identifiants,
    et les règles de fusion de données.

.NOTES
    Auteur: Équipe DevOps
    Date: 2025-05-15
    Version: 1.0
#>

# Structure définissant les règles de normalisation structurelle
$script:StructuralNormalizationRules = @{
    # Règles de standardisation des formats de dates et durées
    Dates = @{
        # Normalisation des dates au format ISO 8601
        ISO8601 = {
            param($date)
            if ($null -eq $date -or [string]::IsNullOrWhiteSpace($date)) { return $null }
            
            try {
                $dateObj = $null
                
                # Essayer de parser la date
                if ($date -is [datetime]) {
                    $dateObj = $date
                }
                elseif ($date -is [string]) {
                    $dateObj = [datetime]::Parse($date)
                }
                else {
                    return $null
                }
                
                # Convertir en UTC et formater en ISO 8601
                return $dateObj.ToUniversalTime().ToString("o")
            }
            catch {
                Write-Warning "Impossible de normaliser la date '$date': $_"
                return $null
            }
        }
        
        # Normalisation des durées en heures
        Hours = {
            param($duration)
            if ($null -eq $duration) { return 0 }
            
            try {
                # Si c'est déjà un nombre, le convertir en double
                if ($duration -is [int] -or $duration -is [double]) {
                    return [double]$duration
                }
                
                # Si c'est une chaîne, essayer de la parser
                if ($duration -is [string]) {
                    # Vérifier si la chaîne contient des unités
                    if ($duration -match '(\d+(\.\d+)?)\s*(h|hour|hours)') {
                        return [double]$matches[1]
                    }
                    elseif ($duration -match '(\d+(\.\d+)?)\s*(d|day|days)') {
                        return [double]$matches[1] * 8  # 1 jour = 8 heures
                    }
                    elseif ($duration -match '(\d+(\.\d+)?)\s*(w|week|weeks)') {
                        return [double]$matches[1] * 40  # 1 semaine = 40 heures
                    }
                    elseif ($duration -match '(\d+(\.\d+)?)\s*(m|min|minute|minutes)') {
                        return [double]$matches[1] / 60  # Convertir les minutes en heures
                    }
                    else {
                        # Essayer de convertir directement en nombre
                        return [double]$duration
                    }
                }
                
                # Si on ne peut pas convertir, retourner 0
                return 0
            }
            catch {
                Write-Warning "Impossible de normaliser la durée '$duration': $_"
                return 0
            }
        }
    }
    
    # Règles de normalisation des références et identifiants
    References = @{
        # Normalisation des identifiants de tâches
        TaskId = {
            param($id)
            if ($null -eq $id -or [string]::IsNullOrWhiteSpace($id)) { return $null }
            
            # Supprimer les espaces et caractères non numériques/points
            $normalizedId = $id -replace '[^0-9\.]', ''
            
            # Vérifier si l'ID est au format correct (X.Y.Z)
            if ($normalizedId -match '^\d+(\.\d+)*$') {
                return $normalizedId
            }
            else {
                Write-Warning "L'identifiant '$id' n'est pas au format valide (X.Y.Z)."
                return $id
            }
        }
        
        # Normalisation des références entre tâches
        TaskReference = {
            param($reference)
            if ($null -eq $reference) { return @() }
            
            # Si c'est déjà un tableau, normaliser chaque élément
            if ($reference -is [array]) {
                $normalizedReferences = @()
                
                foreach ($ref in $reference) {
                    if ($null -ne $ref -and -not [string]::IsNullOrWhiteSpace($ref)) {
                        $normalizedRef = $ref -replace '[^0-9\.]', ''
                        
                        if ($normalizedRef -match '^\d+(\.\d+)*$') {
                            $normalizedReferences += $normalizedRef
                        }
                        else {
                            Write-Warning "La référence '$ref' n'est pas au format valide (X.Y.Z)."
                        }
                    }
                }
                
                # Supprimer les doublons
                return $normalizedReferences | Select-Object -Unique
            }
            
            # Si c'est une chaîne, essayer de la parser comme une liste séparée par des virgules
            if ($reference -is [string]) {
                $refs = $reference -split '[,;]'
                $normalizedReferences = @()
                
                foreach ($ref in $refs) {
                    $normalizedRef = $ref.Trim() -replace '[^0-9\.]', ''
                    
                    if ($normalizedRef -match '^\d+(\.\d+)*$') {
                        $normalizedReferences += $normalizedRef
                    }
                    else {
                        Write-Warning "La référence '$ref' n'est pas au format valide (X.Y.Z)."
                    }
                }
                
                # Supprimer les doublons
                return $normalizedReferences | Select-Object -Unique
            }
            
            # Si on ne peut pas normaliser, retourner un tableau vide
            return @()
        }
    }
    
    # Règles de fusion de données
    Merge = @{
        # Fusion de tâches
        Tasks = {
            param($task1, $task2, $preferTask1 = $true)
            if ($null -eq $task1) { return $task2 }
            if ($null -eq $task2) { return $task1 }
            
            $mergedTask = @{}
            
            # Fusionner les propriétés
            $allProperties = @($task1.PSObject.Properties.Name) + @($task2.PSObject.Properties.Name) | Select-Object -Unique
            
            foreach ($property in $allProperties) {
                $value1 = if ($task1.PSObject.Properties.Name -contains $property) { $task1.$property } else { $null }
                $value2 = if ($task2.PSObject.Properties.Name -contains $property) { $task2.$property } else { $null }
                
                # Déterminer la valeur à utiliser
                if ($null -eq $value1) {
                    $mergedTask[$property] = $value2
                }
                elseif ($null -eq $value2) {
                    $mergedTask[$property] = $value1
                }
                else {
                    # Les deux valeurs existent, appliquer la logique de fusion
                    switch ($property) {
                        # Pour les tableaux, fusionner et supprimer les doublons
                        { $_ -in @("tags", "dependencies", "subTasks", "assignees") } {
                            if ($value1 -is [array] -and $value2 -is [array]) {
                                $mergedTask[$property] = @($value1) + @($value2) | Select-Object -Unique
                            }
                            elseif ($value1 -is [array]) {
                                $mergedTask[$property] = $value1
                            }
                            elseif ($value2 -is [array]) {
                                $mergedTask[$property] = $value2
                            }
                            else {
                                $mergedTask[$property] = if ($preferTask1) { $value1 } else { $value2 }
                            }
                        }
                        
                        # Pour les dates, prendre la plus récente
                        { $_ -in @("updatedAt") } {
                            try {
                                $date1 = [datetime]::Parse($value1)
                                $date2 = [datetime]::Parse($value2)
                                $mergedTask[$property] = if ($date1 -gt $date2) { $value1 } else { $value2 }
                            }
                            catch {
                                $mergedTask[$property] = if ($preferTask1) { $value1 } else { $value2 }
                            }
                        }
                        
                        # Pour les dates de création, prendre la plus ancienne
                        { $_ -in @("createdAt") } {
                            try {
                                $date1 = [datetime]::Parse($value1)
                                $date2 = [datetime]::Parse($value2)
                                $mergedTask[$property] = if ($date1 -lt $date2) { $value1 } else { $value2 }
                            }
                            catch {
                                $mergedTask[$property] = if ($preferTask1) { $value1 } else { $value2 }
                            }
                        }
                        
                        # Pour les descriptions, concaténer si différentes
                        "description" {
                            if ($value1 -ne $value2) {
                                if ([string]::IsNullOrWhiteSpace($value1)) {
                                    $mergedTask[$property] = $value2
                                }
                                elseif ([string]::IsNullOrWhiteSpace($value2)) {
                                    $mergedTask[$property] = $value1
                                }
                                else {
                                    $mergedTask[$property] = "$value1`n`n$value2"
                                }
                            }
                            else {
                                $mergedTask[$property] = $value1
                            }
                        }
                        
                        # Pour les autres propriétés, préférer task1 ou task2 selon le paramètre
                        default {
                            $mergedTask[$property] = if ($preferTask1) { $value1 } else { $value2 }
                        }
                    }
                }
            }
            
            return [PSCustomObject]$mergedTask
        }
    }
}

# Fonction pour normaliser les dates
function ConvertTo-Date {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Date,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("ISO8601")]
        [string]$Format = "ISO8601"
    )
    
    switch ($Format) {
        "ISO8601" {
            return & $script:StructuralNormalizationRules.Dates.ISO8601 $Date
        }
        default {
            return & $script:StructuralNormalizationRules.Dates.ISO8601 $Date
        }
    }
}

# Fonction pour normaliser les durées
function ConvertTo-Duration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Duration,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Hours")]
        [string]$Unit = "Hours"
    )
    
    switch ($Unit) {
        "Hours" {
            return & $script:StructuralNormalizationRules.Dates.Hours $Duration
        }
        default {
            return & $script:StructuralNormalizationRules.Dates.Hours $Duration
        }
    }
}

# Fonction pour normaliser les références
function ConvertTo-Reference {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Reference,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("TaskId", "TaskReference")]
        [string]$Type = "TaskId"
    )
    
    switch ($Type) {
        "TaskId" {
            return & $script:StructuralNormalizationRules.References.TaskId $Reference
        }
        "TaskReference" {
            return & $script:StructuralNormalizationRules.References.TaskReference $Reference
        }
        default {
            return & $script:StructuralNormalizationRules.References.TaskId $Reference
        }
    }
}

# Fonction pour fusionner des tâches
function Merge-Tasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Task1,
        
        [Parameter(Mandatory = $true)]
        [object]$Task2,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreferTask1 = $true
    )
    
    return & $script:StructuralNormalizationRules.Merge.Tasks $Task1 $Task2 $PreferTask1
}

# Fonction pour normaliser structurellement une tâche complète
function ConvertTo-TaskStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$Task
    )
    
    process {
        # Normaliser les champs de date
        if ($Task.PSObject.Properties.Name.Contains("createdAt")) {
            $Task.createdAt = ConvertTo-Date -Date $Task.createdAt
        }
        
        if ($Task.PSObject.Properties.Name.Contains("updatedAt")) {
            $Task.updatedAt = ConvertTo-Date -Date $Task.updatedAt
        }
        
        if ($Task.PSObject.Properties.Name.Contains("dueDate")) {
            $Task.dueDate = ConvertTo-Date -Date $Task.dueDate
        }
        
        if ($Task.PSObject.Properties.Name.Contains("startDate")) {
            $Task.startDate = ConvertTo-Date -Date $Task.startDate
        }
        
        if ($Task.PSObject.Properties.Name.Contains("completionDate")) {
            $Task.completionDate = ConvertTo-Date -Date $Task.completionDate
        }
        
        # Normaliser les durées
        if ($Task.PSObject.Properties.Name.Contains("estimatedHours")) {
            $Task.estimatedHours = ConvertTo-Duration -Duration $Task.estimatedHours
        }
        
        # Normaliser les références
        if ($Task.PSObject.Properties.Name.Contains("id")) {
            $Task.id = ConvertTo-Reference -Reference $Task.id -Type "TaskId"
        }
        
        if ($Task.PSObject.Properties.Name.Contains("parentId")) {
            $Task.parentId = ConvertTo-Reference -Reference $Task.parentId -Type "TaskId"
        }
        
        if ($Task.PSObject.Properties.Name.Contains("dependencies")) {
            $Task.dependencies = ConvertTo-Reference -Reference $Task.dependencies -Type "TaskReference"
        }
        
        if ($Task.PSObject.Properties.Name.Contains("subTasks")) {
            $Task.subTasks = ConvertTo-Reference -Reference $Task.subTasks -Type "TaskReference"
        }
        
        return $Task
    }
}

# Exporter les fonctions
Export-ModuleMember -function ConvertTo-Date, ConvertTo-Duration, ConvertTo-Reference, Merge-Tasks, ConvertTo-TaskStructure

