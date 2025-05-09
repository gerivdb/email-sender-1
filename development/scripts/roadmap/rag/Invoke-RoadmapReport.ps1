# Invoke-RoadmapReport.ps1
# Script pour générer des rapports d'analyse sur les roadmaps
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet(
        "Completion", "Priority", "Progress",
        "Help"
    )]
    [string]$ReportType = "Help",
    
    [Parameter(Mandatory = $false)]
    [string]$FilterPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [string]$Collection = "roadmaps",
    
    [Parameter(Mandatory = $false)]
    [string]$Host = "localhost",
    
    [Parameter(Mandatory = $false)]
    [int]$Port = 6333,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "projet/roadmaps/reports",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("daily", "weekly", "monthly")]
    [string]$TimePeriod = "weekly",
    
    [Parameter(Mandatory = $false)]
    [switch]$OpenInBrowser,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction de journalisation simplifiée
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
    }
    
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message" -ForegroundColor $color
}

# Fonction pour afficher l'aide
function Show-Help {
    Write-Host "Invoke-RoadmapReport.ps1 - Script pour générer des rapports d'analyse sur les roadmaps"
    Write-Host ""
    Write-Host "SYNTAXE:"
    Write-Host "    .\Invoke-RoadmapReport.ps1 -ReportType <ReportType> [options]"
    Write-Host ""
    Write-Host "TYPES DE RAPPORTS:"
    Write-Host "    Completion   : Rapport sur le taux de complétion des tâches"
    Write-Host "    Priority     : Rapport sur la distribution des priorités"
    Write-Host "    Progress     : Rapport sur la progression des tâches"
    Write-Host "    Help         : Affiche cette aide"
    Write-Host ""
    Write-Host "OPTIONS:"
    Write-Host "    -FilterPath      : Fichier JSON contenant les filtres à appliquer"
    Write-Host "    -OutputPath      : Chemin vers le fichier de sortie"
    Write-Host "    -Collection      : Nom de la collection Qdrant (défaut: roadmaps)"
    Write-Host "    -Host            : Hôte du serveur Qdrant (défaut: localhost)"
    Write-Host "    -Port            : Port du serveur Qdrant (défaut: 6333)"
    Write-Host "    -OutputDirectory : Dossier de sortie pour les rapports (défaut: projet/roadmaps/reports)"
    Write-Host "    -TimePeriod      : Période de temps pour l'analyse de progression (daily, weekly, monthly) (défaut: weekly)"
    Write-Host "    -OpenInBrowser   : Ouvre le rapport généré dans le navigateur"
    Write-Host "    -Force           : Force l'écrasement des fichiers existants"
    Write-Host ""
    Write-Host "EXEMPLES:"
    Write-Host "    # Générer un rapport de complétion"
    Write-Host "    .\Invoke-RoadmapReport.ps1 -ReportType Completion -OutputPath 'projet/roadmaps/reports/completion_report.md'"
    Write-Host ""
    Write-Host "    # Générer un rapport de priorités avec filtrage"
    Write-Host "    .\Invoke-RoadmapReport.ps1 -ReportType Priority -FilterPath 'projet/roadmaps/filters/high_priority.json'"
    Write-Host ""
    Write-Host "    # Générer un rapport de progression"
    Write-Host "    .\Invoke-RoadmapReport.ps1 -ReportType Progress -TimePeriod monthly -OpenInBrowser"
}

# Fonction pour vérifier si Python est installé
function Test-PythonInstalled {
    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python (\d+\.\d+\.\d+)") {
            Write-Log "Python $($Matches[1]) trouvé." -Level "Info"
            return $true
        }
        else {
            Write-Log "Python non trouvé." -Level "Error"
            return $false
        }
    }
    catch {
        Write-Log "Python non trouvé." -Level "Error"
        return $false
    }
}

# Fonction pour vérifier si les dépendances Python sont installées
function Test-PythonDependencies {
    try {
        $output = python -c "import qdrant_client, matplotlib" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Dépendances Python trouvées." -Level "Info"
            return $true
        }
        else {
            Write-Log "Dépendances Python manquantes." -Level "Error"
            Write-Log "Installez-les avec: pip install qdrant-client matplotlib" -Level "Info"
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors de la vérification des dépendances Python: $_" -Level "Error"
        return $false
    }
}

# Fonction pour vérifier si Qdrant est en cours d'exécution
function Test-QdrantRunning {
    param (
        [string]$Host,
        [int]$Port
    )
    
    try {
        $response = Invoke-WebRequest -Uri "http://$Host:$Port/collections" -Method GET -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Log "Qdrant est en cours d'exécution sur $Host:$Port." -Level "Info"
            return $true
        }
        else {
            Write-Log "Qdrant n'est pas accessible sur $Host:$Port." -Level "Error"
            return $false
        }
    }
    catch {
        Write-Log "Qdrant n'est pas accessible sur $Host:$Port." -Level "Error"
        Write-Log "Assurez-vous que Qdrant est en cours d'exécution." -Level "Info"
        return $false
    }
}

