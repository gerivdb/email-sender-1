# Install-Dependencies.ps1
# Script pour installer les dépendances nécessaires au système RAG de roadmaps
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$NoPrompt
)

# Fonction de journalisation simplifiée
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
    }
    
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message" -ForegroundColor $color
}

# Fonction pour vérifier si Python est installé
function Test-PythonInstalled {
    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python (\d+\.\d+\.\d+)") {
            Write-Log "Python $($Matches[1]) trouvé." -Level "Info"
            return $true
        }
        else {
            Write-Log "Python non trouvé." -Level "Error"
            return $false
        }
    }
    catch {
        Write-Log "Python non trouvé." -Level "Error"
        return $false
    }
}

# Fonction pour installer Python
function Install-Python {
    Write-Log "Installation de Python..." -Level "Info"
    
    # Télécharger l'installateur Python
    $pythonUrl = "https://www.python.org/ftp/python/3.11.0/python-3.11.0-amd64.exe"
    $pythonInstaller = "$env:TEMP\python-3.11.0-amd64.exe"
    
    Write-Log "Téléchargement de Python depuis $pythonUrl..." -Level "Info"
    Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller
    
    # Installer Python
    Write-Log "Installation de Python..." -Level "Info"
    Start-Process -FilePath $pythonInstaller -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1", "Include_test=0" -Wait
    
    # Vérifier si Python est installé
    if (Test-PythonInstalled) {
        Write-Log "Python installé avec succès." -Level "Success"
        return $true
    }
    else {
        Write-Log "Erreur lors de l'installation de Python." -Level "Error"
        return $false
    }
}

# Fonction pour installer les dépendances Python
function Install-PythonDependencies {
    Write-Log "Installation des dépendances Python..." -Level "Info"
    
    # Liste des dépendances
    $dependencies = @(
        "sentence-transformers",
        "qdrant-client",
        "matplotlib",
        "networkx",
        "pyvis"
    )
    
    # Installer pip si nécessaire
    $pipVersion = python -m pip --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Installation de pip..." -Level "Info"
        python -m ensurepip --upgrade
    }
    
    # Mettre à jour pip
    Write-Log "Mise à jour de pip..." -Level "Info"
    python -m pip install --upgrade pip
    
    # Installer les dépendances
    foreach ($dependency in $dependencies) {
        Write-Log "Installation de $dependency..." -Level "Info"
        python -m pip install $dependency
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Erreur lors de l'installation de $dependency." -Level "Error"
            return $false
        }
    }
    
    Write-Log "Dépendances Python installées avec succès." -Level "Success"
    return $true
}

# Fonction pour vérifier si Docker est installé
function Test-DockerInstalled {
    try {
        $dockerVersion = docker --version 2>&1
        if ($dockerVersion -match "Docker version (\d+\.\d+\.\d+)") {
            Write-Log "Docker $($Matches[1]) trouvé." -Level "Info"
            return $true
        }
        else {
            Write-Log "Docker non trouvé." -Level "Error"
            return $false
        }
    }
    catch {
        Write-Log "Docker non trouvé." -Level "Error"
        return $false
    }
}

# Fonction pour installer Docker
function Install-Docker {
    Write-Log "Installation de Docker..." -Level "Info"
    
    # Vérifier si l'utilisateur est administrateur
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Log "Cette opération nécessite des privilèges d'administrateur." -Level "Error"
        Write-Log "Veuillez exécuter ce script en tant qu'administrateur." -Level "Info"
        return $false
    }
    
    # Télécharger l'installateur Docker
    $dockerUrl = "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
    $dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"
    
    Write-Log "Téléchargement de Docker depuis $dockerUrl..." -Level "Info"
    Invoke-WebRequest -Uri $dockerUrl -OutFile $dockerInstaller
    
    # Installer Docker
    Write-Log "Installation de Docker..." -Level "Info"
    Start-Process -FilePath $dockerInstaller -ArgumentList "install", "--quiet" -Wait
    
    # Vérifier si Docker est installé
    if (Test-DockerInstalled) {
        Write-Log "Docker installé avec succès." -Level "Success"
        return $true
    }
    else {
        Write-Log "Erreur lors de l'installation de Docker." -Level "Error"
        return $false
    }
}

