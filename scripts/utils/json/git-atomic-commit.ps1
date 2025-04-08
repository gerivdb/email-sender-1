# Script pour faciliter les commits atomiques
# Ce script permet de sÃ©lectionner prÃ©cisÃ©ment les fichiers Ã  inclure dans un commit

param (
    [Parameter(Mandatory = $false)]
    [string]$CommitMessage = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Category = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$Push,
    
    [Parameter(Mandatory = $false)]
    [switch]$Interactive
)

# Obtenir le chemin racine du projet
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Set-Location $projectRoot

# Fonction pour afficher un message colorÃ©
function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# VÃ©rifier si nous sommes dans un dÃ©pÃ´t Git
if (-not (Test-Path "$projectRoot\.git")) {
    Write-ColorMessage "Ce dossier n'est pas un dÃ©pÃ´t Git" -ForegroundColor "Red"
    exit 1
}

# Obtenir l'Ã©tat Git actuel
$gitStatus = git status --porcelain

if ([string]::IsNullOrEmpty($gitStatus)) {
    Write-ColorMessage "Aucun changement Ã  commiter" -ForegroundColor "Yellow"
    exit 0
}

# DÃ©finir les catÃ©gories de fichiers
$categories = @{
    "structure" = @("*/*/", "**/*/")
    "docs" = @("*.md", "**/*.md")
    "scripts" = @("*.ps1", "**/*.ps1", "*.py", "**/*.py")
    "workflows" = @("*.json", "**/*.json")
    "config" = @("*.config", "**/*.config", "*.env", "**/*.env", "*.yml", "**/*.yml", "*.yaml", "**/*.yaml")
    "web" = @("*.html", "**/*.html", "*.css", "**/*.css", "*.js", "**/*.js")
}

# Si le mode interactif est activÃ©, afficher les fichiers modifiÃ©s et demander lesquels inclure
if ($Interactive) {
    Write-ColorMessage "`nFichiers modifiÃ©s:" -ForegroundColor "Cyan"
    
    $fileList = @()
    $index = 1
    
    $gitStatus | ForEach-Object {
        $status = $_.Substring(0, 2).Trim()
        $file = $_.Substring(3)
        
        $statusColor = switch -Regex ($status) {
            'M' { "Yellow" }
            'A|(\?\?)' { "Green" }
            'D' { "Red" }
            'R' { "Blue" }
            default { "White" }
        }
        
        $statusText = switch -Regex ($status) {
            'M' { "ModifiÃ©" }
            'A|(\?\?)' { "AjoutÃ©" }
            'D' { "SupprimÃ©" }
            'R' { "RenommÃ©" }
            default { $status }
        }
        
        Write-Host "$index. [$statusText] " -ForegroundColor $statusColor -NoNewline
        Write-Host "$file"
        
        $fileList += $file
        $index++
    }
    
    Write-ColorMessage "`nSÃ©lectionnez les fichiers Ã  inclure (sÃ©parÃ©s par des virgules, 'all' pour tous, 'none' pour aucun):" -ForegroundColor "Cyan"
    $selection = Read-Host
    
    if ($selection -eq "all") {
        git add .
        Write-ColorMessage "Tous les fichiers ont Ã©tÃ© ajoutÃ©s" -ForegroundColor "Green"
    }
    elseif ($selection -eq "none") {
        Write-ColorMessage "Aucun fichier n'a Ã©tÃ© ajoutÃ©" -ForegroundColor "Yellow"
        exit 0
    }
    else {
        $selectedIndices = $selection -split ',' | ForEach-Object { $_.Trim() }
        
        foreach ($idx in $selectedIndices) {
            if ($idx -match '^\d+$' -and [int]$idx -ge 1 -and [int]$idx -le $fileList.Count) {
                $fileToAdd = $fileList[[int]$idx - 1]
                git add "$fileToAdd"
                Write-ColorMessage "AjoutÃ©: $fileToAdd" -ForegroundColor "Green"
            }
            elseif ($idx -match '^\d+-\d+$') {
                $range = $idx -split '-'
                $start = [int]$range[0]
                $end = [int]$range[1]
                
                if ($start -ge 1 -and $end -le $fileList.Count -and $start -le $end) {
                    for ($i = $start; $i -le $end; $i++) {
                        $fileToAdd = $fileList[$i - 1]
                        git add "$fileToAdd"
                        Write-ColorMessage "AjoutÃ©: $fileToAdd" -ForegroundColor "Green"
                    }
                }
            }
        }
    }
}
# Sinon, utiliser la catÃ©gorie spÃ©cifiÃ©e
elseif (-not [string]::IsNullOrEmpty($Category)) {
    if ($categories.ContainsKey($Category.ToLower())) {
        $patterns = $categories[$Category.ToLower()]
        
        Write-ColorMessage "Ajout des fichiers de la catÃ©gorie '$Category':" -ForegroundColor "Cyan"
        
        foreach ($pattern in $patterns) {
            git add $pattern
            Write-ColorMessage "  Pattern ajoutÃ©: $pattern" -ForegroundColor "Green"
        }
    }
    else {
        Write-ColorMessage "CatÃ©gorie '$Category' inconnue. CatÃ©gories disponibles:" -ForegroundColor "Red"
        $categories.Keys | ForEach-Object {
            Write-ColorMessage "  - $_" -ForegroundColor "Yellow"
        }
        exit 1
    }
}
else {
    # Afficher les catÃ©gories disponibles
    Write-ColorMessage "SÃ©lectionnez une catÃ©gorie de fichiers Ã  inclure:" -ForegroundColor "Cyan"
    $index = 1
    
    $categories.Keys | ForEach-Object {
        Write-ColorMessage "$index. $_" -ForegroundColor "Yellow"
        $index++
    }
    
    Write-ColorMessage "$index. Tous les fichiers" -ForegroundColor "Yellow"
    
    $selection = Read-Host "Entrez votre choix (1-$index)"
    
    if ($selection -eq $index) {
        git add .
        Write-ColorMessage "Tous les fichiers ont Ã©tÃ© ajoutÃ©s" -ForegroundColor "Green"
    }
    elseif ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -lt $index) {
        $categoryName = ($categories.Keys)[[int]$selection - 1]
        $patterns = $categories[$categoryName]
        
        Write-ColorMessage "Ajout des fichiers de la catÃ©gorie '$categoryName':" -ForegroundColor "Cyan"
        
        foreach ($pattern in $patterns) {
            git add $pattern
            Write-ColorMessage "  Pattern ajoutÃ©: $pattern" -ForegroundColor "Green"
        }
    }
    else {
        Write-ColorMessage "Choix invalide" -ForegroundColor "Red"
        exit 1
    }
}

