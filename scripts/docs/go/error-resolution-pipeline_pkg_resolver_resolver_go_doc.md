# Package resolver

Package resolver implémente le système de résolution automatique d'erreurs


## Types

### AutoResolver

AutoResolver représente le moteur de résolution automatique


#### Methods

##### AutoResolver.RegisterFixer

RegisterFixer enregistre un nouveau fixer


```go
func (ar *AutoResolver) RegisterFixer(errorType string, fixer ErrorFixer)
```

##### AutoResolver.ResolveErrors

ResolveErrors résout automatiquement une liste d'erreurs


```go
func (ar *AutoResolver) ResolveErrors(ctx context.Context, errors []detector.DetectedError) ([]FixResult, error)
```

### ChangeDetail

ChangeDetail décrit une modification apportée


### CircularDependencyFixer

CircularDependencyFixer résout les dépendances circulaires


#### Methods

##### CircularDependencyFixer.CanFix

```go
func (f *CircularDependencyFixer) CanFix(error detector.DetectedError) bool
```

##### CircularDependencyFixer.Fix

```go
func (f *CircularDependencyFixer) Fix(ctx context.Context, error detector.DetectedError, source []byte) (*FixResult, error)
```

##### CircularDependencyFixer.Safety

```go
func (f *CircularDependencyFixer) Safety() SafetyLevel
```

### ComplexityFixer

ComplexityFixer réduit la complexité en extrayant des méthodes


#### Methods

##### ComplexityFixer.CanFix

```go
func (f *ComplexityFixer) CanFix(error detector.DetectedError) bool
```

##### ComplexityFixer.Fix

```go
func (f *ComplexityFixer) Fix(ctx context.Context, error detector.DetectedError, source []byte) (*FixResult, error)
```

##### ComplexityFixer.Safety

```go
func (f *ComplexityFixer) Safety() SafetyLevel
```

### Config

Config contient la configuration du résolveur


### ErrorFixer

ErrorFixer interface pour les fixers spécifiques


### FixExample

FixExample contient un exemple de fix


### FixPattern

FixPattern définit un pattern de résolution


### FixResult

FixResult contient le résultat d'une correction


### KnowledgeBase

KnowledgeBase contient les patterns de résolution


### SafetyLevel

SafetyLevel définit le niveau de sécurité d'un fix


#### Methods

##### SafetyLevel.String

String retourne la représentation string du niveau de sécurité


```go
func (sl SafetyLevel) String() string
```

### TypeMismatchFixer

TypeMismatchFixer corrige les problèmes de types


#### Methods

##### TypeMismatchFixer.CanFix

```go
func (f *TypeMismatchFixer) CanFix(error detector.DetectedError) bool
```

##### TypeMismatchFixer.Fix

```go
func (f *TypeMismatchFixer) Fix(ctx context.Context, error detector.DetectedError, source []byte) (*FixResult, error)
```

##### TypeMismatchFixer.Safety

```go
func (f *TypeMismatchFixer) Safety() SafetyLevel
```

### UnusedVariableFixer

UnusedVariableFixer corrige les variables non utilisées


#### Methods

##### UnusedVariableFixer.CanFix

```go
func (f *UnusedVariableFixer) CanFix(error detector.DetectedError) bool
```

##### UnusedVariableFixer.Fix

```go
func (f *UnusedVariableFixer) Fix(ctx context.Context, error detector.DetectedError, source []byte) (*FixResult, error)
```

##### UnusedVariableFixer.Safety

```go
func (f *UnusedVariableFixer) Safety() SafetyLevel
```