# Fonction pour générer un rapport
function Invoke-GenerateReport {
    param (
        [string]$ReportType,
        [string]$FilterPath,
        [string]$OutputPath,
        [string]$Collection,
        [string]$Host,
        [int]$Port,
        [string]$OutputDirectory,
        [string]$TimePeriod,
        [switch]$Force
    )
    
    Write-Log "Génération du rapport $ReportType..." -Level "Info"
    
    # Vérifier si Python est installé
    if (-not (Test-PythonInstalled)) {
        return $null
    }
    
    # Vérifier si les dépendances Python sont installées
    if (-not (Test-PythonDependencies)) {
        return $null
    }
    
    # Vérifier si Qdrant est en cours d'exécution
    if (-not (Test-QdrantRunning -Host $Host -Port $Port)) {
        return $null
    }
    
    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputDirectory)) {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    }
    
    # Construire la commande Python
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Generate-RoadmapReport.py"
    
    # Convertir le type de rapport
    $pythonReportType = $ReportType.ToLower()
    
    $command = "python `"$scriptPath`" --report-type $pythonReportType"
    
    if ($FilterPath) {
        $command += " --filter-file `"$FilterPath`""
    }
    
    if ($OutputPath) {
        $command += " --output `"$OutputPath`""
    }
    
    $command += " --collection `"$Collection`" --host `"$Host`" --port $Port --output-dir `"$OutputDirectory`""
    
    if ($ReportType -eq "Progress") {
        $command += " --time-period $TimePeriod"
    }
    
    # Exécuter la commande
    Write-Log "Exécution de la commande: $command" -Level "Info"
    Invoke-Expression $command
    
    if ($LASTEXITCODE -eq 0) {
        # Déterminer le chemin vers le fichier généré
        $outputFileName = if ($OutputPath) {
            Split-Path -Path $OutputPath -Leaf
        }
        else {
            switch ($ReportType) {
                "Completion" { "completion_report.md" }
                "Priority" { "priority_report.md" }
                "Progress" { "progress_report.md" }
                default { "report.md" }
            }
        }
        
        $generatedFilePath = Join-Path -Path $OutputDirectory -ChildPath $outputFileName
        
        Write-Log "Rapport généré avec succès dans $generatedFilePath" -Level "Success"
        return $generatedFilePath
    }
    else {
        Write-Log "Erreur lors de la génération du rapport." -Level "Error"
        return $null
    }
}

# Fonction principale
function Invoke-RoadmapReport {
    param (
        [string]$ReportType,
        [string]$FilterPath,
        [string]$OutputPath,
        [string]$Collection,
        [string]$Host,
        [int]$Port,
        [string]$OutputDirectory,
        [string]$TimePeriod,
        [switch]$OpenInBrowser,
        [switch]$Force
    )
    
    # Exécuter l'action demandée
    switch ($ReportType) {
        "Completion" {
            $generatedFilePath = Invoke-GenerateReport -ReportType $ReportType -FilterPath $FilterPath -OutputPath $OutputPath -Collection $Collection -Host $Host -Port $Port -OutputDirectory $OutputDirectory -TimePeriod $TimePeriod -Force:$Force
            break
        }
        "Priority" {
            $generatedFilePath = Invoke-GenerateReport -ReportType $ReportType -FilterPath $FilterPath -OutputPath $OutputPath -Collection $Collection -Host $Host -Port $Port -OutputDirectory $OutputDirectory -TimePeriod $TimePeriod -Force:$Force
            break
        }
        "Progress" {
            $generatedFilePath = Invoke-GenerateReport -ReportType $ReportType -FilterPath $FilterPath -OutputPath $OutputPath -Collection $Collection -Host $Host -Port $Port -OutputDirectory $OutputDirectory -TimePeriod $TimePeriod -Force:$Force
            break
        }
        "Help" {
            Show-Help
            return $null
        }
        default {
            Write-Log "Type de rapport non reconnu : $ReportType" -Level "Error"
            Show-Help
            return $null
        }
    }
    
    # Ouvrir le rapport généré dans le navigateur si demandé
    if ($generatedFilePath -and $OpenInBrowser) {
        Write-Log "Ouverture du rapport dans le navigateur..." -Level "Info"
        Start-Process $generatedFilePath
    }
    
    return $generatedFilePath
}

# Exécution principale
try {
    $result = Invoke-RoadmapReport -ReportType $ReportType -FilterPath $FilterPath -OutputPath $OutputPath -Collection $Collection -Host $Host -Port $Port -OutputDirectory $OutputDirectory -TimePeriod $TimePeriod -OpenInBrowser:$OpenInBrowser -Force:$Force
    
    # Retourner le résultat
    return $result
}
catch {
    Write-Log "Erreur lors de la génération du rapport : $_" -Level "Error"
    throw $_
}
