# Initialize-TaskDefaults.ps1
# Script pour initialiser les valeurs par défaut des tâches de roadmap
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Initialise les valeurs par défaut pour les champs optionnels des tâches de roadmap.

.DESCRIPTION
    Ce script fournit des fonctions pour initialiser les valeurs par défaut des champs
    optionnels des tâches de roadmap selon les définitions du schéma.

.PARAMETER Task
    L'objet tâche à initialiser avec les valeurs par défaut.

.PARAMETER FieldsToInitialize
    Liste des champs à initialiser. Si non spécifié, tous les champs optionnels seront initialisés.

.PARAMETER OverwriteExisting
    Si spécifié, les valeurs existantes seront écrasées par les valeurs par défaut.

.EXAMPLE
    $task = @{
        id = "1.2.3"
        title = "Implémenter la validation de schéma"
        status = "InProgress"
        createdAt = (Get-Date).ToUniversalTime().ToString("o")
        updatedAt = (Get-Date).ToUniversalTime().ToString("o")
    }
    
    Initialize-TaskDefaults -Task $task

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
    [string[]]$FieldsToInitialize,
    
    [Parameter(Mandatory = $false)]
    [switch]$OverwriteExisting
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
}

process {
    # Obtenir les champs optionnels
    $optionalFields = Get-OptionalTaskFields
    
    # Filtrer les champs à initialiser si spécifié
    if ($FieldsToInitialize) {
        $fieldsToProcess = @{}
        foreach ($fieldName in $FieldsToInitialize) {
            if ($optionalFields.ContainsKey($fieldName)) {
                $fieldsToProcess[$fieldName] = $optionalFields[$fieldName]
            }
            else {
                Write-Warning "Le champ '$fieldName' n'est pas un champ optionnel valide."
            }
        }
    }
    else {
        $fieldsToProcess = $optionalFields
    }
    
    # Initialiser les champs optionnels avec leurs valeurs par défaut
    foreach ($fieldKey in $fieldsToProcess.Keys) {
        $field = $fieldsToProcess[$fieldKey]
        $fieldName = $field.Name
        
        # Vérifier si le champ existe déjà et s'il faut l'écraser
        $fieldExists = $Task.PSObject.Properties.Name.Contains($fieldName) -and $null -ne $Task.$fieldName
        if ($fieldExists -and -not $OverwriteExisting) {
            continue
        }
        
        # Obtenir la valeur par défaut
        $defaultValue = $field.DefaultValue
        if ($defaultValue -is [scriptblock]) {
            $defaultValue = & $defaultValue
        }
        
        # Ajouter ou mettre à jour le champ
        if ($Task -is [PSCustomObject]) {
            if (-not $fieldExists) {
                $Task | Add-Member -MemberType NoteProperty -Name $fieldName -Value $defaultValue
            }
            else {
                $Task.$fieldName = $defaultValue
            }
        }
        elseif ($Task -is [hashtable]) {
            $Task[$fieldName] = $defaultValue
        }
        else {
            Write-Warning "Type d'objet non pris en charge. Seuls PSCustomObject et hashtable sont supportés."
            return $Task
        }
    }
    
    return $Task
}

end {
    # Rien à faire ici
}

# Fonction pour créer une nouvelle tâche avec les valeurs par défaut
function New-DefaultTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id,
        
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $false)]
        [string]$Status = "NotStarted",
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalFields = @{}
    )
    
    # Créer la tâche avec les champs obligatoires
    $task = @{
        id = $Id
        title = $Title
        status = $Status
        createdAt = (Get-Date).ToUniversalTime().ToString("o")
        updatedAt = (Get-Date).ToUniversalTime().ToString("o")
    }
    
    # Ajouter la description si fournie
    if (-not [string]::IsNullOrWhiteSpace($Description)) {
        $task["description"] = $Description
    }
    
    # Ajouter les champs additionnels
    foreach ($key in $AdditionalFields.Keys) {
        $task[$key] = $AdditionalFields[$key]
    }
    
    # Initialiser les valeurs par défaut pour les champs optionnels
    $task = Initialize-TaskDefaults -Task $task
    
    return $task
}

# Exporter la fonction
Export-ModuleMember -Function New-DefaultTask
