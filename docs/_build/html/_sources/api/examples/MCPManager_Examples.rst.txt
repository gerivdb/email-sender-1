.. MCPManager Examples documentation

Exemples d'utilisation du module MCPManager
========================================

Cette page contient des exemples concrets d'utilisation du module ``MCPManager`` pour gérer les serveurs MCP (Model Context Protocol).

Exemple 1: Recherche et détection des serveurs MCP
------------------------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\MCPManager.psm1" -Force
    
    # Initialiser le gestionnaire MCP
    Initialize-MCPManager -Enabled $true -LogPath ".\logs\mcp_manager.log" -LogLevel "INFO"
    
    # Rechercher les serveurs MCP locaux
    Write-Host "Recherche des serveurs MCP locaux..."
    $localServers = Find-MCPServers -ScanLocalPorts
    
    # Afficher les serveurs détectés
    if ($localServers.Count -gt 0) {
        Write-Host "Serveurs MCP locaux détectés:"
        foreach ($server in $localServers) {
            Write-Host "- $($server.Type) sur $($server.Host):$($server.Port) - $($server.Status)"
        }
    } else {
        Write-Host "Aucun serveur MCP local détecté"
    }
    
    # Rechercher les serveurs MCP sur des hôtes distants
    Write-Host "`nRecherche des serveurs MCP sur des hôtes distants..."
    $remoteHosts = @("server1.example.com", "server2.example.com")
    $remoteServers = Find-MCPServers -ScanRemoteHosts $remoteHosts -PortRange @(8000..8010)
    
    # Afficher les serveurs distants détectés
    if ($remoteServers.Count -gt 0) {
        Write-Host "Serveurs MCP distants détectés:"
        foreach ($server in $remoteServers) {
            Write-Host "- $($server.Type) sur $($server.Host):$($server.Port) - $($server.Status)"
        }
    } else {
        Write-Host "Aucun serveur MCP distant détecté"
    }
    
    # Sauvegarder la liste des serveurs détectés
    $allServers = $localServers + $remoteServers
    $allServers | ConvertTo-Json | Set-Content -Path ".\config\detected_mcp_servers.json"
    Write-Host "`nListe des serveurs MCP sauvegardée dans .\config\detected_mcp_servers.json"

Exemple 2: Création et configuration d'un serveur MCP
---------------------------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\MCPManager.psm1" -Force
    
    # Initialiser le gestionnaire MCP
    Initialize-MCPManager -Enabled $true -LogPath ".\logs\mcp_manager.log" -LogLevel "INFO"
    
    # Créer une configuration pour un serveur MCP local
    Write-Host "Création d'une configuration pour un serveur MCP local..."
    $configPath = ".\config\local_mcp_config.json"
    $configCreated = New-MCPConfiguration -OutputPath $configPath -ServerType "local" -Port 8000 -Force
    
    if ($configCreated) {
        Write-Host "Configuration créée avec succès: $configPath"
        
        # Afficher le contenu de la configuration
        $config = Get-Content -Path $configPath | ConvertFrom-Json
        Write-Host "Type de serveur: $($config.serverType)"
        Write-Host "Port: $($config.port)"
        Write-Host "Hôte: $($config.host)"
    } else {
        Write-Host "Erreur lors de la création de la configuration"
    }
    
    # Créer une configuration pour un serveur MCP n8n
    Write-Host "`nCréation d'une configuration pour un serveur MCP n8n..."
    $n8nConfigPath = ".\config\n8n_mcp_config.json"
    $n8nConfigCreated = New-MCPConfiguration -OutputPath $n8nConfigPath -ServerType "n8n" -Port 5678 -Host "localhost" -Force
    
    if ($n8nConfigCreated) {
        Write-Host "Configuration n8n créée avec succès: $n8nConfigPath"
    }
    
    # Installer les dépendances nécessaires
    Write-Host "`nInstallation des dépendances pour les serveurs MCP..."
    $installed = Install-MCPDependencies -ServerType "local"
    
    if ($installed) {
        Write-Host "Dépendances installées avec succès"
    } else {
        Write-Host "Erreur lors de l'installation des dépendances"
    }

Exemple 3: Démarrage et arrêt d'un serveur MCP
--------------------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\MCPManager.psm1" -Force
    
    # Initialiser le gestionnaire MCP
    Initialize-MCPManager -Enabled $true -LogPath ".\logs\mcp_manager.log" -LogLevel "INFO"
    
    # Démarrer un serveur MCP local
    Write-Host "Démarrage d'un serveur MCP local..."
    $server = Start-MCPServer -ServerType "local" -Port 8000 -Wait
    
    if ($server.Status -eq "running") {
        Write-Host "Serveur MCP démarré avec succès: $($server.Url)"
        Write-Host "ID du processus: $($server.ProcessId)"
        
        # Tester le serveur
        Write-Host "`nTest du serveur MCP..."
        $testResult = Test-MCPServer -ServerType "local" -Port 8000
        
        if ($testResult.Available) {
            Write-Host "Serveur MCP disponible"
            Write-Host "Temps de réponse: $($testResult.ResponseTime) ms"
            Write-Host "Version: $($testResult.Version)"
            
            # Exécuter une commande sur le serveur
            Write-Host "`nExécution d'une commande sur le serveur MCP..."
            $result = Invoke-MCPCommand -Command "get_status" -ServerType "local" -Port 8000
            
            Write-Host "Statut du serveur: $($result.status)"
            Write-Host "Uptime: $($result.uptime) secondes"
            
            # Attendre quelques secondes
            Start-Sleep -Seconds 5
            
            # Arrêter le serveur
            Write-Host "`nArrêt du serveur MCP..."
            $stopped = Stop-MCPServer -ServerType "local" -Port 8000
            
            if ($stopped) {
                Write-Host "Serveur MCP arrêté avec succès"
            } else {
                Write-Host "Erreur lors de l'arrêt du serveur MCP"
            }
        } else {
            Write-Host "Serveur MCP non disponible"
        }
    } else {
        Write-Host "Erreur lors du démarrage du serveur MCP: $($server.Error)"
    }

