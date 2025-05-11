# ValidationManager.ps1
# Module de validation de cohérence post-restauration
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$restorePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "RestoreManager.ps1"

if (Test-Path -Path $restorePath) {
    . $restorePath
} else {
    Write-Error "Le fichier RestoreManager.ps1 est introuvable."
    exit 1
}

# Fonction pour valider la cohérence d'un point de restauration après restauration
function Test-RestorePointCoherence {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$RestorePoint,

        [Parameter(Mandatory = $false)]
        [string]$RestorePath,

        [Parameter(Mandatory = $false)]
        [switch]$ShowDetails,

        [Parameter(Mandatory = $false)]
        [switch]$SkipContentValidation,

        [Parameter(Mandatory = $false)]
        [switch]$SkipDependencyValidation,

        [Parameter(Mandatory = $false)]
        [switch]$SkipIntegrityValidation
    )

    # Initialiser le résultat de validation
    $validationResult = [PSCustomObject]@{
        IsValid           = $true
        Errors            = @()
        Warnings          = @()
        Info              = @()
        ValidationTime    = [DateTime]::Now
        RestorePoint      = $RestorePoint
        RestorePath       = $RestorePath
        ValidationDetails = @{
            ContentValidation    = $null
            DependencyValidation = $null
            IntegrityValidation  = $null
        }
    }

    # Fonction pour ajouter une erreur
    function Add-ValidationError {
        param (
            [string]$Message,
            [string]$Category = "General",
            [string]$Code = "ERR001",
            [PSObject]$Data = $null
        )

        $validationResult.Errors += [PSCustomObject]@{
            Message   = $Message
            Category  = $Category
            Code      = $Code
            Timestamp = [DateTime]::Now
            Data      = $Data
        }

        $validationResult.IsValid = $false

        if ($ShowDetails) {
            Write-Host "ERREUR [$Category] $Code : $Message" -ForegroundColor Red
        }
    }

    # Fonction pour ajouter un avertissement
    function Add-ValidationWarning {
        param (
            [string]$Message,
            [string]$Category = "General",
            [string]$Code = "WARN001",
            [PSObject]$Data = $null
        )

        $validationResult.Warnings += [PSCustomObject]@{
            Message   = $Message
            Category  = $Category
            Code      = $Code
            Timestamp = [DateTime]::Now
            Data      = $Data
        }

        if ($ShowDetails) {
            Write-Host "AVERTISSEMENT [$Category] $Code : $Message" -ForegroundColor Yellow
        }
    }

    # Fonction pour ajouter une information
    function Add-ValidationInfo {
        param (
            [string]$Message,
            [string]$Category = "General",
            [PSObject]$Data = $null
        )

        $validationResult.Info += [PSCustomObject]@{
            Message   = $Message
            Category  = $Category
            Timestamp = [DateTime]::Now
            Data      = $Data
        }

        if ($ShowDetails) {
            Write-Host "INFO [$Category] : $Message" -ForegroundColor Gray
        }
    }

    # Vérifier si le point de restauration est valide
    if ($null -eq $RestorePoint) {
        Add-ValidationError -Message "Le point de restauration est null." -Category "Input" -Code "ERR001"
        return $validationResult
    }

    # Vérifier si le chemin de restauration est valide
    if ([string]::IsNullOrWhiteSpace($RestorePath)) {
        if ($RestorePoint.PSObject.Properties.Match("RestorePath").Count -and $null -ne $RestorePoint.RestorePath) {
            $RestorePath = $RestorePoint.RestorePath
        } else {
            Add-ValidationWarning -Message "Aucun chemin de restauration spécifié." -Category "Input" -Code "WARN001"
        }
    }

    # Valider le contenu restauré
    if (-not $SkipContentValidation) {
        $contentValidation = Test-RestoredContent -RestorePoint $RestorePoint -RestorePath $RestorePath -ShowDetails:$ShowDetails
        $validationResult.ValidationDetails.ContentValidation = $contentValidation

        if (-not $contentValidation.IsValid) {
            foreach ($error in $contentValidation.Errors) {
                Add-ValidationError -Message $error.Message -Category "Content" -Code $error.Code -Data $error.Data
            }
        }

        foreach ($warning in $contentValidation.Warnings) {
            Add-ValidationWarning -Message $warning.Message -Category "Content" -Code $warning.Code -Data $warning.Data
        }
    }

    # Valider les dépendances
    if (-not $SkipDependencyValidation) {
        $dependencyValidation = Test-RestoredDependencies -RestorePoint $RestorePoint -RestorePath $RestorePath -ShowDetails:$ShowDetails
        $validationResult.ValidationDetails.DependencyValidation = $dependencyValidation

        if (-not $dependencyValidation.IsValid) {
            foreach ($error in $dependencyValidation.Errors) {
                Add-ValidationError -Message $error.Message -Category "Dependency" -Code $error.Code -Data $error.Data
            }
        }

        foreach ($warning in $dependencyValidation.Warnings) {
            Add-ValidationWarning -Message $warning.Message -Category "Dependency" -Code $warning.Code -Data $warning.Data
        }
    }

    # Valider l'intégrité des données
    if (-not $SkipIntegrityValidation) {
        $integrityValidation = Test-RestoredIntegrity -RestorePoint $RestorePoint -RestorePath $RestorePath -ShowDetails:$ShowDetails
        $validationResult.ValidationDetails.IntegrityValidation = $integrityValidation

        if (-not $integrityValidation.IsValid) {
            foreach ($error in $integrityValidation.Errors) {
                Add-ValidationError -Message $error.Message -Category "Integrity" -Code $error.Code -Data $error.Data
            }
        }

        foreach ($warning in $integrityValidation.Warnings) {
            Add-ValidationWarning -Message $warning.Message -Category "Integrity" -Code $warning.Code -Data $warning.Data
        }
    }

    # Afficher le résultat final
    if ($ShowDetails) {
        if ($validationResult.IsValid) {
            Write-Host "Validation réussie : Le point de restauration est cohérent." -ForegroundColor Green
        } else {
            Write-Host "Validation échouée : Le point de restauration présente des incohérences." -ForegroundColor Red
            Write-Host "Nombre d'erreurs : $($validationResult.Errors.Count)" -ForegroundColor Red
            Write-Host "Nombre d'avertissements : $($validationResult.Warnings.Count)" -ForegroundColor Yellow
        }
    }

    return $validationResult
}

