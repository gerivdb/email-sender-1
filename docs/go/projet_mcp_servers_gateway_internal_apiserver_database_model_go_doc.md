# Package database

## Types

### Database

Database defines the methods for database operations.


### Message

Message represents a chat message


### MySQL

MySQL implements the Database interface using MySQL


#### Methods

##### MySQL.AddUserToTenant

AddUserToTenant adds a user to a tenant


```go
func (db *MySQL) AddUserToTenant(ctx context.Context, userID, tenantID uint) error
```

##### MySQL.Close

Close closes the database connection


```go
func (db *MySQL) Close() error
```

##### MySQL.CreateSession

```go
func (db *MySQL) CreateSession(ctx context.Context, sessionId string) error
```

##### MySQL.CreateSessionWithTitle

```go
func (db *MySQL) CreateSessionWithTitle(ctx context.Context, sessionId string, title string) error
```

##### MySQL.CreateTenant

CreateTenant creates a new tenant


```go
func (db *MySQL) CreateTenant(ctx context.Context, tenant *Tenant) error
```

##### MySQL.CreateUser

CreateUser creates a new user


```go
func (db *MySQL) CreateUser(ctx context.Context, user *User) error
```

##### MySQL.DeleteSession

DeleteSession deletes a session by ID


```go
func (db *MySQL) DeleteSession(ctx context.Context, sessionID string) error
```

##### MySQL.DeleteTenant

DeleteTenant deletes a tenant by ID


```go
func (db *MySQL) DeleteTenant(ctx context.Context, id uint) error
```

##### MySQL.DeleteUser

DeleteUser deletes a user by ID


```go
func (db *MySQL) DeleteUser(ctx context.Context, id uint) error
```

##### MySQL.DeleteUserTenants

DeleteUserTenants deletes all tenant associations for a user


```go
func (db *MySQL) DeleteUserTenants(ctx context.Context, userID uint) error
```

##### MySQL.GetMessages

```go
func (db *MySQL) GetMessages(ctx context.Context, sessionID string) ([]*Message, error)
```

##### MySQL.GetMessagesWithPagination

```go
func (db *MySQL) GetMessagesWithPagination(ctx context.Context, sessionID string, page, pageSize int) ([]*Message, error)
```

##### MySQL.GetSessions

```go
func (db *MySQL) GetSessions(ctx context.Context) ([]*Session, error)
```

##### MySQL.GetTenantByID

GetTenantByID retrieves a tenant by ID


```go
func (db *MySQL) GetTenantByID(ctx context.Context, id uint) (*Tenant, error)
```

##### MySQL.GetTenantByName

GetTenantByName retrieves a tenant by name


```go
func (db *MySQL) GetTenantByName(ctx context.Context, name string) (*Tenant, error)
```

##### MySQL.GetTenantUsers

GetTenantUsers gets all users for a tenant


```go
func (db *MySQL) GetTenantUsers(ctx context.Context, tenantID uint) ([]*User, error)
```

##### MySQL.GetUserByUsername

GetUserByUsername retrieves a user by username


```go
func (db *MySQL) GetUserByUsername(ctx context.Context, username string) (*User, error)
```

##### MySQL.GetUserTenants

GetUserTenants gets all tenants for a user


```go
func (db *MySQL) GetUserTenants(ctx context.Context, userID uint) ([]*Tenant, error)
```

##### MySQL.ListTenants

ListTenants retrieves all tenants


```go
func (db *MySQL) ListTenants(ctx context.Context) ([]*Tenant, error)
```

##### MySQL.ListUsers

ListUsers retrieves all users


```go
func (db *MySQL) ListUsers(ctx context.Context) ([]*User, error)
```

##### MySQL.RemoveUserFromTenant

RemoveUserFromTenant removes a user from a tenant


```go
func (db *MySQL) RemoveUserFromTenant(ctx context.Context, userID, tenantID uint) error
```

##### MySQL.SaveMessage

```go
func (db *MySQL) SaveMessage(ctx context.Context, message *Message) error
```

##### MySQL.SessionExists

```go
func (db *MySQL) SessionExists(ctx context.Context, sessionID string) (bool, error)
```

##### MySQL.Transaction

Transaction implements Database.Transaction


```go
func (db *MySQL) Transaction(ctx context.Context, fn func(ctx context.Context) error) error
```

##### MySQL.UpdateSessionTitle

```go
func (db *MySQL) UpdateSessionTitle(ctx context.Context, sessionID string, title string) error
```

##### MySQL.UpdateTenant

UpdateTenant updates an existing tenant


```go
func (db *MySQL) UpdateTenant(ctx context.Context, tenant *Tenant) error
```

##### MySQL.UpdateUser

UpdateUser updates an existing user


```go
func (db *MySQL) UpdateUser(ctx context.Context, user *User) error
```

### Postgres

Postgres implements the Database interface using PostgreSQL


#### Methods

##### Postgres.AddUserToTenant

AddUserToTenant adds a user to a tenant


