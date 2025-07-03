# Package storage

## Types

### APIStore

APIStore implements the Store interface using the remote http server


#### Methods

##### APIStore.Create

Create implements Store.Create


```go
func (s *APIStore) Create(_ context.Context, server *config.MCPConfig) error
```

##### APIStore.Delete

Delete implements Store.Delete


```go
func (s *APIStore) Delete(_ context.Context, tenant, name string) error
```

##### APIStore.DeleteVersion

DeleteVersion implements Store.DeleteVersion


```go
func (s *APIStore) DeleteVersion(_ context.Context, tenant, name string, version int) error
```

##### APIStore.Get

Get implements Store.Get


```go
func (s *APIStore) Get(_ context.Context, tenant, name string, includeDeleted ...bool) (*config.MCPConfig, error)
```

##### APIStore.GetVersion

GetVersion implements Store.GetVersion


```go
func (s *APIStore) GetVersion(_ context.Context, tenant, name string, version int) (*config.MCPConfigVersion, error)
```

##### APIStore.List

List implements Store.List


```go
func (s *APIStore) List(_ context.Context, _ ...bool) ([]*config.MCPConfig, error)
```

##### APIStore.ListUpdated

ListUpdated implements Store.ListUpdated


```go
func (s *APIStore) ListUpdated(_ context.Context, since time.Time) ([]*config.MCPConfig, error)
```

##### APIStore.ListVersions

ListVersions implements Store.ListVersions


```go
func (s *APIStore) ListVersions(_ context.Context, tenant, name string) ([]*config.MCPConfigVersion, error)
```

##### APIStore.SetActiveVersion

SetActiveVersion implements Store.SetActiveVersion


```go
func (s *APIStore) SetActiveVersion(_ context.Context, tenant, name string, version int) error
```

##### APIStore.Update

Update implements Store.Update


```go
func (s *APIStore) Update(_ context.Context, _ *config.MCPConfig) error
```

### ActiveVersion

ActiveVersion represents the currently active version of an MCP configuration


### DBStore

DBStore implements the Store interface using a database


#### Methods

##### DBStore.Create

Create implements Store.Create


```go
func (s *DBStore) Create(_ context.Context, server *config.MCPConfig) error
```

##### DBStore.Delete

Delete implements Store.Delete


```go
func (s *DBStore) Delete(ctx context.Context, tenant, name string) error
```

##### DBStore.DeleteVersion

DeleteVersion deletes a specific version


```go
func (s *DBStore) DeleteVersion(ctx context.Context, tenant, name string, version int) error
```

##### DBStore.Get

Get implements Store.Get


```go
func (s *DBStore) Get(_ context.Context, tenant, name string, includeDeleted ...bool) (*config.MCPConfig, error)
```

##### DBStore.GetVersion

GetVersion gets a specific version of the configuration


```go
func (s *DBStore) GetVersion(ctx context.Context, tenant, name string, version int) (*config.MCPConfigVersion, error)
```

##### DBStore.List

List implements Store.List


```go
func (s *DBStore) List(_ context.Context, includeDeleted ...bool) ([]*config.MCPConfig, error)
```

##### DBStore.ListUpdated

ListUpdated implements Store.ListUpdated


```go
func (s *DBStore) ListUpdated(_ context.Context, since time.Time) ([]*config.MCPConfig, error)
```

##### DBStore.ListVersions

ListVersions lists all versions of a configuration


```go
func (s *DBStore) ListVersions(ctx context.Context, tenant, name string) ([]*config.MCPConfigVersion, error)
```

##### DBStore.SetActiveVersion

SetActiveVersion sets a specific version as the active version


```go
func (s *DBStore) SetActiveVersion(ctx context.Context, tenant, name string, version int) error
```

##### DBStore.Update

Update implements Store.Update


```go
func (s *DBStore) Update(ctx context.Context, server *config.MCPConfig) error
```

### DatabaseType

DatabaseType represents the type of database


### DiskStore

#### Methods

##### DiskStore.Create

```go
func (s *DiskStore) Create(_ context.Context, server *config.MCPConfig) error
```

##### DiskStore.Delete

```go
func (s *DiskStore) Delete(_ context.Context, tenant, name string) error
```

##### DiskStore.DeleteVersion

```go
func (s *DiskStore) DeleteVersion(_ context.Context, tenant, name string, version int) error
```

##### DiskStore.Get

```go
func (s *DiskStore) Get(_ context.Context, tenant, name string, includeDeleted ...bool) (*config.MCPConfig, error)
```

##### DiskStore.GetActiveVersion

```go
func (s *DiskStore) GetActiveVersion(_ context.Context, tenant, name string) (*config.MCPConfig, error)
```

##### DiskStore.GetVersion

```go
func (s *DiskStore) GetVersion(_ context.Context, tenant, name string, version int) (*config.MCPConfigVersion, error)
```

##### DiskStore.List

```go
func (s *DiskStore) List(_ context.Context, _ ...bool) ([]*config.MCPConfig, error)
```

##### DiskStore.ListUpdated

ListUpdated implements Store.ListUpdated


```go
func (s *DiskStore) ListUpdated(_ context.Context, since time.Time) ([]*config.MCPConfig, error)
```

##### DiskStore.ListVersions

```go
func (s *DiskStore) ListVersions(_ context.Context, tenant, name string) ([]*config.MCPConfigVersion, error)
```

##### DiskStore.SetActiveVersion

```go
func (s *DiskStore) SetActiveVersion(_ context.Context, tenant, name string, version int) error
```

##### DiskStore.Update

```go
func (s *DiskStore) Update(_ context.Context, server *config.MCPConfig) error
```

### MCPConfig

MCPConfig represents the database model for MCPConfig


#### Methods

##### MCPConfig.BeforeCreate

BeforeCreate is a GORM hook that sets timestamps


```go
func (m *MCPConfig) BeforeCreate(_ *gorm.DB) error
```

##### MCPConfig.BeforeUpdate

BeforeUpdate is a GORM hook that updates the UpdatedAt timestamp


```go
func (m *MCPConfig) BeforeUpdate(_ *gorm.DB) error
```

##### MCPConfig.ToMCPConfig

ToMCPConfig converts the database model to MCPConfig


```go
func (m *MCPConfig) ToMCPConfig() (*config.MCPConfig, error)
```

### MCPConfigVersion

MCPConfigVersion represents the database model for MCPConfigVersion


#### Methods

##### MCPConfigVersion.ToConfigVersion

```go
func (m *MCPConfigVersion) ToConfigVersion() *config.MCPConfigVersion
```

##### MCPConfigVersion.ToMCPConfig

ToMCPConfig converts the database model to MCPConfig


```go
func (m *MCPConfigVersion) ToMCPConfig() (*config.MCPConfig, error)
```

### Store

Store defines the interface for MCP configuration storage


