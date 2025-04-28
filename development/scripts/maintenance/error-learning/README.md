# SystÃ¨me d'apprentissage des erreurs PowerShell

Ce systÃ¨me permet de collecter, analyser et apprendre des erreurs PowerShell pour amÃ©liorer la qualitÃ© du code et prÃ©venir les erreurs futures.

## FonctionnalitÃ©s

- **Collecte d'erreurs** : Capture automatique des erreurs PowerShell Ã  partir des journaux d'Ã©vÃ©nements et des fichiers de log.
- **Analyse d'erreurs** : Analyse des erreurs pour identifier les patterns rÃ©currents et les causes racines.
- **Base de connaissances** : Stockage structurÃ© des erreurs et de leurs solutions.
- **Analyse prÃ©dictive** : DÃ©tection des erreurs potentielles dans les scripts PowerShell avant leur exÃ©cution.
- **Tableau de bord** : Visualisation des statistiques d'erreurs et des tendances.
- **Correction automatique** : Application intelligente de corrections basÃ©es sur l'historique des erreurs.
- **Apprentissage adaptatif** : AmÃ©lioration continue des suggestions de correction grÃ¢ce Ã  l'apprentissage.
- **Validation des corrections** : VÃ©rification de la validitÃ© des corrections appliquÃ©es.

## Structure du systÃ¨me

- `ErrorLearningSystem.psm1` : Module principal du systÃ¨me d'apprentissage des erreurs.
- `Collect-ErrorData.ps1` : Script pour collecter et analyser les erreurs PowerShell.
- `Analyze-ScriptForErrors.ps1` : Script pour analyser un script PowerShell et dÃ©tecter les erreurs potentielles.
- `Generate-ErrorDashboard.ps1` : Script pour gÃ©nÃ©rer un tableau de bord de qualitÃ© du code.
- `Manage-KnowledgeBase.ps1` : Script pour gÃ©rer la base de connaissances des erreurs PowerShell.
- `Auto-CorrectErrors.ps1` : Script pour automatiser intelligemment les corrections d'erreurs.
- `Adaptive-ErrorCorrection.ps1` : Script d'apprentissage adaptatif pour les corrections d'erreurs.
- `Validate-ErrorCorrections.ps1` : Script de validation des corrections appliquÃ©es.
- `data/` : Dossier contenant la base de donnÃ©es des erreurs.
- `logs/` : Dossier contenant les journaux d'erreurs.
- `patterns/` : Dossier contenant les patterns d'erreurs.
- `dashboard/` : Dossier contenant le tableau de bord de qualitÃ© du code.

## Utilisation

### Initialisation du systÃ¨me

```powershell
# Importer le module
Import-Module .\ErrorLearningSystem.psm1

# Initialiser le systÃ¨me
Initialize-ErrorLearningSystem
```

### Collecte d'erreurs

```powershell
# Collecter les erreurs Ã  partir des fichiers de log
.\Collect-ErrorData.ps1 -LogPath "C:\Logs" -MaxErrors 100

# Collecter les erreurs Ã  partir des journaux d'Ã©vÃ©nements
.\Collect-ErrorData.ps1 -IncludeEventLogs -MaxErrors 100

# Analyser les erreurs sans collecter de nouvelles erreurs
.\Collect-ErrorData.ps1 -AnalyzeOnly
```

### Analyse prÃ©dictive

```powershell
# Analyser un script PowerShell pour dÃ©tecter les erreurs potentielles
.\Analyze-ScriptForErrors.ps1 -ScriptPath "C:\Scripts\MyScript.ps1"

# GÃ©nÃ©rer un rapport d'analyse
.\Analyze-ScriptForErrors.ps1 -ScriptPath "C:\Scripts\MyScript.ps1" -GenerateReport

# Corriger automatiquement les erreurs dÃ©tectÃ©es
.\Analyze-ScriptForErrors.ps1 -ScriptPath "C:\Scripts\MyScript.ps1" -FixErrors
```

### Tableau de bord

```powershell
# GÃ©nÃ©rer un tableau de bord de qualitÃ© du code
.\Generate-ErrorDashboard.ps1 -OutputPath "C:\Dashboard\error-dashboard.html"

# GÃ©nÃ©rer et ouvrir le tableau de bord dans le navigateur
.\Generate-ErrorDashboard.ps1 -OpenInBrowser
```

### Gestion de la base de connaissances

```powershell
# Ajouter une erreur Ã  la base de connaissances
.\Manage-KnowledgeBase.ps1 -Action Add -ErrorMessage "Erreur de connexion" -Category "Network" -Solution "VÃ©rifier les paramÃ¨tres de connexion"

# Mettre Ã  jour une erreur dans la base de connaissances
.\Manage-KnowledgeBase.ps1 -Action Update -ErrorId "12345" -Solution "Nouvelle solution"

# Rechercher des erreurs dans la base de connaissances
.\Manage-KnowledgeBase.ps1 -Action Search -ErrorMessage "connexion" -Category "Network"

# Exporter la base de connaissances
.\Manage-KnowledgeBase.ps1 -Action Export -FilePath "C:\Backup\knowledge-base.json"

# Importer la base de connaissances
.\Manage-KnowledgeBase.ps1 -Action Import -FilePath "C:\Backup\knowledge-base.json"
```

