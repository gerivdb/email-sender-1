# FAQ / Problèmes fréquents diff Edit

Cette FAQ centralise les retours d’expérience, problèmes courants et solutions liés à l’utilisation de la méthode diff Edit (Go natif).

## Problèmes courants

### 1. Bloc SEARCH non trouvé

- **Cause** : Le bloc SEARCH n’existe pas dans le fichier cible (erreur de copier-coller, encodage, formatage).
- **Solution** : Vérifier l’exactitude du bloc SEARCH, l’encodage du fichier (UTF-8), et les retours à la ligne (CRLF/LF).

### 2. Plusieurs occurrences du bloc SEARCH

- **Cause** : Le bloc SEARCH n’est pas unique dans le fichier.
- **Solution** : Ajouter du contexte avant/après dans le bloc SEARCH pour garantir l’unicité.

### 3. Problèmes d’encodage (UTF-8, BOM, CRLF/LF)

- **Cause** : Fichiers créés sous Windows ou éditeurs différents.
- **Solution** : Convertir le fichier en UTF-8 sans BOM, harmoniser les retours à la ligne.

### 4. Fichiers volumineux ou binaires

- **Cause** : Le script diff Edit n’est pas conçu pour les fichiers binaires ou très volumineux.
- **Solution** : Limiter l’usage à des fichiers texte, segmenter les gros fichiers si besoin.

### 5. Conflits d’équipe

- **Cause** : Plusieurs utilisateurs appliquent des diff Edit en parallèle sur le même fichier.
- **Solution** : Utiliser des branches distinctes, valider les diffs dans Git/VS Code, utiliser les hooks de verrouillage.

## Conseils pratiques

- Toujours faire un backup avant modification.
- Utiliser le mode `--dry-run` pour prévisualiser les changements.
- Lire la documentation et les exemples avant d’appliquer un patch sur un format non standard.

## Pour contribuer à la FAQ

- Ajouter vos questions/réponses dans ce fichier.
- Proposer des améliorations via pull request ou issue sur le dépôt.
