#Requires -Version 5.1
<#
.SYNOPSIS
    Module unifiÃ© pour le traitement sÃ©curisÃ© et performant de fichiers.
.DESCRIPTION
    Ce module combine les fonctionnalitÃ©s des modules UnifiedSegmenter, FileProcessingFacade,
    ParallelProcessing et FileSecurityUtils pour fournir une solution complÃ¨te de traitement de fichiers.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-06-06
#>

# Importer les modules requis
$moduleRoot = $PSScriptRoot
$unifiedSegmenterPath = Join-Path -Path $moduleRoot -ChildPath "UnifiedSegmenter.ps1"
$facadePath = Join-Path -Path $moduleRoot -ChildPath "FileProcessingFacade.ps1"
$parallelProcessingPath = Join-Path -Path $moduleRoot -ChildPath "ParallelProcessing.ps1"
$securityUtilsPath = Join-Path -Path $moduleRoot -ChildPath "FileSecurityUtils.ps1"
$cacheManagerPath = Join-Path -Path $moduleRoot -ChildPath "CacheManager.ps1"
$encryptionUtilsPath = Join-Path -Path $moduleRoot -ChildPath "EncryptionUtils.ps1"

# VÃ©rifier que tous les modules requis sont disponibles
$requiredModules = @($unifiedSegmenterPath, $facadePath, $parallelProcessingPath, $securityUtilsPath)
foreach ($module in $requiredModules) {
    if (-not (Test-Path -Path $module)) {
        throw "Le module requis n'est pas disponible : $module"
    }
}

# VÃ©rifier que les modules optionnels sont disponibles
$optionalModules = @{
    "CacheManager"    = $cacheManagerPath
    "EncryptionUtils" = $encryptionUtilsPath
}

$availableOptionalModules = @{}
foreach ($moduleName in $optionalModules.Keys) {
    $modulePath = $optionalModules[$moduleName]
    if (Test-Path -Path $modulePath) {
        $availableOptionalModules[$moduleName] = $modulePath
        Write-Verbose "Module optionnel disponible : $moduleName"
    } else {
        Write-Verbose "Module optionnel non disponible : $moduleName"
    }
}

# Importer les modules requis
Write-Verbose "Importation du module UnifiedSegmenter..."
. $unifiedSegmenterPath

Write-Verbose "Importation du module FileProcessingFacade..."
. $facadePath

Write-Verbose "Importation du module ParallelProcessing..."
. $parallelProcessingPath

Write-Verbose "Importation du module FileSecurityUtils..."
. $securityUtilsPath

# Vérifier que les fonctions requises sont disponibles
if (-not (Get-Command -Name "Initialize-FileProcessingFacade" -ErrorAction SilentlyContinue)) {
    Write-Error "La fonction Initialize-FileProcessingFacade n'est pas disponible après l'importation du module."
    throw "Erreur d'importation des modules requis."
}

# Importer les modules optionnels
foreach ($moduleName in $availableOptionalModules.Keys) {
    $modulePath = $availableOptionalModules[$moduleName]
    Write-Verbose "Importation du module optionnel : $moduleName"
    . $modulePath
}

# Initialiser les modules
$script:IsInitialized = $false

# Fonction pour initialiser le module unifiÃ©
function Initialize-UnifiedFileProcessor {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$EnableCache,

        [Parameter(Mandatory = $false)]
        [int]$CacheMaxItems = 1000,

        [Parameter(Mandatory = $false)]
        [int]$CacheTTL = 3600,

        [Parameter(Mandatory = $false)]
        [ValidateSet("LRU", "LFU", "FIFO")]
        [string]$CacheEvictionPolicy = "LRU"
    )

    if ($script:IsInitialized -and -not $Force) {
        Write-Verbose "Le module UnifiedFileProcessor est dÃ©jÃ  initialisÃ©."
        return $true
    }

    try {
        # Initialiser le segmenteur unifiÃ©
        $segmenterResult = Initialize-UnifiedSegmenter
        if (-not $segmenterResult) {
            Write-Error "Ã‰chec de l'initialisation du segmenteur unifiÃ©."
            return $false
        }

        # Initialiser la faÃ§ade de traitement de fichiers
        $facadeResult = Initialize-FileProcessingFacade
        if (-not $facadeResult) {
            Write-Error "Ã‰chec de l'initialisation de la faÃ§ade de traitement de fichiers."
            return $false
        }

        # Initialiser le gestionnaire de cache si disponible
        if ($availableOptionalModules.ContainsKey("CacheManager") -and $EnableCache) {
            Write-Verbose "Initialisation du gestionnaire de cache..."
            $cacheResult = Initialize-CacheManager -Enabled $true -MaxItems $CacheMaxItems -DefaultTTL $CacheTTL -EvictionPolicy $CacheEvictionPolicy
            if (-not $cacheResult) {
                Write-Warning "Ã‰chec de l'initialisation du gestionnaire de cache. Le cache sera dÃ©sactivÃ©."
            }
        }

        $script:IsInitialized = $true
        Write-Verbose "Module UnifiedFileProcessor initialisÃ© avec succÃ¨s."
        return $true
    } catch {
        Write-Error "Erreur lors de l'initialisation du module UnifiedFileProcessor : $_"
        return $false
    }
}

