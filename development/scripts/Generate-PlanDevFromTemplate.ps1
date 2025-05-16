# Script pour générer un nouveau plan de développement à partir d'un template externe
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

# Chemin du projet (utilise le répertoire parent du script)
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectPath = Split-Path -Parent (Split-Path -Parent $scriptPath)

# Chemin du template
$templatePath = "$projectPath\development\templates\plan-dev-template.md"

# Vérifier si le template existe
if (-not (Test-Path $templatePath)) {
    Write-Error "Le fichier template n'existe pas : $templatePath"
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

# Lire le contenu du template
$templateContent = Get-Content -Path $templatePath -Raw -Encoding UTF8

# Remplacer les placeholders communs
$date = Get-Date -Format "yyyy-MM-dd"
$content = $templateContent -replace '{VERSION}', $Version -replace '{TITLE}', $Title -replace '{DATE}', $date -replace '{DESCRIPTION}', $Description

# Extraire les parties du template
$headerEndIndex = $content.IndexOf("## {PHASE_NUMBER}")
$header = $content.Substring(0, $headerEndIndex)
$phaseTemplate = $content.Substring($headerEndIndex)

# Créer le contenu final
$finalContent = $header

# Ajouter chaque phase
for ($i = 1; $i -le $Phases; $i++) {
    # Remplacer le numéro de phase
    $phaseContent = $phaseTemplate -replace '{PHASE_NUMBER}', $i

    # Remplacer les numéros de tâches
    $phaseContent = $phaseContent -replace '\*\*1\.', "**$i."

    # Ajouter au contenu final
    $finalContent += $phaseContent

    # Ajouter un saut de ligne entre les phases
    if ($i -lt $Phases) {
        $finalContent += "`n"
    }
}

# Utiliser le contenu final
$content = $finalContent

# Créer le dossier de sortie s'il n'existe pas
$outputDir = Split-Path -Parent $outputPath
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Écrire le contenu dans le fichier avec encodage UTF-8 avec BOM
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
$bytes = $utf8WithBom.GetBytes($content)
[System.IO.File]::WriteAllBytes($outputPath, $bytes)

Write-Host "Plan de développement généré avec succès !" -ForegroundColor Green
Write-Host "Fichier créé : $outputPath" -ForegroundColor Green
