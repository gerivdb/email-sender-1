# Mode ARCHI

## Description
Le mode ARCHI (Architecture) est un mode opÃ©rationnel qui se concentre sur la conception et l'analyse de l'architecture du systÃ¨me.

## Objectif
L'objectif principal du mode ARCHI est de concevoir, documenter et valider l'architecture du systÃ¨me pour assurer sa qualitÃ©, sa maintenabilitÃ© et son Ã©volutivitÃ©.

## FonctionnalitÃ©s
- Conception d'architecture
- ModÃ©lisation de systÃ¨mes
- Analyse de dÃ©pendances
- Documentation d'architecture
- Validation d'architecture

## Utilisation

```powershell
# Analyser l'architecture existante
.\archi-mode.ps1 -SourcePath "src" -OutputPath "projet/architecture"

# GÃ©nÃ©rer un diagramme d'architecture
.\archi-mode.ps1 -SourcePath "src" -OutputPath "projet/architecture" -GenerateDiagram

# Valider l'architecture par rapport Ã  des rÃ¨gles
.\archi-mode.ps1 -SourcePath "src" -RulesPath "config/architecture-rules.json" -Validate
```

## Types d'architecture
Le mode ARCHI peut travailler avec diffÃ©rents types d'architecture :
- **Architecture logicielle** : Conception des composants logiciels
- **Architecture systÃ¨me** : Conception du systÃ¨me dans son ensemble
- **Architecture de donnÃ©es** : Conception des structures de donnÃ©es
- **Architecture d'intÃ©gration** : Conception des interfaces entre systÃ¨mes

## IntÃ©gration avec d'autres modes
Le mode ARCHI peut Ãªtre utilisÃ© en combinaison avec d'autres modes :
- **DEV-R** : Pour concevoir l'architecture avant de commencer le dÃ©veloppement
- **REVIEW** : Pour valider l'architecture implÃ©mentÃ©e
- **C-BREAK** : Pour dÃ©tecter et rÃ©soudre les dÃ©pendances circulaires

## ImplÃ©mentation
Le mode ARCHI est implÃ©mentÃ© dans le script `archi-mode.ps1` qui se trouve dans le dossier `tools/scripts/roadmap/modes/archi`.

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
- Documenter l'architecture avant de commencer l'implÃ©mentation
- Valider l'architecture par rapport aux exigences
- Maintenir la documentation d'architecture Ã  jour
- Utiliser des diagrammes pour visualiser l'architecture
- Suivre les principes SOLID dans la conception
- Minimiser les dÃ©pendances entre composants
- PrÃ©voir l'Ã©volutivitÃ© de l'architecture
