# Script pour générer un nouveau plan de développement à partir du template Hygen
# avec support complet des caractères UTF-8
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

# Conserver les caractères accentués dans le nom du fichier
$normalizedTitle = $Title.ToLower() -replace ' ', '-'

# Nous ne normalisons pas les caractères accentués, nous les conservons tels quels
# Mais nous nous assurons que le nom du fichier est valide pour le système de fichiers
$normalizedTitle = $normalizedTitle -replace '[<>:"/\\|?*]', '_'

# Chemin du fichier de sortie
$outputPath = "$projectPath\projet\roadmaps\plans\plan-dev-$Version-$normalizedTitle.md"

# Générer le contenu du plan
$date = Get-Date -Format "yyyy-MM-dd"
$content = @"
# Plan de développement $Version - $Title
*Version 1.0 - $date - Progression globale : 0%*

$Description

"@

# Nous n'avons pas besoin de remplacer les chaînes car elles sont déjà correctes dans la chaîne de caractères
# Le problème est l'encodage lors de l'écriture dans le fichier

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
# Nous utilisons une approche différente pour garantir que les caractères accentués sont correctement encodés
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
$bytes = $utf8WithBom.GetBytes($content)
[System.IO.File]::WriteAllBytes($outputPath, $bytes)

Write-Host "Plan de développement généré avec succès !" -ForegroundColor Green
Write-Host "Fichier créé : $outputPath" -ForegroundColor Green
