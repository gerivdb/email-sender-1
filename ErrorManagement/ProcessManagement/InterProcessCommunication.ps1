<#
.SYNOPSIS
    Fournit des mécanismes de communication inter-processus pour PowerShell.

.DESCRIPTION
    Ce script implémente plusieurs méthodes de communication inter-processus (IPC)
    pour permettre aux scripts PowerShell de communiquer entre eux, notamment via
    des fichiers partagés, des pipes nommés, et des sockets.

.EXAMPLE
    . .\InterProcessCommunication.ps1
    $server = Start-IPCServer -Protocol "NamedPipe" -Name "MyPipe"
    $client = Connect-IPCClient -Protocol "NamedPipe" -Name "MyPipe"
    Send-IPCMessage -Connection $client -Message "Hello, world!"
    $message = Receive-IPCMessage -Connection $server

.NOTES
    Auteur: Système d'analyse d'erreurs
    Date de création: 07/04/2025
    Version: 1.0
#>

# Classe pour représenter une connexion IPC
class IPCConnection {
    [string]$Protocol
    [string]$Name
    [object]$Connection
    [bool]$IsServer
    [bool]$IsConnected
    [System.Collections.Generic.List[string]]$MessageLog
    
    IPCConnection() {
        $this.IsConnected = $false
        $this.MessageLog = [System.Collections.Generic.List[string]]::new()
    }
}

# Fonction pour démarrer un serveur IPC
function Start-IPCServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("NamedPipe", "Socket", "File")]
        [string]$Protocol,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [int]$Port = 0,
        
        [Parameter(Mandatory = $false)]
        [string]$FilePath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$Async
    )
    
    $ipcConnection = [IPCConnection]::new()
    $ipcConnection.Protocol = $Protocol
    $ipcConnection.Name = $Name
    $ipcConnection.IsServer = $true
    
    switch ($Protocol) {
        "NamedPipe" {
            try {
                $pipeName = if ($Name.StartsWith("\\.\pipe\")) { $Name } else { "\\.\pipe\$Name" }
                $pipeServer = New-Object System.IO.Pipes.NamedPipeServerStream($Name, [System.IO.Pipes.PipeDirection]::InOut)
                
                if (-not $Async) {
                    Write-Verbose "Attente de connexion sur le pipe nommé '$pipeName'..."
                    $pipeServer.WaitForConnection()
                    $ipcConnection.IsConnected = $true
                    Write-Verbose "Connexion établie sur le pipe nommé '$pipeName'."
                }
                else {
                    Write-Verbose "Démarrage du serveur de pipe nommé '$pipeName' en mode asynchrone..."
                    $asyncResult = $pipeServer.BeginWaitForConnection($null, $null)
                }
                
                $ipcConnection.Connection = $pipeServer
            }
            catch {
                Write-Error "Erreur lors du démarrage du serveur de pipe nommé: $_"
                return $null
            }
        }
        "Socket" {
            try {
                if ($Port -eq 0) {
                    $Port = 12345 # Port par défaut
                }
                
                $endpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, $Port)
                $socket = New-Object System.Net.Sockets.Socket([System.Net.Sockets.AddressFamily]::InterNetwork, [System.Net.Sockets.SocketType]::Stream, [System.Net.Sockets.ProtocolType]::Tcp)
                $socket.Bind($endpoint)
                $socket.Listen(5)
                
                if (-not $Async) {
                    Write-Verbose "Attente de connexion sur le socket '$($endpoint.ToString())'..."
                    $clientSocket = $socket.Accept()
                    $ipcConnection.Connection = [PSCustomObject]@{
                        ServerSocket = $socket
                        ClientSocket = $clientSocket
                    }
                    $ipcConnection.IsConnected = $true
                    Write-Verbose "Connexion établie sur le socket '$($endpoint.ToString())'."
                }
                else {
                    Write-Verbose "Démarrage du serveur de socket '$($endpoint.ToString())' en mode asynchrone..."
                    $asyncResult = $socket.BeginAccept($null, $null)
                    $ipcConnection.Connection = [PSCustomObject]@{
                        ServerSocket = $socket
                        AsyncResult = $asyncResult
                    }
                }
            }
            catch {
                Write-Error "Erreur lors du démarrage du serveur de socket: $_"
                return $null
            }
        }
        "File" {
            try {
                if ([string]::IsNullOrEmpty($FilePath)) {
                    $FilePath = Join-Path -Path $env:TEMP -ChildPath "$Name.ipc"
                }
                
                # Créer le fichier s'il n'existe pas
                if (-not (Test-Path -Path $FilePath)) {
                    $null = New-Item -Path $FilePath -ItemType File -Force
                }
                
                $ipcConnection.Connection = [PSCustomObject]@{
                    FilePath = $FilePath
                    LastReadPosition = 0
                }
                $ipcConnection.IsConnected = $true
                
                Write-Verbose "Serveur de fichier IPC créé: '$FilePath'."
            }
            catch {
                Write-Error "Erreur lors de la création du fichier IPC: $_"
                return $null
            }
        }
    }
    
    return $ipcConnection
}

