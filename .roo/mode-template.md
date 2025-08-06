# Template universel Roo-Code — Mode documentaire

> Ce template est multilingue (fr/en), extensible, et intègre la généralisation des hooks événementiels, la matrice capabilities/groupes, les permissions, le versioning et la documentation contextuelle.

---

## Métadonnées principales

- **Nom du mode / Mode name** :  
- **Slug** :  
- **Emoji** :  
- **Description (fr)** :
  > Exemple : Mode dédié à la gestion documentaire collaborative.
- **Description (en)** :
  > Example: Mode dedicated to collaborative document management.
- **Auteur / Author** :  
- **Date de création / Created** :  
- **Dernière modification / Last modified** :  
- **Version** :  
- **Statut** : draft / validated / deprecated

---

## Overrides & Permissions

- **Overrides** :  
  - Création/édition/suppression fichiers : Oui/Non  
  - Restrictions d’extension :  
  - Accès managers/agents :  
  - Export roadmap : Oui/Non  
- **Permissions** :  
  - Utilisateurs autorisés :  
  - Groupes :  
  - Niveau d’accès : lecture / écriture / admin

---

## Hooks événementiels (généralisés)

```yaml
hooks:
  onCreate: |
    # Action à exécuter lors de la création du mode
    # (fr) Exemple : Initialisation des variables, log, notification
    # (en) Example: Variable initialization, logging, notification
  onUpdate: |
    # Action à exécuter lors de la modification du mode
    # (fr) Exemple : Mise à jour des métadonnées, log, notification
    # (en) Example: Metadata update, logging, notification
  onDelete: |
    # Action à exécuter lors de la suppression du mode
    # (fr) Exemple : Archivage, suppression des logs, notification
    # (en) Example: Archiving, log deletion, notification
  onValidate: |
    # Action à exécuter lors de la validation du mode
    # (fr) Exemple : Vérification checklist, log, notification
    # (en) Example: Checklist verification, logging, notification
  onRollback: |
    # Action à exécuter lors d’un rollback
    # (fr) Exemple : Restauration version précédente, log, notification
    # (en) Example: Restore previous version, logging, notification
  onExport: |
    # Action à exécuter lors de l’export roadmap
    # (fr) Exemple : Génération du fichier export, log, notification
    # (en) Example: Export file generation, logging, notification
```

---

## Matrice capabilities/groupes

| Capability / Groupe | Description (fr) | Description (en) | Activé / Enabled | Niveau d’accès / Access level |
|--------------------|------------------|------------------|------------------|------------------------------|
| Edition            | Edition documentaire | Document editing | Oui/Yes         | admin                        |
| Validation         | Validation collaborative | Collaborative validation | Oui/Yes | admin, user |
| Export             | Export roadmap | Roadmap export | Oui/Yes | admin |
| Rollback           | Restauration version | Version restore | Oui/Yes | admin |
| ...                | ...              | ...              | ...              | ...                          |

---

## Sections multilingues

### Français

- **Objectifs** :
  > Décrire les objectifs du mode (ex : faciliter la gestion documentaire collaborative).
- **Workflow principal** :
  > Détailler les étapes clés (ex : création, validation, export, rollback).
- **Critères d’acceptation** :
  > Liste claire des critères (ex : plan validé, export fonctionnel, rollback opérationnel).
- **Cas limites / exceptions** :
  > Exemples de cas particuliers (ex : utilisateur non autorisé, format non supporté).
- **FAQ / Glossaire** :
  > Questions fréquentes et définitions (ex : “Qu’est-ce qu’un rollback ?”).

### English

- **Objectives**:
  > Describe the mode’s objectives (e.g. facilitate collaborative document management).
- **Main workflow**:
  > Detail the main steps (e.g. creation, validation, export, rollback).
- **Acceptance criteria**:
  > Clear criteria list (e.g. validated plan, functional export, operational rollback).
- **Edge cases / exceptions**:
  > Examples of special cases (e.g. unauthorized user, unsupported format).
- **FAQ / Glossary**:
  > Frequently asked questions and definitions (e.g. “What is a rollback?”).

---

## Documentation contextuelle

- **Références croisées** :
  - [`AGENTS.md`](AGENTS.md:1) — Liste des managers et interfaces
  - [`rules.md`](.roo/rules/rules.md:1) — Principes transverses et modèles de modes
  - [`roo-points-extension-index.md`](.roo/rules/roo-points-extension-index.md:1) — Index des points d’extension et overrides
  - [`workflows-matrix.md`](.roo/rules/workflows-matrix.md:1) — Matrice des workflows et modes
  - [`README.md`](.roo/README.md:1) — Guide central Roo-Code
  - Ajouter ici toute référence contextuelle ou documentation générée automatiquement (ex : audit, checklist, synthèse).

---

## Versioning & Rollback

- **Historique des versions** :  
  - v1.0 — Initialisation  
  - v1.1 — Ajout hooks  
  - v1.2 — Matrice capabilities/groupes  
  - v1.3 — Multilingue  
  - v1.4 — Versioning/rollback/logs  
- **Procédure de rollback** :  
  - Décrire comment restaurer une version précédente (Git, UI, etc.)

---

## Logs & Audit

- **Logs d’action** :  
  - Création, modification, suppression, validation, rollback, export
- **Audit** :  
  - Checklist “Ready for prod”, “Security reviewed”, “Rollback OK”

---