Exemple 4: Utilisation de plusieurs serveurs MCP
----------------------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\MCPManager.psm1" -Force
    
    # Initialiser le gestionnaire MCP
    Initialize-MCPManager -Enabled $true -LogPath ".\logs\mcp_manager.log" -LogLevel "INFO"
    
    # Fonction pour démarrer un serveur MCP
    function Start-TestMCPServer {
        param (
            [string]$ServerType,
            [int]$Port
        )
        
        Write-Host "Démarrage du serveur MCP $ServerType sur le port $Port..."
        $server = Start-MCPServer -ServerType $ServerType -Port $Port -Wait
        
        if ($server.Status -eq "running") {
            Write-Host "Serveur MCP $ServerType démarré avec succès: $($server.Url)"
            Write-Host "ID du processus: $($server.ProcessId)"
            return $server
        } else {
            Write-Host "Erreur lors du démarrage du serveur MCP $ServerType: $($server.Error)"
            return $null
        }
    }
    
    # Démarrer plusieurs serveurs MCP
    $servers = @()
    $servers += Start-TestMCPServer -ServerType "local" -Port 8000
    $servers += Start-TestMCPServer -ServerType "n8n" -Port 5678
    
    # Attendre quelques secondes
    Start-Sleep -Seconds 5
    
    # Tester tous les serveurs
    Write-Host "`nTest de tous les serveurs MCP..."
    foreach ($server in $servers) {
        if ($server -ne $null) {
            $testResult = Test-MCPServer -ServerType $server.ServerType -Port $server.Port -Host $server.Host
            
            if ($testResult.Available) {
                Write-Host "Serveur MCP $($server.ServerType) disponible: $($server.Url)"
                Write-Host "Temps de réponse: $($testResult.ResponseTime) ms"
            } else {
                Write-Host "Serveur MCP $($server.ServerType) non disponible: $($server.Url)"
            }
        }
    }
    
    # Arrêter tous les serveurs
    Write-Host "`nArrêt de tous les serveurs MCP..."
    foreach ($server in $servers) {
        if ($server -ne $null) {
            $stopped = Stop-MCPServer -ProcessId $server.ProcessId
            
            if ($stopped) {
                Write-Host "Serveur MCP $($server.ServerType) arrêté avec succès: $($server.Url)"
            } else {
                Write-Host "Erreur lors de l'arrêt du serveur MCP $($server.ServerType): $($server.Url)"
            }
        }
    }

Exemple 5: Intégration avec des scripts Python
--------------------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\MCPManager.psm1" -Force
    
    # Initialiser le gestionnaire MCP
    Initialize-MCPManager -Enabled $true -LogPath ".\logs\mcp_manager.log" -LogLevel "INFO"
    
    # Vérifier si Python est installé
    $pythonInstalled = Get-Command python -ErrorAction SilentlyContinue
    
    if (-not $pythonInstalled) {
        Write-Host "Python n'est pas installé ou n'est pas dans le PATH"
        return
    }
    
    # Créer un script Python simple pour tester l'intégration
    $pythonScriptPath = ".\scripts\mcp_test.py"
    $pythonScript = @"
import sys
import json
import requests

def main():
    server_type = sys.argv[1] if len(sys.argv) > 1 else "local"
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8000
    
    print(f"Testing MCP server: {server_type} on port {port}")
    
    try:
        response = requests.get(f"http://localhost:{port}/health", timeout=2)
        if response.status_code == 200:
            print(f"Server is healthy: {response.json()}")
            return 0
        else:
            print(f"Server returned status code: {response.status_code}")
            return 1
    except Exception as e:
        print(f"Error connecting to server: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
"@
    
    Set-Content -Path $pythonScriptPath -Value $pythonScript
    Write-Host "Script Python créé: $pythonScriptPath"
    
    # Démarrer un serveur MCP local
    Write-Host "`nDémarrage d'un serveur MCP local..."
    $server = Start-MCPServer -ServerType "local" -Port 8000 -Wait
    
    if ($server.Status -eq "running") {
        Write-Host "Serveur MCP démarré avec succès: $($server.Url)"
        
        # Exécuter le script Python
        Write-Host "`nExécution du script Python..."
        $pythonResult = python $pythonScriptPath "local" 8000
        
        Write-Host "Résultat du script Python:"
        Write-Host $pythonResult
        
        # Arrêter le serveur
        Write-Host "`nArrêt du serveur MCP..."
        $stopped = Stop-MCPServer -ServerType "local" -Port 8000
        
        if ($stopped) {
            Write-Host "Serveur MCP arrêté avec succès"
        } else {
            Write-Host "Erreur lors de l'arrêt du serveur MCP"
        }
    } else {
        Write-Host "Erreur lors du démarrage du serveur MCP: $($server.Error)"
    }
    
    # Supprimer le script Python
    Remove-Item -Path $pythonScriptPath
    Write-Host "`nScript Python supprimé: $pythonScriptPath"
