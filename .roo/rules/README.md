# Guide d’organisation des règles Roo-Code

Ce dossier centralise toutes les règles, standards et bonnes pratiques du projet Roo-Code.

## Structure

- **rules.md** : Principes transverses et méthodologies communes à tous les modes Roo-Code.
- **rules-documentation.md** : Règles et modèles pour la documentation.
- **rules-code.md** : Standards de développement et architecture.
- **rules-debug.md** : Méthodologies de diagnostic et résolution.
- **rules-orchestration.md** : Workflows et intégration des managers.
- **rules-security.md** : Principes de sécurité documentaire.
- **rules-maintenance.md** : Procédures de maintenance et optimisation.
- **rules-migration.md** : Bonnes pratiques d’import/export et migration.
- **rules-plugins.md** : Convention d’extension et gestion des plugins.
- **rules-agents.md** : Convention de gestion des rôles et agents.

## Usage

- **Centralisation** : Les règles communes sont dans `rules.md`. Les fichiers spécifiques détaillent les pratiques avancées ou propres à un domaine.
- **Subordination** : Chaque fichier spécialisé doit respecter les principes de `rules.md` et indiquer les éventuels overrides ou spécificités de mode.
- **Overrides** : Si un mode ou un prompt système nécessite une adaptation, documenter la règle dans le fichier spécialisé et référencer le mode concerné.

## Maintenabilité

- Mettre à jour ce dossier à chaque évolution des pratiques ou des besoins du projet.
- Privilégier la clarté, la concision et la structuration logique.
- Documenter les exceptions, overrides et cas particuliers.

---