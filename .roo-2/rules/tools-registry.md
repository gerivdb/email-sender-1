# Registre des outils Roo utilisables par les modes

## 📋 Introduction

Ce registre centralise **tous les outils, commandes, plugins et interfaces** utilisables par Roo, classifiés par type, usage et mode d’accès.  
Il vise à garantir la traçabilité, la sécurité et la clarté documentaire pour l’équipe.

---

## 🗂️ Table des outils et commandes

| Outil / Commande      | Type         | Modes autorisés         | Description / Usage           | Restrictions / Exceptions      | Fichier de référence |
|-----------------------|--------------|-------------------------|-------------------------------|-------------------------------|---------------------|
| write_file            | Système      | code, documentation, project-research, maintenance, migration | Écriture de fichiers sur le disque | Non accessible en ask | .roo/system-prompt-* |
| browser_action        | Système      | ask, project-research   | Navigation web, récupération de contenu | Fermeture automatique, accès limité | .roo/system-prompt-* |
| read_file             | Système      | code, documentation, project-research, maintenance, migration | Lecture de fichiers sur le disque | Non accessible en ask, orchestrator | .roo/system-prompt-* |
| cmd/cli/...           | Commande CLI | code, maintenance, migration, debug | Exécution de scripts/commandes système | Selon droits d’accès, dry-run recommandé | cmd/, .roo/rules/rules-code.md |
| PluginInterface       | Extension    | tous                    | Ajout dynamique de plugins, stratégies | Validation requise, sécurité à vérifier | AGENTS.md, rules-plugins.md |
| API HTTP/REST         | Externe      | project-research, orchestrator, code | Appels API externes, intégration services | Selon configuration, sécurité à valider | .roo/rules/rules-orchestration.md |
| ModeManager           | Manager      | tous                    | Gestion des modes Roo, transitions, préférences | Accès restreint selon contexte | AGENTS.md, rules-agents.md |
| ErrorManager          | Manager      | tous sauf ask           | Centralisation et gestion des erreurs | Non accessible en ask | AGENTS.md, rules-code.md |
| CleanupManager        | Manager      | maintenance, migration, code | Nettoyage, organisation intelligente | Accès restreint, dry-run recommandé | AGENTS.md, rules-maintenance.md |
| MigrationManager      | Manager      | migration, maintenance, code | Import/export, migration de données | Accès restreint, rollback possible | AGENTS.md, rules-migration.md |
| ...                   | ...          | ...                     | ...                           | ...                           | ...                 |

---

## 🧩 Classification des outils

- **Outils système** : write_file, read_file, browser_action
- **Commandes CLI** : cmd/cli, scripts shell, PowerShell, etc.
- **Interfaces d’extension** : PluginInterface, points d’extension managers
- **Managers Roo** : ModeManager, ErrorManager, CleanupManager, MigrationManager, etc.
- **APIs externes** : HTTP/REST, intégrations tierces
- **Plugins** : Extensions IA, formatage, conversion, etc.

---

## 🔒 Sécurité et restrictions

- Chaque outil doit être employé uniquement par les modes autorisés.
- Les restrictions et exceptions sont à respecter strictement (voir tableau ci-dessus).
- Toute extension ou nouveau plugin doit être validé et documenté ici.

---

## 📝 Procédure de mise à jour

- Ajouter chaque nouvel outil, commande ou plugin dans ce registre dès son introduction.
- Mettre à jour les modes autorisés et les restrictions à chaque évolution.
- Synchroniser ce registre avec les prompts système et la documentation centrale `.github/docs/`.

---

## 📚 Références croisées

- [AGENTS.md](../AGENTS.md) : Liste des managers et interfaces
- [rules-plugins.md](rules-plugins.md) : Convention d’extension et gestion des plugins
- [rules-orchestration.md](rules-orchestration.md) : Workflows et intégration des managers
- [rules-code.md](rules-code.md) : Standards de développement et outils CLI
- [rules-maintenance.md](rules-maintenance.md) : Procédures de maintenance et outils associés
- [rules-migration.md](rules-migration.md) : Outils et procédures de migration
- [README.md](README.md) : Guide d’organisation des règles Roo-Code

---

## 🚀 Notes d’évolutivité

- Ce registre est la référence centrale pour la gouvernance des outils Roo.
- Toute modification doit être validée par l’équipe et documentée ici.
- Les outils doivent être conçus pour s’ajuster dynamiquement à la liste des modes disponibles.

---

**À compléter et enrichir au fil des évolutions du projet.  
Signaler toute anomalie ou suggestion d’amélioration à l’équipe documentaire.**