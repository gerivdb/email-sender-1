# Guide de génération de modules PowerShell

Ce guide explique comment générer des modules PowerShell à partir des templates disponibles dans le projet EMAIL_SENDER_1.

## Types de modules disponibles

Le projet propose trois types de modules PowerShell :

1. **Module standard** : Un module PowerShell de base avec une structure organisée et une documentation complète.
2. **Module avancé** : Un module PowerShell avec gestion d'état intégrée, permettant de stocker et de récupérer des données persistantes.
3. **Module d'extension** : Un module PowerShell conçu pour étendre les fonctionnalités d'autres modules via un système de points d'extension.

## Utilisation du script de génération

Le script `New-PowerShellModuleFromTemplate.ps1` permet de générer facilement un nouveau module PowerShell à partir des templates disponibles.

### Syntaxe

```powershell
.\development\scripts\utils\New-PowerShellModuleFromTemplate.ps1 -Name <nom_du_module> -Description <description> -Category <catégorie> -Type <type> [-Author <auteur>] [-Force]
```

### Paramètres

- **Name** (obligatoire) : Nom du module PowerShell à générer.
- **Description** (facultatif) : Description du module PowerShell. Par défaut : "Module PowerShell".
- **Category** (facultatif) : Catégorie du module. Valeurs possibles : core, utils, analysis, reporting, integration, maintenance, testing, documentation, optimization. Par défaut : "core".
- **Type** (facultatif) : Type de module. Valeurs possibles : standard, advanced, extension. Par défaut : "standard".
- **Author** (facultatif) : Auteur du module. Par défaut : "Augment Agent".
- **Force** (facultatif) : Si spécifié, écrase le module existant s'il existe déjà.

### Exemples

#### Générer un module standard

```powershell
.\development\scripts\utils\New-PowerShellModuleFromTemplate.ps1 -Name "ConfigManager" -Description "Module de gestion de configuration" -Category "core" -Type "standard"
```

#### Générer un module avancé avec gestion d'état

```powershell
.\development\scripts\utils\New-PowerShellModuleFromTemplate.ps1 -Name "StateManager" -Description "Module de gestion d'état" -Category "utils" -Type "advanced"
```

#### Générer un module d'extension

```powershell
.\development\scripts\utils\New-PowerShellModuleFromTemplate.ps1 -Name "ExtensionManager" -Description "Module d'extension" -Category "integration" -Type "extension"
```

#### Écraser un module existant

```powershell
.\development\scripts\utils\New-PowerShellModuleFromTemplate.ps1 -Name "ConfigManager" -Description "Module de gestion de configuration amélioré" -Category "core" -Type "standard" -Force
```

## Structure des modules générés

### Module standard

```
ModuleName/
├── ModuleName.psd1     # Manifeste du module
├── ModuleName.psm1     # Module principal
├── Public/             # Fonctions publiques
│   └── README.md       # Documentation des fonctions publiques
├── Private/            # Fonctions privées
│   └── README.md       # Documentation des fonctions privées
├── Tests/              # Tests Pester
│   └── ModuleName.Tests.ps1
├── config/             # Fichiers de configuration
│   └── ModuleName.config.json
├── logs/               # Fichiers de logs
│   └── ...
├── data/               # Données du module
│   └── ...
└── README.md           # Documentation du module
```

### Module avancé

En plus de la structure du module standard, le module avancé inclut :

```
ModuleName/
├── ...
├── state/              # État persistant du module
│   ├── ModuleName.state.json
│   └── backup/         # Sauvegardes de l'état
│       └── ...
└── ...
```

### Module d'extension

En plus de la structure du module standard, le module d'extension inclut :

```
ModuleName/
├── ...
├── extensions/         # Extensions du module
│   └── ...
└── ...
```

## Fonctionnalités spécifiques

### Module standard

- Structure de dossiers organisée
- Documentation intégrée
- Gestion des configurations
- Tests unitaires avec Pester

### Module avancé

- Toutes les fonctionnalités du module standard
- Gestion d'état persistant
- Fonctions de manipulation d'état (Get/Set/Remove)
- Sauvegarde automatique de l'état
- Restauration de l'état

### Module d'extension

- Toutes les fonctionnalités du module standard
- Système de points d'extension
- Gestionnaires d'événements
- Mécanisme d'enregistrement de modules étendus
- Chargement automatique des extensions

## Bonnes pratiques

1. **Nommage des modules** : Utilisez des noms descriptifs et suivez la convention PascalCase (ex: ConfigManager, StateManager).
2. **Organisation des fonctions** : Placez les fonctions publiques dans le dossier `Public` et les fonctions privées dans le dossier `Private`.
3. **Documentation** : Documentez chaque fonction avec des commentaires d'aide PowerShell.
4. **Tests** : Écrivez des tests unitaires pour chaque fonction publique.
5. **Gestion des erreurs** : Implémentez une gestion des erreurs robuste avec try/catch.
6. **Logging** : Utilisez `Write-Verbose` pour le logging détaillé.
7. **ShouldProcess** : Utilisez `SupportsShouldProcess` pour les fonctions qui modifient l'état du système.

## Dépannage

### Le module n'est pas généré correctement

- Vérifiez que vous avez spécifié un nom de module valide.
- Assurez-vous que la catégorie spécifiée est valide.
- Si le module existe déjà, utilisez le paramètre `-Force` pour l'écraser.

### Les fonctions du module ne sont pas exportées

- Vérifiez que les fonctions sont placées dans le dossier `Public`.
- Assurez-vous que les noms des fichiers correspondent aux noms des fonctions.

### Les tests unitaires échouent

- Vérifiez que le module Pester est installé.
- Assurez-vous que les fonctions testées sont correctement implémentées.
- Vérifiez que les chemins dans les tests sont corrects.
