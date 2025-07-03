# Package keybinds

Package keybinds - Key Configuration Manager

Package keybinds - Import/Export functionality for key binding configurations

Package keybinds provides configurable key binding management for TaskMaster CLI

Package keybinds - Key Validator for conflict detection and resolution


## Types

### ConfigEvent

ConfigEvent represents a key binding configuration change event


### ConflictType

ConflictType represents the type of a key binding conflict


### ExportFormat

ExportFormat represents different export formats


### ExportOptions

ExportOptions configures the export process


### ImportOptions

ImportOptions configures the import process


### KeyAction

KeyAction represents the different types of actions that can be bound to keys


### KeyBinding

KeyBinding represents a single key binding configuration


#### Methods

##### KeyBinding.String

String returns a string representation of the key binding


```go
func (kb KeyBinding) String() string
```

##### KeyBinding.Validate

ValidateKeyBinding validates a single key binding


```go
func (kb KeyBinding) Validate() error
```

### KeyConfigManager

KeyConfigManager manages key binding configurations


#### Methods

##### KeyConfigManager.CreateProfile

CreateProfile creates a new key binding profile


```go
func (kcm *KeyConfigManager) CreateProfile(name, description string) (*KeyProfile, error)
```

##### KeyConfigManager.DeleteProfile

DeleteProfile deletes a profile


```go
func (kcm *KeyConfigManager) DeleteProfile(profileID string) error
```

##### KeyConfigManager.GetAllKeyBindings

GetAllKeyBindings returns all key bindings from the current profile


```go
func (kcm *KeyConfigManager) GetAllKeyBindings() ([]KeyBinding, error)
```

##### KeyConfigManager.GetCurrentProfile

GetCurrentProfile returns the currently active profile


```go
func (kcm *KeyConfigManager) GetCurrentProfile() *KeyProfile
```

##### KeyConfigManager.GetEvents

GetEvents returns recent configuration events


```go
func (kcm *KeyConfigManager) GetEvents(limit int) []ConfigEvent
```

##### KeyConfigManager.GetKeyBinding

GetKeyBinding gets a specific key binding


```go
func (kcm *KeyConfigManager) GetKeyBinding(keyMapName, bindingID string) (*KeyBinding, error)
```

##### KeyConfigManager.GetKeyBindingsByContext

GetKeyBindingsByContext returns all key bindings for a specific context


```go
func (kcm *KeyConfigManager) GetKeyBindingsByContext(context string) ([]KeyBinding, error)
```

##### KeyConfigManager.Initialize

Initialize initializes the key configuration manager


```go
func (kcm *KeyConfigManager) Initialize() error
```

##### KeyConfigManager.ListProfiles

ListProfiles returns all available profiles


```go
func (kcm *KeyConfigManager) ListProfiles() []*KeyProfile
```

##### KeyConfigManager.LoadProfile

LoadProfile loads a key binding profile by ID


```go
func (kcm *KeyConfigManager) LoadProfile(profileID string) error
```

##### KeyConfigManager.UpdateKeyBinding

UpdateKeyBinding updates a specific key binding in the current profile


```go
func (kcm *KeyConfigManager) UpdateKeyBinding(keyMapName, bindingID string, updates map[string]interface{}) error
```

##### KeyConfigManager.UpdateProfile

UpdateProfile updates an existing profile


```go
func (kcm *KeyConfigManager) UpdateProfile(profileID string, updates map[string]interface{}) error
```

### KeyConflict

KeyConflict represents a key binding conflict with comprehensive information


### KeyContext

KeyContext represents the context where a key binding is applicable


### KeyExporter

KeyExporter handles exporting key binding configurations


#### Methods

##### KeyExporter.ExportProfile

ExportProfile exports a specific profile


```go
func (ke *KeyExporter) ExportProfile(profileID string, options ExportOptions) error
```

##### KeyExporter.ExportTemplate

ExportTemplate creates a template from a profile


```go
func (ke *KeyExporter) ExportTemplate(profileID string, templateInfo Template) error
```

##### KeyExporter.SaveConfig

SaveConfig exports the current profile configuration to a file


```go
func (ke *KeyExporter) SaveConfig(options ExportOptions) error
```

### KeyImporter

KeyImporter handles importing key binding configurations


#### Methods

##### KeyImporter.CreateDefaultTemplates

CreateDefaultTemplates creates default templates for common use cases


```go
func (ki *KeyImporter) CreateDefaultTemplates() error
```

##### KeyImporter.ImportProfile

ImportProfile imports a profile from a file


```go
func (ki *KeyImporter) ImportProfile(filePath string, options ImportOptions) (*KeyProfile, error)
```

##### KeyImporter.ImportTemplate

ImportTemplate imports a template and creates a new profile from it


```go
func (ki *KeyImporter) ImportTemplate(templateID string, profileName string) (*KeyProfile, error)
```

##### KeyImporter.LoadPresets

LoadPresets loads predefined key binding templates


```go
func (ki *KeyImporter) LoadPresets() ([]Template, error)
```

### KeyMap

KeyMap represents a collection of key bindings


#### Methods

##### KeyMap.AddBinding

AddBinding ajoute un nouveau binding au KeyMap


```go
func (km *KeyMap) AddBinding(binding KeyBinding) error
```

##### KeyMap.GetBinding

GetBinding retourne un binding par son ID


```go
func (km *KeyMap) GetBinding(id string) (*KeyBinding, error)
```

##### KeyMap.RemoveBinding

RemoveBinding supprime un binding par son ID


```go
func (km *KeyMap) RemoveBinding(id string) error
```

##### KeyMap.UpdateBinding

UpdateBinding met à jour un binding existant


```go
func (km *KeyMap) UpdateBinding(id string, updates map[string]interface{}) error
```

### KeyProfile

KeyProfile represents a user's complete key binding configuration


### KeyValidator

KeyValidator provides key binding validation and conflict detection


#### Methods

##### KeyValidator.CheckConflicts

CheckConflicts checks for key binding conflicts


```go
func (kv *KeyValidator) CheckConflicts(profile *KeyProfile) []KeyConflict
```

##### KeyValidator.ResolveConflict

ResolveConflict attempts to resolve a key binding conflict


```go
func (kv *KeyValidator) ResolveConflict(conflict KeyConflict, resolution string) error
```

##### KeyValidator.ValidateKeyBinding

ValidateKeyBinding validates a single key binding


```go
func (kv *KeyValidator) ValidateKeyBinding(binding KeyBinding, profile *KeyProfile) ValidationResult
```

##### KeyValidator.ValidateProfile

ValidateProfile validates an entire key profile for conflicts and issues


```go
func (kv *KeyValidator) ValidateProfile(profile *KeyProfile) ValidationResult
```

### ProfileMetadata

ProfileMetadata contains additional profile information


### Template

Template represents a predefined key binding template


### ValidationResult

ValidationResult represents the result of key binding validation


## Functions

### GetActionDescription

GetActionDescription returns a human-readable description for a key action


```go
func GetActionDescription(action KeyAction) string
```

## Constants

### ConflictTypeExact, ConflictTypePartial, ConflictTypeContext, ConflictTypeSequence, DuplicateKey, ContextOverlap, ModifierConflict, ActionConflict

```go
const (
	ConflictTypeExact	ConflictType	= iota
	ConflictTypePartial
	ConflictTypeContext
	ConflictTypeSequence
	// Legacy compatibility constants
	DuplicateKey		= ConflictTypeExact
	ContextOverlap		= ConflictTypeContext
	ModifierConflict	= ConflictTypePartial
	ActionConflict		= ConflictTypeSequence
)
```

