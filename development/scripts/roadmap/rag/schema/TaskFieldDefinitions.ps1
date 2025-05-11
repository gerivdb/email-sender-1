# TaskFieldDefinitions.ps1
# Script définissant les champs obligatoires et optionnels pour les tâches de roadmap
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Définit les champs obligatoires et optionnels pour les tâches de roadmap dans le système RAG.

.DESCRIPTION
    Ce script définit les structures de données pour les champs des tâches de roadmap,
    en spécifiant quels champs sont obligatoires et lesquels sont optionnels.
    Il inclut également les règles de validation, les valeurs par défaut et les descriptions
    pour chaque champ.

.NOTES
    Auteur: Équipe DevOps
    Date: 2025-05-15
    Version: 1.0
#>

# Structure définissant les champs obligatoires pour les tâches
$script:RequiredTaskFields = @{
    # Identifiant unique de la tâche
    Id = @{
        Name = "id"
        Type = "string"
        Description = "Identifiant unique de la tâche, suivant le format de numérotation hiérarchique (ex: 1.1.2.3)"
        Pattern = "^\d+(\.\d+)*$"
        Validators = @(
            {
                param($value)
                return $value -match "^\d+(\.\d+)*$"
            }
        )
    }

    # Titre de la tâche
    Title = @{
        Name = "title"
        Type = "string"
        Description = "Titre de la tâche"
        MinLength = 1
        MaxLength = 200
        Validators = @(
            {
                param($value)
                return -not [string]::IsNullOrWhiteSpace($value) -and $value.Length -le 200
            }
        )
    }

    # Statut de la tâche
    Status = @{
        Name = "status"
        Type = "string"
        Description = "Statut actuel de la tâche"
        AllowedValues = @("NotStarted", "InProgress", "Completed", "Blocked")
        DefaultValue = "NotStarted"
        Validators = @(
            {
                param($value)
                return $value -in @("NotStarted", "InProgress", "Completed", "Blocked")
            }
        )
    }

    # Date de création
    CreatedAt = @{
        Name = "createdAt"
        Type = "string"
        Format = "date-time"
        Description = "Date et heure de création de la tâche (format ISO 8601)"
        DefaultValue = { (Get-Date).ToUniversalTime().ToString("o") }
        Validators = @(
            {
                param($value)
                try {
                    [datetime]::Parse($value) | Out-Null
                    return $true
                }
                catch {
                    return $false
                }
            }
        )
    }

    # Date de dernière mise à jour
    UpdatedAt = @{
        Name = "updatedAt"
        Type = "string"
        Format = "date-time"
        Description = "Date et heure de dernière mise à jour de la tâche (format ISO 8601)"
        DefaultValue = { (Get-Date).ToUniversalTime().ToString("o") }
        Validators = @(
            {
                param($value)
                try {
                    [datetime]::Parse($value) | Out-Null
                    return $true
                }
                catch {
                    return $false
                }
            }
        )
    }
}

