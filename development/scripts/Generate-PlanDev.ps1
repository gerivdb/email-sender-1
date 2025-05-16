# Script pour générer un nouveau plan de développement à partir du template Hygen
param (
  [Parameter(Mandatory = $true)]
  [string]$Version,

  [Parameter(Mandatory = $true)]
  [string]$Title,

  [Parameter(Mandatory = $true)]
  [string]$Description,

  [Parameter(Mandatory = $true)]
  [int]$Phases
)

# Vérifier si Hygen est installé
$hygenInstalled = $null
try {
  $hygenInstalled = Get-Command hygen -ErrorAction SilentlyContinue
} catch {
  # Hygen n'est pas installé ou pas dans le PATH
}

if ($null -eq $hygenInstalled) {
  Write-Host "Hygen n'est pas installé ou n'est pas dans le PATH. Installation en cours..." -ForegroundColor Yellow
  npm install -g hygen

  if ($LASTEXITCODE -ne 0) {
    Write-Error "Échec de l'installation de Hygen. Veuillez l'installer manuellement avec 'npm install -g hygen'."
    exit 1
  }
}

# Chemin du projet (utilise le répertoire parent du script)
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectPath = Split-Path -Parent (Split-Path -Parent $scriptPath)

# Vérifier si le dossier des templates Hygen existe
if (-not (Test-Path "$projectPath\development\templates\hygen\plan-dev")) {
  Write-Error "Le dossier des templates Hygen n'existe pas. Veuillez exécuter le script depuis la racine du projet."
  exit 1
}

# Générer le plan de développement
Write-Host "Génération du plan de développement $Version - $Title..." -ForegroundColor Cyan

# Variable pour suivre si Hygen a réussi
$hygenSuccess = $false

# Utiliser Hygen pour générer le plan
try {
  Set-Location $projectPath
  hygen plan-dev new --version $Version --title $Title --description $Description --phases $Phases

  if ($LASTEXITCODE -eq 0) {
    $hygenSuccess = $true
    Write-Host "Plan de développement généré avec succès !" -ForegroundColor Green
    Write-Host "Fichier créé : projet/roadmaps/plans/plan-dev-$Version-$($Title.ToLower() -replace ' ', '-').md" -ForegroundColor Green
  } else {
    Write-Warning "Hygen a retourné une erreur (code $LASTEXITCODE)."
  }
} catch {
  Write-Warning "Une erreur s'est produite lors de l'exécution de Hygen: $_"
}

