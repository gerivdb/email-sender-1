#!/usr/bin/env pwsh
# Script pour extraire les schémas de données des workflows N8N
# Tâche Atomique 015: Extraire Schémas Données N8N
# Durée: 20 minutes max

param(
    [string]$WorkflowsFile = "output/phase1/n8n-workflows-export.json",
    [string]$OutputFile = "output/phase1/n8n-data-schemas.json"
)

Write-Host "🔍 TÂCHE 015: Extraire Schémas Données N8N" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green

# Créer le répertoire de sortie
$outputDir = Split-Path $OutputFile -Parent
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Charger les workflows exportés
if (!(Test-Path $WorkflowsFile)) {
    Write-Warning "Fichier workflows non trouvé: $WorkflowsFile"
    Write-Host "Exécution de la tâche 009 d'abord..."
    & "$PSScriptRoot/task-009-scanner-workflows-n8n.ps1"
}

$workflows = Get-Content $WorkflowsFile | ConvertFrom-Json

# Analyser les schémas de données
$dataSchemas = @{
    "metadata" = @{
        "extracted_at" = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        "source_file" = $WorkflowsFile
        "total_workflows" = $workflows.workflows.Count
        "total_nodes" = 0
    }
    "schemas" = @{}
    "common_patterns" = @{}
    "data_transformations" = @{}
}

$nodeTypes = @{}
$fieldPatterns = @{}

foreach ($workflow in $workflows.workflows) {
    $dataSchemas.metadata.total_nodes += $workflow.nodes.Count
    
    foreach ($node in $workflow.nodes) {
        $nodeTypeKey = $node.type
        
        # Compter les types de nodes
        if ($nodeTypes.ContainsKey($nodeTypeKey)) {
            $nodeTypes[$nodeTypeKey]++
        } else {
            $nodeTypes[$nodeTypeKey] = 1
        }
        
        # Extraire les schémas basés sur les paramètres du node
        if (-not $dataSchemas.schemas.ContainsKey($nodeTypeKey)) {
            $dataSchemas.schemas[$nodeTypeKey] = @{
                "node_type" = $nodeTypeKey
                "category" = Get-NodeCategory $nodeTypeKey
                "common_parameters" = @{}
                "data_fields" = @{}
                "input_schema" = @{}
                "output_schema" = @{}
                "usage_count" = 0
                "workflows_using" = @()
            }
        }
        
        $dataSchemas.schemas[$nodeTypeKey].usage_count++
        $dataSchemas.schemas[$nodeTypeKey].workflows_using += "$($workflow.name) ($($workflow.id))"
        
        # Analyser les paramètres pour déduire le schéma
        if ($node.parameters) {
            foreach ($param in $node.parameters.PSObject.Properties) {
                $paramName = $param.Name
                $paramValue = $param.Value
                
                if (-not $dataSchemas.schemas[$nodeTypeKey].common_parameters.ContainsKey($paramName)) {
                    $dataSchemas.schemas[$nodeTypeKey].common_parameters[$paramName] = @{
                        "type" = Get-ParameterType $paramValue
                        "examples" = @()
                        "required" = $false
                    }
                }
                
                # Ajouter des exemples de valeurs
                if ($dataSchemas.schemas[$nodeTypeKey].common_parameters[$paramName].examples.Count -lt 3) {
                    $dataSchemas.schemas[$nodeTypeKey].common_parameters[$paramName].examples += $paramValue
                }
            }
        }
        
        # Schémas spécialisés par type de node
        switch -Wildcard ($nodeTypeKey) {
            "*email*" {
                $dataSchemas.schemas[$nodeTypeKey].input_schema = @{
                    "from" = "string"
                    "to" = "string|array"
                    "subject" = "string"
                    "body" = "string"
                    "attachments" = "array"
                }
                $dataSchemas.schemas[$nodeTypeKey].output_schema = @{
                    "message_id" = "string"
                    "status" = "string"
                    "timestamp" = "datetime"
                }
            }
            "*postgres*" {
                $dataSchemas.schemas[$nodeTypeKey].input_schema = @{
                    "query" = "string"
                    "parameters" = "object"
                }
                $dataSchemas.schemas[$nodeTypeKey].output_schema = @{
                    "rows" = "array"
                    "rowCount" = "number"
                    "fields" = "array"
                }
            }
            "*webhook*" {
                $dataSchemas.schemas[$nodeTypeKey].input_schema = @{
                    "body" = "object"
                    "headers" = "object"
                    "query" = "object"
                }
                $dataSchemas.schemas[$nodeTypeKey].output_schema = @{
                    "statusCode" = "number"
                    "body" = "object"
                    "headers" = "object"
                }
            }
            "*function*" {
                # Analyser le code des fonctions pour déduire les schémas
                if ($node.parameters.functionCode) {
                    $functionAnalysis = Analyze-FunctionCode $node.parameters.functionCode
                    $dataSchemas.schemas[$nodeTypeKey].data_transformations = $functionAnalysis
                }
            }
        }
    }
}

