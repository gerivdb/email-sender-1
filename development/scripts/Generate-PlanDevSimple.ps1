# Script simplifié pour générer un nouveau plan de développement
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

  # Obtenir un nom de fichier sécurisé
  $normalizedTitle = Get-SafeFileName -FileName $Title

  # Chemin du fichier de sortie
  $outputPath = "$projectPath\projet\roadmaps\plans\plan-dev-$Version-$normalizedTitle.md"

  Write-Log "Chemin du fichier de sortie : $outputPath" -Level "DEBUG"

  # Créer le contenu du plan
  $date = Get-Date -Format "yyyy-MM-dd"
  $content = @"
# Plan de développement $Version - $Title
*Version 1.0 - $date - Progression globale : 0%*

$Description

"@

  # Ajouter chaque phase
  for ($i = 1; $i -le $Phases; $i++) {
    Write-Log "Ajout de la phase $i" -Level "DEBUG"

    $content += @"

## $i. Phase $i (Phase $i)

- [ ] **$i.1** Tache principale 1
  - [ ] **$i.1.1** Sous-tache 1.1
    - [ ] **$i.1.1.1** Sous-sous-tache 1.1.1
      - [ ] **$i.1.1.1.1** Action 1.1.1.1
      - [ ] **$i.1.1.1.2** Action 1.1.1.2
      - [ ] **$i.1.1.1.3** Action 1.1.1.3
    - [ ] **$i.1.1.2** Sous-sous-tache 1.1.2
      - [ ] **$i.1.1.2.1** Action 1.1.2.1
      - [ ] **$i.1.1.2.2** Action 1.1.2.2
      - [ ] **$i.1.1.2.3** Action 1.1.2.3
    - [ ] **$i.1.1.3** Sous-sous-tache 1.1.3
      - [ ] **$i.1.1.3.1** Action 1.1.3.1
      - [ ] **$i.1.1.3.2** Action 1.1.3.2
      - [ ] **$i.1.1.3.3** Action 1.1.3.3
  - [ ] **$i.1.2** Sous-tache 1.2
    - [ ] **$i.1.2.1** Sous-sous-tache 1.2.1
      - [ ] **$i.1.2.1.1** Action 1.2.1.1
      - [ ] **$i.1.2.1.2** Action 1.2.1.2
      - [ ] **$i.1.2.1.3** Action 1.2.1.3
    - [ ] **$i.1.2.2** Sous-sous-tache 1.2.2
      - [ ] **$i.1.2.2.1** Action 1.2.2.1
      - [ ] **$i.1.2.2.2** Action 1.2.2.2
      - [ ] **$i.1.2.2.3** Action 1.2.2.3
    - [ ] **$i.1.2.3** Sous-sous-tache 1.2.3
      - [ ] **$i.1.2.3.1** Action 1.2.3.1
      - [ ] **$i.1.2.3.2** Action 1.2.3.2
      - [ ] **$i.1.2.3.3** Action 1.2.3.3
  - [ ] **$i.1.3** Sous-tache 1.3
    - [ ] **$i.1.3.1** Sous-sous-tache 1.3.1
      - [ ] **$i.1.3.1.1** Action 1.3.1.1
      - [ ] **$i.1.3.1.2** Action 1.3.1.2
      - [ ] **$i.1.3.1.3** Action 1.3.1.3
    - [ ] **$i.1.3.2** Sous-sous-tache 1.3.2
      - [ ] **$i.1.3.2.1** Action 1.3.2.1
      - [ ] **$i.1.3.2.2** Action 1.3.2.2
      - [ ] **$i.1.3.2.3** Action 1.3.2.3
    - [ ] **$i.1.3.3** Sous-sous-tache 1.3.3
      - [ ] **$i.1.3.3.1** Action 1.3.3.1
      - [ ] **$i.1.3.3.2** Action 1.3.3.2
      - [ ] **$i.1.3.3.3** Action 1.3.3.3

- [ ] **$i.2** Tache principale 2
  - [ ] **$i.2.1** Sous-tache 2.1
    - [ ] **$i.2.1.1** Sous-sous-tache 2.1.1
    - [ ] **$i.2.1.2** Sous-sous-tache 2.1.2
    - [ ] **$i.2.1.3** Sous-sous-tache 2.1.3
  - [ ] **$i.2.2** Sous-tache 2.2
    - [ ] **$i.2.2.1** Sous-sous-tache 2.2.1
    - [ ] **$i.2.2.2** Sous-sous-tache 2.2.2
    - [ ] **$i.2.2.3** Sous-sous-tache 2.2.3
  - [ ] **$i.2.3** Sous-tache 2.3
    - [ ] **$i.2.3.1** Sous-sous-tache 2.3.1
    - [ ] **$i.2.3.2** Sous-sous-tache 2.3.2
    - [ ] **$i.2.3.3** Sous-sous-tache 2.3.3
"@
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
} catch {
  Write-Log "Erreur : $_" -Level "ERROR"
  exit 1
}
