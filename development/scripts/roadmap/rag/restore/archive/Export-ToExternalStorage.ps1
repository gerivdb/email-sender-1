# Export-ToExternalStorage.ps1
# Script pour exporter les archives de points de restauration vers un stockage externe
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ArchivePath = "",

    [Parameter(Mandatory = $false)]
    [string[]]$ArchivePaths = @(),

    [Parameter(Mandatory = $false)]
    [ValidateSet("Local", "Network", "Azure", "AWS", "GCP", "FTP", "SFTP")]
    [string]$StorageType = "Local",

    [Parameter(Mandatory = $false)]
    [string]$DestinationPath = "",

    [Parameter(Mandatory = $false)]
    [string]$ConfigName = "default",

    [Parameter(Mandatory = $false)]
    [hashtable]$ConnectionParams = @{},

    [Parameter(Mandatory = $false)]
    [switch]$RemoveOriginals,

    [Parameter(Mandatory = $false)]
    [switch]$CreateLogFile,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $rootPath))) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )

        if ($LogLevel -eq "None") {
            return
        }

        $logLevels = @{
            "Error"   = 0
            "Warning" = 1
            "Info"    = 2
            "Debug"   = 3
        }

        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }

            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Fonction pour obtenir le chemin du répertoire des archives
function Get-ArchivesPath {
    [CmdletBinding()]
    param()

    $archivesPath = Join-Path -Path $rootPath -ChildPath "archives"

    if (-not (Test-Path -Path $archivesPath)) {
        New-Item -Path $archivesPath -ItemType Directory -Force | Out-Null
    }

    return $archivesPath
}

# Fonction pour obtenir le chemin du fichier de configuration d'exportation
function Get-ExportConfigPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default"
    )

    $configPath = Join-Path -Path $parentPath -ChildPath "config"

    if (-not (Test-Path -Path $configPath)) {
        New-Item -Path $configPath -ItemType Directory -Force | Out-Null
    }

    $exportPath = Join-Path -Path $configPath -ChildPath "export"

    if (-not (Test-Path -Path $exportPath)) {
        New-Item -Path $exportPath -ItemType Directory -Force | Out-Null
    }

    return Join-Path -Path $exportPath -ChildPath "$ConfigName.json"
}

# Fonction pour charger la configuration d'exportation
function Get-ExportConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default"
    )

    $configPath = Get-ExportConfigPath -ConfigName $ConfigName

    if (Test-Path -Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            return $config
        } catch {
            Write-Log "Error loading export configuration: $_" -Level "Error"
            return $null
        }
    } else {
        return $null
    }
}

# Fonction pour sauvegarder la configuration d'exportation
function Save-ExportConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config,

        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default"
    )

    $configPath = Get-ExportConfigPath -ConfigName $ConfigName

    try {
        $Config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
        Write-Log "Export configuration saved to: $configPath" -Level "Info"
        return $true
    } catch {
        Write-Log "Error saving export configuration: $_" -Level "Error"
        return $false
    }
}

# Fonction pour créer un journal d'exportation
function New-ExportLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        [Parameter(Mandatory = $true)]
        [string]$StorageType,

        [Parameter(Mandatory = $false)]
        [hashtable]$ConnectionParams = @{},

        [Parameter(Mandatory = $false)]
        [bool]$Success = $true,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = ""
    )

    $logEntry = @{
        id          = [Guid]::NewGuid().ToString()
        timestamp   = (Get-Date).ToString("o")
        archive     = @{
            path = $ArchivePath
            name = [System.IO.Path]::GetFileName($ArchivePath)
            size = if (Test-Path -Path $ArchivePath) { (Get-Item -Path $ArchivePath).Length } else { 0 }
        }
        destination = @{
            type = $StorageType
            path = $DestinationPath
        }
        result      = @{
            success          = $Success
            error_message    = $ErrorMessage
            duration_seconds = 0
        }
        connection  = @{}
    }

    # Filtrer les paramètres de connexion sensibles
    foreach ($key in $ConnectionParams.Keys) {
        if ($key -notmatch "password|key|secret|token") {
            $logEntry.connection[$key] = $ConnectionParams[$key]
        } else {
            $logEntry.connection[$key] = "********"
        }
    }

    return $logEntry
}

