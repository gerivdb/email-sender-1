# RestoreManager.ps1
# Module de restauration vers emplacement alternatif
# Version: 1.0
# Date: 2025-05-15

# Importer les modules necessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$extractPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "extract\ExtractManager.ps1"
$pathResolverPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "path\PathResolver.ps1"

if (Test-Path -Path $extractPath) {
    . $extractPath
} else {
    Write-Error "Le fichier ExtractManager.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $pathResolverPath) {
    . $pathResolverPath
} else {
    Write-Error "Le fichier PathResolver.ps1 est introuvable."
    exit 1
}

# Fonction pour restaurer vers un emplacement alternatif
function Restore-ToAlternateLocation {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [string]$Id,

        [Parameter(Mandatory = $true, ParameterSetName = "ByPath")]
        [string]$ArchivePath,

        [Parameter(Mandatory = $true)]
        [string]$IndexPath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Skip", "Overwrite", "Rename")]
        [string]$ConflictResolution = "Skip",

        [Parameter(Mandatory = $false)]
        [switch]$CreateTargetPath,

        [Parameter(Mandatory = $false)]
        [switch]$PreserveStructure,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [string]$LogPath = "$env:TEMP\RestoreLog.json"
    )

    # Valider la restauration
    $validateParams = @{
        IndexPath          = $IndexPath
        TargetPath         = $TargetPath
        ConflictResolution = $ConflictResolution
        CheckIntegrity     = $true
        CheckPermissions   = $true
    }

    if ($PSCmdlet.ParameterSetName -eq "ById") {
        $validateParams.Id = $Id
    } else {
        $validateParams.ArchivePath = $ArchivePath
    }

    $validation = Test-RestoreValidity @validateParams

    if ($null -eq $validation) {
        Write-Error "La validation de la restauration a echoue."
        return $null
    }

    if (-not $validation.IsValid -and -not $Force) {
        Write-Error "La restauration n'est pas valide. Utilisez -Force pour forcer la restauration."
        return $null
    }

    # Creer le repertoire cible si necessaire
    $targetDir = [System.IO.Path]::GetDirectoryName($validation.FinalPath)
    if (-not (Test-Path -Path $targetDir -PathType Container)) {
        if ($CreateTargetPath) {
            try {
                New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
            } catch {
                Write-Error "Erreur lors de la creation du repertoire cible: $($_.Exception.Message)"
                return $null
            }
        } else {
            Write-Error "Le repertoire cible n'existe pas: $targetDir"
            return $null
        }
    }

    # Extraire l'archive
    $extractParams = @{
        IndexPath        = $IndexPath
        OutputPath       = $env:TEMP
        CreateOutputPath = $true
        Overwrite        = $true
    }

    if ($PSCmdlet.ParameterSetName -eq "ById") {
        $extractParams.Id = $Id
    } else {
        $extractParams.ArchivePath = $ArchivePath
    }

    $extraction = Extract-ArchiveItem @extractParams

    if ($null -eq $extraction -or -not $extraction.Success) {
        Write-Error "L'extraction de l'archive a echoue."
        return $null
    }

    # Determiner le chemin final
    $finalPath = $validation.FinalPath

    # Verifier si le fichier cible existe
    if (Test-Path -Path $finalPath -PathType Leaf) {
        switch ($ConflictResolution) {
            "Skip" {
                Write-Warning "Le fichier cible existe deja, il sera ignore: $finalPath"

                # Nettoyer le fichier temporaire
                Remove-Item -Path $extraction.OutputPath -Force

                # Creer un objet avec les informations sur la restauration
                $result = [PSCustomObject]@{
                    Archive            = $extraction.Archive
                    SourcePath         = $extraction.SourcePath
                    TargetPath         = $finalPath
                    Success            = $false
                    Skipped            = $true
                    ConflictResolution = $ConflictResolution
                    RestoreTime        = [DateTime]::Now.ToString("o")
                }

                # Journaliser la restauration
                Add-RestoreLog -LogPath $LogPath -RestoreInfo $result

                return $result
            }
            "Rename" {
                $directory = [System.IO.Path]::GetDirectoryName($finalPath)
                $fileName = [System.IO.Path]::GetFileNameWithoutExtension($finalPath)
                $extension = [System.IO.Path]::GetExtension($finalPath)
                $counter = 1

                do {
                    $newFileName = "${fileName}_${counter}${extension}"
                    $finalPath = Join-Path -Path $directory -ChildPath $newFileName
                    $counter++
                } while (Test-Path -Path $finalPath -PathType Leaf)

                Write-Warning "Le fichier cible existe deja, il sera renomme en: $finalPath"
            }
            "Overwrite" {
                if ($PSCmdlet.ShouldProcess($finalPath, "Ecraser le fichier existant")) {
                    Write-Warning "Le fichier cible existe deja, il sera ecrase: $finalPath"
                    try {
                        Remove-Item -Path $finalPath -Force
                    } catch {
                        Write-Error "Erreur lors de la suppression du fichier existant: $($_.Exception.Message)"

                        # Nettoyer le fichier temporaire
                        Remove-Item -Path $extraction.OutputPath -Force

                        return $null
                    }
                } else {
                    Write-Warning "Operation annulee par l'utilisateur."

                    # Nettoyer le fichier temporaire
                    Remove-Item -Path $extraction.OutputPath -Force

                    return $null
                }
            }
        }
    }

    # Copier le fichier vers l'emplacement final
    try {
        if ($PSCmdlet.ShouldProcess($finalPath, "Restaurer le fichier")) {
            Copy-Item -Path $extraction.OutputPath -Destination $finalPath -Force
        } else {
            Write-Warning "Operation annulee par l'utilisateur."

            # Nettoyer le fichier temporaire
            Remove-Item -Path $extraction.OutputPath -Force

            return $null
        }
    } catch {
        Write-Error "Erreur lors de la copie du fichier: $($_.Exception.Message)"

        # Nettoyer le fichier temporaire
        Remove-Item -Path $extraction.OutputPath -Force

        return $null
    }

    # Nettoyer le fichier temporaire
    Remove-Item -Path $extraction.OutputPath -Force

    # Creer un objet avec les informations sur la restauration
    $result = [PSCustomObject]@{
        Archive            = $extraction.Archive
        SourcePath         = $extraction.SourcePath
        TargetPath         = $finalPath
        Success            = $true
        Skipped            = $false
        ConflictResolution = $ConflictResolution
        RestoreTime        = [DateTime]::Now.ToString("o")
    }

    # Journaliser la restauration
    Add-RestoreLog -LogPath $LogPath -RestoreInfo $result

    return $result
}

