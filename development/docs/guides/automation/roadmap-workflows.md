# Workflows automatisés pour la gestion des roadmaps

Ce document présente les workflows automatisés pour la gestion des roadmaps, qui permettent d'exécuter régulièrement les tâches de synchronisation, de génération de rapports et de planification.

## Workflows disponibles

### Workflow quotidien

Le workflow quotidien exécute les tâches suivantes :

1. Synchronisation de la roadmap principale vers les formats JSON et HTML
2. Vérification de l'état d'avancement des tâches
3. Génération d'un rapport quotidien
4. Journalisation des résultats

**Fréquence d'exécution** : Tous les jours à 9h00

**Script** : `development\scripts\workflows\workflow-quotidien.ps1`

**Tâche planifiée** : `RoadmapManager-Quotidien`

### Workflow hebdomadaire

Le workflow hebdomadaire exécute les tâches suivantes :

1. Synchronisation de toutes les roadmaps vers les formats JSON et HTML
2. Génération de rapports hebdomadaires détaillés
3. Planification des tâches pour la semaine à venir
4. Exécution du workflow de gestion de roadmap
5. Journalisation des résultats

**Fréquence d'exécution** : Tous les vendredis à 16h00

**Script** : `development\scripts\workflows\workflow-hebdomadaire.ps1`

**Tâche planifiée** : `RoadmapManager-Hebdomadaire`

### Workflow mensuel

Le workflow mensuel exécute les tâches suivantes :

1. Synchronisation de toutes les roadmaps vers tous les formats (JSON, HTML, CSV)
2. Génération de rapports mensuels détaillés avec graphiques, tendances et prévisions
3. Planification des tâches pour le mois à venir
4. Analyse des tendances et prévisions
5. Création d'un rapport de synthèse
6. Journalisation des résultats

**Fréquence d'exécution** : Le premier jour de chaque mois à 10h00

**Script** : `development\scripts\workflows\workflow-mensuel.ps1`

**Tâche planifiée** : `RoadmapManager-Mensuel`

## Installation des tâches planifiées

Pour installer les tâches planifiées qui exécuteront automatiquement les workflows, utilisez le script `install-scheduled-tasks.ps1` :

```powershell
# Installer les tâches planifiées avec les paramètres par défaut
.\development\scripts\workflows\install-scheduled-tasks.ps1

# Installer les tâches planifiées avec un préfixe personnalisé
.\development\scripts\workflows\install-scheduled-tasks.ps1 -TaskPrefix "MonProjet"

# Remplacer les tâches existantes
.\development\scripts\workflows\install-scheduled-tasks.ps1 -Force
```

## Exécution manuelle des workflows

Vous pouvez également exécuter manuellement les workflows :

```powershell
# Exécuter le workflow quotidien
.\development\scripts\workflows\workflow-quotidien.ps1

# Exécuter le workflow hebdomadaire
.\development\scripts\workflows\workflow-hebdomadaire.ps1

# Exécuter le workflow mensuel
.\development\scripts\workflows\workflow-mensuel.ps1
```

## Personnalisation des workflows

### Modification des chemins de roadmap

Vous pouvez spécifier les chemins des roadmaps à traiter :

```powershell
# Workflow quotidien avec un chemin de roadmap personnalisé
.\development\scripts\workflows\workflow-quotidien.ps1 -RoadmapPath "projet\roadmaps\mes-plans\roadmap_perso.md"

# Workflow hebdomadaire avec plusieurs chemins de roadmap
$roadmapPaths = @(
    "projet\roadmaps\Roadmap\roadmap_complete_converted.md",
    "projet\roadmaps\mes-plans\roadmap_perso.md"
)
.\development\scripts\workflows\workflow-hebdomadaire.ps1 -RoadmapPaths $roadmapPaths

# Workflow mensuel avec plusieurs chemins de roadmap
.\development\scripts\workflows\workflow-mensuel.ps1 -RoadmapPaths $roadmapPaths
```

### Modification des répertoires de sortie

Vous pouvez spécifier les répertoires de sortie pour les rapports et les plans :

```powershell
# Workflow hebdomadaire avec un répertoire de sortie personnalisé
.\development\scripts\workflows\workflow-hebdomadaire.ps1 -OutputPath "projet\roadmaps\output"

# Workflow mensuel avec un répertoire de sortie personnalisé
.\development\scripts\workflows\workflow-mensuel.ps1 -OutputPath "projet\roadmaps\output"
```

### Modification du fichier de configuration

Vous pouvez spécifier un fichier de configuration personnalisé :

```powershell
# Workflow quotidien avec un fichier de configuration personnalisé
.\development\scripts\workflows\workflow-quotidien.ps1 -ConfigPath "development\config\my-config.json"

# Workflow hebdomadaire avec un fichier de configuration personnalisé
.\development\scripts\workflows\workflow-hebdomadaire.ps1 -ConfigPath "development\config\my-config.json"

# Workflow mensuel avec un fichier de configuration personnalisé
.\development\scripts\workflows\workflow-mensuel.ps1 -ConfigPath "development\config\my-config.json"
```

## Structure des répertoires

Les workflows génèrent des fichiers dans les répertoires suivants :

