# Script pour générer un nouveau plan de développement à partir de templates séparés
# Version 2.0 - 2025-05-15
# Auteur: Augment Agent
# Description: Ce script génère un nouveau plan de développement à partir de templates séparés,
#              avec support complet des caractères accentués.
param (
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [string]$Description,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 6)]
    [int]$Phases
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

# Fonction principale
function New-PlanDev {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 6)]
        [int]$Phases
    )

    try {
        # Chemin du projet (utilise le répertoire parent du script)
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $projectPath = Split-Path -Parent (Split-Path -Parent $scriptPath)

        Write-Log "Chemin du projet : $projectPath" -Level "DEBUG"

        # Chemins des templates
        $headerTemplatePath = Join-Path -Path $projectPath -ChildPath "development\templates\plan-dev-header.md"
        $phaseTemplatePath = Join-Path -Path $projectPath -ChildPath "development\templates\plan-dev-phase.md"

        # Vérifier si le chemin du projet est correct
        Write-Log "Vérification du chemin du projet" -Level "DEBUG"
        Write-Log "Chemin du script : $scriptPath" -Level "DEBUG"
        Write-Log "Chemin du projet : $projectPath" -Level "DEBUG"
        Write-Log "Répertoire courant : $(Get-Location)" -Level "DEBUG"

        # Vérifier si les templates existent
        if (-not (Test-Path $headerTemplatePath)) {
            throw "Le fichier template d'en-tête n'existe pas : $headerTemplatePath"
        }

        if (-not (Test-Path $phaseTemplatePath)) {
            throw "Le fichier template de phase n'existe pas : $phaseTemplatePath"
        }

        Write-Log "Templates trouvés" -Level "DEBUG"

        # Générer le plan de développement
        Write-Log "Génération du plan de développement $Version - $Title..." -Level "INFO"

        # Obtenir un nom de fichier sécurisé
        $normalizedTitle = Get-SafeFileName -FileName $Title

        # Chemin du fichier de sortie
        $outputPath = "$projectPath\projet\roadmaps\plans\plan-dev-$Version-$normalizedTitle.md"

        Write-Log "Chemin du fichier de sortie : $outputPath" -Level "DEBUG"

        # Vérifier à nouveau si les templates existent
        Write-Log "Vérification des templates avant lecture" -Level "DEBUG"
        Write-Log "headerTemplatePath: $headerTemplatePath" -Level "DEBUG"
        Write-Log "phaseTemplatePath: $phaseTemplatePath" -Level "DEBUG"
        Write-Log "headerTemplatePath existe: $(Test-Path $headerTemplatePath)" -Level "DEBUG"
        Write-Log "phaseTemplatePath existe: $(Test-Path $phaseTemplatePath)" -Level "DEBUG"

        # Lire les templates
        try {
            $headerTemplate = Get-Content -Path $headerTemplatePath -Raw -Encoding UTF8
            $phaseTemplate = Get-Content -Path $phaseTemplatePath -Raw -Encoding UTF8

            Write-Log "Templates lus avec succès" -Level "DEBUG"
            Write-Log "headerTemplate: $($headerTemplate.Length) caractères" -Level "DEBUG"
            Write-Log "phaseTemplate: $($phaseTemplate.Length) caractères" -Level "DEBUG"
        } catch {
            Write-Log "Erreur lors de la lecture des templates: $_" -Level "ERROR"
            throw
        }

        # Remplacer les placeholders dans l'en-tête
        $date = Get-Date -Format "yyyy-MM-dd"
        $header = $headerTemplate -replace '{VERSION}', $Version -replace '{TITLE}', $Title -replace '{DATE}', $date -replace '{DESCRIPTION}', $Description

        # Créer le contenu final
        $content = $header

        # Ajouter chaque phase
        for ($i = 1; $i -le $Phases; $i++) {
            Write-Log "Ajout de la phase $i" -Level "DEBUG"

            # Remplacer le numéro de phase
            $phaseContent = $phaseTemplate -replace '{PHASE_NUMBER}', $i

            # Ajouter au contenu final
            $content += "`n`n" + $phaseContent
        }

        # Créer le dossier de sortie s'il n'existe pas
        $outputDir = Split-Path -Parent $outputPath
        if (-not (Test-Path $outputDir)) {
            Write-Log "Création du dossier de sortie : $outputDir" -Level "DEBUG"
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        # Supprimer le fichier s'il existe déjà
        if (Test-Path $outputPath) {
            Write-Log "Suppression du fichier existant : $outputPath" -Level "DEBUG"
            Remove-Item $outputPath -Force
        }

        # Écrire le contenu dans le fichier avec encodage UTF-8 avec BOM
        Write-Log "Écriture du contenu dans le fichier" -Level "DEBUG"
        $utf8WithBom = New-Object System.Text.UTF8Encoding $true
        $bytes = $utf8WithBom.GetBytes($content)
        [System.IO.File]::WriteAllBytes($outputPath, $bytes)

        Write-Log "Plan de développement généré avec succès !" -Level "INFO"
        Write-Log "Fichier créé : $outputPath" -Level "INFO"

        return $outputPath
    } catch {
        Write-Log "Erreur lors de la génération du plan de développement : $_" -Level "ERROR"
        throw
    }
}

# Exécution de la fonction principale
try {
    # Appeler la fonction principale et récupérer le chemin du fichier généré
    $outputPath = New-PlanDev -Version $Version -Title $Title -Description $Description -Phases $Phases

    # Vérifier si le chemin est valide
    if ([string]::IsNullOrEmpty($outputPath) -or -not (Test-Path $outputPath)) {
        Write-Log "Le fichier n'a pas été créé correctement : $outputPath" -Level "ERROR"
        exit 1
    }

    # Afficher le chemin du fichier généré
    Write-Output $outputPath
    exit 0
} catch {
    Write-Log "Erreur : $_" -Level "ERROR"
    exit 1
}
