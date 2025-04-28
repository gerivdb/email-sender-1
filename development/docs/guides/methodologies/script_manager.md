# Guide du Script Manager

Ce document explique la structure et l'utilisation du Script Manager dans le projet EMAIL_SENDER_1.

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Structure du dossier](#structure-du-dossier)
3. [Fonctionnalités](#fonctionnalités)
4. [Utilisation](#utilisation)
5. [Intégration avec Hygen](#intégration-avec-hygen)
6. [Intégration avec MCP Desktop Commander](#intégration-avec-mcp-desktop-commander)
7. [Hooks Git](#hooks-git)
8. [Tests](#tests)
9. [Bonnes pratiques](#bonnes-pratiques)
10. [Résolution des problèmes](#résolution-des-problèmes)

## Vue d'ensemble

Le Script Manager est un ensemble d'outils pour gérer, analyser et organiser les scripts du projet EMAIL_SENDER_1. Il permet de :

- Indexer et cataloguer tous les scripts du projet
- Analyser les scripts pour en extraire des informations structurelles
- Détecter les dépendances entre les scripts
- Évaluer la qualité du code
- Organiser les scripts dans une structure de dossiers cohérente
- Générer de nouveaux scripts avec une structure standardisée
- Documenter les scripts et les modules

Le Script Manager suit les principes SOLID, DRY, KISS et Clean Code pour offrir une solution modulaire, maintenable et extensible.

## Structure du dossier

Le dossier `development/scripts/manager` est organisé en sous-dossiers thématiques :

- **analysis** : Scripts d'analyse des scripts
- **organization** : Scripts d'organisation des scripts
- **inventory** : Scripts de gestion de l'inventaire des scripts
- **documentation** : Scripts de génération de documentation
- **monitoring** : Scripts de surveillance des scripts
- **optimization** : Scripts d'optimisation des scripts
- **testing** : Scripts de test
- **configuration** : Scripts et fichiers de configuration
- **generation** : Scripts de génération de nouveaux scripts
- **integration** : Scripts d'intégration avec d'autres outils
- **ui** : Scripts d'interface utilisateur
- **core** : Scripts principaux du manager

Chaque sous-dossier peut contenir des scripts et des modules :

- Les scripts sont des fichiers PowerShell (.ps1) qui peuvent être exécutés directement
- Les modules sont des fichiers PowerShell (.psm1) qui contiennent des fonctions réutilisables

## Fonctionnalités

### Inventaire des scripts

Le Script Manager maintient un inventaire de tous les scripts du projet, avec des informations telles que :

- Nom et chemin du script
- Type de script (PowerShell, Python, Batch, Shell)
- Auteur et version
- Description et tags
- Date de création et de dernière modification

Cet inventaire peut être consulté, filtré et exporté dans différents formats (CSV, JSON, HTML).

### Analyse des scripts

Le Script Manager peut analyser les scripts pour en extraire des informations structurelles, telles que :

- Nombre de lignes de code et de commentaires
- Fonctions et variables
- Imports et dépendances
- Structures conditionnelles et boucles
- Classes et méthodes (pour les langages orientés objet)

Cette analyse permet d'évaluer la qualité du code, de détecter les problèmes potentiels et de proposer des améliorations.

### Organisation des scripts

Le Script Manager peut organiser les scripts dans une structure de dossiers cohérente, basée sur des règles définies dans le fichier `config/rules.json`. Ces règles peuvent être basées sur :

- Le contenu du script
- Le chemin du script
- Le nom du script
- Le type de script

L'organisation des scripts est automatisée grâce à un hook pre-commit Git qui détecte les scripts ajoutés à la racine du dossier manager et les déplace dans les sous-dossiers appropriés.

### Génération de scripts

Le Script Manager utilise Hygen pour générer de nouveaux scripts avec une structure standardisée. Des templates sont disponibles pour différents types de scripts et modules, avec des paramètres personnalisables.

### Documentation

Le Script Manager peut générer automatiquement de la documentation pour les scripts et les modules, en extrayant les informations des commentaires et des en-têtes. Cette documentation peut être exportée dans différents formats (Markdown, HTML, PDF).

## Utilisation

### Commandes principales

Le Script Manager peut être utilisé via des commandes PowerShell ou via MCP Desktop Commander.

#### Via PowerShell

```powershell
# Organiser les scripts du manager
.\development\scripts\manager\organization\Organize-ManagerScripts.ps1 -Force

# Afficher l'inventaire des scripts
.\development\scripts\manager\inventory\Show-ScriptInventory.ps1

# Analyser les scripts
.\development\scripts\manager\analysis\Analyze-Scripts.ps1

# Tester les scripts du manager
.\development\scripts\manager\testing\Test-ManagerScripts.ps1
```

#### Via MCP Desktop Commander

```powershell
# Lancer MCP Desktop Commander
npx -y @wonderwhy-er/desktop-commander
```

Puis sélectionner la commande `manager` et la sous-commande souhaitée.

### Création de nouveaux scripts

Pour créer un nouveau script avec Hygen :

```powershell
# Via PowerShell
npx hygen script new

# Via MCP Desktop Commander
# Sélectionner la commande `manager` puis `create-script`
```

Suivez les instructions pour spécifier le nom, la description et la catégorie du script.

### Création de nouveaux modules

Pour créer un nouveau module avec Hygen :

```powershell
# Via PowerShell
npx hygen module new

# Via MCP Desktop Commander
# Sélectionner la commande `manager` puis `create-module`
```

Suivez les instructions pour spécifier le nom, la description et la catégorie du module.

## Intégration avec Hygen

Le Script Manager utilise Hygen pour générer de nouveaux scripts et modules avec une structure standardisée. Les templates Hygen sont stockés dans le dossier `_templates` et peuvent être personnalisés selon les besoins du projet.

### Structure des templates

- `_templates/.hygen.js` : Configuration générale de Hygen
- `_templates/script/new/` : Templates pour les nouveaux scripts
- `_templates/module/new/` : Templates pour les nouveaux modules

### Personnalisation des templates

Les templates peuvent être personnalisés en modifiant les fichiers EJS dans les dossiers `_templates`. Par exemple, pour ajouter un nouveau paramètre à un script :

1. Modifiez le fichier `_templates/script/new/prompt.js` pour ajouter le paramètre
2. Modifiez le fichier `_templates/script/new/script.ejs.t` pour utiliser le paramètre

## Intégration avec MCP Desktop Commander

Le Script Manager est intégré avec MCP Desktop Commander pour faciliter l'exécution des commandes. La configuration est stockée dans le fichier `configuration/mcp-config.json` et peut être personnalisée selon les besoins du projet.

### Structure de la configuration

```json
{
  "mcpServers": {
    "desktop-commander": {
      "command": "npx",
      "args": ["-y", "@wonderwhy-er/desktop-commander"]
    }
  },
  "commands": {
    "manager": {
      "description": "Commandes du Script Manager",
      "subcommands": {
        "organize": {
          "description": "Organiser les scripts du manager",
          "command": "powershell.exe",
          "args": ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "development/scripts/manager/organization/Organize-ManagerScripts.ps1", "-Force"]
        },
        // Autres sous-commandes...
      }
    }
  }
}
```

### Personnalisation de la configuration

La configuration peut être personnalisée en modifiant le fichier `configuration/mcp-config.json`. Par exemple, pour ajouter une nouvelle sous-commande :

1. Ajoutez la sous-commande dans la section `commands.manager.subcommands`
2. Spécifiez la description, la commande et les arguments

## Hooks Git

Le Script Manager utilise des hooks Git pour automatiser l'organisation des scripts. Le hook pre-commit détecte les scripts ajoutés à la racine du dossier manager et les déplace dans les sous-dossiers appropriés.

### Installation du hook

```powershell
# Via PowerShell
.\development\scripts\manager\git\Install-ManagerPreCommitHook.ps1 -Force

# Via MCP Desktop Commander
# Sélectionner la commande `manager` puis `install-hooks`
```

### Fonctionnement du hook

Le hook pre-commit vérifie si des fichiers PowerShell ont été ajoutés à la racine du dossier manager. Si c'est le cas, il exécute le script `Organize-ManagerScripts.ps1` pour les déplacer dans les sous-dossiers appropriés, puis ajoute les fichiers déplacés au commit en cours.

## Tests

Le Script Manager inclut des tests unitaires pour vérifier le bon fonctionnement des scripts. Ces tests sont basés sur le framework Pester et peuvent être exécutés via PowerShell ou MCP Desktop Commander.

### Exécution des tests

```powershell
# Via PowerShell
.\development\scripts\manager\testing\Test-ManagerScripts.ps1

# Via MCP Desktop Commander
# Sélectionner la commande `manager` puis `test`
```

### Structure des tests

Les tests sont organisés en contextes et en cas de test, selon les bonnes pratiques de Pester :

```powershell
Describe "Tests des scripts du manager" {
    Context "Tests de la fonction Get-ScriptCategory" {
        It "Devrait retourner 'analysis' pour un fichier contenant 'analyze' dans son nom" {
            Get-ScriptCategory -FileName "Analyze-Scripts.ps1" | Should -Be "analysis"
        }
        // Autres cas de test...
    }
    // Autres contextes...
}
```

## Bonnes pratiques

Le Script Manager suit les bonnes pratiques suivantes :

### SOLID

- **S**ingle Responsibility Principle : Chaque module a une responsabilité unique
- **O**pen/Closed Principle : Les modules sont ouverts à l'extension mais fermés à la modification
- **L**iskov Substitution Principle : Les sous-modules peuvent être remplacés sans affecter le comportement
- **I**nterface Segregation Principle : Les interfaces sont spécifiques et cohérentes
- **D**ependency Inversion Principle : Les modules dépendent d'abstractions, pas d'implémentations

### DRY (Don't Repeat Yourself)

- Factorisation du code commun dans des fonctions réutilisables
- Utilisation de modules pour éviter la duplication de code
- Centralisation des configurations et des règles

### KISS (Keep It Simple, Stupid)

- Fonctions courtes et focalisées
- Noms de variables et de fonctions explicites
- Documentation claire et concise
- Éviter les solutions complexes quand des solutions simples existent

### Clean Code

- Code lisible et bien commenté
- Nommage significatif
- Gestion des erreurs appropriée
- Tests unitaires
- Documentation à jour

## Résolution des problèmes

### Problèmes courants

1. **Erreur lors de la création d'un script avec Hygen**
   - Vérifiez que Hygen est correctement installé : `npx hygen --version`
   - Vérifiez que les templates existent : `Get-ChildItem -Path "development\scripts\manager\_templates"`

2. **Erreur lors de l'organisation des scripts**
   - Vérifiez que le script `Organize-ManagerScripts.ps1` existe : `Test-Path -Path "development\scripts\manager\organization\Organize-ManagerScripts.ps1"`
   - Vérifiez que les sous-dossiers existent : `Get-ChildItem -Path "development\scripts\manager" -Directory`

3. **Erreur lors de l'exécution des tests**
   - Vérifiez que Pester est correctement installé : `Get-Module -Name Pester -ListAvailable`
   - Vérifiez que les scripts à tester existent : `Test-Path -Path "development\scripts\manager\organization\Organize-ManagerScripts.ps1"`

4. **Erreur lors de l'utilisation de MCP Desktop Commander**
   - Vérifiez que la configuration existe : `Test-Path -Path "development\scripts\manager\configuration\mcp-config.json"`
   - Vérifiez que les commandes sont correctement définies : `Get-Content -Path "development\scripts\manager\configuration\mcp-config.json"`

### Commandes de diagnostic

1. **Vérifier la structure des dossiers**
   ```powershell
   Get-ChildItem -Path "development\scripts\manager" -Directory | Select-Object Name
   ```

2. **Vérifier les scripts existants**
   ```powershell
   Get-ChildItem -Path "development\scripts\manager" -Recurse -File -Filter "*.ps1" | Select-Object FullName
   ```

3. **Vérifier les modules existants**
   ```powershell
   Get-ChildItem -Path "development\scripts\manager" -Recurse -File -Filter "*.psm1" | Select-Object FullName
   ```

4. **Vérifier les templates Hygen**
   ```powershell
   Get-ChildItem -Path "development\scripts\manager\_templates" -Recurse | Select-Object FullName
   ```

5. **Vérifier la configuration MCP Desktop Commander**
   ```powershell
   Get-Content -Path "development\scripts\manager\configuration\mcp-config.json"
   ```

6. **Vérifier le hook pre-commit**
   ```powershell
   Get-Content -Path ".git\hooks\pre-commit"
   ```