# Structure définissant les champs optionnels pour les tâches
$script:OptionalTaskFields = @{
    # Champs d'identification
    ParentId = @{
        Name = "parentId"
        Type = "string"
        Description = "Identifiant de la tâche parente"
        Pattern = "^\d+(\.\d+)*$"
        AllowNull = $true
        DefaultValue = $null
        Validators = @(
            {
                param($value)
                return $null -eq $value -or $value -match "^\d+(\.\d+)*$"
            }
        )
    }

    # Champs de contenu
    Description = @{
        Name = "description"
        Type = "string"
        Description = "Description détaillée de la tâche"
        DefaultValue = ""
        AllowNull = $true
        Validators = @(
            {
                param($value)
                return $true  # Toute valeur est acceptée, y compris null ou chaîne vide
            }
        )
    }

    # Champs de planification
    DueDate = @{
        Name = "dueDate"
        Type = "string"
        Format = "date-time"
        Description = "Date d'échéance prévue (format ISO 8601)"
        AllowNull = $true
        DefaultValue = $null
        Validators = @(
            {
                param($value)
                if ($null -eq $value) { return $true }
                try {
                    [datetime]::Parse($value) | Out-Null
                    return $true
                }
                catch {
                    return $false
                }
            }
        )
    }

    StartDate = @{
        Name = "startDate"
        Type = "string"
        Format = "date-time"
        Description = "Date de début prévue ou réelle (format ISO 8601)"
        AllowNull = $true
        DefaultValue = $null
        Validators = @(
            {
                param($value)
                if ($null -eq $value) { return $true }
                try {
                    [datetime]::Parse($value) | Out-Null
                    return $true
                }
                catch {
                    return $false
                }
            }
        )
    }

    CompletionDate = @{
        Name = "completionDate"
        Type = "string"
        Format = "date-time"
        Description = "Date d'achèvement réelle (format ISO 8601)"
        AllowNull = $true
        DefaultValue = $null
        Validators = @(
            {
                param($value)
                if ($null -eq $value) { return $true }
                try {
                    [datetime]::Parse($value) | Out-Null
                    return $true
                }
                catch {
                    return $false
                }
            }
        )
    }

    # Champs de relations
    Dependencies = @{
        Name = "dependencies"
        Type = "array"
        Description = "Liste des identifiants des tâches dont dépend cette tâche"
        ItemType = "string"
        ItemPattern = "^\d+(\.\d+)*$"
        DefaultValue = @()
        Validators = @(
            {
                param($value)
                if ($null -eq $value) { return $true }
                if (-not ($value -is [array])) { return $false }
                foreach ($item in $value) {
                    if (-not ($item -match "^\d+(\.\d+)*$")) { return $false }
                }
                return $true
            }
        )
    }

    SubTasks = @{
        Name = "subTasks"
        Type = "array"
        Description = "Liste des identifiants des sous-tâches"
        ItemType = "string"
        ItemPattern = "^\d+(\.\d+)*$"
        DefaultValue = @()
        Validators = @(
            {
                param($value)
                if ($null -eq $value) { return $true }
                if (-not ($value -is [array])) { return $false }
                foreach ($item in $value) {
                    if (-not ($item -match "^\d+(\.\d+)*$")) { return $false }
                }
                return $true
            }
        )
    }

    # Champs d'attribution
    Owner = @{
        Name = "owner"
        Type = "string"
        Description = "Personne responsable de la tâche"
        AllowNull = $true
        DefaultValue = $null
        Validators = @(
            {
                param($value)
                return $true  # Toute valeur est acceptée, y compris null ou chaîne vide
            }
        )
    }

    Assignees = @{
        Name = "assignees"
        Type = "array"
        Description = "Liste des personnes assignées à la tâche"
        ItemType = "string"
        DefaultValue = @()
        Validators = @(
            {
                param($value)
                if ($null -eq $value) { return $true }
                return $value -is [array]
            }
        )
    }

    # Champs de statut
    Progress = @{
        Name = "progress"
        Type = "integer"
        Description = "Pourcentage de progression de la tâche (0-100)"
        Minimum = 0
        Maximum = 100
        DefaultValue = 0
        Validators = @(
            {
                param($value)
                if ($null -eq $value) { return $true }
                return $value -is [int] -and $value -ge 0 -and $value -le 100
            }
        )
    }

    Priority = @{
        Name = "priority"
        Type = "string"
        Description = "Priorité de la tâche"
        AllowedValues = @("Low", "Medium", "High", "Critical")
        DefaultValue = "Medium"
        Validators = @(
            {
                param($value)
                if ($null -eq $value) { return $true }
                return $value -in @("Low", "Medium", "High", "Critical")
            }
        )
    }

    Complexity = @{
        Name = "complexity"
        Type = "integer"
        Description = "Niveau de complexité de la tâche (1-5)"
        Minimum = 1
        Maximum = 5
        DefaultValue = 3
        Validators = @(
            {
                param($value)
                if ($null -eq $value) { return $true }
                return $value -is [int] -and $value -ge 1 -and $value -le 5
            }
        )
    }

    # Champs de métadonnées
    Tags = @{
        Name = "tags"
        Type = "array"
        Description = "Liste des tags associés à la tâche"
        ItemType = "string"
        DefaultValue = @()
        Validators = @(
            {
                param($value)
                if ($null -eq $value) { return $true }
                return $value -is [array]
            }
        )
    }

    Category = @{
        Name = "category"
        Type = "string"
        Description = "Catégorie de la tâche"
        AllowNull = $true
        DefaultValue = $null
        Validators = @(
            {
                param($value)
                return $true  # Toute valeur est acceptée, y compris null ou chaîne vide
            }
        )
    }

    EstimatedHours = @{
        Name = "estimatedHours"
        Type = "number"
        Description = "Temps estimé pour compléter la tâche (en heures)"
        Minimum = 0
        DefaultValue = 0
        Validators = @(
            {
                param($value)
                if ($null -eq $value) { return $true }
                return ($value -is [int] -or $value -is [double]) -and $value -ge 0
            }
        )
    }
}

