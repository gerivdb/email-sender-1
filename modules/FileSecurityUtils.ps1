#Requires -Version 5.1
<#
.SYNOPSIS
    Utilitaires de sÃ©curitÃ© pour le traitement de fichiers.
.DESCRIPTION
    Ce module fournit des fonctions essentielles pour amÃ©liorer la sÃ©curitÃ© lors du traitement de fichiers.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-06-06
#>

# Fonction pour valider un chemin de fichier
function Test-SecurePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$AllowRelativePaths,

        [Parameter(Mandatory = $false)]
        [string[]]$AllowedExtensions,

        [Parameter(Mandatory = $false)]
        [string[]]$BlockedExtensions = @(".exe", ".dll", ".ps1", ".bat", ".cmd", ".vbs", ".js")
    )

    # VÃ©rifier si le chemin est vide ou null
    if ([string]::IsNullOrWhiteSpace($Path)) {
        Write-Error "Le chemin ne peut pas Ãªtre vide."
        return $false
    }

    # VÃ©rifier si le chemin contient des caractÃ¨res invalides
    $invalidChars = [System.IO.Path]::GetInvalidPathChars()
    $invalidCharsFound = $invalidChars | Where-Object { $Path.Contains($_) }
    if ($invalidCharsFound) {
        Write-Error "Le chemin contient des caractÃ¨res invalides."
        return $false
    }

    # VÃ©rifier si le chemin est relatif
    $isRelative = -not [System.IO.Path]::IsPathRooted($Path)
    if ($isRelative -and -not $AllowRelativePaths) {
        Write-Error "Les chemins relatifs ne sont pas autorisÃ©s."
        return $false
    }

    # VÃ©rifier l'extension du fichier
    $extension = [System.IO.Path]::GetExtension($Path).ToLower()

    # VÃ©rifier si l'extension est dans la liste des extensions bloquÃ©es
    if ($BlockedExtensions -contains $extension) {
        Write-Error "L'extension de fichier '$extension' n'est pas autorisÃ©e."
        return $false
    }

    # VÃ©rifier si l'extension est dans la liste des extensions autorisÃ©es (si spÃ©cifiÃ©e)
    if ($AllowedExtensions -and $AllowedExtensions.Count -gt 0) {
        if (-not ($AllowedExtensions -contains $extension)) {
            Write-Error "L'extension de fichier '$extension' n'est pas dans la liste des extensions autorisÃ©es."
            return $false
        }
    }

    # Si toutes les vÃ©rifications sont passÃ©es, le chemin est valide
    return $true
}

# Fonction pour valider le contenu d'un fichier
function Test-SecureContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [int]$MaxFileSizeKB = 10240,

        [Parameter(Mandatory = $false)]
        [switch]$CheckForExecutableContent
    )

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier n'existe pas : $FilePath"
        return $false
    }

    # VÃ©rifier la taille du fichier
    $fileSize = (Get-Item -Path $FilePath).Length / 1KB
    if ($fileSize -gt $MaxFileSizeKB) {
        Write-Error "La taille du fichier ($([math]::Round($fileSize, 2)) KB) dÃ©passe la taille maximale autorisÃ©e ($MaxFileSizeKB KB)."
        return $false
    }

    # VÃ©rifier si le fichier contient du contenu exÃ©cutable
    if ($CheckForExecutableContent) {
        $fileContent = Get-Content -Path $FilePath -Raw

        # Rechercher des motifs suspects
        $suspiciousPatterns = @(
            # PowerShell
            "Invoke-Expression",
            "IEX",
            "Invoke-Command",
            "ScriptBlock",

            # JavaScript
            "<script>",
            "eval\(",

            # SQL Injection
            "SELECT.*FROM",
            "INSERT INTO",
            "DROP TABLE",

            # Commandes systÃ¨me
            "cmd\.exe",
            "powershell\.exe"
        )

        foreach ($pattern in $suspiciousPatterns) {
            if ($fileContent -match $pattern) {
                Write-Warning "Le fichier contient un motif suspect : $pattern"
                return $false
            }
        }
    }

    # Si toutes les vÃ©rifications sont passÃ©es, le contenu est considÃ©rÃ© comme sÃ»r
    return $true
}

# Fonction pour valider un fichier de maniÃ¨re sÃ©curisÃ©e
function Test-FileSecurely {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$Format = "AUTO",

        [Parameter(Mandatory = $false)]
        [string]$SchemaFile,

        [Parameter(Mandatory = $false)]
        [int]$MaxFileSizeKB = 10240,

        [Parameter(Mandatory = $false)]
        [switch]$CheckForExecutableContent
    )

    # Vérifier que le module UnifiedSegmenter est disponible
    $moduleRoot = $PSScriptRoot
    $unifiedSegmenterPath = Join-Path -Path $moduleRoot -ChildPath "UnifiedSegmenter.ps1"

    if (-not (Test-Path -Path $unifiedSegmenterPath)) {
        Write-Error "Le module UnifiedSegmenter.ps1 n'est pas disponible."
        return $false
    }

    # Importer le module UnifiedSegmenter
    . $unifiedSegmenterPath

    # Initialiser le segmenteur unifiÃ©
    $initResult = Initialize-UnifiedSegmenter
    if (-not $initResult) {
        Write-Error "Erreur lors de l'initialisation du segmenteur unifiÃ©."
        return $false
    }

    # Valider le chemin du fichier
    $isPathValid = Test-SecurePath -Path $FilePath -AllowRelativePaths
    if (-not $isPathValid) {
        Write-Error "Chemin de fichier invalide : $FilePath"
        return $false
    }

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier n'existe pas : $FilePath"
        return $false
    }

    # Valider le contenu du fichier
    $isContentValid = Test-SecureContent -FilePath $FilePath -MaxFileSizeKB $MaxFileSizeKB -CheckForExecutableContent:$CheckForExecutableContent
    if (-not $isContentValid) {
        Write-Error "Contenu de fichier invalide : $FilePath"
        return $false
    }

    # DÃ©tecter le format si nÃ©cessaire
    if ($Format -eq "AUTO") {
        $Format = Get-FileFormat -FilePath $FilePath
        Write-Verbose "Format dÃ©tectÃ© : $Format"
    }

    # Valider le fichier selon son format
    $isValid = Test-FileValidity -FilePath $FilePath -Format $Format -SchemaFile $SchemaFile

    return $isValid
}

# Exporter les fonctions
# Export-ModuleMember est commentÃ© pour permettre le chargement direct du script

