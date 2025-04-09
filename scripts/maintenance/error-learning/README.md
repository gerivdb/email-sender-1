# Système d'apprentissage des erreurs PowerShell

Ce système permet de collecter, analyser et apprendre des erreurs PowerShell pour améliorer la qualité du code et prévenir les erreurs futures.

## Fonctionnalités

- **Collecte d'erreurs** : Capture automatique des erreurs PowerShell à partir des journaux d'événements et des fichiers de log.
- **Analyse d'erreurs** : Analyse des erreurs pour identifier les patterns récurrents et les causes racines.
- **Base de connaissances** : Stockage structuré des erreurs et de leurs solutions.
- **Analyse prédictive** : Détection des erreurs potentielles dans les scripts PowerShell avant leur exécution.
- **Tableau de bord** : Visualisation des statistiques d'erreurs et des tendances.

## Structure du système

- `ErrorLearningSystem.psm1` : Module principal du système d'apprentissage des erreurs.
- `Collect-ErrorData.ps1` : Script pour collecter et analyser les erreurs PowerShell.
- `Analyze-ScriptForErrors.ps1` : Script pour analyser un script PowerShell et détecter les erreurs potentielles.
- `Generate-ErrorDashboard.ps1` : Script pour générer un tableau de bord de qualité du code.
- `Manage-KnowledgeBase.ps1` : Script pour gérer la base de connaissances des erreurs PowerShell.
- `data/` : Dossier contenant la base de données des erreurs.
- `logs/` : Dossier contenant les journaux d'erreurs.
- `patterns/` : Dossier contenant les patterns d'erreurs.
- `dashboard/` : Dossier contenant le tableau de bord de qualité du code.

## Utilisation

### Initialisation du système

```powershell
# Importer le module
Import-Module .\ErrorLearningSystem.psm1

# Initialiser le système
Initialize-ErrorLearningSystem
```

### Collecte d'erreurs

```powershell
# Collecter les erreurs à partir des fichiers de log
.\Collect-ErrorData.ps1 -LogPath "C:\Logs" -MaxErrors 100

# Collecter les erreurs à partir des journaux d'événements
.\Collect-ErrorData.ps1 -IncludeEventLogs -MaxErrors 100

# Analyser les erreurs sans collecter de nouvelles erreurs
.\Collect-ErrorData.ps1 -AnalyzeOnly
```

### Analyse prédictive

```powershell
# Analyser un script PowerShell pour détecter les erreurs potentielles
.\Analyze-ScriptForErrors.ps1 -ScriptPath "C:\Scripts\MyScript.ps1"

# Générer un rapport d'analyse
.\Analyze-ScriptForErrors.ps1 -ScriptPath "C:\Scripts\MyScript.ps1" -GenerateReport

# Corriger automatiquement les erreurs détectées
.\Analyze-ScriptForErrors.ps1 -ScriptPath "C:\Scripts\MyScript.ps1" -FixErrors
```

### Tableau de bord

```powershell
# Générer un tableau de bord de qualité du code
.\Generate-ErrorDashboard.ps1 -OutputPath "C:\Dashboard\error-dashboard.html"

# Générer et ouvrir le tableau de bord dans le navigateur
.\Generate-ErrorDashboard.ps1 -OpenInBrowser
```

### Gestion de la base de connaissances

```powershell
# Ajouter une erreur à la base de connaissances
.\Manage-KnowledgeBase.ps1 -Action Add -ErrorMessage "Erreur de connexion" -Category "Network" -Solution "Vérifier les paramètres de connexion"

# Mettre à jour une erreur dans la base de connaissances
.\Manage-KnowledgeBase.ps1 -Action Update -ErrorId "12345" -Solution "Nouvelle solution"

# Rechercher des erreurs dans la base de connaissances
.\Manage-KnowledgeBase.ps1 -Action Search -ErrorMessage "connexion" -Category "Network"

# Exporter la base de connaissances
.\Manage-KnowledgeBase.ps1 -Action Export -FilePath "C:\Backup\knowledge-base.json"

# Importer la base de connaissances
.\Manage-KnowledgeBase.ps1 -Action Import -FilePath "C:\Backup\knowledge-base.json"
```

## Intégration avec les scripts existants

Pour intégrer le système d'apprentissage des erreurs dans vos scripts existants, vous pouvez utiliser le module `ErrorLearningSystem.psm1` comme suit :

```powershell
# Importer le module
Import-Module "chemin\vers\ErrorLearningSystem.psm1"

# Initialiser le système
Initialize-ErrorLearningSystem

# Utiliser le système dans un bloc try/catch
try {
    # Votre code ici
}
catch {
    # Enregistrer l'erreur
    Register-PowerShellError -ErrorRecord $_ -Source "MonScript" -Category "MonCategorie"
    
    # Obtenir des suggestions pour l'erreur
    $suggestions = Get-ErrorSuggestions -ErrorRecord $_
    
    if ($suggestions.Found) {
        Write-Host "Suggestions pour résoudre l'erreur :"
        foreach ($suggestion in $suggestions.Suggestions) {
            Write-Host "- $($suggestion.Solution)"
        }
    }
    
    # Relancer l'erreur
    throw
}
```

## Maintenance

### Nettoyage des journaux

Les journaux d'erreurs sont stockés dans le dossier `logs/`. Vous pouvez les nettoyer périodiquement pour économiser de l'espace disque.

### Sauvegarde de la base de connaissances

Il est recommandé de sauvegarder régulièrement la base de connaissances à l'aide de la commande suivante :

```powershell
.\Manage-KnowledgeBase.ps1 -Action Export -FilePath "C:\Backup\knowledge-base.json"
```

## Dépannage

### Problèmes courants

- **Le système ne collecte pas d'erreurs** : Vérifiez les permissions d'accès aux journaux d'événements et aux fichiers de log.
- **Le tableau de bord ne s'affiche pas correctement** : Vérifiez que vous avez accès à Internet pour charger les bibliothèques JavaScript nécessaires.
- **Les suggestions ne sont pas pertinentes** : Ajoutez manuellement des erreurs à la base de connaissances pour améliorer les suggestions.

### Journalisation

Le système génère des journaux détaillés dans le dossier `logs/`. Consultez ces journaux pour diagnostiquer les problèmes.
