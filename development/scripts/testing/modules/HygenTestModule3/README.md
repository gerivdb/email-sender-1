# Module HygenTestModule3

Module de test pour Hygen 3

## Installation

```powershell
# Copier le module dans un des dossiers de modules PowerShell

Copy-Item -Path ".\HygenTestModule3" -Destination "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\" -Recurse

# Importer le module

Import-Module HygenTestModule3
```plaintext
## Fonctionnalités

Ce module fournit les fonctionnalités suivantes :

- Fonctionnalité 1
- Fonctionnalité 2
- Fonctionnalité 3

## Commandes disponibles

```powershell
Get-Command -Module HygenTestModule3
```plaintext
## Structure du module

```plaintext
HygenTestModule3/
├── HygenTestModule3.psd1     # Manifeste du module

├── HygenTestModule3.psm1     # Module principal

├── Public/              # Fonctions publiques

│   └── ...
├── Private/             # Fonctions privées

│   └── ...
├── Tests/               # Tests Pester

│   └── HygenTestModule3.Tests.ps1
├── config/              # Fichiers de configuration

│   └── HygenTestModule3.config.json
├── logs/                # Fichiers de logs

│   └── ...
└── data/                # Données du module

    └── ...
```plaintext
## Exemples d'utilisation

```powershell
# Exemple 1

Get-Something -Parameter "Value"

# Exemple 2

Set-Something -Name "Name" -Value "Value"
```plaintext
## Tests

Ce module inclut des tests Pester. Pour exécuter les tests :

```powershell
Invoke-Pester -Path ".\HygenTestModule3\Tests\HygenTestModule3.Tests.ps1"
```plaintext
## Dépendances

- PowerShell 5.1 ou supérieur
- Module Pester (pour les tests uniquement)

## Auteur

Augment Agent

## Licence

Ce module est distribué sous licence MIT.

