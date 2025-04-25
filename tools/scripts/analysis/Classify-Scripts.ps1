<#
.SYNOPSIS
Classifie automatiquement les scripts selon une taxonomie définie

.DESCRIPTION
Ce script permet de :
- Classifier les scripts par catégories et sous-catégories
- Appliquer des tags basés sur le contenu
- Générer une structure de dossiers basée sur la classification
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
            "Initialisation" = "Scripts de démarrage et configuration"
            "Utils"          = "Fonctions utilitaires de base"
            "Modules"        = "Modules principaux"
        }
    }
    "Gestion" = @{
        Description   = "Scripts de gestion et administration"
        SubCategories = @{
            "Projet" = "Gestion du projet"
            "CI-CD"  = "Intégration et déploiement continu"
            "Tests"  = "Gestion des tests"
        }
    }
    "Données" = @{
        Description   = "Scripts de gestion des données"
        SubCategories = @{
            "Import"         = "Import de données"
            "Export"         = "Export de données"
            "Transformation" = "Transformation de données"
        }
    }
    "MCP"     = @{
        Description   = "Scripts liés aux MCP (Model Control Providers)"
        SubCategories = @{
            "Intégration" = "Intégration avec MCP"
            "Outils"      = "Outils MCP"
            "Gestion"     = "Gestion des MCP"
        }
    }
}

# Règles de classification basées sur le contenu
$classificationRules = @{
    "Core"    = @{
        Patterns = @("Initialize-", "Setup-", "Config", "MainModule")
        Keywords = @("configuration", "initialisation", "core", "module")
    }
    "Gestion" = @{
        Patterns = @("Manage-", "Admin-", "Test-", "Build-", "Deploy-")
        Keywords = @("gestion", "admin", "test", "build", "deploy")
    }
    "Données" = @{
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
        Category    = "Non classé"
        SubCategory = "Autre"
        Tags        = @()
    }

    # Vérifier les règles de classification
    foreach ($category in $classificationRules.Keys) {
        $matchFound = $false

        # Vérifier les patterns dans le nom
        foreach ($pattern in $classificationRules[$category].Patterns) {
            if ($scriptName -like "*$pattern*") {
                $matchFound = $true
                break
            }
        }

        # Vérifier les keywords dans le contenu
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
            # Trouver la sous-catégorie la plus probable
            foreach ($subCat in $taxonomy[$category].SubCategories.Keys) {
                if ($scriptName -like "*$subCat*" -or $content -match $subCat) {
                    $classification.SubCategory = $subCat
                    break
                }
            }
            break
        }
    }

    # Ajouter des tags basés sur le contenu
    if ($content -match "function ") { $classification.Tags += "Fonctions" }
    if ($content -match "class ") { $classification.Tags += "Classes" }
    if ($content -match "workflow") { $classification.Tags += "Workflow" }
    if ($content -match "param\(") { $classification.Tags += "Paramètres" }

    return $classification
}

# Récupérer tous les scripts
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

# Générer le rapport
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
    <p>Généré le $(Get-Date)</p>
    <table>
        <tr>
            <th>Script</th>
            <th>Catégorie</th>
            <th>Sous-catégorie</th>
            <th>Tags</th>
            $(
                if ($UpdateStructure) {
                    "<th>Chemin suggéré</th>"
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

# Mettre à jour la structure si demandé
if ($UpdateStructure) {
    Write-Host "Mise à jour de la structure des dossiers..."
    foreach ($result in $results) {
        if ($result.SuggestedPath -and $result.CurrentPath -ne $result.SuggestedPath) {
            $targetDir = Split-Path $result.SuggestedPath -Parent
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            Move-Item $result.CurrentPath $result.SuggestedPath -Force
        }
    }
    Write-Host "Structure mise à jour avec succès."
}

Write-Host "Rapport généré: $reportFile"
$results | Format-Table -AutoSize
