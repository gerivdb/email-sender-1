<#
.SYNOPSIS
    Fournit des mÃ©canismes de communication inter-processus pour PowerShell.

.DESCRIPTION
    Ce script implÃ©mente plusieurs mÃ©thodes de communication inter-processus (IPC)
    pour permettre aux scripts PowerShell de communiquer entre eux, notamment via
    des fichiers partagÃ©s, des pipes nommÃ©s, et des sockets.

.EXAMPLE
    . .\InterProcessCommunication.ps1
    $server = Start-IPCServer -Protocol "NamedPipe" -Name "MyPipe"
    $client = Connect-IPCClient -Protocol "NamedPipe" -Name "MyPipe"
    Send-IPCMessage -Connection $client -Message "Hello, world!"
    $message = Receive-IPCMessage -Connection $server

.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 07/04/2025
    Version: 1.0
#>

# Classe pour reprÃ©senter une connexion IPC
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

# Fonction pour dÃ©marrer un serveur IPC
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
                    Write-Verbose "Attente de connexion sur le pipe nommÃ© '$pipeName'..."
                    $pipeServer.WaitForConnection()
                    $ipcConnection.IsConnected = $true
                    Write-Verbose "Connexion Ã©tablie sur le pipe nommÃ© '$pipeName'."
                }
                else {
                    Write-Verbose "DÃ©marrage du serveur de pipe nommÃ© '$pipeName' en mode asynchrone..."
                    $asyncResult = $pipeServer.BeginWaitForConnection($null, $null)
                }

                $ipcConnection.Connection = $pipeServer
            }
            catch {
                Write-Error "Erreur lors du dÃ©marrage du serveur de pipe nommÃ©: $_"
                return $null
            }
        }
        "Socket" {
            try {
                if ($Port -eq 0) {
                    $Port = 12345 # Port par dÃ©faut
                }

                $endpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, $Port)
                $socket = New-Object System.Net.Sockets.Socket([System.Net.Sockets.AddressFamily]::InterNetwork, [System.Net.Sockets.SocketType]::Stream, [System.Net.Sockets.ProtocolType]::Tcp)
                $socket.Bind($endpoint)
                $socket.Listen(5)

                if (-not $Async) {
                    Write-Verbose "Attente de connexion sur le socket '${endpoint}'..."
                    $clientSocket = $socket.Accept()
                    $ipcConnection.Connection = [PSCustomObject]@{
                        ServerSocket = $socket
                        ClientSocket = $clientSocket
                    }
                    $ipcConnection.IsConnected = $true
                    Write-Verbose "Connexion établie sur le socket '${endpoint}'."
                }
                else {
                    Write-Verbose "DÃ©marrage du serveur de socket '${endpoint}' en mode asynchrone..."
                    $asyncResult = $socket.BeginAccept($null, $null)
                    $ipcConnection.Connection = [PSCustomObject]@{
                        ServerSocket = $socket
                        AsyncResult = $asyncResult
                    }
                }
            }
            catch {
                Write-Error "Erreur lors du dÃ©marrage du serveur de socket: $_"
                return $null
            }
        }
        "File" {
            try {
                if ([string]::IsNullOrEmpty($FilePath)) {
                    $FilePath = Join-Path -Path $env:TEMP -ChildPath "$Name.ipc"
                }

                # CrÃ©er le fichier s'il n'existe pas
                if (-not (Test-Path -Path $FilePath)) {
                    $null = New-Item -Path $FilePath -ItemType File -Force
                }

                $ipcConnection.Connection = [PSCustomObject]@{
                    FilePath = $FilePath
                    LastReadPosition = 0
                }
                $ipcConnection.IsConnected = $true

                Write-Verbose "Serveur de fichier IPC crÃ©Ã©: '$FilePath'."
            }
            catch {
                Write-Error "Erreur lors de la crÃ©ation du fichier IPC: $_"
                return $null
            }
        }
    }

    return $ipcConnection
}