# Fonction pour se connecter à un serveur IPC
function Connect-IPCClient {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("NamedPipe", "Socket", "File")]
        [string]$Protocol,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$Server = "localhost",
        
        [Parameter(Mandatory = $false)]
        [int]$Port = 0,
        
        [Parameter(Mandatory = $false)]
        [string]$FilePath = "",
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutMilliseconds = 5000
    )
    
    $ipcConnection = [IPCConnection]::new()
    $ipcConnection.Protocol = $Protocol
    $ipcConnection.Name = $Name
    $ipcConnection.IsServer = $false
    
    switch ($Protocol) {
        "NamedPipe" {
            try {
                $pipeName = if ($Name.StartsWith("\\.\pipe\")) { $Name } else { "\\.\pipe\$Name" }
                $pipeClient = New-Object System.IO.Pipes.NamedPipeClientStream($Server, $Name, [System.IO.Pipes.PipeDirection]::InOut)
                
                Write-Verbose "Connexion au pipe nommé '$pipeName'..."
                $pipeClient.Connect($TimeoutMilliseconds)
                
                $ipcConnection.Connection = $pipeClient
                $ipcConnection.IsConnected = $true
                
                Write-Verbose "Connexion établie au pipe nommé '$pipeName'."
            }
            catch {
                Write-Error "Erreur lors de la connexion au pipe nommé: $_"
                return $null
            }
        }
        "Socket" {
            try {
                if ($Port -eq 0) {
                    $Port = 12345 # Port par défaut
                }
                
                $socket = New-Object System.Net.Sockets.Socket([System.Net.Sockets.AddressFamily]::InterNetwork, [System.Net.Sockets.SocketType]::Stream, [System.Net.Sockets.ProtocolType]::Tcp)
                
                Write-Verbose "Connexion au socket '$Server:$Port'..."
                $socket.Connect($Server, $Port)
                
                $ipcConnection.Connection = $socket
                $ipcConnection.IsConnected = $true
                
                Write-Verbose "Connexion établie au socket '$Server:$Port'."
            }
            catch {
                Write-Error "Erreur lors de la connexion au socket: $_"
                return $null
            }
        }
        "File" {
            try {
                if ([string]::IsNullOrEmpty($FilePath)) {
                    $FilePath = Join-Path -Path $env:TEMP -ChildPath "$Name.ipc"
                }
                
                # Vérifier si le fichier existe
                if (-not (Test-Path -Path $FilePath)) {
                    Write-Error "Le fichier IPC '$FilePath' n'existe pas."
                    return $null
                }
                
                $ipcConnection.Connection = [PSCustomObject]@{
                    FilePath = $FilePath
                    LastReadPosition = 0
                }
                $ipcConnection.IsConnected = $true
                
                Write-Verbose "Connexion établie au fichier IPC: '$FilePath'."
            }
            catch {
                Write-Error "Erreur lors de la connexion au fichier IPC: $_"
                return $null
            }
        }
    }
    
    return $ipcConnection
}

# Fonction pour envoyer un message via une connexion IPC
function Send-IPCMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IPCConnection]$Connection,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Encoding = "UTF8"
    )
    
    if (-not $Connection.IsConnected) {
        Write-Error "La connexion IPC n'est pas établie."
        return $false
    }
    
    # Ajouter un délimiteur de message
    $messageWithDelimiter = "$Message`n"
    
    # Obtenir l'encodage
    $encodingObj = switch ($Encoding.ToUpper()) {
        "UTF8" { [System.Text.Encoding]::UTF8 }
        "UTF16" { [System.Text.Encoding]::Unicode }
        "ASCII" { [System.Text.Encoding]::ASCII }
        default { [System.Text.Encoding]::UTF8 }
    }
    
    # Convertir le message en octets
    $messageBytes = $encodingObj.GetBytes($messageWithDelimiter)
    
    try {
        switch ($Connection.Protocol) {
            "NamedPipe" {
                $Connection.Connection.Write($messageBytes, 0, $messageBytes.Length)
                $Connection.Connection.Flush()
            }
            "Socket" {
                if ($Connection.IsServer) {
                    $Connection.Connection.ClientSocket.Send($messageBytes)
                }
                else {
                    $Connection.Connection.Send($messageBytes)
                }
            }
            "File" {
                # Ajouter le message au fichier
                Add-Content -Path $Connection.Connection.FilePath -Value $messageWithDelimiter -Encoding $Encoding -NoNewline
            }
        }
        
        # Ajouter le message au journal
        $Connection.MessageLog.Add("SENT: $Message")
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'envoi du message: $_"
        return $false
    }
}

