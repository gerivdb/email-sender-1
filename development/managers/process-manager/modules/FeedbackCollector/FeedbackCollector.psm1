<#
.SYNOPSIS
    Module de collecte et d'agrÃ©gation des messages de feedback pour le Process Manager.

.DESCRIPTION
    Ce module fournit des fonctions pour collecter, stocker et analyser les messages
    de feedback gÃ©nÃ©rÃ©s par le Process Manager et ses gestionnaires.

.NOTES
    Version: 1.0.0
    Auteur: Process Manager Team
    Date de crÃ©ation: 2025-05-15
#>

# Importer les dÃ©pendances
if (-not (Get-Module -Name "FeedbackManager")) {
    $feedbackManagerPath = Join-Path -Path $PSScriptRoot -Parent -ChildPath "FeedbackManager\FeedbackManager.psm1"
    if (Test-Path -Path $feedbackManagerPath) {
        Import-Module $feedbackManagerPath -Force
    }
}

# Variables globales du module
$script:DefaultConfigPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent -Parent -Parent -Parent) -ChildPath "projet\config\managers\process-manager\feedback-collector.config.json"
$script:MessageCollection = @()
$script:MaxCollectionSize = 10000
$script:DefaultStoragePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent -Parent -Parent -Parent) -ChildPath "projet\data\feedback"
$script:RotationEnabled = $true
$script:RotationInterval = 86400 # 24 heures en secondes
$script:LastRotationTime = Get-Date
$script:PersistenceEnabled = $true
$script:ImportantMessageTags = @("Critical", "Security", "Performance", "Error")

# Structure de donnÃ©es pour la collection de messages
class MessageCollection {
    [System.Collections.ArrayList]$Messages
    [int]$MaxSize
    [string]$Name
    [datetime]$CreationTime
    [datetime]$LastUpdateTime
    [hashtable]$Statistics
    
    # Constructeur par dÃ©faut
    MessageCollection() {
        $this.Messages = [System.Collections.ArrayList]::new()
        $this.MaxSize = 10000
        $this.Name = "DefaultCollection"
        $this.CreationTime = Get-Date
        $this.LastUpdateTime = $this.CreationTime
        $this.Statistics = @{
            TotalMessages = 0
            ErrorCount = 0
            WarningCount = 0
            InfoCount = 0
            SuccessCount = 0
            DebugCount = 0
            VerboseCount = 0
            AverageMessageSize = 0
            OldestMessageTime = $null
            NewestMessageTime = $null
        }
    }
    
    # Constructeur avec paramÃ¨tres
    MessageCollection([string]$Name, [int]$MaxSize) {
        $this.Messages = [System.Collections.ArrayList]::new()
        $this.MaxSize = $MaxSize
        $this.Name = $Name
        $this.CreationTime = Get-Date
        $this.LastUpdateTime = $this.CreationTime
        $this.Statistics = @{
            TotalMessages = 0
            ErrorCount = 0
            WarningCount = 0
            InfoCount = 0
            SuccessCount = 0
            DebugCount = 0
            VerboseCount = 0
            AverageMessageSize = 0
            OldestMessageTime = $null
            NewestMessageTime = $null
        }
    }
    
    # MÃ©thode pour ajouter un message Ã  la collection
    [void] AddMessage([FeedbackMessage]$Message) {
        # Ajouter le message Ã  la collection
        $this.Messages.Add($Message)
        
        # Mettre Ã  jour les statistiques
        $this.Statistics.TotalMessages++
        
        switch ($Message.Type) {
            "Error" { $this.Statistics.ErrorCount++ }
            "Warning" { $this.Statistics.WarningCount++ }
            "Information" { $this.Statistics.InfoCount++ }
            "Success" { $this.Statistics.SuccessCount++ }
            "Debug" { $this.Statistics.DebugCount++ }
            "Verbose" { $this.Statistics.VerboseCount++ }
        }
        
        # Mettre Ã  jour les horodatages
        if ($this.Statistics.OldestMessageTime -eq $null -or $Message.Timestamp -lt $this.Statistics.OldestMessageTime) {
            $this.Statistics.OldestMessageTime = $Message.Timestamp
        }
        
        if ($this.Statistics.NewestMessageTime -eq $null -or $Message.Timestamp -gt $this.Statistics.NewestMessageTime) {
            $this.Statistics.NewestMessageTime = $Message.Timestamp
        }
        
        # Calculer la taille moyenne des messages
        $this.Statistics.AverageMessageSize = ($this.Statistics.AverageMessageSize * ($this.Statistics.TotalMessages - 1) + $Message.Message.Length) / $this.Statistics.TotalMessages
        
        # Mettre Ã  jour l'horodatage de derniÃ¨re mise Ã  jour
        $this.LastUpdateTime = Get-Date
        
        # VÃ©rifier si la collection a dÃ©passÃ© sa taille maximale
        if ($this.Messages.Count -gt $this.MaxSize) {
            $this.Messages.RemoveAt(0)
        }
    }
    
