# Module de gestion d'erreurs

Ce rÃ©pertoire contient un module PowerShell pour la gestion d'erreurs dans les scripts, ainsi que des outils pour ajouter automatiquement des blocs try/catch et crÃ©er un systÃ¨me de journalisation centralisÃ©.

## Contenu

- **ErrorHandling.psm1** : Module principal de gestion d'erreurs
- **ErrorHandling.Tests.ps1** : Tests unitaires pour le module
- **Add-ErrorHandlingToScripts.ps1** : Script pour ajouter la gestion d'erreurs Ã  plusieurs scripts
- **Run-Tests.ps1** : Script pour exÃ©cuter les tests unitaires

## FonctionnalitÃ©s

### Module ErrorHandling

Le module ErrorHandling fournit les fonctionnalitÃ©s suivantes :

- **Ajout automatique de blocs try/catch** : Analyse les scripts PowerShell et ajoute des blocs try/catch aux fonctions et au code principal.
- **Journalisation des erreurs** : Enregistre les erreurs dans un fichier JSON avec des informations dÃ©taillÃ©es.
- **SystÃ¨me de journalisation centralisÃ©** : CrÃ©e une structure de rÃ©pertoires et des scripts pour gÃ©rer les journaux.
- **Base de donnÃ©es d'erreurs** : Stocke les erreurs connues et leurs solutions.
- **Analyse des erreurs** : Identifie les patterns d'erreurs et suggÃ¨re des solutions.

### Fonctions principales

- `Initialize-ErrorHandling` : Initialise le module avec un rÃ©pertoire de journaux personnalisÃ©.
- `Add-TryCatchBlock` : Ajoute des blocs try/catch Ã  un script PowerShell.
- `Write-Log-Error` : Journalise une erreur dans un fichier JSON.
- `New-CentralizedLoggingSystem` : CrÃ©e un systÃ¨me de journalisation centralisÃ©.
- `Add-ErrorSolution` : Ajoute une solution Ã  une erreur connue.

## Utilisation

### Installation du module

```powershell
# Importer le module

Import-Module .\ErrorHandling.psm1

# Initialiser le module avec un rÃ©pertoire de journaux personnalisÃ©

Initialize-ErrorHandling -LogPath "C:\Logs"
```plaintext
### Ajout de blocs try/catch Ã  un script

```powershell
# Ajouter des blocs try/catch Ã  un script

Add-TryCatchBlock -ScriptPath "C:\Scripts\MonScript.ps1" -BackupFile

# Ajouter des blocs try/catch Ã  plusieurs scripts

.\Add-ErrorHandlingToScripts.ps1 -ScriptPath "C:\Scripts" -Recurse -BackupFiles
```plaintext
### Journalisation des erreurs

```powershell
# Journaliser une erreur

try {
    # Code qui peut gÃ©nÃ©rer une erreur

    Get-Content -Path "C:\fichier_inexistant.txt" -ErrorAction Stop
}
catch {
    # Journaliser l'erreur

    Write-Log-Error -ErrorRecord $_ -FunctionName "MaFonction" -Category "FileSystem"
}
```plaintext
### CrÃ©ation d'un systÃ¨me de journalisation centralisÃ©

```powershell
# CrÃ©er un systÃ¨me de journalisation centralisÃ©

New-CentralizedLoggingSystem -LogPath "C:\Logs" -IncludeAnalytics
```plaintext
## Tests unitaires

Le module inclut des tests unitaires pour vÃ©rifier son bon fonctionnement. Pour exÃ©cuter les tests :

```powershell
# ExÃ©cuter les tests unitaires

.\Run-Tests.ps1

# ExÃ©cuter les tests unitaires et gÃ©nÃ©rer un rapport HTML

.\Run-Tests.ps1 -GenerateReport
```plaintext
## Exemples

### Exemple 1 : Ajouter la gestion d'erreurs Ã  tous les scripts d'un rÃ©pertoire

```powershell
.\Add-ErrorHandlingToScripts.ps1 -ScriptPath "D:\Projets\Scripts" -Recurse -BackupFiles
```plaintext
### Exemple 2 : CrÃ©er un systÃ¨me de journalisation centralisÃ©

```powershell
Import-Module .\ErrorHandling.psm1
New-CentralizedLoggingSystem -LogPath "D:\Logs" -IncludeAnalytics
```plaintext
### Exemple 3 : Ajouter une solution Ã  une erreur connue

```powershell
Import-Module .\ErrorHandling.psm1
Initialize-ErrorHandling -LogPath "D:\Logs"

# Obtenir le hash d'une erreur

$errorHash = "..."

# Ajouter une solution

Add-ErrorSolution -ErrorHash $errorHash -Solution "VÃ©rifier que le fichier existe avant d'appeler Get-Content"
```plaintext
## Bonnes pratiques

- Toujours initialiser le module avec un rÃ©pertoire de journaux appropriÃ©.
- CrÃ©er des sauvegardes des fichiers avant de les modifier avec l'option `-BackupFile`.
- Utiliser des catÃ©gories d'erreurs cohÃ©rentes pour faciliter l'analyse.
- ExÃ©cuter rÃ©guliÃ¨rement les tests unitaires pour vÃ©rifier le bon fonctionnement du module.
- Analyser rÃ©guliÃ¨rement les journaux d'erreurs pour identifier des patterns et amÃ©liorer le code.

## DÃ©pannage

Si vous rencontrez des problÃ¨mes avec le module, vÃ©rifiez les points suivants :

- Assurez-vous que PowerShell 5.1 ou supÃ©rieur est installÃ©.
- VÃ©rifiez que vous avez les droits d'accÃ¨s en lecture et en Ã©criture sur les rÃ©pertoires de journaux.
- ExÃ©cutez les tests unitaires pour vÃ©rifier le bon fonctionnement du module.
- Consultez les journaux d'erreurs pour identifier les problÃ¨mes.
