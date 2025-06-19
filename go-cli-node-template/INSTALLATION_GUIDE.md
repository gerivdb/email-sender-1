# N8N Go CLI Node - Installation Guide

## 🎯 Action Atomique 042: Node Template Go CLI - Installation Guide

### 📋 Overview

Ce guide détaille l'installation et la configuration du node N8N personnalisé pour l'intégration Go CLI. Le node permet d'exécuter des binaires Go directement depuis N8N avec gestion complète des paramètres, erreurs et formats de données.

### 🔧 Prerequisites

- **N8N** : Version 0.180.0 ou supérieure
- **Node.js** : Version 16.x ou supérieure  
- **TypeScript** : Version 4.8.4 ou supérieure
- **Go CLI Binary** : Binaire Go compilé avec les commandes `execute`, `validate`, `status`, `health`

### 📦 Installation Steps

#### 1. Build du Node

```bash
# Navigate to the node template directory
cd go-cli-node-template

# Install dependencies
npm install

# Build the TypeScript files
npm run build

# Verify build output
ls -la dist/
```

#### 2. Installation dans N8N

**Méthode A: Installation Locale**

```bash
# Copy to N8N custom nodes directory
cp -r dist/* ~/.n8n/custom/

# Restart N8N
n8n start
```

**Méthode B: Installation via npm (Recommandée)**

```bash
# Package the node
npm pack

# Install in N8N environment
cd ~/.n8n/
npm install /path/to/n8n-nodes-go-cli-1.0.0.tgz

# Restart N8N
n8n restart
```

#### 3. Configuration du Go CLI Binary

```bash
# Make sure Go CLI binary is executable
chmod +x /usr/local/bin/n8n-go-cli

# Test CLI functionality
/usr/local/bin/n8n-go-cli health
/usr/local/bin/n8n-go-cli status
```

### 🎛️ Node Configuration

#### Paramètres Principaux

| Paramètre | Type | Description | Défaut |
|-----------|------|-------------|--------|
| **Operation** | Options | Type d'opération (execute, validate, status, health) | execute |
| **CLI Binary Path** | String | Chemin vers le binaire Go | /usr/local/bin/n8n-go-cli |
| **Command** | String | Commande Go CLI à exécuter | - |
| **Arguments** | Collection | Arguments de ligne de commande | [] |
| **Timeout** | Number | Timeout en secondes | 30 |

#### Gestion des Données

- **Input Processing** : JSON, Arguments, ou Aucun
- **Output Format** : JSON, Raw Text, ou Lines Array
- **Environment Variables** : Variables d'environnement personnalisées

#### Options Avancées

- **Working Directory** : Répertoire de travail
- **Error Handling** : Stop, Continue, ou Retry
- **Retry Count** : Nombre de tentatives (si retry activé)
- **Enable Tracing** : Debugging et tracing

### 🔄 Utilisation du Node

#### Exemple Basique

```json
{
  "operation": "execute",
  "binaryPath": "/usr/local/bin/n8n-go-cli",
  "command": "email-process",
  "arguments": [
    {
      "name": "template",
      "value": "welcome-email",
      "type": "string"
    },
    {
      "name": "count",
      "value": "100",
      "type": "number"
    }
  ],
  "inputProcessing": "json",
  "outputFormat": "json",
  "timeout": 60
}
```

#### Workflow Example

```json
{
  "nodes": [
    {
      "parameters": {
        "operation": "execute",
        "binaryPath": "/usr/local/bin/n8n-go-cli",
        "command": "email-send",
        "arguments": [
          {
            "name": "batch-size",
            "value": "50",
            "type": "number"
          }
        ],
        "inputProcessing": "json",
        "outputFormat": "json",
        "environmentVariables": {
          "variable": [
            {
              "name": "SMTP_HOST",
              "value": "smtp.example.com"
            }
          ]
        }
      },
      "type": "n8n-nodes-go-cli.goCli",
      "typeVersion": 1,
      "position": [400, 300]
    }
  ]
}
```

### 🚨 Error Handling

#### Types d'Erreurs Gérées

