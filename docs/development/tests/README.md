# Tests Unitaires

## Introduction

Les tests unitaires sont essentiels pour garantir la qualité et la fiabilité du code. Cette documentation décrit les tests unitaires implémentés pour le système de journal de bord RAG.

## Structure des tests

Les tests sont organisés selon la structure suivante:

```
tests/
  ├── unit/
  │   ├── components/
  │   │   ├── analysis/
  │   │   │   ├── WordCloudVisualization.spec.js
  │   │   │   ├── SentimentAnalysis.spec.js
  │   │   │   └── TopicTrends.spec.js
  │   │   ├── integrations/
  │   │   │   └── ERPNextIntegration.spec.js
  │   │   └── common/
  │   │       └── FilterPanel.spec.js
  │   └── services/
  │       ├── AnalysisService.spec.js
  │       └── ERPNextService.spec.js
  └── e2e/
      └── ...
```

## Outils de test

Les tests unitaires utilisent les outils suivants:

- **Jest**: Framework de test JavaScript
- **Vue Test Utils**: Bibliothèque de test pour Vue.js
- **jsdom**: Implémentation JavaScript de DOM pour les tests
- **sinon**: Bibliothèque de mocks, stubs et spies

## Exécution des tests

Pour exécuter les tests unitaires:

```bash
# Exécuter tous les tests
npm run test:unit

# Exécuter un fichier de test spécifique
npm run test:unit -- tests/unit/services/ERPNextService.spec.js

# Exécuter les tests avec un pattern
npm run test:unit -- -t "ERPNextService"

# Exécuter les tests en mode watch
npm run test:unit -- --watch
```

## Couverture de code

Pour générer un rapport de couverture de code:

```bash
npm run test:unit -- --coverage
```

Le rapport de couverture sera généré dans le répertoire `coverage/`.

## Bonnes pratiques

- Chaque composant et service doit avoir des tests unitaires
- Les tests doivent être indépendants les uns des autres
- Utilisez des mocks pour les dépendances externes
- Testez les cas normaux et les cas d'erreur
- Maintenez une couverture de code élevée
