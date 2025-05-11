<#
.SYNOPSIS
    Gestionnaire d'export pour le partage des vues.

.DESCRIPTION
    Ce module implémente le gestionnaire d'export qui permet d'exporter
    les vues dans différents formats (JSON, URL paramétré, fichier autonome).

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer les modules requis
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$permissionManagerPath = Join-Path -Path $scriptDir -ChildPath "PermissionManager.ps1"
$encryptionManagerPath = Join-Path -Path $scriptDir -ChildPath "EncryptionManager.ps1"

if (Test-Path -Path $permissionManagerPath) {
    . $permissionManagerPath
} else {
    throw "Le module PermissionManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $permissionManagerPath"
}

if (Test-Path -Path $encryptionManagerPath) {
    . $encryptionManagerPath
} else {
    throw "Le module EncryptionManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $encryptionManagerPath"
}

# Classe pour représenter le gestionnaire d'export
class ExportManager {
    # Propriétés
    [string]$ExportStorePath
    [bool]$EnableDebug
    [hashtable]$ExportFormats

    # Constructeur par défaut
    ExportManager() {
        $this.ExportStorePath = Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ExportStore"
        $this.EnableDebug = $false
        $this.InitializeExportFormats()
    }

    # Constructeur avec paramètres
    ExportManager([string]$exportStorePath, [bool]$enableDebug) {
        $this.ExportStorePath = $exportStorePath
        $this.EnableDebug = $enableDebug
        $this.InitializeExportFormats()
    }

    # Méthode pour initialiser les formats d'export
    [void] InitializeExportFormats() {
        $this.ExportFormats = @{
            "JSON"         = @{
                Extension   = ".json"
                ContentType = "application/json"
                Description = "Format JSON standard"
            }
            "JSON_COMPACT" = @{
                Extension   = ".min.json"
                ContentType = "application/json"
                Description = "Format JSON compact (minifié)"
            }
            "URL"          = @{
                Extension   = ".url"
                ContentType = "text/plain"
                Description = "URL paramétré"
            }
            "STANDALONE"   = @{
                Extension   = ".html"
                ContentType = "text/html"
                Description = "Fichier HTML autonome"
            }
        }
    }

    # Méthode pour écrire des messages de débogage
    [void] WriteDebug([string]$message) {
        if ($this.EnableDebug) {
            Write-Host "[DEBUG] [ExportManager] $message" -ForegroundColor Cyan
        }
    }

    # Méthode pour initialiser le stockage des exports
    [void] InitializeExportStore() {
        $this.WriteDebug("Initialisation du stockage des exports")

        try {
            # Créer le répertoire de stockage s'il n'existe pas
            if (-not (Test-Path -Path $this.ExportStorePath)) {
                New-Item -Path $this.ExportStorePath -ItemType Directory -Force | Out-Null
                $this.WriteDebug("Répertoire de stockage créé: $($this.ExportStorePath)")
            }

            # Créer les sous-répertoires pour chaque format d'export
            foreach ($format in $this.ExportFormats.Keys) {
                $formatPath = Join-Path -Path $this.ExportStorePath -ChildPath $format

                if (-not (Test-Path -Path $formatPath)) {
                    New-Item -Path $formatPath -ItemType Directory -Force | Out-Null
                    $this.WriteDebug("Répertoire de stockage pour le format $format créé: $formatPath")
                }
            }

            $this.WriteDebug("Initialisation du stockage des exports terminée")
        } catch {
            $this.WriteDebug("Erreur lors de l'initialisation du stockage des exports - $($_.Exception.Message)")
            throw "Erreur lors de l'initialisation du stockage des exports - $($_.Exception.Message)"
        }
    }