# Fonction pour traiter un fichier de maniÃ¨re sÃ©curisÃ©e
function Invoke-SecureFileProcessing {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$InputFormat = "AUTO",

        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$OutputFormat,

        [Parameter(Mandatory = $false)]
        [bool]$FlattenNestedObjects = $true,

        [Parameter(Mandatory = $false)]
        [string]$NestedSeparator = ".",

        [Parameter(Mandatory = $false)]
        [switch]$CheckForExecutableContent,

        [Parameter(Mandatory = $false)]
        [int]$MaxFileSizeKB = 10240
    )

    # VÃ©rifier que le module est initialisÃ©
    if (-not $script:IsInitialized) {
        $initialized = Initialize-UnifiedFileProcessor
        if (-not $initialized) {
            Write-Error "Le module UnifiedFileProcessor n'est pas initialisÃ©."
            return $false
        }
    }

    # Valider le fichier de maniÃ¨re sÃ©curisÃ©e
    $isSecureFile = Test-FileSecurely -FilePath $InputFile -Format $InputFormat -CheckForExecutableContent:$CheckForExecutableContent -MaxFileSizeKB $MaxFileSizeKB

    if (-not $isSecureFile) {
        Write-Error "Le fichier n'est pas sÃ»r ou n'est pas valide : $InputFile"
        return $false
    }

    # Convertir le fichier
    $result = Convert-File -InputFile $InputFile -OutputFile $OutputFile -InputFormat $InputFormat -OutputFormat $OutputFormat -FlattenNestedObjects $FlattenNestedObjects -NestedSeparator $NestedSeparator

    return $result
}

# Fonction pour traiter plusieurs fichiers en parallÃ¨le de maniÃ¨re sÃ©curisÃ©e
function Invoke-ParallelSecureFileProcessing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$InputFiles,

        [Parameter(Mandatory = $true)]
        [string]$OutputDir,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$InputFormat = "AUTO",

        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$OutputFormat,

        [Parameter(Mandatory = $false)]
        [bool]$FlattenNestedObjects = $true,

        [Parameter(Mandatory = $false)]
        [string]$NestedSeparator = ".",

        [Parameter(Mandatory = $false)]
        [switch]$CheckForExecutableContent,

        [Parameter(Mandatory = $false)]
        [int]$MaxFileSizeKB = 10240,

        [Parameter(Mandatory = $false)]
        [int]$ThrottleLimit = 3
    )

    # VÃ©rifier que le module est initialisÃ©
    if (-not $script:IsInitialized) {
        $initialized = Initialize-UnifiedFileProcessor
        if (-not $initialized) {
            Write-Error "Le module UnifiedFileProcessor n'est pas initialisÃ©."
            return $null
        }
    }

    # Valider les fichiers de maniÃ¨re sÃ©curisÃ©e
    $secureFiles = @()
    $insecureFiles = @()

    foreach ($file in $InputFiles) {
        $isSecureFile = Test-FileSecurely -FilePath $file -Format $InputFormat -CheckForExecutableContent:$CheckForExecutableContent -MaxFileSizeKB $MaxFileSizeKB

        if ($isSecureFile) {
            $secureFiles += $file
        } else {
            $insecureFiles += $file
            Write-Warning "Le fichier n'est pas sÃ»r ou n'est pas valide : $file"
        }
    }

    if ($secureFiles.Count -eq 0) {
        Write-Error "Aucun fichier sÃ»r Ã  traiter."
        return $null
    }

    if ($insecureFiles.Count -gt 0) {
        Write-Warning "Certains fichiers ont Ã©tÃ© exclus du traitement car ils ne sont pas sÃ»rs ou ne sont pas valides : $($insecureFiles.Count) fichier(s)"
    }

    # Convertir les fichiers en parallÃ¨le
    $results = Convert-FilesInParallel -InputFiles $secureFiles -OutputDir $OutputDir -InputFormat $InputFormat -OutputFormat $OutputFormat -FlattenNestedObjects $FlattenNestedObjects -NestedSeparator $NestedSeparator -ThrottleLimit $ThrottleLimit

    return $results
}

