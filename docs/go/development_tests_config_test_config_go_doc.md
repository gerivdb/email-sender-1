# Package config

Package config provides test configuration for Phase 5 validation


## Types

### TestConfig

TestConfig configuration pour les tests de la Phase 5


#### Methods

##### TestConfig.EnsureDirectories

EnsureDirectories crée les répertoires nécessaires pour les tests


```go
func (c *TestConfig) EnsureDirectories() error
```

##### TestConfig.GetTimeoutWithMultiplier

GetTimeoutWithMultiplier retourne un timeout avec le multiplicateur appliqué


```go
func (c *TestConfig) GetTimeoutWithMultiplier(baseTimeout time.Duration) time.Duration
```

##### TestConfig.IsCI

IsCI vérifie si nous sommes dans un environnement CI


```go
func (c *TestConfig) IsCI() bool
```

##### TestConfig.ShouldSkipTest

ShouldSkipTest vérifie si un type de test doit être ignoré


```go
func (c *TestConfig) ShouldSkipTest(testType string) bool
```

