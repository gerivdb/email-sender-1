# Système de remédiation n8n

Ce dossier contient un ensemble d'outils pour gérer, surveiller et maintenir une installation n8n. Il offre une interface unifiée pour toutes les fonctionnalités nécessaires à la gestion de n8n, incluant le démarrage, l'arrêt, la surveillance, l'importation de workflows et les diagnostics.

## Fonctionnalités

- **Gestion du cycle de vie** : Démarrage, arrêt et redémarrage de n8n
- **Surveillance et diagnostics** : Surveillance du port et de l'API, test de structure, vérification des workflows
- **Gestion des workflows** : Importation automatique des workflows, importation en masse, vérification de la présence des workflows
- **Maintenance** : Rotation des logs, sauvegarde des workflows, planification des tâches
- **Tests d'intégration** : Exécution de scénarios de test, génération de rapports
- **Interface utilisateur** : Interface interactive, tableau de bord

## Structure

La structure du dossier est organisée de manière à séparer clairement les différents composants et à faciliter la maintenance et l'intégration avec d'autres systèmes.

```plaintext
n8n/
├── automation/           # Scripts d'automatisation

│   ├── deployment/      # Scripts de déploiement

│   ├── monitoring/      # Scripts de surveillance

│   ├── diagnostics/     # Scripts de diagnostic

│   ├── notification/    # Scripts de notification

│   ├── tests/           # Tests d'intégration

│   ├── maintenance/     # Scripts de maintenance

│   ├── dashboard/       # Tableau de bord

│   └── n8n-manager.ps1  # Script d'orchestration principal

├── config/              # Fichiers de configuration

├── core/                # Composants principaux

│   ├── workflows/       # Workflows n8n

│   └── n8n-config.json  # Configuration n8n

├── data/                # Données n8n

│   ├── .n8n/           # Dossier .n8n

│   │   └── workflows/  # Workflows n8n

│   └── n8n.pid         # Fichier PID

├── docs/                # Documentation

│   ├── architecture/   # Documentation technique

│   ├── examples/       # Exemples d'utilisation

│   └── user-guide.md   # Guide d'utilisation

└── logs/                # Fichiers de log

    ├── n8n.log         # Log n8n

    ├── n8n-status.log  # Log de surveillance

    └── history/        # Historique des logs

```plaintext
## Utilisation

### Interface principale

Pour lancer l'interface principale, exécutez :

```plaintext
.\n8n-manager.cmd
```plaintext
### Scripts de raccourcis

Des scripts de raccourcis sont disponibles pour les actions les plus courantes :

- `n8n-start.cmd` : Démarre n8n
- `n8n-stop.cmd` : Arrête n8n
- `n8n-restart.cmd` : Redémarre n8n
- `n8n-status.cmd` : Vérifie l'état de n8n
- `n8n-import.cmd` : Importe des workflows
- `n8n-test.cmd` : Exécute les tests d'intégration

### Exécution directe d'une action

Pour exécuter directement une action sans passer par le menu, utilisez le paramètre `-Action` :

```plaintext
.\n8n-manager.cmd -Action start
```plaintext
Actions disponibles :
- `start` : Démarre n8n
- `stop` : Arrête n8n
- `restart` : Redémarre n8n
- `status` : Vérifie l'état de n8n
- `import` : Importe des workflows
- `verify` : Vérifie la présence des workflows
- `test` : Teste la structure
- `dashboard` : Affiche le tableau de bord
- `maintenance` : Exécute la maintenance

## Documentation

La documentation complète est disponible dans le dossier `docs` :

- [Guide d'utilisation](docs/user-guide.md) - Guide complet pour l'utilisation du système
- [Exemples d'utilisation courants](docs/examples/common-scenarios.md) - Exemples pratiques pour les scénarios courants
- [Vue d'ensemble du système](docs/architecture/system-overview.md) - Architecture globale du système
- [n8n Manager](docs/architecture/n8n-manager.md) - Documentation du script d'orchestration principal
- [Surveillance du port et de l'API](docs/architecture/port-api-monitoring.md) - Documentation de la surveillance
- [Test de structure](docs/architecture/structure-test.md) - Documentation des tests de structure
- [Tests d'intégration](docs/architecture/integration-tests.md) - Documentation des tests d'intégration
- [Vérification des workflows](docs/architecture/workflow-verification.md) - Documentation de la vérification des workflows