# Fonction pour obtenir tous les champs (obligatoires et optionnels)
function Get-AllTaskFields {
    [CmdletBinding()]
    param()
    
    $allFields = @{}
    
    # Ajouter les champs obligatoires
    foreach ($key in $script:RequiredTaskFields.Keys) {
        $allFields[$key] = $script:RequiredTaskFields[$key]
    }
    
    # Ajouter les champs optionnels
    foreach ($key in $script:OptionalTaskFields.Keys) {
        $allFields[$key] = $script:OptionalTaskFields[$key]
    }
    
    return $allFields
}

# Fonction pour obtenir les champs obligatoires
function Get-RequiredTaskFields {
    [CmdletBinding()]
    param()
    
    return $script:RequiredTaskFields
}

# Fonction pour obtenir les champs optionnels
function Get-OptionalTaskFields {
    [CmdletBinding()]
    param()
    
    return $script:OptionalTaskFields
}

# Fonction pour valider une tâche selon les définitions de champs
function Test-TaskAgainstFieldDefinitions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Task,
        
        [Parameter(Mandatory = $false)]
        [switch]$Strict
    )
    
    $errors = @()
    
    # Vérifier les champs obligatoires
    foreach ($fieldKey in $script:RequiredTaskFields.Keys) {
        $field = $script:RequiredTaskFields[$fieldKey]
        $fieldName = $field.Name
        
        # Vérifier si le champ existe
        if (-not $Task.PSObject.Properties.Name.Contains($fieldName) -or $null -eq $Task.$fieldName) {
            $errors += "Champ obligatoire manquant: $fieldName"
            continue
        }
        
        # Valider la valeur du champ
        foreach ($validator in $field.Validators) {
            if (-not (& $validator $Task.$fieldName)) {
                $errors += "Validation échouée pour le champ $fieldName"
                break
            }
        }
    }
    
    # Vérifier les champs optionnels si le mode strict est activé
    if ($Strict) {
        foreach ($fieldKey in $script:OptionalTaskFields.Keys) {
            $field = $script:OptionalTaskFields[$fieldKey]
            $fieldName = $field.Name
            
            # Ignorer si le champ n'existe pas (il est optionnel)
            if (-not $Task.PSObject.Properties.Name.Contains($fieldName) -or $null -eq $Task.$fieldName) {
                continue
            }
            
            # Valider la valeur du champ
            foreach ($validator in $field.Validators) {
                if (-not (& $validator $Task.$fieldName)) {
                    $errors += "Validation échouée pour le champ optionnel $fieldName"
                    break
                }
            }
        }
    }
    
    if ($errors.Count -gt 0) {
        Write-Error ($errors -join "`n")
        return $false
    }
    
    return $true
}

# Exporter les fonctions
Export-ModuleMember -Function Get-AllTaskFields, Get-RequiredTaskFields, Get-OptionalTaskFields, Test-TaskAgainstFieldDefinitions
