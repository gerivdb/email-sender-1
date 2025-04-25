#Requires -Version 5.1
<#
.SYNOPSIS
    Utilitaires de sécurité pour le traitement de fichiers.
.DESCRIPTION
    Ce module fournit des fonctions pour améliorer la sécurité lors du traitement de fichiers,
    notamment la validation des entrées, la détection de contenu malveillant et la journalisation sécurisée.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-06-06
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
        [switch]$AllowUNC,
        
        [Parameter(Mandatory = $false)]
        [switch]$AllowHttp,
        
        [Parameter(Mandatory = $false)]
        [string[]]$AllowedExtensions,
        
        [Parameter(Mandatory = $false)]
        [string[]]$BlockedExtensions = @(".exe", ".dll", ".ps1", ".bat", ".cmd", ".vbs", ".js", ".reg", ".msi", ".com")
    )
    
    # Vérifier si le chemin est vide ou null
    if ([string]::IsNullOrWhiteSpace($Path)) {
        Write-Error "Le chemin ne peut pas être vide."
        return $false
    }
    
    # Vérifier si le chemin contient des caractères invalides
    $invalidChars = [System.IO.Path]::GetInvalidPathChars()
    $invalidCharsFound = $invalidChars | Where-Object { $Path.Contains($_) }
    if ($invalidCharsFound) {
        Write-Error "Le chemin contient des caractères invalides."
        return $false
    }
    
    # Vérifier si le chemin est relatif
    $isRelative = -not [System.IO.Path]::IsPathRooted($Path)
    if ($isRelative -and -not $AllowRelativePaths) {
        Write-Error "Les chemins relatifs ne sont pas autorisés."
        return $false
    }
    
    # Vérifier si le chemin est un chemin UNC
    $isUNC = $Path -match "^\\\\[^\\]+\\[^\\]+.*$"
    if ($isUNC -and -not $AllowUNC) {
        Write-Error "Les chemins UNC ne sont pas autorisés."
        return $false
    }
    
    # Vérifier si le chemin est une URL
    $isHttp = $Path -match "^https?://"
    if ($isHttp -and -not $AllowHttp) {
        Write-Error "Les URLs ne sont pas autorisées."
        return $false
    }
    
    # Vérifier l'extension du fichier
    $extension = [System.IO.Path]::GetExtension($Path).ToLower()
    
    # Vérifier si l'extension est dans la liste des extensions bloquées
    if ($BlockedExtensions -contains $extension) {
        Write-Error "L'extension de fichier '$extension' n'est pas autorisée."
        return $false
    }
    
    # Vérifier si l'extension est dans la liste des extensions autorisées (si spécifiée)
    if ($AllowedExtensions -and $AllowedExtensions.Count -gt 0) {
        if (-not ($AllowedExtensions -contains $extension)) {
            Write-Error "L'extension de fichier '$extension' n'est pas dans la liste des extensions autorisées."
            return $false
        }
    }
    
    # Si toutes les vérifications sont passées, le chemin est valide
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
        [switch]$ScanForMalware,
        
        [Parameter(Mandatory = $false)]
        [switch]$CheckForExecutableContent
    )
    
    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier n'existe pas : $FilePath"
        return $false
    }
    
    # Vérifier la taille du fichier
    $fileSize = (Get-Item -Path $FilePath).Length / 1KB
    if ($fileSize -gt $MaxFileSizeKB) {
        Write-Error "La taille du fichier ($([math]::Round($fileSize, 2)) KB) dépasse la taille maximale autorisée ($MaxFileSizeKB KB)."
        return $false
    }
    
    # Vérifier si le fichier contient du contenu exécutable
    if ($CheckForExecutableContent) {
        $fileContent = Get-Content -Path $FilePath -Raw
        
        # Rechercher des motifs suspects
        $suspiciousPatterns = @(
            # PowerShell
            "Invoke-Expression",
            "IEX",
            "Invoke-Command",
            "ScriptBlock",
            "ExecutionContext",
            "Add-Type",
            
            # JavaScript
            "<script>",
            "eval\(",
            "document\.write",
            
            # SQL Injection
            "SELECT.*FROM",
            "INSERT INTO",
            "UPDATE.*SET",
            "DELETE FROM",
            "DROP TABLE",
            "UNION SELECT",
            
            # Commandes système
            "cmd\.exe",
            "powershell\.exe",
            "wscript\.exe",
            "cscript\.exe",
            "rundll32\.exe",
            "regsvr32\.exe"
        )
        
        foreach ($pattern in $suspiciousPatterns) {
            if ($fileContent -match $pattern) {
                Write-Warning "Le fichier contient un motif suspect : $pattern"
            }
        }
    }
    
    # Analyser le fichier à la recherche de logiciels malveillants (simulation)
    if ($ScanForMalware) {
        Write-Verbose "Analyse du fichier à la recherche de logiciels malveillants..."
        
        # Ici, vous pourriez intégrer un véritable scanner antivirus
        # Pour cet exemple, nous simulons une analyse
        $isMalware = $false
        
        if ($isMalware) {
            Write-Error "Le fichier contient potentiellement un logiciel malveillant."
            return $false
        }
    }
    
    # Si toutes les vérifications sont passées, le contenu est considéré comme sûr
    return $true
}

