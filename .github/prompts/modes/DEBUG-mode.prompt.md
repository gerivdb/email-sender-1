---
mode: 'agent'
tools: ['debugging']
description: 'Analyse et résolution de problèmes complexes'
---

# Mode DEBUG - Débogage Avancé

## 🎯 OBJECTIF
Analyser et résoudre les problèmes complexes de manière systématique

## 📋 PARAMÈTRES
- **LogPath** : Chemin des logs d'analyse
- **AnalysisLevel** : Profondeur d'analyse ("Quick", "Deep", "Comprehensive")
- **AutoFix** : Activation des corrections automatiques

## 🔄 WORKFLOW
1. Collecte des informations
2. Analyse des logs et traces
3. Reproduction du problème
4. Identification de la cause
5. Application de la solution

## 🛠️ COMMANDES PRINCIPALES
```powershell
# Analyse profonde avec auto-correction
.\debug-mode.ps1 -LogPath "logs/" -AnalysisLevel "Deep" -AutoFix

# Analyse rapide sans correction
.\debug-mode.ps1 -LogPath "logs/" -AnalysisLevel "Quick"

# Debug d'un composant spécifique
.\debug-mode.ps1 -ComponentPath "./src/component" -Verbose
```

## 📝 FORMAT DE RAPPORT
```markdown
# Rapport de Débogage [Date]

## Problème Analysé
- [Description du problème]

## Cause Racine
- [Analyse de la cause]

## Solution Appliquée
1. [Étape 1]
2. [Étape 2]

## Validation
- [Tests effectués]
- [Résultats obtenus]
```

## 🔗 INTÉGRATION
- **CHECK** : Validation post-correction
- **DEV-R** : Application itérative des corrections
- **ARCHI** : Impact sur l'architecture