# Process-Task.ps1
# Script pour traiter complètement une tâche de roadmap
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Traite complètement une tâche de roadmap en la validant, la normalisant et en détectant les anomalies.

.DESCRIPTION
    Ce script fournit des fonctions pour traiter complètement une tâche de roadmap,
    notamment la validation, la normalisation et la détection d'anomalies.
    Il intègre les fonctionnalités des scripts TaskFieldDefinitions.ps1, Normalize-Task.ps1 et Detect-TaskAnomalies.ps1.

.PARAMETER Task
    L'objet tâche à traiter.

.PARAMETER Validate
    Si spécifié, valide la tâche avant traitement.

.PARAMETER Normalize
    Si spécifié, normalise la tâche.

.PARAMETER DetectAnomalies
    Si spécifié, détecte les anomalies dans la tâche.

.PARAMETER FixAnomalies
    Si spécifié, tente de corriger automatiquement les anomalies détectées.

.PARAMETER OutputReport
    Si spécifié, génère un rapport détaillé du traitement.

.EXAMPLE
    $task = @{
        id = "1.2.3"
        title = "  Implémenter la validation de schéma  "
        status = "inprogress"
        createdAt = "2025-05-15T10:00:00"
        updatedAt = "2025-05-15T10:00:00"
        estimatedHours = "2h"
        tags = @("important", "URGENT")
    }
    
    Process-Task -Task $task -Validate -Normalize -DetectAnomalies -OutputReport

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
    [switch]$Validate = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$Normalize = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$DetectAnomalies = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$FixAnomalies = $false,
    
    [Parameter(Mandatory = $false)]
    [switch]$OutputReport = $false
)

begin {
    # Importer les modules nécessaires
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $taskFieldDefinitionsPath = Join-Path -Path $scriptPath -ChildPath "TaskFieldDefinitions.ps1"
    $normalizeTaskPath = Join-Path -Path $scriptPath -ChildPath "Normalize-Task.ps1"
    $detectTaskAnomaliesPath = Join-Path -Path $scriptPath -ChildPath "Detect-TaskAnomalies.ps1"
    
    # Vérifier si les fichiers existent
    if ($Validate -and -not (Test-Path -Path $taskFieldDefinitionsPath)) {
        Write-Error "Le fichier TaskFieldDefinitions.ps1 est introuvable."
        exit 1
    }
    
    if ($Normalize -and -not (Test-Path -Path $normalizeTaskPath)) {
        Write-Error "Le fichier Normalize-Task.ps1 est introuvable."
        exit 1
    }
    
    if ($DetectAnomalies -and -not (Test-Path -Path $detectTaskAnomaliesPath)) {
        Write-Error "Le fichier Detect-TaskAnomalies.ps1 est introuvable."
        exit 1
    }
    
    # Importer les scripts
    if ($Validate) {
        . $taskFieldDefinitionsPath
    }
    
    if ($Normalize) {
        . $normalizeTaskPath
    }
    
    if ($DetectAnomalies) {
        . $detectTaskAnomaliesPath
    }
    
    # Initialiser le rapport
    $report = @{
        OriginalTask = $null
        ProcessedTask = $null
        ValidationResult = $null
        NormalizationApplied = $false
        Anomalies = @()
        FixesApplied = @()
        Success = $false
        Messages = @()
    }
}

