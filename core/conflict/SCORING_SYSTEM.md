# Scoring and Priority System Documentation

## Interfaces et structures

- **ConflictScorer** : Interface avec Calculate(), Compare()
- **MultiCriteriaScorer** : Algorithme multi-critères (impact, urgence, complexité)
- **PriorityQueue** : File de priorité pour conflits scorés
- **ScoringConfig** : Poids dynamiques
- **ScoreHistory** : Historique des scores
- **ScoringMetrics** : Précision du scoring

## Exemple d'utilisation

```go
scorer := &MultiCriteriaScorer{ImpactWeight: 1, UrgencyWeight: 2, ComplexityWeight: 3}
conf := Conflict{Metadata: map[string]interface{}{"impact": 2.0, "urgency": 1.0, "complexity": 0.5}}
score := scorer.Calculate(conf)
```

## Tests

Tous les composants sont testés dans `scoring_test.go`.
