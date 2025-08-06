Voici le plan de développement détaillé pour l’amélioration de la gestion des restrictions par mode Roo-Code, conforme aux principes Roo, SOTA, DRY, KISS et SOLID :

---

# Plan Dev — Centralisation et Documentation des Restrictions par Mode Roo-Code

## Objectif

Garantir la clarté, la traçabilité et la maintenabilité des règles et restrictions par mode Roo-Code, en centralisant l’information, en simplifiant la navigation et en assurant la modularité documentaire.

---

## Phases & Tâches Actionnables

### Phase 1 : Centralisation des règles et restrictions

- **Objectif** : Regrouper toutes les règles et restrictions par mode dans un emplacement unique.
- **Livrables** : `.roo/rules/tools-registry.md` mis à jour, table exhaustive des modes et outils.
- **Tâches** :
  - [ ] Compléter la table des outils et commandes dans `tools-registry.md` avec tous les modes, restrictions, exceptions et liens directs vers les fichiers de référence.
  - [ ] Ajouter une colonne “Overrides/Exceptions” pour chaque mode et outil.
  - [ ] Synchroniser la liste des modes avec l’inventaire de `.roo/rules/rules.md` et la documentation centrale.
- **Critères de validation** :
  - Table exhaustive, à jour, avec liens cliquables.
  - Cohérence avec la documentation centrale et les prompts système.

---

### Phase 2 : Ajout d’une section synthétique dans le README racine

- **Objectif** : Faciliter la compréhension des restrictions par mode pour tous les utilisateurs.
- **Livrables** : Section “Restrictions par mode” dans `.roo/README.md`.
- **Tâches** :
  - [ ] Rédiger une matrice cliquable des modes, actions permises/interdites, exceptions et overrides.
  - [ ] Ajouter des explications synthétiques sur les principes Roo, la traçabilité et la justification des restrictions.
  - [ ] Lier chaque mode à sa fiche détaillée et à la table du `tools-registry.md`.
- **Critères de validation** :
  - Section claire, concise, facilement navigable.
  - Liens croisés fonctionnels.

---

### Phase 3 : Mise à jour des fiches mode (DRY/KISS)

- **Objectif** : Rendre chaque fiche mode auto-suffisante et explicite sur ses restrictions.
- **Livrables** : Fiches mode dans `.roo/rules/rules.md` et fichiers spécialisés.
- **Tâches** :
  - [ ] Ajouter un résumé DRY/KISS : actions permises/interdites, extensions autorisées, cas limites, liens doc centrale.
  - [ ] Expliciter les exceptions et overrides dans chaque fiche.
  - [ ] Lier vers la documentation centrale et le `tools-registry.md`.
- **Critères de validation** :
  - Fiches mode à jour, synthétiques, sans redondance inutile.
  - Justification claire des restrictions.

---

### Phase 4 : Isolation et modularité des règles (SOLID)

- **Objectif** : Permettre la modification indépendante de chaque règle ou restriction.
- **Livrables** : Fichiers de règles spécialisés, documentation croisée.
- **Tâches** :
  - [ ] Isoler chaque règle/restriction dans son fichier source dédié.
  - [ ] Documenter les points d’extension et les impacts sur les autres modes.
  - [ ] Mettre à jour les liens croisés dans la documentation centrale.
- **Critères de validation** :
  - Modification d’une règle n’impacte pas les autres modes.
  - Documentation croisée à jour.

---

### Phase 5 : Exemples d’usage et workflows dans la documentation centrale

- **Objectif** : Illustrer concrètement l’application des restrictions et des workflows par mode.
- **Livrables** : Exemples dans `.github/docs/vsix/roo-code/README.md`.
- **Tâches** :
  - [ ] Ajouter des exemples d’usage pour chaque mode (tableaux, checklists, workflows Mermaid).
  - [ ] Documenter les cas limites et les exceptions typiques.
  - [ ] Lier vers les fiches mode et le `tools-registry.md`.
- **Critères de validation** :
  - Exemples clairs, actionnables, couvrant les principaux cas d’usage.

---

### Phase 6 : Indexation des points d’extension et overrides (DRY)

- **Objectif** : Centraliser tous les points d’extension et overrides pour faciliter la maintenance.
- **Livrables** : Emplacement unique (section ou fichier) listant tous les points d’extension et overrides.
- **Tâches** :
  - [ ] Recenser tous les points d’extension (plugins, hooks, exceptions) dans un tableau synthétique.
  - [ ] Lier chaque point d’extension à sa documentation et à son mode concerné.
  - [ ] Mettre à jour la documentation centrale et le `tools-registry.md`.
- **Critères de validation** :
  - Index complet, à jour, facilement navigable.

---

### Phase 7 : Vérification de la cohérence et de la lisibilité

- **Objectif** : Garantir la simplicité, la cohérence et la justification documentaire.
- **Livrables** : README, fiches mode et documentation centrale vérifiés.
- **Tâches** :
  - [ ] Relire chaque section pour vérifier la clarté et la justification des restrictions.
  - [ ] Corriger les incohérences ou redondances.
  - [ ] Valider la traçabilité Roo et la conformité SOTA, DRY, KISS, SOLID.
- **Critères de validation** :
  - Documentation cohérente, simple, justifiée et traçable.

---

## Synthèse visuelle (Mermaid)

```mermaid
flowchart TD
    A[Centraliser restrictions dans tools-registry.md] --> B[Ajouter section synthétique dans README]
    B --> C[Mise à jour des fiches mode DRY/KISS]
    C --> D[Isoler chaque règle/restriction (SOLID)]
    D --> E[Ajouter exemples et workflows dans doc centrale]
    E --> F[Indexation des points d’extension et overrides]
    F --> G[Vérification cohérence et lisibilité]
    G --> H[Validation utilisateur]
```

---

## Questions ouvertes & points d’attention

- Y a-t-il des modes ou outils non référencés à intégrer ?
- Faut-il prévoir des workflows spécifiques pour certains modes ?
- Des cas limites ou exceptions à documenter en priorité ?
- Besoin d’automatiser la synchronisation entre les fichiers ?

---

## Critères de validation globaux

- Table des restrictions exhaustive et à jour
- Documentation centrale et fiches mode synchronisées
- Indexation claire des points d’extension et overrides
- Justification explicite des restrictions et exceptions
- Traçabilité Roo assurée sur toutes les modifications

---

## Liens utiles

- [tools-registry.md](.roo/rules/tools-registry.md)
- [README.md](.roo/README.md)
- [rules.md](.roo/rules/rules.md)
- [AGENTS.md](AGENTS.md)
- [workflows-matrix.md](.roo/rules/workflows-matrix.md)
- [Documentation centrale Roo-Code](.github/docs/vsix/roo-code/README.md)

---
