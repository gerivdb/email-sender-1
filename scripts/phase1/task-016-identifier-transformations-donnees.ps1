#!/usr/bin/env pwsh
# Script pour identifier les transformations de données dans les workflows N8N
# Tâche Atomique 016: Identifier Transformations Données
# Durée: 15 minutes max

param(
    [string]$WorkflowsFile = "output/phase1/n8n-workflows-export.json",
    [string]$OutputFile = "output/phase1/data-transformations.md"
)

Write-Host "🔍 TÂCHE 016: Identifier Transformations Données" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

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

# Analyser les transformations
$transformations = @{
    "set_nodes" = @()
    "function_nodes" = @()
    "expression_transformations" = @()
    "data_mappers" = @()
    "filters" = @()
    "aggregations" = @()
}

$transformationStats = @{}

foreach ($workflow in $workflows.workflows) {
    foreach ($node in $workflow.nodes) {
        # Set nodes (transformations de données simples)
        if ($node.type -like "*set*") {
            $setTransformation = @{
                "workflow" = "$($workflow.name) ($($workflow.id))"
                "node_name" = $node.name
                "operations" = @()
            }
            
            if ($node.parameters.values) {
                foreach ($value in $node.parameters.values) {
                    $setTransformation.operations += @{
                        "field" = $value.name
                        "value" = $value.value
                        "type" = "assignment"
                    }
                }
            }
            
            $transformations.set_nodes += $setTransformation
            $transformationStats["set"] = ($transformationStats["set"] -or 0) + 1
        }
        
        # Function nodes (transformations JavaScript)
        if ($node.type -like "*function*") {
            $functionCode = $node.parameters.functionCode
            $functionAnalysis = @{
                "workflow" = "$($workflow.name) ($($workflow.id))"
                "node_name" = $node.name
                "code" = $functionCode
                "patterns" = @()
                "complexity" = "low"
            }
            
            # Analyser le code pour identifier les patterns
            if ($functionCode) {
                if ($functionCode -match "items\.map") {
                    $functionAnalysis.patterns += "array_mapping"
                }
                if ($functionCode -match "\.filter\(") {
                    $functionAnalysis.patterns += "array_filtering"
                }
                if ($functionCode -match "JSON\.parse") {
                    $functionAnalysis.patterns += "json_parsing"
                }
                if ($functionCode -match "JSON\.stringify") {
                    $functionAnalysis.patterns += "json_serialization"
                }
                if ($functionCode -match "reduce\(") {
                    $functionAnalysis.patterns += "array_reduction"
                }
                if ($functionCode -match "for\s*\(|while\s*\(") {
                    $functionAnalysis.complexity = "medium"
                }
                if ($functionCode -match "Promise|async|await") {
                    $functionAnalysis.complexity = "high"
                }
            }
            
            $transformations.function_nodes += $functionAnalysis
            $transformationStats["function"] = ($transformationStats["function"] -or 0) + 1
        }
        
        # Expression transformations (dans les paramètres)
        if ($node.parameters) {
            foreach ($param in $node.parameters.PSObject.Properties) {
                if ($param.Value -and $param.Value.ToString() -match "=\{\{.*\}\}") {
                    $expressionTransformation = @{
                        "workflow" = "$($workflow.name) ($($workflow.id))"
                        "node_name" = $node.name
                        "parameter" = $param.Name
                        "expression" = $param.Value
                        "type" = "expression"
                    }
                    
                    $transformations.expression_transformations += $expressionTransformation
                    $transformationStats["expression"] = ($transformationStats["expression"] -or 0) + 1
                }
            }
        }
    }
}

# Générer le rapport Markdown
$report = @"
# 🔄 ANALYSE DES TRANSFORMATIONS DE DONNÉES

**Date d'analyse**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Fichier source**: $WorkflowsFile  
**Total workflows analysés**: $($workflows.workflows.Count)

---

## 📊 STATISTIQUES GLOBALES

"@

foreach ($type in $transformationStats.Keys | Sort-Object) {
    $count = $transformationStats[$type]
    $report += "- **Transformations $type**: $count occurrences`n"
}

$report += @"

---

## 🔧 SET NODES (Transformations Simples)

Les Set nodes permettent d'assigner des valeurs à des champs de manière déclarative.

"@

foreach ($setNode in $transformations.set_nodes) {
    $report += @"

### $($setNode.node_name)
**Workflow**: $($setNode.workflow)

**Opérations**:
"@
    foreach ($op in $setNode.operations) {
        $report += "- `$($op.field)` = `$($op.value)``n"
    }
    $report += "`n"
}

$report += @"

---

