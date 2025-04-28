# Script pour installer un hook Git qui met Ã  jour automatiquement la roadmap

# Importer le module de mise Ã  jour de la roadmap
$updaterPath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapUpdater.ps1"
if (Test-Path -Path $updaterPath) {
    . $updaterPath
}
else {
    Write-Error "Le module de mise Ã  jour de la roadmap est introuvable: $updaterPath"
    exit 1
}

# Fonction pour obtenir le chemin du dÃ©pÃ´t Git



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
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
# Script pour installer un hook Git qui met Ã  jour automatiquement la roadmap

# Importer le module de mise Ã  jour de la roadmap
$updaterPath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapUpdater.ps1"
if (Test-Path -Path $updaterPath) {
    . $updaterPath
}
else {
    Write-Error "Le module de mise Ã  jour de la roadmap est introuvable: $updaterPath"
    exit 1
}

# Fonction pour obtenir le chemin du dÃ©pÃ´t Git
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
    # Obtenir le chemin du dÃ©pÃ´t Git
    $repoPath = Get-GitRepositoryPath
    
    if (-not $repoPath) {
        Write-Error "Aucun dÃ©pÃ´t Git trouvÃ©."
        return $false
    }
    
    # Chemin du hook pre-commit
    $hooksPath = Join-Path -Path $repoPath -ChildPath ".git\hooks"
    $preCommitPath = Join-Path -Path $hooksPath -ChildPath "pre-commit"
    
    # CrÃ©er le dossier hooks s'il n'existe pas
    if (-not (Test-Path -Path $hooksPath)) {
        New-Item -Path $hooksPath -ItemType Directory -Force | Out-Null
    }
    
    # Contenu du hook pre-commit
    $hookContent = @"
#!/bin/sh
#
# Pre-commit hook pour mettre Ã  jour automatiquement la roadmap
#

# Chemin relatif du script PowerShell
SCRIPT_PATH="ProjectManagement/Roadmap/RoadmapUpdater.ps1"

# VÃ©rifier si le script existe
if [ -f "\$SCRIPT_PATH" ]; then
    echo "Mise Ã  jour de la roadmap..."
    powershell.exe -ExecutionPolicy Bypass -File "\$SCRIPT_PATH" -Command "Update-Roadmap"
    
    # VÃ©rifier si la roadmap a Ã©tÃ© modifiÃ©e
    if git diff --quiet -- "Roadmap\roadmap_perso.md"; then
        echo "Aucune modification de la roadmap."
    else
        echo "La roadmap a Ã©tÃ© mise Ã  jour. Ajout des modifications au commit..."
        git add "Roadmap\roadmap_perso.md"
    fi
else
    echo "Script de mise Ã  jour de la roadmap introuvable: \$SCRIPT_PATH"
    exit 1
fi

exit 0
"@
    
    # Enregistrer le hook
    $hookContent | Set-Content -Path $preCommitPath -Encoding ASCII
    
    # Rendre le hook exÃ©cutable
    if ($IsLinux -or $IsMacOS) {
        chmod +x $preCommitPath
    }
    
    Write-Host "Hook pre-commit installÃ© avec succÃ¨s dans: $preCommitPath"
    return $true
}

# Fonction pour installer le hook post-merge
function Install-PostMergeHook {
    # Obtenir le chemin du dÃ©pÃ´t Git
    $repoPath = Get-GitRepositoryPath
    
    if (-not $repoPath) {
        Write-Error "Aucun dÃ©pÃ´t Git trouvÃ©."
        return $false
    }
    
    # Chemin du hook post-merge
    $hooksPath = Join-Path -Path $repoPath -ChildPath ".git\hooks"
    $postMergePath = Join-Path -Path $hooksPath -ChildPath "post-merge"
    
    # CrÃ©er le dossier hooks s'il n'existe pas
    if (-not (Test-Path -Path $hooksPath)) {
        New-Item -Path $hooksPath -ItemType Directory -Force | Out-Null
    }
    
    # Contenu du hook post-merge
    $hookContent = @"
#!/bin/sh
#
# Post-merge hook pour mettre Ã  jour automatiquement la roadmap
#

# Chemin relatif du script PowerShell
SCRIPT_PATH="ProjectManagement/Roadmap/RoadmapUpdater.ps1"

# VÃ©rifier si le script existe
if [ -f "\$SCRIPT_PATH" ]; then
    echo "Mise Ã  jour de la roadmap aprÃ¨s fusion..."
    powershell.exe -ExecutionPolicy Bypass -File "\$SCRIPT_PATH" -Command "Update-Roadmap"
    
    # VÃ©rifier si la roadmap a Ã©tÃ© modifiÃ©e
    if git diff --quiet -- "Roadmap\roadmap_perso.md"; then
        echo "Aucune modification de la roadmap."
    else
        echo "La roadmap a Ã©tÃ© mise Ã  jour. CrÃ©ation d'un nouveau commit..."
        git add "Roadmap\roadmap_perso.md"
        git commit -m "Mise Ã  jour automatique de la roadmap aprÃ¨s fusion"
    fi
else
    echo "Script de mise Ã  jour de la roadmap introuvable: \$SCRIPT_PATH"
    exit 1
fi

exit 0
"@
    
    # Enregistrer le hook
    $hookContent | Set-Content -Path $postMergePath -Encoding ASCII
    
    # Rendre le hook exÃ©cutable
    if ($IsLinux -or $IsMacOS) {
        chmod +x $postMergePath
    }
    
    Write-Host "Hook post-merge installÃ© avec succÃ¨s dans: $postMergePath"
    return $true
}

# Installer les hooks
Write-Host "Installation des hooks Git pour la mise Ã  jour automatique de la roadmap..."
$preCommitInstalled = Install-PreCommitHook
$postMergeInstalled = Install-PostMergeHook

if ($preCommitInstalled -and $postMergeInstalled) {
    Write-Host "Installation terminÃ©e avec succÃ¨s."
    Write-Host "La roadmap sera automatiquement mise Ã  jour avant chaque commit et aprÃ¨s chaque fusion."
}
else {
    Write-Host "L'installation a Ã©chouÃ©."
}

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