# Fonction pour recevoir un message via une connexion IPC
function Receive-IPCMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IPCConnection]$Connection,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutMilliseconds = 5000,
        
        [Parameter(Mandatory = $false)]
        [string]$Encoding = "UTF8",
        
        [Parameter(Mandatory = $false)]
        [switch]$NoWait
    )
    
    if (-not $Connection.IsConnected) {
        Write-Error "La connexion IPC n'est pas établie."
        return $null
    }
    
    # Obtenir l'encodage
    $encodingObj = switch ($Encoding.ToUpper()) {
        "UTF8" { [System.Text.Encoding]::UTF8 }
        "UTF16" { [System.Text.Encoding]::Unicode }
        "ASCII" { [System.Text.Encoding]::ASCII }
        default { [System.Text.Encoding]::UTF8 }
    }
    
    try {
        switch ($Connection.Protocol) {
            "NamedPipe" {
                # Créer un buffer pour recevoir les données
                $buffer = New-Object byte[] 4096
                $stringBuilder = New-Object System.Text.StringBuilder
                
                # Configurer un timeout
                $startTime = Get-Date
                $Connection.Connection.ReadMode = [System.IO.Pipes.PipeTransmissionMode]::Message
                
                while ($true) {
                    # Vérifier si le timeout est atteint
                    if (-not $NoWait -and ((Get-Date) - $startTime).TotalMilliseconds -gt $TimeoutMilliseconds) {
                        Write-Warning "Timeout atteint lors de la réception du message."
                        return $null
                    }
                    
                    # Vérifier si des données sont disponibles
                    if ($NoWait -and $Connection.Connection.InBufferSize -eq 0) {
                        return $null
                    }
                    
                    # Lire les données
                    $bytesRead = $Connection.Connection.Read($buffer, 0, $buffer.Length)
                    
                    if ($bytesRead -gt 0) {
                        $stringBuilder.Append($encodingObj.GetString($buffer, 0, $bytesRead)) | Out-Null
                        
                        # Vérifier si le message est complet
                        if ($Connection.Connection.IsMessageComplete) {
                            break
                        }
                    }
                    else {
                        if ($NoWait) {
                            return $null
                        }
                        
                        # Attendre un peu avant de réessayer
                        Start-Sleep -Milliseconds 100
                    }
                }
                
                $message = $stringBuilder.ToString().TrimEnd("`r`n")
            }
            "Socket" {
                # Créer un buffer pour recevoir les données
                $buffer = New-Object byte[] 4096
                $stringBuilder = New-Object System.Text.StringBuilder
                
                # Obtenir le socket client
                $socket = if ($Connection.IsServer) {
                    $Connection.Connection.ClientSocket
                }
                else {
                    $Connection.Connection
                }
                
                # Configurer un timeout
                $socket.ReceiveTimeout = $TimeoutMilliseconds
                
                # Vérifier si des données sont disponibles
                if ($NoWait -and $socket.Available -eq 0) {
                    return $null
                }
                
                # Lire les données
                $bytesRead = $socket.Receive($buffer)
                
                if ($bytesRead -gt 0) {
                    $stringBuilder.Append($encodingObj.GetString($buffer, 0, $bytesRead)) | Out-Null
                }
                
                $message = $stringBuilder.ToString().TrimEnd("`r`n")
            }
            "File" {
                # Lire le contenu du fichier
                $content = Get-Content -Path $Connection.Connection.FilePath -Raw
                
                if ([string]::IsNullOrEmpty($content)) {
                    if ($NoWait) {
                        return $null
                    }
                    
                    # Attendre qu'il y ait du contenu
                    $startTime = Get-Date
                    
                    while ([string]::IsNullOrEmpty($content)) {
                        # Vérifier si le timeout est atteint
                        if ((Get-Date) - $startTime).TotalMilliseconds -gt $TimeoutMilliseconds) {
                            Write-Warning "Timeout atteint lors de la réception du message."
                            return $null
                        }
                        
                        # Attendre un peu avant de réessayer
                        Start-Sleep -Milliseconds 100
                        
                        # Relire le contenu
                        $content = Get-Content -Path $Connection.Connection.FilePath -Raw
                    }
                }
                
                # Extraire les nouveaux messages
                $lines = $content -split "`n"
                $newLines = $lines[$Connection.Connection.LastReadPosition..($lines.Length - 1)]
                
                if ($newLines.Count -eq 0) {
                    if ($NoWait) {
                        return $null
                    }
                    
                    # Attendre qu'il y ait de nouveaux messages
                    $startTime = Get-Date
                    
                    while ($newLines.Count -eq 0) {
                        # Vérifier si le timeout est atteint
                        if ((Get-Date) - $startTime).TotalMilliseconds -gt $TimeoutMilliseconds) {
                            Write-Warning "Timeout atteint lors de la réception du message."
                            return $null
                        }
                        
                        # Attendre un peu avant de réessayer
                        Start-Sleep -Milliseconds 100
                        
                        # Relire le contenu
                        $content = Get-Content -Path $Connection.Connection.FilePath -Raw
                        $lines = $content -split "`n"
                        $newLines = $lines[$Connection.Connection.LastReadPosition..($lines.Length - 1)]
                    }
                }
                
                # Mettre à jour la position de lecture
                $Connection.Connection.LastReadPosition = $lines.Length
                
                # Retourner le premier nouveau message
                $message = $newLines[0].TrimEnd("`r")
            }
        }
        
        # Ajouter le message au journal
        $Connection.MessageLog.Add("RECEIVED: $message")
        
        return $message
    }
    catch {
        Write-Error "Erreur lors de la réception du message: $_"
        return $null
    }
}