# VÃ©rifier les fichiers ajoutÃ©s
$stagedChanges = git diff --staged --stat

if ([string]::IsNullOrEmpty($stagedChanges)) {
    Write-ColorMessage "Aucun changement n'a Ã©tÃ© ajoutÃ© Ã  l'index" -ForegroundColor "Yellow"
    exit 0
}

Write-ColorMessage "`nChangements qui seront commitÃ©s:" -ForegroundColor "Cyan"
Write-Host $stagedChanges

# Demander confirmation
$confirmation = Read-Host "`nVoulez-vous continuer avec le commit? (O/N)"
if ($confirmation -ne "O" -and $confirmation -ne "o") {
    Write-ColorMessage "Commit annulÃ© par l'utilisateur" -ForegroundColor "Yellow"
    exit 0
}

# Si aucun message de commit n'est fourni, demander Ã  l'utilisateur
if ([string]::IsNullOrEmpty($CommitMessage)) {
    Write-ColorMessage "`nEntrez un message de commit descriptif:" -ForegroundColor "Cyan"
    Write-ColorMessage "Suggestions pour les commits atomiques:" -ForegroundColor "Yellow"
    Write-ColorMessage "- 'docs: Mise Ã  jour de la documentation sur...'" -ForegroundColor "Yellow"
    Write-ColorMessage "- 'feat: Ajout de la fonctionnalitÃ©...'" -ForegroundColor "Yellow"
    Write-ColorMessage "- 'fix: Correction du problÃ¨me...'" -ForegroundColor "Yellow"
    Write-ColorMessage "- 'refactor: RÃ©organisation de...'" -ForegroundColor "Yellow"
    Write-ColorMessage "- 'chore: Maintenance de...'" -ForegroundColor "Yellow"
    
    $CommitMessage = Read-Host "Message de commit"
    
    if ([string]::IsNullOrEmpty($CommitMessage)) {
        $CommitMessage = "Commit atomique via git-atomic-commit.ps1"
        Write-ColorMessage "Aucun message fourni, utilisation du message par dÃ©faut" -ForegroundColor "Yellow"
    }
}

# CrÃ©er le commit
git commit -m $CommitMessage
Write-ColorMessage "Commit crÃ©Ã© avec le message: $CommitMessage" -ForegroundColor "Green"

# Push si demandÃ©
if ($Push) {
    Write-ColorMessage "`nPush vers le dÃ©pÃ´t distant..." -ForegroundColor "Cyan"
    git push
    Write-ColorMessage "Push terminÃ© avec succÃ¨s" -ForegroundColor "Green"
}

# Afficher l'aide si demandÃ©
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-ColorMessage "`nUtilisation: .\git-atomic-commit.ps1 [options]" -ForegroundColor "Cyan"
    Write-ColorMessage "`nOptions:" -ForegroundColor "Cyan"
    Write-ColorMessage "  -CommitMessage 'message'  Message de commit (si non fourni, sera demandÃ©)" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Category 'nom'           CatÃ©gorie de fichiers Ã  inclure (structure, docs, scripts, workflows, config, web)" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Interactive              Mode interactif pour sÃ©lectionner les fichiers individuellement" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Push                     Effectuer un push aprÃ¨s le commit" -ForegroundColor "Cyan"
    Write-ColorMessage "`nExemples:" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\git-atomic-commit.ps1 -CommitMessage 'docs: Mise Ã  jour de la documentation' -Category 'docs'" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\git-atomic-commit.ps1 -Interactive -Push" -ForegroundColor "Cyan"
}
