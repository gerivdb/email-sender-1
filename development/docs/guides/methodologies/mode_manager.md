# Mode MANAGER

## Description
Le mode MANAGER est un mode opérationnel qui permet de gérer et d'orchestrer les différents modes du projet. Il offre une interface unifiée pour basculer entre les modes, configurer les paramètres et exécuter les modes de manière cohérente.

## Objectif
L'objectif principal du mode MANAGER est de simplifier l'utilisation des différents modes opérationnels et d'assurer une cohérence dans leur exécution. Il permet également d'enchaîner plusieurs modes pour créer des workflows complets.

## Fonctionnalités
- Interface unifiée pour tous les modes opérationnels
- Gestion centralisée de la configuration
- Exécution individuelle des modes
- Enchaînement de plusieurs modes
- Affichage de la liste des modes disponibles
- Affichage de la configuration des modes

## Utilisation

### Commande de base
```powershell
.\development\scripts\manager\mode-manager.ps1 -Mode <MODE> -FilePath <FILEPATH> -TaskIdentifier <TASKID> [-Force]
```

### Paramètres
| Paramètre | Description | Obligatoire | Valeur par défaut |
|-----------|-------------|-------------|-------------------|
| Mode | Le mode à exécuter (ARCHI, CHECK, C-BREAK, DEBUG, DEV-R, GRAN, OPTI, PREDIC, REVIEW, TEST) | Oui (sauf avec -ListModes, -ShowConfig ou -Chain) | - |
| FilePath | Chemin vers le fichier de roadmap ou le document actif | Non | Valeur de configuration |
| TaskIdentifier | Identifiant de la tâche à traiter (ex: "1.2.3") | Non | - |
| ConfigPath | Chemin vers le fichier de configuration | Non | Chemin par défaut |
| Force | Indique si les modifications doivent être appliquées sans confirmation | Non | $false |
| ListModes | Affiche la liste des modes disponibles et leurs descriptions | Non | $false |
| ShowConfig | Affiche la configuration actuelle du mode spécifié | Non | $false |
| Chain | Chaîne de modes à exécuter séquentiellement (ex: "GRAN,DEV-R,CHECK") | Non | - |

### Exemples

#### Exécuter un mode spécifique
```powershell
# Exécuter le mode CHECK
.\development\scripts\manager\mode-manager.ps1 -Mode CHECK -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -Force

# Exécuter le mode GRAN
.\development\scripts\manager\mode-manager.ps1 -Mode GRAN -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
```

#### Afficher la liste des modes disponibles
```powershell
.\development\scripts\manager\mode-manager.ps1 -ListModes
```

#### Afficher la configuration d'un mode
```powershell
.\development\scripts\manager\mode-manager.ps1 -ShowConfig -Mode CHECK
```

#### Exécuter une chaîne de modes
```powershell
# Exécuter GRAN, puis DEV-R, puis CHECK
.\development\scripts\manager\mode-manager.ps1 -Chain "GRAN,DEV-R,CHECK" -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
```

## Workflows prédéfinis

Le mode MANAGER permet d'exécuter des workflows prédéfinis en utilisant le paramètre `-Chain`. Voici quelques workflows utiles :

### Workflow de développement complet
```powershell
.\development\scripts\manager\mode-manager.ps1 -Chain "GRAN,DEV-R,TEST,CHECK" -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
```
Ce workflow décompose une tâche, l'implémente, la teste et vérifie son état d'avancement.

### Workflow d'optimisation
```powershell
.\development\scripts\manager\mode-manager.ps1 -Chain "REVIEW,OPTI,TEST,CHECK" -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
```
Ce workflow revoit le code, l'optimise, le teste et vérifie son état d'avancement.

### Workflow de débogage
```powershell
.\development\scripts\manager\mode-manager.ps1 -Chain "DEBUG,TEST,CHECK" -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
```
Ce workflow débogue le code, le teste et vérifie son état d'avancement.

## Configuration

La configuration du mode MANAGER se trouve dans le fichier `config.json` dans le répertoire `development\roadmap\parser\config`. Ce fichier contient la configuration de tous les modes opérationnels.

Exemple de configuration :
```json
{
  "General": {
    "RoadmapPath": "docs\\plans\\roadmap_complete_2.md",
    "ActiveDocumentPath": "docs\\plans\\plan-modes-stepup.md",
    "ReportPath": "reports"
  },
  "Modes": {
    "Check": {
      "Enabled": true,
      "ScriptPath": "development\\scripts\\maintenance\\modes\\check.ps1"
    },
    "Debug": {
      "Enabled": true,
      "ScriptPath": "development\\roadmap\\parser\\modes\\debug\\debug-mode.ps1"
    },
    // Autres modes...
  }
}
```

## Intégration avec d'autres modes

Le mode MANAGER s'intègre avec tous les autres modes opérationnels :
- **ARCHI** : Pour concevoir et valider l'architecture du système
- **CHECK** : Pour vérifier l'état d'avancement des tâches
- **C-BREAK** : Pour détecter et résoudre les dépendances circulaires
- **DEBUG** : Pour identifier et résoudre les problèmes
- **DEV-R** : Pour implémenter les tâches de la roadmap
- **GRAN** : Pour décomposer les tâches complexes
- **OPTI** : Pour améliorer les performances et la qualité du code
- **PREDIC** : Pour anticiper les performances et détecter les anomalies
- **REVIEW** : Pour évaluer et améliorer la qualité du code
- **TEST** : Pour créer et exécuter des tests

## Dépannage

### Problème : Le script d'un mode est introuvable
**Solution** : Vérifiez que le chemin du script est correctement configuré dans le fichier `config.json`. Vous pouvez également spécifier explicitement le chemin du script avec le paramètre `-ConfigPath`.

### Problème : Erreur lors de l'exécution d'un mode
**Solution** : Vérifiez les paramètres passés au mode. Assurez-vous que le fichier de roadmap et l'identifiant de tâche sont corrects. Consultez les logs d'erreur pour plus d'informations.

### Problème : La chaîne de modes s'arrête prématurément
**Solution** : La chaîne de modes s'arrête si un mode échoue. Vérifiez que chaque mode de la chaîne fonctionne correctement individuellement avant de les enchaîner.

## Bonnes pratiques
- Utilisez le mode MANAGER comme point d'entrée unique pour tous les modes opérationnels
- Créez des workflows personnalisés en enchaînant les modes adaptés à vos besoins
- Maintenez à jour la configuration des modes dans le fichier `config.json`
- Documentez les workflows que vous créez pour faciliter leur réutilisation
- Utilisez le paramètre `-Force` avec précaution, car il peut entraîner des modifications sans confirmation
