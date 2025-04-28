#Requires -Version 5.1
<#
.SYNOPSIS
    Consolide les dossiers analysis et analytics en une structure unifiée.
.DESCRIPTION
    Ce script fusionne les dossiers development/scripts/analysis et development/scripts/analytics
    en une structure unifiée et organisée, en éliminant la redondance tout en préservant
    les fonctionnalités distinctes.
.PARAMETER DryRun
    Si spécifié, le script affiche les actions qui seraient effectuées sans les exécuter.
.PARAMETER Force
    Si spécifié, le script écrase les fichiers existants sans demander de confirmation.
.PARAMETER LogFile
    Chemin vers un fichier de log pour enregistrer les actions effectuées.
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

# Définir le répertoire racine du dépôt
$repoRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\"
$repoRoot = [System.IO.Path]::GetFullPath($repoRoot)

# Vérifier que le répertoire racine existe
if (-not (Test-Path -Path $repoRoot -PathType Container)) {
    throw "Le répertoire racine n'existe pas : $repoRoot"
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
    "=== Consolidation des dossiers analysis et analytics démarrée le $timestamp ===" | Out-File -FilePath $LogFile -Encoding UTF8
    "Répertoire racine: $repoRoot" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# Définir les chemins des dossiers source et destination
$analysisPath = Join-Path -Path $repoRoot -ChildPath "development\scripts\analysis"
$analyticsPath = Join-Path -Path $repoRoot -ChildPath "development\scripts\analytics"
$unifiedPath = Join-Path -Path $repoRoot -ChildPath "development\scripts\analysis"

# Vérifier que les dossiers source existent
if (-not (Test-Path -Path $analysisPath -PathType Container)) {
    Write-Log "Le dossier analysis n'existe pas : $analysisPath" -Color "Red"
    exit 1
}

if (-not (Test-Path -Path $analyticsPath -PathType Container)) {
    Write-Log "Le dossier analytics n'existe pas : $analyticsPath" -Color "Red"
    exit 1
}

# Créer la nouvelle structure de dossiers
$newFolders = @(
    "code", # Pour l'analyse de code source
    "performance", # Pour l'analyse de performance
    "data", # Pour l'analyse de données
    "reporting", # Pour les rapports
    "integration", # Pour l'intégration avec des outils tiers
    "roadmap", # Pour les scripts liés à la roadmap
    "common" # Pour les modules et outils communs
)

Write-Log "Création de la nouvelle structure de dossiers..." -Color "Cyan"

foreach ($folder in $newFolders) {
    $folderPath = Join-Path -Path $unifiedPath -ChildPath $folder

    if (-not (Test-Path -Path $folderPath)) {
        if ($DryRun) {
            Write-Log "[DRYRUN] Création du dossier : $folderPath" -Color "Yellow"
        } else {
            if ($PSCmdlet.ShouldProcess($folderPath, "Créer le dossier")) {
                New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
                Write-Log "Dossier créé : $folderPath" -Color "Green"
            }
        }
    } else {
        Write-Log "Le dossier existe déjà : $folderPath" -Color "Gray"
    }
}

# Définir les mappages de fichiers
$fileMappings = @{
    # Déplacer les scripts d'analyse de code
    "$analysisPath\Start-CodeAnalysis.ps1"              = "$unifiedPath\code\Start-CodeAnalysis.ps1"
    "$analysisPath\Start-CachedCodeAnalysis.ps1"        = "$unifiedPath\code\Start-CachedCodeAnalysis.ps1"
    "$analysisPath\Invoke-CachedPSScriptAnalyzer.ps1"   = "$unifiedPath\code\Invoke-CachedPSScriptAnalyzer.ps1"
    "$analysisPath\Analyze-ScriptSimilarity.ps1"        = "$unifiedPath\code\Analyze-ScriptSimilarity.ps1"
    "$analysisPath\Classify-Scripts.ps1"                = "$unifiedPath\code\Classify-Scripts.ps1"
    "$analysisPath\Find-RedundantScripts.ps1"           = "$unifiedPath\code\Find-RedundantScripts.ps1"

    # Déplacer les scripts d'intégration
    "$analysisPath\Integrate-ThirdPartyTools.ps1"       = "$unifiedPath\integration\Integrate-ThirdPartyTools.ps1"
    "$analysisPath\Register-AnalysisPlugin.ps1"         = "$unifiedPath\integration\Register-AnalysisPlugin.ps1"

    # Déplacer les scripts de roadmap
    "$analysisPath\Update-RoadmapProgress.ps1"          = "$unifiedPath\roadmap\Update-RoadmapProgress.ps1"
    "$analysisPath\Update-RoadmapGlobalProgress.ps1"    = "$unifiedPath\roadmap\Update-RoadmapGlobalProgress.ps1"
    "$analysisPath\Update-RoadmapCheckboxes.ps1"        = "$unifiedPath\roadmap\Update-RoadmapCheckboxes.ps1"
    "$analysisPath\Update-RoadmapWithCachedResults.ps1" = "$unifiedPath\roadmap\Update-RoadmapWithCachedResults.ps1"
    "$analysisPath\Update-RoadmapWithInventory.ps1"     = "$unifiedPath\roadmap\Update-RoadmapWithInventory.ps1"
    "$analysisPath\Fix-RoadmapCheckboxes.ps1"           = "$unifiedPath\roadmap\Fix-RoadmapCheckboxes.ps1"

    # Déplacer les scripts d'utilitaires
    "$analysisPath\Fix-HtmlReportEncoding.ps1"          = "$unifiedPath\reporting\Fix-HtmlReportEncoding.ps1"
    "$analysisPath\Merge-AnalysisResults.ps1"           = "$unifiedPath\reporting\Merge-AnalysisResults.ps1"
    "$analysisPath\Start-CachedAnalysis.ps1"            = "$unifiedPath\common\Start-CachedAnalysis.ps1"

    # Déplacer les scripts d'analytics
    "$analyticsPath\anomaly_detection.ps1"              = "$unifiedPath\data\Detect-Anomalies.ps1"
    "$analyticsPath\correlation_analysis.ps1"           = "$unifiedPath\data\Analyze-Correlations.ps1"
    "$analyticsPath\trend_analysis.ps1"                 = "$unifiedPath\data\Analyze-Trends.ps1"
    "$analyticsPath\data_preparation.ps1"               = "$unifiedPath\data\Prepare-AnalysisData.ps1"

    # Déplacer les scripts de KPI
    "$analyticsPath\application_kpi_calculator.ps1"     = "$unifiedPath\performance\Calculate-ApplicationKPIs.ps1"
    "$analyticsPath\business_kpi_calculator.ps1"        = "$unifiedPath\performance\Calculate-BusinessKPIs.ps1"
    "$analyticsPath\system_kpi_calculator.ps1"          = "$unifiedPath\performance\Calculate-SystemKPIs.ps1"

    # Déplacer les scripts d'alerte
    "$analyticsPath\alert_configuration_manager.ps1"    = "$unifiedPath\performance\Manage-AlertConfigurations.ps1"
    "$analyticsPath\alert_thresholds_manager.ps1"       = "$unifiedPath\performance\Manage-AlertThresholds.ps1"
}

# Fonction pour déplacer un fichier
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
            Write-Log "[DRYRUN] Création du répertoire : $destinationDir" -Color "Yellow"
        } else {
            if ($PSCmdlet.ShouldProcess($destinationDir, "Créer le répertoire")) {
                New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
                Write-Log "Répertoire créé : $destinationDir" -Color "Green"
            }
        }
    }

    if (Test-Path -Path $DestinationPath) {
        if ($Force) {
            $shouldContinue = $true
        } else {
            $shouldContinue = $PSCmdlet.ShouldContinue("Le fichier existe déjà : $DestinationPath. Voulez-vous le remplacer ?", "Confirmation")
        }
    } else {
        $shouldContinue = $true
    }

    if ($shouldContinue) {
        if ($DryRun) {
            Write-Log "[DRYRUN] Déplacement du fichier : $SourceFile -> $DestinationPath" -Color "Yellow"
        } else {
            if ($PSCmdlet.ShouldProcess($SourceFile, "Déplacer vers $DestinationPath")) {
                # Utiliser Copy-Item puis Remove-Item pour simuler un Move-Item avec création de dossiers parents
                Copy-Item -Path $SourceFile -Destination $DestinationPath -Force
                Write-Log "Fichier copié : $SourceFile -> $DestinationPath" -Color "Green"

                # Ne pas supprimer le fichier source pour l'instant
            }
        }
    } else {
        Write-Log "Déplacement ignoré : $SourceFile" -Color "Gray"
    }
}

