# Script pour générer un nouveau plan de développement à partir d'un fichier template
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

try {
    # Chemin du projet
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectPath = Split-Path -Parent (Split-Path -Parent $scriptPath)
    
    Write-Log "Chemin du script : $scriptPath" -Level "DEBUG"
    Write-Log "Chemin du projet : $projectPath" -Level "DEBUG"
    Write-Log "Répertoire courant : $(Get-Location)" -Level "DEBUG"
    
    # Chemin du template
    $templatePath = Join-Path -Path $projectPath -ChildPath "development\templates\plan-dev-template.txt"
    
    # Vérifier si le template existe
    if (-not (Test-Path $templatePath)) {
        throw "Le fichier template n'existe pas : $templatePath"
    }
    
    Write-Log "Template trouvé : $templatePath" -Level "DEBUG"
    
    # Lire le template
    $template = Get-Content -Path $templatePath -Raw -Encoding UTF8
    
    Write-Log "Template lu avec succès : $($template.Length) caractères" -Level "DEBUG"
    
    # Obtenir un nom de fichier sécurisé
    $normalizedTitle = Get-SafeFileName -FileName $Title
    
    # Chemin du fichier de sortie
    $outputPath = "$projectPath\projet\roadmaps\plans\plan-dev-$Version-$normalizedTitle.md"
    
    Write-Log "Chemin du fichier de sortie : $outputPath" -Level "DEBUG"
    
    # Extraire la partie d'en-tête et la partie de phase du template
    $headerEndIndex = $template.IndexOf("## {PHASE_NUMBER}")
    $header = $template.Substring(0, $headerEndIndex)
    $phaseTemplate = $template.Substring($headerEndIndex)
    
    Write-Log "En-tête extrait : $($header.Length) caractères" -Level "DEBUG"
    Write-Log "Template de phase extrait : $($phaseTemplate.Length) caractères" -Level "DEBUG"
    
    # Remplacer les placeholders dans l'en-tête
    $date = Get-Date -Format "yyyy-MM-dd"
    $headerContent = $header -replace '{VERSION}', $Version -replace '{TITLE}', $Title -replace '{DATE}', $date -replace '{DESCRIPTION}', $Description
    
    # Créer le contenu final
    $content = $headerContent
    
    # Ajouter chaque phase
    for ($i = 1; $i -le $Phases; $i++) {
        Write-Log "Ajout de la phase $i" -Level "DEBUG"
        
        # Remplacer le numéro de phase
        $phaseContent = $phaseTemplate -replace '{PHASE_NUMBER}', $i
        
        # Ajouter au contenu final
        $content += $phaseContent
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
    
    # Afficher le chemin du fichier généré
    Write-Output $outputPath
    exit 0
}
catch {
    Write-Log "Erreur : $_" -Level "ERROR"
    exit 1
}