```go
func (db *Postgres) AddUserToTenant(ctx context.Context, userID, tenantID uint) error
```

##### Postgres.Close

Close closes the database connection


```go
func (db *Postgres) Close() error
```

##### Postgres.CreateSession

CreateSession creates a new session with the given sessionId


```go
func (db *Postgres) CreateSession(ctx context.Context, sessionId string) error
```

##### Postgres.CreateSessionWithTitle

CreateSessionWithTitle creates a new session with the given sessionId and title


```go
func (db *Postgres) CreateSessionWithTitle(ctx context.Context, sessionId string, title string) error
```

##### Postgres.CreateTenant

CreateTenant creates a new tenant


```go
func (db *Postgres) CreateTenant(ctx context.Context, tenant *Tenant) error
```

##### Postgres.CreateUser

CreateUser creates a new user


```go
func (db *Postgres) CreateUser(ctx context.Context, user *User) error
```

##### Postgres.DeleteSession

DeleteSession deletes a session by ID


```go
func (db *Postgres) DeleteSession(ctx context.Context, sessionID string) error
```

##### Postgres.DeleteTenant

DeleteTenant deletes a tenant by ID


```go
func (db *Postgres) DeleteTenant(ctx context.Context, id uint) error
```

##### Postgres.DeleteUser

DeleteUser deletes a user by ID


```go
func (db *Postgres) DeleteUser(ctx context.Context, id uint) error
```

##### Postgres.DeleteUserTenants

DeleteUserTenants deletes all tenant associations for a user


```go
func (db *Postgres) DeleteUserTenants(ctx context.Context, userID uint) error
```

##### Postgres.GetMessages

GetMessages retrieves all messages for a session


```go
func (db *Postgres) GetMessages(ctx context.Context, sessionID string) ([]*Message, error)
```

##### Postgres.GetMessagesWithPagination

GetMessagesWithPagination retrieves messages for a specific session with pagination


```go
func (db *Postgres) GetMessagesWithPagination(ctx context.Context, sessionID string, page, pageSize int) ([]*Message, error)
```

##### Postgres.GetSessions

GetSessions retrieves all chat sessions with their latest message


```go
func (db *Postgres) GetSessions(ctx context.Context) ([]*Session, error)
```

##### Postgres.GetTenantByID

GetTenantByID retrieves a tenant by ID


```go
func (db *Postgres) GetTenantByID(ctx context.Context, id uint) (*Tenant, error)
```

##### Postgres.GetTenantByName

GetTenantByName retrieves a tenant by name


```go
func (db *Postgres) GetTenantByName(ctx context.Context, name string) (*Tenant, error)
```

##### Postgres.GetTenantUsers

GetTenantUsers gets all users for a tenant


```go
func (db *Postgres) GetTenantUsers(ctx context.Context, tenantID uint) ([]*User, error)
```

##### Postgres.GetUserByUsername

GetUserByUsername retrieves a user by username


```go
func (db *Postgres) GetUserByUsername(ctx context.Context, username string) (*User, error)
```

##### Postgres.GetUserTenants

GetUserTenants gets all tenants for a user


```go
func (db *Postgres) GetUserTenants(ctx context.Context, userID uint) ([]*Tenant, error)
```

##### Postgres.ListTenants

ListTenants retrieves all tenants


```go
func (db *Postgres) ListTenants(ctx context.Context) ([]*Tenant, error)
```

##### Postgres.ListUsers

ListUsers retrieves all users


```go
func (db *Postgres) ListUsers(ctx context.Context) ([]*User, error)
```

##### Postgres.RemoveUserFromTenant

RemoveUserFromTenant removes a user from a tenant


```go
func (db *Postgres) RemoveUserFromTenant(ctx context.Context, userID, tenantID uint) error
```

##### Postgres.SaveMessage

SaveMessage saves a message to the database


```go
func (db *Postgres) SaveMessage(ctx context.Context, message *Message) error
```

##### Postgres.SessionExists

SessionExists checks if a session exists


```go
func (db *Postgres) SessionExists(ctx context.Context, sessionID string) (bool, error)
```

##### Postgres.Transaction

Transaction implements Database.Transaction


```go
func (db *Postgres) Transaction(ctx context.Context, fn func(ctx context.Context) error) error
```

##### Postgres.UpdateSessionTitle

UpdateSessionTitle updates the title of a session


```go
func (db *Postgres) UpdateSessionTitle(ctx context.Context, sessionID string, title string) error
```

##### Postgres.UpdateTenant

UpdateTenant updates an existing tenant


```go
func (db *Postgres) UpdateTenant(ctx context.Context, tenant *Tenant) error
```

##### Postgres.UpdateUser

UpdateUser updates an existing user


```go
func (db *Postgres) UpdateUser(ctx context.Context, user *User) error
```

### SQLite

SQLite implements the Database interface using SQLite


#### Methods

##### SQLite.AddUserToTenant

AddUserToTenant adds a user to a tenant


```go
func (db *SQLite) AddUserToTenant(ctx context.Context, userID, tenantID uint) error
```