# Fonction pour analyser un fichier de maniÃ¨re sÃ©curisÃ©e
function Get-SecureFileAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$Format = "AUTO",

        [Parameter(Mandatory = $false)]
        [string]$OutputFile,

        [Parameter(Mandatory = $false)]
        [switch]$AsHtml,

        [Parameter(Mandatory = $false)]
        [switch]$CheckForExecutableContent,

        [Parameter(Mandatory = $false)]
        [int]$MaxFileSizeKB = 10240
    )

    # VÃ©rifier que le module est initialisÃ©
    if (-not $script:IsInitialized) {
        $initialized = Initialize-UnifiedFileProcessor
        if (-not $initialized) {
            Write-Error "Le module UnifiedFileProcessor n'est pas initialisÃ©."
            return $null
        }
    }

    # Valider le fichier de maniÃ¨re sÃ©curisÃ©e
    $isSecureFile = Test-FileSecurely -FilePath $FilePath -Format $Format -CheckForExecutableContent:$CheckForExecutableContent -MaxFileSizeKB $MaxFileSizeKB

    if (-not $isSecureFile) {
        Write-Error "Le fichier n'est pas sÃ»r ou n'est pas valide : $FilePath"
        return $null
    }

    # Analyser le fichier
    $result = Get-FileAnalysisReport -FilePath $FilePath -Format $Format -OutputFile $OutputFile -AsHtml:$AsHtml

    return $result
}

# Fonction pour analyser plusieurs fichiers en parallÃ¨le de maniÃ¨re sÃ©curisÃ©e
function Get-SecureFileAnalysisInParallel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$FilePaths,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$Format = "AUTO",

        [Parameter(Mandatory = $true)]
        [string]$OutputDir,

        [Parameter(Mandatory = $false)]
        [switch]$CheckForExecutableContent,

        [Parameter(Mandatory = $false)]
        [int]$MaxFileSizeKB = 10240,

        [Parameter(Mandatory = $false)]
        [int]$ThrottleLimit = 3
    )

    # VÃ©rifier que le module est initialisÃ©
    if (-not $script:IsInitialized) {
        $initialized = Initialize-UnifiedFileProcessor
        if (-not $initialized) {
            Write-Error "Le module UnifiedFileProcessor n'est pas initialisÃ©."
            return $null
        }
    }

    # Valider les fichiers de maniÃ¨re sÃ©curisÃ©e
    $secureFiles = @()
    $insecureFiles = @()

    foreach ($file in $FilePaths) {
        $isSecureFile = Test-FileSecurely -FilePath $file -Format $Format -CheckForExecutableContent:$CheckForExecutableContent -MaxFileSizeKB $MaxFileSizeKB

        if ($isSecureFile) {
            $secureFiles += $file
        } else {
            $insecureFiles += $file
            Write-Warning "Le fichier n'est pas sÃ»r ou n'est pas valide : $file"
        }
    }

    if ($secureFiles.Count -eq 0) {
        Write-Error "Aucun fichier sÃ»r Ã  analyser."
        return $null
    }

    if ($insecureFiles.Count -gt 0) {
        Write-Warning "Certains fichiers ont Ã©tÃ© exclus de l'analyse car ils ne sont pas sÃ»rs ou ne sont pas valides : $($insecureFiles.Count) fichier(s)"
    }

    # Analyser les fichiers en parallÃ¨le
    $results = Get-FileAnalysisInParallel -FilePaths $secureFiles -Format $Format -OutputDir $OutputDir -ThrottleLimit $ThrottleLimit

    return $results
}

