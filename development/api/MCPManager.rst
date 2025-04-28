.. MCPManager API documentation

Module MCPManager
===============

Le module ``MCPManager`` fournit des fonctionnalités pour gérer les serveurs MCP (Model Context Protocol), détecter les serveurs disponibles, et interagir avec eux. Il permet de démarrer, arrêter et configurer des serveurs MCP locaux ou distants.

Fonctions principales
--------------------

Initialize-MCPManager
~~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Initialize-MCPManager [-Enabled <Boolean>] [-ConfigPath <String>] [-LogPath <String>] [-LogLevel <String>]

Initialise le gestionnaire MCP avec les paramètres spécifiés.

Paramètres:
    * **Enabled** (*Boolean*) - Active ou désactive le gestionnaire MCP. Valeur par défaut : $true
    * **ConfigPath** (*String*) - Chemin du fichier de configuration. Valeur par défaut : ".\projet\config\mcp_manager.json"
    * **LogPath** (*String*) - Chemin du fichier de log. Valeur par défaut : ".\logs\mcp_manager.log"
    * **LogLevel** (*String*) - Niveau de log (DEBUG, INFO, WARNING, ERROR). Valeur par défaut : "INFO"

Valeur de retour:
    Booléen indiquant si l'initialisation a réussi.

Exemple:

.. code-block:: powershell

    # Initialiser le gestionnaire MCP avec un fichier de configuration personnalisé
    Initialize-MCPManager -Enabled $true -ConfigPath ".\projet\config\custom_mcp_config.json" -LogPath ".\logs\mcp.log" -LogLevel "DEBUG"

Find-MCPServers
~~~~~~~~~~~~~

.. code-block:: powershell

    Find-MCPServers [-ScanLocalPorts] [-ScanRemoteHosts <String[]>] [-PortRange <Int32[]>] [-Timeout <Int32>]

Recherche les serveurs MCP disponibles sur le réseau local ou sur des hôtes distants.

Paramètres:
    * **ScanLocalPorts** (*Switch*) - Analyse les ports locaux pour détecter les serveurs MCP.
    * **ScanRemoteHosts** (*String[]*) - Tableau d'hôtes distants à analyser.
    * **PortRange** (*Int32[]*) - Plage de ports à analyser. Par défaut : 8000-8100.
    * **Timeout** (*Int32*) - Délai d'attente en millisecondes. Par défaut : 1000.

Valeur de retour:
    Un tableau d'objets représentant les serveurs MCP détectés, avec les propriétés suivantes:
    
    * **Host** (*String*) - Nom ou adresse IP de l'hôte.
    * **Port** (*Int32*) - Numéro de port du serveur MCP.
    * **Type** (*String*) - Type de serveur MCP (local, n8n, notion, etc.).
    * **Status** (*String*) - État du serveur (running, stopped, etc.).
    * **Version** (*String*) - Version du serveur MCP.
    * **Url** (*String*) - URL complète du serveur MCP.

Exemple:

.. code-block:: powershell

    # Rechercher les serveurs MCP locaux
    $localServers = Find-MCPServers -ScanLocalPorts
    
    # Afficher les serveurs détectés
    foreach ($server in $localServers) {
        Write-Host "Serveur MCP détecté: $($server.Type) sur $($server.Host):$($server.Port) - $($server.Status)"
    }
    
    # Rechercher les serveurs MCP sur des hôtes distants
    $remoteServers = Find-MCPServers -ScanRemoteHosts @("server1.example.com", "server2.example.com") -PortRange @(8000, 8001, 8002)
    
    # Afficher les serveurs distants détectés
    foreach ($server in $remoteServers) {
        Write-Host "Serveur MCP distant détecté: $($server.Type) sur $($server.Host):$($server.Port) - $($server.Status)"
    }

New-MCPConfiguration
~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    New-MCPConfiguration [-OutputPath <String>] [-ServerType <String>] [-Port <Int32>] [-Host <String>] [-Force]

Crée un fichier de configuration pour un serveur MCP.

Paramètres:
    * **OutputPath** (*String*) - Chemin du fichier de configuration à créer. Par défaut : ".\projet\config\mcp_config.json"
    * **ServerType** (*String*) - Type de serveur MCP (local, n8n, notion, gateway, git-ingest). Par défaut : "local"
    * **Port** (*Int32*) - Numéro de port du serveur MCP. Par défaut : 8000
    * **Host** (*String*) - Nom ou adresse IP de l'hôte. Par défaut : "localhost"
    * **Force** (*Switch*) - Écrase le fichier de configuration s'il existe déjà.

Valeur de retour:
    Booléen indiquant si la création du fichier de configuration a réussi.

Exemple:

