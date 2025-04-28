#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre des hooks Git pour l'intÃ©gration avec le systÃ¨me d'inventaire
.DESCRIPTION
    Ce script crÃ©e et installe des hooks Git pour mettre Ã  jour automatiquement
    l'inventaire des scripts et vÃ©rifier les mÃ©tadonnÃ©es lors des opÃ©rations Git.
.PARAMETER GitRepoPath
    Chemin du dÃ©pÃ´t Git
.PARAMETER Force
    Indique s'il faut remplacer les hooks existants
.EXAMPLE
    .\Register-GitHooks.ps1 -GitRepoPath "C:\Scripts" -Force
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Tags: git, hooks, intÃ©gration
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$GitRepoPath = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# VÃ©rifier que le rÃ©pertoire est un dÃ©pÃ´t Git
$gitDir = Join-Path -Path $GitRepoPath -ChildPath ".git"
if (-not (Test-Path $gitDir -PathType Container)) {
    Write-Error "Le rÃ©pertoire spÃ©cifiÃ© n'est pas un dÃ©pÃ´t Git: $GitRepoPath"
    exit 1
}

# CrÃ©er le rÃ©pertoire des hooks s'il n'existe pas
$hooksDir = Join-Path -Path $gitDir -ChildPath "hooks"
if (-not (Test-Path $hooksDir -PathType Container)) {
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    Write-Host "RÃ©pertoire des hooks crÃ©Ã©: $hooksDir" -ForegroundColor Green
}

# Fonction pour crÃ©er un hook
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
    
    # VÃ©rifier si le hook existe dÃ©jÃ 
    if ((Test-Path $hookPath) -and -not $Force) {
        Write-Warning "Le hook $HookName existe dÃ©jÃ . Utilisez -Force pour le remplacer."
        return $false
    }
    
    # Ã‰crire le contenu du hook
    Set-Content -Path $hookPath -Value $HookContent -Encoding UTF8
    
    # Rendre le hook exÃ©cutable
    if ($IsLinux -or $IsMacOS) {
        chmod +x $hookPath
    }
    
    Write-Host "Hook $HookName crÃ©Ã©: $hookPath" -ForegroundColor Green
    return $true
}

# Contenu du hook pre-commit
$preCommitHook = @"
#!/usr/bin/env pwsh
#
# Hook pre-commit pour vÃ©rifier les mÃ©tadonnÃ©es des scripts
# CrÃ©Ã© automatiquement par Register-GitHooks.ps1
#

# RÃ©cupÃ©rer les fichiers modifiÃ©s
`$stagedFiles = git diff --cached --name-only --diff-filter=ACM

# Filtrer les scripts
`$scriptExtensions = @('.ps1', '.psm1', '.py', '.cmd', '.bat', '.sh')
`$scripts = `$stagedFiles | Where-Object { 
    `$ext = [System.IO.Path]::GetExtension(`$_)
    `$scriptExtensions -contains `$ext
}