# Fonction pour segmenter un fichier de maniÃ¨re sÃ©curisÃ©e
function Split-FileSecurely {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$OutputDir,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$Format = "AUTO",

        [Parameter(Mandatory = $false)]
        [int]$ChunkSizeKB = 100,

        [Parameter(Mandatory = $false)]
        [string]$FilePrefix = "segment",

        [Parameter(Mandatory = $false)]
        [switch]$CheckForExecutableContent,

        [Parameter(Mandatory = $false)]
        [int]$MaxFileSizeKB = 10240
    )

    # VÃ©rifier que le module est initialisÃ©
    if (-not $script:IsInitialized) {
        $initialized = Initialize-UnifiedFileProcessor
        if (-not $initialized) {
            Write-Error "Le module UnifiedFileProcessor n'est pas initialisÃ©."
            return $null
        }
    }

    # Valider le fichier de maniÃ¨re sÃ©curisÃ©e
    $isSecureFile = Test-FileSecurely -FilePath $FilePath -Format $Format -CheckForExecutableContent:$CheckForExecutableContent -MaxFileSizeKB $MaxFileSizeKB

    if (-not $isSecureFile) {
        Write-Error "Le fichier n'est pas sÃ»r ou n'est pas valide : $FilePath"
        return $null
    }

    # Segmenter le fichier
    $result = Split-FileIntoChunks -FilePath $FilePath -OutputDir $OutputDir -Format $Format -ChunkSizeKB $ChunkSizeKB -FilePrefix $FilePrefix

    return $result
}

# Fonction pour chiffrer un fichier de maniÃ¨re sÃ©curisÃ©e
function Protect-SecureFile {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile,

        [Parameter(Mandatory = $false)]
        [object]$EncryptionKey,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password,

        [Parameter(Mandatory = $false)]
        [switch]$CheckForExecutableContent,

        [Parameter(Mandatory = $false)]
        [int]$MaxFileSizeKB = 10240,

        [Parameter(Mandatory = $false)]
        [switch]$CreateSignature,

        [Parameter(Mandatory = $false)]
        [string]$SignatureFile
    )

    # VÃ©rifier que le module est initialisÃ©
    if (-not $script:IsInitialized) {
        $initialized = Initialize-UnifiedFileProcessor
        if (-not $initialized) {
            Write-Error "Le module UnifiedFileProcessor n'est pas initialisÃ©."
            return [PSCustomObject]@{
                InputFile     = $InputFile
                OutputFile    = $null
                Success       = $false
                EncryptionKey = $null
                SignatureFile = $null
            }
        }
    }

    # VÃ©rifier que le module de chiffrement est disponible
    if (-not $availableOptionalModules.ContainsKey("EncryptionUtils")) {
        Write-Error "Le module de chiffrement n'est pas disponible."
        return [PSCustomObject]@{
            InputFile     = $InputFile
            OutputFile    = $null
            Success       = $false
            EncryptionKey = $null
            SignatureFile = $null
        }
    }

    # Valider le fichier de maniÃ¨re sÃ©curisÃ©e
    $isSecureFile = Test-FileSecurely -FilePath $InputFile -CheckForExecutableContent:$CheckForExecutableContent -MaxFileSizeKB $MaxFileSizeKB

    if (-not $isSecureFile) {
        Write-Error "Le fichier n'est pas sÃ»r ou n'est pas valide : $InputFile"
        return [PSCustomObject]@{
            InputFile     = $InputFile
            OutputFile    = $null
            Success       = $false
            EncryptionKey = $EncryptionKey
            SignatureFile = $null
        }
    }

    # GÃ©nÃ©rer une clÃ© de chiffrement si nÃ©cessaire
    if (-not $EncryptionKey -and -not [string]::IsNullOrEmpty($Password)) {
        $EncryptionKey = New-EncryptionKey -Password $Password
    } elseif (-not $EncryptionKey) {
        $EncryptionKey = New-EncryptionKey
        Write-Verbose "ClÃ© de chiffrement gÃ©nÃ©rÃ©e automatiquement"
    }

    # Chiffrer le fichier
    $encryptResult = Protect-File -InputFile $InputFile -OutputFile $OutputFile -EncryptionKey $EncryptionKey

    if (-not $encryptResult) {
        Write-Error "Erreur lors du chiffrement du fichier : $InputFile"
        return [PSCustomObject]@{
            InputFile     = $InputFile
            OutputFile    = $OutputFile
            Success       = $false
            EncryptionKey = $EncryptionKey
            SignatureFile = $null
        }
    }

    # CrÃ©er une signature si demandÃ©
    if ($CreateSignature) {
        if ([string]::IsNullOrEmpty($SignatureFile)) {
            $SignatureFile = "$OutputFile.sig"
        }

        $signResult = New-FileSignature -FilePath $OutputFile -EncryptionKey $EncryptionKey -SignatureFile $SignatureFile

        if (-not $signResult) {
            Write-Warning "Erreur lors de la crÃ©ation de la signature du fichier : $OutputFile"
        }
    }

    return [PSCustomObject]@{
        InputFile     = $InputFile
        OutputFile    = $OutputFile
        Success       = $true
        EncryptionKey = $EncryptionKey
        SignatureFile = if ($CreateSignature) { $SignatureFile } else { $null }
    }
}