# Fonction pour valider le contenu restauré
function Test-RestoredContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$RestorePoint,

        [Parameter(Mandatory = $false)]
        [string]$RestorePath,

        [Parameter(Mandatory = $false)]
        [switch]$ShowDetails
    )

    # Initialiser le résultat de validation
    $validationResult = [PSCustomObject]@{
        IsValid        = $true
        Errors         = @()
        Warnings       = @()
        Info           = @()
        ValidationTime = [DateTime]::Now
        RestorePoint   = $RestorePoint
        RestorePath    = $RestorePath
        Details        = @{
            FilesChecked    = 0
            FilesValid      = 0
            FilesInvalid    = 0
            TotalSize       = 0
            MissingFiles    = @()
            ModifiedFiles   = @()
            UnexpectedFiles = @()
        }
    }

    # Fonction pour ajouter une erreur
    function Add-ValidationError {
        param (
            [string]$Message,
            [string]$Code = "CONT001",
            [PSObject]$Data = $null
        )

        $validationResult.Errors += [PSCustomObject]@{
            Message   = $Message
            Category  = "Content"
            Code      = $Code
            Timestamp = [DateTime]::Now
            Data      = $Data
        }

        $validationResult.IsValid = $false

        if ($ShowDetails) {
            Write-Host "ERREUR [Content] $Code : $Message" -ForegroundColor Red
        }
    }

    # Fonction pour ajouter un avertissement
    function Add-ValidationWarning {
        param (
            [string]$Message,
            [string]$Code = "CONT001",
            [PSObject]$Data = $null
        )

        $validationResult.Warnings += [PSCustomObject]@{
            Message   = $Message
            Category  = "Content"
            Code      = $Code
            Timestamp = [DateTime]::Now
            Data      = $Data
        }

        if ($ShowDetails) {
            Write-Host "AVERTISSEMENT [Content] $Code : $Message" -ForegroundColor Yellow
        }
    }

    # Vérifier si le point de restauration contient des informations sur les fichiers
    if (-not ($RestorePoint.PSObject.Properties.Match("Files").Count -and $null -ne $RestorePoint.Files)) {
        Add-ValidationWarning -Message "Le point de restauration ne contient pas d'informations sur les fichiers." -Code "CONT001"
        return $validationResult
    }

    # Vérifier si le chemin de restauration est valide
    if ([string]::IsNullOrWhiteSpace($RestorePath)) {
        Add-ValidationWarning -Message "Aucun chemin de restauration spécifié pour la validation du contenu." -Code "CONT002"
        return $validationResult
    }

    # Vérifier si le chemin de restauration existe
    if (-not (Test-Path -Path $RestorePath -PathType Container)) {
        Add-ValidationError -Message "Le chemin de restauration n'existe pas : $RestorePath" -Code "CONT003"
        return $validationResult
    }

    # Récupérer la liste des fichiers attendus
    $expectedFiles = $RestorePoint.Files

    # Récupérer la liste des fichiers actuels
    $currentFiles = Get-ChildItem -Path $RestorePath -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($RestorePath.Length).TrimStart('\', '/')

        [PSCustomObject]@{
            Path          = $relativePath
            FullPath      = $_.FullName
            Size          = $_.Length
            LastWriteTime = $_.LastWriteTime
            Checksum      = $null # Sera calculé si nécessaire
        }
    }

    # Vérifier les fichiers manquants
    foreach ($expectedFile in $expectedFiles) {
        $validationResult.Details.FilesChecked++

        $filePath = if ($expectedFile.PSObject.Properties.Match("Path").Count) { $expectedFile.Path } else { $expectedFile.ToString() }
        $fullPath = Join-Path -Path $RestorePath -ChildPath $filePath

        if (-not (Test-Path -Path $fullPath -PathType Leaf)) {
            $validationResult.Details.FilesInvalid++
            $validationResult.Details.MissingFiles += $filePath

            Add-ValidationError -Message "Fichier manquant : $filePath" -Code "CONT004" -Data @{
                Path     = $filePath
                Expected = $expectedFile
            }
        } else {
            $validationResult.Details.FilesValid++
            $validationResult.Details.TotalSize += (Get-Item -Path $fullPath).Length

            # Vérifier le checksum si disponible
            if ($expectedFile.PSObject.Properties.Match("Checksum").Count -and $null -ne $expectedFile.Checksum) {
                $currentFile = $currentFiles | Where-Object { $_.Path -eq $filePath } | Select-Object -First 1

                if ($null -ne $currentFile) {
                    # Calculer le checksum du fichier actuel
                    $currentChecksum = Get-FileHash -Path $fullPath -Algorithm SHA256 | Select-Object -ExpandProperty Hash
                    $currentFile.Checksum = $currentChecksum

                    if ($currentChecksum -ne $expectedFile.Checksum) {
                        $validationResult.Details.FilesInvalid++
                        $validationResult.Details.FilesValid--
                        $validationResult.Details.ModifiedFiles += $filePath

                        Add-ValidationError -Message "Fichier modifié : $filePath" -Code "CONT005" -Data @{
                            Path     = $filePath
                            Expected = $expectedFile
                            Current  = $currentFile
                        }
                    }
                }
            }
        }
    }

    # Vérifier les fichiers inattendus
    foreach ($currentFile in $currentFiles) {
        $expectedFile = $expectedFiles | Where-Object {
            $_.PSObject.Properties.Match("Path").Count -and $_.Path -eq $currentFile.Path
        } | Select-Object -First 1

        if ($null -eq $expectedFile) {
            $validationResult.Details.UnexpectedFiles += $currentFile.Path

            Add-ValidationWarning -Message "Fichier inattendu : $($currentFile.Path)" -Code "CONT006" -Data @{
                Path    = $currentFile.Path
                Current = $currentFile
            }
        }
    }

    # Afficher le résultat final
    if ($ShowDetails) {
        Write-Host "Validation du contenu terminée." -ForegroundColor Cyan
        Write-Host "  Fichiers vérifiés : $($validationResult.Details.FilesChecked)" -ForegroundColor White
        Write-Host "  Fichiers valides : $($validationResult.Details.FilesValid)" -ForegroundColor Green
        Write-Host "  Fichiers invalides : $($validationResult.Details.FilesInvalid)" -ForegroundColor Red
        Write-Host "  Fichiers manquants : $($validationResult.Details.MissingFiles.Count)" -ForegroundColor Yellow
        Write-Host "  Fichiers modifiés : $($validationResult.Details.ModifiedFiles.Count)" -ForegroundColor Yellow
        Write-Host "  Fichiers inattendus : $($validationResult.Details.UnexpectedFiles.Count)" -ForegroundColor Yellow
    }

    return $validationResult
}

