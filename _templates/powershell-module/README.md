# Templates de modules PowerShell

Ce répertoire contient des templates Hygen pour générer des modules PowerShell optimisés pour le projet EMAIL_SENDER_1.

## Types de modules disponibles

### 1. Module standard

Un module PowerShell standard avec une structure organisée et une documentation complète.

Caractéristiques :
- Structure de dossiers standard (Public, Private, Tests, etc.)
- Manifeste de module (.psd1)
- Fichier de module principal (.psm1)
- Documentation intégrée
- Tests unitaires avec Pester
- Initialisation automatique du module

### 2. Module avancé

Un module PowerShell avancé avec gestion d'état intégrée.

Caractéristiques :
- Toutes les fonctionnalités du module standard
- Système de gestion d'état persistant
- Sauvegarde automatique de l'état
- Fonctions de manipulation d'état (Get/Set/Remove)
- Gestion des sauvegardes d'état

### 3. Module d'extension

Un module PowerShell conçu pour étendre les fonctionnalités d'autres modules.

Caractéristiques :
- Toutes les fonctionnalités du module standard
- Système de points d'extension
- Gestionnaires d'événements
- Mécanisme d'enregistrement de modules étendus
- Chargement automatique des extensions

## Utilisation

### Générer un nouveau module PowerShell

```bash
npx hygen powershell-module new
```

Ou avec des paramètres spécifiques :

```bash
npx hygen powershell-module new --name NomDuModule --description "Description du module" --category core --type standard --author "Votre Nom"
```

#### Paramètres

- `--name` : Nom du module (obligatoire)
- `--description` : Description du module (par défaut: 'Module PowerShell standard')
- `--author` : Auteur du module (par défaut: 'Augment Agent')
- `--category` : Catégorie du module (par défaut: 'core')
- `--type` : Type de module (standard, advanced, extension) (par défaut: 'standard')

### Exemples

```bash
# Créer un module standard
npx hygen powershell-module new --name ConfigManager --category core --type standard

# Créer un module avancé avec gestion d'état
npx hygen powershell-module new --name StateManager --category utils --type advanced

# Créer un module d'extension
npx hygen powershell-module new --name ExtensionManager --category integration --type extension
```

## Structure des modules générés

```
NomDuModule/
├── NomDuModule.psd1     # Manifeste du module
├── NomDuModule.psm1     # Module principal
├── Public/              # Fonctions publiques
│   └── README.md        # Documentation des fonctions publiques
├── Private/             # Fonctions privées
│   └── README.md        # Documentation des fonctions privées
├── Tests/               # Tests Pester
│   └── NomDuModule.Tests.ps1
├── config/              # Fichiers de configuration
│   └── NomDuModule.config.json
├── logs/                # Fichiers de logs
│   └── ...
└── README.md            # Documentation du module
```

Les modules avancés et d'extension incluent des dossiers et fichiers supplémentaires spécifiques à leurs fonctionnalités.

## Tests

Pour tester les templates de modules PowerShell :

```powershell
.\development\scripts\tests\Test-PowerShellModuleTemplates.ps1
```

Options disponibles :
- `-TestStandard` : Teste uniquement le template de module standard
- `-TestAdvanced` : Teste uniquement le template de module avancé
- `-TestExtension` : Teste uniquement le template de module d'extension
- `-KeepGeneratedFiles` : Conserve les fichiers générés après les tests
- `-OutputFolder` : Spécifie un dossier de sortie personnalisé pour les tests