if (`$scripts.Count -eq 0) {
    # Aucun script modifiÃ©, continuer le commit
    exit 0
}

Write-Host "VÃ©rification des mÃ©tadonnÃ©es pour `$(`$scripts.Count) scripts..." -ForegroundColor Cyan

`$errors = @()

foreach (`$script in `$scripts) {
    `$content = Get-Content `$script -Raw -ErrorAction SilentlyContinue
    
    if (-not `$content) {
        `$errors += "Erreur: Impossible de lire le contenu du script: `$script"
        continue
    }
    
    # VÃ©rifier les mÃ©tadonnÃ©es selon le type de script
    `$ext = [System.IO.Path]::GetExtension(`$script)
    
    if (`$ext -eq '.ps1' -or `$ext -eq '.psm1') {
        # VÃ©rifier les mÃ©tadonnÃ©es PowerShell
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
        # VÃ©rifier les mÃ©tadonnÃ©es Python
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
    Write-Host "`nProblÃ¨mes dÃ©tectÃ©s dans les mÃ©tadonnÃ©es des scripts:" -ForegroundColor Red
    foreach (`$error in `$errors) {
        Write-Host `$error -ForegroundColor Yellow
    }
    
    `$continue = Read-Host "Voulez-vous continuer le commit malgrÃ© les problÃ¨mes? (O/N)"
    if (`$continue -ne "O" -and `$continue -ne "o") {
        Write-Host "Commit annulÃ©. Veuillez corriger les problÃ¨mes et rÃ©essayer." -ForegroundColor Red
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
# Hook post-commit pour mettre Ã  jour l'inventaire des scripts
# CrÃ©Ã© automatiquement par Register-GitHooks.ps1
#

# Chemin relatif vers le module d'inventaire
`$modulePath = Join-Path -Path `$PSScriptRoot -ChildPath "../../modules/ScriptInventoryManager.psm1"

# VÃ©rifier si le module existe
if (Test-Path `$modulePath) {
    try {
        # Importer le module
        Import-Module `$modulePath -Force
        
        # Mettre Ã  jour l'inventaire
        Write-Host "Mise Ã  jour de l'inventaire des scripts..." -ForegroundColor Cyan
        Update-ScriptInventory
        Write-Host "Inventaire mis Ã  jour avec succÃ¨s." -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de la mise Ã  jour de l'inventaire: `$_" -ForegroundColor Red
    }
}
else {
    Write-Host "Module d'inventaire non trouvÃ©: `$modulePath" -ForegroundColor Yellow
}

# Continuer normalement
exit 0
"@

# Contenu du hook post-merge
$postMergeHook = @"
#!/usr/bin/env pwsh
#
# Hook post-merge pour mettre Ã  jour l'inventaire des scripts
# CrÃ©Ã© automatiquement par Register-GitHooks.ps1
#

# Chemin relatif vers le module d'inventaire
`$modulePath = Join-Path -Path `$PSScriptRoot -ChildPath "../../modules/ScriptInventoryManager.psm1"

# VÃ©rifier si le module existe
if (Test-Path `$modulePath) {
    try {
        # Importer le module
        Import-Module `$modulePath -Force
        
        # Mettre Ã  jour l'inventaire
        Write-Host "Mise Ã  jour de l'inventaire des scripts aprÃ¨s merge..." -ForegroundColor Cyan
        Update-ScriptInventory
        Write-Host "Inventaire mis Ã  jour avec succÃ¨s." -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de la mise Ã  jour de l'inventaire: `$_" -ForegroundColor Red
    }
}
else {
    Write-Host "Module d'inventaire non trouvÃ©: `$modulePath" -ForegroundColor Yellow
}

# Continuer normalement
exit 0
"@

# CrÃ©er les hooks
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

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ©:" -ForegroundColor Cyan
Write-Host "- $hooksCreated hooks Git crÃ©Ã©s ou mis Ã  jour" -ForegroundColor Green

if ($hooksCreated -gt 0) {
    Write-Host "`nLes hooks Git ont Ã©tÃ© installÃ©s avec succÃ¨s." -ForegroundColor Green
    Write-Host "Ces hooks permettront de:" -ForegroundColor White
    Write-Host "- VÃ©rifier les mÃ©tadonnÃ©es des scripts avant un commit" -ForegroundColor White
    Write-Host "- Mettre Ã  jour l'inventaire des scripts aprÃ¨s un commit" -ForegroundColor White
    Write-Host "- Mettre Ã  jour l'inventaire des scripts aprÃ¨s un merge" -ForegroundColor White
    
    Write-Host "`nNote: Pour ignorer les hooks lors d'un commit, utilisez l'option --no-verify:" -ForegroundColor Yellow
    Write-Host "git commit --no-verify -m 'Message de commit'" -ForegroundColor White
}
