# Guide d'utilisation du serveur de passerelle API MCP

Ce guide explique comment utiliser le serveur de passerelle API MCP.

## Introduction

Le serveur de passerelle API MCP est un composant central qui permet de gérer et de rediriger les requêtes API vers les différents services MCP. Il sert de point d'entrée unique pour toutes les API MCP et offre des fonctionnalités telles que l'authentification, l'autorisation, la journalisation et la limitation de débit.

## Installation

### Prérequis

- PowerShell 5.1 ou supérieur
- Modules MCP installés

### Installation automatique

La méthode la plus simple pour installer le serveur de passerelle API MCP est d'utiliser le script d'installation :

```batch
.\mcp\cmd\utils\install-api-gateway.cmd
```plaintext
Ce script installera le serveur de passerelle API MCP et créera la structure de dossiers nécessaire.

### Installation manuelle

Si vous préférez installer le serveur de passerelle API MCP manuellement, suivez ces étapes :

1. Copiez le fichier `api-gateway.ps1` dans le dossier `mcp\core\server`
2. Assurez-vous que les modules MCP sont installés
3. Configurez le serveur selon vos besoins

## Configuration

Le serveur de passerelle API MCP peut être configuré en modifiant les paramètres suivants :

- **Port** : Port sur lequel le serveur écoute (par défaut : 8000)
- **LogLevel** : Niveau de journalisation (DEBUG, INFO, WARNING, ERROR)
- **MaxConnections** : Nombre maximum de connexions simultanées
- **Timeout** : Délai d'attente en secondes
- **AllowedIPs** : Liste des adresses IP autorisées
- **EnableCompression** : Activer ou désactiver la compression

Exemple de configuration :

```powershell
$serverConfig = @{
    Port = 8000
    LogLevel = "INFO"
    MaxConnections = 10
    Timeout = 30
    AllowedIPs = @("127.0.0.1", "::1")
    EnableCompression = $true
}
```plaintext
## Utilisation

### Démarrage du serveur

Pour démarrer le serveur de passerelle API MCP, exécutez la commande suivante :

```powershell
.\mcp\core\server\api-gateway.ps1 -Port 8000 -LogLevel INFO
```plaintext
### Arrêt du serveur

Pour arrêter le serveur, appuyez sur `Ctrl+C` dans la console où le serveur est en cours d'exécution.

### Vérification de l'état du serveur

Pour vérifier l'état du serveur, vous pouvez utiliser le client API MCP :

```powershell
.\mcp\core\client\api-client.ps1 -ServerUrl "http://localhost:8000"
```plaintext
## API disponibles

Le serveur de passerelle API MCP expose les API suivantes :

### API d'information

- **Endpoint** : `/api/info`
- **Méthode** : GET
- **Description** : Obtient des informations sur les API disponibles
- **Exemple** :
  ```powershell
  Invoke-ApiRequest -Method "GET" -Endpoint "/api/info"
  ```

### API de statut

- **Endpoint** : `/api/status/{api_name}`
- **Méthode** : GET
- **Description** : Vérifie l'état d'une API
- **Paramètres** :
  - `api_name` : Nom de l'API à vérifier
- **Exemple** :
  ```powershell
  Invoke-ApiRequest -Method "GET" -Endpoint "/api/status/users"
  ```

### API de redirection

- **Endpoint** : `/api/proxy/{api_name}/{endpoint}`
- **Méthode** : GET, POST, PUT, DELETE
- **Description** : Redirige une requête vers une API
- **Paramètres** :
  - `api_name` : Nom de l'API
  - `endpoint` : Point de terminaison de l'API
- **Exemple** :
  ```powershell
  Invoke-ApiRequest -Method "GET" -Endpoint "/api/proxy/users/list"
  ```

## Outils disponibles

Le serveur de passerelle API MCP fournit les outils suivants :

### get_api_info

- **Description** : Obtient des informations sur les API disponibles
- **Exemple** :
  ```powershell
  Invoke-MCPTool -Name "get_api_info" -Params @{}
  ```

### check_api_status

- **Description** : Vérifie l'état d'une API
- **Paramètres** :
  - `api_name` : Nom de l'API à vérifier
- **Exemple** :
  ```powershell
  Invoke-MCPTool -Name "check_api_status" -Params @{api_name="users"}
  ```

### proxy_api_request

- **Description** : Redirige une requête vers une API
- **Paramètres** :
  - `api_name` : Nom de l'API
  - `endpoint` : Point de terminaison de l'API
- **Exemple** :
  ```powershell
  Invoke-MCPTool -Name "proxy_api_request" -Params @{api_name="users"; endpoint="/list"}
  ```

## Journalisation

Le serveur de passerelle API MCP utilise un système de journalisation configurable. Les messages de journal sont affichés dans la console avec des couleurs différentes selon le niveau de journalisation :

- **DEBUG** : Messages de débogage (affiché uniquement si le niveau de journalisation est DEBUG)
- **INFO** : Messages d'information (affiché si le niveau de journalisation est DEBUG ou INFO)
- **WARNING** : Messages d'avertissement (affiché si le niveau de journalisation est DEBUG, INFO ou WARNING)
- **ERROR** : Messages d'erreur (toujours affiché)

Exemple de message de journal :

```plaintext
[2023-05-15 12:34:56] [INFO] Démarrage du serveur api-gateway sur le port 8000...
```plaintext
## Dépannage

### Le serveur ne démarre pas

- Vérifiez que le port n'est pas déjà utilisé par une autre application
- Vérifiez que vous avez les droits d'administrateur
- Vérifiez que les modules MCP sont installés

### Erreur de connexion

- Vérifiez que le serveur est en cours d'exécution
- Vérifiez que vous utilisez la bonne URL
- Vérifiez que votre adresse IP est autorisée

### Erreur d'authentification

- Vérifiez que vous utilisez la bonne clé API
- Vérifiez que la clé API n'a pas expiré

## Exemples

### Exemple 1 : Démarrer le serveur avec des paramètres personnalisés

```powershell
.\mcp\core\server\api-gateway.ps1 -Port 8080 -LogLevel DEBUG
```plaintext
### Exemple 2 : Obtenir des informations sur les API disponibles

```powershell
$client = .\mcp\core\client\api-client.ps1 -ServerUrl "http://localhost:8000"
$client.get-api-info
```plaintext
### Exemple 3 : Vérifier l'état d'une API

```powershell
$client = .\mcp\core\client\api-client.ps1 -ServerUrl "http://localhost:8000"
$client.check-api-status users
```plaintext
### Exemple 4 : Rediriger une requête vers une API

```powershell
$client = .\mcp\core\client\api-client.ps1 -ServerUrl "http://localhost:8000"
$client.proxy-request users /list
```plaintext
## Références

- [Documentation MCP](../README.md)
- [Guide d'utilisation du client API MCP](api-client-guide.md)
- [Guide d'utilisation des modules MCP](../api/MCPApiUtils.md)

## Support

Si vous rencontrez des problèmes avec le serveur de passerelle API MCP, vous pouvez contacter l'équipe MCP ou consulter les ressources suivantes :

- [Guide de résolution des problèmes](troubleshooting-guide.md)
- [Forum de discussion MCP](https://example.com/mcp-forum)
- [Canal Slack MCP](https://example.com/mcp-slack)