# Fonction pour dÃ©chiffrer un fichier de maniÃ¨re sÃ©curisÃ©e
function Unprotect-SecureFile {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile,

        [Parameter(Mandatory = $true)]
        [object]$EncryptionKey,

        [Parameter(Mandatory = $false)]
        [string]$SignatureFile,

        [Parameter(Mandatory = $false)]
        [switch]$VerifySignature
    )

    # VÃ©rifier que le module est initialisÃ©
    if (-not $script:IsInitialized) {
        $initialized = Initialize-UnifiedFileProcessor
        if (-not $initialized) {
            Write-Error "Le module UnifiedFileProcessor n'est pas initialisÃ©."
            return [PSCustomObject]@{
                InputFile  = $InputFile
                OutputFile = $null
                Success    = $false
            }
        }
    }

    # VÃ©rifier que le module de chiffrement est disponible
    if (-not $availableOptionalModules.ContainsKey("EncryptionUtils")) {
        Write-Error "Le module de chiffrement n'est pas disponible."
        return [PSCustomObject]@{
            InputFile  = $InputFile
            OutputFile = $null
            Success    = $false
        }
    }

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $InputFile -PathType Leaf)) {
        Write-Error "Le fichier n'existe pas : $InputFile"
        return [PSCustomObject]@{
            InputFile  = $InputFile
            OutputFile = $null
            Success    = $false
        }
    }

    # VÃ©rifier la signature si demandÃ©
    if ($VerifySignature) {
        if ([string]::IsNullOrEmpty($SignatureFile) -and (Test-Path -Path "$InputFile.sig")) {
            $SignatureFile = "$InputFile.sig"
        }

        if (-not [string]::IsNullOrEmpty($SignatureFile) -and (Test-Path -Path $SignatureFile)) {
            $signatureResult = Test-FileSignature -FilePath $InputFile -EncryptionKey $EncryptionKey -SignatureFile $SignatureFile

            if (-not $signatureResult.IsValid) {
                Write-Error "La signature du fichier n'est pas valide : $InputFile"
                return [PSCustomObject]@{
                    InputFile  = $InputFile
                    OutputFile = $null
                    Success    = $false
                }
            }

            Write-Verbose "Signature du fichier vÃ©rifiÃ©e avec succÃ¨s : $InputFile"
        } else {
            Write-Warning "Fichier de signature non trouvÃ©. La vÃ©rification de la signature a Ã©tÃ© ignorÃ©e."
        }
    }

    # DÃ©chiffrer le fichier
    $decryptResult = Unprotect-File -InputFile $InputFile -OutputFile $OutputFile -EncryptionKey $EncryptionKey

    if (-not $decryptResult) {
        Write-Error "Erreur lors du dÃ©chiffrement du fichier : $InputFile"
        return [PSCustomObject]@{
            InputFile  = $InputFile
            OutputFile = $OutputFile
            Success    = $false
        }
    }

    return [PSCustomObject]@{
        InputFile  = $InputFile
        OutputFile = $OutputFile
        Success    = $true
    }
}