    # MÃ©thode pour obtenir les messages filtrÃ©s
    [System.Collections.ArrayList] GetFilteredMessages([FeedbackFilter]$Filter) {
        $filteredMessages = [System.Collections.ArrayList]::new()
        
        foreach ($message in $this.Messages) {
            if ($Filter.PassesFilter($message)) {
                $filteredMessages.Add($message)
            }
        }
        
        return $filteredMessages
    }
    
    # MÃ©thode pour obtenir les statistiques de la collection
    [hashtable] GetStatistics() {
        return $this.Statistics
    }
    
    # MÃ©thode pour vider la collection
    [void] Clear() {
        $this.Messages.Clear()
        $this.Statistics = @{
            TotalMessages = 0
            ErrorCount = 0
            WarningCount = 0
            InfoCount = 0
            SuccessCount = 0
            DebugCount = 0
            VerboseCount = 0
            AverageMessageSize = 0
            OldestMessageTime = $null
            NewestMessageTime = $null
        }
        $this.LastUpdateTime = Get-Date
    }
    
    # MÃ©thode pour exporter la collection au format JSON
    [string] ExportToJson() {
        return ConvertTo-Json -InputObject $this -Depth 10
    }
    
    # MÃ©thode pour exporter la collection au format CSV
    [string] ExportToCsv() {
        $csv = "Timestamp,Type,Source,Severity,Message`n"
        
        foreach ($message in $this.Messages) {
            $timestamp = $message.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
            $type = $message.Type
            $source = $message.Source
            $severity = $message.Severity
            $messageText = $message.Message -replace ",", ";" -replace "`n", " " -replace "`r", " "
            
            $csv += "$timestamp,$type,$source,$severity,`"$messageText`"`n"
        }
        
        return $csv
    }
    
    # MÃ©thode pour importer une collection depuis un fichier JSON
    static [MessageCollection] ImportFromJson([string]$JsonContent) {
        $importedCollection = ConvertFrom-Json -InputObject $JsonContent
        
        $collection = [MessageCollection]::new($importedCollection.Name, $importedCollection.MaxSize)
        $collection.CreationTime = [datetime]$importedCollection.CreationTime
        $collection.LastUpdateTime = [datetime]$importedCollection.LastUpdateTime
        $collection.Statistics = $importedCollection.Statistics
        
        foreach ($messageData in $importedCollection.Messages) {
            $message = [FeedbackMessage]::new(
                [FeedbackType]$messageData.Type,
                $messageData.Message,
                $messageData.Source,
                $messageData.Severity,
                $messageData.Data,
                [VerbosityLevel]$messageData.MinimumVerbosity
            )
            
            $message.Timestamp = [datetime]$messageData.Timestamp
            $message.CorrelationId = $messageData.CorrelationId
            
            $collection.Messages.Add($message)
        }
        
        return $collection
    }
}

# Fonction de journalisation
function Write-CollectorLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Debug", "Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    # DÃ©terminer la couleur en fonction du niveau
    $color = switch ($Level) {
        "Debug" { "Gray" }
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        default { "White" }
    }
    
    # Ã‰crire le message dans la console
    Write-Host "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] [FeedbackCollector] [$Level] $Message" -ForegroundColor $color
}

# Initialiser la collection de messages
$script:MessageCollection = [MessageCollection]::new("MainCollection", $script:MaxCollectionSize)

