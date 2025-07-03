# Package storage

## Types

### JSONStorage

JSONStorage handles JSON-based persistence for roadmap data


#### Methods

##### JSONStorage.Close

Close is a no-op for JSON storage but maintains interface compatibility


```go
func (js *JSONStorage) Close() error
```

##### JSONStorage.CreateEnrichedItem

CreateEnrichedItem adds a new roadmap item with enriched fields


```go
func (js *JSONStorage) CreateEnrichedItem(options types.EnrichedItemOptions) (*types.RoadmapItem, error)
```

##### JSONStorage.CreateEnrichedItems

CreateEnrichedItems adds multiple enriched roadmap items in batch


```go
func (js *JSONStorage) CreateEnrichedItems(enrichedItems []types.EnrichedItemOptions) ([]types.RoadmapItem, error)
```

##### JSONStorage.CreateItem

CreateItem adds a new roadmap item with basic fields


```go
func (js *JSONStorage) CreateItem(title, description, priority string, targetDate time.Time) (*types.RoadmapItem, error)
```

##### JSONStorage.CreateMilestone

CreateMilestone adds a new milestone


```go
func (js *JSONStorage) CreateMilestone(title, description string, targetDate time.Time) (*types.Milestone, error)
```

##### JSONStorage.DeleteItem

DeleteItem removes an item by ID


```go
func (js *JSONStorage) DeleteItem(id string) error
```

##### JSONStorage.GetAllItems

GetAllItems returns all roadmap items


```go
func (js *JSONStorage) GetAllItems() ([]types.RoadmapItem, error)
```

##### JSONStorage.GetAllMilestones

GetAllMilestones returns all milestones


```go
func (js *JSONStorage) GetAllMilestones() ([]types.Milestone, error)
```

##### JSONStorage.UpdateItem

UpdateItem updates an existing roadmap item with provided updates


```go
func (js *JSONStorage) UpdateItem(id string, updates map[string]interface{}) error
```

##### JSONStorage.UpdateItemStatus

UpdateItemStatus updates an item's status and progress


```go
func (js *JSONStorage) UpdateItemStatus(id, status string, progress int) error
```

### Migration

Migration represents a data migration


### MigrationManager

MigrationManager handles data migrations between versions


#### Methods

##### MigrationManager.GetAvailableMigrations

GetAvailableMigrations returns all available migrations


```go
func (m *MigrationManager) GetAvailableMigrations() []Migration
```

##### MigrationManager.RunMigrations

RunMigrations executes all pending migrations


```go
func (m *MigrationManager) RunMigrations() error
```

### RoadmapDB

RoadmapDB handles database operations for roadmap data


#### Methods

##### RoadmapDB.Close

Close closes the database connection


```go
func (rdb *RoadmapDB) Close() error
```

##### RoadmapDB.CreateItem

CreateItem inserts a new roadmap item into the database


```go
func (rdb *RoadmapDB) CreateItem(title, description, priority string, targetDate time.Time) (*types.RoadmapItem, error)
```

##### RoadmapDB.CreateMilestone

CreateMilestone inserts a new milestone into the database


```go
func (rdb *RoadmapDB) CreateMilestone(title, description string, targetDate time.Time) (*types.Milestone, error)
```

##### RoadmapDB.DeleteItem

DeleteItem removes a roadmap item from the database


```go
func (rdb *RoadmapDB) DeleteItem(id string) error
```

##### RoadmapDB.GetAllItems

GetAllItems retrieves all roadmap items from the database


```go
func (rdb *RoadmapDB) GetAllItems() ([]types.RoadmapItem, error)
```

##### RoadmapDB.GetAllMilestones

GetAllMilestones retrieves all milestones from the database


```go
func (rdb *RoadmapDB) GetAllMilestones() ([]types.Milestone, error)
```

##### RoadmapDB.GetItem

GetItem retrieves a single roadmap item by ID


```go
func (rdb *RoadmapDB) GetItem(id string) (*types.RoadmapItem, error)
```

##### RoadmapDB.UpdateItemStatus

UpdateItemStatus updates the status and progress of a roadmap item


```go
func (rdb *RoadmapDB) UpdateItemStatus(id, status string, progress int) error
```

### RoadmapData

RoadmapData represents the complete roadmap data structure


### StorageManager

StorageManager manages roadmap data persistence


#### Methods

##### StorageManager.CreateItem

CreateItem creates a new roadmap item


```go
func (sm *StorageManager) CreateItem(title, description, status, priority string) (*types.RoadmapItem, error)
```

##### StorageManager.DeleteItem

DeleteItem deletes a roadmap item


```go
func (sm *StorageManager) DeleteItem(id string) error
```

##### StorageManager.GetAllItems

GetAllItems returns all roadmap items


```go
func (sm *StorageManager) GetAllItems() ([]types.RoadmapItem, error)
```

##### StorageManager.GetStorageDir

GetStorageDir returns the storage directory path


```go
func (sm *StorageManager) GetStorageDir() string
```

##### StorageManager.LoadAdvancedRoadmap

LoadAdvancedRoadmap loads an advanced roadmap from storage


```go
func (sm *StorageManager) LoadAdvancedRoadmap() (*types.AdvancedRoadmap, error)
```

##### StorageManager.LoadRoadmap

LoadRoadmap loads a roadmap from storage


```go
func (sm *StorageManager) LoadRoadmap() (*types.Roadmap, error)
```

##### StorageManager.SaveAdvancedRoadmap

SaveAdvancedRoadmap saves an advanced roadmap to storage


```go
func (sm *StorageManager) SaveAdvancedRoadmap(roadmap *types.AdvancedRoadmap) error
```

##### StorageManager.SaveRoadmap

SaveRoadmap saves a roadmap to storage


```go
func (sm *StorageManager) SaveRoadmap(roadmap *types.Roadmap) error
```

##### StorageManager.UpdateItem

UpdateItem updates an existing roadmap item


```go
func (sm *StorageManager) UpdateItem(id string, updates map[string]interface{}) error
```

## Functions

### GetDefaultStoragePath

GetDefaultStoragePath returns the standardized storage path for roadmap data
This ensures both CLI and TUI use the same storage location


```go
func GetDefaultStoragePath() string
```

### GetStorageDir

GetStorageDir returns the directory portion of the storage path


```go
func GetStorageDir() string
```

