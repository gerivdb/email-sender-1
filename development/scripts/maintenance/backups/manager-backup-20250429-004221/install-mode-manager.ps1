<#
.SYNOPSIS
    Script d'installation du mode MANAGER.

.DESCRIPTION
    Ce script installe le mode MANAGER en :
    1. Copiant les fichiers nécessaires dans les bons répertoires
    2. Mettant à jour la configuration pour inclure le mode MANAGER
    3. Créant des liens symboliques pour faciliter l'accès au mode MANAGER

.PARAMETER Force
    Indique si les modifications doivent être appliquées sans confirmation.
    Par défaut : $false (mode simulation).

.PARAMETER BackupFiles
    Indique si des copies de sauvegarde des fichiers originaux doivent être créées.
    Par défaut : $true.

.EXAMPLE
    .\install-mode-manager.ps1 -Force

.NOTES
    Auteur: Mode Manager Team
    Version: 1.0
    Date de création: 2023-08-15
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$BackupFiles = $true
)

# Chemin de base du projet
$basePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
if (-not (Test-Path -Path $basePath)) {
    $basePath = $PSScriptRoot
    while ((Split-Path -Path $basePath -Leaf) -ne "EMAIL_SENDER_1" -and (Split-Path -Path $basePath) -ne "") {
        $basePath = Split-Path -Path $basePath
    }
}

# Afficher les informations de démarrage
Write-Host "Installation du mode MANAGER" -ForegroundColor Cyan
Write-Host "Mode : " -NoNewline
if ($Force) {
    Write-Host "Installation" -ForegroundColor Yellow
} else {
    Write-Host "Simulation (utilisez -Force pour installer)" -ForegroundColor Gray
}
Write-Host "Sauvegarde des fichiers originaux : " -NoNewline
if ($BackupFiles) {
    Write-Host "Activée" -ForegroundColor Green
} else {
    Write-Host "Désactivée" -ForegroundColor Yellow
}

# Fonction pour créer une sauvegarde d'un fichier
function Backup-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-not (Test-Path -Path $FilePath)) {
        Write-Warning "Le fichier à sauvegarder n'existe pas : $FilePath"
        return
    }

    $backupPath = "$FilePath.bak"
    $i = 1
    while (Test-Path -Path $backupPath) {
        $backupPath = "$FilePath.bak$i"
        $i++
    }

    if ($PSCmdlet.ShouldProcess($FilePath, "Créer une sauvegarde")) {
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        Write-Host "Sauvegarde créée : $backupPath" -ForegroundColor Green
    }
}

# Fonction pour créer un répertoire s'il n'existe pas
function Ensure-Directory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath
    )

    if (-not (Test-Path -Path $DirectoryPath)) {
        if ($PSCmdlet.ShouldProcess($DirectoryPath, "Créer le répertoire")) {
            New-Item -Path $DirectoryPath -ItemType Directory -Force | Out-Null
            Write-Host "Répertoire créé : $DirectoryPath" -ForegroundColor Green
        }
    }
}

# Fonction pour copier un fichier
function Copy-FileWithBackup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup = $true
    )

    if (-not (Test-Path -Path $SourcePath)) {
        Write-Warning "Le fichier source n'existe pas : $SourcePath"
        return
    }

    # Créer le répertoire de destination s'il n'existe pas
    $destinationDir = Split-Path -Path $DestinationPath -Parent
    Ensure-Directory -DirectoryPath $destinationDir

    # Créer une sauvegarde si le fichier de destination existe et que la sauvegarde est activée
    if ((Test-Path -Path $DestinationPath) -and $CreateBackup) {
        Backup-File -FilePath $DestinationPath
    }

    if ($PSCmdlet.ShouldProcess($DestinationPath, "Copier le fichier")) {
        Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
        Write-Host "Fichier copié : $SourcePath -> $DestinationPath" -ForegroundColor Green
    }
}

# Fonction pour mettre à jour la configuration
function Update-Configuration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,

        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup = $true
    )

    if (-not (Test-Path -Path $ConfigPath)) {
        Write-Warning "Le fichier de configuration n'existe pas : $ConfigPath"
        return
    }

    # Créer une sauvegarde si la sauvegarde est activée
    if ($CreateBackup) {
        Backup-File -FilePath $ConfigPath
    }

    try {
        # Lire le contenu du fichier de configuration
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

        # Vérifier si le mode MANAGER existe déjà dans la configuration
        $managerExists = $false
        if ($config.Modes -and $config.Modes.PSObject.Properties.Name -contains "Manager") {
            $managerExists = $true
        }

        # Ajouter le mode MANAGER s'il n'existe pas
        if (-not $managerExists) {
            if (-not $config.Modes) {
                $config | Add-Member -MemberType NoteProperty -Name "Modes" -Value ([PSCustomObject]@{})
            }

            $config.Modes | Add-Member -MemberType NoteProperty -Name "Manager" -Value ([PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\scripts\manager\mode-manager.ps1"
            })

            if ($PSCmdlet.ShouldProcess($ConfigPath, "Mettre à jour la configuration")) {
                $config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
                Write-Host "Configuration mise à jour : $ConfigPath" -ForegroundColor Green
            }
        } else {
            Write-Host "Le mode MANAGER existe déjà dans la configuration : $ConfigPath" -ForegroundColor Yellow
        }
    } catch {
        Write-Error "Erreur lors de la mise à jour de la configuration : $_"
    }
}

