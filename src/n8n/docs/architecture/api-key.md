# Utilisation de l'API Key pour n8n

Ce document explique comment configurer et utiliser l'API Key pour accéder à l'API REST de n8n.

## Vue d'ensemble

L'API Key est un mécanisme d'authentification simple pour accéder à l'API REST de n8n. Elle permet de :

1. Sécuriser l'accès à l'API REST de n8n
2. Éviter l'authentification par nom d'utilisateur et mot de passe
3. Faciliter l'intégration avec d'autres systèmes

## Configuration de l'API Key

### Génération d'une API Key

Pour générer et configurer une API Key, utilisez le script `configure-n8n-api-key.ps1` :

```plaintext
.\configure-n8n-api-key.cmd
```plaintext
Ce script :
1. Génère une API Key sécurisée (32 caractères hexadécimaux)
2. Configure l'API Key dans le fichier `n8n/core/n8n-config.json`
3. Configure l'API Key dans le fichier `n8n/.env`

Vous pouvez également spécifier votre propre API Key :

```plaintext
.\configure-n8n-api-key.cmd -ApiKey "votre-api-key"
```plaintext
### Configuration manuelle

Si vous préférez configurer l'API Key manuellement, vous devez :

1. Modifier le fichier `n8n/core/n8n-config.json` :
   ```json
   {
     "security": {
       "apiKey": {
         "value": "votre-api-key",
         "enabled": true
       }
     }
   }
   ```

2. Modifier le fichier `n8n/.env` :
   ```
   N8N_API_KEY=votre-api-key
   ```

## Test de l'API Key

Pour tester l'API Key, utilisez le script `test-n8n-api-key.ps1` :

```plaintext
.\test-n8n-api-key.cmd
```plaintext
Ce script teste l'accès à différents endpoints de l'API REST de n8n en utilisant l'API Key configurée.

Vous pouvez également spécifier une API Key différente pour le test :

```plaintext
.\test-n8n-api-key.cmd -ApiKey "votre-api-key"
```plaintext
## Utilisation de l'API Key

### En-tête HTTP

Pour utiliser l'API Key avec l'API REST de n8n, ajoutez l'en-tête HTTP suivant à vos requêtes :

```plaintext
X-N8N-API-KEY: votre-api-key
```plaintext
### Exemples d'utilisation

#### Avec curl

```bash
curl -X GET http://localhost:5678/api/v1/workflows -H "X-N8N-API-KEY: votre-api-key"
```plaintext
#### Avec PowerShell

```powershell
Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows" -Method Get -Headers @{"X-N8N-API-KEY" = "votre-api-key"}
```plaintext
#### Avec JavaScript (fetch)

```javascript
fetch('http://localhost:5678/api/v1/workflows', {
  method: 'GET',
  headers: {
    'X-N8N-API-KEY': 'votre-api-key'
  }
})
.then(response => response.json())
.then(data => console.log(data));
```plaintext
#### Avec Python (requests)

```python
import requests

headers = {
    'X-N8N-API-KEY': 'votre-api-key'
}

response = requests.get('http://localhost:5678/api/v1/workflows', headers=headers)
data = response.json()
print(data)
```plaintext
## Scripts d'utilisation de l'API

### Importation de workflows

Pour importer des workflows via l'API, utilisez le script `import-workflow-api.ps1` :

```plaintext
.\import-workflow-api.cmd -WorkflowFile "path/to/workflow.json" -Tags "tag1,tag2" -Active $true
```plaintext
Vous pouvez également importer tous les workflows d'un dossier :

```plaintext
.\import-workflow-api.cmd -WorkflowFile "path/to/workflows/folder" -Tags "tag1,tag2" -Active $true
```plaintext
### Liste des workflows

Pour lister les workflows via l'API, utilisez le script `list-workflows-api.ps1` :

```plaintext
.\list-workflows-api.cmd
```plaintext
Vous pouvez filtrer les workflows par état d'activation et par tags :

```plaintext
.\list-workflows-api.cmd -Active $true -Tags "tag1,tag2"
```plaintext
## Résolution des problèmes

### L'API Key n'est pas reconnue

Si l'API Key n'est pas reconnue, vérifiez les points suivants :

1. Vérifiez que l'API Key est correctement configurée dans les fichiers `n8n/core/n8n-config.json` et `n8n/.env`
2. Vérifiez que n8n est configuré pour utiliser l'API Key (section `security.apiKey.enabled` à `true` dans le fichier de configuration)
3. Vérifiez que vous utilisez le bon en-tête HTTP (`X-N8N-API-KEY`)
4. Redémarrez n8n pour appliquer les modifications de configuration

### Erreur 401 Unauthorized

Si vous recevez une erreur 401 Unauthorized, cela signifie que l'API Key n'est pas valide ou n'est pas correctement configurée. Vérifiez les points suivants :

1. Vérifiez que vous utilisez la bonne API Key
2. Vérifiez que l'API Key est correctement configurée dans les fichiers de configuration
3. Vérifiez que l'authentification par API Key est activée dans n8n

### Erreur 404 Not Found

Si vous recevez une erreur 404 Not Found, cela signifie que l'endpoint que vous essayez d'accéder n'existe pas. Vérifiez les points suivants :

1. Vérifiez que vous utilisez la bonne URL
2. Vérifiez que n8n est en cours d'exécution
3. Vérifiez que vous utilisez la bonne version de l'API (v1)

## Bonnes pratiques

1. **Sécurité** : Utilisez une API Key forte et ne la partagez pas
2. **Rotation** : Changez régulièrement l'API Key pour améliorer la sécurité
3. **Isolation** : Utilisez des API Keys différentes pour différents environnements (développement, test, production)
4. **Surveillance** : Surveillez l'utilisation de l'API Key pour détecter les abus
5. **Limitation** : Limitez l'accès à l'API Key aux personnes et systèmes qui en ont besoin
