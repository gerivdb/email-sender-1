---
to: development/scripts/{{category}}/modules/{{name}}/README.md
---
# Module <%= name %>

<%= description %>

## Installation

```powershell
# Copier le module dans un des dossiers de modules PowerShell
Copy-Item -Path ".\<%= name %>" -Destination "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\" -Recurse

# Importer le module
Import-Module <%= name %>
```

## Fonctionnalités

Ce module fournit les fonctionnalités suivantes :

- Fonctionnalité 1
- Fonctionnalité 2
- Fonctionnalité 3

## Commandes disponibles

```powershell
Get-Command -Module <%= name %>
```

## Structure du module

```
<%= name %>/
├── <%= name %>.psd1     # Manifeste du module
├── <%= name %>.psm1     # Module principal
├── Public/              # Fonctions publiques
│   └── ...
├── Private/             # Fonctions privées
│   └── ...
├── Tests/               # Tests Pester
│   └── <%= name %>.Tests.ps1
├── config/              # Fichiers de configuration
│   └── <%= name %>.config.json
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
Invoke-Pester -Path ".\<%= name %>\Tests\<%= name %>.Tests.ps1"
```

## Dépendances

- PowerShell 5.1 ou supérieur
- Module Pester (pour les tests uniquement)

## Auteur

<%= author %>

## Licence

Ce module est distribué sous licence MIT.