# Déplacer les fichiers selon les mappages
Write-Log "Déplacement des fichiers selon les mappages..." -Color "Cyan"

foreach ($sourceFile in $fileMappings.Keys) {
    $destinationPath = $fileMappings[$sourceFile]
    Move-FileToNewLocation -SourceFile $sourceFile -DestinationPath $destinationPath
}

# Déplacer les modules et outils communs
Write-Log "Déplacement des modules et outils communs..." -Color "Cyan"

if (Test-Path -Path "$analysisPath\modules") {
    if ($DryRun) {
        Write-Log "[DRYRUN] Déplacement du dossier modules : $analysisPath\modules -> $unifiedPath\common\modules" -Color "Yellow"
    } else {
        if ($PSCmdlet.ShouldProcess("$analysisPath\modules", "Déplacer vers $unifiedPath\common\modules")) {
            Copy-Item -Path "$analysisPath\modules" -Destination "$unifiedPath\common\modules" -Recurse -Force
            Write-Log "Dossier modules copié : $analysisPath\modules -> $unifiedPath\common\modules" -Color "Green"
        }
    }
}

if (Test-Path -Path "$analysisPath\tools") {
    if ($DryRun) {
        Write-Log "[DRYRUN] Déplacement du dossier tools : $analysisPath\tools -> $unifiedPath\common\tools" -Color "Yellow"
    } else {
        if ($PSCmdlet.ShouldProcess("$analysisPath\tools", "Déplacer vers $unifiedPath\common\tools")) {
            Copy-Item -Path "$analysisPath\tools" -Destination "$unifiedPath\common\tools" -Recurse -Force
            Write-Log "Dossier tools copié : $analysisPath\tools -> $unifiedPath\common\tools" -Color "Green"
        }
    }
}

