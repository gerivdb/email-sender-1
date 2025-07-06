# Package hybrid

internal/hybrid/selector.go


## Types

### DecisionCache

#### Methods

##### DecisionCache.Get

Méthodes du cache de décisions


```go
func (dc *DecisionCache) Get(key string) (*interfaces.ModeDecision, bool)
```

##### DecisionCache.Set

```go
func (dc *DecisionCache) Set(key string, decision *interfaces.ModeDecision)
```

### HybridMetrics

#### Methods

##### HybridMetrics.RecordDecision

Méthodes des métriques


```go
func (hm *HybridMetrics) RecordDecision(decision *interfaces.ModeDecision)
```

### ModeSelector

#### Methods

##### ModeSelector.SelectOptimalMode

```go
func (ms *ModeSelector) SelectOptimalMode(ctx context.Context, query interfaces.ContextQuery) (*interfaces.ModeDecision, error)
```