##### SQLite.Close

Close closes the database connection


```go
func (db *SQLite) Close() error
```

##### SQLite.CreateSession

```go
func (db *SQLite) CreateSession(ctx context.Context, sessionId string) error
```

##### SQLite.CreateSessionWithTitle

```go
func (db *SQLite) CreateSessionWithTitle(ctx context.Context, sessionId string, title string) error
```

##### SQLite.CreateTenant

CreateTenant creates a new tenant


```go
func (db *SQLite) CreateTenant(ctx context.Context, tenant *Tenant) error
```

##### SQLite.CreateUser

CreateUser creates a new user


```go
func (db *SQLite) CreateUser(ctx context.Context, user *User) error
```

##### SQLite.DeleteSession

DeleteSession deletes a session by ID


```go
func (db *SQLite) DeleteSession(ctx context.Context, sessionID string) error
```

##### SQLite.DeleteTenant

DeleteTenant deletes a tenant by ID


```go
func (db *SQLite) DeleteTenant(ctx context.Context, id uint) error
```

##### SQLite.DeleteUser

DeleteUser deletes a user by ID


```go
func (db *SQLite) DeleteUser(ctx context.Context, id uint) error
```

##### SQLite.DeleteUserTenants

DeleteUserTenants deletes all tenant associations for a user


```go
func (db *SQLite) DeleteUserTenants(ctx context.Context, userID uint) error
```

##### SQLite.GetMessages

```go
func (db *SQLite) GetMessages(ctx context.Context, sessionID string) ([]*Message, error)
```

##### SQLite.GetMessagesWithPagination

```go
func (db *SQLite) GetMessagesWithPagination(ctx context.Context, sessionID string, page, pageSize int) ([]*Message, error)
```

##### SQLite.GetSessions

```go
func (db *SQLite) GetSessions(ctx context.Context) ([]*Session, error)
```

##### SQLite.GetTenantByID

GetTenantByID retrieves a tenant by ID


```go
func (db *SQLite) GetTenantByID(ctx context.Context, id uint) (*Tenant, error)
```

##### SQLite.GetTenantByName

GetTenantByName retrieves a tenant by name


```go
func (db *SQLite) GetTenantByName(ctx context.Context, name string) (*Tenant, error)
```

##### SQLite.GetTenantUsers

GetTenantUsers gets all users for a tenant


```go
func (db *SQLite) GetTenantUsers(ctx context.Context, tenantID uint) ([]*User, error)
```

##### SQLite.GetUserByUsername

GetUserByUsername retrieves a user by username


```go
func (db *SQLite) GetUserByUsername(ctx context.Context, username string) (*User, error)
```

##### SQLite.GetUserTenants

GetUserTenants gets all tenants for a user


```go
func (db *SQLite) GetUserTenants(ctx context.Context, userID uint) ([]*Tenant, error)
```

##### SQLite.ListTenants

ListTenants retrieves all tenants


```go
func (db *SQLite) ListTenants(ctx context.Context) ([]*Tenant, error)
```

##### SQLite.ListUsers

ListUsers retrieves all users


```go
func (db *SQLite) ListUsers(ctx context.Context) ([]*User, error)
```

##### SQLite.RemoveUserFromTenant

RemoveUserFromTenant removes a user from a tenant


```go
func (db *SQLite) RemoveUserFromTenant(ctx context.Context, userID, tenantID uint) error
```

##### SQLite.SaveMessage

```go
func (db *SQLite) SaveMessage(ctx context.Context, message *Message) error
```

##### SQLite.SessionExists

```go
func (db *SQLite) SessionExists(ctx context.Context, sessionID string) (bool, error)
```

##### SQLite.Transaction

Transaction implements Database.Transaction


```go
func (db *SQLite) Transaction(ctx context.Context, fn func(ctx context.Context) error) error
```

##### SQLite.UpdateSessionTitle

```go
func (db *SQLite) UpdateSessionTitle(ctx context.Context, sessionID string, title string) error
```

##### SQLite.UpdateTenant

UpdateTenant updates an existing tenant


```go
func (db *SQLite) UpdateTenant(ctx context.Context, tenant *Tenant) error
```

##### SQLite.UpdateUser

UpdateUser updates an existing user


```go
func (db *SQLite) UpdateUser(ctx context.Context, user *User) error
```

### Session

Session represents a chat session


### Tenant

Tenant represents a tenant in the system


### User

User represents an admin user


### UserRole

UserRole represents the role of a user


### UserTenant

UserTenant represents the relationship between a user and a tenant


## Functions

### ContextWithTransaction

ContextWithTransaction creates a context containing a transaction


```go
func ContextWithTransaction(ctx context.Context, tx *gorm.DB) context.Context
```

### InitDefaultTenant

InitDefaultTenant initializes the default tenant if it doesn't exist


```go
func InitDefaultTenant(db *gorm.DB) error
```

### TransactionFromContext

TransactionFromContext extracts a transaction from the context


```go
func TransactionFromContext(ctx context.Context) *gorm.DB
```

