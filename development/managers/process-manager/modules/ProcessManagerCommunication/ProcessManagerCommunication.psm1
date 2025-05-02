<#
.SYNOPSIS
    Module de communication avec le Process Manager.

.DESCRIPTION
    Ce module fournit des fonctions pour communiquer avec le Process Manager
    et ses gestionnaires enregistrés.

.NOTES
    Version: 1.0.0
    Auteur: Process Manager Team
    Date de création: 2025-05-15
#>

# Variables globales du module
$script:DefaultConfigPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent -Parent -Parent -Parent) -ChildPath "projet\config\managers\process-manager\process-manager.config.json"
$script:DefaultPipeName = "ProcessManagerPipe"
$script:DefaultEventName = "ProcessManagerEvent"

# Fonction de journalisation
function Write-CommunicationLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Debug", "Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    # Déterminer la couleur en fonction du niveau
    $color = switch ($Level) {
        "Debug" { "Gray" }
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        default { "White" }
    }
    
    # Écrire le message dans la console
    Write-Host "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] [ProcessManagerCommunication] [$Level] $Message" -ForegroundColor $color
}

<#
.SYNOPSIS
    Initialise la communication avec le Process Manager.

.DESCRIPTION
    Cette fonction initialise la communication avec le Process Manager
    en créant les canaux de communication nécessaires.

.PARAMETER Protocol
    Le protocole de communication à utiliser (NamedPipe, FileSystem, Socket).

.PARAMETER Name
    Le nom du canal de communication.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration du Process Manager.

.EXAMPLE
    Initialize-ProcessManagerCommunication -Protocol "NamedPipe"
    Initialise la communication avec le Process Manager via un pipe nommé.
