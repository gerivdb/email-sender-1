# Script pour convertir un plan de développement au format standard
# Version 1.0 - 2025-05-15
# Auteur: Augment Agent
# Description: Ce script convertit un plan de développement au format standard
#              défini dans le template plan-dev-template.txt.
param (
    [Parameter(Mandatory = $true)]
    [string]$PlanPath,

    [Parameter(Mandatory = $false)]
    [switch]$ArchiveOriginal = $true
)

# Configuration de l'encodage de la console
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Fonction pour écrire des messages de log
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        "INFO" { Write-Host $logMessage -ForegroundColor Cyan }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "DEBUG" { Write-Host $logMessage -ForegroundColor Gray }
    }
}

# Fonction pour archiver un fichier
function Backup-File {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        $fileName = [System.IO.Path]::GetFileName($FilePath)
        $directoryPath = [System.IO.Path]::GetDirectoryName($FilePath)
        $archivePath = Join-Path -Path $directoryPath -ChildPath "archive"

        # Créer le dossier d'archive s'il n'existe pas
        if (-not (Test-Path $archivePath)) {
            New-Item -ItemType Directory -Path $archivePath -Force | Out-Null
        }

        # Générer un nom de fichier unique avec timestamp
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $archiveFileName = [System.IO.Path]::GetFileNameWithoutExtension($fileName) + "-" + $timestamp + [System.IO.Path]::GetExtension($fileName)
        $archiveFilePath = Join-Path -Path $archivePath -ChildPath $archiveFileName

        # Copier le fichier dans le dossier d'archive
        Copy-Item -Path $FilePath -Destination $archiveFilePath -Force

        Write-Log "Fichier archivé : $archiveFilePath" -Level "INFO"
        return $true
    }
    catch {
        Write-Log "Erreur lors de l'archivage du fichier $FilePath : $_" -Level "ERROR"
        return $false
    }
}

# Fonction principale
try {
    Write-Log "Début de la conversion du plan $PlanPath..." -Level "INFO"

    # Vérifier si le fichier existe
    if (-not (Test-Path $PlanPath)) {
        Write-Log "Le fichier n'existe pas : $PlanPath" -Level "ERROR"
        exit 1
    }

    # Extraire les informations du fichier
    $fileName = [System.IO.Path]::GetFileName($PlanPath)
    $fileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($PlanPath)

    # Extraire la version du nom du fichier
    $version = "v1"
    if ($fileNameWithoutExt -match 'v(\d+)') {
        $version = "v" + $matches[1]
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $PlanPath -Raw -Encoding UTF8

    # Extraire le titre (première ligne commençant par #)
    $title = "Plan de développement"
    if ($content -match '# (.+?)(\r?\n|$)') {
        $title = $matches[1].Trim()
    }

    # Extraire la description (premier paragraphe après le titre)
    $description = "Plan de développement standardisé."
    if ($content -match '# .+?(\r?\n)+(.*?)(\r?\n\r?\n|$)') {
        $description = $matches[2].Trim()
    }

    # Déterminer le nombre de phases en fonction du contenu
    $phaseCount = ([regex]::Matches($content, '## \d+\.')).Count

    # Si aucune phase n'est détectée, utiliser 1 phase par défaut
    if ($phaseCount -eq 0) {
        $phaseCount = 1
    }

    # Limiter le nombre de phases à 6 (maximum autorisé)
    if ($phaseCount -gt 6) {
        Write-Log "Nombre de phases détecté ($phaseCount) supérieur à la limite (6). Limitation à 6 phases." -Level "WARNING"
        $phaseCount = 6
    }

    Write-Log "Informations extraites :" -Level "INFO"
    Write-Log "- Version : $version" -Level "INFO"
    Write-Log "- Titre : $title" -Level "INFO"
    Write-Log "- Description : $description" -Level "INFO"
    Write-Log "- Nombre de phases : $phaseCount" -Level "INFO"

    # Archiver le fichier original si demandé
    if ($ArchiveOriginal) {
        Backup-File -FilePath $PlanPath
    }

    # Vérifier si le script Generate-PlanDevFromFile.ps1 existe
    $scriptPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "Generate-PlanDevFromFile.ps1"

    if (-not (Test-Path $scriptPath)) {
        Write-Log "Le script de génération n'existe pas : $scriptPath" -Level "ERROR"
        exit 1
    }

    # Exécuter le script de génération
    Write-Log "Exécution du script $scriptPath..." -Level "INFO"

    & $scriptPath -Version $version -Title $title -Description $description -Phases $phaseCount

    if ($LASTEXITCODE -ne 0) {
        Write-Log "Erreur lors de la génération du nouveau plan" -Level "ERROR"
        exit 1
    }

    Write-Log "Conversion terminée avec succès." -Level "INFO"
    exit 0
}
catch {
    Write-Log "Erreur : $_" -Level "ERROR"
    exit 1
}