# Fonction pour transformer les chemins
function ConvertTo-RestorePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$SourceRoot,

        [Parameter(Mandatory = $true)]
        [string]$TargetRoot,

        [Parameter(Mandatory = $false)]
        [switch]$CreateTargetPath
    )

    # Verifier si les chemins existent
    if (-not (Test-Path -Path $SourcePath -PathType Leaf)) {
        Write-Error "Le chemin source n'existe pas: $SourcePath"
        return $null
    }

    if (-not (Test-Path -Path $SourceRoot -PathType Container)) {
        Write-Error "Le repertoire source n'existe pas: $SourceRoot"
        return $null
    }

    # Creer le repertoire cible si necessaire
    if (-not (Test-Path -Path $TargetRoot -PathType Container)) {
        if ($CreateTargetPath) {
            try {
                New-Item -Path $TargetRoot -ItemType Directory -Force | Out-Null
            } catch {
                Write-Error "Erreur lors de la creation du repertoire cible: $($_.Exception.Message)"
                return $null
            }
        } else {
            Write-Error "Le repertoire cible n'existe pas: $TargetRoot"
            return $null
        }
    }

    # Convertir le chemin source en chemin relatif par rapport au repertoire source
    $relativePath = $null
    try {
        $sourcePathAbs = [System.IO.Path]::GetFullPath($SourcePath)
        $sourceRootAbs = [System.IO.Path]::GetFullPath($SourceRoot)

        if (-not $sourcePathAbs.StartsWith($sourceRootAbs, [StringComparison]::OrdinalIgnoreCase)) {
            Write-Error "Le chemin source n'est pas sous le repertoire source."
            return $null
        }

        $relativePath = $sourcePathAbs.Substring($sourceRootAbs.Length)

        # Supprimer le separateur de chemin initial si present
        if ($relativePath.StartsWith([System.IO.Path]::DirectorySeparatorChar) -or $relativePath.StartsWith([System.IO.Path]::AltDirectorySeparatorChar)) {
            $relativePath = $relativePath.Substring(1)
        }
    } catch {
        Write-Error "Erreur lors de la conversion du chemin: $($_.Exception.Message)"
        return $null
    }

    # Construire le chemin cible
    $targetPath = Join-Path -Path $TargetRoot -ChildPath $relativePath

    # Creer le repertoire parent du chemin cible si necessaire
    $targetDir = [System.IO.Path]::GetDirectoryName($targetPath)
    if (-not (Test-Path -Path $targetDir -PathType Container)) {
        if ($CreateTargetPath) {
            try {
                New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
            } catch {
                Write-Error "Erreur lors de la creation du repertoire parent: $($_.Exception.Message)"
                return $null
            }
        } else {
            Write-Error "Le repertoire parent n'existe pas: $targetDir"
            return $null
        }
    }

    # Creer un objet avec les informations sur la transformation
    $result = [PSCustomObject]@{
        SourcePath   = $SourcePath
        SourceRoot   = $SourceRoot
        TargetRoot   = $TargetRoot
        RelativePath = $relativePath
        TargetPath   = $targetPath
    }

    return $result
}