## ⚙️ FUNCTION NODES (Transformations JavaScript)

Les Function nodes contiennent du code JavaScript personnalisé pour les transformations complexes.

"@

foreach ($funcNode in $transformations.function_nodes) {
    $report += @"

### $($funcNode.node_name)
**Workflow**: $($funcNode.workflow)  
**Complexité**: $($funcNode.complexity)  
**Patterns détectés**: $($funcNode.patterns -join ', ')

**Code**:
``````javascript
$($funcNode.code)
```````

"@
}

$report += @"

---

## 📝 EXPRESSION TRANSFORMATIONS

Les expressions N8N permettent des transformations inline dans les paramètres.

"@

foreach ($exprTransform in $transformations.expression_transformations) {
    $report += @"

### $($exprTransform.node_name) - $($exprTransform.parameter)
**Workflow**: $($exprTransform.workflow)

**Expression**: `$($exprTransform.expression)`

"@
}

$report += @"

---

## 🎯 ANALYSE POUR MIGRATION GO

### Patterns de Transformation Identifiés

"@

$allPatterns = @()
foreach ($funcNode in $transformations.function_nodes) {
    $allPatterns += $funcNode.patterns
}
$uniquePatterns = $allPatterns | Sort-Object | Get-Unique

foreach ($pattern in $uniquePatterns) {
    $count = ($allPatterns | Where-Object { $_ -eq $pattern }).Count
    $report += @"

#### $pattern ($count occurrences)
"@
    switch ($pattern) {
        "array_mapping" {
            $report += @"
**Go équivalent**:
``````go
// Utiliser des slices et range loops
for i, item := range items {
    result[i] = transformItem(item)
}
```````
"@
        }
        "array_filtering" {
            $report += @"
**Go équivalent**:
``````go
// Utiliser des slices conditionnelles
var filtered []Item
for _, item := range items {
    if condition(item) {
        filtered = append(filtered, item)
    }
}
```````
"@
        }
        "json_parsing" {
            $report += @"
**Go équivalent**:
``````go
// Utiliser encoding/json
var data interface{}
err := json.Unmarshal([]byte(jsonStr), &data)
```````
"@
        }
        "json_serialization" {
            $report += @"
**Go équivalent**:
``````go
// Utiliser encoding/json
jsonData, err := json.Marshal(data)
```````
"@
        }
        "array_reduction" {
            $report += @"
**Go équivalent**:
``````go
// Utiliser accumulation manuelle
result := initialValue
for _, item := range items {
    result = reduceFunc(result, item)
}
```````
"@
        }
    }
}

$report += @"

### Recommandations de Migration

1. **Set Nodes → Go Structs**
   - Créer des structs Go pour les transformations de données
   - Utiliser des méthodes pour les assignations

2. **Function Nodes → Go Functions**
   - Convertir le JavaScript en fonctions Go équivalentes
   - Utiliser des interfaces pour la flexibilité

3. **Expressions → Go Templates**
   - Utiliser text/template ou html/template pour les expressions
   - Créer des helpers pour les transformations communes

### Points d'Attention

- ⚠️ **Complexité élevée**: $($transformations.function_nodes | Where-Object { $_.complexity -eq "high" } | Measure-Object).Count Function nodes
- ⚠️ **Patterns asynchrones**: Nécessitent goroutines et channels
- ⚠️ **Expressions dynamiques**: Peuvent nécessiter un interpréteur

### Prochaines Étapes

1. Créer des templates Go pour chaque pattern
2. Développer des utilitaires de conversion
3. Tester la compatibilité des transformations
4. Documenter les équivalences JavaScript ↔ Go

---

**📝 Rapport généré automatiquement par la Tâche 016**
"@

# Sauvegarder le rapport
$report | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "✅ Identification des transformations terminée" -ForegroundColor Green
Write-Host "📁 Fichier: $OutputFile" -ForegroundColor Cyan
Write-Host "📊 Set nodes: $($transformations.set_nodes.Count)" -ForegroundColor Cyan
Write-Host "📊 Function nodes: $($transformations.function_nodes.Count)" -ForegroundColor Cyan
Write-Host "📊 Expressions: $($transformations.expression_transformations.Count)" -ForegroundColor Cyan

# Afficher un résumé
Write-Host "`n📋 RÉSUMÉ DES TRANSFORMATIONS:" -ForegroundColor Yellow
foreach ($type in $transformationStats.Keys | Sort-Object) {
    Write-Host "  - $type: $($transformationStats[$type])" -ForegroundColor White
}

Write-Host "`n🎯 TÂCHE 016 TERMINÉE avec succès!" -ForegroundColor Green
