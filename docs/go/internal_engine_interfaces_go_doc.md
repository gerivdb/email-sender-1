# Package engine

## Types

### PatternConfig

### PatternMatcher

### PatternResult

### RegexMatcher

#### Methods

##### RegexMatcher.Match

```go
func (rm *RegexMatcher) Match(content string) []PatternResult
```

##### RegexMatcher.Score

```go
func (rm *RegexMatcher) Score(result PatternResult) float64
```

