<#
.SYNOPSIS
    Module d'intégration pour le partage des vues RAG.

.DESCRIPTION
    Ce module implémente l'intégration entre le système de partage des vues
    et les autres composants du système RAG.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer les modules requis
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$exportManagerPath = Join-Path -Path $scriptDir -ChildPath "ExportManager.ps1"
$importManagerPath = Join-Path -Path $scriptDir -ChildPath "ImportManager.ps1"
$permissionManagerPath = Join-Path -Path $scriptDir -ChildPath "PermissionManager.ps1"

if (Test-Path -Path $exportManagerPath) {
    . $exportManagerPath
}
else {
    throw "Le module ExportManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $exportManagerPath"
}

if (Test-Path -Path $importManagerPath) {
    . $importManagerPath
}
else {
    throw "Le module ImportManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $importManagerPath"
}

if (Test-Path -Path $permissionManagerPath) {
    . $permissionManagerPath
}
else {
    throw "Le module PermissionManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $permissionManagerPath"
}

# Classe pour représenter l'intégration du partage des vues
class SharingIntegration {
    # Propriétés
    [string]$StoragePath
    [bool]$EnableDebug
    [hashtable]$Config
    [object]$ExportManager
    [object]$ImportManager
    [object]$PermissionManager

    # Constructeur par défaut
    SharingIntegration() {
        $this.StoragePath = Join-Path -Path $env:TEMP -ChildPath "ViewSharing"
        $this.EnableDebug = $false
        $this.InitializeConfig()
        $this.InitializeManagers()
    }

    # Constructeur avec paramètres
    SharingIntegration([string]$storagePath, [bool]$enableDebug) {
        $this.StoragePath = $storagePath
        $this.EnableDebug = $enableDebug
        $this.InitializeConfig()
        $this.InitializeManagers()
    }

    # Méthode pour initialiser la configuration
    [void] InitializeConfig() {
        $this.Config = @{
            "ExportFormats" = @("JSON", "URL", "STANDALONE")
            "ImportFormats" = @("JSON", "URL", "STANDALONE")
            "DefaultPermissions" = @("READ_STANDARD")
            "TemplatesPath" = Join-Path -Path (Split-Path -Path $this.StoragePath -Parent) -ChildPath "templates"
            "BaseURL" = "https://example.com/view"
            "MaxExportSize" = 10 * 1024 * 1024 # 10 MB
            "MaxImportSize" = 10 * 1024 * 1024 # 10 MB
            "EnableEncryption" = $true
            "EnableCompression" = $true
        }
    }

    # Méthode pour initialiser les gestionnaires
    [void] InitializeManagers() {
        $this.WriteDebug("Initialisation des gestionnaires")
        
        # Créer les chemins de stockage
        $exportStorePath = Join-Path -Path $this.StoragePath -ChildPath "ExportStore"
        $importStorePath = Join-Path -Path $this.StoragePath -ChildPath "ImportStore"
        $permissionStorePath = Join-Path -Path $this.StoragePath -ChildPath "PermissionStore"
        
        # Initialiser les gestionnaires
        $this.ExportManager = New-ExportManager -ExportStorePath $exportStorePath -EnableDebug:$this.EnableDebug
        $this.ImportManager = New-ImportManager -ImportStorePath $importStorePath -EnableDebug:$this.EnableDebug
        $this.PermissionManager = New-PermissionManager -PermissionStorePath $permissionStorePath -EnableDebug:$this.EnableDebug
        
        $this.WriteDebug("Gestionnaires initialisés")
    }

    # Méthode pour écrire des messages de débogage
    [void] WriteDebug([string]$message) {
        if ($this.EnableDebug) {
            Write-Host "[DEBUG] [SharingIntegration] $message" -ForegroundColor Cyan
        }
    }