## IntÃ©gration avec les scripts existants

Pour intÃ©grer le systÃ¨me d'apprentissage des erreurs dans vos scripts existants, vous pouvez utiliser le module `ErrorLearningSystem.psm1` comme suit :

```powershell
# Importer le module
Import-Module "chemin\vers\ErrorLearningSystem.psm1"

# Initialiser le systÃ¨me
Initialize-ErrorLearningSystem

# Utiliser le systÃ¨me dans un bloc try/catch
try {
    # Votre code ici
}
catch {
    # Enregistrer l'erreur
    Register-PowerShellError -ErrorRecord $_ -Source "MonScript" -Category "MonCategorie"

    # Obtenir des suggestions pour l'erreur
    $suggestions = Get-ErrorSuggestions -ErrorRecord $_

    if ($suggestions.Found) {
        Write-Host "Suggestions pour rÃ©soudre l'erreur :"
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

Les journaux d'erreurs sont stockÃ©s dans le dossier `logs/`. Vous pouvez les nettoyer pÃ©riodiquement pour Ã©conomiser de l'espace disque.

### Sauvegarde de la base de connaissances

Il est recommandÃ© de sauvegarder rÃ©guliÃ¨rement la base de connaissances Ã  l'aide de la commande suivante :

```powershell
.\Manage-KnowledgeBase.ps1 -Action Export -FilePath "C:\Backup\knowledge-base.json"
```

### Correction automatique des erreurs

```powershell
# Analyser et corriger automatiquement un script
.\Auto-CorrectErrors.ps1 -ScriptPath "C:\Scripts\MonScript.ps1" -ApplyCorrections

# GÃ©nÃ©rer un rapport des corrections suggÃ©rÃ©es
.\Auto-CorrectErrors.ps1 -ScriptPath "C:\Scripts\MonScript.ps1" -GenerateReport

# Activer le mode d'apprentissage pour enregistrer les corrections manuelles
.\Auto-CorrectErrors.ps1 -ScriptPath "C:\Scripts\MonScript.ps1" -LearningMode
```

### Apprentissage adaptatif

```powershell
# Activer le mode d'entraÃ®nement pour amÃ©liorer le modÃ¨le
.\Adaptive-ErrorCorrection.ps1 -TrainingMode

# GÃ©nÃ©rer un modÃ¨le de correction
.\Adaptive-ErrorCorrection.ps1 -GenerateModel -ModelPath "C:\Models\correction-model.json"

# Tester le modÃ¨le sur un script
.\Adaptive-ErrorCorrection.ps1 -TestScript "C:\Scripts\MonScript.ps1"
```

### Validation des corrections

```powershell
# Valider les corrections appliquÃ©es Ã  un script
.\Validate-ErrorCorrections.ps1 -ScriptPath "C:\Scripts\MonScript.ps1" -TestPath "C:\Scripts\Tests\MonScript.Tests.ps1"

# GÃ©nÃ©rer un script de test unitaire
.\Validate-ErrorCorrections.ps1 -ScriptPath "C:\Scripts\MonScript.ps1" -GenerateTestScript

# Valider les corrections en mode interactif
.\Validate-ErrorCorrections.ps1 -ScriptPath "C:\Scripts\MonScript.ps1" -Interactive
```

## DÃ©pannage

### ProblÃ¨mes courants

- **Le systÃ¨me ne collecte pas d'erreurs** : VÃ©rifiez les permissions d'accÃ¨s aux journaux d'Ã©vÃ©nements et aux fichiers de log.
- **Le tableau de bord ne s'affiche pas correctement** : VÃ©rifiez que vous avez accÃ¨s Ã  Internet pour charger les bibliothÃ¨ques JavaScript nÃ©cessaires.
- **Les suggestions ne sont pas pertinentes** : Ajoutez manuellement des erreurs Ã  la base de connaissances pour amÃ©liorer les suggestions.
- **Les corrections automatiques ne fonctionnent pas** : VÃ©rifiez que le modÃ¨le de correction a Ã©tÃ© gÃ©nÃ©rÃ© correctement.
- **Les tests de validation Ã©chouent** : VÃ©rifiez que les scripts de test sont Ã  jour et correspondent au script corrigÃ©.

### Journalisation

Le systÃ¨me gÃ©nÃ¨re des journaux dÃ©taillÃ©s dans le dossier `logs/`. Consultez ces journaux pour diagnostiquer les problÃ¨mes.
