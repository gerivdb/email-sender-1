# Module Path-Manager

## Description

Le module Path-Manager est un gestionnaire de chemins pour les projets PowerShell. Il permet de définir des mappings de chemins et de résoudre des chemins relatifs par rapport à ces mappings.

## Fonctionnalités

- Initialisation du module avec un répertoire racine de projet
- Découverte automatique des répertoires de premier niveau
- Définition de mappings de chemins personnalisés
- Résolution de chemins relatifs par rapport à des mappings
- Calcul de chemins relatifs entre deux chemins
- Normalisation des chemins pour la compatibilité cross-platform
- Vérification si un chemin est dans le projet
- Journalisation des opérations avec différents niveaux de verbosité
- Gestion avancée des erreurs avec des types d'exceptions personnalisés
- Système de cache configurable pour améliorer les performances

## Installation

1. Copiez le fichier `Path-Manager.psm1` dans un répertoire de modules PowerShell
2. Importez le module avec `Import-Module Path-Manager`

## Utilisation

### Initialisation du module

```powershell
# Initialisation simple avec le répertoire courant comme racine
Initialize-PathManager

# Initialisation avec un répertoire spécifique comme racine
Initialize-PathManager -ProjectRootPath "C:\Projects\MonProjet"

# Initialisation avec découverte automatique des répertoires de premier niveau
Initialize-PathManager -DiscoverDirectories

# Initialisation avec des mappings personnalisés
Initialize-PathManager -InitialMappings @{
    "src" = "source"
    "docs" = "documentation"
}

# Initialisation avec journalisation
Initialize-PathManager -EnableLogging -LogLevel "Debug"
```

### Gestion des mappings

```powershell
# Ajouter un mapping
Add-PathMapping -Name "scripts" -Path "scripts"

# Ajouter un mapping et créer le répertoire s'il n'existe pas
Add-PathMapping -Name "logs" -Path "logs" -CreateIfNotExists

# Remplacer un mapping existant
Add-PathMapping -Name "scripts" -Path "new-scripts" -Force

# Obtenir tous les mappings
Get-PathMappings

# Obtenir les mappings avec des détails
Get-PathMappings -IncludeDetails

# Obtenir les mappings sous forme d'objet
Get-PathMappings -AsObject
```

### Résolution de chemins

```powershell
# Résoudre un chemin relatif à la racine du projet
Get-ProjectPath -PathOrMappingName "docs\index.html"

# Résoudre un chemin relatif à un mapping
Get-ProjectPath -PathOrMappingName "helper.ps1" -BaseMappingName "scripts"

# Résoudre un chemin et vérifier son existence
Get-ProjectPath -PathOrMappingName "config.json" -VerifyExists

# Calculer un chemin relatif par rapport à la racine
Get-RelativePath -AbsolutePath "C:\Projects\MonProjet\docs\index.html"

# Calculer un chemin relatif par rapport à un mapping
Get-RelativePath -AbsolutePath "C:\Projects\MonProjet\scripts\helper.ps1" -BaseMappingName "scripts"
```

### Utilitaires de chemins

```powershell
# Vérifier si un chemin est dans le projet
Test-PathIsWithinProject -Path "C:\Projects\MonProjet\docs"

# Normaliser un chemin avec le style Windows
ConvertTo-NormalizedPath -Path "docs/images\logo.png" -ForceWindowsStyle

# Normaliser un chemin avec le style Unix
ConvertTo-NormalizedPath -Path "scripts\\utils//helper.ps1" -ForceUnixStyle

# Normaliser un chemin et ajouter un slash de fin
ConvertTo-NormalizedPath -Path "docs\images" -AddTrailingSlash

# Normaliser un chemin et supprimer un slash de fin
ConvertTo-NormalizedPath -Path "docs\images\" -RemoveTrailingSlash
```

### Journalisation

```powershell
# Activer la journalisation
Enable-PathManagerLogging -Enable $true -LogPath "C:\Logs\path-manager.log" -LogLevel "Debug"

# Désactiver la journalisation
Enable-PathManagerLogging -Enable $false
```

### Gestion du cache

```powershell
# Configurer le cache
Set-PathManagerCache -Enable $true -MaxCacheSize 2000

# Désactiver le cache
Set-PathManagerCache -Enable $false

# Vider le cache
Set-PathManagerCache -ClearCache

# Vider uniquement le cache des chemins relatifs
Set-PathManagerCache -ClearCache -CacheType "RelativePath"

# Résoudre un chemin sans utiliser le cache
Get-ProjectPath -PathOrMappingName "docs\index.html" -NoCache
```

## Gestion des erreurs

Le module utilise des types d'exceptions personnalisés pour une meilleure gestion des erreurs :

- `PathManagerException` : Exception de base pour toutes les erreurs du module
- `PathManagerNotInitializedException` : Le module n'a pas été initialisé
- `PathManagerInvalidPathException` : Le chemin n'est pas valide ou accessible
- `PathManagerMappingNotFoundException` : Le mapping n'existe pas

Exemple de gestion des erreurs :

```powershell
try {
    Get-ProjectPath -PathOrMappingName "nonexistent.txt" -VerifyExists
}
catch [PathManagerInvalidPathException] {
    Write-Host "Le chemin n'est pas valide : $($_.Exception.Path)"
}
catch [PathManagerException] {
    Write-Host "Erreur du module Path-Manager : $($_.Exception.Message)"
}
catch {
    Write-Host "Erreur inattendue : $($_.Exception.Message)"
}
```

## Tests

Le module est livré avec une suite de tests Pester. Pour exécuter les tests :

```powershell
cd tools\path-utils\tests
.\Run-Tests.ps1
```
