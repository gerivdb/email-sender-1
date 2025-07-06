# Package ai

## Types

### PatternProcessor

PatternProcessor implements neural pattern recognition for code analysis


#### Methods

##### PatternProcessor.AnalyzeCodePatterns

AnalyzeCodePatterns analyzes Go code patterns in a project


```go
func (pp *PatternProcessor) AnalyzeCodePatterns(projectPath string) (*interfaces.PatternAnalysis, error)
```

##### PatternProcessor.AnalyzeScope

AnalyzeScope analyzes the scope of variables in a given AST node


```go
func (pp *PatternProcessor) AnalyzeScope(node ast.Node) *interfaces.ScopeInfo
```

### SimilarityScorer

SimilarityScorer implements semantic matching algorithms for templates


#### Methods

##### SimilarityScorer.CalculateJaccardSimilarity

CalculateJaccardSimilarity calculates Jaccard similarity between two string slices


```go
func (ss *SimilarityScorer) CalculateJaccardSimilarity(set1, set2 []string) float64
```

##### SimilarityScorer.CalculateSemanticWeight

CalculateSemanticWeight calculates semantic weight between templates with enhanced analysis


```go
func (ss *SimilarityScorer) CalculateSemanticWeight(template1, template2 *interfaces.Template) float64
```

##### SimilarityScorer.CalculateSimilarity

CalculateSimilarity calculates similarity between two templates


```go
func (ss *SimilarityScorer) CalculateSimilarity(template1, template2 *interfaces.Template) float64
```

##### SimilarityScorer.LevenshteinDistance

LevenshteinDistance calculates the Levenshtein distance between two strings


```go
func (ss *SimilarityScorer) LevenshteinDistance(a, b string) int
```