.. code-block:: powershell

    # Créer une configuration pour un serveur MCP local
    $configCreated = New-MCPConfiguration -OutputPath ".\projet\config\local_mcp_config.json" -ServerType "local" -Port 8000 -Force
    
    if ($configCreated) {
        Write-Host "Configuration créée avec succès: .\projet\config\local_mcp_config.json"
    }
    
    # Créer une configuration pour un serveur MCP n8n
    $n8nConfigCreated = New-MCPConfiguration -OutputPath ".\projet\config\n8n_mcp_config.json" -ServerType "n8n" -Port 5678 -Host "localhost" -Force
    
    if ($n8nConfigCreated) {
        Write-Host "Configuration n8n créée avec succès: .\projet\config\n8n_mcp_config.json"
    }

Start-MCPServer
~~~~~~~~~~~~~

.. code-block:: powershell

    Start-MCPServer [-ServerType <String>] [-Port <Int32>] [-Host <String>] [-ConfigPath <String>] [-Wait] [-Timeout <Int32>]

Démarre un serveur MCP.

Paramètres:
    * **ServerType** (*String*) - Type de serveur MCP (local, n8n, notion, gateway, git-ingest). Par défaut : "local"
    * **Port** (*Int32*) - Numéro de port du serveur MCP. Par défaut : 8000
    * **Host** (*String*) - Nom ou adresse IP de l'hôte. Par défaut : "localhost"
    * **ConfigPath** (*String*) - Chemin du fichier de configuration. Par défaut : ".\projet\config\mcp_config.json"
    * **Wait** (*Switch*) - Attend que le serveur soit prêt avant de retourner.
    * **Timeout** (*Int32*) - Délai d'attente en secondes. Par défaut : 30

Valeur de retour:
    Un objet représentant le serveur MCP démarré, avec les propriétés suivantes:
    
    * **ProcessId** (*Int32*) - ID du processus du serveur MCP.
    * **ServerType** (*String*) - Type de serveur MCP.
    * **Port** (*Int32*) - Numéro de port du serveur MCP.
    * **Host** (*String*) - Nom ou adresse IP de l'hôte.
    * **Url** (*String*) - URL complète du serveur MCP.
    * **Status** (*String*) - État du serveur (running, error).

Exemple:

.. code-block:: powershell

    # Démarrer un serveur MCP local
    $server = Start-MCPServer -ServerType "local" -Port 8000 -Wait
    
    if ($server.Status -eq "running") {
        Write-Host "Serveur MCP démarré avec succès: $($server.Url)"
        Write-Host "ID du processus: $($server.ProcessId)"
    } else {
        Write-Host "Erreur lors du démarrage du serveur MCP: $($server.Error)"
    }
    
    # Démarrer un serveur MCP n8n
    $n8nServer = Start-MCPServer -ServerType "n8n" -Port 5678 -Wait
    
    if ($n8nServer.Status -eq "running") {
        Write-Host "Serveur MCP n8n démarré avec succès: $($n8nServer.Url)"
    }

Stop-MCPServer
~~~~~~~~~~~~

.. code-block:: powershell

    Stop-MCPServer [-ServerType <String>] [-Port <Int32>] [-Host <String>] [-ProcessId <Int32>] [-Force]

Arrête un serveur MCP.

Paramètres:
    * **ServerType** (*String*) - Type de serveur MCP (local, n8n, notion, gateway, git-ingest). Par défaut : "local"
    * **Port** (*Int32*) - Numéro de port du serveur MCP. Par défaut : 8000
    * **Host** (*String*) - Nom ou adresse IP de l'hôte. Par défaut : "localhost"
    * **ProcessId** (*Int32*) - ID du processus du serveur MCP.
    * **Force** (*Switch*) - Force l'arrêt du serveur.

Valeur de retour:
    Booléen indiquant si l'arrêt du serveur a réussi.

Exemple:

.. code-block:: powershell

    # Arrêter un serveur MCP local
    $stopped = Stop-MCPServer -ServerType "local" -Port 8000
    
    if ($stopped) {
        Write-Host "Serveur MCP arrêté avec succès"
    } else {
        Write-Host "Erreur lors de l'arrêt du serveur MCP"
    }
    
    # Arrêter un serveur MCP par son ID de processus
    $stoppedById = Stop-MCPServer -ProcessId 1234 -Force
    
    if ($stoppedById) {
        Write-Host "Serveur MCP avec l'ID de processus 1234 arrêté avec succès"
    }

Invoke-MCPCommand
~~~~~~~~~~~~~~~

.. code-block:: powershell

    Invoke-MCPCommand [-Command <String>] [-Parameters <Hashtable>] [-ServerType <String>] [-Port <Int32>] [-Host <String>] [-Timeout <Int32>]

Exécute une commande sur un serveur MCP.

Paramètres:
    * **Command** (*String*) - Commande à exécuter.
    * **Parameters** (*Hashtable*) - Paramètres de la commande.
    * **ServerType** (*String*) - Type de serveur MCP (local, n8n, notion, gateway, git-ingest). Par défaut : "local"
    * **Port** (*Int32*) - Numéro de port du serveur MCP. Par défaut : 8000
    * **Host** (*String*) - Nom ou adresse IP de l'hôte. Par défaut : "localhost"
    * **Timeout** (*Int32*) - Délai d'attente en secondes. Par défaut : 30

