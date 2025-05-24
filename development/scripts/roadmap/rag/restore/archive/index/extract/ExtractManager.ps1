# ExtractManager.ps1
# Module d'extraction selective des archives
# Version: 1.0
# Date: 2025-05-15

# Importer le module de resolution des chemins d'archives
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$pathResolverPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "path\PathResolver.ps1"

if (Test-Path -Path $pathResolverPath) {
    . $pathResolverPath
} else {
    Write-Error "Le fichier PathResolver.ps1 est introuvable."
    exit 1
}

# Fonction pour extraire un element d'archive
function Export-ArchiveItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [string]$Id,
        
        [Parameter(Mandatory = $true, ParameterSetName = "ByPath")]
        [string]$ArchivePath,
        
        [Parameter(Mandatory = $true)]
        [string]$IndexPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "$env:TEMP\ExtractedArchives",
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateOutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Overwrite,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreserveStructure
    )
    
    # Verifier si le fichier d'index existe
    if (-not (Test-Path -Path $IndexPath -PathType Leaf)) {
        Write-Error "Le fichier d'index n'existe pas: $IndexPath"
        return $null
    }
    
    # Charger le fichier d'index
    try {
        $index = Get-Content -Path $IndexPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Error "Erreur lors du chargement du fichier d'index: $($_.Exception.Message)"
        return $null
    }
    
    # Verifier si l'index a des archives
    if (-not $index.PSObject.Properties.Match("Archives").Count -or $index.Archives.Count -eq 0) {
        Write-Error "L'index ne contient pas d'archives."
        return $null
    }
    
    # Trouver l'archive a extraire
    $archive = $null
    
    if ($PSCmdlet.ParameterSetName -eq "ById") {
        $archive = $index.Archives | Where-Object { $_.Id -eq $Id } | Select-Object -First 1
        
        if ($null -eq $archive) {
            Write-Error "Aucune archive trouvee avec l'ID: $Id"
            return $null
        }
    }
    else {
        $archive = $index.Archives | Where-Object { $_.ArchivePath -eq $ArchivePath } | Select-Object -First 1
        
        if ($null -eq $archive) {
            Write-Error "Aucune archive trouvee avec le chemin: $ArchivePath"
            return $null
        }
    }
    
    # Verifier si l'archive a un chemin
    if (-not $archive.PSObject.Properties.Match("ArchivePath").Count -or [string]::IsNullOrWhiteSpace($archive.ArchivePath)) {
        Write-Error "L'archive n'a pas de chemin specifie."
        return $null
    }
    
    # Resoudre le chemin de l'archive
    $resolvedArchivePath = Resolve-ArchivePath -Path $archive.ArchivePath -IndexPath $IndexPath -ValidateExists -PathType "File"
    
    if ($null -eq $resolvedArchivePath) {
        Write-Error "Impossible de resoudre le chemin de l'archive: $($archive.ArchivePath)"
        return $null
    }
    
    # Creer le repertoire de sortie si necessaire
    if (-not (Test-Path -Path $OutputPath -PathType Container)) {
        if ($CreateOutputPath) {
            try {
                New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
            }
            catch {
                Write-Error "Erreur lors de la creation du repertoire de sortie: $($_.Exception.Message)"
                return $null
            }
        }
        else {
            Write-Error "Le repertoire de sortie n'existe pas: $OutputPath"
            return $null
        }
    }
    
    # Determiner le chemin de sortie
    $outputFilePath = $null
    
    if ($PreserveStructure) {
        # Utiliser la structure de repertoires de l'archive
        $relativePath = Convert-ArchivePath -Path $resolvedArchivePath.ResolvedPath -ConversionType "ToRelative" -IndexPath $IndexPath
        $outputFilePath = Join-Path -Path $OutputPath -ChildPath $relativePath
        
        # Creer le repertoire parent si necessaire
        $parentDirectory = [System.IO.Path]::GetDirectoryName($outputFilePath)
        if (-not (Test-Path -Path $parentDirectory -PathType Container)) {
            try {
                New-Item -Path $parentDirectory -ItemType Directory -Force | Out-Null
            }
            catch {
                Write-Error "Erreur lors de la creation du repertoire parent: $($_.Exception.Message)"
                return $null
            }
        }
    }
    else {
        # Utiliser uniquement le nom du fichier
        $fileName = [System.IO.Path]::GetFileName($resolvedArchivePath.ResolvedPath)
        $outputFilePath = Join-Path -Path $OutputPath -ChildPath $fileName
    }
    
    # Verifier si le fichier de sortie existe deja
    if (Test-Path -Path $outputFilePath -PathType Leaf) {
        if ($Overwrite) {
            try {
                Remove-Item -Path $outputFilePath -Force
            }
            catch {
                Write-Error "Erreur lors de la suppression du fichier existant: $($_.Exception.Message)"
                return $null
            }
        }
        else {
            Write-Error "Le fichier de sortie existe deja: $outputFilePath"
            return $null
        }
    }
    
    # Copier le fichier
    try {
        Copy-Item -Path $resolvedArchivePath.ResolvedPath -Destination $outputFilePath -Force
    }
    catch {
        Write-Error "Erreur lors de la copie du fichier: $($_.Exception.Message)"
        return $null
    }
    
    # Creer un objet avec les informations sur l'extraction
    $result = [PSCustomObject]@{
        Archive = $archive
        SourcePath = $resolvedArchivePath.ResolvedPath
        OutputPath = $outputFilePath
        ExtractionTime = [DateTime]::Now.ToString("o")
        Success = $true
    }
    
    return $result
}