```
projet/
  roadmaps/
    Roadmap/
      roadmap_complete_converted.md  # Roadmap principale au format Markdown
      roadmap_complete.json          # Version JSON de la roadmap principale
      roadmap_complete.html          # Version HTML de la roadmap principale
      roadmap_complete.csv           # Version CSV de la roadmap principale
    Reports/
      quotidien-YYYY-MM-DD/          # Rapports quotidiens
      hebdomadaire-ROADMAP-YYYY-MM-DD/ # Rapports hebdomadaires
      mensuel-ROADMAP-YYYY-MM/       # Rapports mensuels
      synthese-YYYY-MM.md            # Rapport de synthèse mensuel
    Plans/
      hebdomadaire-ROADMAP-YYYY-MM-DD.md # Plans hebdomadaires
      mensuel-ROADMAP-YYYY-MM.md     # Plans mensuels
    Analysis/
      analyse-ROADMAP-YYYY-MM.md     # Analyses mensuelles
    Logs/
      workflow-quotidien-YYYY-MM-DD.log # Journaux quotidiens
      workflow-hebdomadaire-YYYY-MM-DD.log # Journaux hebdomadaires
      workflow-mensuel-YYYY-MM.log   # Journaux mensuels
```

## Journalisation

Tous les workflows génèrent des journaux détaillés qui incluent les informations suivantes :

- Date et heure d'exécution
- Étapes exécutées
- Résultats des opérations
- Erreurs rencontrées

Les journaux sont stockés dans le répertoire `projet\roadmaps\Logs` et sont nommés selon le format suivant :

- `workflow-quotidien-YYYY-MM-DD.log` pour le workflow quotidien
- `workflow-hebdomadaire-YYYY-MM-DD.log` pour le workflow hebdomadaire
- `workflow-mensuel-YYYY-MM.log` pour le workflow mensuel

## Intégration avec d'autres outils

### Git

Vous pouvez intégrer les workflows avec Git en ajoutant des commandes Git dans les scripts :

```powershell
# Ajouter à la fin du workflow quotidien
git add "projet\roadmaps\Roadmap\roadmap_complete_converted.md"
git add "projet\roadmaps\Roadmap\roadmap_complete.json"
git commit -m "Mise à jour quotidienne de la roadmap - $(Get-Date -Format 'yyyy-MM-dd')"
git push
```

### n8n

Vous pouvez créer un workflow n8n qui exécute les scripts PowerShell et traite les résultats :

```javascript
// Exemple de nœud Execute Command dans n8n
{
  "parameters": {
    "command": "powershell.exe",
    "arguments": "-NoProfile -ExecutionPolicy Bypass -File D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\development\\scripts\\workflows\\workflow-quotidien.ps1",
    "executeOnce": true
  }
}
```

### Notification par e-mail

Vous pouvez ajouter des notifications par e-mail dans les scripts :

```powershell
# Ajouter à la fin du workflow hebdomadaire
$emailParams = @{
    From = "roadmap@example.com"
    To = "equipe@example.com"
    Subject = "Rapport hebdomadaire de roadmap - $(Get-Date -Format 'yyyy-MM-dd')"
    Body = "Le rapport hebdomadaire de roadmap est disponible à l'adresse suivante : $reportPath"
    SmtpServer = "smtp.example.com"
}
Send-MailMessage @emailParams
```

## Résolution des problèmes

### Problème: Les tâches planifiées ne s'exécutent pas

**Symptôme**: Les tâches planifiées sont installées mais ne s'exécutent pas.

**Solution**:
1. Vérifiez que le service de planification des tâches est en cours d'exécution.
2. Vérifiez que l'utilisateur qui exécute les tâches a les droits nécessaires.
3. Vérifiez les journaux d'événements Windows pour les erreurs.

```powershell
# Vérifier l'état du service de planification des tâches
Get-Service -Name "Schedule"

# Vérifier les tâches planifiées
Get-ScheduledTask -TaskName "RoadmapManager-*"

# Vérifier l'historique d'exécution des tâches
Get-ScheduledTaskInfo -TaskName "RoadmapManager-Quotidien"
```

### Problème: Les workflows échouent avec des erreurs

**Symptôme**: Les workflows s'exécutent mais échouent avec des erreurs.

**Solution**:
1. Vérifiez les journaux pour identifier les erreurs.
2. Vérifiez que les chemins des fichiers sont corrects.
3. Vérifiez que les répertoires de sortie existent et sont accessibles en écriture.

```powershell
# Vérifier les journaux
Get-Content -Path "projet\roadmaps\Logs\workflow-quotidien-$(Get-Date -Format 'yyyy-MM-dd').log"

# Exécuter le workflow en mode verbose
.\development\scripts\workflows\workflow-quotidien.ps1 -Verbose
```

### Problème: Les rapports ne sont pas générés

**Symptôme**: Les workflows s'exécutent mais les rapports ne sont pas générés.

**Solution**:
1. Vérifiez que les roadmaps existent et sont correctement formatées.
2. Vérifiez que les répertoires de sortie existent et sont accessibles en écriture.
3. Exécutez manuellement le mode ROADMAP-REPORT pour vérifier qu'il fonctionne correctement.

```powershell
# Exécuter manuellement le mode ROADMAP-REPORT
.\development\scripts\integrated-manager.ps1 -Mode "ROADMAP-REPORT" -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "HTML"
```

## Conclusion

Les workflows automatisés pour la gestion des roadmaps permettent d'exécuter régulièrement les tâches de synchronisation, de génération de rapports et de planification. Ils facilitent le suivi de l'avancement des projets et la prise de décision.
