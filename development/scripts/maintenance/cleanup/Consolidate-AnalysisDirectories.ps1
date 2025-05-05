#Requires -Version 5.1
<#
.SYNOPSIS
    Consolide les dossiers analysis et analytics en une structure unifiÃ©e.
.DESCRIPTION
    Ce script fusionne les dossiers development/scripts/analysis et development/scripts/analytics
    en une structure unifiÃ©e et organisÃ©e, en Ã©liminant la redondance tout en prÃ©servant
    les fonctionnalitÃ©s distinctes.
.PARAMETER DryRun
    Si spÃ©cifiÃ©, le script affiche les actions qui seraient effectuÃ©es sans les exÃ©cuter.
.PARAMETER Force
    Si spÃ©cifiÃ©, le script Ã©crase les fichiers existants sans demander de confirmation.
.PARAMETER LogFile
    Chemin vers un fichier de log pour enregistrer les actions effectuÃ©es.
.EXAMPLE
    .\Consolidate-AnalysisDirectories.ps1 -DryRun
.EXAMPLE
    .\Consolidate-AnalysisDirectories.ps1 -Force -LogFile "consolidation.log"
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2023-12-15
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$LogFile = "logs/consolidation-analysis-directories-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
)

# DÃ©finir le rÃ©pertoire racine du dÃ©pÃ´t
$repoRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\"
$repoRoot = [System.IO.Path]::GetFullPath($repoRoot)

# VÃ©rifier que le rÃ©pertoire racine existe
if (-not (Test-Path -Path $repoRoot -PathType Container)) {
    throw "Le rÃ©pertoire racine n'existe pas : $repoRoot"
}

# Fonction pour journaliser les actions
function Write-Log {
    param (
        [string]$Message,
        [string]$Color = "White"
    )

    Write-Host $Message -ForegroundColor $Color

    if ($LogFile) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp - $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
}