# Fonction pour journaliser les opérations de sécurité
function Write-SecureLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Information", "Warning", "Error", "SecurityAlert")]
        [string]$Level = "Information",
        
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeTimestamp,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeUsername,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeComputerName
    )
    
    # Construire l'entrée de journal
    $logEntry = ""
    
    # Ajouter l'horodatage
    if ($IncludeTimestamp) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry += "[$timestamp] "
    }
    
    # Ajouter le niveau
    $logEntry += "[$Level] "
    
    # Ajouter le nom d'utilisateur
    if ($IncludeUsername) {
        $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $logEntry += "[User: $username] "
    }
    
    # Ajouter le nom de l'ordinateur
    if ($IncludeComputerName) {
        $computerName = $env:COMPUTERNAME
        $logEntry += "[Computer: $computerName] "
    }
    
    # Ajouter le message
    $logEntry += $Message
    
    # Afficher le message dans la console
    switch ($Level) {
        "Information" { Write-Verbose $logEntry }
        "Warning" { Write-Warning $logEntry }
        "Error" { Write-Error $logEntry }
        "SecurityAlert" { 
            Write-Host $logEntry -ForegroundColor Red -BackgroundColor Black
            # Vous pourriez également déclencher une alerte ou une notification ici
        }
    }
    
    # Enregistrer dans un fichier journal si spécifié
    if ($LogFilePath) {
        # Créer le répertoire du fichier journal s'il n'existe pas
        $logDir = Split-Path -Parent $LogFilePath
        if (-not (Test-Path -Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        
        # Ajouter l'entrée au fichier journal
        Add-Content -Path $LogFilePath -Value $logEntry -Encoding UTF8
    }
}

# Fonction pour valider un fichier de manière sécurisée
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
        [switch]$CheckForExecutableContent,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath
    )
    
    # Vérifier que le module UnifiedSegmenter est disponible
    $scriptPath = $MyInvocation.MyCommand.Path
    $moduleRoot = Split-Path -Parent $scriptPath
    $unifiedSegmenterPath = Join-Path -Path $moduleRoot -ChildPath "UnifiedSegmenter.ps1"
    
    if (-not (Test-Path -Path $unifiedSegmenterPath)) {
        Write-Error "Le module UnifiedSegmenter.ps1 n'est pas disponible."
        return $false
    }
    
    # Importer le module UnifiedSegmenter
    . $unifiedSegmenterPath
    
    # Initialiser le segmenteur unifié
    $initResult = Initialize-UnifiedSegmenter
    if (-not $initResult) {
        Write-Error "Erreur lors de l'initialisation du segmenteur unifié."
        return $false
    }
    
    # Journaliser le début de la validation
    Write-SecureLog -Message "Début de la validation sécurisée du fichier : $FilePath" -Level "Information" -LogFilePath $LogFilePath -IncludeTimestamp -IncludeUsername
    
    # Valider le chemin du fichier
    $isPathValid = Test-SecurePath -Path $FilePath -AllowRelativePaths
    if (-not $isPathValid) {
        Write-SecureLog -Message "Chemin de fichier invalide : $FilePath" -Level "Error" -LogFilePath $LogFilePath -IncludeTimestamp -IncludeUsername
        return $false
    }
    
    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-SecureLog -Message "Le fichier n'existe pas : $FilePath" -Level "Error" -LogFilePath $LogFilePath -IncludeTimestamp -IncludeUsername
        return $false
    }
    
    # Valider le contenu du fichier
    $isContentValid = Test-SecureContent -FilePath $FilePath -MaxFileSizeKB $MaxFileSizeKB -CheckForExecutableContent:$CheckForExecutableContent
    if (-not $isContentValid) {
        Write-SecureLog -Message "Contenu de fichier invalide : $FilePath" -Level "Error" -LogFilePath $LogFilePath -IncludeTimestamp -IncludeUsername
        return $false
    }
    
    # Détecter le format si nécessaire
    if ($Format -eq "AUTO") {
        $Format = Get-FileFormat -FilePath $FilePath
        Write-SecureLog -Message "Format détecté : $Format" -Level "Information" -LogFilePath $LogFilePath -IncludeTimestamp
    }
    
    # Valider le fichier selon son format
    $isValid = Test-FileValidity -FilePath $FilePath -Format $Format -SchemaFile $SchemaFile
    
    # Journaliser le résultat de la validation
    if ($isValid) {
        Write-SecureLog -Message "Le fichier est valide : $FilePath (Format: $Format)" -Level "Information" -LogFilePath $LogFilePath -IncludeTimestamp
    } else {
        Write-SecureLog -Message "Le fichier n'est pas valide : $FilePath (Format: $Format)" -Level "Warning" -LogFilePath $LogFilePath -IncludeTimestamp -IncludeUsername
    }
    
    return $isValid
}

# Exporter les fonctions
Export-ModuleMember -Function Test-SecurePath, Test-SecureContent, Write-SecureLog, Test-FileSecurely
