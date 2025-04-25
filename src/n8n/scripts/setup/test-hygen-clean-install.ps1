<#
.SYNOPSIS
    Script de test de l'installation de Hygen dans un environnement propre.

.DESCRIPTION
    Ce script crée un dossier temporaire et y teste l'installation de Hygen
    pour vérifier que le script d'installation fonctionne correctement.

.PARAMETER TempFolder
    Chemin du dossier temporaire à utiliser. Si non spécifié, un dossier temporaire sera créé.

.PARAMETER KeepTemp
    Si spécifié, le dossier temporaire ne sera pas supprimé après le test.

.EXAMPLE
    .\test-hygen-clean-install.ps1
    Teste l'installation de Hygen dans un dossier temporaire.

.EXAMPLE
    .\test-hygen-clean-install.ps1 -TempFolder "C:\Temp\HygenTest" -KeepTemp
    Teste l'installation de Hygen dans le dossier spécifié et conserve le dossier après le test.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-08
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [string]$TempFolder = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$KeepTemp = $false
)

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Fonction pour afficher un message de succès
function Write-Success {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✓ $Message" -ForegroundColor $successColor
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✗ $Message" -ForegroundColor $errorColor
}

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "ℹ $Message" -ForegroundColor $infoColor
}

# Fonction pour afficher un message d'avertissement
function Write-Warning {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "⚠ $Message" -ForegroundColor $warningColor
}

# Fonction pour créer un dossier temporaire
function New-TempFolder {
    if ([string]::IsNullOrEmpty($TempFolder)) {
        $tempFolder = Join-Path -Path $env:TEMP -ChildPath "HygenTest-$(Get-Random)"
    } else {
        $tempFolder = $TempFolder
    }
    
    if (Test-Path -Path $tempFolder) {
        Write-Warning "Le dossier temporaire existe déjà: $tempFolder"
        if ($PSCmdlet.ShouldProcess($tempFolder, "Supprimer le dossier existant")) {
            Remove-Item -Path $tempFolder -Recurse -Force
            Write-Info "Dossier temporaire existant supprimé"
        } else {
            Write-Error "Impossible de continuer sans supprimer le dossier existant"
            return $null
        }
    }
    
    if ($PSCmdlet.ShouldProcess($tempFolder, "Créer le dossier temporaire")) {
        New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null
        Write-Success "Dossier temporaire créé: $tempFolder"
        return $tempFolder
    } else {
        return $null
    }
}

# Fonction pour copier les fichiers nécessaires
function Copy-RequiredFiles {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DestinationFolder
    )
    
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.Parent.FullName
    
    # Créer la structure de dossiers
    $n8nFolder = Join-Path -Path $DestinationFolder -ChildPath "n8n"
    $scriptsFolder = Join-Path -Path $n8nFolder -ChildPath "scripts"
    $setupFolder = Join-Path -Path $scriptsFolder -ChildPath "setup"
    
    if ($PSCmdlet.ShouldProcess("Structure de dossiers", "Créer")) {
        New-Item -Path $setupFolder -ItemType Directory -Force | Out-Null
        Write-Success "Structure de dossiers créée"
    }
    
    # Copier le script d'installation
    $sourceScript = Join-Path -Path $projectRoot -ChildPath "n8n\scripts\setup\install-hygen.ps1"
    $destinationScript = Join-Path -Path $setupFolder -ChildPath "install-hygen.ps1"
    
    if ($PSCmdlet.ShouldProcess($sourceScript, "Copier vers $destinationScript")) {
        Copy-Item -Path $sourceScript -Destination $destinationScript -Force
        Write-Success "Script d'installation copié"
    }
    
    # Copier le script de vérification de structure
    $sourceScript = Join-Path -Path $projectRoot -ChildPath "n8n\scripts\setup\ensure-hygen-structure.ps1"
    $destinationScript = Join-Path -Path $setupFolder -ChildPath "ensure-hygen-structure.ps1"
    
    if ($PSCmdlet.ShouldProcess($sourceScript, "Copier vers $destinationScript")) {
        Copy-Item -Path $sourceScript -Destination $destinationScript -Force
        Write-Success "Script de vérification de structure copié"
    }
    
    # Créer un package.json minimal
    $packageJsonPath = Join-Path -Path $DestinationFolder -ChildPath "package.json"
    $packageJson = @{
        name = "hygen-test"
        version = "1.0.0"
        description = "Test d'installation de Hygen"
        scripts = @{
            test = "echo ""Test"""
        }
        devDependencies = @{}
    } | ConvertTo-Json
    
    if ($PSCmdlet.ShouldProcess($packageJsonPath, "Créer")) {
        Set-Content -Path $packageJsonPath -Value $packageJson
        Write-Success "Fichier package.json créé"
    }
    
    return $true
}

