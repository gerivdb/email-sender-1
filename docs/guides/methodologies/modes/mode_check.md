# Mode CHECK

## Description
Le mode CHECK est un mode opérationnel qui vérifie automatiquement si les tâches sont 100% implémentées et testées, puis les marque comme complètes dans la roadmap.

## Objectif
L'objectif principal du mode CHECK est d'automatiser la vérification de l'état d'avancement des tâches et de maintenir la roadmap à jour.

## Fonctionnalités
- Vérification automatique de l'implémentation des tâches
- Vérification automatique des tests associés aux tâches
- Marquage automatique des tâches complètes dans la roadmap
- Mise à jour automatique des cases à cocher dans le document actif
- Génération de rapports d'avancement

## Utilisation

```powershell
# Vérifier l'état d'avancement d'une tâche spécifique
.\check-mode.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3"

# Vérifier l'état d'avancement et mettre à jour la roadmap
.\check-mode.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -UpdateRoadmap

# Vérifier l'état d'avancement et simuler la mise à jour des cases à cocher dans le document actif
.\check-mode.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -CheckActiveDocument

# Vérifier l'état d'avancement et mettre à jour les cases à cocher dans le document actif spécifié
.\check-mode.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -ActiveDocumentPath "document_actif.md" -CheckActiveDocument -Force

# Vérifier l'état d'avancement, mettre à jour la roadmap et le document actif
.\check-mode.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -UpdateRoadmap -CheckActiveDocument -Force

# Détecter automatiquement le document actif et mettre à jour les cases à cocher
.\check-mode.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -CheckActiveDocument -Force
```

## Critères de validation
Une tâche est considérée comme complète si :
- [ ] Elle est 100% implémentée
- [ ] Elle a des tests associés
- [ ] Tous les tests passent avec succès
- [ ] La documentation est à jour

## Intégration avec d'autres modes
Le mode CHECK peut être utilisé en combinaison avec d'autres modes :
- **DEV-R** : Pour vérifier l'état d'avancement des tâches en cours de développement
- **TEST** : Pour vérifier que tous les tests passent avant de marquer une tâche comme complète
- **REVIEW** : Pour vérifier que le code a été revu avant de marquer une tâche comme complète

## Implémentation
Le mode CHECK est implémenté dans le script `check-mode.ps1` qui se trouve dans le dossier `tools/scripts/roadmap/modes/check`.

## Exemple de rapport
```
Rapport d'avancement :
- Tâche 1.1 : 100% implémentée, 100% testée ✓
- Tâche 1.2 : 75% implémentée, 50% testée ✗
- Tâche 1.3 : 100% implémentée, 100% testée ✓
- Tâche 2.1 : 0% implémentée, 0% testée ✗
```

## Bonnes pratiques
- Exécuter le mode CHECK régulièrement pour maintenir la roadmap à jour
- Vérifier manuellement les tâches marquées comme complètes
- Utiliser le mode CHECK avant de présenter l'avancement du projet
- Configurer des seuils de validation personnalisés si nécessaire
- Utiliser le paramètre `-ActiveDocumentPath` pour mettre à jour automatiquement les cases à cocher dans le document actif
- Vérifier que les tâches sont correctement identifiées dans le document actif (format des cases à cocher)

## Mise à jour des cases à cocher dans le document actif
Le mode CHECK peut automatiquement mettre à jour les cases à cocher dans le document actif lorsque les tâches sont implémentées et testées à 100%. Pour cela, il recherche les lignes qui contiennent des cases à cocher non cochées (`- [ ]`) et les remplace par des cases à cocher cochées (`- [x]`) si la tâche correspondante est complète.

### Détection du document actif
Le mode CHECK peut détecter automatiquement le document actif de plusieurs façons :
1. Via la variable d'environnement `VSCODE_ACTIVE_DOCUMENT` (si disponible)
2. En recherchant les fichiers Markdown récemment modifiés dans le répertoire courant
3. Via le paramètre `-ActiveDocumentPath` spécifié par l'utilisateur

### Formats de cases à cocher reconnus
Le script reconnaît plusieurs formats de cases à cocher :
```markdown
- [ ] **1.2.3** Nom de la tâche
- [ ] 1.2.3 Nom de la tâche
- [ ] Nom de la tâche
- [ ] [1.2.3] Nom de la tâche
- [ ] (1.2.3) Nom de la tâche
```

Le script prend également en charge les identifiants de tâches longs et complexes :
```markdown
- [ ] **1.3.1.2.2.1.2.1.1.1.1.1.3.2.5.6.2.6.2.1** Nom de la tâche
```

### Mode simulation et mode force
Par défaut, le mode CHECK fonctionne en mode simulation (`-Force` non spécifié) :
- Il affiche les modifications qui seraient apportées sans les appliquer
- Il indique le nombre de cases à cocher qui seraient mises à jour

Pour appliquer réellement les modifications, utilisez le paramètre `-Force` :
```powershell
.\check-mode.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -CheckActiveDocument -Force
```

Pour que la mise à jour fonctionne correctement, assurez-vous que les cases à cocher dans le document actif suivent l'un des formats reconnus et que les tâches sont implémentées et testées à 100%.