# Fonction pour valider les dépendances restaurées
function Test-RestoredDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$RestorePoint,

        [Parameter(Mandatory = $false)]
        [string]$RestorePath,

        [Parameter(Mandatory = $false)]
        [switch]$ShowDetails
    )

    # Initialiser le résultat de validation
    $validationResult = [PSCustomObject]@{
        IsValid        = $true
        Errors         = @()
        Warnings       = @()
        Info           = @()
        ValidationTime = [DateTime]::Now
        RestorePoint   = $RestorePoint
        RestorePath    = $RestorePath
        Details        = @{
            DependenciesChecked  = 0
            DependenciesValid    = 0
            DependenciesInvalid  = 0
            MissingDependencies  = @()
            CircularDependencies = @()
            WeakDependencies     = @()
        }
    }

    # Fonction pour ajouter une erreur
    function Add-ValidationError {
        param (
            [string]$Message,
            [string]$Code = "DEP001",
            [PSObject]$Data = $null
        )

        $validationResult.Errors += [PSCustomObject]@{
            Message   = $Message
            Category  = "Dependency"
            Code      = $Code
            Timestamp = [DateTime]::Now
            Data      = $Data
        }

        $validationResult.IsValid = $false

        if ($ShowDetails) {
            Write-Host "ERREUR [Dependency] $Code : $Message" -ForegroundColor Red
        }
    }

    # Fonction pour ajouter un avertissement
    function Add-ValidationWarning {
        param (
            [string]$Message,
            [string]$Code = "DEP001",
            [PSObject]$Data = $null
        )

        $validationResult.Warnings += [PSCustomObject]@{
            Message   = $Message
            Category  = "Dependency"
            Code      = $Code
            Timestamp = [DateTime]::Now
            Data      = $Data
        }

        if ($ShowDetails) {
            Write-Host "AVERTISSEMENT [Dependency] $Code : $Message" -ForegroundColor Yellow
        }
    }

    # Vérifier si le point de restauration contient des informations sur les dépendances
    if (-not ($RestorePoint.PSObject.Properties.Match("Dependencies").Count -and $null -ne $RestorePoint.Dependencies)) {
        Add-ValidationWarning -Message "Le point de restauration ne contient pas d'informations sur les dépendances." -Code "DEP001"
        return $validationResult
    }

    # Récupérer les dépendances
    $dependencies = $RestorePoint.Dependencies

    # Récupérer tous les points de restauration disponibles
    $allPoints = Get-RestorePoints

    # Vérifier chaque dépendance
    foreach ($dependency in $dependencies) {
        $validationResult.Details.DependenciesChecked++

        $dependencyId = if ($dependency.PSObject.Properties.Match("Id").Count) {
            $dependency.Id
        } elseif ($dependency.PSObject.Properties.Match("TargetId").Count) {
            $dependency.TargetId
        } else {
            $dependency.ToString()
        }

        # Vérifier si la dépendance existe
        $dependencyPoint = $allPoints | Where-Object { $_.Id -eq $dependencyId } | Select-Object -First 1

        if ($null -eq $dependencyPoint) {
            $validationResult.Details.DependenciesInvalid++
            $validationResult.Details.MissingDependencies += $dependencyId

            Add-ValidationError -Message "Dépendance manquante : $dependencyId" -Code "DEP002" -Data @{
                Id         = $dependencyId
                Dependency = $dependency
            }
        } else {
            $validationResult.Details.DependenciesValid++

            # Vérifier la force de la dépendance
            if ($dependency.PSObject.Properties.Match("Strength").Count -and $dependency.Strength -lt 0.5) {
                $validationResult.Details.WeakDependencies += $dependencyId

                Add-ValidationWarning -Message "Dépendance faible : $dependencyId (Force: $([Math]::Round($dependency.Strength * 100))%)" -Code "DEP003" -Data @{
                    Id         = $dependencyId
                    Dependency = $dependency
                    Strength   = $dependency.Strength
                }
            }

            # Vérifier les dépendances circulaires
            if ($dependencyPoint.PSObject.Properties.Match("Dependencies").Count -and $null -ne $dependencyPoint.Dependencies) {
                $circularCheck = $dependencyPoint.Dependencies | Where-Object {
                    $depId = if ($_.PSObject.Properties.Match("Id").Count) {
                        $_.Id
                    } elseif ($_.PSObject.Properties.Match("TargetId").Count) {
                        $_.TargetId
                    } else {
                        $_.ToString()
                    }

                    $depId -eq $RestorePoint.Id
                }

                if ($null -ne $circularCheck) {
                    $validationResult.Details.CircularDependencies += $dependencyId

                    Add-ValidationWarning -Message "Dépendance circulaire détectée entre $($RestorePoint.Id) et $dependencyId" -Code "DEP004" -Data @{
                        SourceId   = $RestorePoint.Id
                        TargetId   = $dependencyId
                        Dependency = $dependency
                    }
                }
            }
        }
    }

    # Afficher le résultat final
    if ($ShowDetails) {
        Write-Host "Validation des dépendances terminée." -ForegroundColor Cyan
        Write-Host "  Dépendances vérifiées : $($validationResult.Details.DependenciesChecked)" -ForegroundColor White
        Write-Host "  Dépendances valides : $($validationResult.Details.DependenciesValid)" -ForegroundColor Green
        Write-Host "  Dépendances invalides : $($validationResult.Details.DependenciesInvalid)" -ForegroundColor Red
        Write-Host "  Dépendances manquantes : $($validationResult.Details.MissingDependencies.Count)" -ForegroundColor Yellow
        Write-Host "  Dépendances circulaires : $($validationResult.Details.CircularDependencies.Count)" -ForegroundColor Yellow
        Write-Host "  Dépendances faibles : $($validationResult.Details.WeakDependencies.Count)" -ForegroundColor Yellow
    }

    return $validationResult
}