# Initialiser le fichier de log
if ($LogFile) {
    if (-not [System.IO.Path]::IsPathRooted($LogFile)) {
        $LogFile = Join-Path -Path $repoRoot -ChildPath $LogFile
    }

    $logDir = Split-Path -Path $LogFile -Parent
    if (-not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== Consolidation des dossiers analysis et analytics dÃ©marrÃ©e le $timestamp ===" | Out-File -FilePath $LogFile -Encoding UTF8
    "RÃ©pertoire racine: $repoRoot" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# DÃ©finir les chemins des dossiers source et destination
$analysisPath = Join-Path -Path $repoRoot -ChildPath "development\scripts\analysis"
$analyticsPath = Join-Path -Path $repoRoot -ChildPath "development\scripts\analytics"
$unifiedPath = Join-Path -Path $repoRoot -ChildPath "development\scripts\analysis"

# VÃ©rifier que les dossiers source existent
if (-not (Test-Path -Path $analysisPath -PathType Container)) {
    Write-Log "Le dossier analysis n'existe pas : $analysisPath" -Color "Red"
    exit 1
}

if (-not (Test-Path -Path $analyticsPath -PathType Container)) {
    Write-Log "Le dossier analytics n'existe pas : $analyticsPath" -Color "Red"
    exit 1
}

# CrÃ©er la nouvelle structure de dossiers
$newFolders = @(
    "code", # Pour l'analyse de code source
    "performance", # Pour l'analyse de performance
    "data", # Pour l'analyse de donnÃ©es
    "reporting", # Pour les rapports
    "integration", # Pour l'intÃ©gration avec des outils tiers
    "roadmap", # Pour les scripts liÃ©s Ã  la roadmap
    "common" # Pour les modules et outils communs
)

Write-Log "CrÃ©ation de la nouvelle structure de dossiers..." -Color "Cyan"

foreach ($folder in $newFolders) {
    $folderPath = Join-Path -Path $unifiedPath -ChildPath $folder

    if (-not (Test-Path -Path $folderPath)) {
        if ($DryRun) {
            Write-Log "[DRYRUN] CrÃ©ation du dossier : $folderPath" -Color "Yellow"
        } else {
            if ($PSCmdlet.ShouldProcess($folderPath, "CrÃ©er le dossier")) {
                New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
                Write-Log "Dossier crÃ©Ã© : $folderPath" -Color "Green"
            }
        }
    } else {
        Write-Log "Le dossier existe dÃ©jÃ  : $folderPath" -Color "Gray"
    }
}

# DÃ©finir les mappages de fichiers
$fileMappings = @{
    # DÃ©placer les scripts d'analyse de code
    "$analysisPath\Start-CodeAnalysis.ps1"              = "$unifiedPath\code\Start-CodeAnalysis.ps1"
    "$analysisPath\Start-CachedCodeAnalysis.ps1"        = "$unifiedPath\code\Start-CachedCodeAnalysis.ps1"
    "$analysisPath\Invoke-CachedPSScriptAnalyzer.ps1"   = "$unifiedPath\code\Invoke-CachedPSScriptAnalyzer.ps1"
    "$analysisPath\Analyze-ScriptSimilarity.ps1"        = "$unifiedPath\code\Analyze-ScriptSimilarity.ps1"
    "$analysisPath\Classify-Scripts.ps1"                = "$unifiedPath\code\Classify-Scripts.ps1"
    "$analysisPath\Find-RedundantScripts.ps1"           = "$unifiedPath\code\Find-RedundantScripts.ps1"

    # DÃ©placer les scripts d'intÃ©gration
    "$analysisPath\Integrate-ThirdPartyTools.ps1"       = "$unifiedPath\integration\Integrate-ThirdPartyTools.ps1"
    "$analysisPath\Register-AnalysisPlugin.ps1"         = "$unifiedPath\integration\Register-AnalysisPlugin.ps1"

    # DÃ©placer les scripts de roadmap
    "$analysisPath\Update-RoadmapProgress.ps1"          = "$unifiedPath\roadmap\Update-RoadmapProgress.ps1"
    "$analysisPath\Update-RoadmapGlobalProgress.ps1"    = "$unifiedPath\roadmap\Update-RoadmapGlobalProgress.ps1"
    "$analysisPath\Update-RoadmapCheckboxes.ps1"        = "$unifiedPath\roadmap\Update-RoadmapCheckboxes.ps1"
    "$analysisPath\Update-RoadmapWithCachedResults.ps1" = "$unifiedPath\roadmap\Update-RoadmapWithCachedResults.ps1"
    "$analysisPath\Update-RoadmapWithInventory.ps1"     = "$unifiedPath\roadmap\Update-RoadmapWithInventory.ps1"
    "$analysisPath\Fix-RoadmapCheckboxes.ps1"           = "$unifiedPath\roadmap\Fix-RoadmapCheckboxes.ps1"

    # DÃ©placer les scripts d'utilitaires
    "$analysisPath\Fix-HtmlReportEncoding.ps1"          = "$unifiedPath\reporting\Fix-HtmlReportEncoding.ps1"
    "$analysisPath\Merge-AnalysisResults.ps1"           = "$unifiedPath\reporting\Merge-AnalysisResults.ps1"
    "$analysisPath\Start-CachedAnalysis.ps1"            = "$unifiedPath\common\Start-CachedAnalysis.ps1"

    # DÃ©placer les scripts d'analytics
    "$analyticsPath\anomaly_detection.ps1"              = "$unifiedPath\data\Detect-Anomalies.ps1"
    "$analyticsPath\correlation_analysis.ps1"           = "$unifiedPath\data\Analyze-Correlations.ps1"
    "$analyticsPath\trend_analysis.ps1"                 = "$unifiedPath\data\Analyze-Trends.ps1"
    "$analyticsPath\data_preparation.ps1"               = "$unifiedPath\data\Prepare-AnalysisData.ps1"

    # DÃ©placer les scripts de KPI
    "$analyticsPath\application_kpi_calculator.ps1"     = "$unifiedPath\performance\Calculate-ApplicationKPIs.ps1"
    "$analyticsPath\business_kpi_calculator.ps1"        = "$unifiedPath\performance\Calculate-BusinessKPIs.ps1"
    "$analyticsPath\system_kpi_calculator.ps1"          = "$unifiedPath\performance\Calculate-SystemKPIs.ps1"

    # DÃ©placer les scripts d'alerte
    "$analyticsPath\alert_configuration_manager.ps1"    = "$unifiedPath\performance\Manage-AlertConfigurations.ps1"
    "$analyticsPath\alert_thresholds_manager.ps1"       = "$unifiedPath\performance\Manage-AlertThresholds.ps1"
}

# Fonction pour dÃ©placer un fichier
function Move-FileToNewLocation {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [string]$SourceFile,
        [string]$DestinationPath
    )

    if (-not (Test-Path -Path $SourceFile)) {
        Write-Log "Le fichier source n'existe pas : $SourceFile" -Color "Yellow"
        return
    }

    $destinationDir = Split-Path -Path $DestinationPath -Parent
    if (-not (Test-Path -Path $destinationDir)) {
        if ($DryRun) {
            Write-Log "[DRYRUN] CrÃ©ation du rÃ©pertoire : $destinationDir" -Color "Yellow"
        } else {
            if ($PSCmdlet.ShouldProcess($destinationDir, "CrÃ©er le rÃ©pertoire")) {
                New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
                Write-Log "RÃ©pertoire crÃ©Ã© : $destinationDir" -Color "Green"
            }
        }
    }

    if (Test-Path -Path $DestinationPath) {
        if ($Force) {
            $shouldContinue = $true
        } else {
            $shouldContinue = $PSCmdlet.ShouldContinue("Le fichier existe dÃ©jÃ  : $DestinationPath. Voulez-vous le remplacer ?", "Confirmation")
        }
    } else {
        $shouldContinue = $true
    }

    if ($shouldContinue) {
        if ($DryRun) {
            Write-Log "[DRYRUN] DÃ©placement du fichier : $SourceFile -> $DestinationPath" -Color "Yellow"
        } else {
            if ($PSCmdlet.ShouldProcess($SourceFile, "DÃ©placer vers $DestinationPath")) {
                # Utiliser Copy-Item puis Remove-Item pour simuler un Move-Item avec crÃ©ation de dossiers parents
                Copy-Item -Path $SourceFile -Destination $DestinationPath -Force
                Write-Log "Fichier copiÃ© : $SourceFile -> $DestinationPath" -Color "Green"

                # Ne pas supprimer le fichier source pour l'instant
            }
        }
    } else {
        Write-Log "DÃ©placement ignorÃ© : $SourceFile" -Color "Gray"
    }
}

# DÃ©placer les fichiers selon les mappages
Write-Log "DÃ©placement des fichiers selon les mappages..." -Color "Cyan"

foreach ($sourceFile in $fileMappings.Keys) {
    $destinationPath = $fileMappings[$sourceFile]
    Move-FileToNewLocation -SourceFile $sourceFile -DestinationPath $destinationPath
}

# DÃ©placer les modules et outils communs
Write-Log "DÃ©placement des modules et outils communs..." -Color "Cyan"

if (Test-Path -Path "$analysisPath\modules") {
    if ($DryRun) {
        Write-Log "[DRYRUN] DÃ©placement du dossier modules : $analysisPath\modules -> $unifiedPath\common\modules" -Color "Yellow"
    } else {
        if ($PSCmdlet.ShouldProcess("$analysisPath\modules", "DÃ©placer vers $unifiedPath\common\modules")) {
            Copy-Item -Path "$analysisPath\modules" -Destination "$unifiedPath\common\modules" -Recurse -Force
            Write-Log "Dossier modules copiÃ© : $analysisPath\modules -> $unifiedPath\common\modules" -Color "Green"
        }
    }
}

if (Test-Path -Path "$analysisPath\tools") {
    if ($DryRun) {
        Write-Log "[DRYRUN] DÃ©placement du dossier tools : $analysisPath\tools -> $unifiedPath\common\tools" -Color "Yellow"
    } else {
        if ($PSCmdlet.ShouldProcess("$analysisPath\tools", "DÃ©placer vers $unifiedPath\common\tools")) {
            Copy-Item -Path "$analysisPath\tools" -Destination "$unifiedPath\common\tools" -Recurse -Force
            Write-Log "Dossier tools copiÃ© : $analysisPath\tools -> $unifiedPath\common\tools" -Color "Green"
        }
    }
}

if (Test-Path -Path "$analysisPath\plugins") {
    if ($DryRun) {
        Write-Log "[DRYRUN] DÃ©placement du dossier plugins : $analysisPath\plugins -> $unifiedPath\common\plugins" -Color "Yellow"
    } else {
        if ($PSCmdlet.ShouldProcess("$analysisPath\plugins", "DÃ©placer vers $unifiedPath\common\plugins")) {
            Copy-Item -Path "$analysisPath\plugins" -Destination "$unifiedPath\common\plugins" -Recurse -Force
            Write-Log "Dossier plugins copiÃ© : $analysisPath\plugins -> $unifiedPath\common\plugins" -Color "Green"
        }
    }
}

# DÃ©placer la documentation
Write-Log "DÃ©placement de la documentation..." -Color "Cyan"

if (Test-Path -Path "$analysisPath\docs") {
    if ($DryRun) {
        Write-Log "[DRYRUN] DÃ©placement du dossier docs : $analysisPath\docs -> $unifiedPath\docs" -Color "Yellow"
    } else {
        if ($PSCmdlet.ShouldProcess("$analysisPath\docs", "DÃ©placer vers $unifiedPath\docs")) {
            Copy-Item -Path "$analysisPath\docs" -Destination "$unifiedPath\docs" -Recurse -Force
            Write-Log "Dossier docs copiÃ© : $analysisPath\docs -> $unifiedPath\docs" -Color "Green"
        }
    }
}

# CrÃ©er un README.md pour le dossier unifiÃ©
$readmePath = Join-Path -Path $unifiedPath -ChildPath "README.md"
$readmeContent = @"
# SystÃ¨me d'Analyse UnifiÃ©

Ce rÃ©pertoire contient des scripts pour l'analyse de code, de performance et de donnÃ©es, ainsi que des outils d'intÃ©gration et de reporting.

## Structure

- **code/** - Scripts d'analyse de code source
- **performance/** - Scripts d'analyse de performance
- **data/** - Scripts d'analyse de donnÃ©es
- **reporting/** - Scripts de gÃ©nÃ©ration de rapports
- **integration/** - Scripts d'intÃ©gration avec des outils tiers
- **roadmap/** - Scripts de mise Ã  jour de la roadmap
- **common/** - Modules et outils communs
- **docs/** - Documentation

## Utilisation

### Analyse de Code

```powershell
.\code\Start-CodeAnalysis.ps1 -Path ".\development\scripts" -Tools PSScriptAnalyzer -GenerateHtmlReport -Recurse
```

### Analyse de Performance

```powershell
.\performance\Calculate-SystemKPIs.ps1 -DataPath "data/performance" -OutputPath "data/analysis"
```

### Analyse de DonnÃ©es

```powershell
.\data\Detect-Anomalies.ps1 -DataPath "data/performance" -OutputPath "data/analysis"
```

### Mise Ã  Jour de la Roadmap

```powershell
.\roadmap\Update-RoadmapProgress.ps1 -Path ".\projet\roadmaps\roadmap_complete_converted.md"
```

## Documentation

Consultez le dossier `docs/` pour plus d'informations sur l'utilisation des diffÃ©rents scripts et outils.
"@

if ($DryRun) {
    Write-Log "[DRYRUN] CrÃ©ation du fichier README.md : $readmePath" -Color "Yellow"
} else {
    if ($PSCmdlet.ShouldProcess($readmePath, "CrÃ©er le fichier README.md")) {
        Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
        Write-Log "Fichier README.md crÃ©Ã© : $readmePath" -Color "Green"
    }
}

# CrÃ©er un README.md pour chaque sous-dossier
$subfolderReadmes = @{
    "code"        = @"
# Analyse de Code

Ce dossier contient des scripts pour l'analyse de code source avec diffÃ©rents outils.

## Scripts disponibles

- **Start-CodeAnalysis.ps1** - Script principal pour l'analyse de code
- **Start-CachedCodeAnalysis.ps1** - Version avec mise en cache des rÃ©sultats
- **Invoke-CachedPSScriptAnalyzer.ps1** - Analyse avec PSScriptAnalyzer et mise en cache
- **Analyze-ScriptSimilarity.ps1** - Analyse de similaritÃ© entre scripts
- **Classify-Scripts.ps1** - Classification des scripts par fonctionnalitÃ©
- **Find-RedundantScripts.ps1** - DÃ©tection de scripts redondants

## Exemples d'utilisation

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\development\scripts" -Tools PSScriptAnalyzer -GenerateHtmlReport -Recurse
```
"@

    "performance" = @"
# Analyse de Performance

Ce dossier contient des scripts pour l'analyse de performance et le calcul de KPIs.

## Scripts disponibles

- **Calculate-ApplicationKPIs.ps1** - Calcul des KPIs d'application
- **Calculate-BusinessKPIs.ps1** - Calcul des KPIs mÃ©tier
- **Calculate-SystemKPIs.ps1** - Calcul des KPIs systÃ¨me
- **Manage-AlertConfigurations.ps1** - Gestion des configurations d'alerte
- **Manage-AlertThresholds.ps1** - Gestion des seuils d'alerte

## Exemples d'utilisation

```powershell
.\Calculate-SystemKPIs.ps1 -DataPath "data/performance" -OutputPath "data/analysis"
```
"@

    "data"        = @"
# Analyse de DonnÃ©es

Ce dossier contient des scripts pour l'analyse de donnÃ©es et la dÃ©tection d'anomalies.

## Scripts disponibles

- **Detect-Anomalies.ps1** - DÃ©tection d'anomalies dans les donnÃ©es
- **Analyze-Correlations.ps1** - Analyse de corrÃ©lations entre mÃ©triques
- **Analyze-Trends.ps1** - Analyse de tendances dans les donnÃ©es
- **Prepare-AnalysisData.ps1** - PrÃ©paration des donnÃ©es pour l'analyse

## Exemples d'utilisation

```powershell
.\Detect-Anomalies.ps1 -DataPath "data/performance" -OutputPath "data/analysis"
```
"@

    "reporting"   = @"
# Reporting

Ce dossier contient des scripts pour la gÃ©nÃ©ration et la gestion de rapports.

## Scripts disponibles

- **Fix-HtmlReportEncoding.ps1** - Correction des problÃ¨mes d'encodage dans les rapports HTML
- **Merge-AnalysisResults.ps1** - Fusion des rÃ©sultats d'analyse de diffÃ©rents outils

## Exemples d'utilisation

```powershell
.\Fix-HtmlReportEncoding.ps1 -Path ".\results\report.html"
```
"@

    "integration" = @"
# IntÃ©gration

Ce dossier contient des scripts pour l'intÃ©gration avec des outils tiers.

## Scripts disponibles

- **Integrate-ThirdPartyTools.ps1** - IntÃ©gration des rÃ©sultats d'analyse avec des outils tiers
- **Register-AnalysisPlugin.ps1** - Enregistrement de plugins d'analyse

## Exemples d'utilisation

```powershell
.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool SonarQube -ApiKey "your-api-key" -ApiUrl "https://sonarqube.example.com/api" -ProjectKey "your-project-key"
```
"@

    "roadmap"     = @"
# Roadmap

Ce dossier contient des scripts pour la mise Ã  jour et la gestion de la roadmap.

## Scripts disponibles

- **Update-RoadmapProgress.ps1** - Mise Ã  jour de la progression dans la roadmap
- **Update-RoadmapGlobalProgress.ps1** - Mise Ã  jour de la progression globale
- **Update-RoadmapCheckboxes.ps1** - Mise Ã  jour des cases Ã  cocher dans la roadmap
- **Update-RoadmapWithCachedResults.ps1** - Mise Ã  jour avec des rÃ©sultats mis en cache
- **Update-RoadmapWithInventory.ps1** - Mise Ã  jour avec l'inventaire des fichiers
- **Fix-RoadmapCheckboxes.ps1** - Correction des cases Ã  cocher dans la roadmap

## Exemples d'utilisation

```powershell
.\Update-RoadmapProgress.ps1 -Path ".\projet\roadmaps\roadmap_complete_converted.md"
```
"@

    "common"      = @"
# Modules et Outils Communs

Ce dossier contient des modules et outils communs utilisÃ©s par les diffÃ©rents scripts d'analyse.

## Contenu

- **modules/** - Modules PowerShell rÃ©utilisables
- **tools/** - Outils d'intÃ©gration avec des outils tiers
- **plugins/** - Plugins d'analyse

## Scripts disponibles

- **Start-CachedAnalysis.ps1** - Script gÃ©nÃ©rique pour l'analyse avec mise en cache

## Exemples d'utilisation

```powershell
.\Start-CachedAnalysis.ps1 -Path ".\development\scripts" -Tool "PSScriptAnalyzer" -CachePath ".\cache"
```
"@
}

foreach ($folder in $newFolders) {
    $folderReadmePath = Join-Path -Path $unifiedPath -ChildPath "$folder\README.md"

    if (-not (Test-Path -Path $folderReadmePath) -or $Force) {
        if ($DryRun) {
            Write-Log "[DRYRUN] CrÃ©ation du fichier README.md : $folderReadmePath" -Color "Yellow"
        } else {
            if ($PSCmdlet.ShouldProcess($folderReadmePath, "CrÃ©er le fichier README.md")) {
                Set-Content -Path $folderReadmePath -Value $subfolderReadmes[$folder] -Encoding UTF8
                Write-Log "Fichier README.md crÃ©Ã© : $folderReadmePath" -Color "Green"
            }
        }
    } else {
        Write-Log "Le fichier README.md existe dÃ©jÃ  : $folderReadmePath" -Color "Gray"
    }
}

# CrÃ©er un fichier de redirection dans le dossier analytics
$redirectPath = Join-Path -Path $analyticsPath -ChildPath "README.md"
$redirectContent = @"
# Redirection

**Note importante**: Ce dossier a Ã©tÃ© consolidÃ© avec le dossier `development/scripts/analysis`.

Veuillez utiliser les scripts dans la nouvelle structure:

- Analyse de code: `development/scripts/analysis/code/`
- Analyse de performance: `development/scripts/analysis/performance/`
- Analyse de donnÃ©es: `development/scripts/analysis/data/`
- Reporting: `development/scripts/analysis/reporting/`
- IntÃ©gration: `development/scripts/analysis/integration/`
- Roadmap: `development/scripts/analysis/roadmap/`
- Modules et outils communs: `development/scripts/analysis/common/`

Cette redirection est temporaire et ce dossier sera supprimÃ© dans une future mise Ã  jour.
"@

if ($DryRun) {
    Write-Log "[DRYRUN] CrÃ©ation du fichier de redirection : $redirectPath" -Color "Yellow"
} else {
    if ($PSCmdlet.ShouldProcess($redirectPath, "CrÃ©er le fichier de redirection")) {
        Set-Content -Path $redirectPath -Value $redirectContent -Encoding UTF8
        Write-Log "Fichier de redirection crÃ©Ã© : $redirectPath" -Color "Green"
    }
}

# RÃ©sumÃ© de la consolidation
Write-Log "Consolidation terminÃ©e." -Color "Cyan"
Write-Log "Les dossiers analysis et analytics ont Ã©tÃ© consolidÃ©s en une structure unifiÃ©e." -Color "Cyan"
Write-Log "Nouvelle structure : $unifiedPath" -Color "Cyan"

if ($LogFile) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== Consolidation terminÃ©e le $timestamp ===" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "Nouvelle structure : $unifiedPath" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8

    Write-Host "Log de consolidation enregistrÃ© dans : $LogFile" -ForegroundColor Cyan
}

# Avertissement final
Write-Log "IMPORTANT : Ce script a copiÃ© les fichiers vers la nouvelle structure, mais n'a pas supprimÃ© les fichiers originaux." -Color "Yellow"
Write-Log "Une fois que vous avez vÃ©rifiÃ© que tout fonctionne correctement, vous pouvez supprimer les fichiers originaux." -Color "Yellow"
Write-Log "Pour supprimer le dossier analytics, exÃ©cutez la commande suivante :" -Color "Yellow"
Write-Log "Remove-Item -Path '$analyticsPath' -Recurse -Force" -Color "Yellow"
