# Normalize-TaskFields.ps1
# Script pour normaliser les champs des tâches de roadmap
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Normalise les champs des tâches de roadmap selon les règles définies.

.DESCRIPTION
    Ce script fournit des fonctions pour normaliser les champs des tâches de roadmap
    selon les règles définies dans le schéma. La normalisation inclut la standardisation
    des formats de dates, la normalisation des chaînes de caractères, etc.

.PARAMETER Task
    L'objet tâche à normaliser.

.PARAMETER FieldsToNormalize
    Liste des champs à normaliser. Si non spécifié, tous les champs seront normalisés.

.EXAMPLE
    $task = @{
        id = "1.2.3"
        title = "  Implémenter la validation de schéma  "
        status = "inprogress"
        createdAt = "2025-05-15T10:00:00"
        updatedAt = "2025-05-15T10:00:00"
    }
    
    Normalize-TaskFields -Task $task

.NOTES
    Auteur: Équipe DevOps
    Date: 2025-05-15
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [object]$Task,
    
    [Parameter(Mandatory = $false)]
    [string[]]$FieldsToNormalize
)

begin {
    # Importer le module de définition des champs
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $taskFieldDefinitionsPath = Join-Path -Path $scriptPath -ChildPath "TaskFieldDefinitions.ps1"
    
    if (-not (Test-Path -Path $taskFieldDefinitionsPath)) {
        Write-Error "Le fichier TaskFieldDefinitions.ps1 est introuvable."
        exit 1
    }
    
    . $taskFieldDefinitionsPath
    
    # Définir les règles de normalisation pour chaque type de champ
    $normalizationRules = @{
        # Normalisation des chaînes de caractères
        String = {
            param($value)
            if ($null -eq $value) { return $null }
            return $value.Trim()
        }
        
        # Normalisation des identifiants
        Id = {
            param($value)
            if ($null -eq $value) { return $null }
            return $value.Trim()
        }
        
        # Normalisation des statuts
        Status = {
            param($value)
            if ($null -eq $value) { return "NotStarted" }
            
            switch ($value.ToLower()) {
                "notstarted" { return "NotStarted" }
                "not started" { return "NotStarted" }
                "todo" { return "NotStarted" }
                "to do" { return "NotStarted" }
                "new" { return "NotStarted" }
                
                "inprogress" { return "InProgress" }
                "in progress" { return "InProgress" }
                "in-progress" { return "InProgress" }
                "started" { return "InProgress" }
                "ongoing" { return "InProgress" }
                "wip" { return "InProgress" }
                
                "completed" { return "Completed" }
                "complete" { return "Completed" }
                "done" { return "Completed" }
                "finished" { return "Completed" }
                
                "blocked" { return "Blocked" }
                "block" { return "Blocked" }
                "stuck" { return "Blocked" }
                "impediment" { return "Blocked" }
                
                default { return "NotStarted" }
            }
        }
        
        # Normalisation des priorités
        Priority = {
            param($value)
            if ($null -eq $value) { return "Medium" }
            
            switch ($value.ToLower()) {
                "low" { return "Low" }
                "l" { return "Low" }
                "minor" { return "Low" }
                "trivial" { return "Low" }
                
                "medium" { return "Medium" }
                "m" { return "Medium" }
                "normal" { return "Medium" }
                "standard" { return "Medium" }
                
                "high" { return "High" }
                "h" { return "High" }
                "important" { return "High" }
                "major" { return "High" }
                
                "critical" { return "Critical" }
                "c" { return "Critical" }
                "urgent" { return "Critical" }
                "blocker" { return "Critical" }
                
                default { return "Medium" }
            }
        }
        
        # Normalisation des dates
        DateTime = {
            param($value)
            if ($null -eq $value) { return $null }
            
            try {
                $date = [datetime]::Parse($value)
                return $date.ToUniversalTime().ToString("o")
            }
            catch {
                Write-Warning "Impossible de parser la date '$value'. Utilisation de la valeur telle quelle."
                return $value
            }
        }
        
        # Normalisation des nombres
        Number = {
            param($value)
            if ($null -eq $value) { return 0 }
            
            try {
                return [double]$value
            }
            catch {
                Write-Warning "Impossible de convertir '$value' en nombre. Utilisation de 0."
                return 0
            }
        }
        
        # Normalisation des entiers
        Integer = {
            param($value)
            if ($null -eq $value) { return 0 }
            
            try {
                return [int]$value
            }
            catch {
                Write-Warning "Impossible de convertir '$value' en entier. Utilisation de 0."
                return 0
            }
        }
        
        # Normalisation des booléens
        Boolean = {
            param($value)
            if ($null -eq $value) { return $false }
            
            if ($value -is [bool]) {
                return $value
            }
            
            if ($value -is [string]) {
                switch ($value.ToLower()) {
                    "true" { return $true }
                    "yes" { return $true }
                    "y" { return $true }
                    "1" { return $true }
                    
                    "false" { return $false }
                    "no" { return $false }
                    "n" { return $false }
                    "0" { return $false }
                    
                    default { return $false }
                }
            }
            
            return [bool]$value
        }
        
        # Normalisation des tableaux
        Array = {
            param($value)
            if ($null -eq $value) { return @() }
            
            if ($value -is [array]) {
                return $value
            }
            
            if ($value -is [string]) {
                if ([string]::IsNullOrWhiteSpace($value)) {
                    return @()
                }
                
                # Essayer de diviser la chaîne par des virgules
                return $value.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            }
            
            return @($value)
        }
    }
}

