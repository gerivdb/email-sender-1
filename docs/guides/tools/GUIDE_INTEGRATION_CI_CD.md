# Guide d'intégration CI/CD

Ce guide explique comment utiliser et personnaliser l'intégration CI/CD mise en place dans le projet n8n. L'intégration CI/CD permet d'automatiser les vérifications de qualité du code, les tests et le déploiement.

## Table des matières

1. [Introduction à l'intégration CI/CD](#introduction-à-lintégration-cicd)
2. [Configuration GitHub Actions](#configuration-github-actions)
3. [Exécution locale des vérifications CI/CD](#exécution-locale-des-vérifications-cicd)
4. [Personnalisation des vérifications](#personnalisation-des-vérifications)
5. [Déploiement automatisé](#déploiement-automatisé)
6. [Tests unitaires](#tests-unitaires)
7. [Intégration avec les hooks Git](#intégration-avec-les-hooks-git)
8. [Bonnes pratiques](#bonnes-pratiques)

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

## Déploiement automatisé

Le projet inclut un script de déploiement automatisé qui permet de déployer le code vers différents environnements.

### Environnements disponibles

Le script de déploiement prend en charge les environnements suivants :

- **Development** : Environnement de développement
- **Staging** : Environnement de pré-production
- **Production** : Environnement de production

### Utilisation des scripts de déploiement

Le projet propose deux scripts de déploiement :

1. **deploy.ps1** : Script de déploiement de base (simulation)
2. **deploy-real.ps1** : Script de déploiement réel avec SSH et notifications

#### Script de déploiement de base

Pour déployer le projet vers un environnement spécifique, utilisez le script `scripts/ci/deploy.ps1` :

```powershell
# Déployer vers l'environnement de développement
.\scripts\ci\deploy.ps1 -Environment Development

# Déployer vers l'environnement de production
.\scripts\ci\deploy.ps1 -Environment Production

# Déployer sans exécuter les tests
.\scripts\ci\deploy.ps1 -Environment Staging -SkipTests

# Afficher des informations détaillées pendant le déploiement
.\scripts\ci\deploy.ps1 -Environment Development -Verbose
```

#### Script de déploiement réel

Pour un déploiement réel vers un serveur distant, utilisez le script `scripts/ci/deploy-real.ps1` :

```powershell
# Déployer vers l'environnement de développement
.\scripts\ci\deploy-real.ps1 -Environment Development

# Déployer vers l'environnement de production avec notifications
.\scripts\ci\deploy-real.ps1 -Environment Production -SendNotification

# Déployer sans exécuter les tests
.\scripts\ci\deploy-real.ps1 -Environment Staging -SkipTests

# Spécifier une adresse email pour les notifications
.\scripts\ci\deploy-real.ps1 -Environment Production -SendNotification -NotificationEmail "admin@example.com"
```

### Étapes du déploiement

Le script de déploiement effectue les étapes suivantes :

1. **Exécution des tests** : Exécute les tests unitaires pour vérifier que le code fonctionne correctement
2. **Création du package** : Crée une archive contenant les fichiers nécessaires au déploiement
3. **Déploiement** : Copie les fichiers vers le serveur cible
4. **Vérification** : Vérifie que le déploiement a réussi

### Personnalisation du déploiement

Vous pouvez personnaliser le déploiement en modifiant le script `scripts/ci/deploy.ps1`. Par exemple, vous pouvez :

- Ajouter de nouveaux environnements
- Modifier les serveurs cibles
- Ajouter des étapes de déploiement spécifiques
- Configurer des notifications après le déploiement

## Tests unitaires

Le projet inclut des tests unitaires pour vérifier le bon fonctionnement du code. Les tests sont écrits en PowerShell (Pester) et Python (unittest).

### Tests PowerShell

Les tests PowerShell se trouvent dans le dossier `tests/powershell`. Pour exécuter ces tests, utilisez Pester :

```powershell
# Installer Pester si nécessaire
Install-Module -Name Pester -Force -Scope CurrentUser

# Exécuter tous les tests PowerShell
Invoke-Pester -Path .\tests\powershell

# Exécuter un test spécifique
Invoke-Pester -Path .\tests\powershell\GitHooksTest.ps1
```

### Tests Python

Les tests Python se trouvent dans le dossier `tests/python`. Pour exécuter ces tests, utilisez unittest ou pytest :

```bash
# Exécuter tous les tests Python avec unittest
python -m unittest discover -s tests/python

# Exécuter tous les tests Python avec pytest
pytest tests/python

# Exécuter un test spécifique
python -m unittest tests.python.test_ci_integration
```

### Intégration des tests dans le pipeline CI/CD

Les tests sont automatiquement exécutés dans le pipeline CI/CD. Si les tests échouent, le pipeline s'arrête et le déploiement n'est pas effectué.

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

### Installation des hooks

Pour installer les hooks Git, utilisez le script `scripts/setup/install-git-hooks.ps1` :

```powershell
# Installer tous les hooks
.\scripts\setup\install-git-hooks.ps1

# Installer avec des liens symboliques (recommandé)
.\scripts\setup\install-git-hooks.ps1 -UseSymlinks

# Installer uniquement le hook pre-commit
.\scripts\setup\install-git-hooks.ps1 -SkipPrePush

# Installer uniquement le hook pre-push
.\scripts\setup\install-git-hooks.ps1 -SkipPreCommit
```

### Résolution des problèmes avec les hooks

Si vous rencontrez des problèmes avec les hooks Git, essayez les solutions suivantes :

1. **Utiliser des liens symboliques** : L'option `-UseSymlinks` permet d'utiliser des liens symboliques au lieu de copies directes, ce qui peut résoudre certains problèmes de chemins.

2. **Éviter les espaces dans les chemins** : Les espaces dans les chemins peuvent causer des problèmes avec les hooks Git. Essayez de déplacer le projet dans un répertoire sans espaces.

3. **Utiliser l'option `--no-verify`** : Si les hooks bloquent un commit ou un push urgent, vous pouvez utiliser l'option `--no-verify` pour ignorer les hooks :
   ```bash
   git commit --no-verify -m "Commit urgent"
   git push --no-verify
   ```

## Notifications

Le projet inclut un système de notifications par email pour informer l'équipe des résultats des vérifications CI/CD et des déploiements.

### Notifications dans GitHub Actions

Le workflow GitHub Actions envoie des notifications par email dans les cas suivants :

1. **Échec du pipeline CI/CD** : Un email est envoyé lorsque le pipeline échoue, avec des détails sur la branche, le commit et un lien vers les logs.

2. **Succès du pipeline CI/CD** : Un email est envoyé lorsque le pipeline réussit pour les branches `main` et `develop`, avec des détails sur l'environnement de déploiement.

### Notifications dans le script de déploiement réel

Le script `deploy-real.ps1` peut envoyer des notifications par email dans les cas suivants :

1. **Échec des tests** : Un email est envoyé lorsque les tests échouent avant le déploiement.

2. **Échec du déploiement** : Un email est envoyé lorsque le déploiement échoue, avec des détails sur l'erreur.

3. **Succès du déploiement** : Un email est envoyé lorsque le déploiement réussit, avec des détails sur la version déployée.

### Configuration des notifications

Pour configurer les notifications par email dans GitHub Actions, vous devez ajouter les secrets suivants dans les paramètres du dépôt :

- `EMAIL_USERNAME` : Nom d'utilisateur pour le serveur SMTP
- `EMAIL_PASSWORD` : Mot de passe pour le serveur SMTP

Pour configurer les notifications par email dans le script de déploiement réel, utilisez les paramètres suivants :

```powershell
# Activer les notifications
.\scripts\ci\deploy-real.ps1 -Environment Production -SendNotification

# Spécifier une adresse email pour les notifications
.\scripts\ci\deploy-real.ps1 -Environment Production -SendNotification -NotificationEmail "admin@example.com"
```

## Test des hooks Git dans un environnement propre

Le projet inclut un script pour tester les hooks Git dans un environnement sans espaces dans les chemins. Ce script clone le dépôt dans un répertoire temporaire sans espaces et teste les hooks Git.

### Utilisation du script de test

Pour tester les hooks Git dans un environnement propre, utilisez le script `scripts/setup/test-hooks-clean-env.ps1` :

```powershell
# Tester les hooks Git dans un environnement propre
.\scripts\setup\test-hooks-clean-env.ps1

# Nettoyer le répertoire temporaire après les tests
.\scripts\setup\test-hooks-clean-env.ps1 -CleanupAfter

# Spécifier un répertoire temporaire personnalisé
.\scripts\setup\test-hooks-clean-env.ps1 -TempDir "D:\Temp\n8n_test"

# Afficher des informations détaillées pendant les tests
.\scripts\setup\test-hooks-clean-env.ps1 -Verbose
```

## Bonnes pratiques

1. **Exécutez les vérifications localement avant de pousser** : Utilisez le script `scripts/ci/run-ci-checks.ps1` pour exécuter les mêmes vérifications que le pipeline CI/CD avant de pousser vos modifications.

2. **Créez des tests unitaires** : Créez des tests unitaires pour chaque nouvelle fonctionnalité ou correction de bug. Les tests unitaires permettent de détecter les régressions et de documenter le comportement attendu du code.

3. **Testez les hooks Git dans un environnement propre** : Utilisez le script `scripts/setup/test-hooks-clean-env.ps1` pour tester les hooks Git dans un environnement sans espaces dans les chemins.

4. **Utilisez le déploiement réel pour les environnements de production** : Utilisez le script `scripts/ci/deploy-real.ps1` pour déployer vers les environnements de production, car il inclut des vérifications et des notifications plus avancées.

5. **Configurez les notifications par email** : Configurez les notifications par email pour être informé des résultats des vérifications CI/CD et des déploiements.

6. **Respectez les conventions de style** : Suivez les conventions de style de code pour PowerShell et Python. Cela rend le code plus lisible et facilite la collaboration.

7. **Ne commettez pas d'informations sensibles** : N'incluez jamais de mots de passe, de clés API ou d'autres informations sensibles dans le code. Utilisez des variables d'environnement ou des fichiers de configuration externes.

8. **Utilisez des branches de fonctionnalité** : Créez une branche pour chaque nouvelle fonctionnalité ou correction de bug. Cela permet de travailler sur plusieurs fonctionnalités en parallèle sans interférence.

9. **Créez des pull requests** : Utilisez des pull requests pour faire réviser votre code avant de le fusionner dans les branches principales. Cela permet de détecter les problèmes avant qu'ils n'affectent les autres développeurs.

10. **Documentez les changements** : Documentez les changements importants dans le journal de bord et les fichiers README appropriés. Cela aide les autres développeurs à comprendre les modifications et leur impact.

## Conclusion

L'intégration CI/CD est un outil puissant pour maintenir la qualité du code et automatiser les processus de déploiement. En suivant les bonnes pratiques et en utilisant les outils fournis, vous pouvez contribuer à maintenir un code de haute qualité et à faciliter la collaboration au sein de l'équipe.