# Fonction pour gerer les permissions
function Set-RestorePermissions {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$SourcePath = "",

        [Parameter(Mandatory = $false)]
        [switch]$InheritFromParent,

        [Parameter(Mandatory = $false)]
        [switch]$CopyFromSource
    )

    # Verifier si le chemin existe
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le chemin n'existe pas: $Path"
        return $false
    }

    try {
        # Obtenir l'ACL actuelle
        $acl = Get-Acl -Path $Path

        if ($InheritFromParent) {
            # Obtenir l'ACL du repertoire parent
            $parentPath = [System.IO.Path]::GetDirectoryName($Path)
            $parentAcl = Get-Acl -Path $parentPath

            if ($PSCmdlet.ShouldProcess($Path, "Appliquer les permissions du repertoire parent")) {
                # Appliquer l'ACL du repertoire parent
                Set-Acl -Path $Path -AclObject $parentAcl
            }
        } elseif ($CopyFromSource -and -not [string]::IsNullOrWhiteSpace($SourcePath) -and (Test-Path -Path $SourcePath)) {
            # Obtenir l'ACL du fichier source
            $sourceAcl = Get-Acl -Path $SourcePath

            if ($PSCmdlet.ShouldProcess($Path, "Appliquer les permissions du fichier source")) {
                # Appliquer l'ACL du fichier source
                Set-Acl -Path $Path -AclObject $sourceAcl
            }
        } else {
            # Ajouter les permissions par defaut
            $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($currentUser, "FullControl", "Allow")

            if ($PSCmdlet.ShouldProcess($Path, "Ajouter les permissions par defaut")) {
                # Ajouter la regle
                $acl.AddAccessRule($rule)

                # Appliquer l'ACL
                Set-Acl -Path $Path -AclObject $acl
            }
        }

        return $true
    } catch {
        Write-Error "Erreur lors de la modification des permissions: $($_.Exception.Message)"
        return $false
    }
}