# Fonction pour traiter un fichier avec mise en cache
function Invoke-CachedFileProcessing {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$InputFormat = "AUTO",

        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$OutputFormat,

        [Parameter(Mandatory = $false)]
        [bool]$FlattenNestedObjects = $true,

        [Parameter(Mandatory = $false)]
        [string]$NestedSeparator = ".",

        [Parameter(Mandatory = $false)]
        [int]$CacheTTL = -1
    )

    # VÃ©rifier que le module est initialisÃ©
    if (-not $script:IsInitialized) {
        $initialized = Initialize-UnifiedFileProcessor
        if (-not $initialized) {
            Write-Error "Le module UnifiedFileProcessor n'est pas initialisÃ©."
            return $false  # Ce retour est acceptable car la fonction a un OutputType([bool])
        }
    }

    # VÃ©rifier que le module de cache est disponible
    if (-not $availableOptionalModules.ContainsKey("CacheManager")) {
        Write-Verbose "Le module de cache n'est pas disponible. Traitement sans cache."
        return Invoke-SecureFileProcessing -InputFile $InputFile -OutputFile $OutputFile -InputFormat $InputFormat -OutputFormat $OutputFormat -FlattenNestedObjects $FlattenNestedObjects -NestedSeparator $NestedSeparator
    }

    # GÃ©nÃ©rer une clÃ© de cache basÃ©e sur les paramÃ¨tres
    $cacheKey = "FileProcessing_$InputFile`_$OutputFormat`_$FlattenNestedObjects`_$NestedSeparator"

    # DÃ©finir le script block pour le traitement du fichier
    $scriptBlock = {
        param($InputFile, $OutputFile, $InputFormat, $OutputFormat, $FlattenNestedObjects, $NestedSeparator)

        Invoke-SecureFileProcessing -InputFile $InputFile -OutputFile $OutputFile -InputFormat $InputFormat -OutputFormat $OutputFormat -FlattenNestedObjects $FlattenNestedObjects -NestedSeparator $NestedSeparator
    }

    # ExÃ©cuter le traitement avec mise en cache
    $arguments = @($InputFile, $OutputFile, $InputFormat, $OutputFormat, $FlattenNestedObjects, $NestedSeparator)
    $result = Invoke-CachedFunction -ScriptBlock $scriptBlock -CacheKey $cacheKey -TTL $CacheTTL -Arguments $arguments

    return $result
}

# Fonction pour aplatir le contenu CSV
function ConvertTo-FlatCsvContent {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [string]$Separator = "."
    )

    try {
        # Convertir le contenu CSV en objets
        $objects = ConvertFrom-Csv -InputObject $Content

        # Aplatir chaque objet
        $flattenedObjects = @()
        foreach ($obj in $objects) {
            $flattenedObj = [PSCustomObject]@{}
            $properties = $obj | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name

            foreach ($prop in $properties) {
                $value = $obj.$prop
                if ($value -is [PSCustomObject]) {
                    # Aplatir l'objet imbriqué
                    $nestedProps = $value | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
                    foreach ($nestedProp in $nestedProps) {
                        $flattenedObj | Add-Member -MemberType NoteProperty -Name "$prop$Separator$nestedProp" -Value $value.$nestedProp
                    }
                } else {
                    # Propriété simple
                    $flattenedObj | Add-Member -MemberType NoteProperty -Name $prop -Value $value
                }
            }

            $flattenedObjects += $flattenedObj
        }

        # Convertir les objets aplatis en CSV
        $flattenedContent = $flattenedObjects | ConvertTo-Csv -NoTypeInformation
        return $flattenedContent -join "`n"
    } catch {
        Write-Error "Erreur lors de l'aplatissement du contenu CSV : $_"
        return $Content
    }
}