# Fonction pour se connecter Ã  un serveur IPC
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

                Write-Verbose "Connexion au pipe nommÃ© '$pipeName'..."
                $pipeClient.Connect($TimeoutMilliseconds)

                $ipcConnection.Connection = $pipeClient
                $ipcConnection.IsConnected = $true

                Write-Verbose "Connexion Ã©tablie au pipe nommÃ© '$pipeName'."
            }
            catch {
                Write-Error "Erreur lors de la connexion au pipe nommÃ©: $_"
                return $null
            }
        }
        "Socket" {
            try {
                if ($Port -eq 0) {
                    $Port = 12345 # Port par dÃ©faut
                }

                $socket = New-Object System.Net.Sockets.Socket([System.Net.Sockets.AddressFamily]::InterNetwork, [System.Net.Sockets.SocketType]::Stream, [System.Net.Sockets.ProtocolType]::Tcp)

                Write-Verbose "Connexion au socket '${Server}:${Port}'..."
                $socket.Connect($Server, $Port)

                $ipcConnection.Connection = $socket
                $ipcConnection.IsConnected = $true

                Write-Verbose "Connexion établie au socket '${Server}:${Port}'."
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

                # VÃ©rifier si le fichier existe
                if (-not (Test-Path -Path $FilePath)) {
                    Write-Error "Le fichier IPC '$FilePath' n'existe pas."
                    return $null
                }

                $ipcConnection.Connection = [PSCustomObject]@{
                    FilePath = $FilePath
                    LastReadPosition = 0
                }
                $ipcConnection.IsConnected = $true

                Write-Verbose "Connexion Ã©tablie au fichier IPC: '$FilePath'."
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
        Write-Error "La connexion IPC n'est pas Ã©tablie."
        return $false
    }

    # Ajouter un dÃ©limiteur de message
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
                $buffer = New-Object byte[] 1024
                $messageBuilder = New-Object System.Text.StringBuilder

                if ($NoWait -and -not $Connection.Connection.IsMessageReady) {
                    return $null
                }

                $bytesRead = $Connection.Connection.Read($buffer, 0, $buffer.Length)
                if ($bytesRead -gt 0) {
                    $messageBuilder.Append($encodingObj.GetString($buffer, 0, $bytesRead)) | Out-Null
                }

                return $messageBuilder.ToString().TrimEnd()
            }
            "Socket" {
                $buffer = New-Object byte[] 1024
                $messageBuilder = New-Object System.Text.StringBuilder

                if ($NoWait) {
                    if ($Connection.IsServer) {
                        if (-not $Connection.Connection.ClientSocket.Poll(0, [System.Net.Sockets.SelectMode]::Read)) {
                            return $null
                        }
                    } else {
                        if (-not $Connection.Connection.Poll(0, [System.Net.Sockets.SelectMode]::Read)) {
                            return $null
                        }
                    }
                }

                $bytesRead = if ($Connection.IsServer) {
                    $Connection.Connection.ClientSocket.Receive($buffer)
                } else {
                    $Connection.Connection.Receive($buffer)
                }

                if ($bytesRead -gt 0) {
                    $messageBuilder.Append($encodingObj.GetString($buffer, 0, $bytesRead)) | Out-Null
                }

                return $messageBuilder.ToString().TrimEnd()
            }
            "File" {
                if (-not (Test-Path $Connection.Connection.FilePath)) {
                    return $null
                }

                $content = Get-Content $Connection.Connection.FilePath -Encoding $Encoding
                if ($content.Length -gt $Connection.Connection.LastReadPosition) {
                    $newMessages = $content[$Connection.Connection.LastReadPosition..($content.Length-1)]
                    $Connection.Connection.LastReadPosition = $content.Length
                    return $newMessages -join "`n"
                }

                return $null
            }
        }
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
        Write-Warning "La connexion IPC n'est pas Ã©tablie."
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
                # Rien Ã  faire pour les fichiers
            }
        }

        $Connection.IsConnected = $false

        Write-Verbose "Connexion IPC fermÃ©e."
        return $true
    }
    catch {
        Write-Error "Erreur lors de la fermeture de la connexion IPC: $_"
        return $false
    }
}

# Fonction pour crÃ©er un mutex (verrou global)
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
        Write-Error "Erreur lors de la crÃ©ation du mutex: $_"
        return $null
    }
}

# Fonction pour acquÃ©rir un mutex
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
            Write-Warning "Impossible d'acquÃ©rir le mutex '$($Mutex.Name)' dans le dÃ©lai imparti."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors de l'acquisition du mutex: $_"
        return $false
    }
}

# Fonction pour libÃ©rer un mutex
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
            Write-Warning "Le mutex '$($Mutex.Name)' n'est pas dÃ©tenu par ce processus."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors de la libÃ©ration du mutex: $_"
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

# Fonction pour crÃ©er un Ã©vÃ©nement (signal global)
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
        $eventHandle = New-Object System.Threading.EventWaitHandle(
            $false,
            $(if ($ManualReset) { [System.Threading.EventResetMode]::ManualReset } else { [System.Threading.EventResetMode]::AutoReset }),
            $eventName
        )

        return [PSCustomObject]@{
            Name = $eventName
            EventHandle = $eventHandle
        }
    }
    catch {
        Write-Error "Erreur lors de la création de l'événement: $_"
        return $null
    }
}

# Fonction pour signaler un Ã©vÃ©nement
function Set-IPCEvent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$EventObj  # Changed from $Event
    )

    try {
        $EventObj.Event.Set() | Out-Null
        return $true
    }
    catch {
        Write-Error "Erreur lors du signalement de l'Ã©vÃ©nement: $_"
        return $false
    }
}

# Fonction pour rÃ©initialiser un Ã©vÃ©nement
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
        Write-Error "Erreur lors de la rÃ©initialisation de l'Ã©vÃ©nement: $_"
        return $false
    }
}

# Fonction pour attendre un Ã©vÃ©nement
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
            Write-Warning "L'Ã©vÃ©nement '$($Event.Name)' n'a pas Ã©tÃ© signalÃ© dans le dÃ©lai imparti."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors de l'attente de l'Ã©vÃ©nement: $_"
        return $false
    }
}

# Fonction pour fermer un Ã©vÃ©nement
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
        Write-Error "Erreur lors de la fermeture de l'Ã©vÃ©nement: $_"
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Start-IPCServer, Connect-IPCClient, Send-IPCMessage, Receive-IPCMessage, Close-IPCConnection
Export-ModuleMember -Function New-IPCMutex, Lock-IPCMutex, Unlock-IPCMutex, Close-IPCMutex
Export-ModuleMember -Function New-IPCEvent, Set-IPCEvent, Reset-IPCEvent, Wait-IPCEvent, Close-IPCEvent