# Fonction pour créer un lien symbolique
function Create-SymbolicLink {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$LinkPath
    )

    if (-not (Test-Path -Path $SourcePath)) {
        Write-Warning "Le fichier source n'existe pas : $SourcePath"
        return
    }

    # Supprimer le lien s'il existe déjà
    if (Test-Path -Path $LinkPath) {
        if ($PSCmdlet.ShouldProcess($LinkPath, "Supprimer le lien existant")) {
            Remove-Item -Path $LinkPath -Force
            Write-Host "Lien existant supprimé : $LinkPath" -ForegroundColor Yellow
        }
    }

    # Créer le répertoire parent s'il n'existe pas
    $linkDir = Split-Path -Path $LinkPath -Parent
    Ensure-Directory -DirectoryPath $linkDir

    if ($PSCmdlet.ShouldProcess($LinkPath, "Créer un lien symbolique")) {
        try {
            New-Item -ItemType SymbolicLink -Path $LinkPath -Target $SourcePath -Force | Out-Null
            Write-Host "Lien symbolique créé : $LinkPath -> $SourcePath" -ForegroundColor Green
        } catch {
            Write-Warning "Impossible de créer un lien symbolique. Création d'une copie à la place."
            Copy-FileWithBackup -SourcePath $SourcePath -DestinationPath $LinkPath -CreateBackup:$false
        }
    }
}

# Chemins des fichiers source
$modeManagerScript = Join-Path -Path $PSScriptRoot -ChildPath "mode-manager.ps1"
$modeManagerDoc = Join-Path -Path $basePath -ChildPath "development\docs\guides\methodologies\mode_manager.md"
$modesConfigJson = Join-Path -Path $basePath -ChildPath "development\roadmap\parser\config\modes-config.json"

# Chemins des fichiers de configuration
$configPaths = @(
    (Join-Path -Path $basePath -ChildPath "development\roadmap\parser\config\config.json"),
    (Join-Path -Path $basePath -ChildPath "tools\scripts\roadmap-parser\config\config.json")
)

# Chemins des liens symboliques
$linkPaths = @{
    "tools\scripts\mode-manager.ps1" = $modeManagerScript
    "scripts\mode-manager.ps1" = $modeManagerScript
}

# Vérifier que les fichiers source existent
if (-not (Test-Path -Path $modeManagerScript)) {
    Write-Error "Le script mode-manager.ps1 est introuvable : $modeManagerScript"
    exit 1
}

if (-not (Test-Path -Path $modeManagerDoc)) {
    Write-Warning "La documentation du mode MANAGER est introuvable : $modeManagerDoc"
}

if (-not (Test-Path -Path $modesConfigJson)) {
    Write-Warning "Le fichier de configuration des modes est introuvable : $modesConfigJson"
}

# Mettre à jour la configuration
foreach ($configPath in $configPaths) {
    if (Test-Path -Path $configPath) {
        Update-Configuration -ConfigPath $configPath -CreateBackup:$BackupFiles
    }
}

# Créer des liens symboliques
foreach ($linkPath in $linkPaths.Keys) {
    $fullLinkPath = Join-Path -Path $basePath -ChildPath $linkPath
    Create-SymbolicLink -SourcePath $linkPaths[$linkPath] -LinkPath $fullLinkPath
}

# Copier le fichier de configuration des modes s'il existe
if (Test-Path -Path $modesConfigJson) {
    foreach ($configPath in $configPaths) {
        $configDir = Split-Path -Path $configPath -Parent
        $destPath = Join-Path -Path $configDir -ChildPath "modes-config.json"
        Copy-FileWithBackup -SourcePath $modesConfigJson -DestinationPath $destPath -CreateBackup:$BackupFiles
    }
}

# Afficher un message de fin
Write-Host "`nInstallation du mode MANAGER terminée." -ForegroundColor Cyan
if (-not $Force) {
    Write-Host "Exécutez ce script avec le paramètre -Force pour appliquer les modifications." -ForegroundColor Yellow
}

# Afficher des exemples d'utilisation
Write-Host "`nExemples d'utilisation du mode MANAGER :" -ForegroundColor Cyan
Write-Host ".\scripts\mode-manager.ps1 -ListModes" -ForegroundColor Gray
Write-Host ".\scripts\mode-manager.ps1 -Mode CHECK -FilePath `"docs\plans\plan-modes-stepup.md`" -TaskIdentifier `"1.2.3`" -Force" -ForegroundColor Gray
Write-Host ".\scripts\mode-manager.ps1 -Chain `"GRAN,DEV-R,TEST,CHECK`" -FilePath `"docs\plans\plan-modes-stepup.md`" -TaskIdentifier `"1.2.3`"" -ForegroundColor Gray
