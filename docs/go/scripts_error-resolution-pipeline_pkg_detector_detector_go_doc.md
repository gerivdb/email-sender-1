# Package detector

Package detector implémente le système de détection d'erreurs du pipeline


## Types

### CircularDependencyPattern

CircularDependencyPattern détecte les dépendances circulaires


#### Methods

##### CircularDependencyPattern.Detect

```go
func (p *CircularDependencyPattern) Detect(node ast.Node, info *types.Info, fset *token.FileSet) []DetectedError
```

##### CircularDependencyPattern.Name

```go
func (p *CircularDependencyPattern) Name() string
```

##### CircularDependencyPattern.Priority

```go
func (p *CircularDependencyPattern) Priority() int
```

### ComplexityPattern

ComplexityPattern détecte la complexité excessive


#### Methods

##### ComplexityPattern.Detect

```go
func (p *ComplexityPattern) Detect(node ast.Node, info *types.Info, fset *token.FileSet) []DetectedError
```

##### ComplexityPattern.Name

```go
func (p *ComplexityPattern) Name() string
```

##### ComplexityPattern.Priority

```go
func (p *ComplexityPattern) Priority() int
```

### Config

Config contient la configuration du détecteur


### DetectedError

DetectedError représente une erreur détectée


### DetectorMetrics

DetectorMetrics contient les métriques Prometheus


### ErrorDetector

ErrorDetector représente le moteur principal de détection d'erreurs


#### Methods

##### ErrorDetector.DetectInDirectory

DetectInDirectory détecte les erreurs dans un répertoire


```go
func (ed *ErrorDetector) DetectInDirectory(ctx context.Context, dirPath string) ([]DetectedError, error)
```

##### ErrorDetector.DetectInFile

DetectInFile détecte les erreurs dans un fichier spécifique


```go
func (ed *ErrorDetector) DetectInFile(ctx context.Context, filePath string) ([]DetectedError, error)
```

### ErrorPattern

ErrorPattern définit un pattern de détection d'erreur


### Severity

Severity définit la sévérité d'une erreur


#### Methods

##### Severity.String

String retourne la représentation string de la sévérité


```go
func (s Severity) String() string
```

### TypeMismatchPattern

TypeMismatchPattern détecte les erreurs de type


#### Methods

##### TypeMismatchPattern.Detect

```go
func (p *TypeMismatchPattern) Detect(node ast.Node, info *types.Info, fset *token.FileSet) []DetectedError
```

##### TypeMismatchPattern.Name

```go
func (p *TypeMismatchPattern) Name() string
```

##### TypeMismatchPattern.Priority

```go
func (p *TypeMismatchPattern) Priority() int
```

### UnusedVariablePattern

UnusedVariablePattern détecte les variables non utilisées


#### Methods

##### UnusedVariablePattern.Detect

```go
func (p *UnusedVariablePattern) Detect(node ast.Node, info *types.Info, fset *token.FileSet) []DetectedError
```

##### UnusedVariablePattern.Name

```go
func (p *UnusedVariablePattern) Name() string
```

##### UnusedVariablePattern.Priority

```go
func (p *UnusedVariablePattern) Priority() int
```

