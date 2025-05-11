# Detect-TaskAnomalies.ps1
# Script pour détecter les anomalies dans les tâches de roadmap
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Détecte les anomalies dans les tâches de roadmap.

.DESCRIPTION
    Ce script fournit des fonctions pour détecter les anomalies dans les tâches de roadmap,
    notamment les incohérences de structure, les valeurs aberrantes et les références invalides.

.PARAMETER Task
    L'objet tâche à analyser.

.PARAMETER AnomalyTypes
    Types d'anomalies à détecter. Par défaut, tous les types sont détectés.

.PARAMETER Threshold
    Seuil de détection des anomalies. Plus le seuil est bas, plus la détection est sensible.

.EXAMPLE
    $task = @{
        id = "1.2.3"
        title = "Implémenter la validation de schéma"
        status = "InProgress"
        createdAt = (Get-Date).ToUniversalTime().ToString("o")
        updatedAt = (Get-Date).ToUniversalTime().ToString("o")
        estimatedHours = 1000  # Valeur aberrante
        dependencies = @("9.9.9")  # Référence probablement invalide
    }
    
    Detect-TaskAnomalies -Task $task

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
    [ValidateSet("Structure", "Values", "References", "Dates", "All")]
    [string[]]$AnomalyTypes = @("All"),
    
    [Parameter(Mandatory = $false)]
    [double]$Threshold = 0.7
)

