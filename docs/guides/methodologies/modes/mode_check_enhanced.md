# Mode CHECK Amélioré

## Description

Le mode CHECK amélioré est une version avancée du [mode CHECK](mode_check.md) qui vérifie si les tâches sélectionnées ont été implémentées à 100% et testées avec succès à 100%, puis met à jour automatiquement les cases à cocher dans le document actif.

## Améliorations par rapport au mode CHECK standard

- **Encodage UTF-8 avec BOM** : Tous les fichiers sont enregistrés en UTF-8 avec BOM, ce qui garantit une meilleure compatibilité avec les caractères accentués.
- **Préservation des indentations** : Les indentations dans les documents sont correctement préservées lors de la mise à jour des cases à cocher.
- **Meilleure détection des tâches** : L'algorithme de détection des tâches a été amélioré pour mieux identifier les tâches dans le document actif.
- **Préservation du texte complet des tâches** : Le texte complet des tâches est préservé lors de la mise à jour des cases à cocher.
- **Script wrapper simplifié** : Un script wrapper `check.ps1` est fourni pour faciliter l'utilisation du mode CHECK amélioré.

## Utilisation

Le mode CHECK amélioré est accessible via un script wrapper simplifié qui facilite son utilisation.

### Installation

Le mode CHECK amélioré est installé automatiquement avec les autres modes opérationnels. Le script wrapper `check.ps1` est placé dans le répertoire `tools\scripts\`.

### Syntaxe de base

```powershell
.\tools\scripts\check.ps1 [-FilePath <chemin_roadmap>] [-TaskIdentifier <id_tâche>] [-ActiveDocumentPath <chemin_document>] [-Force]
```

### Vérification simple (mode simulation)

Pour vérifier si les tâches sélectionnées ont été implémentées à 100% et testées avec succès à 100% sans appliquer les modifications :

```powershell
.\tools\scripts\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3"
```

### Mise à jour automatique des cases à cocher

Pour mettre à jour automatiquement les cases à cocher dans le document actif :

```powershell
.\tools\scripts\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -Force
```

### Spécification du document actif

Si le document actif ne peut pas être détecté automatiquement, vous pouvez le spécifier manuellement :

```powershell
.\tools\scripts\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -ActiveDocumentPath "docs/roadmap/roadmap.md" -Force
```

### Mode simulation et mode force

Par défaut, le mode CHECK amélioré fonctionne en mode simulation (`-Force` non spécifié) :
- Il affiche les modifications qui seraient apportées sans les appliquer
- Il indique le nombre de cases à cocher qui seraient mises à jour

Pour appliquer réellement les modifications, utilisez le paramètre `-Force` :
```powershell
.\tools\scripts\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -Force
```

### Paramètres complets

- **FilePath** : Chemin vers le fichier de roadmap à vérifier (par défaut : "docs/plans/plan-modes-stepup.md")
- **TaskIdentifier** : Identifiant de la tâche à vérifier (par exemple, "1.2.3")
- **ActiveDocumentPath** : Chemin vers le document actif à mettre à jour
- **Force** : Applique les modifications sans confirmation

## Fonctionnement interne

Le mode CHECK amélioré fonctionne en plusieurs étapes :

1. **Analyse de la roadmap** : Le script analyse le fichier de roadmap pour identifier les tâches et leur structure.
2. **Vérification de l'implémentation** : Pour chaque tâche, le script vérifie si l'implémentation est complète (100%).
3. **Vérification des tests** : Pour chaque tâche, le script vérifie si les tests sont complets et réussis (100%).
4. **Détection du document actif** : Le script tente de détecter automatiquement le document actif.
5. **Mise à jour des cases à cocher** : Si les conditions sont remplies, le script met à jour les cases à cocher dans le document actif.

### Composants principaux

Le mode CHECK amélioré utilise les fonctions suivantes :

1. `Invoke-RoadmapCheck` : Vérifie si les tâches sélectionnées ont été implémentées à 100% et testées avec succès à 100%.
2. `Update-RoadmapTaskStatus` : Met à jour le statut des tâches dans la roadmap.
3. `Update-ActiveDocumentCheckboxes-Enhanced` : Met à jour les cases à cocher dans le document actif avec support UTF-8 avec BOM.

### Détection du document actif

Le mode CHECK amélioré tente de détecter automatiquement le document actif en utilisant les méthodes suivantes :

1. Vérification de la variable d'environnement `VSCODE_ACTIVE_DOCUMENT`.
2. Recherche des fichiers Markdown récemment modifiés (dans les 30 dernières minutes).

Si aucun document actif ne peut être détecté automatiquement, vous pouvez le spécifier manuellement avec le paramètre `-ActiveDocumentPath`.

## Intégration avec les autres modes

Le mode CHECK amélioré s'intègre parfaitement avec les autres modes opérationnels :

- **Mode DEV-R** : Permet de vérifier automatiquement les tâches implémentées pendant le développement.
- **Mode GRAN** : Complémentaire au mode CHECK pour la granularisation des tâches.
- **Mode TEST** : Fournit les résultats de tests utilisés par le mode CHECK.

## Résolution des problèmes

### Problèmes d'encodage

Si vous rencontrez des problèmes d'encodage (caractères accentués mal affichés), assurez-vous que tous les fichiers sont enregistrés en UTF-8 avec BOM. Le mode CHECK amélioré tente de corriger automatiquement l'encodage, mais certains cas particuliers peuvent nécessiter une intervention manuelle.

### Problèmes de détection du document actif

Si le document actif ne peut pas être détecté automatiquement, utilisez le paramètre `-ActiveDocumentPath` pour le spécifier manuellement. Cela peut se produire si vous n'utilisez pas VS Code ou si le document n'a pas été modifié récemment.

### Problèmes de mise à jour des cases à cocher

Si les cases à cocher ne sont pas mises à jour correctement, vérifiez les points suivants :
- Les tâches ont bien été implémentées à 100% et testées avec succès à 100%
- Le format des tâches dans votre roadmap correspond au format attendu
- Vous avez utilisé le paramètre `-Force` pour appliquer les modifications
