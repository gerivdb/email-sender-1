# Test-TaskSchema.ps1
# Script pour valider les tâches de roadmap selon le schéma défini
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Valide les tâches de roadmap selon le schéma JSON défini.

.DESCRIPTION
    Ce script permet de valider les tâches de roadmap selon le schéma JSON défini
    dans le fichier task_schema.json. Il utilise la bibliothèque Newtonsoft.Json.Schema
    pour effectuer la validation.

.PARAMETER TaskObject
    L'objet tâche à valider.

.PARAMETER TaskJson
    La chaîne JSON représentant la tâche à valider.

.PARAMETER TaskFile
    Le chemin vers un fichier JSON contenant la tâche à valider.

.PARAMETER SchemaFile
    Le chemin vers le fichier de schéma JSON. Par défaut, il s'agit du fichier task_schema.json
    situé dans le même répertoire que ce script.

.EXAMPLE
    $task = @{
        id = "1.2.3"
        title = "Implémenter la validation de schéma"
        status = "InProgress"
        createdAt = (Get-Date).ToUniversalTime().ToString("o")
        updatedAt = (Get-Date).ToUniversalTime().ToString("o")
    }
    
    Test-TaskSchema -TaskObject $task

.EXAMPLE
    Test-TaskSchema -TaskJson '{"id":"1.2.3","title":"Implémenter la validation de schéma","status":"InProgress","createdAt":"2025-05-15T10:00:00Z","updatedAt":"2025-05-15T10:00:00Z"}'

.EXAMPLE
    Test-TaskSchema -TaskFile "path/to/task.json"

.NOTES
    Auteur: Équipe DevOps
    Date: 2025-05-15
    Version: 1.0
#>

[CmdletBinding(DefaultParameterSetName = 'Object')]
param (
    [Parameter(Mandatory = $true, ParameterSetName = 'Object')]
    [object]$TaskObject,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'Json')]
    [string]$TaskJson,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'File')]
    [string]$TaskFile,
    
    [Parameter(Mandatory = $false)]
    [string]$SchemaFile
)

# Importer les modules nécessaires
$ErrorActionPreference = 'Stop'

# Vérifier si Newtonsoft.Json.Schema est installé
$newtonsoftSchemaModule = Get-Module -ListAvailable -Name Newtonsoft.Json.Schema
if (-not $newtonsoftSchemaModule) {
    Write-Warning "Le module Newtonsoft.Json.Schema n'est pas installé. Installation en cours..."
    try {
        Install-Package -Name Newtonsoft.Json.Schema -Scope CurrentUser -Force | Out-Null
    }
    catch {
        Write-Error "Impossible d'installer le module Newtonsoft.Json.Schema. Veuillez l'installer manuellement."
        exit 1
    }
}

# Charger les assemblies nécessaires
Add-Type -Path (Get-Package -Name Newtonsoft.Json.Schema).Source
Add-Type -AssemblyName System.Web.Extensions

# Déterminer le chemin du fichier de schéma
if (-not $SchemaFile) {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $SchemaFile = Join-Path -Path $scriptPath -ChildPath "task_schema.json"
}

# Vérifier si le fichier de schéma existe
if (-not (Test-Path -Path $SchemaFile)) {
    Write-Error "Le fichier de schéma '$SchemaFile' n'existe pas."
    exit 1
}

# Charger le schéma JSON
try {
    $schemaJson = Get-Content -Path $SchemaFile -Raw
    $schema = [Newtonsoft.Json.Schema.JSchema]::Parse($schemaJson)
}
catch {
    Write-Error "Erreur lors du chargement du schéma JSON: $_"
    exit 1
}

# Fonction pour valider un objet JSON selon le schéma
function Test-JsonAgainstSchema {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Json,
        
        [Parameter(Mandatory = $true)]
        [Newtonsoft.Json.Schema.JSchema]$Schema
    )
    
    try {
        $jsonObject = [Newtonsoft.Json.Linq.JObject]::Parse($Json)
        $isValid = $jsonObject.IsValid($Schema, [ref]$null)
        
        if (-not $isValid) {
            $errorMessages = New-Object System.Collections.Generic.List[string]
            $jsonObject.IsValid($Schema, [ref]$errorMessages)
            
            foreach ($error in $errorMessages) {
                Write-Warning $error
            }
            
            return $false
        }
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de la validation JSON: $_"
        return $false
    }
}

# Valider la tâche selon le paramètre fourni
switch ($PSCmdlet.ParameterSetName) {
    'Object' {
        # Convertir l'objet en JSON
        $serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
        $json = $serializer.Serialize($TaskObject)
        
        # Valider le JSON
        $result = Test-JsonAgainstSchema -Json $json -Schema $schema
    }
    
    'Json' {
        # Valider le JSON directement
        $result = Test-JsonAgainstSchema -Json $TaskJson -Schema $schema
    }
    
    'File' {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $TaskFile)) {
            Write-Error "Le fichier '$TaskFile' n'existe pas."
            exit 1
        }
        
        # Charger le contenu du fichier
        $json = Get-Content -Path $TaskFile -Raw
        
        # Valider le JSON
        $result = Test-JsonAgainstSchema -Json $json -Schema $schema
    }
}

# Retourner le résultat
return $result
