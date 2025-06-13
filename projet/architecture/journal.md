# Journal de Bord - Documentation Technique

## Vue d'ensemble

Le journal de bord est le composant central du système. Il permet de créer, stocker et rechercher des entrées structurées qui documentent les actions, erreurs, optimisations et enseignements liés au projet.

## Structure des entrées

Chaque entrée du journal est un fichier Markdown avec des métadonnées YAML en en-tête. Le format est le suivant:

```markdown
---
date: AAAA-MM-JJ
heure: HH-MM
title: Titre de l'entrée
tags: [tag1, tag2, tag3]
related: [fichier1.md, fichier2.md]
---

# Titre de l'entrée

## Actions réalisées

- Action 1
- Action 2

## Résolution des erreurs, déductions tirées

- Erreur 1: solution 1
- Déduction 1

## Optimisations identifiées

- Pour le système: optimisation 1
- Pour le code: optimisation 2
- Pour la gestion des erreurs: optimisation 3
- Pour les workflows: optimisation 4

## Enseignements techniques

- Enseignement 1
- Enseignement 2

## Impact sur le projet musical

- Impact 1
- Impact 2

## Code associé

```python
# Exemple de code

```plaintext
## Prochaines étapes

- Étape 1
- Étape 2

## Références et ressources

- Référence 1
- Référence 2
```plaintext
### Métadonnées

- `date`: Date de création au format AAAA-MM-JJ
- `heure`: Heure de création au format HH-MM
- `title`: Titre de l'entrée
- `tags`: Liste de tags pour catégoriser l'entrée
- `related`: Liste d'entrées liées (par nom de fichier)

### Sections

- **Actions réalisées**: Description des actions effectuées
- **Résolution des erreurs, déductions tirées**: Problèmes rencontrés et solutions trouvées
- **Optimisations identifiées**: Améliorations possibles, organisées par catégorie
- **Enseignements techniques**: Connaissances techniques acquises
- **Impact sur le projet musical**: Lien avec le domaine métier (industrie musicale)
- **Code associé**: Exemples de code pertinents
- **Prochaines étapes**: Actions futures à entreprendre
- **Références et ressources**: Liens et ressources utiles

## Nommage des fichiers

Les fichiers sont nommés selon le format:

```plaintext
AAAA-MM-JJ-HH-MM-slug-de-l-entree.md
```plaintext
Où:
- `AAAA-MM-JJ`: Date de création
- `HH-MM`: Heure de création
- `slug-de-l-entree`: Version simplifiée du titre (sans accents, en minuscules, avec des tirets)

Exemple: `2025-04-05-14-30-implementation-du-systeme-rag.md`

## Organisation des fichiers

Les entrées sont stockées dans le répertoire `docs/journal_de_bord/entries/`.

## Implémentation

### Script principal: journal_entry.py

Ce script gère la création d'entrées de journal:

```python
# Créer une entrée avec titre et tags

python scripts/python/journal/journal_entry.py "Titre de l'entrée" --tags tag1 tag2
```plaintext
#### Fonctions principales

- `create_journal_entry(title, tags=None, related=None)`: Crée une nouvelle entrée
- `normalize_accents(text)`: Normalise les caractères accentués
- `slugify(text)`: Convertit un texte en slug pour le nom de fichier

### Script de recherche: journal_search_simple.py

Ce script permet de rechercher dans le journal:

```python
# Rechercher par mots-clés

python scripts/python/journal/journal_search_simple.py --query "terme de recherche"

# Rechercher par tag

python scripts/python/journal/journal_search_simple.py --tag "nom_du_tag"

# Rechercher par date

python scripts/python/journal/journal_search_simple.py --date "2025-04-05"
```plaintext
#### Fonctions principales

- `search(query, n=5)`: Recherche par mots-clés
- `search_by_tag(tag)`: Recherche par tag
- `search_by_date(date)`: Recherche par date
- `build_index()`: Construit l'index de recherche

## Intégration avec VS Code

Le système s'intègre avec VS Code via:

- Des tâches définies dans `.vscode/tasks.json`
- Des raccourcis clavier définis dans `.vscode/keybindings.json`
- Une configuration d'extension dans `.vscode/journal-extension.json`

## Automatisation

La création d'entrées peut être automatisée via:

- Le script `journal-daily.ps1` pour les entrées quotidiennes et hebdomadaires
- Des tâches planifiées Windows configurées via `setup-journal-tasks.ps1`
- Le script `journal_watcher.py` pour surveiller les modifications et mettre à jour les index

## Considérations techniques

### Encodage

Tous les fichiers sont encodés en UTF-8 pour gérer correctement les caractères accentués français.

### Normalisation des caractères accentués

Les caractères accentués sont normalisés dans les noms de fichiers et les slugs pour éviter les problèmes de compatibilité.

### Gestion des métadonnées

Les métadonnées YAML sont extraites et analysées à l'aide d'expressions régulières pour éviter des dépendances supplémentaires.

## Bonnes pratiques

1. **Structuration**: Suivre la structure de sections recommandée
2. **Tags**: Utiliser des tags cohérents pour faciliter la recherche
3. **Détails**: Inclure suffisamment de détails pour que l'entrée soit utile à long terme
4. **Optimisations**: Documenter systématiquement les optimisations par catégorie
5. **Enseignements**: Extraire et documenter les enseignements techniques réutilisables
