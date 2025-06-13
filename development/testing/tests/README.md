# Tests

Ce répertoire contient les tests du projet.

## Structure

- **unit/** - Tests unitaires
- **integration/** - Tests d'intégration
- **performance/** - Tests de performance
- **e2e/** - Tests end-to-end
- **fixtures/** - Données de test
- **mocks/** - Mocks et stubs

## Exécution des tests

`powershell
# Exécuter tous les tests

Invoke-Pester

# Exécuter les tests unitaires

Invoke-Pester -Path ./unit

# Exécuter les tests d'intégration

Invoke-Pester -Path ./integration
`
"@

    "config" = @"
# Configuration

Ce répertoire contient les fichiers de configuration du projet.

## Structure

- **environments/** - Configurations d'environnement
- **settings/** - Paramètres généraux
- **schemas/** - Schémas de configuration
- **templates/** - Templates de configuration

## Utilisation

Les fichiers de configuration sont chargés automatiquement par l'application en fonction de l'environnement.