# Fonction pour aplatir le contenu texte
function ConvertTo-FlatTextContent {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [string]$Separator = "."  # Utilisé à la ligne 773 pour séparer les clés et les valeurs
    )

    try {
        # Utiliser le séparateur pour les structures imbriquées
        Write-Verbose "Utilisation du séparateur: $Separator"

        # Diviser le contenu en lignes
        $lines = $Content -split "`n"

        # Aplatir chaque ligne
        $flattenedLines = @()
        foreach ($line in $lines) {
            $flattenedLine = $line

            # Rechercher les structures imbriquées (JSON-like)
            if ($line -match "\{.*\}") {
                # Extraire et aplatir les structures imbriquées
                $flattenedLine = $line -replace "\{([^{}]*)\}", { param($match)
                    $nestedContent = $match.Groups[1].Value
                    $nestedPairs = $nestedContent -split ","
                    $flattenedPairs = @()

                    foreach ($pair in $nestedPairs) {
                        if ($pair -match "([^:]+):(.*)") {
                            $key = $matches[1].Trim()
                            $value = $matches[2].Trim()
                            $flattenedPairs += "$key$Separator$value"
                        } else {
                            $flattenedPairs += $pair
                        }
                    }

                    return $flattenedPairs -join ","
                }
            }

            $flattenedLines += $flattenedLine
        }

        return $flattenedLines -join "`n"
    } catch {
        Write-Error "Erreur lors de l'aplatissement du contenu texte : $_"
        return $Content
    }
}

# Fonction pour convertir un fichier d'un format à un autre
function Convert-File {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "CSV", "YAML", "TEXT")]
        [string]$InputFormat = "AUTO",

        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "XML", "CSV", "YAML", "TEXT")]
        [string]$OutputFormat,

        [Parameter(Mandatory = $false)]
        [bool]$FlattenNestedObjects = $true,

        [Parameter(Mandatory = $false)]
        [string]$NestedSeparator = "."
    )

    # Vérifier que le module est initialisé
    if (-not $script:IsInitialized) {
        $initialized = Initialize-UnifiedFileProcessor
        if (-not $initialized) {
            Write-Error "Le module UnifiedFileProcessor n'est pas initialisé."
            return [PSCustomObject]@{
                InputFile     = $InputFile
                OutputFile    = $null
                Success       = $false
                EncryptionKey = $null
                SignatureFile = $null
            }
        }
    }

    # Vérifier que le fichier d'entrée existe
    if (-not (Test-Path -Path $InputFile -PathType Leaf)) {
        Write-Error "Le fichier d'entrée n'existe pas : $InputFile"
        return $false  # Ce retour est acceptable car la fonction a un OutputType([bool])
    }

    # Détecter le format d'entrée si nécessaire
    if ($InputFormat -eq "AUTO") {
        $InputFormat = Get-FileFormat -FilePath $InputFile
        Write-Verbose "Format d'entrée détecté : $InputFormat"
    }

    # Convertir le fichier en utilisant la façade de traitement de fichiers
    $result = Convert-FileFormat -InputFile $InputFile -OutputFile $OutputFile -InputFormat $InputFormat -OutputFormat $OutputFormat

    # Vérifier que la conversion a réussi
    if (-not $result) {
        Write-Error "Erreur lors de la conversion du fichier : $InputFile"
        return $false  # Ce retour est acceptable car la fonction a un OutputType([bool])
    }

    # Appliquer l'aplatissement des objets imbriqués si demandé
    if ($FlattenNestedObjects -and ($OutputFormat -eq "CSV" -or $OutputFormat -eq "TEXT")) {
        $tempFile = [System.IO.Path]::GetTempFileName()
        try {
            # Lire le fichier de sortie
            $content = Get-Content -Path $OutputFile -Raw

            # Aplatir les objets imbriqués
            $flattenedContent = $content
            if ($OutputFormat -eq "CSV") {
                $flattenedContent = ConvertTo-FlatCsvContent -Content $content -Separator $NestedSeparator
            } elseif ($OutputFormat -eq "TEXT") {
                $flattenedContent = ConvertTo-FlatTextContent -Content $content -Separator $NestedSeparator
            }

            # Écrire le contenu aplati dans un fichier temporaire
            Set-Content -Path $tempFile -Value $flattenedContent -Encoding UTF8

            # Remplacer le fichier de sortie par le fichier temporaire
            Copy-Item -Path $tempFile -Destination $OutputFile -Force
        } finally {
            # Supprimer le fichier temporaire
            if (Test-Path -Path $tempFile) {
                Remove-Item -Path $tempFile -Force
            }
        }
    }

    return $true
}

# Exporter les fonctions
# Export-ModuleMember est commenté pour permettre le chargement direct du script

