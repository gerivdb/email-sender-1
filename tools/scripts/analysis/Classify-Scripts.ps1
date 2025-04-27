<#
.SYNOPSIS
Classifie automatiquement les scripts selon une taxonomie dÃ©finie

.DESCRIPTION
Ce script permet de :
- Classifier les scripts par catÃ©gories et sous-catÃ©gories
- Appliquer des tags basÃ©s sur le contenu
- GÃ©nÃ©rer une structure de dossiers basÃ©e sur la classification
#>

param(
    [ValidateSet('CSV', 'JSON', 'HTML')]
    [string]$ReportFormat = 'HTML',
    [string]$OutputPath = "reports/script_classification",
    [switch]$UpdateStructure
)

# Charger le module d'inventaire
Import-Module $PSScriptRoot/../../modules/ScriptInventoryManager.psm1 -Force

# Taxonomie des scripts
$taxonomy = @{
    "Core"    = @{
        Description   = "Scripts fondamentaux du projet"
        SubCategories = @{
            "Initialisation" = "Scripts de dÃ©marrage et configuration"
            "Utils"          = "Fonctions utilitaires de base"
            "Modules"        = "Modules principaux"
        }
    }
    "Gestion" = @{
        Description   = "Scripts de gestion et administration"
        SubCategories = @{
            "Projet" = "Gestion du projet"
            "CI-CD"  = "IntÃ©gration et dÃ©ploiement continu"
            "Tests"  = "Gestion des tests"
        }
    }
    "DonnÃ©es" = @{
        Description   = "Scripts de gestion des donnÃ©es"
        SubCategories = @{
            "Import"         = "Import de donnÃ©es"
            "Export"         = "Export de donnÃ©es"
            "Transformation" = "Transformation de donnÃ©es"
        }
    }
    "MCP"     = @{
        Description   = "Scripts liÃ©s aux MCP (Model Control Providers)"
        SubCategories = @{
            "IntÃ©gration" = "IntÃ©gration avec MCP"
            "Outils"      = "Outils MCP"
            "Gestion"     = "Gestion des MCP"
        }
    }
}

# RÃ¨gles de classification basÃ©es sur le contenu
$classificationRules = @{
    "Core"    = @{
        Patterns = @("Initialize-", "Setup-", "Config", "MainModule")
        Keywords = @("configuration", "initialisation", "core", "module")
    }
    "Gestion" = @{
        Patterns = @("Manage-", "Admin-", "Test-", "Build-", "Deploy-")
        Keywords = @("gestion", "admin", "test", "build", "deploy")
    }
    "DonnÃ©es" = @{
        Patterns = @("Import-", "Export-", "Convert-", "Transform-")
        Keywords = @("import", "export", "data", "csv", "json", "transform")
    }
    "MCP"     = @{
        Patterns = @("MCP-", "Gateway-", "Provider-")
        Keywords = @("mcp", "gateway", "provider", "model", "control")
    }
}

# Fonction pour classifier un script
function Get-ScriptClassification {
    param(
        [string]$scriptPath,
        [string]$scriptName
    )

    $content = Get-Content $scriptPath -Raw
    $classification = @{
        Category    = "Non classÃ©"
        SubCategory = "Autre"
        Tags        = @()
    }

    # VÃ©rifier les rÃ¨gles de classification
    foreach ($category in $classificationRules.Keys) {
        $matchFound = $false

        # VÃ©rifier les patterns dans le nom
        foreach ($pattern in $classificationRules[$category].Patterns) {
            if ($scriptName -like "*$pattern*") {
                $matchFound = $true
                break
            }
        }

        # VÃ©rifier les keywords dans le contenu
        if (-not $matchFound) {
            foreach ($keyword in $classificationRules[$category].Keywords) {
                if ($content -match $keyword) {
                    $matchFound = $true
                    break
                }
            }
        }

        if ($matchFound) {
            $classification.Category = $category
            # Trouver la sous-catÃ©gorie la plus probable
            foreach ($subCat in $taxonomy[$category].SubCategories.Keys) {
                if ($scriptName -like "*$subCat*" -or $content -match $subCat) {
                    $classification.SubCategory = $subCat
                    break
                }
            }
            break
        }
    }

    # Ajouter des tags basÃ©s sur le contenu
    if ($content -match "function ") { $classification.Tags += "Fonctions" }
    if ($content -match "class ") { $classification.Tags += "Classes" }
    if ($content -match "workflow") { $classification.Tags += "Workflow" }
    if ($content -match "param\(") { $classification.Tags += "ParamÃ¨tres" }

    return $classification
}

# RÃ©cupÃ©rer tous les scripts
$allScripts = Get-ScriptInventory -ForceRescan
$results = @()

# Classifier chaque script
foreach ($script in $allScripts) {
    $classification = Get-ScriptClassification -scriptPath $script.FullPath -scriptName $script.FileName

    $result = [PSCustomObject]@{
        ScriptName    = $script.FileName
        Category      = $classification.Category
        SubCategory   = $classification.SubCategory
        Tags          = $classification.Tags -join ", "
        CurrentPath   = $script.FullPath
        SuggestedPath = if ($UpdateStructure) {
            "scripts/$($classification.Category)/$($classification.SubCategory)/$($script.FileName)"
        } else { "" }
    }

    $results += $result
}

# GÃ©nÃ©rer le rapport
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$reportFile = "$OutputPath/script_classification_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

switch ($ReportFormat) {
    'CSV' {
        $reportFile += '.csv'
        $results | Export-Csv -Path $reportFile -NoTypeInformation -Encoding UTF8
    }
    'JSON' {
        $reportFile += '.json'
        $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportFile -Encoding UTF8
    }
    'HTML' {
        $reportFile += '.html'
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Classification des Scripts</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>Classification des Scripts</h1>
    <p>GÃ©nÃ©rÃ© le $(Get-Date)</p>
    <table>
        <tr>
            <th>Script</th>
            <th>CatÃ©gorie</th>
            <th>Sous-catÃ©gorie</th>
            <th>Tags</th>
            $(
                if ($UpdateStructure) {
                    "<th>Chemin suggÃ©rÃ©</th>"
                }
            )
        </tr>
"@

        foreach ($result in $results) {
            $html += @"
        <tr>
            <td>$($result.ScriptName)</td>
            <td>$($result.Category)</td>
            <td>$($result.SubCategory)</td>
            <td>$($result.Tags)</td>
            $(
                if ($UpdateStructure) {
                    "<td>$($result.SuggestedPath)</td>"
                }
            )
        </tr>
"@
        }

        $html += @"
    </table>
</body>
</html>
"@

        $html | Out-File -FilePath $reportFile -Encoding UTF8
    }
}

# Mettre Ã  jour la structure si demandÃ©
if ($UpdateStructure) {
    Write-Host "Mise Ã  jour de la structure des dossiers..."
    foreach ($result in $results) {
        if ($result.SuggestedPath -and $result.CurrentPath -ne $result.SuggestedPath) {
            $targetDir = Split-Path $result.SuggestedPath -Parent
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            Move-Item $result.CurrentPath $result.SuggestedPath -Force
        }
    }
    Write-Host "Structure mise Ã  jour avec succÃ¨s."
}

Write-Host "Rapport gÃ©nÃ©rÃ©: $reportFile"
$results | Format-Table -AutoSize