# Fonction pour fermer une connexion IPC
function Close-IPCConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IPCConnection]$Connection
    )
    
    if (-not $Connection.IsConnected) {
        Write-Warning "La connexion IPC n'est pas établie."
        return $true
    }
    
    try {
        switch ($Connection.Protocol) {
            "NamedPipe" {
                $Connection.Connection.Close()
                $Connection.Connection.Dispose()
            }
            "Socket" {
                if ($Connection.IsServer) {
                    if ($null -ne $Connection.Connection.ClientSocket) {
                        $Connection.Connection.ClientSocket.Close()
                    }
                    $Connection.Connection.ServerSocket.Close()
                }
                else {
                    $Connection.Connection.Close()
                }
            }
            "File" {
                # Rien à faire pour les fichiers
            }
        }
        
        $Connection.IsConnected = $false
        
        Write-Verbose "Connexion IPC fermée."
        return $true
    }
    catch {
        Write-Error "Erreur lors de la fermeture de la connexion IPC: $_"
        return $false
    }
}

# Fonction pour créer un mutex (verrou global)
function New-IPCMutex {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [switch]$Global
    )
    
    try {
        $mutexName = if ($Global) { "Global\$Name" } else { $Name }
        $mutex = New-Object System.Threading.Mutex($false, $mutexName)
        
        return [PSCustomObject]@{
            Name = $mutexName
            Mutex = $mutex
            IsOwned = $false
        }
    }
    catch {
        Write-Error "Erreur lors de la création du mutex: $_"
        return $null
    }
}

