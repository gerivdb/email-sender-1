# Script pour corriger les dossiers n8n
# Ce script doit être exécuté avec des privilèges d'administrateur

# Vérifier si le script est exécuté avec des privilèges d'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error "Ce script doit être exécuté avec des privilèges d'administrateur."
    exit 1
}

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$n8nNewPath = Join-Path -Path $rootPath -ChildPath "n8n-new"
$n8nSourcePath = Join-Path -Path $rootPath -ChildPath "n8n-source"
$n8nTempPath = Join-Path -Path $rootPath -ChildPath "n8n-temp"
$n8nFinalPath = Join-Path -Path $rootPath -ChildPath "n8n-final"

# Fonction pour arrêter tous les processus qui pourraient bloquer les dossiers
function Stop-BlockingProcesses {
    Write-Host "Arrêt des processus qui pourraient bloquer les dossiers..."
    
    # Arrêter les processus Node.js qui pourraient utiliser n8n
    Get-Process | Where-Object { $_.Name -like "*node*" } | ForEach-Object {
        try {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            Write-Host "Processus arrêté : $($_.Name) (PID: $($_.Id))"
        } catch {
            Write-Warning "Impossible d'arrêter le processus $($_.Name) (PID: $($_.Id)): $_"
        }
    }
    
    # Arrêter les processus PowerShell qui pourraient utiliser n8n
    Get-Process | Where-Object { $_.Name -like "*powershell*" -and $_.Id -ne $PID } | ForEach-Object {
        try {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            Write-Host "Processus arrêté : $($_.Name) (PID: $($_.Id))"
        } catch {
            Write-Warning "Impossible d'arrêter le processus $($_.Name) (PID: $($_.Id)): $_"
        }
    }
}

# Fonction pour créer une copie d'un dossier
function Copy-FolderContents {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )
    
    if (-not (Test-Path -Path $SourcePath)) {
        Write-Error "Le dossier source '$SourcePath' n'existe pas."
        return $false
    }
    
    if (-not (Test-Path -Path $DestinationPath)) {
        New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
    }
    
    try {
        # Utiliser robocopy pour copier les fichiers
        $robocopyArgs = @(
            "`"$SourcePath`"",
            "`"$DestinationPath`"",
            "/E",    # Copier les sous-dossiers, y compris les vides
            "/COPY:DAT", # Copier les données, les attributs et les horodatages
            "/DCOPY:T",  # Copier les horodatages des dossiers
            "/R:1",   # Nombre de tentatives pour les fichiers occupés
            "/W:1",   # Temps d'attente entre les tentatives (en secondes)
            "/NFL",   # Pas de liste de fichiers
            "/NDL",   # Pas de liste de dossiers
            "/NJH",   # Pas d'en-tête de travail
            "/NJS"    # Pas de résumé de travail
        )
        
        $robocopyProcess = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -NoNewWindow -Wait -PassThru
        
        # Robocopy retourne des codes spécifiques
        # 0 = Aucune erreur, 1 = Copié avec succès, 2 = Extras, 3 = Extras et modifiés
        # Tout code supérieur à 7 indique une erreur
        if ($robocopyProcess.ExitCode -lt 8) {
            Write-Host "Copie réussie de '$SourcePath' vers '$DestinationPath'."
            return $true
        } else {
            Write-Error "Erreur lors de la copie de '$SourcePath' vers '$DestinationPath'. Code de sortie: $($robocopyProcess.ExitCode)"
            return $false
        }
    } catch {
        Write-Error "Erreur lors de la copie de '$SourcePath' vers '$DestinationPath': $_"
        return $false
    }
}

# Fonction pour supprimer un dossier de manière forcée
function Remove-FolderForced {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    if (-not (Test-Path -Path $Path)) {
        Write-Host "Le dossier '$Path' n'existe pas."
        return $true
    }
    
    try {
        # Utiliser rd /s /q pour supprimer le dossier de manière forcée
        $rdProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c rd /s /q `"$Path`"" -NoNewWindow -Wait -PassThru
        
        if ($rdProcess.ExitCode -eq 0) {
            Write-Host "Suppression réussie du dossier '$Path'."
            return $true
        } else {
            Write-Error "Erreur lors de la suppression du dossier '$Path'. Code de sortie: $($rdProcess.ExitCode)"
            return $false
        }
    } catch {
        Write-Error "Erreur lors de la suppression du dossier '$Path': $_"
        return $false
    }
}

# Arrêter les processus qui pourraient bloquer les dossiers
Stop-BlockingProcesses

# Étape 1: Créer un dossier temporaire pour n8n-source
Write-Host ""
Write-Host "Étape 1: Création d'un dossier temporaire pour n8n-source..."
Write-Host "------------------------------------------------------------"

if (Test-Path -Path $n8nSourcePath) {
    Write-Host "Le dossier n8n-source existe déjà. Il sera supprimé."
    Remove-FolderForced -Path $n8nSourcePath
}

if (Test-Path -Path $n8nTempPath) {
    Write-Host "Le dossier n8n-temp existe déjà. Il sera supprimé."
    Remove-FolderForced -Path $n8nTempPath
}

if (Test-Path -Path $n8nFinalPath) {
    Write-Host "Le dossier n8n-final existe déjà. Il sera supprimé."
    Remove-FolderForced -Path $n8nFinalPath
}

# Étape 2: Copier n8n vers n8n-source
Write-Host ""
Write-Host "Étape 2: Copie de n8n vers n8n-source..."
Write-Host "------------------------------------------------------------"

if (Test-Path -Path $n8nPath) {
    $success = Copy-FolderContents -SourcePath $n8nPath -DestinationPath $n8nSourcePath
    
    if (-not $success) {
        Write-Error "Erreur lors de la copie de n8n vers n8n-source."
        exit 1
    }
} else {
    Write-Error "Le dossier n8n n'existe pas."
    exit 1
}

# Étape 3: Copier n8n-new vers n8n-final
Write-Host ""
Write-Host "Étape 3: Copie de n8n-new vers n8n-final..."
Write-Host "------------------------------------------------------------"

if (Test-Path -Path $n8nNewPath) {
    $success = Copy-FolderContents -SourcePath $n8nNewPath -DestinationPath $n8nFinalPath
    
    if (-not $success) {
        Write-Error "Erreur lors de la copie de n8n-new vers n8n-final."
        exit 1
    }
} else {
    Write-Error "Le dossier n8n-new n'existe pas."
    exit 1
}

# Étape 4: Supprimer les dossiers originaux
Write-Host ""
Write-Host "Étape 4: Suppression des dossiers originaux..."
Write-Host "------------------------------------------------------------"

$success = Remove-FolderForced -Path $n8nPath
if (-not $success) {
    Write-Error "Erreur lors de la suppression du dossier n8n."
    exit 1
}

$success = Remove-FolderForced -Path $n8nNewPath
if (-not $success) {
    Write-Error "Erreur lors de la suppression du dossier n8n-new."
    exit 1
}

# Étape 5: Renommer n8n-final en n8n
Write-Host ""
Write-Host "Étape 5: Renommage de n8n-final en n8n..."
Write-Host "------------------------------------------------------------"

try {
    Rename-Item -Path $n8nFinalPath -NewName "n8n" -Force
    Write-Host "Dossier n8n-final renommé en n8n."
} catch {
    Write-Error "Erreur lors du renommage du dossier n8n-final en n8n : $_"
    exit 1
}

Write-Host ""
Write-Host "Opération terminée avec succès."
Write-Host "Le dossier n8n contient maintenant la nouvelle structure organisée."
Write-Host "Le dossier n8n-source contient le code source original de n8n."