# Identifier les patterns communs
$commonFields = @("id", "name", "email", "timestamp", "status", "data", "json", "headers")
foreach ($field in $commonFields) {
    $usage = 0
    $schemas = @()
    
    foreach ($schemaKey in $dataSchemas.schemas.Keys) {
        $schema = $dataSchemas.schemas[$schemaKey]
        if ($schema.common_parameters.ContainsKey($field) -or 
            $schema.input_schema.ContainsKey($field) -or 
            $schema.output_schema.ContainsKey($field)) {
            $usage++
            $schemas += $schemaKey
        }
    }
    
    if ($usage -gt 1) {
        $dataSchemas.common_patterns[$field] = @{
            "usage_count" = $usage
            "used_in_schemas" = $schemas
            "recommended_type" = Get-RecommendedType $field
        }
    }
}

# Sauvegarder les schémas
$jsonOutput = $dataSchemas | ConvertTo-Json -Depth 10
$jsonOutput | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "✅ Extraction des schémas de données terminée" -ForegroundColor Green
Write-Host "📁 Fichier: $OutputFile" -ForegroundColor Cyan
Write-Host "📊 Types de nodes analysés: $($dataSchemas.schemas.Count)" -ForegroundColor Cyan
Write-Host "📊 Patterns communs: $($dataSchemas.common_patterns.Count)" -ForegroundColor Cyan

# Afficher un résumé
Write-Host "`n📋 RÉSUMÉ DES SCHÉMAS:" -ForegroundColor Yellow
foreach ($schemaKey in ($dataSchemas.schemas.Keys | Sort-Object)) {
    $schema = $dataSchemas.schemas[$schemaKey]
    Write-Host "  - $schemaKey ($($schema.usage_count) usages)" -ForegroundColor White
}

Write-Host "`n🎯 TÂCHE 015 TERMINÉE avec succès!" -ForegroundColor Green

# Fonctions utilitaires
function Get-NodeCategory {
    param($nodeType)
    
    switch -Wildcard ($nodeType) {
        "*trigger*" { return "trigger" }
        "*email*" { return "communication" }
        "*postgres*" { return "database" }
        "*mysql*" { return "database" }
        "*webhook*" { return "api" }
        "*function*" { return "logic" }
        "*set*" { return "data_transformation" }
        "*http*" { return "api" }
        default { return "other" }
    }
}

function Get-ParameterType {
    param($value)
    
    if ($value -eq $null) { return "null" }
    if ($value -is [bool]) { return "boolean" }
    if ($value -is [int] -or $value -is [double]) { return "number" }
    if ($value -is [array]) { return "array" }
    if ($value -is [hashtable] -or $value.GetType().Name -eq "PSCustomObject") { return "object" }
    return "string"
}

function Get-RecommendedType {
    param($fieldName)
    
    switch ($fieldName) {
        "id" { return "string|uuid" }
        "email" { return "string|email" }
        "timestamp" { return "datetime|iso8601" }
        "status" { return "string|enum" }
        "data" { return "object" }
        "json" { return "object" }
        "headers" { return "object" }
        default { return "string" }
    }
}

function Analyze-FunctionCode {
    param($code)
    
    $analysis = @{
        "inputs_detected" = @()
        "outputs_detected" = @()
        "transformations" = @()
    }
    
    # Analyser le code JavaScript pour détecter les patterns
    if ($code -match "items\.map") {
        $analysis.transformations += "array_mapping"
    }
    if ($code -match "\.filter\(") {
        $analysis.transformations += "array_filtering"
    }
    if ($code -match "JSON\.parse") {
        $analysis.transformations += "json_parsing"
    }
    if ($code -match "JSON\.stringify") {
        $analysis.transformations += "json_serialization"
    }
    
    return $analysis
}