# Fonction pour initialiser le collecteur de feedback
function Initialize-FeedbackCollector {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath,
        
        [Parameter(Mandatory = $false)]
        [string]$StoragePath = $script:DefaultStoragePath,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxCollectionSize = 10000,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableRotation = $true,
        
        [Parameter(Mandatory = $false)]
        [int]$RotationInterval = 86400,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnablePersistence = $true
    )
    
    try {
        # VÃ©rifier si le rÃ©pertoire de stockage existe
        if (-not (Test-Path -Path $StoragePath -PathType Container)) {
            New-Item -Path $StoragePath -ItemType Directory -Force | Out-Null
            Write-CollectorLog -Message "RÃ©pertoire de stockage crÃ©Ã© : $StoragePath" -Level Info
        }
        
        # Charger la configuration si elle existe
        if (Test-Path -Path $ConfigPath -PathType Leaf) {
            $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            
            if ($config.MaxCollectionSize) {
                $MaxCollectionSize = $config.MaxCollectionSize
            }
            
            if ($config.RotationEnabled -ne $null) {
                $EnableRotation = $config.RotationEnabled
            }
            
            if ($config.RotationInterval) {
                $RotationInterval = $config.RotationInterval
            }
            
            if ($config.PersistenceEnabled -ne $null) {
                $EnablePersistence = $config.PersistenceEnabled
            }
            
            if ($config.ImportantMessageTags) {
                $script:ImportantMessageTags = $config.ImportantMessageTags
            }
            
            Write-CollectorLog -Message "Configuration chargÃ©e depuis $ConfigPath" -Level Info
        }
        else {
            # CrÃ©er la configuration par dÃ©faut
            $config = @{
                MaxCollectionSize = $MaxCollectionSize
                RotationEnabled = $EnableRotation
                RotationInterval = $RotationInterval
                PersistenceEnabled = $EnablePersistence
                ImportantMessageTags = $script:ImportantMessageTags
                StoragePath = $StoragePath
            }
            
            # CrÃ©er le rÃ©pertoire parent si nÃ©cessaire
            $configDir = Split-Path -Path $ConfigPath -Parent
            if (-not (Test-Path -Path $configDir -PathType Container)) {
                New-Item -Path $configDir -ItemType Directory -Force | Out-Null
            }
            
            # Enregistrer la configuration
            $config | ConvertTo-Json -Depth 5 | Out-File -FilePath $ConfigPath -Encoding utf8
            Write-CollectorLog -Message "Configuration par dÃ©faut crÃ©Ã©e : $ConfigPath" -Level Info
        }
        
        # Mettre Ã  jour les variables globales
        $script:MaxCollectionSize = $MaxCollectionSize
        $script:DefaultStoragePath = $StoragePath
        $script:RotationEnabled = $EnableRotation
        $script:RotationInterval = $RotationInterval
        $script:PersistenceEnabled = $EnablePersistence
        
        # Initialiser la collection de messages
        $script:MessageCollection = [MessageCollection]::new("MainCollection", $script:MaxCollectionSize)
        
        # Enregistrer le gestionnaire d'Ã©vÃ©nements pour collecter les messages
        if (Get-Module -Name "FeedbackManager") {
            # CrÃ©er une fonction de rappel pour collecter les messages
            $collectMessageCallback = {
                param($Message)
                
                # Ajouter le message Ã  la collection
                Add-MessageToCollection -Message $Message
            }
            
            # S'abonner aux notifications de feedback
            $subscription = Subscribe-ProcessManagerNotifications -EventTypes @("FeedbackMessage") -Callback $collectMessageCallback
            
            if ($subscription) {
                Write-CollectorLog -Message "Abonnement aux notifications de feedback crÃ©Ã©" -Level Success
            }
            else {
                Write-CollectorLog -Message "Impossible de s'abonner aux notifications de feedback" -Level Warning
            }
        }
        
        Write-CollectorLog -Message "Collecteur de feedback initialisÃ©" -Level Success
        return $true
    }
    catch {
        Write-CollectorLog -Message "Erreur lors de l'initialisation du collecteur de feedback : $_" -Level Error
        return $false
    }
}

