<#
.SYNOPSIS
    GÃ©nÃ¨re un rapport sur l'utilisation d'Augment Code.

.DESCRIPTION
    Ce script gÃ©nÃ¨re un rapport simple sur l'utilisation d'Augment Code,
    en analysant les logs et les Memories.

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour le rapport.
    Par dÃ©faut : "reports\augment\usage-report.md".

.EXAMPLE
    .\generate-usage-report.ps1
    # GÃ©nÃ¨re un rapport sur l'utilisation d'Augment Code

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$OutputPath = "reports\augment\usage-report.md"
)

# DÃ©terminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de dÃ©terminer le chemin du projet."
        exit 1
    }
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
$outputPath = Join-Path -Path $projectRoot -ChildPath $OutputPath
$outputDir = Split-Path -Path $outputPath -Parent
if (-not (Test-Path -Path $outputDir -PathType Container)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Fonction pour obtenir les statistiques d'utilisation
function Get-UsageStats {
    [CmdletBinding()]
    param ()
    
    $stats = @{
        TotalRequests = 0
        ModeUsage = @{}
        MemoriesSize = 0
        LastUpdated = $null
    }
    
    # Analyser les logs d'Augment
    $logPath = Join-Path -Path $projectRoot -ChildPath "logs\augment\augment.log"
    if (Test-Path -Path $logPath) {
        $logContent = Get-Content -Path $logPath -Encoding UTF8
        
        foreach ($line in $logContent) {
            if ($line -match "^(.*?)\|REQUEST\|(.*?)$") {
                $requestData = $matches[2] | ConvertFrom-Json
                $stats.TotalRequests++
                
                if ($requestData.mode) {
                    if (-not $stats.ModeUsage.ContainsKey($requestData.mode)) {
                        $stats.ModeUsage[$requestData.mode] = 0
                    }
                    $stats.ModeUsage[$requestData.mode]++
                }
            }
        }
    }
    
    # Analyser les Memories
    $memoriesPath = Join-Path -Path $projectRoot -ChildPath ".augment\memories\journal_memories.json"
    if (Test-Path -Path $memoriesPath) {
        $memoriesContent = Get-Content -Path $memoriesPath -Raw
        $stats.MemoriesSize = [System.Text.Encoding]::UTF8.GetByteCount($memoriesContent)
        
        try {
            $memories = $memoriesContent | ConvertFrom-Json
            if ($memories.lastUpdated) {
                $stats.LastUpdated = $memories.lastUpdated
            }
        } catch {
            Write-Warning "Erreur lors de l'analyse des Memories : $_"
        }
    }
    
    return $stats
}

# GÃ©nÃ©rer le rapport
$stats = Get-UsageStats
$report = @"
# Rapport d'utilisation d'Augment Code

GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Statistiques globales

- **Nombre total de requÃªtes** : $($stats.TotalRequests)
- **Taille des Memories** : $([math]::Round($stats.MemoriesSize / 1024, 2)) KB
- **DerniÃ¨re mise Ã  jour des Memories** : $($stats.LastUpdated)

## Utilisation par mode

| Mode | Nombre de requÃªtes | Pourcentage |
|------|-------------------|------------|
"@

# Ajouter les statistiques par mode
$totalModeRequests = $stats.ModeUsage.Values | Measure-Object -Sum | Select-Object -ExpandProperty Sum
foreach ($mode in $stats.ModeUsage.Keys | Sort-Object) {
    $count = $stats.ModeUsage[$mode]
    $percentage = if ($totalModeRequests -gt 0) { [math]::Round(($count / $totalModeRequests) * 100, 2) } else { 0 }
    $report += "| $mode | $count | $percentage% |`n"
}

$report += @"

## Recommandations

"@

# Ajouter des recommandations basÃ©es sur les statistiques
if ($stats.TotalRequests -eq 0) {
    $report += "- Commencez Ã  utiliser Augment Code pour bÃ©nÃ©ficier de ses fonctionnalitÃ©s.`n"
} else {
    # Recommandations basÃ©es sur l'utilisation des modes
    $mostUsedMode = $stats.ModeUsage.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1
    $leastUsedModes = $stats.ModeUsage.GetEnumerator() | Sort-Object -Property Value | Select-Object -First 3
    
    $report += "- Mode le plus utilisÃ© : **$($mostUsedMode.Key)** ($($mostUsedMode.Value) requÃªtes)`n"
    $report += "- Modes les moins utilisÃ©s : $($leastUsedModes.Key -join ', ')`n"
    $report += "- Envisagez d'utiliser davantage les modes moins utilisÃ©s pour tirer pleinement parti d'Augment Code.`n"
    
    # Recommandations basÃ©es sur la taille des Memories
    if ($stats.MemoriesSize -gt 10240) {
        $report += "- Les Memories sont assez volumineuses ($([math]::Round($stats.MemoriesSize / 1024, 2)) KB). Envisagez de les optimiser.`n"
    } elseif ($stats.MemoriesSize -lt 1024) {
        $report += "- Les Memories sont trÃ¨s petites ($([math]::Round($stats.MemoriesSize / 1024, 2)) KB). Envisagez de les enrichir.`n"
    }
    
    # Recommandations basÃ©es sur la date de derniÃ¨re mise Ã  jour
    if ($stats.LastUpdated) {
        try {
            $lastUpdated = [DateTime]$stats.LastUpdated
            $daysSinceUpdate = (Get-Date) - $lastUpdated
            
            if ($daysSinceUpdate.Days -gt 7) {
                $report += "- Les Memories n'ont pas Ã©tÃ© mises Ã  jour depuis $($daysSinceUpdate.Days) jours. Envisagez de les mettre Ã  jour.`n"
            }
        } catch {
            # Ignorer les erreurs de conversion de date
        }
    }
}

$report += @"

## Prochaines Ã©tapes

1. ExÃ©cutez `Import-Module AugmentIntegration` pour utiliser le module d'intÃ©gration Augment
2. Utilisez `Initialize-AugmentIntegration -StartServers` pour dÃ©marrer les serveurs MCP
3. Mettez Ã  jour les Memories avec `Update-AugmentMemoriesForMode -Mode ALL`
4. Analysez les performances avec `Analyze-AugmentPerformance`

## Ressources

- [Guide d'intÃ©gration avec Augment Code](../../docs/guides/augment/integration_guide.md)
- [Guide d'utilisation avancÃ©e](../../docs/guides/augment/advanced_usage.md)
- [Optimisation des Memories](../../docs/guides/augment/memories_optimization.md)
- [Limitations d'Augment Code](../../docs/guides/augment/limitations.md)
"@

# Enregistrer le rapport
$report | Out-File -FilePath $outputPath -Encoding UTF8
Write-Host "Rapport d'utilisation gÃ©nÃ©rÃ© : $outputPath" -ForegroundColor Green
