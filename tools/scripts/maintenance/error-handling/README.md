# Module de gestion d'erreurs

Ce répertoire contient un module PowerShell pour la gestion d'erreurs dans les scripts, ainsi que des outils pour ajouter automatiquement des blocs try/catch et créer un système de journalisation centralisé.

## Contenu

- **ErrorHandling.psm1** : Module principal de gestion d'erreurs
- **ErrorHandling.Tests.ps1** : Tests unitaires pour le module
- **Add-ErrorHandlingToScripts.ps1** : Script pour ajouter la gestion d'erreurs à plusieurs scripts
- **Run-Tests.ps1** : Script pour exécuter les tests unitaires

## Fonctionnalités

### Module ErrorHandling

Le module ErrorHandling fournit les fonctionnalités suivantes :

- **Ajout automatique de blocs try/catch** : Analyse les scripts PowerShell et ajoute des blocs try/catch aux fonctions et au code principal.
- **Journalisation des erreurs** : Enregistre les erreurs dans un fichier JSON avec des informations détaillées.
- **Système de journalisation centralisé** : Crée une structure de répertoires et des scripts pour gérer les journaux.
- **Base de données d'erreurs** : Stocke les erreurs connues et leurs solutions.
- **Analyse des erreurs** : Identifie les patterns d'erreurs et suggère des solutions.

### Fonctions principales

- `Initialize-ErrorHandling` : Initialise le module avec un répertoire de journaux personnalisé.
- `Add-TryCatchBlock` : Ajoute des blocs try/catch à un script PowerShell.
- `Write-Log-Error` : Journalise une erreur dans un fichier JSON.
- `New-CentralizedLoggingSystem` : Crée un système de journalisation centralisé.
- `Add-ErrorSolution` : Ajoute une solution à une erreur connue.

## Utilisation

### Installation du module

```powershell
# Importer le module
Import-Module .\ErrorHandling.psm1

# Initialiser le module avec un répertoire de journaux personnalisé
Initialize-ErrorHandling -LogPath "C:\Logs"
```

### Ajout de blocs try/catch à un script

```powershell
# Ajouter des blocs try/catch à un script
Add-TryCatchBlock -ScriptPath "C:\Scripts\MonScript.ps1" -BackupFile

# Ajouter des blocs try/catch à plusieurs scripts
.\Add-ErrorHandlingToScripts.ps1 -ScriptPath "C:\Scripts" -Recurse -BackupFiles
```

### Journalisation des erreurs

```powershell
# Journaliser une erreur
try {
    # Code qui peut générer une erreur
    Get-Content -Path "C:\fichier_inexistant.txt" -ErrorAction Stop
}
catch {
    # Journaliser l'erreur
    Write-Log-Error -ErrorRecord $_ -FunctionName "MaFonction" -Category "FileSystem"
}
```

### Création d'un système de journalisation centralisé

```powershell
# Créer un système de journalisation centralisé
New-CentralizedLoggingSystem -LogPath "C:\Logs" -IncludeAnalytics
```

## Tests unitaires

Le module inclut des tests unitaires pour vérifier son bon fonctionnement. Pour exécuter les tests :

```powershell
# Exécuter les tests unitaires
.\Run-Tests.ps1

# Exécuter les tests unitaires et générer un rapport HTML
.\Run-Tests.ps1 -GenerateReport
```

## Exemples

### Exemple 1 : Ajouter la gestion d'erreurs à tous les scripts d'un répertoire

```powershell
.\Add-ErrorHandlingToScripts.ps1 -ScriptPath "D:\Projets\Scripts" -Recurse -BackupFiles
```

### Exemple 2 : Créer un système de journalisation centralisé

```powershell
Import-Module .\ErrorHandling.psm1
New-CentralizedLoggingSystem -LogPath "D:\Logs" -IncludeAnalytics
```

### Exemple 3 : Ajouter une solution à une erreur connue

```powershell
Import-Module .\ErrorHandling.psm1
Initialize-ErrorHandling -LogPath "D:\Logs"

# Obtenir le hash d'une erreur
$errorHash = "..."

# Ajouter une solution
Add-ErrorSolution -ErrorHash $errorHash -Solution "Vérifier que le fichier existe avant d'appeler Get-Content"
```

## Bonnes pratiques

- Toujours initialiser le module avec un répertoire de journaux approprié.
- Créer des sauvegardes des fichiers avant de les modifier avec l'option `-BackupFile`.
- Utiliser des catégories d'erreurs cohérentes pour faciliter l'analyse.
- Exécuter régulièrement les tests unitaires pour vérifier le bon fonctionnement du module.
- Analyser régulièrement les journaux d'erreurs pour identifier des patterns et améliorer le code.

## Dépannage

Si vous rencontrez des problèmes avec le module, vérifiez les points suivants :

- Assurez-vous que PowerShell 5.1 ou supérieur est installé.
- Vérifiez que vous avez les droits d'accès en lecture et en écriture sur les répertoires de journaux.
- Exécutez les tests unitaires pour vérifier le bon fonctionnement du module.
- Consultez les journaux d'erreurs pour identifier les problèmes.