# Fonction pour acquérir un mutex
function Lock-IPCMutex {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Mutex,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutMilliseconds = 5000
    )
    
    try {
        $acquired = $Mutex.Mutex.WaitOne($TimeoutMilliseconds)
        
        if ($acquired) {
            $Mutex.IsOwned = $true
            return $true
        }
        else {
            Write-Warning "Impossible d'acquérir le mutex '$($Mutex.Name)' dans le délai imparti."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors de l'acquisition du mutex: $_"
        return $false
    }
}

# Fonction pour libérer un mutex
function Unlock-IPCMutex {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Mutex
    )
    
    try {
        if ($Mutex.IsOwned) {
            $Mutex.Mutex.ReleaseMutex()
            $Mutex.IsOwned = $false
            return $true
        }
        else {
            Write-Warning "Le mutex '$($Mutex.Name)' n'est pas détenu par ce processus."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors de la libération du mutex: $_"
        return $false
    }
}

# Fonction pour fermer un mutex
function Close-IPCMutex {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Mutex
    )
    
    try {
        if ($Mutex.IsOwned) {
            $Mutex.Mutex.ReleaseMutex()
            $Mutex.IsOwned = $false
        }
        
        $Mutex.Mutex.Close()
        $Mutex.Mutex.Dispose()
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de la fermeture du mutex: $_"
        return $false
    }
}

# Fonction pour créer un événement (signal global)
function New-IPCEvent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [switch]$Global,
        
        [Parameter(Mandatory = $false)]
        [switch]$ManualReset
    )
    
    try {
        $eventName = if ($Global) { "Global\$Name" } else { $Name }
        $event = New-Object System.Threading.EventWaitHandle($false, [System.Threading.EventResetMode]::$($ManualReset ? "ManualReset" : "AutoReset"), $eventName)
        
        return [PSCustomObject]@{
            Name = $eventName
            Event = $event
        }
    }
    catch {
        Write-Error "Erreur lors de la création de l'événement: $_"
        return $null
    }
}

# Fonction pour signaler un événement
function Set-IPCEvent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Event
    )
    
    try {
        $Event.Event.Set() | Out-Null
        return $true
    }
    catch {
        Write-Error "Erreur lors du signalement de l'événement: $_"
        return $false
    }
}

# Fonction pour réinitialiser un événement
function Reset-IPCEvent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Event
    )
    
    try {
        $Event.Event.Reset() | Out-Null
        return $true
    }
    catch {
        Write-Error "Erreur lors de la réinitialisation de l'événement: $_"
        return $false
    }
}

# Fonction pour attendre un événement
function Wait-IPCEvent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Event,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutMilliseconds = 5000
    )
    
    try {
        $signaled = $Event.Event.WaitOne($TimeoutMilliseconds)
        
        if ($signaled) {
            return $true
        }
        else {
            Write-Warning "L'événement '$($Event.Name)' n'a pas été signalé dans le délai imparti."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors de l'attente de l'événement: $_"
        return $false
    }
}

# Fonction pour fermer un événement
function Close-IPCEvent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Event
    )
    
    try {
        $Event.Event.Close()
        $Event.Event.Dispose()
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de la fermeture de l'événement: $_"
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Start-IPCServer, Connect-IPCClient, Send-IPCMessage, Receive-IPCMessage, Close-IPCConnection
Export-ModuleMember -Function New-IPCMutex, Lock-IPCMutex, Unlock-IPCMutex, Close-IPCMutex
Export-ModuleMember -Function New-IPCEvent, Set-IPCEvent, Reset-IPCEvent, Wait-IPCEvent, Close-IPCEvent
