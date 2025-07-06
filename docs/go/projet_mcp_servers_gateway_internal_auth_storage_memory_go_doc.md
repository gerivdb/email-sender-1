# Package storage

## Types

### AuthorizationCode

AuthorizationCode represents an authorization code


### Client

Client represents an OAuth2 client


### MemoryStorage

MemoryStorage implements the Store interface using in-memory storage


#### Methods

##### MemoryStorage.CreateClient

CreateClient creates a new client


```go
func (s *MemoryStorage) CreateClient(ctx context.Context, client *Client) error
```

##### MemoryStorage.DeleteAuthorizationCode

DeleteAuthorizationCode deletes an authorization code


```go
func (s *MemoryStorage) DeleteAuthorizationCode(ctx context.Context, code string) error
```

##### MemoryStorage.DeleteClient

DeleteClient deletes a client


```go
func (s *MemoryStorage) DeleteClient(ctx context.Context, clientID string) error
```

##### MemoryStorage.DeleteToken

DeleteToken deletes a token


```go
func (s *MemoryStorage) DeleteToken(ctx context.Context, accessToken string) error
```

##### MemoryStorage.DeleteTokensByClientID

DeleteTokensByClientID deletes all tokens for a client


```go
func (s *MemoryStorage) DeleteTokensByClientID(ctx context.Context, clientID string) error
```

##### MemoryStorage.GetAuthorizationCode

GetAuthorizationCode retrieves an authorization code


```go
func (s *MemoryStorage) GetAuthorizationCode(ctx context.Context, code string) (*AuthorizationCode, error)
```

##### MemoryStorage.GetClient

GetClient retrieves a client by ID


```go
func (s *MemoryStorage) GetClient(ctx context.Context, clientID string) (*Client, error)
```

##### MemoryStorage.GetToken

GetToken retrieves a token


```go
func (s *MemoryStorage) GetToken(ctx context.Context, accessToken string) (*Token, error)
```

##### MemoryStorage.SaveAuthorizationCode

SaveAuthorizationCode saves an authorization code


```go
func (s *MemoryStorage) SaveAuthorizationCode(ctx context.Context, code *AuthorizationCode) error
```

##### MemoryStorage.SaveToken

SaveToken saves a token


```go
func (s *MemoryStorage) SaveToken(ctx context.Context, token *Token) error
```

##### MemoryStorage.UpdateClient

UpdateClient updates an existing client


```go
func (s *MemoryStorage) UpdateClient(ctx context.Context, client *Client) error
```

### RedisStorage

RedisStorage implements the Store interface using Redis


#### Methods

##### RedisStorage.CreateClient

CreateClient creates a new client


```go
func (s *RedisStorage) CreateClient(ctx context.Context, client *Client) error
```

##### RedisStorage.DeleteAuthorizationCode

DeleteAuthorizationCode deletes an authorization code


```go
func (s *RedisStorage) DeleteAuthorizationCode(ctx context.Context, code string) error
```

##### RedisStorage.DeleteClient

DeleteClient deletes a client


```go
func (s *RedisStorage) DeleteClient(ctx context.Context, clientID string) error
```

##### RedisStorage.DeleteToken

DeleteToken deletes a token


```go
func (s *RedisStorage) DeleteToken(ctx context.Context, accessToken string) error
```

##### RedisStorage.DeleteTokensByClientID

DeleteTokensByClientID deletes all tokens for a client


```go
func (s *RedisStorage) DeleteTokensByClientID(ctx context.Context, clientID string) error
```

##### RedisStorage.GetAuthorizationCode

GetAuthorizationCode retrieves an authorization code


```go
func (s *RedisStorage) GetAuthorizationCode(ctx context.Context, code string) (*AuthorizationCode, error)
```

##### RedisStorage.GetClient

GetClient retrieves a client by ID


```go
func (s *RedisStorage) GetClient(ctx context.Context, clientID string) (*Client, error)
```

##### RedisStorage.GetToken

GetToken retrieves a token


```go
func (s *RedisStorage) GetToken(ctx context.Context, accessToken string) (*Token, error)
```

##### RedisStorage.SaveAuthorizationCode

SaveAuthorizationCode saves an authorization code


```go
func (s *RedisStorage) SaveAuthorizationCode(ctx context.Context, code *AuthorizationCode) error
```

##### RedisStorage.SaveToken

SaveToken saves a token


```go
func (s *RedisStorage) SaveToken(ctx context.Context, token *Token) error
```

##### RedisStorage.UpdateClient

UpdateClient updates an existing client


```go
func (s *RedisStorage) UpdateClient(ctx context.Context, client *Client) error
```

### Store

Store defines the interface for OAuth2 data storage


### Token

Token represents an OAuth2 token


