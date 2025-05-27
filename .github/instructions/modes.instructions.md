# Instructions Copilot - Modes Opérationnels

## 🎯 Objectif
Utiliser les modes opérationnels spécialisés définis dans `projet/guides/methodologies/` pour optimiser les workflows de développement.

## 📋 Modes Disponibles

### Mode GRAN (Granularisation)
**Objectif** : Décomposer une tâche complexe en sous-tâches détaillées
```powershell
.\gran-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -TaskId "1.2.3"
```

### Mode CHECK (Vérification Améliorée)
**Objectif** : Valider l'implémentation et les tests d'une tâche
```powershell
.\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskId "1.2.3" -Force
```

### Mode DEV-R (Développement Récursif)
**Objectif** : Développement itératif avec amélioration continue
```powershell
.\dev-r-mode.ps1 -TaskPath "docs/roadmap/" -TaskId "2.1" -Iterations 3
```

### Mode ARCHI (Architecture)
**Objectif** : Conception et validation architecturale
```powershell
.\archi-mode.ps1 -ProjectPath "." -AnalyzeStructure -GenerateReport
```

### Mode DEBUG (Débogage Avancé)
**Objectif** : Analyse et résolution de problèmes complexes
```powershell
.\debug-mode.ps1 -LogPath "logs/" -AnalysisLevel "Deep" -AutoFix
```

## 🔄 Combinaisons de Modes Recommandées

### Pour Développement Nouveau
1. **ARCHI** → Conception de l'architecture
2. **GRAN** → Décomposition en tâches
3. **DEV-R** → Implémentation itérative
4. **CHECK** → Validation finale

### Pour Résolution de Problèmes
1. **DEBUG** → Identification du problème
2. **ARCHI** → Évaluation de l'impact architectural
3. **DEV-R** → Correction itérative
4. **CHECK** → Validation de la correction

### Pour Refactoring
1. **CHECK** → État initial
2. **ARCHI** → Nouvelle structure
3. **GRAN** → Planification étapes
4. **DEV-R** → Refactoring progressif
5. **CHECK** → Validation finale

## 📊 Suivi de l'Exécution des Modes
```markdown
## Historique d'Exécution des Modes
- **[Timestamp]** Mode **[NOM]** sur tâche **[ID]**
  - 📋 **Objectif** : [Description]
  - ✅ **Résultat** : [Succès/Échec]
  - 📝 **Détails** : [Informations supplémentaires]
  - 🔗 **Fichiers modifiés** : [Liste des fichiers]
```

## 🔧 Scripts Associés
- **Dossier principal** : `tools/scripts/roadmap/modes/`
- **Configuration** : `projet/guides/methodologies/`
- **Logs des modes** : `logs/modes/`

## ⚡ Raccourcis Copilot pour Modes
Utiliser ces prompts pour invoquer rapidement les modes :

**Prompt GRAN** :
```
Applique le mode GRAN sur la tâche [ID] du fichier [chemin]. Décompose en sous-tâches détaillées.
```

**Prompt CHECK** :
```
Exécute le mode CHECK sur la tâche [ID]. Vérifie implémentation et tests à 100%.
```

**Prompt DEV-R** :
```
Lance le mode DEV-R pour la tâche [ID] avec [n] itérations d'amélioration.
```

## 📚 Références Détaillées
- **Index des méthodologies** : `projet/guides/methodologies/index.md`
- **Mode CHECK amélioré** : `projet/guides/methodologies/mode_check_enhanced.md`
- **Configuration des modes** : `projet/guides/methodologies/config/`

---
*Instructions spécialisées pour les modes opérationnels du projet*