# Script pour installer un hook Git qui met à jour automatiquement la roadmap

# Importer le module de mise à jour de la roadmap
$updaterPath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapUpdater.ps1"
if (Test-Path -Path $updaterPath) {
    . $updaterPath
}
else {
    Write-Error "Le module de mise à jour de la roadmap est introuvable: $updaterPath"
    exit 1
}

# Fonction pour obtenir le chemin du dépôt Git



# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Écrire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # Créer le répertoire de logs si nécessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'écriture dans le journal
    }
}
try {
    # Script principal
# Script pour installer un hook Git qui met à jour automatiquement la roadmap

# Importer le module de mise à jour de la roadmap
$updaterPath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapUpdater.ps1"
if (Test-Path -Path $updaterPath) {
    . $updaterPath
}
else {
    Write-Error "Le module de mise à jour de la roadmap est introuvable: $updaterPath"
    exit 1
}

# Fonction pour obtenir le chemin du dépôt Git
function Get-GitRepositoryPath {
    $currentPath = Get-Location
    
    while ($currentPath) {
        $gitPath = Join-Path -Path $currentPath -ChildPath ".git"
        
        if (Test-Path -Path $gitPath -PathType Container) {
            return $currentPath
        }
        
        $parentPath = Split-Path -Path $currentPath -Parent
        
        if ($parentPath -eq $currentPath) {
            return $null
        }
        
        $currentPath = $parentPath
    }
    
    return $null
}

# Fonction pour installer le hook pre-commit
function Install-PreCommitHook {
    # Obtenir le chemin du dépôt Git
    $repoPath = Get-GitRepositoryPath
    
    if (-not $repoPath) {
        Write-Error "Aucun dépôt Git trouvé."
        return $false
    }
    
    # Chemin du hook pre-commit
    $hooksPath = Join-Path -Path $repoPath -ChildPath ".git\hooks"
    $preCommitPath = Join-Path -Path $hooksPath -ChildPath "pre-commit"
    
    # Créer le dossier hooks s'il n'existe pas
    if (-not (Test-Path -Path $hooksPath)) {
        New-Item -Path $hooksPath -ItemType Directory -Force | Out-Null
    }
    
    # Contenu du hook pre-commit
    $hookContent = @"
#!/bin/sh
#
# Pre-commit hook pour mettre à jour automatiquement la roadmap
#

# Chemin relatif du script PowerShell
SCRIPT_PATH="ProjectManagement/Roadmap/RoadmapUpdater.ps1"

# Vérifier si le script existe
if [ -f "\$SCRIPT_PATH" ]; then
    echo "Mise à jour de la roadmap..."
    powershell.exe -ExecutionPolicy Bypass -File "\$SCRIPT_PATH" -Command "Update-Roadmap"
    
    # Vérifier si la roadmap a été modifiée
    if git diff --quiet -- "Roadmap\roadmap_perso.md"; then
        echo "Aucune modification de la roadmap."
    else
        echo "La roadmap a été mise à jour. Ajout des modifications au commit..."
        git add "Roadmap\roadmap_perso.md"
    fi
else
    echo "Script de mise à jour de la roadmap introuvable: \$SCRIPT_PATH"
    exit 1
fi

exit 0
"@
    
    # Enregistrer le hook
    $hookContent | Set-Content -Path $preCommitPath -Encoding ASCII
    
    # Rendre le hook exécutable
    if ($IsLinux -or $IsMacOS) {
        chmod +x $preCommitPath
    }
    
    Write-Host "Hook pre-commit installé avec succès dans: $preCommitPath"
    return $true
}

# Fonction pour installer le hook post-merge
function Install-PostMergeHook {
    # Obtenir le chemin du dépôt Git
    $repoPath = Get-GitRepositoryPath
    
    if (-not $repoPath) {
        Write-Error "Aucun dépôt Git trouvé."
        return $false
    }
    
    # Chemin du hook post-merge
    $hooksPath = Join-Path -Path $repoPath -ChildPath ".git\hooks"
    $postMergePath = Join-Path -Path $hooksPath -ChildPath "post-merge"
    
    # Créer le dossier hooks s'il n'existe pas
    if (-not (Test-Path -Path $hooksPath)) {
        New-Item -Path $hooksPath -ItemType Directory -Force | Out-Null
    }
    
    # Contenu du hook post-merge
    $hookContent = @"
#!/bin/sh
#
# Post-merge hook pour mettre à jour automatiquement la roadmap
#

# Chemin relatif du script PowerShell
SCRIPT_PATH="ProjectManagement/Roadmap/RoadmapUpdater.ps1"

# Vérifier si le script existe
if [ -f "\$SCRIPT_PATH" ]; then
    echo "Mise à jour de la roadmap après fusion..."
    powershell.exe -ExecutionPolicy Bypass -File "\$SCRIPT_PATH" -Command "Update-Roadmap"
    
    # Vérifier si la roadmap a été modifiée
    if git diff --quiet -- "Roadmap\roadmap_perso.md"; then
        echo "Aucune modification de la roadmap."
    else
        echo "La roadmap a été mise à jour. Création d'un nouveau commit..."
        git add "Roadmap\roadmap_perso.md"
        git commit -m "Mise à jour automatique de la roadmap après fusion"
    fi
else
    echo "Script de mise à jour de la roadmap introuvable: \$SCRIPT_PATH"
    exit 1
fi

exit 0
"@
    
    # Enregistrer le hook
    $hookContent | Set-Content -Path $postMergePath -Encoding ASCII
    
    # Rendre le hook exécutable
    if ($IsLinux -or $IsMacOS) {
        chmod +x $postMergePath
    }
    
    Write-Host "Hook post-merge installé avec succès dans: $postMergePath"
    return $true
}

# Installer les hooks
Write-Host "Installation des hooks Git pour la mise à jour automatique de la roadmap..."
$preCommitInstalled = Install-PreCommitHook
$postMergeInstalled = Install-PostMergeHook

if ($preCommitInstalled -and $postMergeInstalled) {
    Write-Host "Installation terminée avec succès."
    Write-Host "La roadmap sera automatiquement mise à jour avant chaque commit et après chaque fusion."
}
else {
    Write-Host "L'installation a échoué."
}

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "Exécution du script terminée."
}
