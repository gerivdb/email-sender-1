Voici une version améliorée du tableau central du registre des outils Roo, repensée pour une lisibilité optimale, une classification claire et une présentation contemporaine (SOTA). Cette refonte privilégie l’alignement des colonnes, la réduction des doublons, et la synthèse des points saillants, tout en préservant l’exhaustivité et la rigueur documentaire.

## 🗂️ Outils et Commandes — Vue Synthétique

| **Outil / Commande**   | **Catégorie**      | **Modes Autorisés**                                                     | **Usage Principal**                     | **Restrictions**                          | **Références**                      |
|------------------------|--------------------|-------------------------------------------------------------------------|------------------------------------------|--------------------------------------------|--------------------------------------|
| **write_file**         | Système            | code, architect, debug, orchestrator, project-research, documentation-writer, mode-writer, user-story-creator, plandev-engineer, devops, maintenance, migration | Écriture sur disque                      | Non disponible en mode ask                | .roo/system-prompt-*                |
| **read_file**          | Système            | code, documentation, project-research, maintenance, migration           | Lecture sur disque                       | Non dispo en ask, orchestrator             | .roo/system-prompt-*                |
| **browser_action**     | Système            | ask, project-research                                                   | Navigation web, extraction de contenu    | Fermeture automatique, accès limité        | .roo/system-prompt-*                |
| **cmd / cli**          | Commande CLI       | code, maintenance, migration, debug                                      | Exécution scripts/commandes système      | Restriction droits, dry-run conseillé      | .roo/rules/rules-code.md            |
| **PluginInterface**    | Extension          | tous                                                                    | Plug-in dynamique, extensions            | Validation & sécurité                         | AGENTS.md, rules-plugins.md          |
| **API HTTP / REST**    | Externe            | project-research, orchestrator, code                                     | Appel d’API externe                      | Revue de sécurité requise                  | .roo/rules/rules-orchestration.md    |
| **ModeManager**        | Manager            | tous                                                                    | Orchestration des modes Roo              | Accès limité selon contexte                | AGENTS.md, rules-agents.md           |
| **ErrorManager**       | Manager            | tous sauf ask                                                           | Gestion centralisée des erreurs          | Inaccessible en mode ask                   | AGENTS.md, rules-code.md             |
| **CleanupManager**     | Manager            | maintenance, migration, code                                            | Nettoyage intelligent                    | Préconisation dry-run                      | AGENTS.md, rules-maintenance.md       |
| **MigrationManager**   | Manager            | migration, maintenance, code                                            | Migration et transfert de données        | Fonctionnalité rollback possible           | AGENTS.md, rules-migration.md        |

### 🏷️ **Catégories Simplifiées**

- **Système** : write_file, read_file, browser_action
- **CLI** : cmd / cli (shell, PowerShell)
- **Extension** : PluginInterface, extensions IA/outils de formatage
- **Manager** : ModeManager, ErrorManager, CleanupManager, MigrationManager
- **Externe** : API HTTP / REST

### ⚠️ **Synthèse Sécurité et Gouvernance**

- **Contrôle strict** des modes et restrictions pour chaque outil
- **Validation obligatoire** pour tout ajout/plugin/extension
- **Audit à jour** pour garantir conformité & traçabilité

### ✅ **Instructions d’Actualisation**

1. Inscrire tout nouvel outil/plugin dès intégration.
2. Ajuster modes et restrictions correspondants.
3. Aligner avec `.github/docs/` et prompts système lors des évolutions.

### 📑 **Références Utiles**

- AGENTS.md – Managers & orchestration
- rules-plugins.md – Gestion des extensions/plugins
- rules-orchestration.md – Workflows externes et sécurité
- rules-code.md – Standards d’implémentation
- rules-maintenance.md – Maintenance & nettoyage
- rules-migration.md – Gestion et rollback migration
- README.md – Guide général Roo-Code

> **Astuce SOTA** : adosse systématiquement chaque outil à une politique d’usage et une référence documentaire, afin de garantir évolutivité, traçabilité, et sécurité, tout en facilitant le build d’outils dynamiques et adaptatifs pour l’équipe.

**Ce registre doit être vivant, enrichi au fil de l’évolution du projet, et validé collégialement par les responsables technique et documentaire.**