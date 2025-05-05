<#
.SYNOPSIS
    Exemple d'utilisation du module ConfigurationMetadataExtractor.
.DESCRIPTION
    Ce script montre comment utiliser les fonctions du module ConfigurationMetadataExtractor
    pour analyser un fichier de configuration.
.PARAMETER Path
    Chemin vers le fichier de configuration Ã  analyser.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer les rÃ©sultats de l'analyse.
.EXAMPLE
    .\AnalyzeConfiguration.ps1 -Path "config.json" -OutputPath "analysis"
    Analyse le fichier config.json et enregistre les rÃ©sultats dans le dossier analysis.
#>
param (
    [Parameter(Mandatory = $true)]
    [string]$Path,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "analysis"
)

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\ConfigurationMetadataExtractor.psm1'
Import-Module $modulePath -Force

# VÃ©rifier que le fichier existe
if (-not (Test-Path -Path $Path -PathType Leaf)) {
    Write-Error "Le fichier spÃ©cifiÃ© n'existe pas: $Path"
    exit 1
}

# CrÃ©er le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath -PathType Container)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Analyser le format du fichier
$format = Get-ConfigurationFormat -Path $Path
Write-Host "Format du fichier: $format"

if ($format -eq "UNKNOWN") {
    Write-Error "Format de fichier non reconnu."
    exit 1
}

# Analyser la structure du fichier
$structure = Get-ConfigurationStructure -Path $Path -Format $format
Write-Host "Structure du fichier:"
Write-Host "  Nombre de sections: $($structure.SectionCount)"
Write-Host "  Nombre de clÃ©s: $($structure.KeyCount)"
Write-Host "  Profondeur maximale: $($structure.Depth)"

# Enregistrer la structure dans un fichier JSON
$structureOutputPath = Join-Path -Path $OutputPath -ChildPath "structure.json"
ConvertTo-Json -InputObject $structure -Depth 10 | Set-Content -Path $structureOutputPath
Write-Host "Structure enregistrÃ©e dans: $structureOutputPath"

# Extraire les options de configuration
$options = Get-ConfigurationOptions -Path $Path -Format $format -IncludeValues
Write-Host "Options de configuration:"
Write-Host "  Nombre d'options: $($options.Count)"

# Enregistrer les options dans un fichier JSON
$optionsOutputPath = Join-Path -Path $OutputPath -ChildPath "options.json"
ConvertTo-Json -InputObject $options -Depth 10 | Set-Content -Path $optionsOutputPath
Write-Host "Options enregistrÃ©es dans: $optionsOutputPath"

# Extraire les dÃ©pendances de configuration
$dependencies = Get-ConfigurationDependencies -Path $Path -Format $format -DetectionMode "All"
Write-Host "DÃ©pendances de configuration:"
Write-Host "  Nombre de dÃ©pendances internes: $($dependencies.InternalDependencies.Count)"
Write-Host "  Nombre de dÃ©pendances externes: $($dependencies.ExternalDependencies.Count)"
Write-Host "  Nombre de chemins rÃ©fÃ©rencÃ©s: $($dependencies.ReferencedPaths.Count)"
Write-Host "  Nombre de dÃ©pendances circulaires: $($dependencies.CircularDependencies.Count)"

# Enregistrer les dÃ©pendances dans un fichier JSON
$dependenciesOutputPath = Join-Path -Path $OutputPath -ChildPath "dependencies.json"
ConvertTo-Json -InputObject $dependencies -Depth 10 | Set-Content -Path $dependenciesOutputPath
Write-Host "DÃ©pendances enregistrÃ©es dans: $dependenciesOutputPath"

# Analyser les contraintes de configuration
$constraints = Get-ConfigurationConstraints -Path $Path -Format $format -ValidateValues
Write-Host "Contraintes de configuration:"
Write-Host "  Nombre de contraintes de type: $($constraints.TypeConstraints.Count)"
Write-Host "  Nombre de contraintes de valeur: $($constraints.ValueConstraints.Count)"
Write-Host "  Nombre de contraintes de relation: $($constraints.RelationConstraints.Count)"
Write-Host "  Nombre de problÃ¨mes de validation: $($constraints.ValidationIssues.Count)"

