# Script pour faciliter les commits atomiques
# Ce script permet de sélectionner précisément les fichiers à inclure dans un commit

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

# Fonction pour afficher un message coloré
function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Vérifier si nous sommes dans un dépôt Git
if (-not (Test-Path "$projectRoot\.git")) {
    Write-ColorMessage "Ce dossier n'est pas un dépôt Git" -ForegroundColor "Red"
    exit 1
}

# Obtenir l'état Git actuel
$gitStatus = git status --porcelain

if ([string]::IsNullOrEmpty($gitStatus)) {
    Write-ColorMessage "Aucun changement à commiter" -ForegroundColor "Yellow"
    exit 0
}

# Définir les catégories de fichiers
$categories = @{
    "structure" = @("*/*/", "**/*/")
    "docs" = @("*.md", "**/*.md")
    "scripts" = @("*.ps1", "**/*.ps1", "*.py", "**/*.py")
    "workflows" = @("*.json", "**/*.json")
    "config" = @("*.config", "**/*.config", "*.env", "**/*.env", "*.yml", "**/*.yml", "*.yaml", "**/*.yaml")
    "web" = @("*.html", "**/*.html", "*.css", "**/*.css", "*.js", "**/*.js")
}

# Si le mode interactif est activé, afficher les fichiers modifiés et demander lesquels inclure
if ($Interactive) {
    Write-ColorMessage "`nFichiers modifiés:" -ForegroundColor "Cyan"
    
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
            'M' { "Modifié" }
            'A|(\?\?)' { "Ajouté" }
            'D' { "Supprimé" }
            'R' { "Renommé" }
            default { $status }
        }
        
        Write-Host "$index. [$statusText] " -ForegroundColor $statusColor -NoNewline
        Write-Host "$file"
        
        $fileList += $file
        $index++
    }
    
    Write-ColorMessage "`nSélectionnez les fichiers à inclure (séparés par des virgules, 'all' pour tous, 'none' pour aucun):" -ForegroundColor "Cyan"
    $selection = Read-Host
    
    if ($selection -eq "all") {
        git add .
        Write-ColorMessage "Tous les fichiers ont été ajoutés" -ForegroundColor "Green"
    }
    elseif ($selection -eq "none") {
        Write-ColorMessage "Aucun fichier n'a été ajouté" -ForegroundColor "Yellow"
        exit 0
    }
    else {
        $selectedIndices = $selection -split ',' | ForEach-Object { $_.Trim() }
        
        foreach ($idx in $selectedIndices) {
            if ($idx -match '^\d+$' -and [int]$idx -ge 1 -and [int]$idx -le $fileList.Count) {
                $fileToAdd = $fileList[[int]$idx - 1]
                git add "$fileToAdd"
                Write-ColorMessage "Ajouté: $fileToAdd" -ForegroundColor "Green"
            }
            elseif ($idx -match '^\d+-\d+$') {
                $range = $idx -split '-'
                $start = [int]$range[0]
                $end = [int]$range[1]
                
                if ($start -ge 1 -and $end -le $fileList.Count -and $start -le $end) {
                    for ($i = $start; $i -le $end; $i++) {
                        $fileToAdd = $fileList[$i - 1]
                        git add "$fileToAdd"
                        Write-ColorMessage "Ajouté: $fileToAdd" -ForegroundColor "Green"
                    }
                }
            }
        }
    }
}
# Sinon, utiliser la catégorie spécifiée
elseif (-not [string]::IsNullOrEmpty($Category)) {
    if ($categories.ContainsKey($Category.ToLower())) {
        $patterns = $categories[$Category.ToLower()]
        
        Write-ColorMessage "Ajout des fichiers de la catégorie '$Category':" -ForegroundColor "Cyan"
        
        foreach ($pattern in $patterns) {
            git add $pattern
            Write-ColorMessage "  Pattern ajouté: $pattern" -ForegroundColor "Green"
        }
    }
    else {
        Write-ColorMessage "Catégorie '$Category' inconnue. Catégories disponibles:" -ForegroundColor "Red"
        $categories.Keys | ForEach-Object {
            Write-ColorMessage "  - $_" -ForegroundColor "Yellow"
        }
        exit 1
    }
}
else {
    # Afficher les catégories disponibles
    Write-ColorMessage "Sélectionnez une catégorie de fichiers à inclure:" -ForegroundColor "Cyan"
    $index = 1
    
    $categories.Keys | ForEach-Object {
        Write-ColorMessage "$index. $_" -ForegroundColor "Yellow"
        $index++
    }
    
    Write-ColorMessage "$index. Tous les fichiers" -ForegroundColor "Yellow"
    
    $selection = Read-Host "Entrez votre choix (1-$index)"
    
    if ($selection -eq $index) {
        git add .
        Write-ColorMessage "Tous les fichiers ont été ajoutés" -ForegroundColor "Green"
    }
    elseif ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -lt $index) {
        $categoryName = ($categories.Keys)[[int]$selection - 1]
        $patterns = $categories[$categoryName]
        
        Write-ColorMessage "Ajout des fichiers de la catégorie '$categoryName':" -ForegroundColor "Cyan"
        
        foreach ($pattern in $patterns) {
            git add $pattern
            Write-ColorMessage "  Pattern ajouté: $pattern" -ForegroundColor "Green"
        }
    }
    else {
        Write-ColorMessage "Choix invalide" -ForegroundColor "Red"
        exit 1
    }
}

