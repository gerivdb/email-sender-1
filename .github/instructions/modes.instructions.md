# Instructions Copilot - Modes Opérationnels

Ce fichier décrit les modes opérationnels personnalisés pour Copilot.

## 🎯 Objectif

Utiliser les modes opérationnels spécialisés définis dans `projet/guides/methodologies/` pour optimiser les workflows de développement.

## 📋 Modes Disponibles

### Mode GRAN (Granularisation)

**Objectif** : Décomposer une tâche complexe en sous-tâches détaillées
```powershell
.\gran-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -TaskId "1.2.3"
```plaintext
### Mode CHECK (Vérification Améliorée)

**Objectif** : Valider l'implémentation et les tests d'une tâche
```powershell
.\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskId "1.2.3" -Force
```plaintext
### Mode DEV-R (Développement Récursif)

**Objectif** : Développement itératif avec amélioration continue
```powershell
.\dev-r-mode.ps1 -TaskPath "docs/roadmap/" -TaskId "2.1" -Iterations 3
```plaintext
### Mode ARCHI (Architecture)

**Objectif** : Conception et validation architecturale
```powershell
.\archi-mode.ps1 -ProjectPath "." -AnalyzeStructure -GenerateReport
```plaintext
### Mode DEBUG (Débogage Avancé)

**Objectif** : Analyse et résolution de problèmes complexes
```powershell
.\debug-mode.ps1 -LogPath "logs/" -AnalysisLevel "Deep" -AutoFix
```plaintext
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
```plaintext
## 🔧 Scripts Associés

- **Dossier principal** : `tools/scripts/roadmap/modes/`
- **Configuration** : `projet/guides/methodologies/`
- **Logs des modes** : `logs/modes/`

## ⚡ Raccourcis Copilot pour Modes

Utiliser ces prompts pour invoquer rapidement les modes :

**Prompt GRAN** :
```plaintext
Applique le mode GRAN sur la tâche [ID] du fichier [chemin]. Décompose en sous-tâches détaillées.
```plaintext
**Prompt CHECK** :
```plaintext
Exécute le mode CHECK sur la tâche [ID]. Vérifie implémentation et tests à 100%.
```plaintext
**Prompt DEV-R** :
```plaintext
Lance le mode DEV-R pour la tâche [ID] avec [n] itérations d'amélioration.
```plaintext
## 📚 Références Détaillées

- **Index des méthodologies** : `projet/guides/methodologies/index.md`
- **Mode CHECK amélioré** : `projet/guides/methodologies/mode_check_enhanced.md`
- **Configuration des modes** : `projet/guides/methodologies/config/`

---
*Instructions spécialisées pour les modes opérationnels du projet*

## Modes disponibles

- **Mode standard** : Respect strict des standards globaux du projet (voir [Standards et Conventions](../../docs/guides/standards/README.md)).
- **Mode plan** : Exécution guidée par les plans de développement (voir `.github/instructions/plan-executor.instructions.md`).
- **Mode augment** : Intégration avancée avec l’extension Augment (voir [Guides Augment](../../docs/guides/augment/)).
- **Mode DEV-R** : Réalisation/exécution de tâches existantes ou planifiées, avec focus sur la robustesse, les tests, le debug, et la livraison incrémentale. Ne pas inclure de refonte ou migration majeure (voir mode GRAN).
- **Mode GRAN** : Grands travaux de refonte, migration, restructuration ou évolution architecturale. Focus sur la conception, la documentation approfondie, la validation globale, et la planification de rollback.

### Différences entre DEV-R et GRAN

- **DEV-R** : Implémentation et exécution de tâches existantes ou planifiées. Focus sur la robustesse, les tests, le debug, et la livraison incrémentale. Ne pas inclure de refonte ou migration majeure.
- **GRAN** : Refonte, migration, ou restructuration profonde d’un module ou d’une architecture. Focus sur la conception, la documentation, la validation globale, et la planification de rollback.

### Extrait du guide méthodologique

> « Les modes opérationnels permettent d’adapter le comportement de Copilot selon le contexte : génération de code, documentation, exécution de plans, ou intégration IA. »

Pour plus de détails, consultez `projet/guides/methodologies/`.