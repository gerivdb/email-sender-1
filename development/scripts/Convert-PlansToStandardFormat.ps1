# Script pour convertir les plans de développement existants au format standard
# Version 1.0 - 2025-05-15
# Auteur: Augment Agent
# Description: Ce script convertit les plans de développement existants (v2 à v5) au format standard
#              défini dans le template plan-dev-template.txt.
param (
    [Parameter(Mandatory = $false)]
    [switch]$ArchiveOriginals = $true,

    [Parameter(Mandatory = $false)]
    [switch]$Force = $false
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

# Fonction pour nettoyer les caractères spéciaux dans le titre
function Get-SafeFileName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FileName
    )

    # Convertir en minuscules et remplacer les espaces par des tirets
    $safeFileName = $FileName.ToLower() -replace ' ', '-'

    # Remplacer les caractères invalides pour les noms de fichiers
    $safeFileName = $safeFileName -replace '[<>:"/\\|?*]', '_'

    return $safeFileName
}

# Fonction pour extraire le titre d'un fichier markdown
function Get-MarkdownTitle {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8

        # Rechercher le premier titre de niveau 1 (# Titre)
        if ($content -match '# (.+?)(\r?\n|$)') {
            return $matches[1].Trim()
        }

        # Si pas de titre de niveau 1, utiliser le nom du fichier
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        return $fileName
    } catch {
        Write-Log "Erreur lors de l'extraction du titre du fichier $FilePath : $_" -Level "ERROR"
        return [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    }
}

# Fonction pour extraire la description d'un fichier markdown
function Get-MarkdownDescription {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8

        # Rechercher le premier paragraphe après le titre
        if ($content -match '# .+?(\r?\n)+(.*?)(\r?\n\r?\n|$)') {
            return $matches[2].Trim()
        }

        # Si pas de description, retourner une description par défaut
        return "Plan de développement standardisé à partir du fichier original."
    } catch {
        Write-Log "Erreur lors de l'extraction de la description du fichier $FilePath : $_" -Level "ERROR"
        return "Plan de développement standardisé à partir du fichier original."
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
    } catch {
        Write-Log "Erreur lors de l'archivage du fichier $FilePath : $_" -Level "ERROR"
        return $false
    }
}