# Fonction pour ajouter un message Ã  la collection
function Add-MessageToCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [FeedbackMessage]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$CollectionName = "MainCollection"
    )
    
    try {
        # VÃ©rifier si la rotation est nÃ©cessaire
        if ($script:RotationEnabled) {
            $currentTime = Get-Date
            $timeSinceLastRotation = ($currentTime - $script:LastRotationTime).TotalSeconds
            
            if ($timeSinceLastRotation -ge $script:RotationInterval) {
                # Effectuer la rotation
                Invoke-CollectionRotation
                $script:LastRotationTime = $currentTime
            }
        }
        
        # Ajouter le message Ã  la collection
        $script:MessageCollection.AddMessage($Message)
        
        # VÃ©rifier si le message doit Ãªtre persistÃ©
        if ($script:PersistenceEnabled) {
            # VÃ©rifier si le message est important
            $isImportant = $false
            
            # VÃ©rifier le type de message
            if ($Message.Type -eq [FeedbackType]::Error -or $Message.Severity -le 2) {
                $isImportant = $true
            }
            
            # VÃ©rifier les tags dans les donnÃ©es
            if ($Message.Data -and $Message.Data.Tags) {
                foreach ($tag in $Message.Data.Tags) {
                    if ($script:ImportantMessageTags -contains $tag) {
                        $isImportant = $true
                        break
                    }
                }
            }
            
            # Persister le message si important
            if ($isImportant) {
                Save-ImportantMessage -Message $Message
            }
        }
        
        return $true
    }
    catch {
        Write-CollectorLog -Message "Erreur lors de l'ajout du message Ã  la collection : $_" -Level Error
        return $false
    }
}

# Fonction pour effectuer la rotation de la collection
function Invoke-CollectionRotation {
    [CmdletBinding()]
    param ()
    
    try {
        # VÃ©rifier si la collection contient des messages
        if ($script:MessageCollection.Messages.Count -eq 0) {
            Write-CollectorLog -Message "Aucun message Ã  archiver lors de la rotation" -Level Info
            return $true
        }
        
        # CrÃ©er le nom de fichier pour l'archive
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $archiveFileName = "feedback_archive_$timestamp.json"
        $archivePath = Join-Path -Path $script:DefaultStoragePath -ChildPath $archiveFileName
        
        # Exporter la collection au format JSON
        $jsonContent = $script:MessageCollection.ExportToJson()
        $jsonContent | Out-File -FilePath $archivePath -Encoding utf8
        
        # Vider la collection
        $script:MessageCollection.Clear()
        
        Write-CollectorLog -Message "Rotation de la collection effectuÃ©e, archive crÃ©Ã©e : $archivePath" -Level Success
        return $true
    }
    catch {
        Write-CollectorLog -Message "Erreur lors de la rotation de la collection : $_" -Level Error
        return $false
    }
}

# Fonction pour sauvegarder un message important
function Save-ImportantMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [FeedbackMessage]$Message
    )
    
    try {
        # CrÃ©er le rÃ©pertoire pour les messages importants
        $importantMessagesDir = Join-Path -Path $script:DefaultStoragePath -ChildPath "important"
        
        if (-not (Test-Path -Path $importantMessagesDir -PathType Container)) {
            New-Item -Path $importantMessagesDir -ItemType Directory -Force | Out-Null
        }
        
        # CrÃ©er le nom de fichier pour le message
        $timestamp = $Message.Timestamp.ToString("yyyyMMdd_HHmmss")
        $messageType = $Message.Type.ToString().ToLower()
        $messageId = $Message.CorrelationId.Substring(0, 8)
        $fileName = "important_${messageType}_${timestamp}_${messageId}.json"
        $filePath = Join-Path -Path $importantMessagesDir -ChildPath $fileName
        
        # Exporter le message au format JSON
        $jsonContent = $Message | ConvertTo-Json -Depth 5
        $jsonContent | Out-File -FilePath $filePath -Encoding utf8
        
        Write-CollectorLog -Message "Message important sauvegardÃ© : $filePath" -Level Info
        return $true
    }
    catch {
        Write-CollectorLog -Message "Erreur lors de la sauvegarde du message important : $_" -Level Error
        return $false
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-FeedbackCollector, Add-MessageToCollection, Invoke-CollectionRotation
