# Module de compatibilitÃ© entre environnements

Ce module fournit des fonctions pour amÃ©liorer la compatibilitÃ© des scripts PowerShell entre diffÃ©rents environnements (Windows, Linux, macOS).

## Contenu

- **EnvironmentManager.psm1** : Module principal pour la gestion de la compatibilitÃ© entre environnements
- **Test-EnvironmentManager.ps1** : Script de test pour le module
- **Improve-ScriptCompatibility.ps1** : Script pour amÃ©liorer la compatibilitÃ© des scripts existants
- **README.md** : Documentation pour le module

## FonctionnalitÃ©s

### DÃ©tection d'environnement

- DÃ©tection automatique du systÃ¨me d'exploitation (Windows, Linux, macOS)
- DÃ©tection de la version et de l'Ã©dition de PowerShell
- VÃ©rification de la compatibilitÃ© avec un environnement cible

### Gestion des chemins

- Normalisation des chemins pour la compatibilitÃ© entre environnements
- VÃ©rification de l'existence des chemins de maniÃ¨re compatible
- Jointure de chemins de maniÃ¨re compatible

### Wrappers de commandes

- ExÃ©cution de commandes adaptÃ©es Ã  l'environnement d'exÃ©cution
- Lecture et Ã©criture de fichiers de maniÃ¨re compatible
- Remplacement des commandes spÃ©cifiques Ã  Windows par des alternatives compatibles

### AmÃ©lioration de la compatibilitÃ© des scripts

- Analyse des scripts pour dÃ©tecter les problÃ¨mes de compatibilitÃ©
- Modification automatique des scripts pour amÃ©liorer leur compatibilitÃ©
- GÃ©nÃ©ration de rapports sur la compatibilitÃ© des scripts

## Utilisation

### Importation du module

```powershell
# Importer le module
Import-Module ".\scripts\maintenance\environment-compatibility\EnvironmentManager.psm1"

# Initialiser le module
Initialize-EnvironmentManager
```

### DÃ©tection d'environnement

```powershell
# Obtenir des informations sur l'environnement
$envInfo = Get-EnvironmentInfo
if ($envInfo.IsWindows) {
    # Code spÃ©cifique Ã  Windows
}
elseif ($envInfo.IsLinux) {
    # Code spÃ©cifique Ã  Linux
}
elseif ($envInfo.IsMacOS) {
    # Code spÃ©cifique Ã  macOS
}

# VÃ©rifier la compatibilitÃ© avec un environnement cible
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

# VÃ©rifier si un chemin existe
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
# ExÃ©cuter une commande adaptÃ©e Ã  l'environnement
Invoke-CrossPlatformCommand -WindowsCommand "dir" -UnixCommand "ls -la"

# Lire le contenu d'un fichier
$content = Get-CrossPlatformContent -Path "C:\Users\user\Documents\file.txt"

# Ã‰crire dans un fichier
Set-CrossPlatformContent -Path "C:\Users\user\Documents\file.txt" -Content "Hello, World!" -Force
```

### AmÃ©lioration de la compatibilitÃ© des scripts

```powershell
# Analyser et amÃ©liorer un script
.\Improve-ScriptCompatibility.ps1 -ScriptPath "C:\Scripts\script.ps1" -BackupFiles

# Analyser et amÃ©liorer tous les scripts d'un rÃ©pertoire
.\Improve-ScriptCompatibility.ps1 -ScriptPath "C:\Scripts" -Recurse -BackupFiles

# GÃ©nÃ©rer uniquement un rapport sans modifier les scripts
.\Improve-ScriptCompatibility.ps1 -ScriptPath "C:\Scripts" -Recurse -ReportOnly

# Afficher les modifications qui seraient apportÃ©es sans les appliquer
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
    Write-Warning "Module EnvironmentManager non trouvÃ©: $modulePath"
}

# Initialiser le module
Initialize-EnvironmentManager

# Obtenir le chemin du rÃ©pertoire temporaire
$tempDir = if ($IsWindows) {
    $env:TEMP
}
else {
    "/tmp"
}

# CrÃ©er un fichier temporaire
$tempFile = Join-CrossPlatformPath -Path $tempDir -ChildPath "test.txt"
Set-CrossPlatformContent -Path $tempFile -Content "Test" -Force

# ExÃ©cuter une commande adaptÃ©e Ã  l'environnement
Invoke-CrossPlatformCommand -WindowsCommand "type $tempFile" -UnixCommand "cat $tempFile"

# Supprimer le fichier temporaire
Remove-Item -Path $tempFile -Force
```

### Exemple 2 : VÃ©rification de la compatibilitÃ© avant l'exÃ©cution

```powershell
# Importer le module EnvironmentManager
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\maintenance\environment-compatibility\EnvironmentManager.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
}
else {
    Write-Warning "Module EnvironmentManager non trouvÃ©: $modulePath"
}

# Initialiser le module
Initialize-EnvironmentManager

# VÃ©rifier la compatibilitÃ©
$compatibility = Test-EnvironmentCompatibility -TargetOS "Windows" -MinimumPSVersion "5.1"
if (-not $compatibility.IsCompatible) {
    Write-Error "Ce script nÃ©cessite Windows avec PowerShell 5.1 ou supÃ©rieur."
    exit 1
}

# Code spÃ©cifique Ã  Windows
# ...
```

## Tests

Pour tester le module, exÃ©cutez le script de test :

```powershell
.\Test-EnvironmentManager.ps1
```

Ce script teste toutes les fonctionnalitÃ©s du module et affiche les rÃ©sultats.