1. **CLI Execution Errors** : Erreurs d'exécution du binaire
2. **Timeout Errors** : Dépassement de timeout
3. **JSON Parse Errors** : Erreurs de parsing JSON
4. **File Not Found** : Binaire introuvable
5. **Permission Errors** : Problèmes de permissions

#### Stratégies de Récupération

- **Stop on Error** : Arrêt immédiat (défaut)
- **Continue on Error** : Continue avec erreur dans output
- **Retry on Error** : Retry automatique (configurable)

### 🧪 Testing

#### Test Node Loading

```bash
# Start N8N in development mode
N8N_LOG_LEVEL=debug n8n start

# Check logs for node loading
grep "Go CLI" ~/.n8n/logs/n8n.log
```

#### Test CLI Integration

```bash
# Test direct CLI execution
echo '{"test": "data"}' | /usr/local/bin/n8n-go-cli execute test-command

# Expected output format
{
  "success": true,
  "result": "processed",
  "timestamp": "2025-06-19T12:00:00Z"
}
```

### 🔒 Security Considerations

#### Binary Security

- **Path Validation** : Vérifier que le chemin binaire est sécurisé
- **Permission Check** : S'assurer que les permissions sont minimales
- **Input Sanitization** : Validation des arguments d'entrée

#### Environment Variables

- **Secret Handling** : Utiliser N8N credentials pour les secrets
- **Variable Scoping** : Limiter la portée des variables d'environnement
- **Logging** : Éviter de logger des données sensibles

### 📊 Monitoring & Performance

#### Métriques Disponibles

- **Execution Time** : Temps d'exécution des commandes
- **Success Rate** : Taux de succès des exécutions
- **Error Rate** : Taux d'erreurs par type
- **Resource Usage** : Utilisation mémoire/CPU

#### Logs et Debugging

```bash
# Enable debug logging
export N8N_LOG_LEVEL=debug

# Check CLI execution logs
tail -f ~/.n8n/logs/n8n.log | grep "Go CLI"

# Monitor resource usage
top -p $(pgrep n8n)
```

### 🔧 Troubleshooting

#### Problèmes Courants

1. **Node Not Loading**

   ```bash
   # Check N8N custom nodes directory
   ls -la ~/.n8n/custom/
   # Verify file permissions
   chmod -R 755 ~/.n8n/custom/
   ```

2. **CLI Binary Not Found**

   ```bash
   # Check binary path and permissions
   which n8n-go-cli
   chmod +x /usr/local/bin/n8n-go-cli
   ```

3. **JSON Parse Errors**

   ```bash
   # Test CLI output format
   /usr/local/bin/n8n-go-cli execute test | jq .
   ```

4. **Timeout Issues**

   ```bash
   # Increase timeout in node configuration
   # Monitor CLI execution time
   time /usr/local/bin/n8n-go-cli execute long-command
   ```

### 🚀 Advanced Configuration

#### Custom Binary Paths

```javascript
// Support for multiple CLI binaries
const binaryMappings = {
  'email': '/usr/local/bin/email-cli',
  'vector': '/usr/local/bin/vector-cli',
  'analytics': '/usr/local/bin/analytics-cli'
};
```

#### Environment-Specific Configuration

```yaml
# config/environments.yml
development:
  binary_path: "/usr/local/bin/n8n-go-cli-dev"
  timeout: 60
  debug: true

production:
  binary_path: "/usr/local/bin/n8n-go-cli"
  timeout: 30
  debug: false
```

### ✅ Validation Checklist

- [ ] Node apparaît dans la liste N8N
- [ ] CLI binary est exécutable
- [ ] Commandes de base fonctionnent (health, status)
- [ ] JSON input/output correctement traité
- [ ] Error handling fonctionne
- [ ] Timeout configuration respectée
- [ ] Environment variables correctement passées
- [ ] Logs et monitoring opérationnels

### 📝 Next Steps

Après installation réussie :

1. **Tester avec données réelles**
2. **Configurer monitoring**
3. **Optimiser performance**
4. **Implémenter workflows hybrides**
5. **Documenter cas d'usage**

---

**Status** : ✅ Installation Guide Complete  
**Action Atomique 042** : Node Template Go CLI - TERMINÉ