# Fonction pour journaliser les redirections
function Add-RestoreLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogPath,

        [Parameter(Mandatory = $true)]
        [PSObject]$RestoreInfo
    )

    # Creer le repertoire parent si necessaire
    $logDir = [System.IO.Path]::GetDirectoryName($LogPath)
    if (-not (Test-Path -Path $logDir -PathType Container)) {
        try {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        } catch {
            Write-Error "Erreur lors de la creation du repertoire de journalisation: $($_.Exception.Message)"
            return $false
        }
    }

    # Charger le journal existant ou creer un nouveau
    $log = @()

    if (Test-Path -Path $LogPath -PathType Leaf) {
        try {
            $log = Get-Content -Path $LogPath -Raw | ConvertFrom-Json
        } catch {
            Write-Warning "Erreur lors du chargement du journal existant: $($_.Exception.Message)"
            # Continuer avec un journal vide
        }
    }

    # Ajouter l'entree au journal
    if ($log -is [System.Array]) {
        $log = @($log) + @($RestoreInfo)
    } else {
        $log = @($RestoreInfo)
    }

    # Sauvegarder le journal
    try {
        $log | ConvertTo-Json -Depth 10 | Set-Content -Path $LogPath -Force
        return $true
    } catch {
        Write-Error "Erreur lors de la sauvegarde du journal: $($_.Exception.Message)"
        return $false
    }
}

# Fonction pour resoudre les conflits
function Resolve-RestoreConflict {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Skip", "Overwrite", "Rename", "Interactive")]
        [string]$ConflictResolution = "Interactive"
    )

    # Verifier si le fichier cible existe
    if (-not (Test-Path -Path $TargetPath -PathType Leaf)) {
        # Pas de conflit
        return $TargetPath
    }

    # Resolution interactive
    if ($ConflictResolution -eq "Interactive") {
        $sourceInfo = Get-Item -Path $SourcePath
        $targetInfo = Get-Item -Path $TargetPath

        Write-Host "Conflit detecte:" -ForegroundColor Yellow
        Write-Host "  Source: $SourcePath" -ForegroundColor Yellow
        Write-Host "    Taille: $($sourceInfo.Length) octets" -ForegroundColor Yellow
        Write-Host "    Date de modification: $($sourceInfo.LastWriteTime)" -ForegroundColor Yellow
        Write-Host "  Cible: $TargetPath" -ForegroundColor Yellow
        Write-Host "    Taille: $($targetInfo.Length) octets" -ForegroundColor Yellow
        Write-Host "    Date de modification: $($targetInfo.LastWriteTime)" -ForegroundColor Yellow

        $choices = @(
            [System.Management.Automation.Host.ChoiceDescription]::new("&Skip", "Ignorer ce fichier")
            [System.Management.Automation.Host.ChoiceDescription]::new("&Overwrite", "Ecraser le fichier existant")
            [System.Management.Automation.Host.ChoiceDescription]::new("&Rename", "Renommer le fichier")
            [System.Management.Automation.Host.ChoiceDescription]::new("&Cancel", "Annuler l'operation")
        )

        $decision = $Host.UI.PromptForChoice("Resolution de conflit", "Comment voulez-vous resoudre ce conflit?", $choices, 0)

        switch ($decision) {
            0 { $ConflictResolution = "Skip" }
            1 { $ConflictResolution = "Overwrite" }
            2 { $ConflictResolution = "Rename" }
            3 { return $null }
        }
    }

    # Appliquer la resolution
    switch ($ConflictResolution) {
        "Skip" {
            Write-Warning "Le fichier cible existe deja, il sera ignore: $TargetPath"
            return $null
        }
        "Overwrite" {
            Write-Warning "Le fichier cible existe deja, il sera ecrase: $TargetPath"
            return $TargetPath
        }
        "Rename" {
            $directory = [System.IO.Path]::GetDirectoryName($TargetPath)
            $fileName = [System.IO.Path]::GetFileNameWithoutExtension($TargetPath)
            $extension = [System.IO.Path]::GetExtension($TargetPath)
            $counter = 1

            do {
                $newFileName = "${fileName}_${counter}${extension}"
                $newPath = Join-Path -Path $directory -ChildPath $newFileName
                $counter++
            } while (Test-Path -Path $newPath -PathType Leaf)

            Write-Warning "Le fichier cible existe deja, il sera renomme en: $newPath"
            return $newPath
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Restore-ToAlternateLocation, ConvertTo-RestorePath, Set-RestorePermissions, Add-RestoreLog, Resolve-RestoreConflict
