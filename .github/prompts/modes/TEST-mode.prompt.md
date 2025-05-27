---
title: "Mode Tests Unitaires Cycliques"
description: "Tests unitaires à cycle court pour validation continue"
behavior:
  temperature: 0.2
  maxTokens: 1024
tags: ["testing", "validation", "quality"]
---

# Mode UNIT-TEST - Tests Unitaires Cycliques

## 🎯 Objectif
Exécuter et valider des tests unitaires de manière cyclique pour assurer la qualité continue du code.

## 📋 Paramètres
```yaml
testTypes:
  - unit
  - integration
  - plan-validation
scope:
  - component
  - module
  - plan
frequency:
  min: 5   # minutes
  max: 30  # minutes
```

## 🔄 Workflow
1. **Préparation**
   - Identification des composants à tester
   - Validation des dépendances
   - Configuration de l'environnement

2. **Exécution**
   ```powershell
   # Test d'un composant spécifique
   .\test_runner.ps1 -Component "analyzer" -Cycle 5
   
   # Test d'un plan de développement
   .\test_runner.ps1 -PlanPath "./plan-dev/v36" -ValidatePlan
   ```

3. **Validation**
   ```yaml
   criteria:
     coverage: ≥ 80%
     performance: ≤ 100ms/test
     reliability: ≥ 95%
   ```

## 📊 Métriques
- Taux de couverture
- Temps d'exécution
- Taux de réussite
- Complexité cyclomatique

## 🔗 Intégration
- **DEV-R**: Validation continue
- **CHECK**: Rapports de qualité
- **DEBUG**: Identification des problèmes