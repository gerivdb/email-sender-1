# Guide d'intégration CI/CD

Ce guide explique comment utiliser et personnaliser l'intégration CI/CD mise en place dans le projet n8n. L'intégration CI/CD permet d'automatiser les vérifications de qualité du code, les tests et le déploiement.

## Table des matières

1. [Introduction à l'intégration CI/CD](#introduction-à-lintégration-cicd)
2. [Configuration GitHub Actions](#configuration-github-actions)
3. [Exécution locale des vérifications CI/CD](#exécution-locale-des-vérifications-cicd)
4. [Personnalisation des vérifications](#personnalisation-des-vérifications)
5. [Intégration avec les hooks Git](#intégration-avec-les-hooks-git)
6. [Bonnes pratiques](#bonnes-pratiques)

## Introduction à l'intégration CI/CD

L'intégration CI/CD (Continuous Integration/Continuous Deployment) permet d'automatiser les processus de vérification, de test et de déploiement du code. Dans ce projet, nous utilisons GitHub Actions pour mettre en œuvre ces processus.

Les principaux avantages de l'intégration CI/CD sont :

- **Détection précoce des problèmes** : Les erreurs sont détectées dès qu'elles sont introduites dans le code
- **Cohérence des vérifications** : Les mêmes vérifications sont effectuées pour chaque modification
- **Automatisation du déploiement** : Le déploiement est automatisé et standardisé
- **Traçabilité** : Chaque modification est tracée et vérifiée

## Configuration GitHub Actions

Le projet utilise GitHub Actions pour l'intégration CI/CD. La configuration se trouve dans le fichier `.github/workflows/ci.yml`.

### Structure du pipeline CI/CD

Le pipeline CI/CD est composé de plusieurs jobs :

1. **Lint** : Vérification du style de code
   - Analyse des fichiers PowerShell avec PSScriptAnalyzer
   - Analyse des fichiers Python avec flake8

2. **Test** : Exécution des tests unitaires
   - Exécution des tests PowerShell avec Pester
   - Exécution des tests Python avec pytest

3. **Security** : Vérification de sécurité
   - Détection des informations sensibles dans le code

4. **Build** : Construction et déploiement
   - Construction du projet
   - Déploiement vers l'environnement approprié (développement ou production)

### Déclenchement du pipeline

Le pipeline CI/CD est déclenché dans les cas suivants :

- **Push** sur les branches `main` ou `develop`
- **Pull Request** vers les branches `main` ou `develop`

Le job de déploiement n'est exécuté que lors d'un push sur les branches `main` ou `develop`.

## Exécution locale des vérifications CI/CD

Vous pouvez exécuter les mêmes vérifications que le pipeline CI/CD localement, avant de pousser vos modifications. Pour cela, utilisez le script `scripts/ci/run-ci-checks.ps1`.

### Exemples d'utilisation

```powershell
# Exécuter toutes les vérifications
.\scripts\ci\run-ci-checks.ps1

# Exécuter uniquement les vérifications de style de code
.\scripts\ci\run-ci-checks.ps1 -SkipTests -SkipSecurity

# Exécuter uniquement les tests unitaires
.\scripts\ci\run-ci-checks.ps1 -SkipLint -SkipSecurity

# Exécuter uniquement les vérifications de sécurité
.\scripts\ci\run-ci-checks.ps1 -SkipLint -SkipTests

# Afficher des informations détaillées
.\scripts\ci\run-ci-checks.ps1 -Verbose
```

## Personnalisation des vérifications

Vous pouvez personnaliser les vérifications effectuées par le pipeline CI/CD en modifiant les fichiers suivants :

### Vérifications de style de code

- **PowerShell** : Modifiez les règles PSScriptAnalyzer dans le script `scripts/ci/run-ci-checks.ps1`
- **Python** : Créez un fichier `.flake8` à la racine du projet pour personnaliser les règles flake8

### Tests unitaires

- **PowerShell** : Créez des fichiers de test avec le suffixe `Test` (par exemple, `MyFunctionTest.ps1`)
- **Python** : Créez des fichiers de test avec le préfixe `test_` (par exemple, `test_my_function.py`)

### Vérifications de sécurité

Modifiez les patterns de détection des informations sensibles dans le script `scripts/ci/run-ci-checks.ps1` :

```powershell
$sensitivePatterns = @(
    "password\s*=\s*['\"][^'\"]+['\"]",
    "apikey\s*=\s*['\"][^'\"]+['\"]",
    # Ajoutez vos patterns personnalisés ici
)
```

## Intégration avec les hooks Git

Les vérifications CI/CD sont également intégrées aux hooks Git locaux, ce qui permet de détecter les problèmes avant même de commiter ou de pousser les modifications.

### Hook pre-commit

Le hook pre-commit exécute les vérifications suivantes :

- Organisation des fichiers
- Vérification du style de code
- Détection des informations sensibles

### Hook pre-push

Le hook pre-push exécute les vérifications suivantes :

- Détection des conflits non résolus
- Vérification des fichiers volumineux
- Exécution des tests unitaires
- Détection des informations sensibles

### Configuration des hooks

Pour configurer les hooks Git, utilisez le script `scripts/setup/setup-git-hooks.ps1` :

```powershell
# Installer tous les hooks
.\scripts\setup\setup-git-hooks.ps1

# Installer uniquement le hook pre-commit
.\scripts\setup\setup-git-hooks.ps1 -SkipPrePush

# Installer uniquement le hook pre-push
.\scripts\setup\setup-git-hooks.ps1 -SkipPreCommit
```

## Bonnes pratiques

1. **Exécutez les vérifications localement avant de pousser** : Utilisez le script `scripts/ci/run-ci-checks.ps1` pour exécuter les mêmes vérifications que le pipeline CI/CD avant de pousser vos modifications.

2. **Créez des tests unitaires** : Créez des tests unitaires pour chaque nouvelle fonctionnalité ou correction de bug. Les tests unitaires permettent de détecter les régressions et de documenter le comportement attendu du code.

3. **Respectez les conventions de style** : Suivez les conventions de style de code pour PowerShell et Python. Cela rend le code plus lisible et facilite la collaboration.

4. **Ne commettez pas d'informations sensibles** : N'incluez jamais de mots de passe, de clés API ou d'autres informations sensibles dans le code. Utilisez des variables d'environnement ou des fichiers de configuration externes.

5. **Utilisez des branches de fonctionnalité** : Créez une branche pour chaque nouvelle fonctionnalité ou correction de bug. Cela permet de travailler sur plusieurs fonctionnalités en parallèle sans interférence.

6. **Créez des pull requests** : Utilisez des pull requests pour faire réviser votre code avant de le fusionner dans les branches principales. Cela permet de détecter les problèmes avant qu'ils n'affectent les autres développeurs.

7. **Documentez les changements** : Documentez les changements importants dans le journal de bord et les fichiers README appropriés. Cela aide les autres développeurs à comprendre les modifications et leur impact.

## Conclusion

L'intégration CI/CD est un outil puissant pour maintenir la qualité du code et automatiser les processus de déploiement. En suivant les bonnes pratiques et en utilisant les outils fournis, vous pouvez contribuer à maintenir un code de haute qualité et à faciliter la collaboration au sein de l'équipe.