process {
    # Initialiser le rapport
    if ($OutputReport) {
        $report.OriginalTask = $Task
    }
    
    # Copier la tâche pour éviter de modifier l'original
    $processedTask = $Task
    
    # Valider la tâche
    $validationResult = $true
    if ($Validate) {
        $validationResult = Test-TaskAgainstFieldDefinitions -Task $processedTask -ErrorAction SilentlyContinue
        
        if ($OutputReport) {
            $report.ValidationResult = $validationResult
        }
        
        if (-not $validationResult) {
            if ($OutputReport) {
                $report.Messages += "La tâche n'est pas valide selon les définitions de champs."
            }
            else {
                Write-Warning "La tâche n'est pas valide selon les définitions de champs."
            }
        }
    }
    
    # Normaliser la tâche
    if ($Normalize) {
        $processedTask = Normalize-Task -Task $processedTask -NormalizeText -NormalizeStructure
        
        if ($OutputReport) {
            $report.NormalizationApplied = $true
        }
    }
    
    # Détecter les anomalies
    if ($DetectAnomalies) {
        $anomalies = Detect-TaskAnomalies -Task $processedTask
        
        if ($OutputReport) {
            $report.Anomalies = $anomalies
        }
        
        if ($anomalies.Count -gt 0) {
            if ($OutputReport) {
                $report.Messages += "Anomalies détectées: $($anomalies.Count)"
            }
            else {
                Write-Warning "Anomalies détectées: $($anomalies.Count)"
                
                foreach ($anomaly in $anomalies) {
                    Write-Warning "  - $($anomaly.Message) (Sévérité: $($anomaly.Severity))"
                }
            }
            
            # Corriger les anomalies si demandé
            if ($FixAnomalies) {
                $fixesApplied = @()
                
                foreach ($anomaly in $anomalies) {
                    $fix = $null
                    
                    # Appliquer des corrections spécifiques selon le type d'anomalie
                    switch ($anomaly.Type) {
                        "Structure" {
                            # Corriger les champs obligatoires manquants
                            if ($anomaly.Message -like "*Champs obligatoires manquants*") {
                                foreach ($fieldName in $anomaly.Fields) {
                                    $requiredFields = Get-RequiredTaskFields
                                    
                                    foreach ($fieldKey in $requiredFields.Keys) {
                                        $field = $requiredFields[$fieldKey]
                                        
                                        if ($field.Name -eq $fieldName) {
                                            $defaultValue = $field.DefaultValue
                                            
                                            if ($defaultValue -is [scriptblock]) {
                                                $defaultValue = & $defaultValue
                                            }
                                            
                                            if ($processedTask -is [PSCustomObject]) {
                                                $processedTask | Add-Member -MemberType NoteProperty -Name $fieldName -Value $defaultValue -Force
                                            }
                                            elseif ($processedTask -is [hashtable]) {
                                                $processedTask[$fieldName] = $defaultValue
                                            }
                                            
                                            $fix = @{
                                                AnomalyType = $anomaly.Type
                                                Field = $fieldName
                                                Action = "Added missing required field with default value"
                                                Value = $defaultValue
                                            }
                                            
                                            $fixesApplied += $fix
                                        }
                                    }
                                }
                            }
                        }
                        
                        "Values" {
                            # Corriger les valeurs numériques aberrantes
                            if ($anomaly.Message -like "*Valeurs numériques aberrantes*") {
                                foreach ($detail in $anomaly.Details) {
                                    $fieldName = $detail.Field
                                    $value = $detail.Value
                                    $threshold = $detail.Threshold
                                    
                                    # Appliquer une correction spécifique selon le champ
                                    switch ($fieldName) {
                                        "estimatedHours" {
                                            if ($value -gt 100) {
                                                if ($processedTask -is [PSCustomObject]) {
                                                    $processedTask.estimatedHours = 100
                                                }
                                                elseif ($processedTask -is [hashtable]) {
                                                    $processedTask["estimatedHours"] = 100
                                                }
                                                
                                                $fix = @{
                                                    AnomalyType = $anomaly.Type
                                                    Field = $fieldName
                                                    Action = "Capped excessive value to maximum threshold"
                                                    OldValue = $value
                                                    NewValue = 100
                                                }
                                                
                                                $fixesApplied += $fix
                                            }
                                        }
                                        
                                        "progress" {
                                            if ($value -lt 0) {
                                                if ($processedTask -is [PSCustomObject]) {
                                                    $processedTask.progress = 0
                                                }
                                                elseif ($processedTask -is [hashtable]) {
                                                    $processedTask["progress"] = 0
                                                }
                                                
                                                $fix = @{
                                                    AnomalyType = $anomaly.Type
                                                    Field = $fieldName
                                                    Action = "Adjusted value to minimum threshold"
                                                    OldValue = $value
                                                    NewValue = 0
                                                }
                                                
                                                $fixesApplied += $fix
                                            }
                                            elseif ($value -gt 100) {
                                                if ($processedTask -is [PSCustomObject]) {
                                                    $processedTask.progress = 100
                                                }
                                                elseif ($processedTask -is [hashtable]) {
                                                    $processedTask["progress"] = 100
                                                }
                                                
                                                $fix = @{
                                                    AnomalyType = $anomaly.Type
                                                    Field = $fieldName
                                                    Action = "Adjusted value to maximum threshold"
                                                    OldValue = $value
                                                    NewValue = 100
                                                }
                                                
                                                $fixesApplied += $fix
                                            }
                                        }
                                        
                                        "complexity" {
                                            if ($value -lt 1) {
                                                if ($processedTask -is [PSCustomObject]) {
                                                    $processedTask.complexity = 1
                                                }
                                                elseif ($processedTask -is [hashtable]) {
                                                    $processedTask["complexity"] = 1
                                                }
                                                
                                                $fix = @{
                                                    AnomalyType = $anomaly.Type
                                                    Field = $fieldName
                                                    Action = "Adjusted value to minimum threshold"
                                                    OldValue = $value
                                                    NewValue = 1
                                                }
                                                
                                                $fixesApplied += $fix
                                            }
                                            elseif ($value -gt 5) {
                                                if ($processedTask -is [PSCustomObject]) {
                                                    $processedTask.complexity = 5
                                                }
                                                elseif ($processedTask -is [hashtable]) {
                                                    $processedTask["complexity"] = 5
                                                }
                                                
                                                $fix = @{
                                                    AnomalyType = $anomaly.Type
                                                    Field = $fieldName
                                                    Action = "Adjusted value to maximum threshold"
                                                    OldValue = $value
                                                    NewValue = 5
                                                }
                                                
                                                $fixesApplied += $fix
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        "References" {
                            # Corriger les références invalides
                            if ($anomaly.Message -like "*Auto-dépendance détectée*") {
                                foreach ($detail in $anomaly.Details) {
                                    if ($detail.Message -like "*Auto-dépendance détectée*") {
                                        $fieldName = $detail.Field
                                        $value = $detail.Value
                                        
                                        if ($processedTask -is [PSCustomObject]) {
                                            $processedTask.$fieldName = $processedTask.$fieldName | Where-Object { $_ -ne $value }
                                        }
                                        elseif ($processedTask -is [hashtable]) {
                                            $processedTask[$fieldName] = $processedTask[$fieldName] | Where-Object { $_ -ne $value }
                                        }
                                        
                                        $fix = @{
                                            AnomalyType = $anomaly.Type
                                            Field = $fieldName
                                            Action = "Removed self-reference"
                                            Value = $value
                                        }
                                        
                                        $fixesApplied += $fix
                                    }
                                }
                            }
                        }
                        
                        "Dates" {
                            # Corriger les dates incohérentes
                            if ($anomaly.Message -like "*Dates incohérentes*") {
                                foreach ($detail in $anomaly.Details) {
                                    $field1 = $detail.Field1
                                    $value1 = $detail.Value1
                                    $field2 = $detail.Field2
                                    $value2 = $detail.Value2
                                    
                                    # Corriger selon le type d'incohérence
                                    if ($detail.Message -like "*La date de mise à jour est antérieure à la date de création*") {
                                        # Mettre à jour updatedAt pour qu'il soit égal à createdAt
                                        if ($processedTask -is [PSCustomObject]) {
                                            $processedTask.$field2 = $processedTask.$field1
                                        }
                                        elseif ($processedTask -is [hashtable]) {
                                            $processedTask[$field2] = $processedTask[$field1]
                                        }
                                        
                                        $fix = @{
                                            AnomalyType = $anomaly.Type
                                            Field = $field2
                                            Action = "Adjusted to match creation date"
                                            OldValue = $value2
                                            NewValue = $processedTask.$field1
                                        }
                                        
                                        $fixesApplied += $fix
                                    }
                                    elseif ($detail.Message -like "*La date d'achèvement est antérieure à la date de début*") {
                                        # Mettre à jour completionDate pour qu'il soit égal à startDate
                                        if ($processedTask -is [PSCustomObject]) {
                                            $processedTask.$field2 = $processedTask.$field1
                                        }
                                        elseif ($processedTask -is [hashtable]) {
                                            $processedTask[$field2] = $processedTask[$field1]
                                        }
                                        
                                        $fix = @{
                                            AnomalyType = $anomaly.Type
                                            Field = $field2
                                            Action = "Adjusted to match start date"
                                            OldValue = $value2
                                            NewValue = $processedTask.$field1
                                        }
                                        
                                        $fixesApplied += $fix
                                    }
                                }
                            }
                        }
                    }
                }
                
                if ($OutputReport) {
                    $report.FixesApplied = $fixesApplied
                }
                
                if ($fixesApplied.Count -gt 0) {
                    if ($OutputReport) {
                        $report.Messages += "Corrections appliquées: $($fixesApplied.Count)"
                    }
                    else {
                        Write-Host "Corrections appliquées: $($fixesApplied.Count)" -ForegroundColor Green
                        
                        foreach ($fix in $fixesApplied) {
                            Write-Host "  - $($fix.Field): $($fix.Action)" -ForegroundColor Green
                        }
                    }
                }
            }
        }
    }
    
    # Mettre à jour le rapport
    if ($OutputReport) {
        $report.ProcessedTask = $processedTask
        $report.Success = $true
        
        return $report
    }
    else {
        return $processedTask
    }
}

end {
    # Rien à faire ici
}

# Fonction pour traiter un fichier JSON contenant une tâche
function Invoke-TaskFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Validate = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$Normalize = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$DetectAnomalies = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$FixAnomalies = $false,
        
        [Parameter(Mandatory = $false)]
        [switch]$OutputReport = $false,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force = $false
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        return $false
    }
    
    # Déterminer le chemin de sortie
    if (-not $OutputPath) {
        $OutputPath = $FilePath
    }
    
    # Vérifier si le fichier de sortie existe déjà
    if ((Test-Path -Path $OutputPath) -and -not $Force -and $OutputPath -ne $FilePath) {
        Write-Error "Le fichier de sortie '$OutputPath' existe déjà. Utilisez -Force pour écraser."
        return $false
    }
    
    try {
        # Charger le fichier JSON
        $json = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
        
        # Traiter la tâche
        $result = Process-Task -Task $json -Validate:$Validate -Normalize:$Normalize -DetectAnomalies:$DetectAnomalies -FixAnomalies:$FixAnomalies -OutputReport:$OutputReport
        
        if ($OutputReport) {
            # Enregistrer le rapport
            $reportJson = ConvertTo-Json -InputObject $result -Depth 10
            $reportPath = [System.IO.Path]::ChangeExtension($OutputPath, "report.json")
            Set-Content -Path $reportPath -Value $reportJson -Encoding UTF8
            
            # Enregistrer la tâche traitée
            $processedJson = ConvertTo-Json -InputObject $result.ProcessedTask -Depth 10
            Set-Content -Path $OutputPath -Value $processedJson -Encoding UTF8
            
            Write-Verbose "Rapport enregistré dans '$reportPath'."
            Write-Verbose "Tâche traitée enregistrée dans '$OutputPath'."
            
            return $result
        }
        else {
            # Enregistrer la tâche traitée
            $processedJson = ConvertTo-Json -InputObject $result -Depth 10
            Set-Content -Path $OutputPath -Value $processedJson -Encoding UTF8
            
            Write-Verbose "Tâche traitée enregistrée dans '$OutputPath'."
            
            return $true
        }
    }
    catch {
        Write-Error "Erreur lors du traitement du fichier: $_"
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Process-Task, Invoke-TaskFile