# Fonction principale pour convertir un plan
function Convert-PlanToStandardFormat {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$Archive = $true,

        [Parameter(Mandatory = $false)]
        [switch]$ForceOverwrite = $false
    )

    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path $FilePath)) {
            Write-Log "Le fichier n'existe pas : $FilePath" -Level "ERROR"
            return $false
        }

        # Extraire les informations du fichier
        $fileName = [System.IO.Path]::GetFileName($FilePath)
        $fileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)

        # Extraire la version du nom du fichier
        $version = "v1"
        if ($fileNameWithoutExt -match 'v(\d+)') {
            $version = "v" + $matches[1]
        }

        # Extraire le titre et la description
        $title = Get-MarkdownTitle -FilePath $FilePath
        $description = Get-MarkdownDescription -FilePath $FilePath

        # Déterminer le nombre de phases en fonction du contenu
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        $phaseCount = ([regex]::Matches($content, '## \d+\.')).Count

        # Si aucune phase n'est détectée, utiliser 1 phase par défaut
        if ($phaseCount -eq 0) {
            $phaseCount = 1
        }

        Write-Log "Conversion du plan $fileName (Version: $version, Titre: $title, Phases: $phaseCount)" -Level "INFO"

        # Archiver le fichier original si demandé
        if ($Archive) {
            Backup-File -FilePath $FilePath
        }

        # Générer le nouveau plan avec le script Generate-PlanDevFromFile.ps1
        $scriptPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "Generate-PlanDevFromFile.ps1"

        if (-not (Test-Path $scriptPath)) {
            Write-Log "Le script de génération n'existe pas : $scriptPath" -Level "ERROR"
            return $false
        }

        # Exécuter le script de génération
        $params = @{
            Version     = $version
            Title       = $title
            Description = $description
            Phases      = $phaseCount
        }

        Write-Log "Exécution du script $scriptPath avec les paramètres : $($params | ConvertTo-Json -Compress)" -Level "DEBUG"

        # Générer le nouveau plan
        $outputPath = & $scriptPath @params

        Write-Log "Résultat de la génération : $outputPath" -Level "DEBUG"

        if ([string]::IsNullOrEmpty($outputPath) -or -not (Test-Path $outputPath)) {
            Write-Log "Erreur lors de la génération du nouveau plan" -Level "ERROR"
            return $false
        }

        Write-Log "Plan converti avec succès : $outputPath" -Level "INFO"
        return $true
    } catch {
        Write-Log "Erreur lors de la conversion du plan $FilePath : $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour convertir tous les plans
function Convert-AllPlans {
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Archive = $true,

        [Parameter(Mandatory = $false)]
        [switch]$ForceOverwrite = $false
    )

    try {
        # Chemin du projet
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $projectPath = Split-Path -Parent (Split-Path -Parent $scriptPath)
        $plansPath = Join-Path -Path $projectPath -ChildPath "projet\roadmaps\plans"

        # Vérifier si le dossier des plans existe
        if (-not (Test-Path $plansPath)) {
            Write-Log "Le dossier des plans n'existe pas : $plansPath" -Level "ERROR"
            return $false
        }

        # Rechercher les plans v2 à v5
        $planFiles = Get-ChildItem -Path $plansPath -Filter "plan-dev-v[2-5]*.md"

        Write-Log "Recherche des plans dans $plansPath" -Level "DEBUG"
        Write-Log "Résultat de la recherche : $($planFiles | Select-Object FullName | ConvertTo-Json -Compress)" -Level "DEBUG"

        if ($planFiles.Count -eq 0) {
            Write-Log "Aucun plan v2 à v5 trouvé dans $plansPath" -Level "WARNING"
            return $true
        }

        Write-Log "Conversion de $($planFiles.Count) plans..." -Level "INFO"

        $successCount = 0

        # Convertir chaque plan
        foreach ($planFile in $planFiles) {
            $result = Convert-PlanToStandardFormat -FilePath $planFile.FullName -Archive:$Archive -ForceOverwrite:$ForceOverwrite

            if ($result) {
                $successCount++
            }
        }

        Write-Log "Conversion terminée. $successCount/$($planFiles.Count) plans convertis avec succès." -Level "INFO"
        return $true
    } catch {
        Write-Log "Erreur lors de la conversion des plans : $_" -Level "ERROR"
        return $false
    }
}

# Exécution principale
try {
    Write-Log "Début de la conversion des plans de développement..." -Level "INFO"

    # Vérifier si le script Generate-PlanDevFromFile.ps1 existe
    $scriptPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "Generate-PlanDevFromFile.ps1"

    if (-not (Test-Path $scriptPath)) {
        Write-Log "Le script de génération n'existe pas : $scriptPath" -Level "ERROR"
        exit 1
    }

    Write-Log "Script de génération trouvé : $scriptPath" -Level "INFO"

    # Vérifier si le template existe
    $templatePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) -ChildPath "development\templates\plan-dev-template.txt"

    if (-not (Test-Path $templatePath)) {
        Write-Log "Le fichier template n'existe pas : $templatePath" -Level "ERROR"
        exit 1
    }

    Write-Log "Template trouvé : $templatePath" -Level "INFO"

    # Exécuter la conversion
    $result = Convert-AllPlans -Archive:$ArchiveOriginals -ForceOverwrite:$Force

    if ($result) {
        Write-Log "Conversion des plans terminée avec succès." -Level "INFO"
        exit 0
    } else {
        Write-Log "Erreur lors de la conversion des plans." -Level "ERROR"
        exit 1
    }
} catch {
    Write-Log "Erreur : $_" -Level "ERROR"
    exit 1
}
