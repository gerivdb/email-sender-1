# Workflows automatisÃ©s pour la gestion des roadmaps

Ce document prÃ©sente les workflows automatisÃ©s pour la gestion des roadmaps, qui permettent d'exÃ©cuter rÃ©guliÃ¨rement les tÃ¢ches de synchronisation, de gÃ©nÃ©ration de rapports et de planification.

## Workflows disponibles

### Workflow quotidien

Le workflow quotidien exÃ©cute les tÃ¢ches suivantes :

1. Synchronisation de la roadmap principale vers les formats JSON et HTML
2. VÃ©rification de l'Ã©tat d'avancement des tÃ¢ches
3. GÃ©nÃ©ration d'un rapport quotidien
4. Journalisation des rÃ©sultats

**FrÃ©quence d'exÃ©cution** : Tous les jours Ã  9h00

**Script** : `development\scripts\workflows\workflow-quotidien.ps1`

**TÃ¢che planifiÃ©e** : `roadmap-manager-Quotidien`

### Workflow hebdomadaire

Le workflow hebdomadaire exÃ©cute les tÃ¢ches suivantes :

1. Synchronisation de toutes les roadmaps vers les formats JSON et HTML
2. GÃ©nÃ©ration de rapports hebdomadaires dÃ©taillÃ©s
3. Planification des tÃ¢ches pour la semaine Ã  venir
4. ExÃ©cution du workflow de gestion de roadmap
5. Journalisation des rÃ©sultats

**FrÃ©quence d'exÃ©cution** : Tous les vendredis Ã  16h00

**Script** : `development\scripts\workflows\workflow-hebdomadaire.ps1`

**TÃ¢che planifiÃ©e** : `roadmap-manager-Hebdomadaire`

### Workflow mensuel

Le workflow mensuel exÃ©cute les tÃ¢ches suivantes :

1. Synchronisation de toutes les roadmaps vers tous les formats (JSON, HTML, CSV)
2. GÃ©nÃ©ration de rapports mensuels dÃ©taillÃ©s avec graphiques, tendances et prÃ©visions
3. Planification des tÃ¢ches pour le mois Ã  venir
4. Analyse des tendances et prÃ©visions
5. CrÃ©ation d'un rapport de synthÃ¨se
6. Journalisation des rÃ©sultats

**FrÃ©quence d'exÃ©cution** : Le premier jour de chaque mois Ã  10h00

**Script** : `development\scripts\workflows\workflow-mensuel.ps1`

**TÃ¢che planifiÃ©e** : `roadmap-manager-Mensuel`

## Installation des tÃ¢ches planifiÃ©es

Pour installer les tÃ¢ches planifiÃ©es qui exÃ©cuteront automatiquement les workflows, utilisez le script `install-scheduled-tasks.ps1` :

```powershell
# Installer les tÃ¢ches planifiÃ©es avec les paramÃ¨tres par dÃ©faut

.\development\scripts\workflows\install-scheduled-tasks.ps1

# Installer les tÃ¢ches planifiÃ©es avec un prÃ©fixe personnalisÃ©

.\development\scripts\workflows\install-scheduled-tasks.ps1 -TaskPrefix "MonProjet"

# Remplacer les tÃ¢ches existantes

.\development\scripts\workflows\install-scheduled-tasks.ps1 -Force
```plaintext
## ExÃ©cution manuelle des workflows

Vous pouvez Ã©galement exÃ©cuter manuellement les workflows :

```powershell
# ExÃ©cuter le workflow quotidien

.\development\scripts\workflows\workflow-quotidien.ps1

# ExÃ©cuter le workflow hebdomadaire

.\development\scripts\workflows\workflow-hebdomadaire.ps1

# ExÃ©cuter le workflow mensuel

.\development\scripts\workflows\workflow-mensuel.ps1
```plaintext
## Personnalisation des workflows

### Modification des chemins de roadmap

Vous pouvez spÃ©cifier les chemins des roadmaps Ã  traiter :

