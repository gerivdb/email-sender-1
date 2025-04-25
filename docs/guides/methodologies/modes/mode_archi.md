# Mode ARCHI

## Description
Le mode ARCHI (Architecture) est un mode opérationnel qui se concentre sur la conception et l'analyse de l'architecture du système.

## Objectif
L'objectif principal du mode ARCHI est de concevoir, documenter et valider l'architecture du système pour assurer sa qualité, sa maintenabilité et son évolutivité.

## Fonctionnalités
- Conception d'architecture
- Modélisation de systèmes
- Analyse de dépendances
- Documentation d'architecture
- Validation d'architecture

## Utilisation

```powershell
# Analyser l'architecture existante
.\archi-mode.ps1 -SourcePath "src" -OutputPath "docs/architecture"

# Générer un diagramme d'architecture
.\archi-mode.ps1 -SourcePath "src" -OutputPath "docs/architecture" -GenerateDiagram

# Valider l'architecture par rapport à des règles
.\archi-mode.ps1 -SourcePath "src" -RulesPath "config/architecture-rules.json" -Validate
```

## Types d'architecture
Le mode ARCHI peut travailler avec différents types d'architecture :
- **Architecture logicielle** : Conception des composants logiciels
- **Architecture système** : Conception du système dans son ensemble
- **Architecture de données** : Conception des structures de données
- **Architecture d'intégration** : Conception des interfaces entre systèmes

## Intégration avec d'autres modes
Le mode ARCHI peut être utilisé en combinaison avec d'autres modes :
- **DEV-R** : Pour concevoir l'architecture avant de commencer le développement
- **REVIEW** : Pour valider l'architecture implémentée
- **C-BREAK** : Pour détecter et résoudre les dépendances circulaires

## Implémentation
Le mode ARCHI est implémenté dans le script `archi-mode.ps1` qui se trouve dans le dossier `tools/scripts/roadmap/modes/archi`.

## Exemple de diagramme d'architecture
```
+---------------+      +---------------+
|    Frontend   |----->|     API       |
+---------------+      +---------------+
                              |
                              v
+---------------+      +---------------+
|   Database    |<-----|   Services    |
+---------------+      +---------------+
```

## Bonnes pratiques
- Documenter l'architecture avant de commencer l'implémentation
- Valider l'architecture par rapport aux exigences
- Maintenir la documentation d'architecture à jour
- Utiliser des diagrammes pour visualiser l'architecture
- Suivre les principes SOLID dans la conception
- Minimiser les dépendances entre composants
- Prévoir l'évolutivité de l'architecture
