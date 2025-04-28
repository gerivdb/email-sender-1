# Ce script doit Ãªtre exÃ©cutÃ© avec des privilÃ¨ges d'administrateur

# VÃ©rifier si le script est exÃ©cutÃ© avec des privilÃ¨ges d'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error "Ce script doit Ãªtre exÃ©cutÃ© avec des privilÃ¨ges d'administrateur."
    exit 1
}

# DÃ©finir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$n8nNewPath = Join-Path -Path $rootPath -ChildPath "n8n-new"
$n8nSourcePath = Join-Path -Path $rootPath -ChildPath "n8n-source"
$n8nTempPath = Join-Path -Path $rootPath -ChildPath "n8n-temp"

# VÃ©rifier si les dossiers existent
if (-not (Test-Path -Path $n8nPath)) {
    Write-Error "Le dossier n8n n'existe pas."
    exit 1
}

if (-not (Test-Path -Path $n8nNewPath)) {
    Write-Error "Le dossier n8n-new n'existe pas."
    exit 1
}

# Renommer n8n en n8n-temp
Write-Host "Renommage de n8n en n8n-temp..."
try {
    Rename-Item -Path $n8nPath -NewName "n8n-temp" -Force
    Write-Host "Dossier n8n renommÃ© en n8n-temp."
} catch {
    Write-Error "Erreur lors du renommage du dossier n8n en n8n-temp : $_"
    exit 1
}

# Renommer n8n-new en n8n
Write-Host "Renommage de n8n-new en n8n..."
try {
    Rename-Item -Path $n8nNewPath -NewName "n8n" -Force
    Write-Host "Dossier n8n-new renommÃ© en n8n."
} catch {
    Write-Error "Erreur lors du renommage du dossier n8n-new en n8n : $_"
    
    # Essayer de restaurer n8n-temp en n8n
    try {
        Rename-Item -Path $n8nTempPath -NewName "n8n" -Force
        Write-Host "Dossier n8n-temp restaurÃ© en n8n."
    } catch {
        Write-Error "Erreur lors de la restauration du dossier n8n-temp en n8n : $_"
    }
    
    exit 1
}

# Renommer n8n-temp en n8n-source
Write-Host "Renommage de n8n-temp en n8n-source..."
try {
    Rename-Item -Path $n8nTempPath -NewName "n8n-source" -Force
    Write-Host "Dossier n8n-temp renommÃ© en n8n-source."
} catch {
    Write-Error "Erreur lors du renommage du dossier n8n-temp en n8n-source : $_"
    exit 1
}

Write-Host ""
Write-Host "Renommage des dossiers terminÃ©."
Write-Host "Le dossier n8n contient maintenant la nouvelle structure organisÃ©e."
Write-Host "Le dossier n8n-source contient le code source original de n8n."
