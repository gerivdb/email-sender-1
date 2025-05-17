#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre des hooks Git pour détecter les modifications des fichiers Markdown.
.DESCRIPTION
    Ce script configure des hooks Git pour détecter les modifications des fichiers
    Markdown et déclencher la synchronisation avec Qdrant. Il fait partie du système
    de synchronisation bidirectionnelle entre les fichiers Markdown et la base
    vectorielle Qdrant.
.PARAMETER RepositoryPath
    Chemin du dépôt Git. Par défaut, utilise le répertoire courant.
.PARAMETER HookTypes
    Types de hooks à installer. Par défaut, "post-commit", "post-merge", "post-checkout".
.PARAMETER WatcherScriptPath
    Chemin du script de surveillance à exécuter. Par défaut, utilise le script
    Watch-MarkdownFiles.ps1 dans le même répertoire.
.PARAMETER Force
    Force la réinstallation des hooks même s'ils existent déjà.
.EXAMPLE
    .\Register-GitHooks.ps1 -RepositoryPath "D:\Projets\MonProjet"
    Installe les hooks Git dans le dépôt spécifié.
.NOTES
    Nom: Register-GitHooks.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-06-10
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RepositoryPath = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [string[]]$HookTypes = @("post-commit", "post-merge", "post-checkout"),
    
    [Parameter(Mandatory = $false)]
    [string]$WatcherScriptPath = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesPath = Join-Path -Path $scriptPath -ChildPath "..\modules"
$loggingModulePath = Join-Path -Path $modulesPath -ChildPath "Logging.psm1"

if (Test-Path -Path $loggingModulePath) {
    Import-Module $loggingModulePath -Force
} else {
    # Fonction de logging simplifiée si le module n'est pas disponible
    function Write-Log {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Message,
            
            [Parameter(Mandatory = $false)]
            [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "DEBUG")]
            [string]$Level = "INFO"
        )
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$Level] $Message"
        
        # Définir la couleur en fonction du niveau
        $color = switch ($Level) {
            "INFO" { "White" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            "SUCCESS" { "Green" }
            "DEBUG" { "Cyan" }
            default { "White" }
        }
        
        # Afficher le message dans la console
        Write-Host $logMessage -ForegroundColor $color
    }
}

# Fonction pour vérifier si Git est disponible
function Test-GitAvailable {
    try {
        $gitVersion = git --version
        return $true
    } catch {
        return $false
    }
}

# Fonction pour vérifier si le chemin est un dépôt Git
function Test-GitRepository {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    try {
        Push-Location $Path
        $isGitRepo = git rev-parse --is-inside-work-tree 2>$null
        Pop-Location
        
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

# Fonction pour créer un hook Git
function New-GitHook {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $true)]
        [string]$HookType,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier que le dépôt Git existe
    if (-not (Test-GitRepository -Path $RepositoryPath)) {
        Write-Log "Le chemin spécifié n'est pas un dépôt Git valide: $RepositoryPath" -Level "ERROR"
        return $false
    }
    
    # Chemin du répertoire des hooks
    $hooksDir = Join-Path -Path $RepositoryPath -ChildPath ".git\hooks"
    
    # Vérifier que le répertoire des hooks existe
    if (-not (Test-Path -Path $hooksDir)) {
        Write-Log "Le répertoire des hooks n'existe pas: $hooksDir" -Level "ERROR"
        return $false
    }
    
    # Chemin du hook
    $hookPath = Join-Path -Path $hooksDir -ChildPath $HookType
    
    # Vérifier si le hook existe déjà
    if (Test-Path -Path $hookPath) {
        if (-not $Force) {
            Write-Log "Le hook $HookType existe déjà. Utilisez -Force pour le remplacer." -Level "WARNING"
            return $false
        }
        
        # Sauvegarder le hook existant
        $backupPath = "$hookPath.bak"
        Copy-Item -Path $hookPath -Destination $backupPath -Force
        Write-Log "Hook existant sauvegardé dans: $backupPath" -Level "INFO"
    }
    
    # Créer le contenu du hook
    $hookContent = @"
#!/bin/sh
#
# Hook $HookType pour la synchronisation Markdown-Qdrant
# Généré automatiquement par Register-GitHooks.ps1
# Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
#

# Exécuter le script PowerShell
powershell.exe -ExecutionPolicy Bypass -File "$ScriptPath" -HookType "$HookType" -RepositoryPath "$RepositoryPath"

# Sortir avec le code de retour du script PowerShell
exit $?
"@
    
    # Écrire le contenu du hook
    $hookContent | Set-Content -Path $hookPath -Encoding ASCII
    
    # Rendre le hook exécutable
    if ($IsLinux -or $IsMacOS) {
        chmod +x $hookPath
    }
    
    Write-Log "Hook $HookType créé avec succès: $hookPath" -Level "SUCCESS"
    return $true
}

# Fonction pour créer le script de traitement des hooks
function New-HookHandlerScript {
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [string]$WatcherScriptPath
    )
    
    # Créer le contenu du script
    $scriptContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Gestionnaire de hooks Git pour la synchronisation Markdown-Qdrant.
.DESCRIPTION
    Ce script est appelé par les hooks Git pour détecter les modifications
    des fichiers Markdown et déclencher la synchronisation avec Qdrant.