# Fonction pour démarrer Qdrant
function Start-Qdrant {
    Write-Log "Démarrage de Qdrant..." -Level "Info"
    
    # Vérifier si le conteneur Qdrant existe déjà
    $qdrantContainer = docker ps -a --filter "name=qdrant" --format "{{.Names}}" 2>&1
    
    if ($qdrantContainer -eq "qdrant") {
        # Vérifier si le conteneur est en cours d'exécution
        $qdrantRunning = docker ps --filter "name=qdrant" --format "{{.Names}}" 2>&1
        
        if ($qdrantRunning -eq "qdrant") {
            Write-Log "Qdrant est déjà en cours d'exécution." -Level "Info"
        }
        else {
            # Démarrer le conteneur existant
            Write-Log "Démarrage du conteneur Qdrant existant..." -Level "Info"
            docker start qdrant
        }
    }
    else {
        # Créer et démarrer un nouveau conteneur
        Write-Log "Création d'un nouveau conteneur Qdrant..." -Level "Info"
        docker run -d --name qdrant -p 6333:6333 -p 6334:6334 -v qdrant_storage:/qdrant/storage qdrant/qdrant
    }
    
    # Vérifier si Qdrant est en cours d'exécution
    $qdrantRunning = docker ps --filter "name=qdrant" --format "{{.Names}}" 2>&1
    
    if ($qdrantRunning -eq "qdrant") {
        Write-Log "Qdrant démarré avec succès." -Level "Success"
        return $true
    }
    else {
        Write-Log "Erreur lors du démarrage de Qdrant." -Level "Error"
        return $false
    }
}

# Fonction principale
function Install-Dependencies {
    param (
        [switch]$Force,
        [switch]$NoPrompt
    )
    
    Write-Log "Installation des dépendances pour le système RAG de roadmaps..." -Level "Info"
    
    # Demander confirmation si -NoPrompt n'est pas spécifié
    if (-not $NoPrompt) {
        $confirmation = Read-Host "Voulez-vous installer les dépendances nécessaires ? (O/N)"
        if ($confirmation -ne "O") {
            Write-Log "Opération annulée." -Level "Info"
            return $false
        }
    }
    
    # Vérifier si Python est installé
    $pythonInstalled = Test-PythonInstalled
    
    # Installer Python si nécessaire
    if (-not $pythonInstalled) {
        if ($Force -or $NoPrompt -or (Read-Host "Python n'est pas installé. Voulez-vous l'installer ? (O/N)") -eq "O") {
            $pythonInstalled = Install-Python
            
            if (-not $pythonInstalled) {
                Write-Log "Impossible de continuer sans Python." -Level "Error"
                return $false
            }
        }
        else {
            Write-Log "Impossible de continuer sans Python." -Level "Error"
            return $false
        }
    }
    
    # Installer les dépendances Python
    $pythonDependenciesInstalled = Install-PythonDependencies
    
    if (-not $pythonDependenciesInstalled) {
        Write-Log "Erreur lors de l'installation des dépendances Python." -Level "Error"
        return $false
    }
    
    # Vérifier si Docker est installé
    $dockerInstalled = Test-DockerInstalled
    
    # Installer Docker si nécessaire
    if (-not $dockerInstalled) {
        if ($Force -or $NoPrompt -or (Read-Host "Docker n'est pas installé. Voulez-vous l'installer ? (O/N)") -eq "O") {
            $dockerInstalled = Install-Docker
            
            if (-not $dockerInstalled) {
                Write-Log "Impossible de continuer sans Docker." -Level "Error"
                return $false
            }
        }
        else {
            Write-Log "Impossible de continuer sans Docker." -Level "Error"
            return $false
        }
    }
    
    # Démarrer Qdrant
    $qdrantStarted = Start-Qdrant
    
    if (-not $qdrantStarted) {
        Write-Log "Erreur lors du démarrage de Qdrant." -Level "Error"
        return $false
    }
    
    Write-Log "Toutes les dépendances ont été installées avec succès." -Level "Success"
    return $true
}

# Exécution principale
try {
    $result = Install-Dependencies -Force:$Force -NoPrompt:$NoPrompt
    
    # Retourner le résultat
    return $result
}
catch {
    Write-Log "Erreur lors de l'installation des dépendances : $_" -Level "Error"
    throw $_
}
