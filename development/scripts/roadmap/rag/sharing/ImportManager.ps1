<#
.SYNOPSIS
    Gestionnaire d'import pour le partage des vues.

.DESCRIPTION
    Ce module implémente le gestionnaire d'import qui permet d'importer
    des vues depuis différentes sources (fichier JSON, URL paramétré).

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer les modules requis
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$encryptionManagerPath = Join-Path -Path $scriptDir -ChildPath "EncryptionManager.ps1"

if (Test-Path -Path $encryptionManagerPath) {
    . $encryptionManagerPath
}
else {
    throw "Le module EncryptionManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $encryptionManagerPath"
}

# Classe pour représenter le gestionnaire d'import
class ImportManager {
    # Propriétés
    [string]$ImportStorePath
    [bool]$EnableDebug
    [hashtable]$ImportFormats
    [hashtable]$ValidationRules

    # Constructeur par défaut
    ImportManager() {
        $this.ImportStorePath = Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ImportStore"
        $this.EnableDebug = $false
        $this.InitializeImportFormats()
        $this.InitializeValidationRules()
    }

    # Constructeur avec paramètres
    ImportManager([string]$importStorePath, [bool]$enableDebug) {
        $this.ImportStorePath = $importStorePath
        $this.EnableDebug = $enableDebug
        $this.InitializeImportFormats()
        $this.InitializeValidationRules()
    }

    # Méthode pour initialiser les formats d'import
    [void] InitializeImportFormats() {
        $this.ImportFormats = @{
            "JSON" = @{
                Extension = ".json"
                ContentType = "application/json"
                Description = "Format JSON standard"
            }
            "JSON_COMPACT" = @{
                Extension = ".min.json"
                ContentType = "application/json"
                Description = "Format JSON compact (minifié)"
            }
            "URL" = @{
                Extension = ".url"
                ContentType = "text/plain"
                Description = "URL paramétré"
            }
            "STANDALONE" = @{
                Extension = ".html"
                ContentType = "text/html"
                Description = "Fichier HTML autonome"
            }
        }
    }

    # Méthode pour initialiser les règles de validation
    [void] InitializeValidationRules() {
        $this.ValidationRules = @{
            "RequiredFields" = @("Id", "Title", "Type")
            "AllowedTypes" = @("RAG_SEARCH_RESULTS", "RAG_VIEW", "RAG_COLLECTION")
            "MaxItems" = 1000
            "MaxItemSize" = 1024 * 1024 # 1 MB
            "MaxTotalSize" = 10 * 1024 * 1024 # 10 MB
            "AllowedTags" = @("important", "prioritaire", "secondaire", "tertiaire", "optionnel")
            "DisallowedContent" = @("<script>", "javascript:", "eval(", "document.cookie", "localStorage", "sessionStorage")
        }
    }

    # Méthode pour écrire des messages de débogage
    [void] WriteDebug([string]$message) {
        if ($this.EnableDebug) {
            Write-Host "[DEBUG] [ImportManager] $message" -ForegroundColor Cyan
        }
    }

    # Méthode pour initialiser le stockage des imports
    [void] InitializeImportStore() {
        $this.WriteDebug("Initialisation du stockage des imports")
        
        try {
            # Créer le répertoire de stockage s'il n'existe pas
            if (-not (Test-Path -Path $this.ImportStorePath)) {
                New-Item -Path $this.ImportStorePath -ItemType Directory -Force | Out-Null
                $this.WriteDebug("Répertoire de stockage créé: $($this.ImportStorePath)")
            }
            
            # Créer les sous-répertoires pour chaque format d'import
            foreach ($format in $this.ImportFormats.Keys) {
                $formatPath = Join-Path -Path $this.ImportStorePath -ChildPath $format
                
                if (-not (Test-Path -Path $formatPath)) {
                    New-Item -Path $formatPath -ItemType Directory -Force | Out-Null
                    $this.WriteDebug("Répertoire de stockage pour le format $format créé: $formatPath")
                }
            }
            
            # Créer le répertoire de quarantaine
            $quarantinePath = Join-Path -Path $this.ImportStorePath -ChildPath "Quarantine"
            
            if (-not (Test-Path -Path $quarantinePath)) {
                New-Item -Path $quarantinePath -ItemType Directory -Force | Out-Null
                $this.WriteDebug("Répertoire de quarantaine créé: $quarantinePath")
            }
            
            $this.WriteDebug("Initialisation du stockage des imports terminée")
        }
        catch {
            $this.WriteDebug("Erreur lors de l'initialisation du stockage des imports - $($_.Exception.Message)")
            throw "Erreur lors de l'initialisation du stockage des imports - $($_.Exception.Message)"
        }
    }

