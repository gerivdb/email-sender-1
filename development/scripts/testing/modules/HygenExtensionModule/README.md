# Module HygenExtensionModule

Module d'extension de test pour Hygen

## Installation

```powershell
# Copier le module dans un des dossiers de modules PowerShell
Copy-Item -Path ".\HygenExtensionModule" -Destination "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\" -Recurse

# Importer le module
Import-Module HygenExtensionModule
```

## Fonctionnalités

Ce module fournit les fonctionnalités suivantes :

- Fonctionnalité 1
- Fonctionnalité 2
- Fonctionnalité 3

## Commandes disponibles

```powershell
Get-Command -Module HygenExtensionModule
```

## Structure du module

```
HygenExtensionModule/
├── HygenExtensionModule.psd1     # Manifeste du module
├── HygenExtensionModule.psm1     # Module principal
├── Public/              # Fonctions publiques
│   └── ...
├── Private/             # Fonctions privées
│   └── ...
├── Tests/               # Tests Pester
│   └── HygenExtensionModule.Tests.ps1
├── config/              # Fichiers de configuration
│   └── HygenExtensionModule.config.json
├── logs/                # Fichiers de logs
│   └── ...
└── data/                # Données du module
    └── ...
```

## Exemples d'utilisation

```powershell
# Exemple 1
Get-Something -Parameter "Value"

# Exemple 2
Set-Something -Name "Name" -Value "Value"
```

## Tests

Ce module inclut des tests Pester. Pour exécuter les tests :

```powershell
Invoke-Pester -Path ".\HygenExtensionModule\Tests\HygenExtensionModule.Tests.ps1"
```

## Dépendances

- PowerShell 5.1 ou supérieur
- Module Pester (pour les tests uniquement)

## Auteur

Augment Agent

## Licence

Ce module est distribué sous licence MIT.

