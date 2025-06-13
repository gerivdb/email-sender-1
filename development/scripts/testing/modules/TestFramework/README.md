# Module TestFramework

Framework de test minimal pour les tests unitaires PowerShell dans le projet EMAIL_SENDER_1.

## Installation

```powershell
# Copier le module dans un des dossiers de modules PowerShell

Copy-Item -Path ".\TestFramework" -Destination "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\" -Recurse

# Importer le module

Import-Module TestFramework
```plaintext
## Fonctionnalités

Ce module fournit un framework minimal pour standardiser les tests unitaires PowerShell :

- Configuration simplifiée de l'environnement de test
- Création d'environnements de test temporaires
- Génération de données de test
- Création de mocks pour les tests
- Vérification de la disponibilité des fonctions
- Nettoyage de l'environnement après les tests

## Commandes disponibles

```powershell
Get-Command -Module TestFramework
```plaintext
## Structure du module

```plaintext
TestFramework/
├── TestFramework.psd1     # Manifeste du module

├── TestFramework.psm1     # Module principal

├── Public/                # Fonctions publiques

│   ├── New-TestMock.ps1
│   ├── New-TestData.ps1
│   └── Test-FunctionAvailability.ps1
├── Private/               # Fonctions privées

│   └── ...
├── Tests/                 # Tests Pester

│   └── TestFramework.Tests.ps1
├── config/                # Fichiers de configuration

│   └── TestFramework.config.json
├── logs/                  # Fichiers de logs

│   └── ...
├── data/                  # Données de test

│   └── ...
└── results/               # Résultats de test

    └── ...
```plaintext
## Exemples d'utilisation

### Configuration de l'environnement de test

```powershell
# Configurer l'environnement de test pour un module

$testSetup = Invoke-TestSetup -ModuleName "MonModule"

# Utiliser les informations du module

$testSetup.Functions | ForEach-Object { Write-Host $_.Name }
```plaintext
### Création d'un environnement de test temporaire

```powershell
# Créer un environnement de test temporaire

$env = New-TestEnvironment -TestName "MonTest" -Files @{
    "test.txt" = "Contenu du fichier"
    "config.json" = '{"setting": "value"}'
} -Folders @("dossier1", "dossier2")

# Utiliser l'environnement

$filePath = Join-Path -Path $env.Path -ChildPath "test.txt"
$content = Get-Content -Path $filePath

# Nettoyer l'environnement

$env.Cleanup()
```plaintext
### Génération de données de test

```powershell
# Générer une chaîne aléatoire

$randomString = New-TestData -Type String -Length 10

# Générer un nombre aléatoire

$randomNumber = New-TestData -Type Number -Min 1 -Max 100

# Générer un tableau d'objets

$users = New-TestData -Type Array -Count 5 -CustomGenerator {
    param($i)
    return @{
        Id = $i + 1
        Name = "User$($i + 1)"
        Email = "user$($i + 1)@example.com"
    }
}

# Générer un objet JSON

$jsonData = New-TestData -Type Json -Properties @{
    Id = { 1 }
    Name = { "Test" }
    Items = { @("Item1", "Item2", "Item3") }
}
```plaintext
### Création de mocks pour les tests

```powershell
# Créer un mock pour Get-Content

New-TestMock -CommandName "Get-Content" -MockScript {
    return "Contenu mocké"
}

# Créer un mock avec un filtre de paramètres

New-TestMock -CommandName "Invoke-RestMethod" -ParameterFilter {
    $Uri -like "*api/users*"
} -MockScript {
    return @{
        id = 1
        name = "Test"
        email = "test@example.com"
    }
}
```plaintext
### Vérification de la disponibilité des fonctions

```powershell
# Vérifier si une fonction est disponible

$result = Test-FunctionAvailability -FunctionName "Get-Content"

# Vérifier si plusieurs fonctions sont disponibles

$results = Test-FunctionAvailability -FunctionName "Get-Content", "Set-Content", "Remove-Item"

# Vérifier si une fonction est disponible dans un module spécifique

$result = Test-FunctionAvailability -FunctionName "Get-AzureRmVM" -ModuleName "AzureRM.Compute"

# Lever une exception si la fonction n'est pas disponible

try {
    Test-FunctionAvailability -FunctionName "Get-NonExistentFunction" -ThrowOnError
}
catch {
    Write-Host "La fonction n'est pas disponible : $_"
}
```plaintext
### Nettoyage après les tests

```powershell
# Nettoyer l'environnement après les tests

Invoke-TestCleanup -ModuleName "MonModule"
```plaintext
## Tests

Ce module inclut des tests Pester. Pour exécuter les tests :

```powershell
Invoke-Pester -Path ".\TestFramework\Tests\TestFramework.Tests.ps1"
```plaintext
## Dépendances

- PowerShell 5.1 ou supérieur
- Module Pester (pour les tests unitaires)

## Auteur

Augment Agent

## Licence

Ce module est distribué sous licence MIT.
