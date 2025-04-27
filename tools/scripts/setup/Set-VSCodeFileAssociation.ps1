#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Associe les fichiers PowerShell (.ps1, .psm1, .psd1) Ã  Visual Studio Code.
.DESCRIPTION
    Ce script configure Windows pour ouvrir les fichiers PowerShell (.ps1, .psm1, .psd1) 
    avec Visual Studio Code par dÃ©faut au lieu du Bloc-Notes ou d'autres applications.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-20
    NÃ©cessite des droits d'administrateur pour modifier le registre Windows.
#>

# VÃ©rifier si le script est exÃ©cutÃ© en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "Ce script doit Ãªtre exÃ©cutÃ© en tant qu'administrateur. Veuillez redÃ©marrer PowerShell en tant qu'administrateur et rÃ©essayer."
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

# Si VS Code n'est pas trouvÃ©, demander le chemin Ã  l'utilisateur
if (-not $vsCodePath) {
    $vsCodePath = Read-Host "Impossible de trouver VS Code automatiquement. Veuillez entrer le chemin complet vers Code.exe"
    
    if (-not (Test-Path -Path $vsCodePath)) {
        Write-Error "Le chemin spÃ©cifiÃ© n'existe pas. Veuillez vÃ©rifier le chemin et rÃ©essayer."
        exit 1
    }
}

# Ã‰chapper les guillemets dans le chemin
$vsCodePathEscaped = $vsCodePath.Replace('"', '\"')

# Extensions de fichiers PowerShell Ã  associer
$extensions = @('.ps1', '.psm1', '.psd1')

foreach ($extension in $extensions) {
    Write-Host "Association de l'extension $extension Ã  VS Code..." -ForegroundColor Yellow
    
    # CrÃ©er la clÃ© de registre pour l'extension
    $extensionKey = "HKCR:\$extension"
    if (-not (Test-Path -Path $extensionKey)) {
        New-Item -Path $extensionKey -Force | Out-Null
    }
    
    # DÃ©finir la valeur par dÃ©faut
    $fileType = "VSCode$extension"
    Set-ItemProperty -Path $extensionKey -Name "(Default)" -Value $fileType
    
    # CrÃ©er la clÃ© de registre pour le type de fichier
    $fileTypeKey = "HKCR:\$fileType"
    if (-not (Test-Path -Path $fileTypeKey)) {
        New-Item -Path $fileTypeKey -Force | Out-Null
    }
    
    # DÃ©finir la description du type de fichier
    Set-ItemProperty -Path $fileTypeKey -Name "(Default)" -Value "Fichier PowerShell $extension"
    
    # CrÃ©er la clÃ© shell
    $shellKey = "$fileTypeKey\shell"
    if (-not (Test-Path -Path $shellKey)) {
        New-Item -Path $shellKey -Force | Out-Null
    }
    
    # DÃ©finir l'action par dÃ©faut
    Set-ItemProperty -Path $shellKey -Name "(Default)" -Value "open"
    
    # CrÃ©er la clÃ© open
    $openKey = "$shellKey\open"
    if (-not (Test-Path -Path $openKey)) {
        New-Item -Path $openKey -Force | Out-Null
    }
    
    # CrÃ©er la clÃ© command
    $commandKey = "$openKey\command"
    if (-not (Test-Path -Path $commandKey)) {
        New-Item -Path $commandKey -Force | Out-Null
    }
    
    # DÃ©finir la commande
    $command = "`"$vsCodePathEscaped`" `"%1`""
    Set-ItemProperty -Path $commandKey -Name "(Default)" -Value $command
    
    Write-Host "Extension $extension associÃ©e Ã  VS Code avec succÃ¨s." -ForegroundColor Green
}

# Mettre Ã  jour l'explorateur de fichiers
Write-Host "Mise Ã  jour de l'explorateur de fichiers..." -ForegroundColor Yellow
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer

Write-Host "`nToutes les extensions PowerShell (.ps1, .psm1, .psd1) sont maintenant associÃ©es Ã  VS Code." -ForegroundColor Green
Write-Host "Vous pouvez maintenant double-cliquer sur ces fichiers pour les ouvrir directement dans VS Code." -ForegroundColor Green