# Enregistrer les contraintes dans un fichier JSON
$constraintsOutputPath = Join-Path -Path $OutputPath -ChildPath "constraints.json"
ConvertTo-Json -InputObject $constraints -Depth 10 | Set-Content -Path $constraintsOutputPath
Write-Host "Contraintes enregistrÃ©es dans: $constraintsOutputPath"

# GÃ©nÃ©rer un rapport HTML
$reportOutputPath = Join-Path -Path $OutputPath -ChildPath "report.html"
$reportContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'analyse de configuration</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .error { color: red; }
        .warning { color: orange; }
        .info { color: blue; }
    </style>
</head>
<body>
    <h1>Rapport d'analyse de configuration</h1>
    <p>Fichier analysÃ©: $Path</p>
    <p>Format: $format</p>
    
    <h2>Structure</h2>
    <table>
        <tr>
            <th>MÃ©trique</th>
            <th>Valeur</th>
        </tr>
        <tr>
            <td>Nombre de sections</td>
            <td>$($structure.SectionCount)</td>
        </tr>
        <tr>
            <td>Nombre de clÃ©s</td>
            <td>$($structure.KeyCount)</td>
        </tr>
        <tr>
            <td>Profondeur maximale</td>
            <td>$($structure.Depth)</td>
        </tr>
    </table>
    
    <h2>Options</h2>
    <table>
        <tr>
            <th>ClÃ©</th>
            <th>Type</th>
            <th>Complexe</th>
        </tr>
"@

foreach ($key in $options.Keys) {
    $option = $options[$key]
    $reportContent += @"
        <tr>
            <td>$key</td>
            <td>$($option.Type)</td>
            <td>$($option.IsComplex -eq $true)</td>
        </tr>
"@
}

$reportContent += @"
    </table>
    
    <h2>DÃ©pendances</h2>
    <h3>DÃ©pendances internes</h3>
    <table>
        <tr>
            <th>De</th>
            <th>Vers</th>
        </tr>
"@

foreach ($key in $dependencies.InternalDependencies.Keys) {
    foreach ($dependency in $dependencies.InternalDependencies[$key]) {
        $reportContent += @"
        <tr>
            <td>$key</td>
            <td>$dependency</td>
        </tr>
"@
    }
}

$reportContent += @"
    </table>
    
    <h3>DÃ©pendances circulaires</h3>
"@

if ($dependencies.CircularDependencies.Count -gt 0) {
    $reportContent += @"
    <table>
        <tr>
            <th>Cycle</th>
        </tr>
"@

    foreach ($cycle in $dependencies.CircularDependencies) {
        $reportContent += @"
        <tr>
            <td class="error">$($cycle -join " -> ")</td>
        </tr>
"@
    }

    $reportContent += @"
    </table>
"@
}
else {
    $reportContent += @"
    <p>Aucune dÃ©pendance circulaire dÃ©tectÃ©e.</p>
"@
}

$reportContent += @"
    
    <h2>Contraintes</h2>
    <h3>ProblÃ¨mes de validation</h3>
"@

if ($constraints.ValidationIssues.Count -gt 0) {
    $reportContent += @"
    <table>
        <tr>
            <th>ProblÃ¨me</th>
        </tr>
"@

    foreach ($issue in $constraints.ValidationIssues) {
        $reportContent += @"
        <tr>
            <td class="error">$issue</td>
        </tr>
"@
    }

    $reportContent += @"
    </table>
"@
}
else {
    $reportContent += @"
    <p>Aucun problÃ¨me de validation dÃ©tectÃ©.</p>
"@
}

$reportContent += @"
</body>
</html>
"@

Set-Content -Path $reportOutputPath -Value $reportContent
Write-Host "Rapport HTML gÃ©nÃ©rÃ©: $reportOutputPath"

Write-Host "Analyse terminÃ©e avec succÃ¨s."
