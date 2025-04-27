<#
.SYNOPSIS
DÃ©tecte les scripts redondants ou similaires dans le projet

.DESCRIPTION
Ce script analyse le contenu des scripts pour :
- Identifier les scripts similaires (similaritÃ© de Levenshtein)
- DÃ©tecter les versions multiples du mÃªme script
- GÃ©nÃ©rer des recommandations de consolidation
#>

param(
    [ValidateRange(0,100)]
    [int]$SimilarityThreshold = 80,
    [ValidateSet('CSV', 'JSON', 'HTML')]
    [string]$ReportFormat = 'HTML',
    [string]$OutputPath = "reports/script_analysis"
)

# Charger le module d'inventaire
Import-Module $PSScriptRoot/../../modules/ScriptInventoryManager.psm1 -Force

# Fonction pour calculer la similaritÃ© entre deux scripts
function Get-ScriptSimilarity {
    param(
        [string]$script1,
        [string]$script2
    )

    # Normaliser les scripts (supprimer commentaires et espaces)
    $content1 = (Get-Content $script1 -Raw) -replace '#.*?$|\/\*.*?\*\/', '' -replace '\s+', ' '
    $content2 = (Get-Content $script2 -Raw) -replace '#.*?$|\/\*.*?\*\/', '' -replace '\s+', ' '

    # Calculer la distance de Levenshtein
    $len1 = $content1.Length
    $len2 = $content2.Length

    if ($len1 -eq 0 -or $len2 -eq 0) {
        return 0
    }

    $distance = 0
    if ($len1 -gt $len2) {
        $longer = $content1
        $shorter = $content2
    } else {
        $longer = $content2
        $shorter = $content1
    }

    $distance = 0
    for ($i = 0; $i -lt $shorter.Length; $i++) {
        if ($longer[$i] -ne $shorter[$i]) {
            $distance++
        }
    }

    # Calculer le pourcentage de similaritÃ©
    $similarity = (1 - ($distance / [Math]::Max($len1, $len2))) * 100
    return [Math]::Round($similarity, 2)
}

# RÃ©cupÃ©rer tous les scripts
$allScripts = Get-ScriptInventory -ForceRescan
$results = @()

# Comparer chaque paire de scripts
for ($i = 0; $i -lt $allScripts.Count; $i++) {
    for ($j = $i + 1; $j -lt $allScripts.Count; $j++) {
        $script1 = $allScripts[$i]
        $script2 = $allScripts[$j]

        # VÃ©rifier si les noms sont similaires (version diffÃ©rente)
        $nameSimilar = $false
        if ($script1.FileName -replace 'v\d+', '' -eq $script2.FileName -replace 'v\d+', '') {
            $nameSimilar = $true
        }

        # Calculer la similaritÃ© du contenu
        $similarity = Get-ScriptSimilarity -script1 $script1.FullPath -script2 $script2.FullPath

        if ($similarity -ge $SimilarityThreshold -or $nameSimilar) {
            $result = [PSCustomObject]@{
                Script1         = $script1.FileName
                Script2         = $script2.FileName
                Similarity      = $similarity
                NameSimilar     = $nameSimilar
                Script1Path     = $script1.FullPath
                Script2Path     = $script2.FullPath
                Script1Modified = $script1.LastModified
                Script2Modified = $script2.LastModified
                Recommendation  = if ($nameSimilar) {
                    "Scripts avec mÃªme nom mais version diffÃ©rente - vÃ©rifier si version plus rÃ©cente existe"
                } else {
                    "Scripts trÃ¨s similaires - considÃ©rer une fusion"
                }
            }

            $results += $result
        }
    }
}

# GÃ©nÃ©rer le rapport
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$reportFile = "$OutputPath/redundant_scripts_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

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
    <title>Rapport de Scripts Redondants</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .high-sim { background-color: #ffcccc; }
        .name-sim { background-color: #ccffcc; }
    </style>
</head>
<body>
    <h1>Rapport de Scripts Redondants</h1>
    <p>GÃ©nÃ©rÃ© le $(Get-Date) - Seuil de similaritÃ©: $SimilarityThreshold%</p>
    <table>
        <tr>
            <th>Script 1</th>
            <th>Script 2</th>
            <th>SimilaritÃ©</th>
            <th>Recommandation</th>
        </tr>
"@

        foreach ($result in $results) {
            $rowClass = if ($result.NameSimilar) { "name-sim" } elseif ($result.Similarity -ge 90) { "high-sim" }
            $html += @"
        <tr class="$rowClass">
            <td>$($result.Script1) (modifiÃ©: $($result.Script1Modified))</td>
            <td>$($result.Script2) (modifiÃ©: $($result.Script2Modified))</td>
            <td>$($result.Similarity)%</td>
            <td>$($result.Recommendation)</td>
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

Write-Host "Rapport gÃ©nÃ©rÃ©: $reportFile"
$results | Format-Table -AutoSize