#>
function Initialize-ProcessManagerCommunication {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("NamedPipe", "FileSystem", "Socket")]
        [string]$Protocol = "NamedPipe",
        
        [Parameter(Mandatory = $false)]
        [string]$Name = $script:DefaultPipeName,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath
    )
    
    try {
        # Vérifier si le module InterProcessCommunication est disponible
        if (-not (Get-Module -ListAvailable -Name "InterProcessCommunication")) {
            # Essayer de charger le script directement
            $ipcScriptPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent -Parent -Parent -Parent) -ChildPath "development\scripts\email\InterProcessCommunication.ps1"
            
            if (Test-Path -Path $ipcScriptPath -PathType Leaf) {
                . $ipcScriptPath
                Write-CommunicationLog -Message "Script InterProcessCommunication chargé depuis $ipcScriptPath" -Level Info
            }
            else {
                Write-CommunicationLog -Message "Le module InterProcessCommunication n'est pas disponible." -Level Error
                return $false
            }
        }
        else {
            Import-Module -Name "InterProcessCommunication" -ErrorAction Stop
            Write-CommunicationLog -Message "Module InterProcessCommunication importé" -Level Info
        }
        
        # Initialiser la communication selon le protocole
        switch ($Protocol) {
            "NamedPipe" {
                $connection = Connect-IPCClient -Protocol "NamedPipe" -Name $Name
                
                if (-not $connection) {
                    # Le serveur n'est pas en cours d'exécution, essayer de le démarrer
                    $processManagerPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent -Parent) -ChildPath "scripts\process-manager.ps1"
                    
                    if (Test-Path -Path $processManagerPath -PathType Leaf) {
                        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$processManagerPath`" -StartServer -Protocol NamedPipe -Name $Name" -WindowStyle Hidden
                        
                        # Attendre que le serveur démarre
                        Start-Sleep -Seconds 2
                        
                        # Essayer de se connecter à nouveau
                        $connection = Connect-IPCClient -Protocol "NamedPipe" -Name $Name
                    }
                }
                
                if ($connection) {
                    Write-CommunicationLog -Message "Communication initialisée via pipe nommé : $Name" -Level Success
                    return $connection
                }
                else {
                    Write-CommunicationLog -Message "Impossible d'initialiser la communication via pipe nommé : $Name" -Level Error
                    return $false
                }
            }
            "FileSystem" {
                $communicationDir = Join-Path -Path (Split-Path -Path $ConfigPath -Parent) -ChildPath "communication"
                
                if (-not (Test-Path -Path $communicationDir -PathType Container)) {
                    New-Item -Path $communicationDir -ItemType Directory -Force | Out-Null
                }
                
                $connection = @{
                    Protocol = "FileSystem"
                    Directory = $communicationDir
                    RequestFile = Join-Path -Path $communicationDir -ChildPath "request.json"
                    ResponseFile = Join-Path -Path $communicationDir -ChildPath "response.json"
                    LockFile = Join-Path -Path $communicationDir -ChildPath "lock.txt"
                }
                
                Write-CommunicationLog -Message "Communication initialisée via système de fichiers : $communicationDir" -Level Success
                return $connection
            }
            "Socket" {
                $connection = Connect-IPCClient -Protocol "Socket" -Host "localhost" -Port 8765
                
                if ($connection) {
                    Write-CommunicationLog -Message "Communication initialisée via socket : localhost:8765" -Level Success
                    return $connection
                }
                else {
                    Write-CommunicationLog -Message "Impossible d'initialiser la communication via socket : localhost:8765" -Level Error
                    return $false
                }
            }
        }
    }
    catch {
        Write-CommunicationLog -Message "Erreur lors de l'initialisation de la communication : $_" -Level Error
        return $false
    }
}

<#
.SYNOPSIS
    Envoie une commande au Process Manager.

.DESCRIPTION
    Cette fonction envoie une commande au Process Manager via le canal de communication spécifié.

.PARAMETER Connection
    La connexion au Process Manager.

.PARAMETER Command
    La commande à envoyer.

.PARAMETER Parameters
    Les paramètres de la commande.

.PARAMETER Timeout
    Le délai d'attente en secondes pour la réponse.

.EXAMPLE
    $connection = Initialize-ProcessManagerCommunication
    Send-ProcessManagerCommand -Connection $connection -Command "List" -Parameters @{}
    Envoie la commande "List" au Process Manager.
#>
function Send-ProcessManagerCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Connection,
        
        [Parameter(Mandatory = $true)]
        [string]$Command,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},
        
        [Parameter(Mandatory = $false)]
        [int]$Timeout = 30
    )
    
    try {
        # Créer l'objet de commande
        $commandObject = @{
            Command = $Command
            Parameters = $Parameters
            Id = [guid]::NewGuid().ToString()
            Timestamp = (Get-Date).ToString("o")
        }
        
        # Convertir l'objet en JSON
        $commandJson = $commandObject | ConvertTo-Json -Depth 10
        
        # Envoyer la commande selon le protocole
        if ($Connection.Protocol -eq "FileSystem") {
            # Acquérir le verrou
            $lockAcquired = $false
            $startTime = Get-Date
            
            while (-not $lockAcquired -and ((Get-Date) - $startTime).TotalSeconds -lt $Timeout) {
                if (-not (Test-Path -Path $Connection.LockFile -PathType Leaf)) {
                    # Créer le fichier de verrou
                    "LOCKED" | Out-File -FilePath $Connection.LockFile -Encoding utf8
                    $lockAcquired = $true
                }
                else {
                    # Attendre et réessayer
                    Start-Sleep -Milliseconds 100
                }
            }
            
            if (-not $lockAcquired) {
                Write-CommunicationLog -Message "Impossible d'acquérir le verrou pour envoyer la commande." -Level Error
                return $null
            }
            
            # Écrire la commande dans le fichier de requête
            $commandJson | Out-File -FilePath $Connection.RequestFile -Encoding utf8
            
            # Créer un événement pour signaler la requête
            $event = New-IPCEvent -Name "ProcessManagerRequest" -Global
            Set-IPCEvent -Event $event.EventHandle
            
            # Attendre la réponse
            $responseReceived = $false
            $startTime = Get-Date
            
            while (-not $responseReceived -and ((Get-Date) - $startTime).TotalSeconds -lt $Timeout) {
                if (Test-Path -Path $Connection.ResponseFile -PathType Leaf) {
                    # Lire la réponse
                    $responseJson = Get-Content -Path $Connection.ResponseFile -Raw
                    
                    if ($responseJson) {
                        try {
                            $response = $responseJson | ConvertFrom-Json
                            
                            # Vérifier que la réponse correspond à la requête
                            if ($response.Id -eq $commandObject.Id) {
                                $responseReceived = $true
                                
                                # Supprimer le fichier de réponse
                                Remove-Item -Path $Connection.ResponseFile -Force
                            }
                        }
                        catch {
                            Write-CommunicationLog -Message "Erreur lors de la lecture de la réponse : $_" -Level Warning
                        }
                    }
                }
                
                if (-not $responseReceived) {
                    Start-Sleep -Milliseconds 100
                }
            }
            
            # Libérer le verrou
            if (Test-Path -Path $Connection.LockFile -PathType Leaf) {
                Remove-Item -Path $Connection.LockFile -Force
            }
            
            if ($responseReceived) {
                Write-CommunicationLog -Message "Réponse reçue pour la commande '$Command'." -Level Success
                return $response
            }
            else {
                Write-CommunicationLog -Message "Délai d'attente dépassé pour la commande '$Command'." -Level Warning
                return $null
            }
        }
        else {
            # Envoyer la commande via IPC
            Send-IPCMessage -Connection $Connection -Message $commandJson
            
            # Attendre la réponse
            $responseReceived = $false
            $startTime = Get-Date
            
            while (-not $responseReceived -and ((Get-Date) - $startTime).TotalSeconds -lt $Timeout) {
                $responseJson = Receive-IPCMessage -Connection $Connection -Timeout 1
                
                if ($responseJson) {
                    try {
                        $response = $responseJson | ConvertFrom-Json
                        
                        # Vérifier que la réponse correspond à la requête
                        if ($response.Id -eq $commandObject.Id) {
                            $responseReceived = $true
                        }
                    }
                    catch {
                        Write-CommunicationLog -Message "Erreur lors de la lecture de la réponse : $_" -Level Warning
                    }
                }
            }
            
            if ($responseReceived) {
                Write-CommunicationLog -Message "Réponse reçue pour la commande '$Command'." -Level Success
                return $response
            }
            else {
                Write-CommunicationLog -Message "Délai d'attente dépassé pour la commande '$Command'." -Level Warning
                return $null
            }
        }
    }
    catch {
        Write-CommunicationLog -Message "Erreur lors de l'envoi de la commande : $_" -Level Error
        return $null
    }
}

<#
.SYNOPSIS
    Ferme la communication avec le Process Manager.

.DESCRIPTION
    Cette fonction ferme la communication avec le Process Manager
    en libérant les ressources utilisées.

.PARAMETER Connection
    La connexion au Process Manager.

.EXAMPLE
    $connection = Initialize-ProcessManagerCommunication
    Close-ProcessManagerCommunication -Connection $connection
    Ferme la communication avec le Process Manager.
#>
function Close-ProcessManagerCommunication {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Connection
    )
    
    try {
        # Fermer la connexion selon le protocole
        if ($Connection.Protocol -eq "FileSystem") {
            # Rien à faire pour le protocole FileSystem
            Write-CommunicationLog -Message "Communication fermée (FileSystem)." -Level Info
            return $true
        }
        else {
            # Fermer la connexion IPC
            Close-IPCConnection -Connection $Connection
            Write-CommunicationLog -Message "Communication fermée." -Level Info
            return $true
        }
    }
    catch {
        Write-CommunicationLog -Message "Erreur lors de la fermeture de la communication : $_" -Level Error
        return $false
    }
}

<#
.SYNOPSIS
    Envoie une notification au Process Manager.

.DESCRIPTION
    Cette fonction envoie une notification au Process Manager
    pour l'informer d'un événement.

.PARAMETER EventType
    Le type d'événement.

.PARAMETER EventData
    Les données de l'événement.

.PARAMETER Async
    Indique si la notification doit être envoyée de manière asynchrone.

.EXAMPLE
    Send-ProcessManagerNotification -EventType "ManagerStarted" -EventData @{ Name = "ModeManager" }
    Envoie une notification au Process Manager pour l'informer du démarrage du gestionnaire de modes.
#>
function Send-ProcessManagerNotification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$EventType,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$EventData = @{},
        
        [Parameter(Mandatory = $false)]
        [switch]$Async
    )
    
    try {
        # Créer l'objet de notification
        $notification = @{
            EventType = $EventType
            EventData = $EventData
            Id = [guid]::NewGuid().ToString()
            Timestamp = (Get-Date).ToString("o")
        }
        
        # Convertir l'objet en JSON
        $notificationJson = $notification | ConvertTo-Json -Depth 10
        
        # Déterminer le chemin du fichier de notification
        $configPath = $script:DefaultConfigPath
        $notificationDir = Join-Path -Path (Split-Path -Path $configPath -Parent) -ChildPath "notifications"
        
        if (-not (Test-Path -Path $notificationDir -PathType Container)) {
            New-Item -Path $notificationDir -ItemType Directory -Force | Out-Null
        }
        
        $notificationFile = Join-Path -Path $notificationDir -ChildPath "notification_$($notification.Id).json"
        
        # Écrire la notification dans le fichier
        $notificationJson | Out-File -FilePath $notificationFile -Encoding utf8
        
        # Créer un événement pour signaler la notification
        $event = New-IPCEvent -Name $script:DefaultEventName -Global
        
        if ($event) {
            Set-IPCEvent -Event $event.EventHandle
            Write-CommunicationLog -Message "Notification envoyée : $EventType" -Level Success
            return $true
        }
        else {
            Write-CommunicationLog -Message "Impossible de créer l'événement pour la notification." -Level Warning
            return $false
        }
    }
    catch {
        Write-CommunicationLog -Message "Erreur lors de l'envoi de la notification : $_" -Level Error
        return $false
    }
}

<#
.SYNOPSIS
    S'abonne aux notifications du Process Manager.

.DESCRIPTION
    Cette fonction s'abonne aux notifications du Process Manager
    pour recevoir des événements.

.PARAMETER EventTypes
    Les types d'événements auxquels s'abonner.

.PARAMETER Callback
    La fonction de rappel à appeler lors de la réception d'une notification.

.EXAMPLE
    Subscribe-ProcessManagerNotifications -EventTypes @("ManagerStarted", "ManagerStopped") -Callback { param($notification) Write-Host $notification.EventType }
    S'abonne aux notifications de démarrage et d'arrêt des gestionnaires.
#>
function Subscribe-ProcessManagerNotifications {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$EventTypes = @(),
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$Callback
    )
    
    try {
        # Créer un objet d'abonnement
        $subscription = @{
            Id = [guid]::NewGuid().ToString()
            EventTypes = $EventTypes
            Callback = $Callback
            Active = $true
        }
        
        # Démarrer un job pour surveiller les notifications
        $job = Start-Job -ScriptBlock {
            param (
                [string]$SubscriptionId,
                [string[]]$EventTypes,
                [string]$NotificationDir,
                [string]$EventName
            )
            
            # Créer un événement pour attendre les notifications
            $event = New-Object System.Threading.EventWaitHandle($false, [System.Threading.EventResetMode]::AutoReset, $EventName)
            
            while ($true) {
                # Attendre une notification
                $event.WaitOne(1000) | Out-Null
                
                # Rechercher les fichiers de notification
                $notificationFiles = Get-ChildItem -Path $NotificationDir -Filter "notification_*.json" -File
                
                foreach ($file in $notificationFiles) {
                    try {
                        # Lire la notification
                        $notification = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                        
                        # Vérifier si le type d'événement correspond
                        if ($EventTypes.Count -eq 0 -or $EventTypes -contains $notification.EventType) {
                            # Écrire la notification dans le pipeline de sortie
                            $notification
                        }
                        
                        # Supprimer le fichier de notification
                        Remove-Item -Path $file.FullName -Force
                    }
                    catch {
                        # Ignorer les erreurs
                    }
                }
            }
        } -ArgumentList $subscription.Id, $EventTypes, (Join-Path -Path (Split-Path -Path $script:DefaultConfigPath -Parent) -ChildPath "notifications"), $script:DefaultEventName
        
        # Enregistrer le job et l'abonnement
        $subscription.Job = $job
        
        # Démarrer un job pour traiter les notifications
        $processingJob = Start-Job -ScriptBlock {
            param (
                [int]$JobId,
                [scriptblock]$Callback
            )
            
            # Recevoir les notifications du job de surveillance
            while ($true) {
                $notification = Receive-Job -Id $JobId -Wait -AutoRemoveJob:$false
                
                if ($notification) {
                    # Appeler la fonction de rappel
                    & $Callback $notification
                }
                
                # Attendre un peu
                Start-Sleep -Milliseconds 100
            }
        } -ArgumentList $job.Id, $Callback
        
        $subscription.ProcessingJob = $processingJob
        
        Write-CommunicationLog -Message "Abonnement aux notifications créé : $($subscription.Id)" -Level Success
        return $subscription
    }
    catch {
        Write-CommunicationLog -Message "Erreur lors de l'abonnement aux notifications : $_" -Level Error
        return $null
    }
}

<#
.SYNOPSIS
    Se désabonne des notifications du Process Manager.

.DESCRIPTION
    Cette fonction se désabonne des notifications du Process Manager.

.PARAMETER Subscription
    L'abonnement à annuler.

.EXAMPLE
    $subscription = Subscribe-ProcessManagerNotifications -EventTypes @("ManagerStarted") -Callback { ... }
    Unsubscribe-ProcessManagerNotifications -Subscription $subscription
    Se désabonne des notifications du Process Manager.
#>
function Unsubscribe-ProcessManagerNotifications {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Subscription
    )
    
    try {
        # Arrêter les jobs
        if ($Subscription.Job) {
            Stop-Job -Id $Subscription.Job.Id -ErrorAction SilentlyContinue
            Remove-Job -Id $Subscription.Job.Id -Force -ErrorAction SilentlyContinue
        }
        
        if ($Subscription.ProcessingJob) {
            Stop-Job -Id $Subscription.ProcessingJob.Id -ErrorAction SilentlyContinue
            Remove-Job -Id $Subscription.ProcessingJob.Id -Force -ErrorAction SilentlyContinue
        }
        
        # Marquer l'abonnement comme inactif
        $Subscription.Active = $false
        
        Write-CommunicationLog -Message "Désabonnement des notifications : $($Subscription.Id)" -Level Success
        return $true
    }
    catch {
        Write-CommunicationLog -Message "Erreur lors du désabonnement des notifications : $_" -Level Error
        return $false
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-ProcessManagerCommunication, Send-ProcessManagerCommand, Close-ProcessManagerCommunication
Export-ModuleMember -Function Send-ProcessManagerNotification, Subscribe-ProcessManagerNotifications, Unsubscribe-ProcessManagerNotifications