    # Méthode pour exporter une vue au format JSON
    [string] ExportToJSON([PSObject]$viewData, [bool]$compact = $false) {
        $format = if ($compact) { "JSON_COMPACT" } else { "JSON" }
        $this.WriteDebug("Export de la vue au format $format")

        try {
            # Initialiser le stockage des exports
            $this.InitializeExportStore()

            # Générer un nom de fichier unique
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $fileName = "view_$($viewData.Id)_$timestamp$($this.ExportFormats[$format].Extension)"
            $filePath = Join-Path -Path (Join-Path -Path $this.ExportStorePath -ChildPath $format) -ChildPath $fileName

            # Convertir les données en JSON
            $jsonContent = if ($compact) {
                $viewData | ConvertTo-Json -Depth 10 -Compress
            } else {
                $viewData | ConvertTo-Json -Depth 10
            }

            # Écrire le fichier JSON
            $jsonContent | Out-File -FilePath $filePath -Encoding utf8

            $this.WriteDebug("Vue exportée avec succès au format $format - $filePath")
            return $filePath
        } catch {
            $this.WriteDebug("Erreur lors de l'export de la vue au format $format - $($_.Exception.Message)")
            throw "Erreur lors de l'export de la vue au format $format - $($_.Exception.Message)"
        }
    }

    # Méthode pour exporter une vue au format URL paramétré
    [string] ExportToURL([PSObject]$viewData, [string]$baseURL) {
        $this.WriteDebug("Export de la vue au format URL")

        try {
            # Initialiser le stockage des exports
            $this.InitializeExportStore()

            # Générer un nom de fichier unique
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $fileName = "view_$($viewData.Id)_$timestamp$($this.ExportFormats["URL"].Extension)"
            $filePath = Join-Path -Path (Join-Path -Path $this.ExportStorePath -ChildPath "URL") -ChildPath $fileName

            # Convertir les données en JSON compact
            $jsonContent = $viewData | ConvertTo-Json -Depth 10 -Compress

            # Encoder le JSON pour l'URL (méthode compatible avec PowerShell 5.1)
            $encodedJson = [System.Uri]::EscapeDataString($jsonContent)

            # Construire l'URL
            $urlString = "$baseURL" + "?data=$encodedJson"

            # Écrire le fichier URL
            $urlString | Out-File -FilePath $filePath -Encoding utf8

            $this.WriteDebug("Vue exportée avec succès au format URL: $filePath")
            return $filePath
        } catch {
            $this.WriteDebug("Erreur lors de l'export de la vue au format URL - $($_.Exception.Message)")
            throw "Erreur lors de l'export de la vue au format URL - $($_.Exception.Message)"
        }
    }

    # Méthode pour exporter une vue au format fichier autonome
    [string] ExportToStandalone([PSObject]$viewData, [string]$templatePath) {
        $this.WriteDebug("Export de la vue au format fichier autonome")

        try {
            # Initialiser le stockage des exports
            $this.InitializeExportStore()

            # Générer un nom de fichier unique
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $fileName = "view_$($viewData.Id)_$timestamp$($this.ExportFormats["STANDALONE"].Extension)"
            $filePath = Join-Path -Path (Join-Path -Path $this.ExportStorePath -ChildPath "STANDALONE") -ChildPath $fileName

            # Vérifier si le template existe
            if (-not (Test-Path -Path $templatePath)) {
                throw "Le template pour le fichier autonome n'existe pas: $templatePath"
            }

            # Lire le template
            $template = Get-Content -Path $templatePath -Raw

            # Convertir les données en JSON
            $jsonContent = $viewData | ConvertTo-Json -Depth 10 -Compress

            # Remplacer le placeholder dans le template
            $content = $template -replace "{{VIEW_DATA}}", $jsonContent

            # Écrire le fichier autonome
            $content | Out-File -FilePath $filePath -Encoding utf8

            $this.WriteDebug("Vue exportée avec succès au format fichier autonome: $filePath")
            return $filePath
        } catch {
            $this.WriteDebug("Erreur lors de l'export de la vue au format fichier autonome - $($_.Exception.Message)")
            throw "Erreur lors de l'export de la vue au format fichier autonome - $($_.Exception.Message)"
        }
    }