# Fonction pour sauvegarder un journal d'exportation
function Save-ExportLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$LogEntry
    )

    $logsPath = Join-Path -Path $rootPath -ChildPath "logs"

    if (-not (Test-Path -Path $logsPath)) {
        New-Item -Path $logsPath -ItemType Directory -Force | Out-Null
    }

    $exportLogsPath = Join-Path -Path $logsPath -ChildPath "exports"

    if (-not (Test-Path -Path $exportLogsPath)) {
        New-Item -Path $exportLogsPath -ItemType Directory -Force | Out-Null
    }

    $currentDate = Get-Date -Format "yyyy-MM-dd"
    $logFilePath = Join-Path -Path $exportLogsPath -ChildPath "export_log_$currentDate.json"

    try {
        # Charger le journal existant ou créer un nouveau
        if (Test-Path -Path $logFilePath) {
            $log = Get-Content -Path $logFilePath -Raw | ConvertFrom-Json

            # Vérifier si le journal est un tableau
            if (-not ($log -is [array])) {
                $log = @($log)
            }
        } else {
            $log = @()
        }

        # Ajouter la nouvelle entrée
        $log += $LogEntry

        # Sauvegarder le journal
        $log | ConvertTo-Json -Depth 10 | Out-File -FilePath $logFilePath -Encoding UTF8

        Write-Log "Export log saved to: $logFilePath" -Level "Debug"
        return $true
    } catch {
        Write-Log "Error saving export log: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

# Fonction pour exporter vers un stockage local ou réseau
function Export-ToLocalStorage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        [Parameter(Mandatory = $false)]
        [hashtable]$ConnectionParams = @{},

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )

    # Vérifier si le fichier source existe
    if (-not (Test-Path -Path $ArchivePath)) {
        Write-Log "Source archive not found: $ArchivePath" -Level "Error"
        return @{
            Success      = $false
            ErrorMessage = "Source archive not found: $ArchivePath"
        }
    }

    # Créer le répertoire de destination s'il n'existe pas
    if (-not (Test-Path -Path $DestinationPath)) {
        if (-not $WhatIf) {
            try {
                New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
                Write-Log "Created destination directory: $DestinationPath" -Level "Info"
            } catch {
                Write-Log "Error creating destination directory: $($_.Exception.Message)" -Level "Error"
                return @{
                    Success      = $false
                    ErrorMessage = "Error creating destination directory: $($_.Exception.Message)"
                }
            }
        } else {
            Write-Log "WhatIf: Would create destination directory: $DestinationPath" -Level "Info"
        }
    }

    # Construire le chemin de destination complet
    $fileName = [System.IO.Path]::GetFileName($ArchivePath)
    $destinationFilePath = Join-Path -Path $DestinationPath -ChildPath $fileName

    # Copier le fichier
    if (-not $WhatIf) {
        try {
            Copy-Item -Path $ArchivePath -Destination $destinationFilePath -Force
            Write-Log "Exported archive to: $destinationFilePath" -Level "Info"

            # Vérifier si le fichier de métadonnées existe et le copier également
            $metadataPath = [System.IO.Path]::ChangeExtension($ArchivePath, ".metadata.json")

            if (Test-Path -Path $metadataPath) {
                $metadataDestination = [System.IO.Path]::ChangeExtension($destinationFilePath, ".metadata.json")
                Copy-Item -Path $metadataPath -Destination $metadataDestination -Force
                Write-Log "Exported metadata to: $metadataDestination" -Level "Info"
            }

            return @{
                Success      = $true
                ErrorMessage = ""
            }
        } catch {
            Write-Log "Error exporting archive: $($_.Exception.Message)" -Level "Error"
            return @{
                Success      = $false
                ErrorMessage = "Error exporting archive: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Log "WhatIf: Would export archive to: $destinationFilePath" -Level "Info"
        return @{
            Success      = $true
            ErrorMessage = ""
        }
    }
}

# Fonction pour exporter vers Azure Blob Storage
function Export-ToAzureStorage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        [Parameter(Mandatory = $false)]
        [hashtable]$ConnectionParams = @{},

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )

    # Vérifier si le module Az.Storage est installé
    if (-not (Get-Module -ListAvailable -Name Az.Storage)) {
        Write-Log "Az.Storage module is not installed. Please install it using: Install-Module -Name Az.Storage -Force" -Level "Error"
        return @{
            Success      = $false
            ErrorMessage = "Az.Storage module is not installed"
        }
    }

    # Vérifier les paramètres de connexion requis
    $requiredParams = @("StorageAccountName", "StorageAccountKey", "ContainerName")

    foreach ($param in $requiredParams) {
        if (-not $ConnectionParams.ContainsKey($param) -or [string]::IsNullOrEmpty($ConnectionParams[$param])) {
            Write-Log "Missing required connection parameter: $param" -Level "Error"
            return @{
                Success      = $false
                ErrorMessage = "Missing required connection parameter: $param"
            }
        }
    }

    # Vérifier si le fichier source existe
    if (-not (Test-Path -Path $ArchivePath)) {
        Write-Log "Source archive not found: $ArchivePath" -Level "Error"
        return @{
            Success      = $false
            ErrorMessage = "Source archive not found: $ArchivePath"
        }
    }

    # Extraire les paramètres de connexion
    $storageAccountName = $ConnectionParams["StorageAccountName"]
    $storageAccountKey = $ConnectionParams["StorageAccountKey"]
    $containerName = $ConnectionParams["ContainerName"]

    # Construire le chemin de destination dans Azure
    $fileName = [System.IO.Path]::GetFileName($ArchivePath)
    $blobName = if ([string]::IsNullOrEmpty($DestinationPath)) {
        $fileName
    } else {
        "$DestinationPath/$fileName"
    }

    if (-not $WhatIf) {
        try {
            # Créer le contexte de stockage
            $storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

            # Télécharger le fichier vers Azure Blob Storage
            $result = Set-AzStorageBlobContent -File $ArchivePath -Container $containerName -Blob $blobName -Context $storageContext -Force

            if ($result) {
                Write-Log "Exported archive to Azure Blob Storage: $containerName/$blobName" -Level "Info"

                # Vérifier si le fichier de métadonnées existe et le télécharger également
                $metadataPath = [System.IO.Path]::ChangeExtension($ArchivePath, ".metadata.json")

                if (Test-Path -Path $metadataPath) {
                    $metadataBlobName = [System.IO.Path]::ChangeExtension($blobName, ".metadata.json")
                    $metadataResult = Set-AzStorageBlobContent -File $metadataPath -Container $containerName -Blob $metadataBlobName -Context $storageContext -Force

                    if ($metadataResult) {
                        Write-Log "Exported metadata to Azure Blob Storage: $containerName/$metadataBlobName" -Level "Info"
                    } else {
                        Write-Log "Failed to export metadata to Azure Blob Storage" -Level "Warning"
                    }
                }

                return @{
                    Success      = $true
                    ErrorMessage = ""
                }
            } else {
                Write-Log "Failed to export archive to Azure Blob Storage" -Level "Error"
                return @{
                    Success      = $false
                    ErrorMessage = "Failed to export archive to Azure Blob Storage"
                }
            }
        } catch {
            Write-Log "Error exporting to Azure Blob Storage: $($_.Exception.Message)" -Level "Error"
            return @{
                Success      = $false
                ErrorMessage = "Error exporting to Azure Blob Storage: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Log "WhatIf: Would export archive to Azure Blob Storage: $containerName/$blobName" -Level "Info"
        return @{
            Success      = $true
            ErrorMessage = ""
        }
    }
}

# Fonction pour exporter vers AWS S3
function Export-ToAWSStorage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        [Parameter(Mandatory = $false)]
        [hashtable]$ConnectionParams = @{},

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )

    # Vérifier si le module AWS.Tools.S3 est installé
    if (-not (Get-Module -ListAvailable -Name AWS.Tools.S3)) {
        Write-Log "AWS.Tools.S3 module is not installed. Please install it using: Install-Module -Name AWS.Tools.S3 -Force" -Level "Error"
        return @{
            Success      = $false
            ErrorMessage = "AWS.Tools.S3 module is not installed"
        }
    }

    # Vérifier les paramètres de connexion requis
    $requiredParams = @("AccessKey", "SecretKey", "BucketName", "Region")

    foreach ($param in $requiredParams) {
        if (-not $ConnectionParams.ContainsKey($param) -or [string]::IsNullOrEmpty($ConnectionParams[$param])) {
            Write-Log "Missing required connection parameter: $param" -Level "Error"
            return @{
                Success      = $false
                ErrorMessage = "Missing required connection parameter: $param"
            }
        }
    }

    # Vérifier si le fichier source existe
    if (-not (Test-Path -Path $ArchivePath)) {
        Write-Log "Source archive not found: $ArchivePath" -Level "Error"
        return @{
            Success      = $false
            ErrorMessage = "Source archive not found: $ArchivePath"
        }
    }

    # Extraire les paramètres de connexion
    $accessKey = $ConnectionParams["AccessKey"]
    $secretKey = $ConnectionParams["SecretKey"]
    $bucketName = $ConnectionParams["BucketName"]
    $region = $ConnectionParams["Region"]

    # Construire le chemin de destination dans S3
    $fileName = [System.IO.Path]::GetFileName($ArchivePath)
    $key = if ([string]::IsNullOrEmpty($DestinationPath)) {
        $fileName
    } else {
        "$DestinationPath/$fileName"
    }

    if (-not $WhatIf) {
        try {
            # Configurer les informations d'identification AWS
            Set-AWSCredential -AccessKey $accessKey -SecretKey $secretKey -StoreAs default

            # Définir la région par défaut
            Set-DefaultAWSRegion -Region $region

            # Télécharger le fichier vers S3
            $result = Write-S3Object -BucketName $bucketName -File $ArchivePath -Key $key -Force

            if ($result) {
                Write-Log "Exported archive to AWS S3: $bucketName/$key" -Level "Info"

                # Vérifier si le fichier de métadonnées existe et le télécharger également
                $metadataPath = [System.IO.Path]::ChangeExtension($ArchivePath, ".metadata.json")

                if (Test-Path -Path $metadataPath) {
                    $metadataKey = [System.IO.Path]::ChangeExtension($key, ".metadata.json")
                    $metadataResult = Write-S3Object -BucketName $bucketName -File $metadataPath -Key $metadataKey -Force

                    if ($metadataResult) {
                        Write-Log "Exported metadata to AWS S3: $bucketName/$metadataKey" -Level "Info"
                    } else {
                        Write-Log "Failed to export metadata to AWS S3" -Level "Warning"
                    }
                }

                return @{
                    Success      = $true
                    ErrorMessage = ""
                }
            } else {
                Write-Log "Failed to export archive to AWS S3" -Level "Error"
                return @{
                    Success      = $false
                    ErrorMessage = "Failed to export archive to AWS S3"
                }
            }
        } catch {
            Write-Log "Error exporting to AWS S3: $($_.Exception.Message)" -Level "Error"
            return @{
                Success      = $false
                ErrorMessage = "Error exporting to AWS S3: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Log "WhatIf: Would export archive to AWS S3: $bucketName/$key" -Level "Info"
        return @{
            Success      = $true
            ErrorMessage = ""
        }
    }
}

# Fonction pour exporter vers FTP
function Export-ToFTPStorage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        [Parameter(Mandatory = $false)]
        [hashtable]$ConnectionParams = @{},

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )

    # Vérifier les paramètres de connexion requis
    $requiredParams = @("Server", "Username", "Password", "Port")

    foreach ($param in $requiredParams) {
        if (-not $ConnectionParams.ContainsKey($param) -or [string]::IsNullOrEmpty($ConnectionParams[$param])) {
            Write-Log "Missing required connection parameter: $param" -Level "Error"
            return @{
                Success      = $false
                ErrorMessage = "Missing required connection parameter: $param"
            }
        }
    }

    # Vérifier si le fichier source existe
    if (-not (Test-Path -Path $ArchivePath)) {
        Write-Log "Source archive not found: $ArchivePath" -Level "Error"
        return @{
            Success      = $false
            ErrorMessage = "Source archive not found: $ArchivePath"
        }
    }

    # Extraire les paramètres de connexion
    $server = $ConnectionParams["Server"]
    $username = $ConnectionParams["Username"]
    $password = $ConnectionParams["Password"]
    $port = $ConnectionParams["Port"]
    $useSsl = if ($ConnectionParams.ContainsKey("UseSsl")) { $ConnectionParams["UseSsl"] } else { $false }

    # Construire le chemin de destination sur le serveur FTP
    $fileName = [System.IO.Path]::GetFileName($ArchivePath)
    $remotePath = if ([string]::IsNullOrEmpty($DestinationPath)) {
        $fileName
    } else {
        "$DestinationPath/$fileName"
    }

    if (-not $WhatIf) {
        try {
            # Créer une requête FTP
            $uri = if ($useSsl) {
                "ftps://$server`:$port/$remotePath"
            } else {
                "ftp://$server`:$port/$remotePath"
            }

            $request = [System.Net.FtpWebRequest]::Create($uri)
            $request.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
            $request.Credentials = New-Object System.Net.NetworkCredential($username, $password)
            $request.UseBinary = $true
            $request.UsePassive = $true
            $request.EnableSsl = $useSsl

            # Lire le fichier source
            $fileContent = [System.IO.File]::ReadAllBytes($ArchivePath)
            $request.ContentLength = $fileContent.Length

            # Télécharger le fichier
            $requestStream = $request.GetRequestStream()
            $requestStream.Write($fileContent, 0, $fileContent.Length)
            $requestStream.Close()

            # Obtenir la réponse
            $response = $request.GetResponse()
            $response.Close()

            Write-Log "Exported archive to FTP: $uri" -Level "Info"

            # Vérifier si le fichier de métadonnées existe et le télécharger également
            $metadataPath = [System.IO.Path]::ChangeExtension($ArchivePath, ".metadata.json")

            if (Test-Path -Path $metadataPath) {
                $metadataRemotePath = [System.IO.Path]::ChangeExtension($remotePath, ".metadata.json")
                $metadataUri = if ($useSsl) {
                    "ftps://$server`:$port/$metadataRemotePath"
                } else {
                    "ftp://$server`:$port/$metadataRemotePath"
                }

                $metadataRequest = [System.Net.FtpWebRequest]::Create($metadataUri)
                $metadataRequest.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
                $metadataRequest.Credentials = New-Object System.Net.NetworkCredential($username, $password)
                $metadataRequest.UseBinary = $true
                $metadataRequest.UsePassive = $true
                $metadataRequest.EnableSsl = $useSsl

                $metadataContent = [System.IO.File]::ReadAllBytes($metadataPath)
                $metadataRequest.ContentLength = $metadataContent.Length

                $metadataRequestStream = $metadataRequest.GetRequestStream()
                $metadataRequestStream.Write($metadataContent, 0, $metadataContent.Length)
                $metadataRequestStream.Close()

                $metadataResponse = $metadataRequest.GetResponse()
                $metadataResponse.Close()

                Write-Log "Exported metadata to FTP: $metadataUri" -Level "Info"
            }

            return @{
                Success      = $true
                ErrorMessage = ""
            }
        } catch {
            Write-Log "Error exporting to FTP: $($_.Exception.Message)" -Level "Error"
            return @{
                Success      = $false
                ErrorMessage = "Error exporting to FTP: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Log "WhatIf: Would export archive to FTP: $server/$remotePath" -Level "Info"
        return @{
            Success      = $true
            ErrorMessage = ""
        }
    }
}

# Fonction pour exporter vers SFTP
function Export-ToSFTPStorage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        [Parameter(Mandatory = $false)]
        [hashtable]$ConnectionParams = @{},

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )

    # Vérifier si le module Posh-SSH est installé
    if (-not (Get-Module -ListAvailable -Name Posh-SSH)) {
        Write-Log "Posh-SSH module is not installed. Please install it using: Install-Module -Name Posh-SSH -Force" -Level "Error"
        return @{
            Success      = $false
            ErrorMessage = "Posh-SSH module is not installed"
        }
    }

    # Vérifier les paramètres de connexion requis
    $requiredParams = @("Server", "Username", "Port")

    foreach ($param in $requiredParams) {
        if (-not $ConnectionParams.ContainsKey($param) -or [string]::IsNullOrEmpty($ConnectionParams[$param])) {
            Write-Log "Missing required connection parameter: $param" -Level "Error"
            return @{
                Success      = $false
                ErrorMessage = "Missing required connection parameter: $param"
            }
        }
    }

    # Vérifier si au moins une méthode d'authentification est fournie
    if (-not $ConnectionParams.ContainsKey("Password") -and -not $ConnectionParams.ContainsKey("KeyFile")) {
        Write-Log "Missing authentication method: either Password or KeyFile must be provided" -Level "Error"
        return @{
            Success      = $false
            ErrorMessage = "Missing authentication method: either Password or KeyFile must be provided"
        }
    }

    # Vérifier si le fichier source existe
    if (-not (Test-Path -Path $ArchivePath)) {
        Write-Log "Source archive not found: $ArchivePath" -Level "Error"
        return @{
            Success      = $false
            ErrorMessage = "Source archive not found: $ArchivePath"
        }
    }

    # Extraire les paramètres de connexion
    $server = $ConnectionParams["Server"]
    $username = $ConnectionParams["Username"]
    $port = $ConnectionParams["Port"]
    $password = if ($ConnectionParams.ContainsKey("Password")) { $ConnectionParams["Password"] } else { $null }
    $keyFile = if ($ConnectionParams.ContainsKey("KeyFile")) { $ConnectionParams["KeyFile"] } else { $null }

    # Construire le chemin de destination sur le serveur SFTP
    $fileName = [System.IO.Path]::GetFileName($ArchivePath)
    $remotePath = if ([string]::IsNullOrEmpty($DestinationPath)) {
        $fileName
    } else {
        "$DestinationPath/$fileName"
    }

    if (-not $WhatIf) {
        try {
            # Établir une session SFTP
            $session = $null

            if (-not [string]::IsNullOrEmpty($password)) {
                $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
                $credentials = New-Object System.Management.Automation.PSCredential($username, $securePassword)
                $session = New-SFTPSession -ComputerName $server -Credential $credentials -Port $port -AcceptKey
            } elseif (-not [string]::IsNullOrEmpty($keyFile)) {
                $session = New-SFTPSession -ComputerName $server -Username $username -KeyFile $keyFile -Port $port -AcceptKey
            }

            if ($null -eq $session) {
                Write-Log "Failed to establish SFTP session" -Level "Error"
                return @{
                    Success      = $false
                    ErrorMessage = "Failed to establish SFTP session"
                }
            }

            # Créer le répertoire de destination si nécessaire
            if (-not [string]::IsNullOrEmpty($DestinationPath)) {
                $directories = $DestinationPath.Split('/')
                $currentPath = ""

                foreach ($dir in $directories) {
                    if ([string]::IsNullOrEmpty($dir)) {
                        continue
                    }

                    $currentPath += "/$dir"

                    try {
                        $null = Get-SFTPItem -SessionId $session.SessionId -Path $currentPath -ErrorAction SilentlyContinue
                    } catch {
                        $null = New-SFTPItem -SessionId $session.SessionId -Path $currentPath -ItemType Directory
                    }
                }
            }

            # Télécharger le fichier
            $result = Set-SFTPItem -SessionId $session.SessionId -Path $ArchivePath -Destination $remotePath -Force

            if ($result) {
                Write-Log "Exported archive to SFTP: $server port $port path $remotePath" -Level "Info"

                # Vérifier si le fichier de métadonnées existe et le télécharger également
                $metadataPath = [System.IO.Path]::ChangeExtension($ArchivePath, ".metadata.json")

                if (Test-Path -Path $metadataPath) {
                    $metadataRemotePath = [System.IO.Path]::ChangeExtension($remotePath, ".metadata.json")
                    $metadataResult = Set-SFTPItem -SessionId $session.SessionId -Path $metadataPath -Destination $metadataRemotePath -Force

                    if ($metadataResult) {
                        Write-Log "Exported metadata to SFTP: $server port $port path $metadataRemotePath" -Level "Info"
                    } else {
                        Write-Log "Failed to export metadata to SFTP" -Level "Warning"
                    }
                }

                # Fermer la session SFTP
                Remove-SFTPSession -SessionId $session.SessionId

                return @{
                    Success      = $true
                    ErrorMessage = ""
                }
            } else {
                # Fermer la session SFTP
                Remove-SFTPSession -SessionId $session.SessionId

                Write-Log "Failed to export archive to SFTP" -Level "Error"
                return @{
                    Success      = $false
                    ErrorMessage = "Failed to export archive to SFTP"
                }
            }
        } catch {
            # Fermer la session SFTP si elle existe
            if ($null -ne $session) {
                Remove-SFTPSession -SessionId $session.SessionId -ErrorAction SilentlyContinue
            }

            Write-Log "Error exporting to SFTP: $($_.Exception.Message)" -Level "Error"
            return @{
                Success      = $false
                ErrorMessage = "Error exporting to SFTP: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Log "WhatIf: Would export archive to SFTP: $server port $port path $remotePath" -Level "Info"
        return @{
            Success      = $true
            ErrorMessage = ""
        }
    }
}

# Fonction pour exporter vers Google Cloud Storage
function Export-ToGCPStorage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        [Parameter(Mandatory = $false)]
        [hashtable]$ConnectionParams = @{},

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )

    # Vérifier si l'outil Google Cloud SDK est installé
    $gcloudPath = Get-Command -Name "gcloud" -ErrorAction SilentlyContinue

    if ($null -eq $gcloudPath) {
        Write-Log "Google Cloud SDK is not installed or not in PATH" -Level "Error"
        return @{
            Success      = $false
            ErrorMessage = "Google Cloud SDK is not installed or not in PATH"
        }
    }

    # Vérifier les paramètres de connexion requis
    $requiredParams = @("BucketName", "ProjectId")

    foreach ($param in $requiredParams) {
        if (-not $ConnectionParams.ContainsKey($param) -or [string]::IsNullOrEmpty($ConnectionParams[$param])) {
            Write-Log "Missing required connection parameter: $param" -Level "Error"
            return @{
                Success      = $false
                ErrorMessage = "Missing required connection parameter: $param"
            }
        }
    }

    # Vérifier si le fichier source existe
    if (-not (Test-Path -Path $ArchivePath)) {
        Write-Log "Source archive not found: $ArchivePath" -Level "Error"
        return @{
            Success      = $false
            ErrorMessage = "Source archive not found: $ArchivePath"
        }
    }

    # Extraire les paramètres de connexion
    $bucketName = $ConnectionParams["BucketName"]
    $projectId = $ConnectionParams["ProjectId"]
    $serviceAccountKey = if ($ConnectionParams.ContainsKey("ServiceAccountKey")) { $ConnectionParams["ServiceAccountKey"] } else { $null }

    # Construire le chemin de destination dans GCS
    $fileName = [System.IO.Path]::GetFileName($ArchivePath)
    $gcsPath = if ([string]::IsNullOrEmpty($DestinationPath)) {
        "gs://$bucketName/$fileName"
    } else {
        "gs://$bucketName/$DestinationPath/$fileName"
    }

    if (-not $WhatIf) {
        try {
            # Authentifier avec GCP si un fichier de clé de compte de service est fourni
            if (-not [string]::IsNullOrEmpty($serviceAccountKey)) {
                $tempKeyPath = [System.IO.Path]::GetTempFileName()
                $serviceAccountKey | Out-File -FilePath $tempKeyPath -Encoding UTF8

                $authResult = & gcloud auth activate-service-account --key-file=$tempKeyPath

                if ($LASTEXITCODE -ne 0) {
                    Remove-Item -Path $tempKeyPath -Force -ErrorAction SilentlyContinue
                    Write-Log "Failed to authenticate with GCP: $authResult" -Level "Error"
                    return @{
                        Success      = $false
                        ErrorMessage = "Failed to authenticate with GCP: $authResult"
                    }
                }

                Remove-Item -Path $tempKeyPath -Force -ErrorAction SilentlyContinue
            }

            # Définir le projet GCP
            $projectResult = & gcloud config set project $projectId

            if ($LASTEXITCODE -ne 0) {
                Write-Log "Failed to set GCP project: $projectResult" -Level "Error"
                return @{
                    Success      = $false
                    ErrorMessage = "Failed to set GCP project: $projectResult"
                }
            }

            # Télécharger le fichier vers GCS
            $uploadResult = & gcloud storage cp $ArchivePath $gcsPath

            if ($LASTEXITCODE -ne 0) {
                Write-Log "Failed to upload archive to GCS: $uploadResult" -Level "Error"
                return @{
                    Success      = $false
                    ErrorMessage = "Failed to upload archive to GCS: $uploadResult"
                }
            }

            Write-Log "Exported archive to GCS: $gcsPath" -Level "Info"

            # Vérifier si le fichier de métadonnées existe et le télécharger également
            $metadataPath = [System.IO.Path]::ChangeExtension($ArchivePath, ".metadata.json")

            if (Test-Path -Path $metadataPath) {
                $metadataGcsPath = [System.IO.Path]::ChangeExtension($gcsPath, ".metadata.json")
                $metadataUploadResult = & gcloud storage cp $metadataPath $metadataGcsPath

                if ($LASTEXITCODE -eq 0) {
                    Write-Log "Exported metadata to GCS: $metadataGcsPath" -Level "Info"
                } else {
                    Write-Log "Failed to export metadata to GCS: $metadataUploadResult" -Level "Warning"
                }
            }

            return @{
                Success      = $true
                ErrorMessage = ""
            }
        } catch {
            Write-Log "Error exporting to GCS: $($_.Exception.Message)" -Level "Error"
            return @{
                Success      = $false
                ErrorMessage = "Error exporting to GCS: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Log "WhatIf: Would export archive to GCS: $gcsPath" -Level "Info"
        return @{
            Success      = $true
            ErrorMessage = ""
        }
    }
}

# Fonction principale pour exporter vers un stockage externe
function Export-ToExternalStorage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "",

        [Parameter(Mandatory = $false)]
        [string[]]$ArchivePaths = @(),

        [Parameter(Mandatory = $false)]
        [ValidateSet("Local", "Network", "Azure", "AWS", "GCP", "FTP", "SFTP")]
        [string]$StorageType = "Local",

        [Parameter(Mandatory = $false)]
        [string]$DestinationPath = "",

        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default",

        [Parameter(Mandatory = $false)]
        [hashtable]$ConnectionParams = @{},

        [Parameter(Mandatory = $false)]
        [switch]$RemoveOriginals,

        [Parameter(Mandatory = $false)]
        [switch]$CreateLogFile,

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )

    # Charger la configuration si un nom de configuration est spécifié
    if (-not [string]::IsNullOrEmpty($ConfigName)) {
        $config = Get-ExportConfig -ConfigName $ConfigName

        if ($null -ne $config) {
            # Utiliser les paramètres de la configuration si non spécifiés explicitement
            if ([string]::IsNullOrEmpty($StorageType) -and $config.PSObject.Properties.Name.Contains("storage_type")) {
                $StorageType = $config.storage_type
            }

            if ([string]::IsNullOrEmpty($DestinationPath) -and $config.PSObject.Properties.Name.Contains("destination_path")) {
                $DestinationPath = $config.destination_path
            }

            if ($ConnectionParams.Count -eq 0 -and $config.PSObject.Properties.Name.Contains("connection_params")) {
                $ConnectionParams = @{}

                foreach ($prop in $config.connection_params.PSObject.Properties) {
                    $ConnectionParams[$prop.Name] = $prop.Value
                }
            }

            if (-not $PSBoundParameters.ContainsKey("RemoveOriginals") -and $config.PSObject.Properties.Name.Contains("remove_originals")) {
                $RemoveOriginals = $config.remove_originals
            }

            if (-not $PSBoundParameters.ContainsKey("CreateLogFile") -and $config.PSObject.Properties.Name.Contains("create_log_file")) {
                $CreateLogFile = $config.create_log_file
            }
        }
    }

    # Vérifier si un chemin d'archive est spécifié
    if ([string]::IsNullOrEmpty($ArchivePath) -and $ArchivePaths.Count -eq 0) {
        Write-Log "No archive path specified" -Level "Error"
        return $false
    }

    # Combiner les chemins d'archives
    $allArchivePaths = @()

    if (-not [string]::IsNullOrEmpty($ArchivePath)) {
        $allArchivePaths += $ArchivePath
    }

    if ($ArchivePaths.Count -gt 0) {
        $allArchivePaths += $ArchivePaths
    }

    # Vérifier si le répertoire de destination est spécifié
    if ([string]::IsNullOrEmpty($DestinationPath)) {
        Write-Log "No destination path specified" -Level "Error"
        return $false
    }

    # Initialiser les compteurs
    $successCount = 0
    $errorCount = 0
    $startTime = Get-Date

    # Exporter chaque archive
    foreach ($path in $allArchivePaths) {
        $exportStartTime = Get-Date
        $result = $null

        Write-Log "Exporting archive: $path" -Level "Info"

        # Exporter l'archive selon le type de stockage
        switch ($StorageType) {
            "Local" {
                $result = Export-ToLocalStorage -ArchivePath $path -DestinationPath $DestinationPath -ConnectionParams $ConnectionParams -WhatIf:$WhatIf
            }
            "Network" {
                $result = Export-ToLocalStorage -ArchivePath $path -DestinationPath $DestinationPath -ConnectionParams $ConnectionParams -WhatIf:$WhatIf
            }
            "Azure" {
                $result = Export-ToAzureStorage -ArchivePath $path -DestinationPath $DestinationPath -ConnectionParams $ConnectionParams -WhatIf:$WhatIf
            }
            "AWS" {
                $result = Export-ToAWSStorage -ArchivePath $path -DestinationPath $DestinationPath -ConnectionParams $ConnectionParams -WhatIf:$WhatIf
            }
            "FTP" {
                $result = Export-ToFTPStorage -ArchivePath $path -DestinationPath $DestinationPath -ConnectionParams $ConnectionParams -WhatIf:$WhatIf
            }
            "SFTP" {
                $result = Export-ToSFTPStorage -ArchivePath $path -DestinationPath $DestinationPath -ConnectionParams $ConnectionParams -WhatIf:$WhatIf
            }
            "GCP" {
                $result = Export-ToGCPStorage -ArchivePath $path -DestinationPath $DestinationPath -ConnectionParams $ConnectionParams -WhatIf:$WhatIf
            }
            default {
                Write-Log "Storage type not implemented: $StorageType" -Level "Error"
                $result = @{
                    Success      = $false
                    ErrorMessage = "Storage type not implemented: $StorageType"
                }
            }
        }

        $exportEndTime = Get-Date
        $exportDuration = $exportEndTime - $exportStartTime

        # Créer et sauvegarder le journal d'exportation
        if ($CreateLogFile -and -not $WhatIf) {
            $logEntry = New-ExportLog -ArchivePath $path -DestinationPath $DestinationPath -StorageType $StorageType -ConnectionParams $ConnectionParams -Success $result.Success -ErrorMessage $result.ErrorMessage
            $logEntry.result.duration_seconds = $exportDuration.TotalSeconds
            Save-ExportLog -LogEntry $logEntry
        }

        # Mettre à jour les compteurs
        if ($result.Success) {
            $successCount++

            # Supprimer l'original si demandé
            if ($RemoveOriginals -and -not $WhatIf) {
                try {
                    Remove-Item -Path $path -Force
                    Write-Log "Removed original archive: $path" -Level "Info"

                    # Supprimer également le fichier de métadonnées
                    $metadataPath = [System.IO.Path]::ChangeExtension($path, ".metadata.json")

                    if (Test-Path -Path $metadataPath) {
                        Remove-Item -Path $metadataPath -Force
                        Write-Log "Removed original metadata: $metadataPath" -Level "Info"
                    }
                } catch {
                    Write-Log "Error removing original archive: $($_.Exception.Message)" -Level "Warning"
                }
            } elseif ($RemoveOriginals -and $WhatIf) {
                Write-Log "WhatIf: Would remove original archive: $path" -Level "Info"
            }
        } else {
            $errorCount++
        }
    }

    # Calculer la durée totale
    $endTime = Get-Date
    $duration = $endTime - $startTime

    # Afficher le résumé
    Write-Log "Export operation completed: $successCount successful, $errorCount failed" -Level "Info"
    Write-Log "Total duration: $($duration.TotalSeconds) seconds" -Level "Info"

    return $errorCount -eq 0
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Export-ToExternalStorage -ArchivePath $ArchivePath -ArchivePaths $ArchivePaths -StorageType $StorageType -DestinationPath $DestinationPath -ConfigName $ConfigName -ConnectionParams $ConnectionParams -RemoveOriginals:$RemoveOriginals -CreateLogFile:$CreateLogFile -WhatIf:$WhatIf
}
