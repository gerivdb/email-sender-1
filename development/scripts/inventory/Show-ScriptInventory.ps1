<#
.SYNOPSIS
Affiche l'inventaire des scripts avec des options de filtrage et d'export

.DESCRIPTION
Ce script permet de :
- Lister tous les scripts du projet
- Filtrer par nom, auteur, tags ou langage
- Exporter les rÃ©sultats en CSV, JSON ou HTML
- GÃ©nÃ©rer des statistiques sur l'utilisation des scripts
#>

param(
    [string]$Name,
    [string]$Author,
    [string]$Tag,
    [string]$Language,
    [ValidateSet('CSV', 'JSON', 'HTML', 'None')]
    [string]$ExportFormat = 'None',
    [string]$OutputPath = "reports/script_inventory",
    [switch]$Update
)

# Charger le module d'inventaire
Import-Module $PSScriptRoot/../../modules/ScriptInventoryManager.psm1 -Force

# Mettre Ã  jour l'inventaire si demandÃ©
if ($Update) {
    Update-ScriptInventory -Path $PSScriptRoot/../..
}

# RÃ©cupÃ©rer les scripts avec les filtres
$scripts = Find-Script -Name $Name -Author $Author -Tag $Tag -Language $Language

# Afficher les rÃ©sultats en console
$scripts | Format-Table -Property FileName, Language, Author, Version, Tags, LastModified -AutoSize

# GÃ©nÃ©rer des statistiques
$stats = @{
    TotalScripts    = $scripts.Count
    PowerShell      = ($scripts | Where-Object { $_.Language -eq 'PowerShell' }).Count
    Python          = ($scripts | Where-Object { $_.Language -eq 'Python' }).Count
    UniqueAuthors   = ($scripts | Select-Object -ExpandProperty Author -Unique).Count
    MostCommonTag   = $scripts | Select-Object -ExpandProperty Tags | Group-Object | Sort-Object Count -Descending | Select-Object -First 1 -ExpandProperty Name
}

Write-Host "`nStatistiques de l'inventaire:"
$stats.GetEnumerator() | ForEach-Object {
    Write-Host ("- {0}: {1}" -f $_.Key, $_.Value)
}

# Exporter les rÃ©sultats si demandÃ©
if ($ExportFormat -ne 'None') {
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    $exportFile = "$OutputPath/script_inventory_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

    switch ($ExportFormat) {
        'CSV' {
            $exportFile += '.csv'
            $scripts | Export-Csv -Path $exportFile -NoTypeInformation -Encoding UTF8
            Write-Host "`nInventaire exportÃ© au format CSV: $exportFile"
        }
        'JSON' {
            $exportFile += '.json'
            $scripts | ConvertTo-Json -Depth 5 | Out-File -FilePath $exportFile -Encoding UTF8
            Write-Host "`nInventaire exportÃ© au format JSON: $exportFile"
        }
        'HTML' {
            $exportFile += '.html'
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Inventaire des Scripts</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>Inventaire des Scripts</h1>
    <p>GÃ©nÃ©rÃ© le $(Get-Date)</p>
    <h2>Statistiques</h2>
    <ul>
"@

            foreach ($stat in $stats.GetEnumerator()) {
                $html += "        <li><strong>$($stat.Key):</strong> $($stat.Value)</li>`n"
            }

            $html += @"
    </ul>
    <h2>DÃ©tail des Scripts</h2>
    <table>
        <tr>
            <th>Nom</th>
            <th>Langage</th>
            <th>Auteur</th>
            <th>Version</th>
            <th>Tags</th>
            <th>DerniÃ¨re modification</th>
        </tr>
"@

            foreach ($script in $scripts) {
                $html += @"
        <tr>
            <td>$($script.FileName)</td>
            <td>$($script.Language)</td>
            <td>$($script.Author)</td>
            <td>$($script.Version)</td>
            <td>$($script.Tags -join ', ')</td>
            <td>$($script.LastModified)</td>
        </tr>
"@
            }

            $html += @"
    </table>
</body>
</html>
"@

            $html | Out-File -FilePath $exportFile -Encoding UTF8
            Write-Host "`nInventaire exportÃ© au format HTML: $exportFile"
        }
    }
}
