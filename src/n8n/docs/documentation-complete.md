# Documentation Complète - n8n

## Introduction

Cette documentation détaille la structure, l'installation, la configuration et l'utilisation de n8n dans le cadre du projet EMAIL_SENDER_1. Elle couvre également l'intégration avec l'IDE et Augment.

## Structure du projet

```plaintext
n8n/
├── cmd/                  # Scripts de commande Windows

│   ├── install/          # Scripts d'installation

│   ├── setup/            # Scripts de configuration

│   ├── start/            # Scripts de démarrage

│   ├── stop/             # Scripts d'arrêt

│   └── utils/            # Scripts utilitaires

├── config/               # Configuration n8n

├── data/                 # Données n8n

│   ├── credentials/      # Credentials chiffrées

│   ├── database/         # Base de données SQLite

│   └── storage/          # Stockage binaire

├── docs/                 # Documentation

├── integrations/         # Intégrations avec d'autres systèmes

├── n8n-source-old/       # Code source original de n8n (référence)

├── scripts/              # Scripts PowerShell

│   ├── integrations/     # Scripts d'intégration

│   ├── setup/            # Scripts d'installation

│   ├── sync/             # Scripts de synchronisation

│   └── utils/            # Utilitaires communs

└── workflows/            # Workflows n8n

    ├── archive/          # Workflows archivés

    ├── ide/              # Workflows utilisés par l'IDE

    └── local/            # Workflows utilisés par n8n local

```plaintext
## Installation et configuration

### Prérequis

- Node.js 14.x ou supérieur
- npm 6.x ou supérieur
- PowerShell 5.1 ou supérieur

### Installation

Pour installer n8n, exécutez le script d'installation :

```plaintext
.\n8n\cmd\install\install-n8n-local.cmd
```plaintext
Ce script effectue les opérations suivantes :
1. Installe n8n globalement via npm
2. Configure les variables d'environnement nécessaires
3. Initialise la base de données SQLite
4. Crée les dossiers nécessaires pour les workflows et les données

### Configuration

La configuration de n8n est stockée dans le fichier `n8n\config\n8n-config.json`. Ce fichier contient les paramètres suivants :

- `port` : Port sur lequel n8n sera accessible (par défaut : 5678)
- `userFolder` : Dossier contenant les données utilisateur
- `database` : Configuration de la base de données
- `credentials` : Configuration des credentials
- `workflows` : Chemin vers le dossier des workflows
- `logs` : Configuration des logs
- `binaryDataManager` : Configuration du stockage binaire

Pour modifier la configuration, éditez ce fichier ou utilisez les variables d'environnement correspondantes.

## Démarrage et arrêt

### Démarrage

Pour démarrer n8n avec la synchronisation IDE, exécutez :

```plaintext
.\start-n8n.cmd
```plaintext
ou

```plaintext
.\n8n\cmd\start\start-n8n-with-ide-sync.cmd
```plaintext
Pour démarrer n8n sans authentification :

```plaintext
.\n8n\cmd\start\start-n8n-no-auth.cmd
```plaintext
### Arrêt

Pour arrêter n8n, exécutez :

```plaintext
.\n8n\cmd\stop\stop-n8n.cmd
```plaintext
## Workflows

Les workflows sont organisés en trois catégories :

1. **Workflows locaux** (`n8n\workflows\local`) : Workflows utilisés par l'instance n8n locale
2. **Workflows IDE** (`n8n\workflows\ide`) : Workflows utilisés par l'IDE
3. **Workflows archivés** (`n8n\workflows\archive`) : Workflows archivés pour référence

### Synchronisation des workflows

Les workflows sont automatiquement synchronisés entre n8n et l'IDE lorsque vous utilisez le script `start-n8n-with-ide-sync.cmd`.

Pour synchroniser manuellement les workflows, exécutez :

```powershell
.\n8n\scripts\sync\sync-workflows.ps1 -Direction "both" -Environment "all"
```plaintext
Options de direction :
- `to-n8n` : Synchronise les workflows des dossiers locaux vers n8n
- `from-n8n` : Synchronise les workflows de n8n vers les dossiers locaux
- `both` : Synchronisation bidirectionnelle (par défaut)

Options d'environnement :
- `local` : Synchronise uniquement les workflows locaux (par défaut)
- `ide` : Synchronise uniquement les workflows de l'IDE
- `all` : Synchronise tous les workflows

## Intégration avec Augment

### Configuration de l'API key

Pour utiliser l'API n8n avec Augment, vous devez créer une API key :

```plaintext
.\n8n\cmd\setup\create-api-key.cmd
```plaintext
Cette API key sera enregistrée dans le fichier `n8n\config\api-key.json`.

