# Intégration n8n avec Augment

Ce document décrit comment intégrer n8n avec Augment pour permettre la création et la modification de workflows n8n directement depuis l'IDE.

## Prérequis

- n8n installé et configuré
- PowerShell 5.1 ou supérieur
- Accès à l'API n8n

## Structure des dossiers

```plaintext
n8n/
├── cmd/                  # Scripts de commande Windows

├── config/               # Configuration n8n

├── data/                 # Données n8n

├── docs/                 # Documentation

├── integrations/         # Intégrations avec d'autres systèmes

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
## Démarrage de n8n avec synchronisation IDE

Pour démarrer n8n avec la synchronisation automatique des workflows avec l'IDE, utilisez le script suivant :

```powershell
.\n8n\cmd\start\start-n8n-with-ide-sync.cmd
```plaintext
Ce script démarre n8n sans authentification et configure la synchronisation automatique des workflows entre n8n et l'IDE.

## Utilisation de l'intégration Augment

Le script `augment-integration.ps1` permet à Augment de créer et de modifier des workflows n8n directement depuis l'IDE.

### Lister les workflows

```powershell
.\n8n\scripts\integrations\augment-integration.ps1 -Action "list-workflows"
```plaintext
### Récupérer un workflow

```powershell
.\n8n\scripts\integrations\augment-integration.ps1 -Action "get-workflow" -WorkflowId "123" -OutputPath "workflow.json"
```plaintext
### Créer un workflow

```powershell
.\n8n\scripts\integrations\augment-integration.ps1 -Action "create-workflow" -WorkflowName "Mon workflow" -WorkflowData '{"nodes":[],"connections":{}}'
```plaintext
### Mettre à jour un workflow

```powershell
.\n8n\scripts\integrations\augment-integration.ps1 -Action "update-workflow" -WorkflowId "123" -WorkflowData '{"nodes":[],"connections":{}}'
```plaintext
## Synchronisation des workflows

Le script `sync-workflows.ps1` permet de synchroniser les workflows entre n8n et l'IDE de manière bidirectionnelle.

```powershell
.\n8n\scripts\sync\sync-workflows.ps1 -Direction "both" -Environment "all"
```plaintext
### Options de direction

- `to-n8n` : Synchronise les workflows des dossiers locaux vers n8n
- `from-n8n` : Synchronise les workflows de n8n vers les dossiers locaux
- `both` : Synchronisation bidirectionnelle (par défaut)

### Options d'environnement

- `local` : Synchronise uniquement les workflows locaux (par défaut)
- `ide` : Synchronise uniquement les workflows de l'IDE
- `all` : Synchronise tous les workflows

## Intégration avec Augment

Pour intégrer n8n avec Augment, vous pouvez utiliser les commandes suivantes dans vos workflows Augment :

```javascript
// Lister les workflows
const { exec } = require('child_process');
exec('powershell -ExecutionPolicy Bypass -File "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/n8n/scripts/integrations/augment-integration.ps1" -Action "list-workflows" -OutputPath "workflows.json"', (error, stdout, stderr) => {
  if (error) {
    console.error(`Erreur: ${error.message}`);
    return;
  }
  if (stderr) {
    console.error(`Stderr: ${stderr}`);
    return;
  }
  console.log(`Stdout: ${stdout}`);
  
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
Vous pouvez créer une API key en utilisant le script suivant :

```powershell
.\n8n\scripts\setup\create-api-key.ps1
```plaintext
### Problèmes de synchronisation

Si vous rencontrez des problèmes de synchronisation, vérifiez les points suivants :

1. Assurez-vous que les chemins dans le fichier `n8n/config/n8n-config.json` sont corrects
2. Vérifiez que les dossiers de workflows existent
3. Assurez-vous que n8n a les permissions nécessaires pour accéder aux dossiers de workflows