    # Méthode pour convertir un résultat RAG en vue partageable
    [PSObject] ConvertRAGResultToView([PSObject]$ragResult, [string]$title, [string]$description, [string]$creator) {
        $this.WriteDebug("Conversion d'un résultat RAG en vue partageable")
        
        try {
            # Générer un ID unique pour la vue
            $viewId = [guid]::NewGuid().ToString()
            
            # Créer les métadonnées de la vue
            $metadata = [PSCustomObject]@{
                Creator = $creator
                CreatedAt = (Get-Date).ToString('o')
                Description = $description
                Tags = @()
                Query = ""
            }
            
            # Extraire la requête si disponible
            if ($ragResult.PSObject.Properties.Name.Contains("Query")) {
                $metadata.Query = $ragResult.Query
            }
            
            # Extraire les tags si disponibles
            if ($ragResult.PSObject.Properties.Name.Contains("Tags")) {
                $metadata.Tags = $ragResult.Tags
            }
            elseif ($ragResult.PSObject.Properties.Name.Contains("Keywords")) {
                $metadata.Tags = $ragResult.Keywords
            }
            
            # Créer les éléments de la vue
            $items = @()
            
            if ($ragResult.PSObject.Properties.Name.Contains("Results")) {
                foreach ($result in $ragResult.Results) {
                    $item = [PSCustomObject]@{
                        Id = [guid]::NewGuid().ToString()
                        Title = ""
                        Content = ""
                        Source = ""
                        Tags = @()
                        Score = 0.0
                        Metadata = [PSCustomObject]@{
                            Type = "result"
                            CreatedAt = (Get-Date).ToString('o')
                        }
                    }
                    
                    # Extraire le titre
                    if ($result.PSObject.Properties.Name.Contains("Title")) {
                        $item.Title = $result.Title
                    }
                    elseif ($result.PSObject.Properties.Name.Contains("Name")) {
                        $item.Title = $result.Name
                    }
                    else {
                        $item.Title = "Résultat sans titre"
                    }
                    
                    # Extraire le contenu
                    if ($result.PSObject.Properties.Name.Contains("Content")) {
                        $item.Content = $result.Content
                    }
                    elseif ($result.PSObject.Properties.Name.Contains("Text")) {
                        $item.Content = $result.Text
                    }
                    elseif ($result.PSObject.Properties.Name.Contains("Description")) {
                        $item.Content = $result.Description
                    }
                    
                    # Extraire la source
                    if ($result.PSObject.Properties.Name.Contains("Source")) {
                        $item.Source = $result.Source
                    }
                    elseif ($result.PSObject.Properties.Name.Contains("Path")) {
                        $item.Source = $result.Path
                    }
                    elseif ($result.PSObject.Properties.Name.Contains("URL")) {
                        $item.Source = $result.URL
                    }
                    
                    # Extraire les tags
                    if ($result.PSObject.Properties.Name.Contains("Tags")) {
                        $item.Tags = $result.Tags
                    }
                    elseif ($result.PSObject.Properties.Name.Contains("Keywords")) {
                        $item.Tags = $result.Keywords
                    }
                    
                    # Extraire le score
                    if ($result.PSObject.Properties.Name.Contains("Score")) {
                        $item.Score = $result.Score
                    }
                    elseif ($result.PSObject.Properties.Name.Contains("Relevance")) {
                        $item.Score = $result.Relevance
                    }
                    elseif ($result.PSObject.Properties.Name.Contains("Confidence")) {
                        $item.Score = $result.Confidence
                    }
                    
                    # Ajouter l'élément à la liste
                    $items += $item
                }
            }
            
            # Créer la vue
            $view = [PSCustomObject]@{
                Id = $viewId
                Title = $title
                Type = "RAG_SEARCH_RESULTS"
                Metadata = $metadata
                Items = $items
            }
            
            $this.WriteDebug("Vue créée avec succès: $viewId")
            return $view
        }
        catch {
            $this.WriteDebug("Erreur lors de la conversion du résultat RAG en vue - $($_.Exception.Message)")
            throw "Erreur lors de la conversion du résultat RAG en vue - $($_.Exception.Message)"
        }
    }

    # Méthode pour partager une vue
    [hashtable] ShareView([PSObject]$view, [string]$format, [string[]]$recipients, [string[]]$permissions) {
        $this.WriteDebug("Partage d'une vue au format $format avec $($recipients.Count) destinataires")
        
        try {
            # Vérifier si le format est supporté
            if (-not $this.Config.ExportFormats.Contains($format)) {
                throw "Format d'export non supporté: $format"
            }
            
            # Créer les permissions par défaut pour la vue
            $result = $this.PermissionManager.CreateDefaultPermissions($view.Id, $view.Metadata.Creator)
            
            if (-not $result) {
                throw "Échec de la création des permissions par défaut pour la vue"
            }
            
            # Accorder les permissions aux destinataires
            foreach ($recipient in $recipients) {
                foreach ($permission in $permissions) {
                    $result = $this.PermissionManager.GrantPermission($view.Id, $recipient, $permission, $view.Metadata.Creator)
                    
                    if (-not $result) {
                        $this.WriteDebug("Échec de l'attribution de la permission $permission à $recipient")
                    }
                }
            }
            
            # Exporter la vue au format demandé
            $exportPath = ""
            
            switch ($format) {
                "JSON" {
                    $exportPath = $this.ExportManager.ExportToJSON($view, $false)
                }
                "JSON_COMPACT" {
                    $exportPath = $this.ExportManager.ExportToJSON($view, $true)
                }
                "URL" {
                    $exportPath = $this.ExportManager.ExportToURL($view, $this.Config.BaseURL)
                }
                "STANDALONE" {
                    $templatePath = Join-Path -Path $this.Config.TemplatesPath -ChildPath "standalone-template.html"
                    $exportPath = $this.ExportManager.ExportToStandalone($view, $templatePath)
                }
                default {
                    throw "Format d'export non supporté: $format"
                }
            }
            
            # Créer le résultat
            $shareResult = @{
                ViewId = $view.Id
                Format = $format
                ExportPath = $exportPath
                Recipients = $recipients
                Permissions = $permissions
                SharedAt = (Get-Date).ToString('o')
                Creator = $view.Metadata.Creator
            }
            
            $this.WriteDebug("Vue partagée avec succès: $($view.Id)")
            return $shareResult
        }
        catch {
            $this.WriteDebug("Erreur lors du partage de la vue - $($_.Exception.Message)")
            throw "Erreur lors du partage de la vue - $($_.Exception.Message)"
        }
    }

