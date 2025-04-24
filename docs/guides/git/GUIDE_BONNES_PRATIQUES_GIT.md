# Guide des bonnes pratiques Git pour le projet n8n

Ce guide présente les bonnes pratiques à suivre pour la gestion du code source avec Git dans le cadre du projet n8n. Il s'appuie sur les enseignements documentés dans le journal de bord et vise à standardiser les pratiques au sein de l'équipe.

## Table des matières

1. [Structure des commits](#structure-des-commits)
2. [Messages de commit](#messages-de-commit)
3. [Gestion des branches](#gestion-des-branches)
4. [Résolution des problèmes courants](#résolution-des-problèmes-courants)
5. [Outils et scripts](#outils-et-scripts)

## Structure des commits

### Commits atomiques vs. commits volumineux

- **Privilégier les commits atomiques** : Un commit doit idéalement représenter une seule modification logique.
- **Segmenter les changements importants** : Pour une réorganisation majeure, segmenter les changements par catégorie :
  1. Modifications de structure de dossiers
  2. Ajout de nouveaux fichiers
  3. Modifications de fichiers existants
  4. Suppressions de fichiers obsolètes

### Quand utiliser des commits volumineux

Les commits volumineux sont acceptables dans les cas suivants :
- Refactoring majeur qui touche de nombreux fichiers
- Migration de version qui nécessite des changements coordonnés
- Première importation d'un ensemble de fichiers liés

## Messages de commit

### Format recommandé

```
<type>: <description courte>

<description détaillée (optionnelle)>
```

### Types de commit

- `feat` : Nouvelle fonctionnalité
- `fix` : Correction de bug
- `docs` : Modification de la documentation
- `style` : Formatage, espaces, etc. (pas de changement de code)
- `refactor` : Refactoring du code
- `test` : Ajout ou modification de tests
- `chore` : Tâches de maintenance, mises à jour de dépendances, etc.

### Exemples de bons messages de commit

```
feat: Ajout du script d'automatisation des commits Git

Ce script combine toutes les étapes (organisation, vérification, ajout, commit, push)
en une seule commande et inclut des vérifications préalables pour éviter les conflits
avec les hooks Git.
```

```
fix: Correction des conflits avec les hooks Git dans auto-organize-silent.ps1

- Ajout d'une vérification de verrouillage de fichier
- Gestion des erreurs plus robuste
- Contournement du problème d'accès concurrent
```

## Gestion des branches

### Conventions de nommage

- `main` : Branche principale, toujours stable
- `develop` : Branche de développement
- `feature/<nom-feature>` : Nouvelles fonctionnalités
- `fix/<nom-bug>` : Corrections de bugs
- `docs/<sujet>` : Modifications de documentation
- `refactor/<sujet>` : Refactoring du code

### Workflow recommandé

1. Créer une branche à partir de `develop` pour chaque nouvelle fonctionnalité ou correction
2. Effectuer des commits atomiques réguliers
3. Pousser la branche vers le dépôt distant régulièrement
4. Créer une pull request pour fusionner dans `develop`
5. Après validation, fusionner `develop` dans `main` pour les releases

## Résolution des problèmes courants

### Conflits avec les hooks Git

**Problème** : Erreur d'accès au fichier pre-commit pendant le processus de commit
```
Set-Content : Le processus ne peut pas accéder au fichier '.git/hooks/pre-commit', car il est en cours d'utilisation par un autre processus.
```

**Solutions** :
- Exécuter les scripts d'organisation avant de lancer la commande de commit
- Utiliser le script `auto-organize-silent-improved.ps1` qui vérifie si le fichier est déjà en cours d'utilisation
- Utiliser le script `git-smart-commit.ps1` qui gère automatiquement ces conflits

### Gestion des fins de ligne (LF/CRLF)

**Problème** : Avertissements sur les fins de ligne lors du commit
```
warning: in the working copy of 'file.md', LF will be replaced by CRLF the next time Git touches it
```

**Solutions** :
- Configurer Git avec `git config --global core.autocrlf true` (pour Windows)
- Utiliser le fichier `.gitattributes` déjà configuré dans le projet
- Ne pas modifier manuellement les fins de ligne

### Fichiers volumineux et binaires

**Problème** : Git n'est pas adapté pour les fichiers volumineux ou binaires qui changent fréquemment

**Solutions** :
- Utiliser Git LFS pour les fichiers volumineux
- Exclure les fichiers binaires générés via `.gitignore`
- Stocker les données volumineuses dans un système externe

## Outils et scripts

### Scripts d'automatisation Git

- **`git-smart-commit.ps1`** : Script principal pour automatiser le processus de commit et push
  ```powershell
  # Commit standard avec message
  .\scripts\utils\git\git-smart-commit.ps1 -CommitMessage "feat: Nouvelle fonctionnalité"
  
  # Commit atomique (sélection des fichiers par type)
  .\scripts\utils\git\git-smart-commit.ps1 -AtomicCommit
  
  # Commit sans organisation préalable des fichiers
  .\scripts\utils\git\git-smart-commit.ps1 -SkipOrganize
  
  # Commit sans push automatique
  .\scripts\utils\git\git-smart-commit.ps1 -SkipPush
  ```

- **`auto-organize-silent-improved.ps1`** : Script amélioré pour l'organisation automatique des fichiers
  ```powershell
  .\scripts\maintenance\auto-organize-silent-improved.ps1
  ```

### Vérification avant commit

Pour vérifier les changements avant de les commiter :
```bash
git diff --staged
```

Pour voir un résumé statistique des changements :
```bash
git diff --staged --stat
```

### Configuration recommandée

Configuration Git recommandée pour le projet :
```bash
# Configurer les fins de ligne (pour Windows)
git config --global core.autocrlf true

# Configurer l'éditeur (exemple avec VS Code)
git config --global core.editor "code --wait"

# Configurer le nom d'utilisateur et l'email
git config --global user.name "Votre Nom"
git config --global user.email "votre.email@exemple.com"
```

## Conclusion

Suivre ces bonnes pratiques permettra de maintenir un historique Git propre et compréhensible, facilitant la collaboration au sein de l'équipe et la maintenance du projet à long terme. Les scripts d'automatisation fournis simplifient l'application de ces pratiques au quotidien.

N'hésitez pas à contribuer à ce guide en proposant des améliorations ou des clarifications basées sur votre expérience avec le projet.
