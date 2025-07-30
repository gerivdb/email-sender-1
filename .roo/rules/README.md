# Guide d’organisation des règles Roo-Code

Ce dossier centralise toutes les règles, standards et bonnes pratiques du projet Roo-Code.

## Structure

- **rules.md** : Principes transverses et méthodologies communes à tous les modes Roo-Code.
- **rules-agents.md** : Convention de gestion des rôles et agents ([AGENTS.md](../AGENTS.md)).
- **rules-code.md** : Standards de développement et architecture.
- **rules-debug.md** : Méthodologies de diagnostic et résolution.
- **rules-documentation.md** : Règles et modèles pour la documentation.
- **rules-maintenance.md** : Procédures de maintenance et optimisation.
- **rules-migration.md** : Bonnes pratiques d’import/export et migration.
- **rules-orchestration.md** : Workflows et intégration des managers.
- **rules-plugins.md** : Convention d’extension et gestion des plugins.
- **rules-security.md** : Principes de sécurité documentaire.
- **tools-registry.md** : Registre central des outils Roo utilisables par les modes ([voir détails](tools-registry.md)).
- **workflows-matrix.md** : Matrice des workflows Roo, modes et points d’extension ([voir détails](workflows-matrix.md)).

## Références croisées

Chaque fichier spécialisé est subordonné à `rules.md` et doit indiquer ses overrides ou spécificités de mode.  
Les fichiers sont interconnectés :

- **AGENTS.md** ([../AGENTS.md]) : Liste centrale des managers, agents et interfaces.
- **tools-registry.md** : Référence tous les outils, commandes, plugins et managers, avec liens vers les fichiers de règles concernés.
- **workflows-matrix.md** : Synchronise dynamiquement les modes et workflows avec AGENTS.md et ModeManager.
- **rules-orchestration.md** : Détaille les workflows, points d’extension et intégration des managers.
- **rules-plugins.md** : Convention de développement et validation des plugins, avec liens vers AGENTS.md et tools-registry.md.
- **rules-maintenance.md**, **rules-migration.md**, **rules-security.md** : Procédures et outils associés, avec liens vers les managers et outils concernés.
- **rules-debug.md**, **rules-code.md**, **rules-documentation.md** : Standards, checklists et modèles, avec liens vers la documentation centrale et les outils.

## Usage

- **Centralisation** : Les règles communes sont dans `rules.md`. Les fichiers spécifiques détaillent les pratiques avancées ou propres à un domaine.
- **Subordination** : Chaque fichier spécialisé doit respecter les principes de `rules.md` et indiquer les éventuels overrides ou spécificités de mode.
- **Overrides** : Si un mode ou un prompt système nécessite une adaptation, documenter la règle dans le fichier spécialisé et référencer le mode concerné.

## Maintenabilité

- Mettre à jour ce dossier à chaque évolution des pratiques ou des besoins du projet.
- Privilégier la clarté, la concision et la structuration logique.
- Documenter les exceptions, overrides et cas particuliers.
- Vérifier la cohérence documentaire entre tous les fichiers de règles, AGENTS.md, tools-registry.md et workflows-matrix.md.

---

_Tip : Ce README est la référence centrale pour garantir la qualité, la traçabilité et la cohérence documentaire du projet Roo-Code.  
Pour toute question ou doute, commence par explorer la documentation centrale, AGENTS.md, tools-registry.md et workflows-matrix.md.