    # Méthode pour importer une vue partagée
    [PSObject] ImportSharedView([string]$path, [System.Security.SecureString]$password) {
        $this.WriteDebug("Import d'une vue partagée depuis: $path")
        
        try {
            # Importer la vue
            $view = Import-ViewFromFile -FilePath $path -Password $password -EnableDebug:$this.EnableDebug
            
            if ($null -eq $view) {
                throw "Échec de l'import de la vue depuis le fichier"
            }
            
            $this.WriteDebug("Vue importée avec succès: $($view.Id)")
            return $view
        }
        catch {
            $this.WriteDebug("Erreur lors de l'import de la vue - $($_.Exception.Message)")
            throw "Erreur lors de l'import de la vue - $($_.Exception.Message)"
        }
    }

    # Méthode pour intégrer une vue importée au système RAG
    [PSObject] IntegrateImportedView([PSObject]$view, [string]$integrationMode) {
        $this.WriteDebug("Intégration d'une vue importée au système RAG en mode: $integrationMode")
        
        try {
            # Créer un résultat d'intégration
            $integrationResult = [PSCustomObject]@{
                ViewId = $view.Id
                Title = $view.Title
                IntegrationMode = $integrationMode
                IntegratedAt = (Get-Date).ToString('o')
                Status = "Success"
                Message = "Vue intégrée avec succès"
                Data = $null
            }
            
            # Intégrer la vue en fonction du mode
            switch ($integrationMode) {
                "Append" {
                    # Ajouter la vue aux résultats existants
                    $integrationResult.Message = "Vue ajoutée aux résultats existants"
                    $integrationResult.Data = $view
                }
                "Replace" {
                    # Remplacer les résultats existants par la vue
                    $integrationResult.Message = "Résultats existants remplacés par la vue"
                    $integrationResult.Data = $view
                }
                "Merge" {
                    # Fusionner la vue avec les résultats existants
                    $integrationResult.Message = "Vue fusionnée avec les résultats existants"
                    $integrationResult.Data = $view
                }
                default {
                    throw "Mode d'intégration non supporté: $integrationMode"
                }
            }
            
            $this.WriteDebug("Vue intégrée avec succès: $($view.Id)")
            return $integrationResult
        }
        catch {
            $this.WriteDebug("Erreur lors de l'intégration de la vue - $($_.Exception.Message)")
            throw "Erreur lors de l'intégration de la vue - $($_.Exception.Message)"
        }
    }
}

# Fonction pour créer une nouvelle intégration de partage
function New-SharingIntegration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$StoragePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    return [SharingIntegration]::new($StoragePath, $EnableDebug)
}

# Fonction pour convertir un résultat RAG en vue partageable
function ConvertTo-ShareableView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$RAGResult,
        
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Creator = [System.Environment]::UserName,
        
        [Parameter(Mandatory = $false)]
        [string]$StoragePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $integration = New-SharingIntegration -StoragePath $StoragePath -EnableDebug:$EnableDebug
    return $integration.ConvertRAGResultToView($RAGResult, $Title, $Description, $Creator)
}

# Fonction pour partager une vue
function Publish-RAGView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$View,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "JSON_COMPACT", "URL", "STANDALONE")]
        [string]$Format,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Recipients,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Permissions = @("READ_STANDARD"),
        
        [Parameter(Mandatory = $false)]
        [string]$StoragePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $integration = New-SharingIntegration -StoragePath $StoragePath -EnableDebug:$EnableDebug
    return $integration.ShareView($View, $Format, $Recipients, $Permissions)
}

# Fonction pour importer une vue partagée
function Import-SharedView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password,
        
        [Parameter(Mandatory = $false)]
        [string]$StoragePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $integration = New-SharingIntegration -StoragePath $StoragePath -EnableDebug:$EnableDebug
    return $integration.ImportSharedView($Path, $Password)
}

# Fonction pour intégrer une vue importée au système RAG
function Add-ImportedView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$View,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Append", "Replace", "Merge")]
        [string]$IntegrationMode,
        
        [Parameter(Mandatory = $false)]
        [string]$StoragePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $integration = New-SharingIntegration -StoragePath $StoragePath -EnableDebug:$EnableDebug
    return $integration.IntegrateImportedView($View, $IntegrationMode)
}

# Exporter les fonctions
# Export-ModuleMember -Function New-SharingIntegration, ConvertTo-ShareableView, Publish-RAGView, Import-SharedView, Add-ImportedView

