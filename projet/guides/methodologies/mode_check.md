# Mode CHECK

## Description

Le mode CHECK est un mode opérationnel qui permet de vérifier si les tâches d'une roadmap ont été implémentées à 100% et testées avec succès à 100%. Si c'est le cas, il peut mettre à jour automatiquement le statut des tâches dans la roadmap en cochant les cases correspondantes.

## Fonctionnalités

- Vérification de l'implémentation des tâches
- Vérification des tests associés aux tâches
- Mise à jour automatique des cases à cocher dans la roadmap
- Génération de rapports de vérification
- Mise à jour des cases à cocher dans le document actif

## Utilisation

### Commande de base

```powershell
.\tools\scripts\check.ps1 -TaskIdentifier "1.2.3" -ActiveDocumentPath "docs\plans\plan-modes-stepup.md"
```plaintext
### Paramètres

- **TaskIdentifier** : Identifiant de la tâche à vérifier (par exemple, "1.2.1.3.2.3").
- **ActiveDocumentPath** : Chemin vers le document actif à mettre à jour.
- **RoadmapPath** : Chemin vers le fichier de roadmap à vérifier et mettre à jour.
- **WhatIf** : Si spécifié, simule les actions sans les exécuter.

### Exemples

Vérifier une tâche spécifique et mettre à jour le document actif :

```powershell
.\tools\scripts\check.ps1 -TaskIdentifier "1.2.3" -ActiveDocumentPath "docs\plans\plan-modes-stepup.md"
```plaintext
Vérifier une tâche spécifique sans mettre à jour le document actif (simulation) :

```powershell
.\tools\scripts\check.ps1 -TaskIdentifier "1.2.3" -ActiveDocumentPath "docs\plans\plan-modes-stepup.md" -WhatIf
```plaintext
## Architecture

Le mode CHECK est composé des éléments suivants :

1. **Script principal** : `check.ps1`
2. **Script de mode** : `check-mode-enhanced.ps1`
3. **Fonctions publiques** :
   - `Invoke-RoadmapCheck.ps1` : Vérifie si les tâches ont été implémentées et testées
   - `Update-RoadmapTaskStatus.ps1` : Met à jour le statut des tâches dans la roadmap
   - `Update-ActiveDocumentCheckboxes.ps1` : Met à jour les cases à cocher dans le document actif

4. **Fonctions privées** :
   - Fonctions de configuration
   - Fonctions d'encodage
   - Fonctions de test

## Configuration

La configuration du mode CHECK se trouve dans le fichier `config.json` dans le répertoire `tools\scripts\roadmap-parser\config`.

```json
{
  "Check": {
    "DefaultRoadmapFile": "docs\\plans\\roadmap_complete_2.md",
    "DefaultActiveDocumentPath": "docs\\plans\\plan-modes-stepup.md",
    "AutoUpdateRoadmap": true,
    "GenerateReport": true,
    "ReportPath": "reports",
    "AutoUpdateCheckboxes": true,
    "RequireFullTestCoverage": true,
    "SimulationModeDefault": true
  }
}
```plaintext
## Algorithme de vérification

1. Charger la configuration
2. Identifier la tâche à vérifier dans la roadmap
3. Vérifier si l'implémentation est complète
   - Rechercher les fichiers d'implémentation correspondants
   - Analyser le contenu des fichiers pour déterminer le pourcentage d'implémentation
4. Vérifier si les tests sont complets et réussis
   - Rechercher les fichiers de test correspondants
   - Exécuter les tests pour vérifier s'ils réussissent
5. Si l'implémentation et les tests sont à 100%, marquer la tâche comme terminée
   - Mettre à jour la roadmap
   - Mettre à jour le document actif
6. Générer un rapport de vérification

## Intégration avec d'autres modes

Le mode CHECK s'intègre avec les autres modes opérationnels :

- **Mode DEBUG** : Utilise les informations de débogage pour vérifier l'implémentation
- **Mode GRAN** : Vérifie les tâches granularisées
- **Mode ARCHI** : Vérifie l'architecture des composants
- **Mode C-BREAK** : Vérifie les dépendances circulaires

## Dépendances

- PowerShell 5.1 ou supérieur
- Module Pester pour l'exécution des tests
- Accès en lecture/écriture aux fichiers de roadmap et au document actif

## Limitations

- Les tests doivent être nommés selon la convention `Test-*.ps1`
- Les fichiers d'implémentation doivent être dans le répertoire spécifié
- Les tâches doivent être identifiées par un identifiant numérique (par exemple, "1.2.3")

## Résolution des problèmes

### Problèmes courants

1. **Erreur de chemin** : Vérifier que les chemins spécifiés sont corrects
2. **Erreur d'encodage** : Vérifier que les fichiers sont encodés en UTF-8 avec BOM
3. **Erreur de test** : Vérifier que les tests sont correctement implémentés
4. **Erreur de configuration** : Vérifier que le fichier de configuration est correctement formaté

### Solutions

1. Utiliser le paramètre `-WhatIf` pour simuler les actions sans les exécuter
2. Vérifier les journaux d'erreurs dans le répertoire `logs`
3. Exécuter les tests manuellement pour vérifier s'ils réussissent
4. Vérifier que les fichiers d'implémentation sont correctement nommés et placés

## Exemples de code

### Vérification d'une tâche

```powershell
$result = Invoke-RoadmapCheck -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3"
```plaintext
### Mise à jour du statut d'une tâche

```powershell
Update-RoadmapTaskStatus -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3" -Status "Completed"
```plaintext
### Mise à jour des cases à cocher dans le document actif

```powershell
Update-ActiveDocumentCheckboxes -FilePath "docs/plans/plan-modes-stepup.md" -TaskIdentifier "1.2.3" -Status "Completed"
```plaintext
## Bonnes pratiques

1. Toujours utiliser le paramètre `-WhatIf` pour simuler les actions avant de les exécuter
2. Vérifier que les tests sont correctement implémentés et qu'ils réussissent
3. Vérifier que les fichiers d'implémentation sont correctement nommés et placés
4. Utiliser des identifiants de tâche précis pour éviter les erreurs
5. Mettre à jour régulièrement la roadmap pour refléter l'état réel du projet

## Conclusion

Le mode CHECK est un outil puissant pour vérifier l'état d'avancement d'un projet et mettre à jour automatiquement la roadmap. Il permet de s'assurer que les tâches sont correctement implémentées et testées avant d'être marquées comme terminées.