```powershell
# Workflow quotidien avec un chemin de roadmap personnalisÃ©

.\development\scripts\workflows\workflow-quotidien.ps1 -RoadmapPath "projet\roadmaps\mes-plans\roadmap_perso.md"

# Workflow hebdomadaire avec plusieurs chemins de roadmap

$roadmapPaths = @(
    "projet\roadmaps\Roadmap\roadmap_complete_converted.md",
    "projet\roadmaps\mes-plans\roadmap_perso.md"
)
.\development\scripts\workflows\workflow-hebdomadaire.ps1 -RoadmapPaths $roadmapPaths

# Workflow mensuel avec plusieurs chemins de roadmap

.\development\scripts\workflows\workflow-mensuel.ps1 -RoadmapPaths $roadmapPaths
```plaintext
### Modification des rÃ©pertoires de sortie

Vous pouvez spÃ©cifier les rÃ©pertoires de sortie pour les rapports et les plans :

```powershell
# Workflow hebdomadaire avec un rÃ©pertoire de sortie personnalisÃ©

.\development\scripts\workflows\workflow-hebdomadaire.ps1 -OutputPath "projet\roadmaps\output"

# Workflow mensuel avec un rÃ©pertoire de sortie personnalisÃ©

.\development\scripts\workflows\workflow-mensuel.ps1 -OutputPath "projet\roadmaps\output"
```plaintext
### Modification du fichier de configuration

Vous pouvez spÃ©cifier un fichier de configuration personnalisÃ© :

```powershell
# Workflow quotidien avec un fichier de configuration personnalisÃ©

.\development\scripts\workflows\workflow-quotidien.ps1 -ConfigPath "development\config\my-config.json"

# Workflow hebdomadaire avec un fichier de configuration personnalisÃ©

.\development\scripts\workflows\workflow-hebdomadaire.ps1 -ConfigPath "development\config\my-config.json"

# Workflow mensuel avec un fichier de configuration personnalisÃ©

.\development\scripts\workflows\workflow-mensuel.ps1 -ConfigPath "development\config\my-config.json"
```plaintext
## Structure des rÃ©pertoires

Les workflows gÃ©nÃ¨rent des fichiers dans les rÃ©pertoires suivants :

```plaintext
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

      synthese-YYYY-MM.md            # Rapport de synthÃ¨se mensuel

    Plans/
      hebdomadaire-ROADMAP-YYYY-MM-DD.md # Plans hebdomadaires

      mensuel-ROADMAP-YYYY-MM.md     # Plans mensuels

    Analysis/
      analyse-ROADMAP-YYYY-MM.md     # Analyses mensuelles

    Logs/
      workflow-quotidien-YYYY-MM-DD.log # Journaux quotidiens

      workflow-hebdomadaire-YYYY-MM-DD.log # Journaux hebdomadaires

      workflow-mensuel-YYYY-MM.log   # Journaux mensuels

```plaintext
## Journalisation

Tous les workflows gÃ©nÃ¨rent des journaux dÃ©taillÃ©s qui incluent les informations suivantes :

- Date et heure d'exÃ©cution
- Ã‰tapes exÃ©cutÃ©es
- RÃ©sultats des opÃ©rations
- Erreurs rencontrÃ©es

Les journaux sont stockÃ©s dans le rÃ©pertoire `projet\roadmaps\Logs` et sont nommÃ©s selon le format suivant :

- `workflow-quotidien-YYYY-MM-DD.log` pour le workflow quotidien
- `workflow-hebdomadaire-YYYY-MM-DD.log` pour le workflow hebdomadaire
- `workflow-mensuel-YYYY-MM.log` pour le workflow mensuel

## IntÃ©gration avec d'autres outils

### Git

Vous pouvez intÃ©grer les workflows avec Git en ajoutant des commandes Git dans les scripts :

```powershell
# Ajouter Ã  la fin du workflow quotidien

git add "projet\roadmaps\Roadmap\roadmap_complete_converted.md"
git add "projet\roadmaps\Roadmap\roadmap_complete.json"
git commit -m "Mise Ã  jour quotidienne de la roadmap - $(Get-Date -Format 'yyyy-MM-dd')"
git push
```plaintext
### n8n