# Fonction pour exécuter le script d'installation
function Start-HygenInstallation {
    param (
        [Parameter(Mandatory=$true)]
        [string]$TempFolder
    )
    
    $installScript = Join-Path -Path $TempFolder -ChildPath "n8n\scripts\setup\install-hygen.ps1"
    
    if (-not (Test-Path -Path $installScript)) {
        Write-Error "Le script d'installation n'existe pas: $installScript"
        return $false
    }
    
    Write-Info "Exécution du script d'installation..."
    
    try {
        if ($PSCmdlet.ShouldProcess($installScript, "Exécuter")) {
            # Changer le répertoire courant
            $currentLocation = Get-Location
            Set-Location -Path $TempFolder
            
            # Exécuter le script d'installation
            & $installScript
            
            # Revenir au répertoire d'origine
            Set-Location -Path $currentLocation
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Script d'installation exécuté avec succès"
                return $true
            } else {
                Write-Error "Erreur lors de l'exécution du script d'installation (code: $LASTEXITCODE)"
                return $false
            }
        } else {
            return $true
        }
    }
    catch {
        Write-Error "Erreur lors de l'exécution du script d'installation: $_"
        return $false
    }
}

# Fonction pour vérifier l'installation
function Test-Installation {
    param (
        [Parameter(Mandatory=$true)]
        [string]$TempFolder
    )
    
    $success = $true
    
    # Vérifier si le dossier _templates existe
    $templatesFolder = Join-Path -Path $TempFolder -ChildPath "_templates"
    if (Test-Path -Path $templatesFolder) {
        Write-Success "Le dossier _templates a été créé"
    } else {
        Write-Error "Le dossier _templates n'a pas été créé"
        $success = $false
    }
    
    # Vérifier si la structure de dossiers a été créée
    $n8nFolder = Join-Path -Path $TempFolder -ChildPath "n8n"
    $foldersToCheck = @(
        "automation",
        "core\workflows",
        "integrations",
        "docs",
        "scripts\utils",
        "cmd\utils"
    )
    
    foreach ($folder in $foldersToCheck) {
        $folderPath = Join-Path -Path $n8nFolder -ChildPath $folder
        if (Test-Path -Path $folderPath) {
            Write-Success "Le dossier n8n\$folder a été créé"
        } else {
            Write-Error "Le dossier n8n\$folder n'a pas été créé"
            $success = $false
        }
    }
    
    # Vérifier si Hygen est installé
    $packageJsonPath = Join-Path -Path $TempFolder -ChildPath "package.json"
    if (Test-Path -Path $packageJsonPath) {
        $packageJson = Get-Content -Path $packageJsonPath -Raw | ConvertFrom-Json
        if ($packageJson.devDependencies.hygen) {
            Write-Success "Hygen a été ajouté aux devDependencies"
        } else {
            Write-Error "Hygen n'a pas été ajouté aux devDependencies"
            $success = $false
        }
    } else {
        Write-Error "Le fichier package.json n'existe pas"
        $success = $false
    }
    
    return $success
}

# Fonction pour nettoyer le dossier temporaire
function Remove-TempFolder {
    param (
        [Parameter(Mandatory=$true)]
        [string]$TempFolder
    )
    
    if ($KeepTemp) {
        Write-Info "Le dossier temporaire est conservé: $TempFolder"
        return
    }
    
    if ($PSCmdlet.ShouldProcess($TempFolder, "Supprimer")) {
        Remove-Item -Path $TempFolder -Recurse -Force
        Write-Success "Dossier temporaire supprimé"
    }
}

# Fonction principale
function Start-CleanInstallTest {
    Write-Info "Test d'installation de Hygen dans un environnement propre..."
    
    # Créer un dossier temporaire
    $tempFolder = New-TempFolder
    if (-not $tempFolder) {
        Write-Error "Impossible de créer le dossier temporaire"
        return $false
    }
    
    # Copier les fichiers nécessaires
    $filesCopied = Copy-RequiredFiles -DestinationFolder $tempFolder
    if (-not $filesCopied) {
        Write-Error "Impossible de copier les fichiers nécessaires"
        Remove-TempFolder -TempFolder $tempFolder
        return $false
    }
    
    # Exécuter le script d'installation
    $installationSuccess = Start-HygenInstallation -TempFolder $tempFolder
    if (-not $installationSuccess) {
        Write-Error "L'installation a échoué"
        Remove-TempFolder -TempFolder $tempFolder
        return $false
    }
    
    # Vérifier l'installation
    $installationValid = Test-Installation -TempFolder $tempFolder
    if (-not $installationValid) {
        Write-Error "La vérification de l'installation a échoué"
        Remove-TempFolder -TempFolder $tempFolder
        return $false
    }
    
    # Nettoyer le dossier temporaire
    Remove-TempFolder -TempFolder $tempFolder
    
    Write-Success "Test d'installation réussi"
    return $true
}

# Exécuter le test
Start-CleanInstallTest