begin {
    # Importer les modules nécessaires
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $taskFieldDefinitionsPath = Join-Path -Path $scriptPath -ChildPath "TaskFieldDefinitions.ps1"
    
    if (-not (Test-Path -Path $taskFieldDefinitionsPath)) {
        Write-Error "Le fichier TaskFieldDefinitions.ps1 est introuvable."
        exit 1
    }
    
    . $taskFieldDefinitionsPath
    
    # Définir les règles de détection d'anomalies
    $anomalyRules = @{
        # Règles de détection d'anomalies structurelles
        Structure = @(
            # Vérifier si des champs obligatoires sont manquants
            {
                param($task)
                
                $requiredFields = Get-RequiredTaskFields
                $missingFields = @()
                
                foreach ($fieldKey in $requiredFields.Keys) {
                    $field = $requiredFields[$fieldKey]
                    $fieldName = $field.Name
                    
                    if (-not $task.PSObject.Properties.Name.Contains($fieldName) -or $null -eq $task.$fieldName) {
                        $missingFields += $fieldName
                    }
                }
                
                if ($missingFields.Count -gt 0) {
                    return @{
                        Type = "Structure"
                        Severity = "High"
                        Message = "Champs obligatoires manquants: $($missingFields -join ', ')"
                        Fields = $missingFields
                    }
                }
                
                return $null
            },
            
            # Vérifier si des champs inconnus sont présents
            {
                param($task)
                
                $allFields = Get-AllTaskFields
                $unknownFields = @()
                
                foreach ($fieldName in $task.PSObject.Properties.Name) {
                    $found = $false
                    
                    foreach ($fieldKey in $allFields.Keys) {
                        if ($allFields[$fieldKey].Name -eq $fieldName) {
                            $found = $true
                            break
                        }
                    }
                    
                    if (-not $found) {
                        $unknownFields += $fieldName
                    }
                }
                
                if ($unknownFields.Count -gt 0) {
                    return @{
                        Type = "Structure"
                        Severity = "Low"
                        Message = "Champs inconnus présents: $($unknownFields -join ', ')"
                        Fields = $unknownFields
                    }
                }
                
                return $null
            },
            
            # Vérifier si des champs ont des types incorrects
            {
                param($task)
                
                $allFields = Get-AllTaskFields
                $incorrectTypes = @()
                
                foreach ($fieldKey in $allFields.Keys) {
                    $field = $allFields[$fieldKey]
                    $fieldName = $field.Name
                    
                    if (-not $task.PSObject.Properties.Name.Contains($fieldName) -or $null -eq $task.$fieldName) {
                        continue
                    }
                    
                    $value = $task.$fieldName
                    $expectedType = $field.Type
                    
                    $typeCorrect = $false
                    
                    switch ($expectedType) {
                        "string" {
                            $typeCorrect = $value -is [string]
                        }
                        "integer" {
                            $typeCorrect = $value -is [int]
                        }
                        "number" {
                            $typeCorrect = $value -is [int] -or $value -is [double]
                        }
                        "boolean" {
                            $typeCorrect = $value -is [bool]
                        }
                        "array" {
                            $typeCorrect = $value -is [array]
                        }
                        "object" {
                            $typeCorrect = $value -is [hashtable] -or $value -is [PSCustomObject]
                        }
                        default {
                            $typeCorrect = $true
                        }
                    }
                    
                    if (-not $typeCorrect) {
                        $incorrectTypes += @{
                            Field = $fieldName
                            ExpectedType = $expectedType
                            ActualType = $value.GetType().Name
                        }
                    }
                }
                
                if ($incorrectTypes.Count -gt 0) {
                    return @{
                        Type = "Structure"
                        Severity = "Medium"
                        Message = "Champs avec types incorrects: $($incorrectTypes.Count)"
                        Fields = $incorrectTypes | ForEach-Object { $_.Field }
                        Details = $incorrectTypes
                    }
                }
                
                return $null
            }
        )
        
        # Règles de détection d'anomalies de valeurs
        Values = @(
            # Vérifier si des valeurs numériques sont aberrantes
            {
                param($task)
                
                $aberrantValues = @()
                
                # Vérifier estimatedHours
                if ($task.PSObject.Properties.Name.Contains("estimatedHours") -and $null -ne $task.estimatedHours) {
                    $value = $task.estimatedHours
                    
                    if ($value -is [int] -or $value -is [double]) {
                        if ($value -gt 100) {  # Seuil arbitraire pour une tâche
                            $aberrantValues += @{
                                Field = "estimatedHours"
                                Value = $value
                                Threshold = 100
                                Message = "Temps estimé anormalement élevé"
                            }
                        }
                    }
                }
                
                # Vérifier progress
                if ($task.PSObject.Properties.Name.Contains("progress") -and $null -ne $task.progress) {
                    $value = $task.progress
                    
                    if ($value -is [int] -or $value -is [double]) {
                        if ($value -lt 0 -or $value -gt 100) {
                            $aberrantValues += @{
                                Field = "progress"
                                Value = $value
                                Threshold = "0-100"
                                Message = "Progression en dehors de la plage valide (0-100)"
                            }
                        }
                    }
                }
                
                # Vérifier complexity
                if ($task.PSObject.Properties.Name.Contains("complexity") -and $null -ne $task.complexity) {
                    $value = $task.complexity
                    
                    if ($value -is [int] -or $value -is [double]) {
                        if ($value -lt 1 -or $value -gt 5) {
                            $aberrantValues += @{
                                Field = "complexity"
                                Value = $value
                                Threshold = "1-5"
                                Message = "Complexité en dehors de la plage valide (1-5)"
                            }
                        }
                    }
                }
                
                if ($aberrantValues.Count -gt 0) {
                    return @{
                        Type = "Values"
                        Severity = "Medium"
                        Message = "Valeurs numériques aberrantes détectées: $($aberrantValues.Count)"
                        Fields = $aberrantValues | ForEach-Object { $_.Field }
                        Details = $aberrantValues
                    }
                }
                
                return $null
            },
            
            # Vérifier si des chaînes sont anormalement longues ou courtes
            {
                param($task)
                
                $anomalousStrings = @()
                
                # Vérifier title
                if ($task.PSObject.Properties.Name.Contains("title") -and $null -ne $task.title) {
                    $value = $task.title
                    
                    if ($value -is [string]) {
                        if ($value.Length < 3) {
                            $anomalousStrings += @{
                                Field = "title"
                                Value = $value
                                Length = $value.Length
                                Threshold = "min 3"
                                Message = "Titre anormalement court"
                            }
                        }
                        elseif ($value.Length > 100) {
                            $anomalousStrings += @{
                                Field = "title"
                                Value = $value
                                Length = $value.Length
                                Threshold = "max 100"
                                Message = "Titre anormalement long"
                            }
                        }
                    }
                }
                
                # Vérifier description
                if ($task.PSObject.Properties.Name.Contains("description") -and $null -ne $task.description) {
                    $value = $task.description
                    
                    if ($value -is [string] -and $value.Length > 1000) {
                        $anomalousStrings += @{
                            Field = "description"
                            Value = $value.Substring(0, 50) + "..."
                            Length = $value.Length
                            Threshold = "max 1000"
                            Message = "Description anormalement longue"
                        }
                    }
                }
                
                if ($anomalousStrings.Count -gt 0) {
                    return @{
                        Type = "Values"
                        Severity = "Low"
                        Message = "Chaînes de caractères anormales détectées: $($anomalousStrings.Count)"
                        Fields = $anomalousStrings | ForEach-Object { $_.Field }
                        Details = $anomalousStrings
                    }
                }
                
                return $null
            },
            
            # Vérifier si des tableaux sont vides ou anormalement grands
            {
                param($task)
                
                $anomalousArrays = @()
                
                # Vérifier tags
                if ($task.PSObject.Properties.Name.Contains("tags") -and $null -ne $task.tags) {
                    $value = $task.tags
                    
                    if ($value -is [array] -and $value.Count > 10) {
                        $anomalousArrays += @{
                            Field = "tags"
                            Count = $value.Count
                            Threshold = "max 10"
                            Message = "Nombre de tags anormalement élevé"
                        }
                    }
                }
                
                # Vérifier dependencies
                if ($task.PSObject.Properties.Name.Contains("dependencies") -and $null -ne $task.dependencies) {
                    $value = $task.dependencies
                    
                    if ($value -is [array] -and $value.Count > 5) {
                        $anomalousArrays += @{
                            Field = "dependencies"
                            Count = $value.Count
                            Threshold = "max 5"
                            Message = "Nombre de dépendances anormalement élevé"
                        }
                    }
                }
                
                # Vérifier subTasks
                if ($task.PSObject.Properties.Name.Contains("subTasks") -and $null -ne $task.subTasks) {
                    $value = $task.subTasks
                    
                    if ($value -is [array] -and $value.Count > 20) {
                        $anomalousArrays += @{
                            Field = "subTasks"
                            Count = $value.Count
                            Threshold = "max 20"
                            Message = "Nombre de sous-tâches anormalement élevé"
                        }
                    }
                }
                
                if ($anomalousArrays.Count -gt 0) {
                    return @{
                        Type = "Values"
                        Severity = "Low"
                        Message = "Tableaux anormaux détectés: $($anomalousArrays.Count)"
                        Fields = $anomalousArrays | ForEach-Object { $_.Field }
                        Details = $anomalousArrays
                    }
                }
                
                return $null
            }
        )
        
        # Règles de détection d'anomalies de références
        References = @(
            # Vérifier si des références sont potentiellement invalides
            {
                param($task)
                
                $invalidReferences = @()
                
                # Vérifier parentId
                if ($task.PSObject.Properties.Name.Contains("parentId") -and $null -ne $task.parentId) {
                    $value = $task.parentId
                    
                    if ($value -is [string]) {
                        # Vérifier si le parentId est un préfixe de l'id (ce qui serait normal)
                        if ($task.PSObject.Properties.Name.Contains("id") -and $null -ne $task.id) {
                            if (-not $task.id.StartsWith($value + ".")) {
                                $invalidReferences += @{
                                    Field = "parentId"
                                    Value = $value
                                    RelatedField = "id"
                                    RelatedValue = $task.id
                                    Message = "L'ID parent n'est pas un préfixe de l'ID de la tâche"
                                }
                            }
                        }
                    }
                }
                
                # Vérifier dependencies
                if ($task.PSObject.Properties.Name.Contains("dependencies") -and $null -ne $task.dependencies) {
                    $values = $task.dependencies
                    
                    if ($values -is [array]) {
                        foreach ($value in $values) {
                            # Vérifier si la dépendance est égale à l'id (ce qui serait une auto-dépendance)
                            if ($task.PSObject.Properties.Name.Contains("id") -and $null -ne $task.id) {
                                if ($value -eq $task.id) {
                                    $invalidReferences += @{
                                        Field = "dependencies"
                                        Value = $value
                                        RelatedField = "id"
                                        RelatedValue = $task.id
                                        Message = "Auto-dépendance détectée"
                                    }
                                }
                            }
                            
                            # Vérifier si la dépendance est un préfixe de l'id (ce qui serait une dépendance circulaire)
                            if ($task.PSObject.Properties.Name.Contains("id") -and $null -ne $task.id) {
                                if ($task.id.StartsWith($value + ".")) {
                                    $invalidReferences += @{
                                        Field = "dependencies"
                                        Value = $value
                                        RelatedField = "id"
                                        RelatedValue = $task.id
                                        Message = "Dépendance circulaire potentielle détectée"
                                    }
                                }
                            }
                        }
                    }
                }
                
                if ($invalidReferences.Count -gt 0) {
                    return @{
                        Type = "References"
                        Severity = "High"
                        Message = "Références potentiellement invalides détectées: $($invalidReferences.Count)"
                        Fields = $invalidReferences | ForEach-Object { $_.Field } | Select-Object -Unique
                        Details = $invalidReferences
                    }
                }
                
                return $null
            }
        )
        
        # Règles de détection d'anomalies de dates
        Dates = @(
            # Vérifier si des dates sont incohérentes
            {
                param($task)
                
                $inconsistentDates = @()
                
                # Vérifier si updatedAt est antérieur à createdAt
                if ($task.PSObject.Properties.Name.Contains("createdAt") -and $null -ne $task.createdAt -and
                    $task.PSObject.Properties.Name.Contains("updatedAt") -and $null -ne $task.updatedAt) {
                    
                    try {
                        $createdAt = [datetime]::Parse($task.createdAt)
                        $updatedAt = [datetime]::Parse($task.updatedAt)
                        
                        if ($updatedAt -lt $createdAt) {
                            $inconsistentDates += @{
                                Field1 = "createdAt"
                                Value1 = $task.createdAt
                                Field2 = "updatedAt"
                                Value2 = $task.updatedAt
                                Message = "La date de mise à jour est antérieure à la date de création"
                            }
                        }
                    }
                    catch {
                        # Ignorer les erreurs de parsing de date
                    }
                }
                
                # Vérifier si completionDate est antérieur à startDate
                if ($task.PSObject.Properties.Name.Contains("startDate") -and $null -ne $task.startDate -and
                    $task.PSObject.Properties.Name.Contains("completionDate") -and $null -ne $task.completionDate) {
                    
                    try {
                        $startDate = [datetime]::Parse($task.startDate)
                        $completionDate = [datetime]::Parse($task.completionDate)
                        
                        if ($completionDate -lt $startDate) {
                            $inconsistentDates += @{
                                Field1 = "startDate"
                                Value1 = $task.startDate
                                Field2 = "completionDate"
                                Value2 = $task.completionDate
                                Message = "La date d'achèvement est antérieure à la date de début"
                            }
                        }
                    }
                    catch {
                        # Ignorer les erreurs de parsing de date
                    }
                }
                
                # Vérifier si dueDate est dans le passé mais status n'est pas Completed
                if ($task.PSObject.Properties.Name.Contains("dueDate") -and $null -ne $task.dueDate -and
                    $task.PSObject.Properties.Name.Contains("status") -and $null -ne $task.status) {
                    
                    try {
                        $dueDate = [datetime]::Parse($task.dueDate)
                        $now = Get-Date
                        
                        if ($dueDate -lt $now -and $task.status -ne "Completed") {
                            $inconsistentDates += @{
                                Field1 = "dueDate"
                                Value1 = $task.dueDate
                                Field2 = "status"
                                Value2 = $task.status
                                Message = "La date d'échéance est passée mais la tâche n'est pas marquée comme terminée"
                            }
                        }
                    }
                    catch {
                        # Ignorer les erreurs de parsing de date
                    }
                }
                
                if ($inconsistentDates.Count -gt 0) {
                    return @{
                        Type = "Dates"
                        Severity = "Medium"
                        Message = "Dates incohérentes détectées: $($inconsistentDates.Count)"
                        Fields = $inconsistentDates | ForEach-Object { $_.Field1, $_.Field2 } | Select-Object -Unique
                        Details = $inconsistentDates
                    }
                }
                
                return $null
            },
            
            # Vérifier si des dates sont dans le futur lointain ou le passé lointain
            {
                param($task)
                
                $anomalousDates = @()
                $now = Get-Date
                $oneYearAgo = $now.AddYears(-1)
                $fiveYearsFromNow = $now.AddYears(5)
                
                # Vérifier createdAt
                if ($task.PSObject.Properties.Name.Contains("createdAt") -and $null -ne $task.createdAt) {
                    try {
                        $date = [datetime]::Parse($task.createdAt)
                        
                        if ($date -gt $fiveYearsFromNow) {
                            $anomalousDates += @{
                                Field = "createdAt"
                                Value = $task.createdAt
                                Message = "Date de création dans un futur lointain"
                            }
                        }
                        elseif ($date -lt $oneYearAgo) {
                            $anomalousDates += @{
                                Field = "createdAt"
                                Value = $task.createdAt
                                Message = "Date de création dans un passé lointain"
                            }
                        }
                    }
                    catch {
                        # Ignorer les erreurs de parsing de date
                    }
                }
                
                # Vérifier dueDate
                if ($task.PSObject.Properties.Name.Contains("dueDate") -and $null -ne $task.dueDate) {
                    try {
                        $date = [datetime]::Parse($task.dueDate)
                        
                        if ($date -gt $fiveYearsFromNow) {
                            $anomalousDates += @{
                                Field = "dueDate"
                                Value = $task.dueDate
                                Message = "Date d'échéance dans un futur lointain"
                            }
                        }
                    }
                    catch {
                        # Ignorer les erreurs de parsing de date
                    }
                }
                
                if ($anomalousDates.Count -gt 0) {
                    return @{
                        Type = "Dates"
                        Severity = "Low"
                        Message = "Dates potentiellement anormales détectées: $($anomalousDates.Count)"
                        Fields = $anomalousDates | ForEach-Object { $_.Field } | Select-Object -Unique
                        Details = $anomalousDates
                    }
                }
                
                return $null
            }
        )
    }
}

process {
    $anomalies = @()
    
    # Déterminer les types d'anomalies à détecter
    $typesToDetect = @()
    
    if ($AnomalyTypes -contains "All") {
        $typesToDetect = @("Structure", "Values", "References", "Dates")
    }
    else {
        $typesToDetect = $AnomalyTypes
    }
    
    # Appliquer les règles de détection d'anomalies
    foreach ($type in $typesToDetect) {
        foreach ($rule in $anomalyRules[$type]) {
            $anomaly = & $rule $Task
            
            if ($null -ne $anomaly) {
                $anomalies += $anomaly
            }
        }
    }
    
    return $anomalies
}

end {
    # Rien à faire ici
}

# Exporter la fonction
Export-ModuleMember -Function Detect-TaskAnomalies
