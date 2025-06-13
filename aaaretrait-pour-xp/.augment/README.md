# Documentation Augment

Ce dossier contient la configuration et les ressources pour l'assistant IA Augment utilisé dans le projet.

## Structure du dossier

```plaintext
.augment/
├── config.json             # Configuration principale d'Augment

├── memories/               # Stockage des memories Augment

│   └── journal_memories.json  # Memories extraites du journal de bord

├── guidelines/             # Règles et standards de développement

│   ├── frontend_rules.md   # Règles pour le développement frontend

│   ├── backend_rules.md    # Règles pour le développement backend

│   ├── project_standards.md # Standards de code globaux

│   └── implementation_steps.md # Instructions d'implémentation

└── context/                # Contexte du projet

    ├── app_flow.md         # Flux applicatif détaillé

    ├── tech_stack.md       # Stack technique et utilisation API

    └── design_system.md    # Système de design (fonts, layout, etc.)

```plaintext
## Utilisation

### Configuration

Le fichier `config.json` définit les sources de données pour Augment, notamment :
- Les sources de memories (journal de bord)
- Les fournisseurs de contexte (guidelines, context, journal_de_bord)

### Guidelines

Les fichiers dans le dossier `guidelines/` fournissent des règles et standards pour le développement :
- **frontend_rules.md** : Règles de style et composants pour le frontend
- **backend_rules.md** : Patterns API et requêtes DB pour le backend
- **project_standards.md** : Standards de code globaux (SOLID, DRY, etc.)
- **implementation_steps.md** : Instructions étape par étape pour l'implémentation

### Context

Les fichiers dans le dossier `context/` fournissent des informations contextuelles sur le projet :
- **app_flow.md** : Flux applicatif détaillé
- **tech_stack.md** : Stack technique et utilisation API
- **design_system.md** : Système de design (fonts, layout, etc.)

## Avantages

Cette structure offre plusieurs avantages :
- Organisation claire des différents aspects du projet
- Séparation des règles par type (frontend, backend, etc.)
- Maintenance facilitée des guidelines et du contexte
- Base de connaissances structurée pour l'IA

## Mise à jour

Pour mettre à jour les guidelines ou le contexte :
1. Modifiez les fichiers Markdown correspondants
2. Augment détectera automatiquement les changements

## Intégration avec VS Code

Pour une expérience optimale avec Augment dans VS Code :
1. Installez l'extension Augment
2. Configurez les paramètres recommandés dans `.vscode/settings.json`
3. Utilisez les raccourcis clavier pour interagir avec Augment