# Fonction pour valider une extraction avant restauration
function Test-RestoreValidity {
    [CmdletBinding()]
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
        [switch]$CheckIntegrity,
        
        [Parameter(Mandatory = $false)]
        [switch]$CheckPermissions
    )
    
    # Extraire l'element d'archive (sans le copier reellement)
    $extractParams = @{
        IndexPath = $IndexPath
    }
    
    if ($PSCmdlet.ParameterSetName -eq "ById") {
        $extractParams.Id = $Id
    }
    else {
        $extractParams.ArchivePath = $ArchivePath
    }
    
    # Trouver l'archive a extraire
    try {
        $index = Get-Content -Path $IndexPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Error "Erreur lors du chargement du fichier d'index: $($_.Exception.Message)"
        return $null
    }
    
    # Verifier si l'index a des archives
    if (-not $index.PSObject.Properties.Match("Archives").Count -or $index.Archives.Count -eq 0) {
        Write-Error "L'index ne contient pas d'archives."
        return $null
    }
    
    # Trouver l'archive a extraire
    $archive = $null
    
    if ($PSCmdlet.ParameterSetName -eq "ById") {
        $archive = $index.Archives | Where-Object { $_.Id -eq $Id } | Select-Object -First 1
        
        if ($null -eq $archive) {
            Write-Error "Aucune archive trouvee avec l'ID: $Id"
            return $null
        }
    }
    else {
        $archive = $index.Archives | Where-Object { $_.ArchivePath -eq $ArchivePath } | Select-Object -First 1
        
        if ($null -eq $archive) {
            Write-Error "Aucune archive trouvee avec le chemin: $ArchivePath"
            return $null
        }
    }
    
    # Verifier si l'archive a un chemin
    if (-not $archive.PSObject.Properties.Match("ArchivePath").Count -or [string]::IsNullOrWhiteSpace($archive.ArchivePath)) {
        Write-Error "L'archive n'a pas de chemin specifie."
        return $null
    }
    
    # Resoudre le chemin de l'archive
    $resolvedArchivePath = Resolve-ArchivePath -Path $archive.ArchivePath -IndexPath $IndexPath -ValidateExists -PathType "File"
    
    if ($null -eq $resolvedArchivePath) {
        Write-Error "Impossible de resoudre le chemin de l'archive: $($archive.ArchivePath)"
        return $null
    }
    
    # Verifier l'integrite de l'archive
    if ($CheckIntegrity) {
        try {
            # Verifier si le fichier peut etre ouvert en lecture
            $fileStream = [System.IO.File]::OpenRead($resolvedArchivePath.ResolvedPath)
            $fileStream.Close()
            $fileStream.Dispose()
            
            # Verifier la taille du fichier
            $fileInfo = Get-Item -Path $resolvedArchivePath.ResolvedPath
            if ($fileInfo.Length -eq 0) {
                Write-Warning "Le fichier d'archive est vide: $($resolvedArchivePath.ResolvedPath)"
            }
        }
        catch {
            Write-Error "Erreur lors de la verification de l'integrite de l'archive: $($_.Exception.Message)"
            return $null
        }
    }
    
    # Resoudre le chemin cible
    $resolvedTargetPath = Resolve-ArchivePath -Path $TargetPath -CreateIfNotExists:$false
    
    if ($null -eq $resolvedTargetPath) {
        Write-Error "Impossible de resoudre le chemin cible: $TargetPath"
        return $null
    }
    
    # Verifier si le chemin cible existe
    $targetExists = $resolvedTargetPath.Exists
    
    # Verifier les permissions sur le chemin cible
    if ($CheckPermissions) {
        if ($targetExists) {
            try {
                $acl = Get-Acl -Path $resolvedTargetPath.ResolvedPath
                $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                
                # Verifier si l'utilisateur a les permissions d'ecriture
                $hasWritePermission = $false
                foreach ($accessRule in $acl.Access) {
                    if ($accessRule.IdentityReference.Value -eq $currentUser -or $accessRule.IdentityReference.Value -eq "Everyone" -or $accessRule.IdentityReference.Value -eq "BUILTIN\Users") {
                        if ($accessRule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Write) {
                            $hasWritePermission = $true
                            break
                        }
                    }
                }
                
                if (-not $hasWritePermission) {
                    Write-Error "L'utilisateur n'a pas les permissions d'ecriture sur: $($resolvedTargetPath.ResolvedPath)"
                    return $null
                }
            }
            catch {
                Write-Error "Erreur lors de la verification des permissions: $($_.Exception.Message)"
                return $null
            }
        }
        else {
            # Verifier les permissions sur le repertoire parent
            $parentDirectory = [System.IO.Path]::GetDirectoryName($resolvedTargetPath.ResolvedPath)
            if (Test-Path -Path $parentDirectory -PathType Container) {
                try {
                    $acl = Get-Acl -Path $parentDirectory
                    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                    
                    # Verifier si l'utilisateur a les permissions d'ecriture
                    $hasWritePermission = $false
                    foreach ($accessRule in $acl.Access) {
                        if ($accessRule.IdentityReference.Value -eq $currentUser -or $accessRule.IdentityReference.Value -eq "Everyone" -or $accessRule.IdentityReference.Value -eq "BUILTIN\Users") {
                            if ($accessRule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Write) {
                                $hasWritePermission = $true
                                break
                            }
                        }
                    }
                    
                    if (-not $hasWritePermission) {
                        Write-Error "L'utilisateur n'a pas les permissions d'ecriture sur le repertoire parent: $parentDirectory"
                        return $null
                    }
                }
                catch {
                    Write-Error "Erreur lors de la verification des permissions sur le repertoire parent: $($_.Exception.Message)"
                    return $null
                }
            }
            else {
                Write-Error "Le repertoire parent n'existe pas: $parentDirectory"
                return $null
            }
        }
    }
    
    # Determiner le chemin final en fonction de la resolution des conflits
    $finalPath = $resolvedTargetPath.ResolvedPath
    
    if ($targetExists) {
        switch ($ConflictResolution) {
            "Skip" {
                Write-Warning "Le fichier cible existe deja, il sera ignore: $finalPath"
                $finalPath = $null
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
                Write-Warning "Le fichier cible existe deja, il sera ecrase: $finalPath"
            }
        }
    }
    
    # Creer un objet avec les informations sur la validation
    $result = [PSCustomObject]@{
        Archive = $archive
        SourcePath = $resolvedArchivePath.ResolvedPath
        TargetPath = $resolvedTargetPath.ResolvedPath
        FinalPath = $finalPath
        TargetExists = $targetExists
        ConflictResolution = $ConflictResolution
        IsValid = $null -ne $finalPath
        ValidationTime = [DateTime]::Now.ToString("o")
    }
    
    return $result
}

# Exporter les fonctions
Export-ModuleMember -function Export-ArchiveItem, Test-RestoreValidity

