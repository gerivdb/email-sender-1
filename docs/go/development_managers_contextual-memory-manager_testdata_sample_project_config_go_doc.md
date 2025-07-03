# Package main

## Types

### AuthHandler

AuthHandler gère l'authentification HTTP


#### Methods

##### AuthHandler.LoginHandler

LoginHandler gère les demandes de connexion


```go
func (ah *AuthHandler) LoginHandler(w http.ResponseWriter, r *http.Request)
```

##### AuthHandler.RegisterHandler

RegisterHandler gère l'enregistrement de nouveaux utilisateurs


```go
func (ah *AuthHandler) RegisterHandler(w http.ResponseWriter, r *http.Request)
```

### BaseManager

BaseManager implémentation de base pour les managers


#### Methods

##### BaseManager.Close

Close ferme le manager


```go
func (bm *BaseManager) Close() error
```

##### BaseManager.GetName

GetName retourne le nom du manager


```go
func (bm *BaseManager) GetName() string
```

##### BaseManager.GetUptime

GetUptime retourne la durée d'activité


```go
func (bm *BaseManager) GetUptime() time.Duration
```

##### BaseManager.HealthCheck

HealthCheck vérifie l'état du manager


```go
func (bm *BaseManager) HealthCheck() error
```

##### BaseManager.Initialize

Initialize initialise le manager


```go
func (bm *BaseManager) Initialize(ctx context.Context) error
```

##### BaseManager.IsActive

IsActive vérifie si le manager est actif


```go
func (bm *BaseManager) IsActive() bool
```

### ConfigManager

ConfigManager gère les configurations


#### Methods

##### ConfigManager.GetAllConfigs

GetAllConfigs retourne toutes les configurations


```go
func (cm *ConfigManager) GetAllConfigs() map[string]interface{}
```

##### ConfigManager.GetConfig

GetConfig récupère une configuration


```go
func (cm *ConfigManager) GetConfig(key string) (interface{}, bool)
```

##### ConfigManager.LoadFromFile

LoadFromFile charge les configurations depuis un fichier


```go
func (cm *ConfigManager) LoadFromFile(filepath string) error
```

##### ConfigManager.SaveToFile

SaveToFile sauvegarde les configurations vers un fichier


```go
func (cm *ConfigManager) SaveToFile(filepath string) error
```

##### ConfigManager.SetConfig

SetConfig définit une configuration


```go
func (cm *ConfigManager) SetConfig(key string, value interface{})
```

### DatabaseConfig

DatabaseConfig contient la configuration de la base de données


#### Methods

##### DatabaseConfig.ConnectionString

ConnectionString génère la chaîne de connexion


```go
func (dc *DatabaseConfig) ConnectionString() string
```

### Manager

Manager interface pour les gestionnaires


### User

User représente un utilisateur


### UserManager

UserManager gère les utilisateurs


#### Methods

##### UserManager.AuthenticateUser

AuthenticateUser authentifie un utilisateur


```go
func (um *UserManager) AuthenticateUser(ctx context.Context, username, password string) (bool, error)
```

##### UserManager.CreateUser

CreateUser crée un nouvel utilisateur


```go
func (um *UserManager) CreateUser(ctx context.Context, username, email, password string) error
```

##### UserManager.GetUser

GetUser récupère un utilisateur par son nom d'utilisateur


```go
func (um *UserManager) GetUser(ctx context.Context, username string) (*User, error)
```

##### UserManager.InitializeDatabase

InitializeDatabase initialise la connexion à la base de données


```go
func (um *UserManager) InitializeDatabase() error
```

