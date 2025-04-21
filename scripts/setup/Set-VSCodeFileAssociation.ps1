#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Associe les fichiers PowerShell (.ps1, .psm1, .psd1) à Visual Studio Code.
.DESCRIPTION
    Ce script configure Windows pour ouvrir les fichiers PowerShell (.ps1, .psm1, .psd1) 
    avec Visual Studio Code par défaut au lieu du Bloc-Notes ou d'autres applications.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-20
    Nécessite des droits d'administrateur pour modifier le registre Windows.
#>

# Vérifier si le script est exécuté en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "Ce script doit être exécuté en tant qu'administrateur. Veuillez redémarrer PowerShell en tant qu'administrateur et réessayer."
    exit 1
}

# Chemin vers VS Code
$vsCodePath = $null

# Rechercher VS Code dans les emplacements courants
$possiblePaths = @(
    "${env:ProgramFiles}\Microsoft VS Code\Code.exe",
    "${env:ProgramFiles(x86)}\Microsoft VS Code\Code.exe",
    "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\Code.exe"
)

foreach ($path in $possiblePaths) {
    if (Test-Path -Path $path) {
        $vsCodePath = $path
        break
    }
}

# Si VS Code n'est pas trouvé, demander le chemin à l'utilisateur
if (-not $vsCodePath) {
    $vsCodePath = Read-Host "Impossible de trouver VS Code automatiquement. Veuillez entrer le chemin complet vers Code.exe"
    
    if (-not (Test-Path -Path $vsCodePath)) {
        Write-Error "Le chemin spécifié n'existe pas. Veuillez vérifier le chemin et réessayer."
        exit 1
    }
}

# Échapper les guillemets dans le chemin
$vsCodePathEscaped = $vsCodePath.Replace('"', '\"')

# Extensions de fichiers PowerShell à associer
$extensions = @('.ps1', '.psm1', '.psd1')

foreach ($extension in $extensions) {
    Write-Host "Association de l'extension $extension à VS Code..." -ForegroundColor Yellow
    
    # Créer la clé de registre pour l'extension
    $extensionKey = "HKCR:\$extension"
    if (-not (Test-Path -Path $extensionKey)) {
        New-Item -Path $extensionKey -Force | Out-Null
    }
    
    # Définir la valeur par défaut
    $fileType = "VSCode$extension"
    Set-ItemProperty -Path $extensionKey -Name "(Default)" -Value $fileType
    
    # Créer la clé de registre pour le type de fichier
    $fileTypeKey = "HKCR:\$fileType"
    if (-not (Test-Path -Path $fileTypeKey)) {
        New-Item -Path $fileTypeKey -Force | Out-Null
    }
    
    # Définir la description du type de fichier
    Set-ItemProperty -Path $fileTypeKey -Name "(Default)" -Value "Fichier PowerShell $extension"
    
    # Créer la clé shell
    $shellKey = "$fileTypeKey\shell"
    if (-not (Test-Path -Path $shellKey)) {
        New-Item -Path $shellKey -Force | Out-Null
    }
    
    # Définir l'action par défaut
    Set-ItemProperty -Path $shellKey -Name "(Default)" -Value "open"
    
    # Créer la clé open
    $openKey = "$shellKey\open"
    if (-not (Test-Path -Path $openKey)) {
        New-Item -Path $openKey -Force | Out-Null
    }
    
    # Créer la clé command
    $commandKey = "$openKey\command"
    if (-not (Test-Path -Path $commandKey)) {
        New-Item -Path $commandKey -Force | Out-Null
    }
    
    # Définir la commande
    $command = "`"$vsCodePathEscaped`" `"%1`""
    Set-ItemProperty -Path $commandKey -Name "(Default)" -Value $command
    
    Write-Host "Extension $extension associée à VS Code avec succès." -ForegroundColor Green
}

# Mettre à jour l'explorateur de fichiers
Write-Host "Mise à jour de l'explorateur de fichiers..." -ForegroundColor Yellow
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer

Write-Host "`nToutes les extensions PowerShell (.ps1, .psm1, .psd1) sont maintenant associées à VS Code." -ForegroundColor Green
Write-Host "Vous pouvez maintenant double-cliquer sur ces fichiers pour les ouvrir directement dans VS Code." -ForegroundColor Green
