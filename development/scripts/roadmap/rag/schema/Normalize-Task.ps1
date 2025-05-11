# Normalize-Task.ps1
# Script pour normaliser complètement une tâche de roadmap
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Normalise complètement une tâche de roadmap selon les règles définies.

.DESCRIPTION
    Ce script normalise complètement une tâche de roadmap en appliquant les règles
    de normalisation textuelle et structurelle définies dans les scripts
    TextNormalizationRules.ps1 et StructuralNormalizationRules.ps1.

.PARAMETER Task
    L'objet tâche à normaliser.

.PARAMETER NormalizeText
    Si spécifié, applique les règles de normalisation textuelle.

.PARAMETER NormalizeStructure
    Si spécifié, applique les règles de normalisation structurelle.

.PARAMETER ValidateAfterNormalization
    Si spécifié, valide la tâche après normalisation.

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
    
    Normalize-Task -Task $task -ValidateAfterNormalization

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
    [switch]$NormalizeText = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$NormalizeStructure = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$ValidateAfterNormalization = $false
)

begin {
    # Importer les modules nécessaires
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $textNormalizationRulesPath = Join-Path -Path $scriptPath -ChildPath "TextNormalizationRules.ps1"
    $structuralNormalizationRulesPath = Join-Path -Path $scriptPath -ChildPath "StructuralNormalizationRules.ps1"
    $taskFieldDefinitionsPath = Join-Path -Path $scriptPath -ChildPath "TaskFieldDefinitions.ps1"
    
    # Vérifier si les fichiers existent
    if ($NormalizeText -and -not (Test-Path -Path $textNormalizationRulesPath)) {
        Write-Error "Le fichier TextNormalizationRules.ps1 est introuvable."
        exit 1
    }
    
    if ($NormalizeStructure -and -not (Test-Path -Path $structuralNormalizationRulesPath)) {
        Write-Error "Le fichier StructuralNormalizationRules.ps1 est introuvable."
        exit 1
    }
    
    if ($ValidateAfterNormalization -and -not (Test-Path -Path $taskFieldDefinitionsPath)) {
        Write-Error "Le fichier TaskFieldDefinitions.ps1 est introuvable."
        exit 1
    }
    
    # Importer les scripts
    if ($NormalizeText) {
        . $textNormalizationRulesPath
    }
    
    if ($NormalizeStructure) {
        . $structuralNormalizationRulesPath
    }
    
    if ($ValidateAfterNormalization) {
        . $taskFieldDefinitionsPath
    }
}

process {
    $normalizedTask = $Task
    
    # Appliquer les règles de normalisation textuelle
    if ($NormalizeText) {
        $normalizedTask = Normalize-TaskText -Task $normalizedTask
    }
    
    # Appliquer les règles de normalisation structurelle
    if ($NormalizeStructure) {
        $normalizedTask = Normalize-TaskStructure -Task $normalizedTask
    }
    
    # Valider la tâche après normalisation
    if ($ValidateAfterNormalization) {
        $isValid = Test-TaskAgainstFieldDefinitions -Task $normalizedTask -ErrorAction SilentlyContinue
        
        if (-not $isValid) {
            Write-Warning "La tâche normalisée n'est pas valide selon les définitions de champs."
        }
    }
    
    return $normalizedTask
}

end {
    # Rien à faire ici
}

# Fonction pour normaliser un fichier JSON contenant une tâche
function Normalize-TaskFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$NormalizeText = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$NormalizeStructure = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$ValidateAfterNormalization = $false,
        
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
        
        # Normaliser la tâche
        $normalizedTask = Normalize-Task -Task $json -NormalizeText:$NormalizeText -NormalizeStructure:$NormalizeStructure -ValidateAfterNormalization:$ValidateAfterNormalization
        
        # Enregistrer la tâche normalisée
        $normalizedJson = ConvertTo-Json -InputObject $normalizedTask -Depth 10
        Set-Content -Path $OutputPath -Value $normalizedJson -Encoding UTF8
        
        Write-Verbose "Tâche normalisée enregistrée dans '$OutputPath'."
        return $true
    }
    catch {
        Write-Error "Erreur lors de la normalisation du fichier: $_"
        return $false
    }
}

# Fonction pour normaliser un tableau de tâches
function Normalize-TaskArray {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Tasks,
        
        [Parameter(Mandatory = $false)]
        [switch]$NormalizeText = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$NormalizeStructure = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$ValidateAfterNormalization = $false
    )
    
    $normalizedTasks = @()
    
    foreach ($task in $Tasks) {
        $normalizedTask = Normalize-Task -Task $task -NormalizeText:$NormalizeText -NormalizeStructure:$NormalizeStructure -ValidateAfterNormalization:$ValidateAfterNormalization
        $normalizedTasks += $normalizedTask
    }
    
    return $normalizedTasks
}

# Exporter les fonctions
Export-ModuleMember -Function Normalize-Task, Normalize-TaskFile, Normalize-TaskArray