### Utilisation de l'intégration

Le script `augment-integration.ps1` permet à Augment de créer et de modifier des workflows n8n directement depuis l'IDE.

#### Lister les workflows

```powershell
.\n8n\scripts\integrations\augment-integration.ps1 -Action "list-workflows"
```plaintext
#### Récupérer un workflow

```powershell
.\n8n\scripts\integrations\augment-integration.ps1 -Action "get-workflow" -WorkflowId "123" -OutputPath "workflow.json"
```plaintext
#### Créer un workflow

```powershell
.\n8n\scripts\integrations\augment-integration.ps1 -Action "create-workflow" -WorkflowName "Mon workflow" -WorkflowData '{"nodes":[],"connections":{}}'
```plaintext
#### Mettre à jour un workflow

```powershell
.\n8n\scripts\integrations\augment-integration.ps1 -Action "update-workflow" -WorkflowId "123" -WorkflowData '{"nodes":[],"connections":{}}'
```plaintext
### Intégration dans les scripts Augment

Pour intégrer n8n avec Augment, vous pouvez utiliser les commandes suivantes dans vos workflows Augment :

```javascript
// Lister les workflows
const { exec } = require('child_process');
exec('powershell -ExecutionPolicy Bypass -File "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/n8n/scripts/integrations/augment-integration.ps1" -Action "list-workflows" -OutputPath "workflows.json"', (error, stdout, stderr) => {
  if (error) {
    console.error(`Erreur: ${error.message}`);
    return;
  }
  
  // Lire le fichier de sortie
  const fs = require('fs');
  const workflows = JSON.parse(fs.readFileSync('workflows.json', 'utf8'));
  console.log(workflows);
});

// Créer un workflow
const workflowData = {
  nodes: [],
  connections: {}
};
exec(`powershell -ExecutionPolicy Bypass -File "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/n8n/scripts/integrations/augment-integration.ps1" -Action "create-workflow" -WorkflowName "Workflow créé par Augment" -WorkflowData '${JSON.stringify(workflowData)}'`, (error, stdout, stderr) => {
  if (error) {
    console.error(`Erreur: ${error.message}`);
    return;
  }
  console.log(`Workflow créé: ${stdout}`);
});
```plaintext
## Bonnes pratiques

### Organisation des workflows

- Utilisez des noms descriptifs pour vos workflows
- Ajoutez des tags pour catégoriser vos workflows (`local`, `ide`, `augment`)
- Documentez vos workflows avec des commentaires

### Sécurité

- Ne stockez pas de credentials sensibles directement dans les workflows
- Utilisez les variables d'environnement pour les informations sensibles
- Activez l'authentification en production

### Performance

- Limitez le nombre de nœuds dans un workflow
- Utilisez des webhooks plutôt que des polling pour les événements
- Optimisez les requêtes API pour réduire la charge

## Dépannage

### n8n n'est pas en cours d'exécution

Si vous recevez l'erreur "n8n n'est pas en cours d'exécution", assurez-vous que n8n est démarré avant d'utiliser les scripts d'intégration.

```powershell
.\n8n\cmd\start\start-n8n-local.cmd
```plaintext
### Erreur d'authentification

Si vous recevez une erreur d'authentification, assurez-vous que vous avez configuré correctement l'API key dans le fichier `n8n/config/api-key.json`.

```json
{
  "apiKey": "votre-api-key"
}
```plaintext
### Problèmes de synchronisation

Si vous rencontrez des problèmes de synchronisation, vérifiez les points suivants :

1. Assurez-vous que les chemins dans le fichier `n8n/config/n8n-config.json` sont corrects
2. Vérifiez que les dossiers de workflows existent
3. Assurez-vous que n8n a les permissions nécessaires pour accéder aux dossiers de workflows

### Réinitialisation

Si vous rencontrez des problèmes persistants, vous pouvez réinitialiser n8n :

```plaintext
.\n8n\cmd\utils\reset-n8n.cmd
```plaintext
Ce script supprime la base de données et les credentials, mais préserve vos workflows.

## Ressources additionnelles

- [Documentation officielle n8n](https://docs.n8n.io/)
- [API Reference n8n](https://docs.n8n.io/api/api-reference/)
- [GitHub n8n](https://github.com/n8n-io/n8n)

## Conclusion

Cette documentation fournit toutes les informations nécessaires pour utiliser n8n dans le cadre du projet EMAIL_SENDER_1. Elle couvre l'installation, la configuration, l'utilisation et l'intégration avec l'IDE et Augment.

Pour toute question ou problème, consultez le journal des erreurs ou le journal de bord pour des informations supplémentaires.
