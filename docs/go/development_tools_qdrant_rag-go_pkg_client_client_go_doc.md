# Package client

Package client fournit un client HTTP pour interagir avec QDrant


## Types

### Option

Option est une fonction qui configure le client QDrant


### QdrantAPIError

QdrantAPIError représente une erreur retournée par l'API QDrant


#### Methods

##### QdrantAPIError.Error

```go
func (e *QdrantAPIError) Error() string
```

##### QdrantAPIError.IsQdrantError

```go
func (e *QdrantAPIError) IsQdrantError() bool
```

### QdrantClient

QdrantClient est le client principal pour interagir avec QDrant via HTTP


#### Methods

##### QdrantClient.HealthCheck

HealthCheck vérifie si le serveur QDrant est disponible et fonctionne correctement


```go
func (c *QdrantClient) HealthCheck() error
```

##### QdrantClient.IsAlive

IsAlive vérifie rapidement si le serveur QDrant est accessible
Cette méthode utilise un cache pour éviter des requêtes trop fréquentes


```go
func (c *QdrantClient) IsAlive() bool
```

### QdrantConnectionError

QdrantConnectionError représente une erreur de connexion au serveur QDrant


#### Methods

##### QdrantConnectionError.Error

```go
func (e *QdrantConnectionError) Error() string
```

##### QdrantConnectionError.IsQdrantError

```go
func (e *QdrantConnectionError) IsQdrantError() bool
```

### QdrantError

QdrantError est l'interface commune pour toutes les erreurs QDrant


### QdrantTimeoutError

QdrantTimeoutError représente une erreur de timeout lors d'une requête à QDrant


#### Methods

##### QdrantTimeoutError.Error

```go
func (e *QdrantTimeoutError) Error() string
```

##### QdrantTimeoutError.IsQdrantError

```go
func (e *QdrantTimeoutError) IsQdrantError() bool
```

### TLSConfig

TLSConfig contient la configuration TLS pour le client


## Functions

### ShouldRetry

ShouldRetry détermine si une requête devrait être réessayée en fonction de l'erreur


```go
func ShouldRetry(err error) bool
```

### WithRetry

WithRetry exécute une fonction avec une stratégie de retry


```go
func WithRetry(maxRetries int, fn func() error) error
```