if (Test-Path -Path "$analysisPath\plugins") {
    if ($DryRun) {
        Write-Log "[DRYRUN] Déplacement du dossier plugins : $analysisPath\plugins -> $unifiedPath\common\plugins" -Color "Yellow"
    } else {
        if ($PSCmdlet.ShouldProcess("$analysisPath\plugins", "Déplacer vers $unifiedPath\common\plugins")) {
            Copy-Item -Path "$analysisPath\plugins" -Destination "$unifiedPath\common\plugins" -Recurse -Force
            Write-Log "Dossier plugins copié : $analysisPath\plugins -> $unifiedPath\common\plugins" -Color "Green"
        }
    }
}

# Déplacer la documentation
Write-Log "Déplacement de la documentation..." -Color "Cyan"

if (Test-Path -Path "$analysisPath\docs") {
    if ($DryRun) {
        Write-Log "[DRYRUN] Déplacement du dossier docs : $analysisPath\docs -> $unifiedPath\docs" -Color "Yellow"
    } else {
        if ($PSCmdlet.ShouldProcess("$analysisPath\docs", "Déplacer vers $unifiedPath\docs")) {
            Copy-Item -Path "$analysisPath\docs" -Destination "$unifiedPath\docs" -Recurse -Force
            Write-Log "Dossier docs copié : $analysisPath\docs -> $unifiedPath\docs" -Color "Green"
        }
    }
}

# Créer un README.md pour le dossier unifié
$readmePath = Join-Path -Path $unifiedPath -ChildPath "README.md"
$readmeContent = @"
# Système d'Analyse Unifié

Ce répertoire contient des scripts pour l'analyse de code, de performance et de données, ainsi que des outils d'intégration et de reporting.

## Structure