Valeur de retour:
    Le résultat de l'exécution de la commande.

Exemple:

.. code-block:: powershell

    # Exécuter une commande sur un serveur MCP local
    $result = Invoke-MCPCommand -Command "get_tools" -ServerType "local" -Port 8000
    
    # Afficher les outils disponibles
    Write-Host "Outils disponibles sur le serveur MCP:"
    foreach ($tool in $result.tools) {
        Write-Host "- $($tool.name): $($tool.description)"
    }
    
    # Exécuter une commande avec des paramètres
    $addResult = Invoke-MCPCommand -Command "add" -Parameters @{ a = 2; b = 3 } -ServerType "local" -Port 8000
    
    Write-Host "Résultat de l'addition: $addResult"

Install-MCPDependencies
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Install-MCPDependencies [-ServerType <String>] [-Force]

Installe les dépendances nécessaires pour un serveur MCP.

Paramètres:
    * **ServerType** (*String*) - Type de serveur MCP (local, n8n, notion, gateway, git-ingest). Par défaut : "local"
    * **Force** (*Switch*) - Force l'installation des dépendances même si elles sont déjà installées.

Valeur de retour:
    Booléen indiquant si l'installation des dépendances a réussi.

Exemple:

.. code-block:: powershell

    # Installer les dépendances pour un serveur MCP local
    $installed = Install-MCPDependencies -ServerType "local"
    
    if ($installed) {
        Write-Host "Dépendances installées avec succès"
    } else {
        Write-Host "Erreur lors de l'installation des dépendances"
    }
    
    # Forcer l'installation des dépendances pour un serveur MCP n8n
    $n8nInstalled = Install-MCPDependencies -ServerType "n8n" -Force
    
    if ($n8nInstalled) {
        Write-Host "Dépendances n8n installées avec succès"
    }

Test-MCPServer
~~~~~~~~~~~~

.. code-block:: powershell

    Test-MCPServer [-ServerType <String>] [-Port <Int32>] [-Host <String>] [-Timeout <Int32>]

Teste la disponibilité d'un serveur MCP.

Paramètres:
    * **ServerType** (*String*) - Type de serveur MCP (local, n8n, notion, gateway, git-ingest). Par défaut : "local"
    * **Port** (*Int32*) - Numéro de port du serveur MCP. Par défaut : 8000
    * **Host** (*String*) - Nom ou adresse IP de l'hôte. Par défaut : "localhost"
    * **Timeout** (*Int32*) - Délai d'attente en millisecondes. Par défaut : 1000

Valeur de retour:
    Un objet avec les propriétés suivantes:
    
    * **Available** (*Boolean*) - Indique si le serveur est disponible.
    * **ResponseTime** (*Int32*) - Temps de réponse en millisecondes.
    * **Version** (*String*) - Version du serveur MCP.
    * **ServerType** (*String*) - Type de serveur MCP.
    * **Url** (*String*) - URL complète du serveur MCP.

Exemple:

.. code-block:: powershell

    # Tester un serveur MCP local
    $testResult = Test-MCPServer -ServerType "local" -Port 8000
    
    if ($testResult.Available) {
        Write-Host "Serveur MCP disponible: $($testResult.Url)"
        Write-Host "Temps de réponse: $($testResult.ResponseTime) ms"
        Write-Host "Version: $($testResult.Version)"
    } else {
        Write-Host "Serveur MCP non disponible"
    }
    
    # Tester un serveur MCP distant
    $remoteTestResult = Test-MCPServer -ServerType "n8n" -Port 5678 -Host "server.example.com" -Timeout 2000
    
    if ($remoteTestResult.Available) {
        Write-Host "Serveur MCP distant disponible: $($remoteTestResult.Url)"
    }

Write-MCPLog
~~~~~~~~~~

.. code-block:: powershell

    Write-MCPLog [-Message <String>] [-Level <String>] [-LogPath <String>]

Écrit un message dans le fichier de log du gestionnaire MCP.

Paramètres:
    * **Message** (*String*) - Message à écrire dans le log.
    * **Level** (*String*) - Niveau de log (DEBUG, INFO, WARNING, ERROR). Par défaut : "INFO"
    * **LogPath** (*String*) - Chemin du fichier de log. Par défaut : valeur définie lors de l'initialisation

Valeur de retour:
    Aucune.

Exemple:

.. code-block:: powershell

    # Écrire un message d'information dans le log
    Write-MCPLog -Message "Démarrage du serveur MCP" -Level "INFO"
    
    # Écrire un message d'erreur dans le log
    Write-MCPLog -Message "Erreur lors de la connexion au serveur MCP: Connexion refusée" -Level "ERROR"
    
    # Écrire un message de débogage dans un fichier de log spécifique
    Write-MCPLog -Message "Détails de la requête: $requestDetails" -Level "DEBUG" -LogPath ".\logs\mcp_debug.log"
