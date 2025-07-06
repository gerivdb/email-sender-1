# Package main

## Types

### CLIConfig

CLIConfig définit la configuration pour l'interface en ligne de commande


### Fix

Fix représente une correction proposée


### LoggedError

### MockErrorManager

MockErrorManager implements ErrorManager for demo purposes


#### Methods

##### MockErrorManager.CatalogError

```go
func (m *MockErrorManager) CatalogError(entry ErrorEntry) error
```

##### MockErrorManager.GetCatalogedErrors

```go
func (m *MockErrorManager) GetCatalogedErrors() []ErrorEntry
```

##### MockErrorManager.GetLoggedErrors

```go
func (m *MockErrorManager) GetLoggedErrors() []LoggedError
```

##### MockErrorManager.LogError

```go
func (m *MockErrorManager) LogError(err error, module string, code string)
```

##### MockErrorManager.ValidateError

```go
func (m *MockErrorManager) ValidateError(entry ErrorEntry) error
```

### ReviewAction

ReviewAction représente les actions possibles lors de la revue


### SafetyLevel

SafetyLevel définit le niveau de sécurité des suggestions


### SuggestionConfig

SuggestionConfig définit les paramètres pour la génération de suggestions


### ValidationConfig

ValidationConfig définit les paramètres pour la validation des corrections


### ValidationSystem

ValidationSystem gère la validation des corrections


#### Methods

##### ValidationSystem.AddValidator

AddValidator ajoute un nouveau validateur


```go
func (v *ValidationSystem) AddValidator(validator Validator)
```

##### ValidationSystem.ValidateFile

ValidateFile valide un fichier entier


```go
func (v *ValidationSystem) ValidateFile(ctx context.Context, filePath string) error
```

##### ValidationSystem.ValidateFix

ValidateFix valide une correction proposée


```go
func (v *ValidationSystem) ValidateFix(ctx context.Context, fix *Fix) error
```

### Validator

Validator définit l'interface pour les validateurs


## Functions

### DemoIntegration

DemoIntegration démontre l'utilisation du gestionnaire d'erreurs intégré


```go
func DemoIntegration()
```

### DemoIntegrationWithConcurrency

DemoIntegrationWithConcurrency démontre la gestion d'erreurs concurrent


```go
func DemoIntegrationWithConcurrency()
```

### SimulateManagerErrors

SimulateManagerErrors simule des erreurs spécifiques à chaque manager


```go
func SimulateManagerErrors()
```