process {
    # Obtenir tous les champs
    $allFields = Get-AllTaskFields
    
    # Filtrer les champs à normaliser si spécifié
    if ($FieldsToNormalize) {
        $fieldsToProcess = @{}
        foreach ($fieldName in $FieldsToNormalize) {
            $found = $false
            foreach ($key in $allFields.Keys) {
                if ($allFields[$key].Name -eq $fieldName) {
                    $fieldsToProcess[$key] = $allFields[$key]
                    $found = $true
                    break
                }
            }
            
            if (-not $found) {
                Write-Warning "Le champ '$fieldName' n'est pas un champ valide."
            }
        }
    }
    else {
        $fieldsToProcess = $allFields
    }
    
    # Normaliser les champs
    foreach ($fieldKey in $fieldsToProcess.Keys) {
        $field = $fieldsToProcess[$fieldKey]
        $fieldName = $field.Name
        
        # Vérifier si le champ existe
        if (-not $Task.PSObject.Properties.Name.Contains($fieldName)) {
            continue
        }
        
        # Obtenir la valeur actuelle
        $value = $Task.$fieldName
        
        # Déterminer la règle de normalisation à appliquer
        $normalizationRule = $null
        
        # Règles spécifiques pour certains champs
        switch ($fieldName) {
            "id" { $normalizationRule = $normalizationRules.Id }
            "status" { $normalizationRule = $normalizationRules.Status }
            "priority" { $normalizationRule = $normalizationRules.Priority }
            default {
                # Règles basées sur le type
                switch ($field.Type) {
                    "string" {
                        if ($field.Format -eq "date-time") {
                            $normalizationRule = $normalizationRules.DateTime
                        }
                        else {
                            $normalizationRule = $normalizationRules.String
                        }
                    }
                    "number" { $normalizationRule = $normalizationRules.Number }
                    "integer" { $normalizationRule = $normalizationRules.Integer }
                    "boolean" { $normalizationRule = $normalizationRules.Boolean }
                    "array" { $normalizationRule = $normalizationRules.Array }
                    default { $normalizationRule = $normalizationRules.String }
                }
            }
        }
        
        # Appliquer la règle de normalisation
        if ($null -ne $normalizationRule) {
            $normalizedValue = & $normalizationRule $value
            
            # Mettre à jour la valeur
            if ($Task -is [PSCustomObject]) {
                $Task.$fieldName = $normalizedValue
            }
            elseif ($Task -is [hashtable]) {
                $Task[$fieldName] = $normalizedValue
            }
        }
    }
    
    return $Task
}

end {
    # Rien à faire ici
}

# Exporter la fonction
Export-ModuleMember -Function Normalize-TaskFields
