# Module TestStandardModule

Module PowerShell standard pour les tests.

## Installation

```powershell
# Copier le module dans un des dossiers de modules PowerShell

Copy-Item -Path ".\TestStandardModule" -Destination "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\" -Recurse

# Importer le module

Import-Module TestStandardModule
```plaintext
## Fonctionnalités

Ce module fournit les fonctionnalités suivantes :

- Fonctionnalité 1
- Fonctionnalité 2
- Fonctionnalité 3

## Commandes disponibles

```powershell
Get-Command -Module TestStandardModule
```plaintext
## Structure du module

```plaintext
TestStandardModule/
├── TestStandardModule.psd1     # Manifeste du module

├── TestStandardModule.psm1     # Module principal

├── Public/              # Fonctions publiques

│   └── ...
├── Private/             # Fonctions privées

│   └── ...
├── Tests/               # Tests Pester

│   └── TestStandardModule.Tests.ps1
├── config/              # Fichiers de configuration

│   └── TestStandardModule.config.json
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
Invoke-Pester -Path ".\TestStandardModule\Tests\TestStandardModule.Tests.ps1"
```plaintext
## Dépendances

- PowerShell 5.1 ou supérieur
- Module Pester (pour les tests uniquement)

## Auteur

Test User

## Licence

Ce module est distribué sous licence MIT.