# Fonction pour générer manuellement un plan de développement (avec un verbe approuvé)
function New-PlanDevManually {
  param (
    [string]$Version,
    [string]$Title,
    [string]$Description,
    [int]$Phases
  )

  $dasherizedTitle = $Title.ToLower() -replace ' ', '-'
  $outputPath = "$projectPath\projet\roadmaps\plans\plan-dev-$Version-$dasherizedTitle.md"
  $date = Get-Date -Format "yyyy-MM-dd"

  # Créer le contenu du fichier
  $content = @"
# Plan de développement $Version - $Title
*Version 1.0 - $date - Progression globale : 0%*

$Description

"@

  # Ajouter les phases
  for ($i = 1; $i -le $Phases; $i++) {
    $content += @"

## $i. Phase $i (Phase $i)

- [ ] **$i.1** Tâche principale 1
  - [ ] **$i.1.1** Sous-tâche 1.1
    - [ ] **$i.1.1.1** Sous-sous-tâche 1.1.1
      - [ ] **$i.1.1.1.1** Action 1.1.1.1
      - [ ] **$i.1.1.1.2** Action 1.1.1.2
      - [ ] **$i.1.1.1.3** Action 1.1.1.3
    - [ ] **$i.1.1.2** Sous-sous-tâche 1.1.2
      - [ ] **$i.1.1.2.1** Action 1.1.2.1
      - [ ] **$i.1.1.2.2** Action 1.1.2.2
      - [ ] **$i.1.1.2.3** Action 1.1.2.3
    - [ ] **$i.1.1.3** Sous-sous-tâche 1.1.3
      - [ ] **$i.1.1.3.1** Action 1.1.3.1
      - [ ] **$i.1.1.3.2** Action 1.1.3.2
      - [ ] **$i.1.1.3.3** Action 1.1.3.3
  - [ ] **$i.1.2** Sous-tâche 1.2
    - [ ] **$i.1.2.1** Sous-sous-tâche 1.2.1
      - [ ] **$i.1.2.1.1** Action 1.2.1.1
      - [ ] **$i.1.2.1.2** Action 1.2.1.2
      - [ ] **$i.1.2.1.3** Action 1.2.1.3
    - [ ] **$i.1.2.2** Sous-sous-tâche 1.2.2
      - [ ] **$i.1.2.2.1** Action 1.2.2.1
      - [ ] **$i.1.2.2.2** Action 1.2.2.2
      - [ ] **$i.1.2.2.3** Action 1.2.2.3
    - [ ] **$i.1.2.3** Sous-sous-tâche 1.2.3
      - [ ] **$i.1.2.3.1** Action 1.2.3.1
      - [ ] **$i.1.2.3.2** Action 1.2.3.2
      - [ ] **$i.1.2.3.3** Action 1.2.3.3
  - [ ] **$i.1.3** Sous-tâche 1.3
    - [ ] **$i.1.3.1** Sous-sous-tâche 1.3.1
      - [ ] **$i.1.3.1.1** Action 1.3.1.1
      - [ ] **$i.1.3.1.2** Action 1.3.1.2
      - [ ] **$i.1.3.1.3** Action 1.3.1.3
    - [ ] **$i.1.3.2** Sous-sous-tâche 1.3.2
      - [ ] **$i.1.3.2.1** Action 1.3.2.1
      - [ ] **$i.1.3.2.2** Action 1.3.2.2
      - [ ] **$i.1.3.2.3** Action 1.3.2.3
    - [ ] **$i.1.3.3** Sous-sous-tâche 1.3.3
      - [ ] **$i.1.3.3.1** Action 1.3.3.1
      - [ ] **$i.1.3.3.2** Action 1.3.3.2
      - [ ] **$i.1.3.3.3** Action 1.3.3.3

- [ ] **$i.2** Tâche principale 2
  - [ ] **$i.2.1** Sous-tâche 2.1
    - [ ] **$i.2.1.1** Sous-sous-tâche 2.1.1
    - [ ] **$i.2.1.2** Sous-sous-tâche 2.1.2
    - [ ] **$i.2.1.3** Sous-sous-tâche 2.1.3
  - [ ] **$i.2.2** Sous-tâche 2.2
    - [ ] **$i.2.2.1** Sous-sous-tâche 2.2.1
    - [ ] **$i.2.2.2** Sous-sous-tâche 2.2.2
    - [ ] **$i.2.2.3** Sous-sous-tâche 2.2.3
  - [ ] **$i.2.3** Sous-tâche 2.3
    - [ ] **$i.2.3.1** Sous-sous-tâche 2.3.1
    - [ ] **$i.2.3.2** Sous-sous-tâche 2.3.2
    - [ ] **$i.2.3.3** Sous-sous-tâche 2.3.3

"@
  }

  # Créer le dossier de sortie s'il n'existe pas
  $outputDir = Split-Path -Parent $outputPath
  if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
  }

  # Écrire le contenu dans le fichier avec encodage UTF-8 avec BOM
  $utf8WithBom = New-Object System.Text.UTF8Encoding $true
  [System.IO.File]::WriteAllText($outputPath, $content, $utf8WithBom)

  Write-Host "Plan de développement généré manuellement avec succès !" -ForegroundColor Green
  Write-Host "Fichier créé : $outputPath" -ForegroundColor Green
}

# Si Hygen n'a pas réussi, utiliser la méthode alternative
if (-not $hygenSuccess) {
  Write-Host "Tentative de génération manuelle..." -ForegroundColor Yellow
  New-PlanDevManually -Version $Version -Title $Title -Description $Description -Phases $Phases
}