.PARAMETER HookType
    Type de hook qui a déclenché le script.
.PARAMETER RepositoryPath
    Chemin du dépôt Git.
.EXAMPLE
    .\Handle-GitHook.ps1 -HookType "post-commit" -RepositoryPath "D:\Projets\MonProjet"
.NOTES
    Nom: Handle-GitHook.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: $(Get-Date -Format "yyyy-MM-dd")
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$HookType,
    
    [Parameter(Mandatory = $true)]
    [string]$RepositoryPath
)

# Chemin du script de surveillance
$watcherScriptPath = "$WatcherScriptPath"

# Obtenir les fichiers Markdown modifiés
function Get-ModifiedMarkdownFiles {
    param (
        [Parameter(Mandatory = $true)]
        [string]$HookType,
        
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath
    )
    
    Push-Location $RepositoryPath
    
    try {
        $files = @()
        
        switch ($HookType) {
            "post-commit" {
                # Obtenir les fichiers modifiés dans le dernier commit
                $files = git diff-tree --no-commit-id --name-only -r HEAD | Where-Object { $_ -match '\.md$' }
            }
            "post-merge" {
                # Obtenir les fichiers modifiés lors du merge
                $files = git diff-tree --no-commit-id --name-only -r ORIG_HEAD HEAD | Where-Object { $_ -match '\.md$' }
            }
            "post-checkout" {
                # Obtenir les fichiers modifiés lors du checkout
                $files = git diff --name-only | Where-Object { $_ -match '\.md$' }
            }
            default {
                Write-Warning "Type de hook non pris en charge: $HookType"
            }
        }
        
        return $files
    } finally {
        Pop-Location
    }
}

# Traiter les fichiers modifiés
$modifiedFiles = Get-ModifiedMarkdownFiles -HookType $HookType -RepositoryPath $RepositoryPath

if ($modifiedFiles.Count -gt 0) {
    Write-Host "Fichiers Markdown modifiés détectés: $($modifiedFiles.Count)"
    
    foreach ($file in $modifiedFiles) {
        $filePath = Join-Path -Path $RepositoryPath -ChildPath $file
        Write-Host "Traitement du fichier: $filePath"
        
        # Appeler le script de surveillance pour traiter le fichier
        & $watcherScriptPath -FilePath $filePath -HookTriggered -HookType $HookType
    }
} else {
    Write-Host "Aucun fichier Markdown modifié détecté."
}
"@
    
    # Écrire le contenu du script
    $scriptContent | Set-Content -Path $OutputPath -Encoding UTF8
    
    Write-Log "Script de traitement des hooks créé avec succès: $OutputPath" -Level "SUCCESS"
    return $true
}

# Fonction principale
function Register-Hooks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RepositoryPath = (Get-Location).Path,
        
        [Parameter(Mandatory = $false)]
        [string[]]$HookTypes = @("post-commit", "post-merge", "post-checkout"),
        
        [Parameter(Mandatory = $false)]
        [string]$WatcherScriptPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    try {
        # Vérifier que Git est disponible
        if (-not (Test-GitAvailable)) {
            Write-Log "Git n'est pas disponible. Veuillez installer Git et l'ajouter au PATH." -Level "ERROR"
            return $false
        }
        
        # Vérifier que le chemin est un dépôt Git
        if (-not (Test-GitRepository -Path $RepositoryPath)) {
            Write-Log "Le chemin spécifié n'est pas un dépôt Git valide: $RepositoryPath" -Level "ERROR"
            return $false
        }
        
        # Si le chemin du script de surveillance n'est pas spécifié, utiliser celui par défaut
        if (-not $WatcherScriptPath) {
            $WatcherScriptPath = Join-Path -Path $scriptPath -ChildPath "Watch-MarkdownFiles.ps1"
        }
        
        # Vérifier que le script de surveillance existe
        if (-not (Test-Path -Path $WatcherScriptPath)) {
            Write-Log "Le script de surveillance n'existe pas: $WatcherScriptPath" -Level "ERROR"
            return $false
        }
        
        # Créer le script de traitement des hooks
        $hookHandlerPath = Join-Path -Path $scriptPath -ChildPath "Handle-GitHook.ps1"
        New-HookHandlerScript -OutputPath $hookHandlerPath -WatcherScriptPath $WatcherScriptPath
        
        # Installer les hooks
        $success = $true
        
        foreach ($hookType in $HookTypes) {
            $result = New-GitHook -RepositoryPath $RepositoryPath -HookType $hookType -ScriptPath $hookHandlerPath -Force:$Force
            
            if (-not $result) {
                $success = $false
            }
        }
        
        if ($success) {
            Write-Log "Hooks Git installés avec succès dans: $RepositoryPath" -Level "SUCCESS"
        } else {
            Write-Log "Des erreurs sont survenues lors de l'installation des hooks Git." -Level "WARNING"
        }
        
        return $success
    } catch {
        Write-Log "Erreur lors de l'installation des hooks Git: $_" -Level "ERROR"
        return $false
    }
}

# Exécuter la fonction principale avec les paramètres fournis
Register-Hooks -RepositoryPath $RepositoryPath -HookTypes $HookTypes -WatcherScriptPath $WatcherScriptPath -Force:$Force