# Vérifier les fichiers ajoutés
$stagedChanges = git diff --staged --stat

if ([string]::IsNullOrEmpty($stagedChanges)) {
    Write-ColorMessage "Aucun changement n'a été ajouté à l'index" -ForegroundColor "Yellow"
    exit 0
}

Write-ColorMessage "`nChangements qui seront commités:" -ForegroundColor "Cyan"
Write-Host $stagedChanges

# Demander confirmation
$confirmation = Read-Host "`nVoulez-vous continuer avec le commit? (O/N)"
if ($confirmation -ne "O" -and $confirmation -ne "o") {
    Write-ColorMessage "Commit annulé par l'utilisateur" -ForegroundColor "Yellow"
    exit 0
}

# Si aucun message de commit n'est fourni, demander à l'utilisateur
if ([string]::IsNullOrEmpty($CommitMessage)) {
    Write-ColorMessage "`nEntrez un message de commit descriptif:" -ForegroundColor "Cyan"
    Write-ColorMessage "Suggestions pour les commits atomiques:" -ForegroundColor "Yellow"
    Write-ColorMessage "- 'docs: Mise à jour de la documentation sur...'" -ForegroundColor "Yellow"
    Write-ColorMessage "- 'feat: Ajout de la fonctionnalité...'" -ForegroundColor "Yellow"
    Write-ColorMessage "- 'fix: Correction du problème...'" -ForegroundColor "Yellow"
    Write-ColorMessage "- 'refactor: Réorganisation de...'" -ForegroundColor "Yellow"
    Write-ColorMessage "- 'chore: Maintenance de...'" -ForegroundColor "Yellow"
    
    $CommitMessage = Read-Host "Message de commit"
    
    if ([string]::IsNullOrEmpty($CommitMessage)) {
        $CommitMessage = "Commit atomique via git-atomic-commit.ps1"
        Write-ColorMessage "Aucun message fourni, utilisation du message par défaut" -ForegroundColor "Yellow"
    }
}

# Créer le commit
git commit -m $CommitMessage
Write-ColorMessage "Commit créé avec le message: $CommitMessage" -ForegroundColor "Green"

# Push si demandé
if ($Push) {
    Write-ColorMessage "`nPush vers le dépôt distant..." -ForegroundColor "Cyan"
    git push
    Write-ColorMessage "Push terminé avec succès" -ForegroundColor "Green"
}

# Afficher l'aide si demandé
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-ColorMessage "`nUtilisation: .\git-atomic-commit.ps1 [options]" -ForegroundColor "Cyan"
    Write-ColorMessage "`nOptions:" -ForegroundColor "Cyan"
    Write-ColorMessage "  -CommitMessage 'message'  Message de commit (si non fourni, sera demandé)" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Category 'nom'           Catégorie de fichiers à inclure (structure, docs, scripts, workflows, config, web)" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Interactive              Mode interactif pour sélectionner les fichiers individuellement" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Push                     Effectuer un push après le commit" -ForegroundColor "Cyan"
    Write-ColorMessage "`nExemples:" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\git-atomic-commit.ps1 -CommitMessage 'docs: Mise à jour de la documentation' -Category 'docs'" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\git-atomic-commit.ps1 -Interactive -Push" -ForegroundColor "Cyan"
}
