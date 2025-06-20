# Resolution Strategies Documentation

## Interfaces et stratégies

- **ResolutionStrategy** : Interface avec Execute(), Validate(), Rollback()
- **AutoMergeStrategy** : Fusion automatique sécurisée
- **UserPromptStrategy** : Résolution interactive
- **BackupAndReplaceStrategy** : Sauvegarde puis remplacement
- **PriorityBasedStrategy** : Résolution selon criticité
- **StrategyChain** : Combinaison de stratégies

## Exemple d'utilisation

```go
conflict := Conflict{Type: ContentConflict}
strat := &AutoMergeStrategy{}
res, err := strat.Execute(conflict)
if err == nil {
    _ = strat.Validate(res)
}
```

## Tests

Chaque stratégie est testée dans `strategy_test.go` avec mocks et cas d'échec.