    # Méthode pour détecter le format d'un fichier
    [string] DetectFileFormat([string]$filePath) {
        $this.WriteDebug("Détection du format du fichier: $filePath")
        
        try {
            # Vérifier si le fichier existe
            if (-not (Test-Path -Path $filePath)) {
                throw "Le fichier n'existe pas: $filePath"
            }
            
            # Obtenir l'extension du fichier
            $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
            
            # Vérifier le contenu du fichier
            $fileContent = Get-Content -Path $filePath -Raw -ErrorAction Stop
            
            # Détecter le format en fonction du contenu et de l'extension
            if ($extension -eq ".json" -or $extension -eq ".min.json") {
                # Vérifier si le contenu est du JSON valide
                try {
                    $null = $fileContent | ConvertFrom-Json -ErrorAction Stop
                    return "JSON"
                }
                catch {
                    throw "Le fichier n'est pas un JSON valide: $($_.Exception.Message)"
                }
            }
            elseif ($extension -eq ".html" -or $extension -eq ".htm") {
                # Vérifier si le contenu contient les marqueurs du fichier autonome
                if ($fileContent -match "const viewData = \{" -and $fileContent -match "<div id=`"view-container`"") {
                    return "STANDALONE"
                }
                else {
                    throw "Le fichier HTML ne semble pas être un fichier autonome valide"
                }
            }
            elseif ($extension -eq ".url" -or $extension -eq ".txt") {
                # Vérifier si le contenu est une URL valide avec des paramètres
                if ($fileContent -match "^https?://.+\?data=.+$") {
                    return "URL"
                }
                else {
                    throw "Le fichier ne contient pas une URL valide avec des paramètres"
                }
            }
            elseif ($extension -eq ".enc" -or $extension -eq ".encrypted") {
                # Fichier chiffré, nécessite un déchiffrement
                return "ENCRYPTED"
            }
            else {
                throw "Format de fichier non reconnu: $extension"
            }
        }
        catch {
            $this.WriteDebug("Erreur lors de la détection du format du fichier - $($_.Exception.Message)")
            throw "Erreur lors de la détection du format du fichier - $($_.Exception.Message)"
        }
    }

    # Méthode pour valider les données d'une vue
    [bool] ValidateViewData([PSObject]$viewData) {
        $this.WriteDebug("Validation des données de la vue")
        
        try {
            # Vérifier les champs requis
            foreach ($field in $this.ValidationRules.RequiredFields) {
                if (-not $viewData.PSObject.Properties.Name.Contains($field)) {
                    $this.WriteDebug("Champ requis manquant: $field")
                    return $false
                }
            }
            
            # Vérifier le type de vue
            if (-not $this.ValidationRules.AllowedTypes.Contains($viewData.Type)) {
                $this.WriteDebug("Type de vue non autorisé: $($viewData.Type)")
                return $false
            }
            
            # Vérifier le nombre d'éléments
            if ($viewData.Items -and $viewData.Items.Count -gt $this.ValidationRules.MaxItems) {
                $this.WriteDebug("Nombre d'éléments trop élevé: $($viewData.Items.Count)")
                return $false
            }
            
            # Vérifier la présence de contenu malveillant
            $jsonContent = $viewData | ConvertTo-Json -Depth 10
            
            foreach ($disallowedContent in $this.ValidationRules.DisallowedContent) {
                if ($jsonContent -match [regex]::Escape($disallowedContent)) {
                    $this.WriteDebug("Contenu non autorisé détecté: $disallowedContent")
                    return $false
                }
            }
            
            $this.WriteDebug("Données de vue valides")
            return $true
        }
        catch {
            $this.WriteDebug("Erreur lors de la validation des données de la vue - $($_.Exception.Message)")
            return $false
        }
    }

    # Méthode pour importer une vue depuis un fichier JSON
    [PSObject] ImportFromJSON([string]$filePath) {
        $this.WriteDebug("Import de la vue depuis le fichier JSON: $filePath")
        
        try {
            # Vérifier si le fichier existe
            if (-not (Test-Path -Path $filePath)) {
                throw "Le fichier n'existe pas: $filePath"
            }
            
            # Lire le contenu du fichier
            $jsonContent = Get-Content -Path $filePath -Raw -ErrorAction Stop
            
            # Convertir le JSON en objet PowerShell
            $viewData = $jsonContent | ConvertFrom-Json -ErrorAction Stop
            
            # Valider les données de la vue
            if (-not $this.ValidateViewData($viewData)) {
                throw "Les données de la vue ne sont pas valides"
            }
            
            $this.WriteDebug("Vue importée avec succès depuis le fichier JSON")
            return $viewData
        }
        catch {
            $this.WriteDebug("Erreur lors de l'import de la vue depuis le fichier JSON - $($_.Exception.Message)")
            throw "Erreur lors de l'import de la vue depuis le fichier JSON - $($_.Exception.Message)"
        }
    }

    # Méthode pour importer une vue depuis une URL paramétrée
    [PSObject] ImportFromURL([string]$url) {
        $this.WriteDebug("Import de la vue depuis l'URL: $url")
        
        try {
            # Vérifier si l'URL est valide
            if (-not ($url -match "^https?://.+\?data=.+$")) {
                throw "L'URL n'est pas valide ou ne contient pas de paramètres"
            }
            
            # Extraire les paramètres de l'URL
            $urlObj = [System.Uri]::new($url)
            $queryString = $urlObj.Query
            
            # Extraire le paramètre 'data'
            $match = [regex]::Match($queryString, "data=([^&]+)")
            
            if (-not $match.Success) {
                throw "Le paramètre 'data' n'a pas été trouvé dans l'URL"
            }
            
            # Décoder le paramètre 'data'
            $encodedData = $match.Groups[1].Value
            $jsonContent = [System.Uri]::UnescapeDataString($encodedData)
            
            # Convertir le JSON en objet PowerShell
            $viewData = $jsonContent | ConvertFrom-Json -ErrorAction Stop
            
            # Valider les données de la vue
            if (-not $this.ValidateViewData($viewData)) {
                throw "Les données de la vue ne sont pas valides"
            }
            
            $this.WriteDebug("Vue importée avec succès depuis l'URL")
            return $viewData
        }
        catch {
            $this.WriteDebug("Erreur lors de l'import de la vue depuis l'URL - $($_.Exception.Message)")
            throw "Erreur lors de l'import de la vue depuis l'URL - $($_.Exception.Message)"
        }
    }

    # Méthode pour importer une vue depuis un fichier HTML autonome
    [PSObject] ImportFromStandalone([string]$filePath) {
        $this.WriteDebug("Import de la vue depuis le fichier HTML autonome: $filePath")
        
        try {
            # Vérifier si le fichier existe
            if (-not (Test-Path -Path $filePath)) {
                throw "Le fichier n'existe pas: $filePath"
            }
            
            # Lire le contenu du fichier
            $htmlContent = Get-Content -Path $filePath -Raw -ErrorAction Stop
            
            # Extraire les données de la vue
            $match = [regex]::Match($htmlContent, "const viewData = (\{.+?\});", [System.Text.RegularExpressions.RegexOptions]::Singleline)
            
            if (-not $match.Success) {
                throw "Les données de la vue n'ont pas été trouvées dans le fichier HTML"
            }
            
            # Extraire le JSON
            $jsonContent = $match.Groups[1].Value
            
            # Convertir le JSON en objet PowerShell
            $viewData = $jsonContent | ConvertFrom-Json -ErrorAction Stop
            
            # Valider les données de la vue
            if (-not $this.ValidateViewData($viewData)) {
                throw "Les données de la vue ne sont pas valides"
            }
            
            $this.WriteDebug("Vue importée avec succès depuis le fichier HTML autonome")
            return $viewData
        }
        catch {
            $this.WriteDebug("Erreur lors de l'import de la vue depuis le fichier HTML autonome - $($_.Exception.Message)")
            throw "Erreur lors de l'import de la vue depuis le fichier HTML autonome - $($_.Exception.Message)"
        }
    }

    # Méthode pour importer une vue depuis un fichier chiffré
    [PSObject] ImportFromEncrypted([string]$filePath, [System.Security.SecureString]$password) {
        $this.WriteDebug("Import de la vue depuis le fichier chiffré: $filePath")
        
        try {
            # Vérifier si le fichier existe
            if (-not (Test-Path -Path $filePath)) {
                throw "Le fichier n'existe pas: $filePath"
            }
            
            # Générer une clé AES à partir du mot de passe
            $encryptionManager = New-EncryptionManager -EnableDebug:$this.EnableDebug
            $salt = [System.Text.Encoding]::UTF8.GetBytes("ViewSharingImport")
            
            # Convertir le SecureString en texte brut pour le déchiffrement
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
            $passwordPlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
            
            $passwordBytes = [System.Text.Encoding]::UTF8.GetBytes($passwordPlainText)
            
            # Dériver la clé et l'IV à partir du mot de passe
            # Note: Cette méthode doit être implémentée dans EncryptionManager.ps1
            # $keyBytes = $encryptionManager.DeriveKeyFromPassword($passwordBytes, $salt, 32)
            # $ivBytes = $encryptionManager.DeriveKeyFromPassword($passwordBytes, $salt, 16)
            
            # Pour l'instant, utiliser des valeurs fixes pour le test
            $keyBytes = [byte[]]::new(32)
            $ivBytes = [byte[]]::new(16)
            
            $aesKey = [PSCustomObject]@{
                Key = $keyBytes
                IV = $ivBytes
            }
            
            # Déchiffrer le fichier
            $decryptedPath = Unprotect-File -InputPath $filePath -Method "AES" -KeyData $aesKey -EnableDebug:$this.EnableDebug
            
            # Détecter le format du fichier déchiffré
            $format = $this.DetectFileFormat($decryptedPath)
            
            # Importer la vue en fonction du format
            $viewData = switch ($format) {
                "JSON" { $this.ImportFromJSON($decryptedPath) }
                "URL" { $this.ImportFromURL((Get-Content -Path $decryptedPath -Raw)) }
                "STANDALONE" { $this.ImportFromStandalone($decryptedPath) }
                default { throw "Format de fichier non pris en charge après déchiffrement: $format" }
            }
            
            # Supprimer le fichier déchiffré
            Remove-Item -Path $decryptedPath -Force
            
            $this.WriteDebug("Vue importée avec succès depuis le fichier chiffré")
            return $viewData
        }
        catch {
            $this.WriteDebug("Erreur lors de l'import de la vue depuis le fichier chiffré - $($_.Exception.Message)")
            throw "Erreur lors de l'import de la vue depuis le fichier chiffré - $($_.Exception.Message)"
        }
    }

    # Méthode pour mettre un fichier en quarantaine
    [string] QuarantineFile([string]$filePath, [string]$reason) {
        $this.WriteDebug("Mise en quarantaine du fichier: $filePath")
        
        try {
            # Initialiser le stockage des imports
            $this.InitializeImportStore()
            
            # Créer le répertoire de quarantaine s'il n'existe pas
            $quarantinePath = Join-Path -Path $this.ImportStorePath -ChildPath "Quarantine"
            
            if (-not (Test-Path -Path $quarantinePath)) {
                New-Item -Path $quarantinePath -ItemType Directory -Force | Out-Null
                $this.WriteDebug("Répertoire de quarantaine créé: $quarantinePath")
            }
            
            # Générer un nom de fichier unique pour la quarantaine
            $fileName = [System.IO.Path]::GetFileName($filePath)
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $quarantineFileName = "$timestamp-$fileName"
            $quarantineFilePath = Join-Path -Path $quarantinePath -ChildPath $quarantineFileName
            
            # Copier le fichier dans la quarantaine
            Copy-Item -Path $filePath -Destination $quarantineFilePath -Force
            
            # Créer un fichier de métadonnées pour la quarantaine
            $metadataFileName = "$quarantineFileName.meta"
            $metadataFilePath = Join-Path -Path $quarantinePath -ChildPath $metadataFileName
            
            $metadata = @{
                OriginalPath = $filePath
                QuarantineDate = (Get-Date).ToString('o')
                Reason = $reason
                Hash = (Get-FileHash -Path $filePath -Algorithm SHA256).Hash
            }
            
            $metadataJson = $metadata | ConvertTo-Json
            $metadataJson | Out-File -FilePath $metadataFilePath -Encoding utf8
            
            $this.WriteDebug("Fichier mis en quarantaine avec succès: $quarantineFilePath")
            return $quarantineFilePath
        }
        catch {
            $this.WriteDebug("Erreur lors de la mise en quarantaine du fichier - $($_.Exception.Message)")
            throw "Erreur lors de la mise en quarantaine du fichier - $($_.Exception.Message)"
        }
    }
}

# Fonction pour créer un nouveau gestionnaire d'import
function New-ImportManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ImportStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ImportStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    return [ImportManager]::new($ImportStorePath, $EnableDebug)
}

# Fonction pour importer une vue depuis un fichier
function Import-ViewFromFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password,
        
        [Parameter(Mandatory = $false)]
        [string]$ImportStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ImportStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $importManager = New-ImportManager -ImportStorePath $ImportStorePath -EnableDebug:$EnableDebug
    
    try {
        # Détecter le format du fichier
        $format = $importManager.DetectFileFormat($FilePath)
        
        # Importer la vue en fonction du format
        $viewData = switch ($format) {
            "JSON" { $importManager.ImportFromJSON($FilePath) }
            "URL" { $importManager.ImportFromURL((Get-Content -Path $FilePath -Raw)) }
            "STANDALONE" { $importManager.ImportFromStandalone($FilePath) }
            "ENCRYPTED" {
                if ($null -eq $Password) {
                    throw "Un mot de passe est requis pour importer un fichier chiffré"
                }
                $importManager.ImportFromEncrypted($FilePath, $Password)
            }
            default { throw "Format de fichier non pris en charge: $format" }
        }
        
        return $viewData
    }
    catch {
        Write-Error "Erreur lors de l'import de la vue depuis le fichier - $($_.Exception.Message)"
        
        # Mettre le fichier en quarantaine en cas d'erreur
        $quarantinePath = $importManager.QuarantineFile($FilePath, $_.Exception.Message)
        Write-Warning "Le fichier a été mis en quarantaine: $quarantinePath"
        
        return $null
    }
}

# Fonction pour importer une vue depuis une URL
function Import-ViewFromURL {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$URL,
        
        [Parameter(Mandatory = $false)]
        [string]$ImportStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ImportStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $importManager = New-ImportManager -ImportStorePath $ImportStorePath -EnableDebug:$EnableDebug
    
    try {
        # Importer la vue depuis l'URL
        $viewData = $importManager.ImportFromURL($URL)
        return $viewData
    }
    catch {
        Write-Error "Erreur lors de l'import de la vue depuis l'URL - $($_.Exception.Message)"
        return $null
    }
}

# Exporter les fonctions
# Export-ModuleMember -Function New-ImportManager, Import-ViewFromFile, Import-ViewFromURL
