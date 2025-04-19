# Guide de gestion Git et GitHub pour Email Sender 1

## Introduction

Ce guide explique comment gérer le code source du projet Email Sender 1 avec Git et GitHub. Il couvre l'initialisation du dépôt, la configuration de GitHub, les bonnes pratiques de commit, et l'utilisation du MCP Git Ingest pour explorer les dépôts GitHub.

## Prérequis

- Git installé sur votre machine (https://git-scm.com/downloads)
- Un compte GitHub (https://github.com/signup)
- PowerShell 5.1 ou supérieur

## Configuration initiale

### 1. Initialiser le dépôt Git

Pour initialiser le dépôt Git et configurer GitHub, exécutez le script suivant :

```powershell
.\scripts\setup\configure-git.ps1
```

Ce script vous guidera à travers les étapes suivantes :
- Vérification de l'installation de Git
- Configuration de vos informations utilisateur Git
- Initialisation du dépôt Git local
- Création des fichiers .gitignore et .gitattributes
- Configuration de GitHub comme remote

### 2. Créer un dépôt privé sur GitHub

1. Connectez-vous à votre compte GitHub (https://github.com/login)
2. Cliquez sur le bouton '+' en haut à droite et sélectionnez 'New repository'
3. Entrez le nom de votre dépôt (ex: 'email-sender-1')
4. Sélectionnez 'Private' pour rendre le dépôt privé
5. Ne cochez PAS 'Initialize this repository with a README'
6. Cliquez sur 'Create repository'

### 3. Premier commit et push

Pour effectuer votre premier commit et push vers GitHub, exécutez le script suivant :

```powershell
.\scripts\setup\initial-commit.ps1
```

Ce script vous guidera à travers les étapes suivantes :
- Ajout de tous les fichiers au staging
- Création du premier commit
- Push des changements vers GitHub

## Utilisation quotidienne de Git

### Commandes Git essentielles

```bash
# Vérifier l'état du dépôt
git status

# Ajouter des fichiers au staging
git add <fichier>  # Ajouter un fichier spécifique
git add .          # Ajouter tous les fichiers modifiés

# Créer un commit
git commit -m "Description des changements"

# Pousser les changements vers GitHub
git push

# Récupérer les changements depuis GitHub
git pull

# Voir l'historique des commits
git log
```

### Bonnes pratiques de commit

1. **Commits atomiques** : Chaque commit doit représenter un changement logique unique
2. **Messages de commit clairs** : Utilisez des messages descriptifs qui expliquent le pourquoi, pas seulement le quoi
3. **Format recommandé** :
   ```
   [Type] Description courte (50 caractères max)
   
   Description détaillée si nécessaire.
   ```
   
   Types courants :
   - `[Feature]` : Nouvelle fonctionnalité
   - `[Fix]` : Correction de bug
   - `[Docs]` : Changements dans la documentation
   - `[Style]` : Formatage, points-virgules manquants, etc.
   - `[Refactor]` : Refactorisation du code
   - `[Test]` : Ajout ou modification de tests
   - `[Chore]` : Tâches de maintenance

## Utilisation du MCP Git Ingest

Le MCP Git Ingest permet d'explorer et de lire les structures de dépôts GitHub et les fichiers importants directement depuis n8n ou Augment.

### Configuration dans Augment

Pour configurer le MCP Git Ingest dans Augment, exécutez le script suivant :

```powershell
.\scripts\setup\configure-augment-git.ps1
```

Puis suivez les instructions pour ajouter le MCP dans Augment Settings.

### Utilisation dans Augment

Une fois configuré, vous pouvez utiliser le MCP Git Ingest dans Augment pour :
- Explorer la structure d'un dépôt GitHub
- Lire le contenu de fichiers spécifiques dans un dépôt GitHub

### Utilisation dans n8n

Pour utiliser le MCP Git Ingest dans n8n, consultez le guide [GUIDE_MCP_GIT_INGEST.md](GUIDE_MCP_GIT_INGEST.md).

## Gestion des branches

### Stratégie de branchement recommandée

Pour ce projet, nous recommandons la stratégie de branchement suivante :

```
master (ou main)  : Code de production stable
├── develop       : Code de développement intégré
│   ├── feature/x : Nouvelles fonctionnalités
│   ├── fix/y     : Corrections de bugs
│   └── docs/z    : Mises à jour de documentation
```

### Commandes pour gérer les branches

```bash
# Créer une nouvelle branche
git checkout -b <nom-de-branche>

# Changer de branche
git checkout <nom-de-branche>

# Fusionner une branche
git checkout develop
git merge <nom-de-branche>

# Supprimer une branche locale
git branch -d <nom-de-branche>
```

## Résolution des problèmes courants

### Conflits de fusion

1. Ouvrez les fichiers avec des conflits (marqués par `<<<<<<<`, `=======`, et `>>>>>>>`)
2. Modifiez les fichiers pour résoudre les conflits
3. Ajoutez les fichiers résolus avec `git add <fichier>`
4. Terminez la fusion avec `git commit`

### Annuler des changements

```bash
# Annuler les changements non stagés dans un fichier
git checkout -- <fichier>

# Annuler tous les changements non stagés
git checkout -- .

# Annuler les changements stagés
git reset HEAD <fichier>

# Annuler le dernier commit (conserve les changements)
git reset --soft HEAD~1

# Annuler le dernier commit (supprime les changements)
git reset --hard HEAD~1
```

## Ressources supplémentaires

- [Documentation officielle de Git](https://git-scm.com/doc)
- [GitHub Guides](https://guides.github.com/)
- [Oh Shit, Git!?!](https://ohshitgit.com/) - Solutions aux problèmes Git courants
- [Learn Git Branching](https://learngitbranching.js.org/) - Tutoriel interactif
