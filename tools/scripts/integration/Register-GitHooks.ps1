#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre des hooks Git pour l'intégration avec le système d'inventaire
.DESCRIPTION
    Ce script crée et installe des hooks Git pour mettre à jour automatiquement
    l'inventaire des scripts et vérifier les métadonnées lors des opérations Git.
.PARAMETER GitRepoPath
    Chemin du dépôt Git
.PARAMETER Force
    Indique s'il faut remplacer les hooks existants
.EXAMPLE
    .\Register-GitHooks.ps1 -GitRepoPath "C:\Scripts" -Force
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Tags: git, hooks, intégration
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$GitRepoPath = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Vérifier que le répertoire est un dépôt Git
$gitDir = Join-Path -Path $GitRepoPath -ChildPath ".git"
if (-not (Test-Path $gitDir -PathType Container)) {
    Write-Error "Le répertoire spécifié n'est pas un dépôt Git: $GitRepoPath"
    exit 1
}

# Créer le répertoire des hooks s'il n'existe pas
$hooksDir = Join-Path -Path $gitDir -ChildPath "hooks"
if (-not (Test-Path $hooksDir -PathType Container)) {
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    Write-Host "Répertoire des hooks créé: $hooksDir" -ForegroundColor Green
}

# Fonction pour créer un hook
function New-GitHook {
    param (
        [Parameter(Mandatory = $true)]
        [string]$HookName,
        
        [Parameter(Mandatory = $true)]
        [string]$HookContent,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    $hookPath = Join-Path -Path $hooksDir -ChildPath $HookName
    
    # Vérifier si le hook existe déjà
    if ((Test-Path $hookPath) -and -not $Force) {
        Write-Warning "Le hook $HookName existe déjà. Utilisez -Force pour le remplacer."
        return $false
    }
    
    # Écrire le contenu du hook
    Set-Content -Path $hookPath -Value $HookContent -Encoding UTF8
    
    # Rendre le hook exécutable
    if ($IsLinux -or $IsMacOS) {
        chmod +x $hookPath
    }
    
    Write-Host "Hook $HookName créé: $hookPath" -ForegroundColor Green
    return $true
}

# Contenu du hook pre-commit
$preCommitHook = @"
#!/usr/bin/env pwsh
#
# Hook pre-commit pour vérifier les métadonnées des scripts
# Créé automatiquement par Register-GitHooks.ps1
#

# Récupérer les fichiers modifiés
`$stagedFiles = git diff --cached --name-only --diff-filter=ACM

# Filtrer les scripts
`$scriptExtensions = @('.ps1', '.psm1', '.py', '.cmd', '.bat', '.sh')
`$scripts = `$stagedFiles | Where-Object { 
    `$ext = [System.IO.Path]::GetExtension(`$_)
    `$scriptExtensions -contains `$ext
}

if (`$scripts.Count -eq 0) {
    # Aucun script modifié, continuer le commit
    exit 0
}

Write-Host "Vérification des métadonnées pour `$(`$scripts.Count) scripts..." -ForegroundColor Cyan

`$errors = @()

foreach (`$script in `$scripts) {
    `$content = Get-Content `$script -Raw -ErrorAction SilentlyContinue
    
    if (-not `$content) {
        `$errors += "Erreur: Impossible de lire le contenu du script: `$script"
        continue
    }
    
    # Vérifier les métadonnées selon le type de script
    `$ext = [System.IO.Path]::GetExtension(`$script)
    
    if (`$ext -eq '.ps1' -or `$ext -eq '.psm1') {
        # Vérifier les métadonnées PowerShell
        if (-not (`$content -match '<#' -and `$content -match '#>')) {
            `$errors += "Erreur: Le script PowerShell `$script ne contient pas de bloc de commentaires."
            continue
        }
        
        if (-not (`$content -match '\.SYNOPSIS' -or `$content -match '\.DESCRIPTION')) {
            `$errors += "Erreur: Le script PowerShell `$script ne contient pas de synopsis ou de description."
        }
        
        if (-not (`$content -match '\.AUTHOR' -or `$content -match 'Author:')) {
            `$errors += "Avertissement: Le script PowerShell `$script ne contient pas d'information sur l'auteur."
        }
        
        if (-not (`$content -match '\.VERSION' -or `$content -match 'Version:')) {
            `$errors += "Avertissement: Le script PowerShell `$script ne contient pas d'information sur la version."
        }
    }
    elseif (`$ext -eq '.py') {
        # Vérifier les métadonnées Python
        if (-not (`$content -match '"""' -and `$content -match '"""')) {
            `$errors += "Erreur: Le script Python `$script ne contient pas de docstring."
            continue
        }
        
        if (-not (`$content -match '@author' -or `$content -match 'Author:')) {
            `$errors += "Avertissement: Le script Python `$script ne contient pas d'information sur l'auteur."
        }
        
        if (-not (`$content -match '@version' -or `$content -match 'Version:')) {
            `$errors += "Avertissement: Le script Python `$script ne contient pas d'information sur la version."
        }
    }
}