- **code/** - Scripts d'analyse de code source
- **performance/** - Scripts d'analyse de performance
- **data/** - Scripts d'analyse de données
- **reporting/** - Scripts de génération de rapports
- **integration/** - Scripts d'intégration avec des outils tiers
- **roadmap/** - Scripts de mise à jour de la roadmap
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

### Analyse de Données

```powershell
.\data\Detect-Anomalies.ps1 -DataPath "data/performance" -OutputPath "data/analysis"
```

### Mise à Jour de la Roadmap

```powershell
.\roadmap\Update-RoadmapProgress.ps1 -Path ".\projet\roadmaps\roadmap_complete_converted.md"
```

## Documentation

Consultez le dossier `docs/` pour plus d'informations sur l'utilisation des différents scripts et outils.
"@

if ($DryRun) {
    Write-Log "[DRYRUN] Création du fichier README.md : $readmePath" -Color "Yellow"
} else {
    if ($PSCmdlet.ShouldProcess($readmePath, "Créer le fichier README.md")) {
        Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
        Write-Log "Fichier README.md créé : $readmePath" -Color "Green"
    }
}

# Créer un README.md pour chaque sous-dossier
$subfolderReadmes = @{
    "code"        = @"
# Analyse de Code

Ce dossier contient des scripts pour l'analyse de code source avec différents outils.

## Scripts disponibles

- **Start-CodeAnalysis.ps1** - Script principal pour l'analyse de code
- **Start-CachedCodeAnalysis.ps1** - Version avec mise en cache des résultats
- **Invoke-CachedPSScriptAnalyzer.ps1** - Analyse avec PSScriptAnalyzer et mise en cache
- **Analyze-ScriptSimilarity.ps1** - Analyse de similarité entre scripts
- **Classify-Scripts.ps1** - Classification des scripts par fonctionnalité
- **Find-RedundantScripts.ps1** - Détection de scripts redondants

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
- **Calculate-BusinessKPIs.ps1** - Calcul des KPIs métier
- **Calculate-SystemKPIs.ps1** - Calcul des KPIs système
- **Manage-AlertConfigurations.ps1** - Gestion des configurations d'alerte
- **Manage-AlertThresholds.ps1** - Gestion des seuils d'alerte

## Exemples d'utilisation

```powershell
.\Calculate-SystemKPIs.ps1 -DataPath "data/performance" -OutputPath "data/analysis"
```
"@

    "data"        = @"
# Analyse de Données

Ce dossier contient des scripts pour l'analyse de données et la détection d'anomalies.

## Scripts disponibles

- **Detect-Anomalies.ps1** - Détection d'anomalies dans les données
- **Analyze-Correlations.ps1** - Analyse de corrélations entre métriques
- **Analyze-Trends.ps1** - Analyse de tendances dans les données
- **Prepare-AnalysisData.ps1** - Préparation des données pour l'analyse

## Exemples d'utilisation

```powershell
.\Detect-Anomalies.ps1 -DataPath "data/performance" -OutputPath "data/analysis"
```
"@

    "reporting"   = @"
# Reporting

Ce dossier contient des scripts pour la génération et la gestion de rapports.

## Scripts disponibles

- **Fix-HtmlReportEncoding.ps1** - Correction des problèmes d'encodage dans les rapports HTML
- **Merge-AnalysisResults.ps1** - Fusion des résultats d'analyse de différents outils

## Exemples d'utilisation

```powershell
.\Fix-HtmlReportEncoding.ps1 -Path ".\results\report.html"
```
"@

    "integration" = @"
# Intégration

Ce dossier contient des scripts pour l'intégration avec des outils tiers.

## Scripts disponibles

- **Integrate-ThirdPartyTools.ps1** - Intégration des résultats d'analyse avec des outils tiers
- **Register-AnalysisPlugin.ps1** - Enregistrement de plugins d'analyse

## Exemples d'utilisation

```powershell
.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool SonarQube -ApiKey "your-api-key" -ApiUrl "https://sonarqube.example.com/api" -ProjectKey "your-project-key"
```
"@

    "roadmap"     = @"
# Roadmap

Ce dossier contient des scripts pour la mise à jour et la gestion de la roadmap.

## Scripts disponibles

- **Update-RoadmapProgress.ps1** - Mise à jour de la progression dans la roadmap
- **Update-RoadmapGlobalProgress.ps1** - Mise à jour de la progression globale
- **Update-RoadmapCheckboxes.ps1** - Mise à jour des cases à cocher dans la roadmap
- **Update-RoadmapWithCachedResults.ps1** - Mise à jour avec des résultats mis en cache
- **Update-RoadmapWithInventory.ps1** - Mise à jour avec l'inventaire des fichiers
- **Fix-RoadmapCheckboxes.ps1** - Correction des cases à cocher dans la roadmap

## Exemples d'utilisation

```powershell
.\Update-RoadmapProgress.ps1 -Path ".\projet\roadmaps\roadmap_complete_converted.md"
```
"@

    "common"      = @"
# Modules et Outils Communs

Ce dossier contient des modules et outils communs utilisés par les différents scripts d'analyse.

## Contenu

- **modules/** - Modules PowerShell réutilisables
- **tools/** - Outils d'intégration avec des outils tiers
- **plugins/** - Plugins d'analyse

## Scripts disponibles

- **Start-CachedAnalysis.ps1** - Script générique pour l'analyse avec mise en cache

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
            Write-Log "[DRYRUN] Création du fichier README.md : $folderReadmePath" -Color "Yellow"
        } else {
            if ($PSCmdlet.ShouldProcess($folderReadmePath, "Créer le fichier README.md")) {
                Set-Content -Path $folderReadmePath -Value $subfolderReadmes[$folder] -Encoding UTF8
                Write-Log "Fichier README.md créé : $folderReadmePath" -Color "Green"
            }
        }
    } else {
        Write-Log "Le fichier README.md existe déjà : $folderReadmePath" -Color "Gray"
    }
}

# Créer un fichier de redirection dans le dossier analytics
$redirectPath = Join-Path -Path $analyticsPath -ChildPath "README.md"
$redirectContent = @"
# Redirection

**Note importante**: Ce dossier a été consolidé avec le dossier `development/scripts/analysis`.

Veuillez utiliser les scripts dans la nouvelle structure:

- Analyse de code: `development/scripts/analysis/code/`
- Analyse de performance: `development/scripts/analysis/performance/`
- Analyse de données: `development/scripts/analysis/data/`
- Reporting: `development/scripts/analysis/reporting/`
- Intégration: `development/scripts/analysis/integration/`
- Roadmap: `development/scripts/analysis/roadmap/`
- Modules et outils communs: `development/scripts/analysis/common/`

Cette redirection est temporaire et ce dossier sera supprimé dans une future mise à jour.
"@

if ($DryRun) {
    Write-Log "[DRYRUN] Création du fichier de redirection : $redirectPath" -Color "Yellow"
} else {
    if ($PSCmdlet.ShouldProcess($redirectPath, "Créer le fichier de redirection")) {
        Set-Content -Path $redirectPath -Value $redirectContent -Encoding UTF8
        Write-Log "Fichier de redirection créé : $redirectPath" -Color "Green"
    }
}

# Résumé de la consolidation
Write-Log "Consolidation terminée." -Color "Cyan"
Write-Log "Les dossiers analysis et analytics ont été consolidés en une structure unifiée." -Color "Cyan"
Write-Log "Nouvelle structure : $unifiedPath" -Color "Cyan"

if ($LogFile) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== Consolidation terminée le $timestamp ===" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "Nouvelle structure : $unifiedPath" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8

    Write-Host "Log de consolidation enregistré dans : $LogFile" -ForegroundColor Cyan
}

# Avertissement final
Write-Log "IMPORTANT : Ce script a copié les fichiers vers la nouvelle structure, mais n'a pas supprimé les fichiers originaux." -Color "Yellow"
Write-Log "Une fois que vous avez vérifié que tout fonctionne correctement, vous pouvez supprimer les fichiers originaux." -Color "Yellow"
Write-Log "Pour supprimer le dossier analytics, exécutez la commande suivante :" -Color "Yellow"
Write-Log "Remove-Item -Path '$analyticsPath' -Recurse -Force" -Color "Yellow"
