# Guide de démarrage rapide du gestionnaire intégré

Ce guide de démarrage rapide vous permettra de commencer à utiliser le gestionnaire intégré en quelques minutes.

## Qu'est-ce que le gestionnaire intégré ?

Le gestionnaire intégré est un outil qui unifie les fonctionnalités du Mode Manager et du Roadmap Manager. Il permet de :

- Exécuter les modes opérationnels (CHECK, GRAN, etc.)
- Gérer les roadmaps (synchronisation, rapports, planification)
- Exécuter des workflows prédéfinis
- Automatiser les tâches récurrentes

## Installation rapide

1. Assurez-vous que PowerShell 5.1 ou supérieur est installé
2. Vérifiez que le module RoadmapParser est installé
3. Vérifiez que le gestionnaire intégré est correctement installé :

```powershell
.\development\scripts\integrated-manager.ps1 -ListModes
```

## Commandes essentielles

### Exécuter un mode

```powershell
# Exécuter le mode CHECK
.\development\scripts\integrated-manager.ps1 -Mode CHECK -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"

# Exécuter le mode GRAN
.\development\scripts\integrated-manager.ps1 -Mode GRAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"

# Exécuter le mode ROADMAP-SYNC
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "JSON"

# Exécuter le mode ROADMAP-REPORT
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-REPORT -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "HTML"

# Exécuter le mode ROADMAP-PLAN
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-PLAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"
```

### Exécuter un workflow

```powershell
# Exécuter le workflow de développement
.\development\scripts\integrated-manager.ps1 -Workflow "Development" -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"

# Exécuter le workflow de gestion de roadmap
.\development\scripts\integrated-manager.ps1 -Workflow "RoadmapManagement" -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"
```

### Exécuter un workflow automatisé

```powershell
# Exécuter le workflow quotidien
.\development\scripts\workflows\workflow-quotidien.ps1

# Exécuter le workflow hebdomadaire
.\development\scripts\workflows\workflow-hebdomadaire.ps1

# Exécuter le workflow mensuel
.\development\scripts\workflows\workflow-mensuel.ps1
```

### Installer les tâches planifiées

```powershell
# Installer les tâches planifiées
.\development\scripts\workflows\install-scheduled-tasks.ps1
```

## Exemples d'utilisation courants

### Vérifier l'état d'avancement d'une tâche

```powershell
.\development\scripts\integrated-manager.ps1 -Mode CHECK -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"
```

### Décomposer une tâche en sous-tâches

```powershell
.\development\scripts\integrated-manager.ps1 -Mode GRAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"
```

### Synchroniser une roadmap vers différents formats

```powershell
# Synchroniser vers JSON
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "JSON"

# Synchroniser vers HTML
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "HTML"

# Synchroniser vers CSV
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "CSV"
```

### Générer un rapport sur l'état d'une roadmap

```powershell
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-REPORT -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "HTML"
```

### Planifier les tâches futures

```powershell
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-PLAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"
```

### Exécuter un workflow complet de gestion de roadmap

```powershell
.\development\scripts\integrated-manager.ps1 -Workflow "RoadmapManagement" -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"
```

## Astuces

### Utiliser la configuration par défaut

Si vous utilisez la configuration par défaut, vous pouvez omettre certains paramètres :

```powershell
# Exécuter le mode CHECK avec la configuration par défaut
.\development\scripts\integrated-manager.ps1 -Mode CHECK -TaskIdentifier "1.2.3"

# Exécuter le mode ROADMAP-SYNC avec la configuration par défaut
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC
```

### Utiliser le mode WhatIf

Pour voir ce qu'un mode ou un workflow ferait sans l'exécuter réellement, utilisez le paramètre `-WhatIf` :

```powershell
# Voir ce que le mode CHECK ferait
.\development\scripts\integrated-manager.ps1 -Mode CHECK -TaskIdentifier "1.2.3" -WhatIf

# Voir ce que le workflow RoadmapManagement ferait
.\development\scripts\integrated-manager.ps1 -Workflow "RoadmapManagement" -WhatIf
```

### Utiliser le mode Verbose

Pour obtenir plus d'informations sur l'exécution d'un mode ou d'un workflow, utilisez le paramètre `-Verbose` :

```powershell
# Exécuter le mode CHECK en mode verbose
.\development\scripts\integrated-manager.ps1 -Mode CHECK -TaskIdentifier "1.2.3" -Verbose

# Exécuter le workflow RoadmapManagement en mode verbose
.\development\scripts\integrated-manager.ps1 -Workflow "RoadmapManagement" -Verbose
```

## Prochaines étapes

- Consultez le [guide d'utilisation complet](integrated-manager-guide.md) pour plus d'informations
- Explorez les [exemples d'utilisation des modes de roadmap](../examples/roadmap-modes-examples.md)
- Découvrez les [bonnes pratiques pour la gestion des roadmaps](../best-practices/roadmap-management.md)
- Apprenez à utiliser les [workflows automatisés](../automation/roadmap-workflows.md)
