# Module de compatibilité entre environnements

Ce module fournit des fonctions pour améliorer la compatibilité des scripts PowerShell entre différents environnements (Windows, Linux, macOS).

## Contenu

- **EnvironmentManager.psm1** : Module principal pour la gestion de la compatibilité entre environnements
- **Test-EnvironmentManager.ps1** : Script de test pour le module
- **Improve-ScriptCompatibility.ps1** : Script pour améliorer la compatibilité des scripts existants
- **README.md** : Documentation pour le module

## Fonctionnalités

### Détection d'environnement

- Détection automatique du système d'exploitation (Windows, Linux, macOS)
- Détection de la version et de l'édition de PowerShell
- Vérification de la compatibilité avec un environnement cible

### Gestion des chemins

- Normalisation des chemins pour la compatibilité entre environnements
- Vérification de l'existence des chemins de manière compatible
- Jointure de chemins de manière compatible

### Wrappers de commandes

- Exécution de commandes adaptées à l'environnement d'exécution
- Lecture et écriture de fichiers de manière compatible
- Remplacement des commandes spécifiques à Windows par des alternatives compatibles

### Amélioration de la compatibilité des scripts

- Analyse des scripts pour détecter les problèmes de compatibilité
- Modification automatique des scripts pour améliorer leur compatibilité
- Génération de rapports sur la compatibilité des scripts

## Utilisation

### Importation du module

```powershell
# Importer le module
Import-Module ".\scripts\maintenance\environment-compatibility\EnvironmentManager.psm1"

# Initialiser le module
Initialize-EnvironmentManager
```

### Détection d'environnement

```powershell
# Obtenir des informations sur l'environnement
$envInfo = Get-EnvironmentInfo
if ($envInfo.IsWindows) {
    # Code spécifique à Windows
}
elseif ($envInfo.IsLinux) {
    # Code spécifique à Linux
}
elseif ($envInfo.IsMacOS) {
    # Code spécifique à macOS
}

# Vérifier la compatibilité avec un environnement cible
$compatibility = Test-EnvironmentCompatibility -TargetOS "Windows" -MinimumPSVersion "5.1"
if ($compatibility.IsCompatible) {
    # Code compatible
}
else {
    Write-Warning "Environnement incompatible: $($compatibility.IncompatibilityReasons -join ', ')"
}
```

### Gestion des chemins

```powershell
# Normaliser un chemin
$normalizedPath = ConvertTo-CrossPlatformPath -Path "C:\Users\user\Documents\file.txt"
# Retourne "C:/Users/user/Documents/file.txt" sur Linux/macOS

# Vérifier si un chemin existe
$exists = Test-CrossPlatformPath -Path "C:\Users\user\Documents\file.txt"
if ($exists) {
    # Le chemin existe
}

# Joindre des chemins
$path = Join-CrossPlatformPath -Path "C:\Users" -ChildPath "user", "Documents", "file.txt"
# Retourne "C:\Users\user\Documents\file.txt" sur Windows
```

### Wrappers de commandes

```powershell
# Exécuter une commande adaptée à l'environnement
Invoke-CrossPlatformCommand -WindowsCommand "dir" -UnixCommand "ls -la"

# Lire le contenu d'un fichier
$content = Get-CrossPlatformContent -Path "C:\Users\user\Documents\file.txt"

# Écrire dans un fichier
Set-CrossPlatformContent -Path "C:\Users\user\Documents\file.txt" -Content "Hello, World!" -Force
```

### Amélioration de la compatibilité des scripts

```powershell
# Analyser et améliorer un script
.\Improve-ScriptCompatibility.ps1 -ScriptPath "C:\Scripts\script.ps1" -BackupFiles

# Analyser et améliorer tous les scripts d'un répertoire
.\Improve-ScriptCompatibility.ps1 -ScriptPath "C:\Scripts" -Recurse -BackupFiles

# Générer uniquement un rapport sans modifier les scripts
.\Improve-ScriptCompatibility.ps1 -ScriptPath "C:\Scripts" -Recurse -ReportOnly

# Afficher les modifications qui seraient apportées sans les appliquer
.\Improve-ScriptCompatibility.ps1 -ScriptPath "C:\Scripts\script.ps1" -WhatIf
```

## Exemples

### Exemple 1 : Script compatible avec Windows et Linux

```powershell
# Importer le module EnvironmentManager
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\maintenance\environment-compatibility\EnvironmentManager.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
}
else {
    Write-Warning "Module EnvironmentManager non trouvé: $modulePath"
}

# Initialiser le module
Initialize-EnvironmentManager

# Obtenir le chemin du répertoire temporaire
$tempDir = if ($IsWindows) {
    $env:TEMP
}
else {
    "/tmp"
}

# Créer un fichier temporaire
$tempFile = Join-CrossPlatformPath -Path $tempDir -ChildPath "test.txt"
Set-CrossPlatformContent -Path $tempFile -Content "Test" -Force

# Exécuter une commande adaptée à l'environnement
Invoke-CrossPlatformCommand -WindowsCommand "type $tempFile" -UnixCommand "cat $tempFile"

# Supprimer le fichier temporaire
Remove-Item -Path $tempFile -Force
```

### Exemple 2 : Vérification de la compatibilité avant l'exécution

```powershell
# Importer le module EnvironmentManager
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\maintenance\environment-compatibility\EnvironmentManager.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
}
else {
    Write-Warning "Module EnvironmentManager non trouvé: $modulePath"
}

# Initialiser le module
Initialize-EnvironmentManager

# Vérifier la compatibilité
$compatibility = Test-EnvironmentCompatibility -TargetOS "Windows" -MinimumPSVersion "5.1"
if (-not $compatibility.IsCompatible) {
    Write-Error "Ce script nécessite Windows avec PowerShell 5.1 ou supérieur."
    exit 1
}

# Code spécifique à Windows
# ...
```

## Tests

Pour tester le module, exécutez le script de test :

```powershell
.\Test-EnvironmentManager.ps1
```

Ce script teste toutes les fonctionnalités du module et affiche les résultats.
