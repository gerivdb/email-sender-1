# Optimisations pour Augment Code

Ce document explique les optimisations mises en place pour améliorer l'utilisation d'Augment Code dans ce projet.

## Fichiers créés

1. **augment-optimized-settings.json** - Configuration VS Code optimisée pour Augment Code
2. **optimize-vscode-for-augment.ps1** - Script PowerShell pour appliquer les optimisations
3. **.augmentignore** - Fichier pour exclure les fichiers non pertinents de l'analyse d'Augment Code

## Comment appliquer les optimisations

1. Exécutez le script PowerShell pour appliquer les optimisations :

```powershell
.\optimize-vscode-for-augment.ps1
```

2. Pour forcer la création d'un nouveau fichier de configuration de l'espace de travail :

```powershell
.\optimize-vscode-for-augment.ps1 -Force
```

3. Pour désactiver la sauvegarde des fichiers de configuration existants :

```powershell
.\optimize-vscode-for-augment.ps1 -Backup:$false
```

4. Redémarrez VS Code pour appliquer les modifications.

## Optimisations appliquées

### 1. Paramètres spécifiques à Augment Code

- **Limite de taille d'input** : Configuration pour respecter la limite stricte de 5KB et la recommandation de 4KB
- **Segmentation automatique** : Activation de la segmentation automatique des inputs volumineux
- **Patterns d'exclusion** : Configuration pour ignorer les fichiers non pertinents

### 2. Optimisations de performance VS Code

- **Exclusion de fichiers** : Configuration pour exclure les fichiers volumineux et non pertinents de la surveillance et de la recherche
- **Limitation des éditeurs** : Limitation du nombre d'éditeurs ouverts simultanément
- **Désactivation de la minimap** : Réduction de la consommation de mémoire

### 3. Fichier .augmentignore

Le fichier `.augmentignore` permet d'exclure les fichiers et dossiers suivants de l'analyse d'Augment Code :

- Dossiers système et de dépendances (node_modules, .git, etc.)
- Fichiers de logs et de cache
- Fichiers volumineux et binaires
- Fichiers de données volumineux
- Fichiers de configuration spécifiques
- Dossiers spécifiques au projet

## Avantages des optimisations

1. **Réduction des erreurs "Input trop volumineux"** : Les optimisations permettent de respecter les limites de taille d'input d'Augment Code.
2. **Amélioration des performances** : L'exclusion des fichiers non pertinents réduit la charge de travail d'Augment Code et de VS Code.
3. **Meilleure qualité des suggestions** : En se concentrant sur les fichiers pertinents, Augment Code peut fournir des suggestions plus précises.
4. **Réduction de la consommation de ressources** : Les optimisations réduisent la consommation de mémoire et de CPU.

## Limitations connues

- Les paramètres spécifiques à Augment Code (`augment.*`) sont des suggestions basées sur la documentation et peuvent ne pas être tous supportés par l'extension actuelle.
- Certaines optimisations peuvent nécessiter des ajustements en fonction de votre projet spécifique.

## Ressources supplémentaires

Pour plus d'informations sur les limitations d'Augment Code et les stratégies d'optimisation, consultez :

- [Limitations d'Augment Code](docs/guides/augment/limitations.md)
- [Plans et Quotas d'Augment Code](docs/guides/augment/plans_and_quotas.md)
- [Guide de Segmentation d'Entrées](docs/guides/InputSegmentation.md)
