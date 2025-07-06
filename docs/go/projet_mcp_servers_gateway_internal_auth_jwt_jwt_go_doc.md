# Package jwt

## Types

### Claims

Claims represents the JWT claims


### Config

Config represents the JWT configuration


### Service

Service represents the JWT service


#### Methods

##### Service.GenerateToken

GenerateToken generates a new JWT token


```go
func (s *Service) GenerateToken(userID uint, username string, role string) (string, error)
```

##### Service.ValidateToken

ValidateToken validates a JWT token


```go
func (s *Service) ValidateToken(tokenString string) (*Claims, error)
```

## Variables

### ErrInvalidToken, ErrExpiredToken

```go
var (
	ErrInvalidToken	= errors.New("invalid token")
	ErrExpiredToken	= errors.New("token has expired")
)
```