Vous pouvez crÃ©er un workflow n8n qui exÃ©cute les scripts PowerShell et traite les rÃ©sultats :

```javascript
// Exemple de nÅ“ud Execute Command dans n8n
{
  "parameters": {
    "command": "powershell.exe",
    "arguments": "-NoProfile -ExecutionPolicy Bypass -File D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\development\\scripts\\workflows\\workflow-quotidien.ps1",
    "executeOnce": true
  }
}
```plaintext
### Notification par e-mail

Vous pouvez ajouter des notifications par e-mail dans les scripts :

```powershell
# Ajouter Ã  la fin du workflow hebdomadaire

$emailParams = @{
    From = "roadmap@example.com"
    To = "equipe@example.com"
    Subject = "Rapport hebdomadaire de roadmap - $(Get-Date -Format 'yyyy-MM-dd')"
    Body = "Le rapport hebdomadaire de roadmap est disponible Ã  l'adresse suivante : $reportPath"
    SmtpServer = "smtp.example.com"
}
Send-MailMessage @emailParams
```plaintext
## RÃ©solution des problÃ¨mes

### ProblÃ¨me: Les tÃ¢ches planifiÃ©es ne s'exÃ©cutent pas

**SymptÃ´me**: Les tÃ¢ches planifiÃ©es sont installÃ©es mais ne s'exÃ©cutent pas.

**Solution**:
1. VÃ©rifiez que le service de planification des tÃ¢ches est en cours d'exÃ©cution.
2. VÃ©rifiez que l'utilisateur qui exÃ©cute les tÃ¢ches a les droits nÃ©cessaires.
3. VÃ©rifiez les journaux d'Ã©vÃ©nements Windows pour les erreurs.

```powershell
# VÃ©rifier l'Ã©tat du service de planification des tÃ¢ches

Get-Service -Name "Schedule"

# VÃ©rifier les tÃ¢ches planifiÃ©es

Get-ScheduledTask -TaskName "roadmap-manager-*"

# VÃ©rifier l'historique d'exÃ©cution des tÃ¢ches

Get-ScheduledTaskInfo -TaskName "roadmap-manager-Quotidien"
```plaintext
### ProblÃ¨me: Les workflows Ã©chouent avec des erreurs

**SymptÃ´me**: Les workflows s'exÃ©cutent mais Ã©chouent avec des erreurs.

**Solution**:
1. VÃ©rifiez les journaux pour identifier les erreurs.
2. VÃ©rifiez que les chemins des fichiers sont corrects.
3. VÃ©rifiez que les rÃ©pertoires de sortie existent et sont accessibles en Ã©criture.

```powershell
# VÃ©rifier les journaux

Get-Content -Path "projet\roadmaps\Logs\workflow-quotidien-$(Get-Date -Format 'yyyy-MM-dd').log"

# ExÃ©cuter le workflow en mode verbose

.\development\scripts\workflows\workflow-quotidien.ps1 -Verbose
```plaintext
### ProblÃ¨me: Les rapports ne sont pas gÃ©nÃ©rÃ©s

**SymptÃ´me**: Les workflows s'exÃ©cutent mais les rapports ne sont pas gÃ©nÃ©rÃ©s.

**Solution**:
1. VÃ©rifiez que les roadmaps existent et sont correctement formatÃ©es.
2. VÃ©rifiez que les rÃ©pertoires de sortie existent et sont accessibles en Ã©criture.
3. ExÃ©cutez manuellement le mode ROADMAP-REPORT pour vÃ©rifier qu'il fonctionne correctement.

```powershell
# ExÃ©cuter manuellement le mode ROADMAP-REPORT

.\development\scripts\integrated-manager.ps1 -Mode "ROADMAP-REPORT" -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "HTML"
```plaintext
## Conclusion

Les workflows automatisÃ©s pour la gestion des roadmaps permettent d'exÃ©cuter rÃ©guliÃ¨rement les tÃ¢ches de synchronisation, de gÃ©nÃ©ration de rapports et de planification. Ils facilitent le suivi de l'avancement des projets et la prise de dÃ©cision.