    # Méthode pour exporter une vue avec chiffrement
    [string] ExportEncrypted([PSObject]$viewData, [string]$format, [System.Security.SecureString]$password) {
        $this.WriteDebug("Export chiffré de la vue au format $format")

        try {
            # Exporter la vue au format demandé
            $exportPath = switch ($format) {
                "JSON" { $this.ExportToJSON($viewData, $false) }
                "JSON_COMPACT" { $this.ExportToJSON($viewData, $true) }
                "URL" { throw "Le format URL ne peut pas être chiffré directement" }
                "STANDALONE" { throw "Le format fichier autonome ne peut pas être chiffré directement" }
                default { throw "Format d'export inconnu: $format" }
            }

            # Générer une clé AES à partir du mot de passe
            $encryptionManager = New-EncryptionManager -EnableDebug:$this.EnableDebug
            $salt = [System.Text.Encoding]::UTF8.GetBytes("ViewSharingExport")

            # Convertir le SecureString en texte brut pour le chiffrement
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
            $passwordPlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

            $passwordBytes = [System.Text.Encoding]::UTF8.GetBytes($passwordPlainText)
            $keyBytes = $encryptionManager.DeriveKeyFromPassword($passwordBytes, $salt, 32)
            $ivBytes = $encryptionManager.DeriveKeyFromPassword($passwordBytes, $salt, 16)

            $aesKey = [PSCustomObject]@{
                Key = $keyBytes
                IV  = $ivBytes
            }

            # Chiffrer le fichier
            $encryptedPath = Protect-File -InputPath $exportPath -Method "AES" -KeyData $aesKey -EnableDebug:$this.EnableDebug

            # Supprimer le fichier non chiffré
            Remove-Item -Path $exportPath -Force

            $this.WriteDebug("Vue exportée et chiffrée avec succès: $encryptedPath")
            return $encryptedPath
        } catch {
            $this.WriteDebug("Erreur lors de l'export chiffré de la vue - $($_.Exception.Message)")
            throw "Erreur lors de l'export chiffré de la vue - $($_.Exception.Message)"
        }
    }
}

# Fonction pour créer un nouveau gestionnaire d'export
function New-ExportManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ExportStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ExportStore"),

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    return [ExportManager]::new($ExportStorePath, $EnableDebug)
}

# Fonction pour exporter une vue au format JSON
function Export-ViewToJSON {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$ViewData,

        [Parameter(Mandatory = $false)]
        [switch]$Compact,

        [Parameter(Mandatory = $false)]
        [string]$ExportStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ExportStore"),

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $exportManager = New-ExportManager -ExportStorePath $ExportStorePath -EnableDebug:$EnableDebug
    return $exportManager.ExportToJSON($ViewData, $Compact)
}

# Fonction pour exporter une vue au format URL paramétré
function Export-ViewToURL {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$ViewData,

        [Parameter(Mandatory = $true)]
        [string]$BaseURL,

        [Parameter(Mandatory = $false)]
        [string]$ExportStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ExportStore"),

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $exportManager = New-ExportManager -ExportStorePath $ExportStorePath -EnableDebug:$EnableDebug
    return $exportManager.ExportToURL($ViewData, $BaseURL)
}

# Fonction pour exporter une vue au format fichier autonome
function Export-ViewToStandalone {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$ViewData,

        [Parameter(Mandatory = $true)]
        [string]$TemplatePath,

        [Parameter(Mandatory = $false)]
        [string]$ExportStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ExportStore"),

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $exportManager = New-ExportManager -ExportStorePath $ExportStorePath -EnableDebug:$EnableDebug
    return $exportManager.ExportToStandalone($ViewData, $TemplatePath)
}

# Fonction pour exporter une vue avec chiffrement
function Export-ViewEncrypted {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$ViewData,

        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "JSON_COMPACT")]
        [string]$Format,

        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]$Password,

        [Parameter(Mandatory = $false)]
        [string]$ExportStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ExportStore"),

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $exportManager = New-ExportManager -ExportStorePath $ExportStorePath -EnableDebug:$EnableDebug
    return $exportManager.ExportEncrypted($ViewData, $Format, $Password)
}

# Exporter les fonctions
# Export-ModuleMember -Function New-ExportManager, Export-ViewToJSON, Export-ViewToURL, Export-ViewToStandalone, Export-ViewEncrypted
