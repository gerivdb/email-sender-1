---
mode: 'agent'
tools: ['terminalLastCommand']
description: 'Exécuter un mode opérationnel du projet'
---

# Exécution d'un Mode Opérationnel

Exécuter le mode opérationnel spécifié avec les paramètres fournis selon les méthodologies définies dans `projet/guides/methodologies/`.

## Paramètres Requis
- **Mode** : [GRAN|CHECK|DEV-R|ARCHI|DEBUG]
- **Fichier cible** : Chemin vers le fichier de plan/roadmap
- **Identifiant de tâche** : ID de la tâche à traiter

## Instructions d'Exécution
1. Consulter `projet/guides/methodologies/index.md` pour les détails du mode
2. Vérifier les prérequis dans `docs/guides/standards/`
3. Utiliser les scripts dans `tools/scripts/roadmap/modes/`
4. Appliquer le suivi temps réel défini dans `.github/instructions/plan-executor.instructions.md`

## Exemple d'Utilisation
```powershell
# Mode GRAN pour décomposer une tâche
.\gran-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -TaskId "1.2.3"

# Mode CHECK pour valider une implémentation
.\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskId "1.2.3" -Force
```

## Suivi et Logging
- Timestamp de début et fin
- Progression des sous-tâches
- Sauvegarde automatique de l'état
- Mise à jour du fichier de plan en temps réel

Si aucun paramètre n'est fourni, demander à l'utilisateur de spécifier le mode et les paramètres nécessaires.