# Fonction pour valider l'intégrité des données restaurées
function Test-RestoredIntegrity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$RestorePoint,

        [Parameter(Mandatory = $false)]
        [string]$RestorePath,

        [Parameter(Mandatory = $false)]
        [switch]$ShowDetails
    )

    # Initialiser le résultat de validation
    $validationResult = [PSCustomObject]@{
        IsValid        = $true
        Errors         = @()
        Warnings       = @()
        Info           = @()
        ValidationTime = [DateTime]::Now
        RestorePoint   = $RestorePoint
        RestorePath    = $RestorePath
        Details        = @{
            ChecksPerformed  = 0
            ChecksPassed     = 0
            ChecksFailed     = 0
            IntegrityIssues  = @()
            VersionIssues    = @()
            StructuralIssues = @()
        }
    }

    # Fonction pour ajouter une erreur
    function Add-ValidationError {
        param (
            [string]$Message,
            [string]$Code = "INT001",
            [PSObject]$Data = $null
        )

        $validationResult.Errors += [PSCustomObject]@{
            Message   = $Message
            Category  = "Integrity"
            Code      = $Code
            Timestamp = [DateTime]::Now
            Data      = $Data
        }

        $validationResult.IsValid = $false

        if ($ShowDetails) {
            Write-Host "ERREUR [Integrity] $Code : $Message" -ForegroundColor Red
        }
    }

    # Fonction pour ajouter un avertissement
    function Add-ValidationWarning {
        param (
            [string]$Message,
            [string]$Code = "INT001",
            [PSObject]$Data = $null
        )

        $validationResult.Warnings += [PSCustomObject]@{
            Message   = $Message
            Category  = "Integrity"
            Code      = $Code
            Timestamp = [DateTime]::Now
            Data      = $Data
        }

        if ($ShowDetails) {
            Write-Host "AVERTISSEMENT [Integrity] $Code : $Message" -ForegroundColor Yellow
        }
    }

    # Vérifier si le chemin de restauration est valide
    if ([string]::IsNullOrWhiteSpace($RestorePath)) {
        Add-ValidationWarning -Message "Aucun chemin de restauration spécifié pour la validation d'intégrité." -Code "INT001"
        return $validationResult
    }

    # Vérifier si le chemin de restauration existe
    if (-not (Test-Path -Path $RestorePath -PathType Container)) {
        Add-ValidationError -Message "Le chemin de restauration n'existe pas : $RestorePath" -Code "INT002"
        return $validationResult
    }

    # Vérifier l'intégrité structurelle
    $validationResult.Details.ChecksPerformed++

    if ($RestorePoint.PSObject.Properties.Match("Structure").Count -and $null -ne $RestorePoint.Structure) {
        $structure = $RestorePoint.Structure

        # Vérifier la structure des répertoires
        if ($structure.PSObject.Properties.Match("Directories").Count -and $null -ne $structure.Directories) {
            foreach ($directory in $structure.Directories) {
                $dirPath = if ($directory.PSObject.Properties.Match("Path").Count) {
                    $directory.Path
                } else {
                    $directory.ToString()
                }

                $fullPath = Join-Path -Path $RestorePath -ChildPath $dirPath

                if (-not (Test-Path -Path $fullPath -PathType Container)) {
                    $validationResult.Details.ChecksFailed++
                    $validationResult.Details.StructuralIssues += $dirPath

                    Add-ValidationError -Message "Répertoire manquant dans la structure : $dirPath" -Code "INT003" -Data @{
                        Path     = $dirPath
                        Expected = $directory
                    }
                }
            }
        }

        $validationResult.Details.ChecksPassed++
    }

    # Vérifier la version des fichiers
    $validationResult.Details.ChecksPerformed++

    if ($RestorePoint.PSObject.Properties.Match("Version").Count -and $null -ne $RestorePoint.Version) {
        # Version du point de restauration disponible

        # Vérifier les fichiers de version
        if ($RestorePoint.PSObject.Properties.Match("Files").Count -and $null -ne $RestorePoint.Files) {
            foreach ($file in $RestorePoint.Files) {
                if ($file.PSObject.Properties.Match("Version").Count -and $null -ne $file.Version) {
                    $filePath = if ($file.PSObject.Properties.Match("Path").Count) {
                        $file.Path
                    } else {
                        $file.ToString()
                    }

                    $fullPath = Join-Path -Path $RestorePath -ChildPath $filePath

                    if (Test-Path -Path $fullPath -PathType Leaf) {
                        # Vérifier la version du fichier (si possible)
                        if (Test-Path -Path $fullPath -PathType Leaf) {
                            try {
                                $fileVersion = (Get-Item -Path $fullPath).VersionInfo.FileVersion

                                if ($null -ne $fileVersion -and $fileVersion -ne $file.Version) {
                                    $validationResult.Details.VersionIssues += $filePath

                                    Add-ValidationWarning -Message "Version de fichier différente : $filePath (Attendu: $($file.Version), Actuel: $fileVersion)" -Code "INT004" -Data @{
                                        Path            = $filePath
                                        ExpectedVersion = $file.Version
                                        ActualVersion   = $fileVersion
                                    }
                                }
                            } catch {
                                # Ignorer les erreurs de récupération de version
                            }
                        }
                    }
                }
            }
        }

        $validationResult.Details.ChecksPassed++
    }

    # Vérifier l'intégrité des données
    $validationResult.Details.ChecksPerformed++

    if ($RestorePoint.PSObject.Properties.Match("Checksums").Count -and $null -ne $RestorePoint.Checksums) {
        $checksums = $RestorePoint.Checksums

        foreach ($checksum in $checksums) {
            $filePath = if ($checksum.PSObject.Properties.Match("Path").Count) {
                $checksum.Path
            } else {
                $checksum.Key
            }

            $expectedChecksum = if ($checksum.PSObject.Properties.Match("Checksum").Count) {
                $checksum.Checksum
            } else {
                $checksum.Value
            }

            $fullPath = Join-Path -Path $RestorePath -ChildPath $filePath

            if (Test-Path -Path $fullPath -PathType Leaf) {
                $actualChecksum = Get-FileHash -Path $fullPath -Algorithm SHA256 | Select-Object -ExpandProperty Hash

                if ($actualChecksum -ne $expectedChecksum) {
                    $validationResult.Details.ChecksFailed++
                    $validationResult.Details.IntegrityIssues += $filePath

                    Add-ValidationError -Message "Intégrité du fichier compromise : $filePath" -Code "INT005" -Data @{
                        Path             = $filePath
                        ExpectedChecksum = $expectedChecksum
                        ActualChecksum   = $actualChecksum
                    }
                }
            }
        }

        $validationResult.Details.ChecksPassed++
    }

    # Afficher le résultat final
    if ($ShowDetails) {
        Write-Host "Validation de l'intégrité terminée." -ForegroundColor Cyan
        Write-Host "  Vérifications effectuées : $($validationResult.Details.ChecksPerformed)" -ForegroundColor White
        Write-Host "  Vérifications réussies : $($validationResult.Details.ChecksPassed)" -ForegroundColor Green
        Write-Host "  Vérifications échouées : $($validationResult.Details.ChecksFailed)" -ForegroundColor Red
        Write-Host "  Problèmes d'intégrité : $($validationResult.Details.IntegrityIssues.Count)" -ForegroundColor Yellow
        Write-Host "  Problèmes de version : $($validationResult.Details.VersionIssues.Count)" -ForegroundColor Yellow
        Write-Host "  Problèmes structurels : $($validationResult.Details.StructuralIssues.Count)" -ForegroundColor Yellow
    }

    return $validationResult
}

# Exporter les fonctions
Export-ModuleMember -Function Test-RestorePointCoherence, Test-RestoredContent, Test-RestoredDependencies, Test-RestoredIntegrity