if (`$errors.Count -gt 0) {
    Write-Host "`nProblèmes détectés dans les métadonnées des scripts:" -ForegroundColor Red
    foreach (`$error in `$errors) {
        Write-Host `$error -ForegroundColor Yellow
    }
    
    `$continue = Read-Host "Voulez-vous continuer le commit malgré les problèmes? (O/N)"
    if (`$continue -ne "O" -and `$continue -ne "o") {
        Write-Host "Commit annulé. Veuillez corriger les problèmes et réessayer." -ForegroundColor Red
        exit 1
    }
}

# Tout est OK, continuer le commit
exit 0
"@

# Contenu du hook post-commit
$postCommitHook = @"
#!/usr/bin/env pwsh
#
# Hook post-commit pour mettre à jour l'inventaire des scripts
# Créé automatiquement par Register-GitHooks.ps1
#

# Chemin relatif vers le module d'inventaire
`$modulePath = Join-Path -Path `$PSScriptRoot -ChildPath "../../modules/ScriptInventoryManager.psm1"

# Vérifier si le module existe
if (Test-Path `$modulePath) {
    try {
        # Importer le module
        Import-Module `$modulePath -Force
        
        # Mettre à jour l'inventaire
        Write-Host "Mise à jour de l'inventaire des scripts..." -ForegroundColor Cyan
        Update-ScriptInventory
        Write-Host "Inventaire mis à jour avec succès." -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de la mise à jour de l'inventaire: `$_" -ForegroundColor Red
    }
}
else {
    Write-Host "Module d'inventaire non trouvé: `$modulePath" -ForegroundColor Yellow
}

# Continuer normalement
exit 0
"@

# Contenu du hook post-merge
$postMergeHook = @"
#!/usr/bin/env pwsh
#
# Hook post-merge pour mettre à jour l'inventaire des scripts
# Créé automatiquement par Register-GitHooks.ps1
#

# Chemin relatif vers le module d'inventaire
`$modulePath = Join-Path -Path `$PSScriptRoot -ChildPath "../../modules/ScriptInventoryManager.psm1"

# Vérifier si le module existe
if (Test-Path `$modulePath) {
    try {
        # Importer le module
        Import-Module `$modulePath -Force
        
        # Mettre à jour l'inventaire
        Write-Host "Mise à jour de l'inventaire des scripts après merge..." -ForegroundColor Cyan
        Update-ScriptInventory
        Write-Host "Inventaire mis à jour avec succès." -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de la mise à jour de l'inventaire: `$_" -ForegroundColor Red
    }
}
else {
    Write-Host "Module d'inventaire non trouvé: `$modulePath" -ForegroundColor Yellow
}

# Continuer normalement
exit 0
"@

# Créer les hooks
$hooksCreated = 0

if (New-GitHook -HookName "pre-commit" -HookContent $preCommitHook -Force:$Force) {
    $hooksCreated++
}

if (New-GitHook -HookName "post-commit" -HookContent $postCommitHook -Force:$Force) {
    $hooksCreated++
}

if (New-GitHook -HookName "post-merge" -HookContent $postMergeHook -Force:$Force) {
    $hooksCreated++
}

# Afficher un résumé
Write-Host "`nRésumé:" -ForegroundColor Cyan
Write-Host "- $hooksCreated hooks Git créés ou mis à jour" -ForegroundColor Green

if ($hooksCreated -gt 0) {
    Write-Host "`nLes hooks Git ont été installés avec succès." -ForegroundColor Green
    Write-Host "Ces hooks permettront de:" -ForegroundColor White
    Write-Host "- Vérifier les métadonnées des scripts avant un commit" -ForegroundColor White
    Write-Host "- Mettre à jour l'inventaire des scripts après un commit" -ForegroundColor White
    Write-Host "- Mettre à jour l'inventaire des scripts après un merge" -ForegroundColor White
    
    Write-Host "`nNote: Pour ignorer les hooks lors d'un commit, utilisez l'option --no-verify:" -ForegroundColor Yellow
    Write-Host "git commit --no-verify -m 'Message de commit'" -ForegroundColor White
}
