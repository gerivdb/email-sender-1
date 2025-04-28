# Outils de développement

Ce dossier contient des **bibliothèques, modules et utilitaires réutilisables** qui fournissent des fonctionnalités communes utilisées par les scripts ou d'autres parties du projet.

## Différence avec le dossier `scripts`

- **Tools** : Bibliothèques, modules et utilitaires réutilisables qui fournissent des fonctionnalités communes
- **Scripts** : Programmes exécutables qui réalisent des tâches spécifiques

Les outils dans ce dossier sont généralement importés et utilisés par les scripts du dossier `development/scripts` plutôt que d'être exécutés directement.

## Structure

Les outils sont organisés par type de fonctionnalité :

- **analysis-tools/** - Outils d'analyse de code et de performance
- **augment-tools/** - Configuration et outils pour Augment
- **cache-tools/** - Gestionnaires de cache et outils de mise en cache
- **converters-tools/** - Convertisseurs de formats (CSV, YAML, JSON, etc.)
- **detectors-tools/** - Détecteurs de problèmes et d'anomalies
- **documentation-tools/** - Outils de génération de documentation
- **error-handling-tools/** - Outils de gestion des erreurs
- **examples-tools/** - Exemples d'utilisation des outils
- **git-tools/** - Outils pour Git
- **integrations-tools/** - Intégrations avec d'autres systèmes
- **json-tools/** - Outils de manipulation de JSON
- **markdown-tools/** - Outils de manipulation de Markdown
- **optimization-tools/** - Outils d'optimisation
- **reports-tools/** - Générateurs de rapports
- **roadmap-tools/** - Outils pour la roadmap
- **testing-tools/** - Outils de test
- **utilities-tools/** - Utilitaires divers

## Conventions de nommage

Les modules suivent généralement la convention de nommage :
- Modules PowerShell : `NomModule.psm1` et `NomModule.psd1`
- Bibliothèques de fonctions : `NomFonctionnalité.ps1`

## Utilisation

Pour utiliser un outil dans un script :

```powershell
# Importer un module
Import-Module -Name "$PSScriptRoot\..\..\tools\converters-tools\Format-Converters.psm1"

# Utiliser une fonction du module
Convert-FileFormat -Path "chemin/vers/fichier" -TargetFormat "json"
```

## Développement

Pour ajouter un nouvel outil :

1. Identifiez le type de fonctionnalité approprié
2. Créez le module ou la bibliothèque en suivant la convention de nommage
3. Documentez l'outil avec des commentaires en début de fichier et des exemples d'utilisation
4. Créez ou mettez à jour le README.md du sous-dossier pour expliquer l'utilisation de l'outil



