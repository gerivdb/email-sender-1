# Package panels

Package panels - Context preservation and session management

Package panels - Context-aware shortcuts and dynamic key binding system

Package panels - Floating panels management system

Package panels - Panel minimization system with quick restoration

Package panels - Mode-specific key binding adaptation system

Package panels provides multi-panel management functionality for the TUI


## Types

### AddItemMsg

### AddMilestoneMsg

### AddTagMsg

### BasicStructureRule

BasicStructureRule validates basic structure


#### Methods

##### BasicStructureRule.AutoRepair

```go
func (r *BasicStructureRule) AutoRepair() bool
```

##### BasicStructureRule.Description

```go
func (r *BasicStructureRule) Description() string
```

##### BasicStructureRule.Name

```go
func (r *BasicStructureRule) Name() string
```

##### BasicStructureRule.Severity

```go
func (r *BasicStructureRule) Severity() ValidationSeverity
```

##### BasicStructureRule.Validate

```go
func (r *BasicStructureRule) Validate(state *ContextState) *ValidationError
```

### CancelMsg

### ChangeCalendarViewMsg

### ChecksumValidationRule

ChecksumValidationRule validates checksums


#### Methods

##### ChecksumValidationRule.AutoRepair

```go
func (r *ChecksumValidationRule) AutoRepair() bool
```

##### ChecksumValidationRule.Description

```go
func (r *ChecksumValidationRule) Description() string
```

##### ChecksumValidationRule.Name

```go
func (r *ChecksumValidationRule) Name() string
```

##### ChecksumValidationRule.Severity

```go
func (r *ChecksumValidationRule) Severity() ValidationSeverity
```

##### ChecksumValidationRule.Validate

```go
func (r *ChecksumValidationRule) Validate(state *ContextState) *ValidationError
```

### CloseAllPanelsMsg

### ClosePanelMsg

### CompressionAlgorithm

CompressionAlgorithm represents different compression algorithms


### CompressionConfig

CompressionConfig represents compression configuration


### CompressionResult

CompressionResult represents the result of a compression operation


### CompressionStats

CompressionStats tracks compression statistics


### ContentSerializer

ContentSerializer interface for serializable content


### ContextManager

ContextManager manages state persistence and restoration


#### Methods

##### ContextManager.DeleteState

DeleteState deletes a saved state


```go
func (cm *ContextManager) DeleteState(timestamp time.Time) error
```

##### ContextManager.GetStateInfo

GetStateInfo returns information about a saved state


```go
func (cm *ContextManager) GetStateInfo(timestamp time.Time) (*ContextState, error)
```

##### ContextManager.ListSavedStates

ListSavedStates returns a list of available saved states


```go
func (cm *ContextManager) ListSavedStates() ([]time.Time, error)
```

##### ContextManager.LoadLatestState

LoadLatestState loads the most recent state


```go
func (cm *ContextManager) LoadLatestState() (*ContextState, error)
```

##### ContextManager.LoadStateByTime

LoadStateByTime loads state from a specific time


```go
func (cm *ContextManager) LoadStateByTime(timestamp time.Time) (*ContextState, error)
```

##### ContextManager.MarkDirty

MarkDirty marks the state as dirty (needs saving)


```go
func (cm *ContextManager) MarkDirty()
```

##### ContextManager.RestoreState

RestoreState restores the panel system from a saved state


```go
func (cm *ContextManager) RestoreState(state *ContextState, pm *PanelManager, fm *FloatingManager, minimizer *PanelMinimizer) error
```

##### ContextManager.SaveState

SaveState saves the complete panel system state


```go
func (cm *ContextManager) SaveState(pm *PanelManager, fm *FloatingManager, minimizer *PanelMinimizer) error
```

##### ContextManager.SetAutoSaveInterval

SetAutoSaveInterval sets the auto-save interval


```go
func (cm *ContextManager) SetAutoSaveInterval(interval time.Duration)
```

##### ContextManager.SetMaxSnapshots

SetMaxSnapshots sets the maximum number of snapshots to keep


```go
func (cm *ContextManager) SetMaxSnapshots(max int)
```

##### ContextManager.ShouldAutoSave

ShouldAutoSave returns true if auto-save should be triggered


```go
func (cm *ContextManager) ShouldAutoSave() bool
```

### ContextState

ContextState represents the complete state of the panel system


### ContextValidator

ContextValidator provides comprehensive state validation functionality


#### Methods

##### ContextValidator.AddRule

AddRule adds a custom validation rule


```go
func (cv *ContextValidator) AddRule(rule ValidationRule)
```

##### ContextValidator.ClearCache

ClearCache clears the validation cache


```go
func (cv *ContextValidator) ClearCache()
```

##### ContextValidator.GetRules

GetRules returns the list of registered rules


```go
func (cv *ContextValidator) GetRules() []ValidationRule
```

##### ContextValidator.RemoveRule

RemoveRule removes a validation rule by name


```go
func (cv *ContextValidator) RemoveRule(name string)
```

##### ContextValidator.SetRepairMode

SetRepairMode enables or disables automatic repair mode


```go
func (cv *ContextValidator) SetRepairMode(enabled bool)
```

##### ContextValidator.SetStrictMode

SetStrictMode enables or disables strict validation mode


```go
func (cv *ContextValidator) SetStrictMode(enabled bool)
```

##### ContextValidator.Verify

Verify performs comprehensive validation of a context state


```go
func (cv *ContextValidator) Verify(state *ContextState, options *ValidationOptions) (*ValidationResult, error)
```

##### ContextValidator.VerifyAndRepair

VerifyAndRepair performs validation and attempts to repair issues


```go
func (cv *ContextValidator) VerifyAndRepair(state *ContextState) (*ValidationResult, *ContextState, error)
```

##### ContextValidator.VerifyQuick

VerifyQuick performs a quick validation with basic rules only


```go
func (cv *ContextValidator) VerifyQuick(state *ContextState) (*ValidationResult, error)
```

### ContextualShortcut

ContextualShortcut represents a context-aware shortcut


### ContextualShortcutManager

ContextualShortcutManager manages dynamic shortcuts based on context


#### Methods

##### ContextualShortcutManager.GetAvailableShortcuts

GetAvailableShortcuts returns all available shortcuts for the current context as a map


```go
func (csm *ContextualShortcutManager) GetAvailableShortcuts(panelID PanelID) map[string]string
```

##### ContextualShortcutManager.GetDynamicKeyBindings

GetDynamicKeyBindings returns the current dynamic key bindings


```go
func (csm *ContextualShortcutManager) GetDynamicKeyBindings() map[string]key.Binding
```

##### ContextualShortcutManager.GetHelpText

GetHelpText returns help text for available shortcuts


```go
func (csm *ContextualShortcutManager) GetHelpText() []string
```

##### ContextualShortcutManager.HandleKey

HandleKey processes a key input through the contextual system


```go
func (csm *ContextualShortcutManager) HandleKey(keypress string, panelID PanelID) tea.Cmd
```

##### ContextualShortcutManager.HandleKeyPress

HandleKeyPress handles a key press and executes the appropriate action


```go
func (csm *ContextualShortcutManager) HandleKeyPress(key string) tea.Cmd
```

##### ContextualShortcutManager.RegisterShortcut

RegisterShortcut registers a new contextual shortcut


```go
func (csm *ContextualShortcutManager) RegisterShortcut(shortcut *ContextualShortcut)
```

##### ContextualShortcutManager.UpdateContext

UpdateContext updates the current context for dynamic shortcuts


```go
func (csm *ContextualShortcutManager) UpdateContext(context ShortcutContext)
```

### CreateCardMsg

Additional message types for mode-specific actions


### DataConsistencyRule

DataConsistencyRule validates data consistency


#### Methods

##### DataConsistencyRule.AutoRepair

```go
func (r *DataConsistencyRule) AutoRepair() bool
```

##### DataConsistencyRule.Description

```go
func (r *DataConsistencyRule) Description() string
```

##### DataConsistencyRule.Name

```go
func (r *DataConsistencyRule) Name() string
```

##### DataConsistencyRule.Severity

```go
func (r *DataConsistencyRule) Severity() ValidationSeverity
```

##### DataConsistencyRule.Validate

```go
func (r *DataConsistencyRule) Validate(state *ContextState) *ValidationError
```

### EditCardMsg

### EncryptionConfig

EncryptionConfig represents encryption configuration


### ExportFormat

ExportFormat represents different export formats


### ExportHandler

ExportHandler represents a handler for exporting states


### ExportOptions

ExportOptions represents options for state export


### ExportResult

ExportResult represents the result of an export operation


### FilterListMsg

### FindMsg

### FloatingManager

FloatingManager manages floating panels with z-order and focus


#### Methods

##### FloatingManager.BringToFront

BringToFront brings a floating panel to the front


```go
func (fm *FloatingManager) BringToFront(id PanelID) error
```

##### FloatingManager.CloseFloatingPanel

CloseFloatingPanel closes and removes a floating panel


```go
func (fm *FloatingManager) CloseFloatingPanel(id PanelID) error
```

##### FloatingManager.CreateFloatingPanel

CreateFloatingPanel creates a new floating panel from a regular panel


```go
func (fm *FloatingManager) CreateFloatingPanel(panel *Panel, modal bool) *FloatingPanel
```

##### FloatingManager.EndDrag

EndDrag ends dragging a floating panel


```go
func (fm *FloatingManager) EndDrag(id PanelID) error
```

##### FloatingManager.EndResize

EndResize ends resizing a floating panel


```go
func (fm *FloatingManager) EndResize(id PanelID) error
```

##### FloatingManager.GetFloatingPanel

GetFloatingPanel returns a floating panel by ID


```go
func (fm *FloatingManager) GetFloatingPanel(id PanelID) (*FloatingPanel, error)
```

##### FloatingManager.GetModalPanels

GetModalPanels returns all modal floating panels


```go
func (fm *FloatingManager) GetModalPanels() []*FloatingPanel
```

##### FloatingManager.GetTopPanel

GetTopPanel returns the topmost floating panel


```go
func (fm *FloatingManager) GetTopPanel() *FloatingPanel
```

##### FloatingManager.GetZOrderedPanels

GetZOrderedPanels returns panels sorted by z-order (back to front)


```go
func (fm *FloatingManager) GetZOrderedPanels() []*FloatingPanel
```

##### FloatingManager.HasModalPanels

HasModalPanels returns true if there are any modal panels


```go
func (fm *FloatingManager) HasModalPanels() bool
```

##### FloatingManager.SendToBack

SendToBack sends a floating panel to the back


```go
func (fm *FloatingManager) SendToBack(id PanelID) error
```

##### FloatingManager.StartDrag

StartDrag starts dragging a floating panel


```go
func (fm *FloatingManager) StartDrag(id PanelID, startPos Position) error
```

##### FloatingManager.StartResize

StartResize starts resizing a floating panel


```go
func (fm *FloatingManager) StartResize(id PanelID, startPos Position) error
```

##### FloatingManager.Update

Update handles updates for floating panels


```go
func (fm *FloatingManager) Update(msg tea.Msg) tea.Cmd
```

##### FloatingManager.UpdateDrag

UpdateDrag updates the position during drag


```go
func (fm *FloatingManager) UpdateDrag(id PanelID, currentPos Position) error
```

##### FloatingManager.UpdateResize

UpdateResize updates the size during resize


```go
func (fm *FloatingManager) UpdateResize(id PanelID, currentPos Position) error
```

##### FloatingManager.View

View renders all floating panels


```go
func (fm *FloatingManager) View(termWidth, termHeight int) string
```

### FloatingPanel

FloatingPanel represents a panel that can float above others


### FloatingPanelData

FloatingPanelData represents serializable floating panel data


### GoToDateMsg

### GoToTodayMsg

### ImportHandler

ImportHandler represents a handler for importing states


### ImportOptions

ImportOptions represents options for state import


### ImportResult

ImportResult represents the result of an import operation


### LayoutConfig

LayoutConfig represents the configuration for panel layout


### LayoutType

LayoutType represents different layout types


### LayoutValidationRule

LayoutValidationRule validates layout configuration


#### Methods

##### LayoutValidationRule.AutoRepair

```go
func (r *LayoutValidationRule) AutoRepair() bool
```

##### LayoutValidationRule.Description

```go
func (r *LayoutValidationRule) Description() string
```

##### LayoutValidationRule.Name

```go
func (r *LayoutValidationRule) Name() string
```

##### LayoutValidationRule.Severity

```go
func (r *LayoutValidationRule) Severity() ValidationSeverity
```

##### LayoutValidationRule.Validate

```go
func (r *LayoutValidationRule) Validate(state *ContextState) *ValidationError
```

### MergeMode

MergeMode represents different merge strategies


### MinimizedBar

MinimizedBar represents the minimized panels bar


### MinimizedState

MinimizedState represents the state of a minimized panel


### ModeKeyBinding

ModeKeyBinding represents a key binding for a specific mode


### ModeSpecificKeyManager

ModeSpecificKeyManager manages key bindings that adapt to different view modes


#### Methods

##### ModeSpecificKeyManager.DisableBinding

DisableBinding disables a specific key binding


```go
func (mskm *ModeSpecificKeyManager) DisableBinding(mode ViewMode, key string)
```

##### ModeSpecificKeyManager.EnableBinding

EnableBinding enables a specific key binding


```go
func (mskm *ModeSpecificKeyManager) EnableBinding(mode ViewMode, key string)
```

##### ModeSpecificKeyManager.GetActiveBindings

GetActiveBindings returns the currently active key bindings


```go
func (mskm *ModeSpecificKeyManager) GetActiveBindings() map[string]key.Binding
```

##### ModeSpecificKeyManager.GetCurrentMode

GetCurrentMode returns the current view mode


```go
func (mskm *ModeSpecificKeyManager) GetCurrentMode() ViewMode
```

##### ModeSpecificKeyManager.GetModeHelp

GetModeHelp returns help text for the current mode


```go
func (mskm *ModeSpecificKeyManager) GetModeHelp() []string
```

##### ModeSpecificKeyManager.HandleKeyPress

HandleKeyPress handles a key press with mode-specific logic


```go
func (mskm *ModeSpecificKeyManager) HandleKeyPress(keyStr string) tea.Cmd
```

##### ModeSpecificKeyManager.SetMode

SetMode changes the current view mode and rebuilds bindings


```go
func (mskm *ModeSpecificKeyManager) SetMode(mode ViewMode) error
```

##### ModeSpecificKeyManager.SwitchMode

SwitchMode switches to a new view mode and adapts key bindings


```go
func (mskm *ModeSpecificKeyManager) SwitchMode(newMode ViewMode)
```

### MoveCardDirectionMsg

### MoveCardMsg

### MoveQuadrantMsg

### NavigatePeriodMsg

### NewCardMsg

### NewEventMsg

### NewPanelMsg

### NextPanelMsg

### OptimizationResult

OptimizationResult represents the result of an optimization operation


### OptimizationStrategy

OptimizationStrategy represents different optimization strategies


### PanMsg

### Panel

Panel represents a single panel in the TUI


### PanelData

PanelData represents serializable panel data


### PanelID

PanelID represents a unique identifier for panels


### PanelIntegrityRule

PanelIntegrityRule validates panel integrity


#### Methods

##### PanelIntegrityRule.AutoRepair

```go
func (r *PanelIntegrityRule) AutoRepair() bool
```

##### PanelIntegrityRule.Description

```go
func (r *PanelIntegrityRule) Description() string
```

##### PanelIntegrityRule.Name

```go
func (r *PanelIntegrityRule) Name() string
```

##### PanelIntegrityRule.Severity

```go
func (r *PanelIntegrityRule) Severity() ValidationSeverity
```

##### PanelIntegrityRule.Validate

```go
func (r *PanelIntegrityRule) Validate(state *ContextState) *ValidationError
```

### PanelManager

PanelManager manages multiple panels with layouts


#### Methods

##### PanelManager.AddPanel

AddPanel adds a new panel to the manager


```go
func (pm *PanelManager) AddPanel(panel *Panel) error
```

##### PanelManager.GetActivePanel

GetActivePanel returns the currently active panel


```go
func (pm *PanelManager) GetActivePanel() *Panel
```

##### PanelManager.GetActivePanelID

GetActivePanelID returns the ID of the currently active panel


```go
func (pm *PanelManager) GetActivePanelID() PanelID
```

##### PanelManager.GetAvailableShortcuts

GetAvailableShortcuts returns all available shortcuts for the current context


```go
func (pm *PanelManager) GetAvailableShortcuts() map[string]string
```

##### PanelManager.GetContextualManager

GetContextualManager returns the contextual shortcut manager


```go
func (pm *PanelManager) GetContextualManager() *ContextualShortcutManager
```

##### PanelManager.GetLayout

GetLayout returns the current layout configuration


```go
func (pm *PanelManager) GetLayout() LayoutConfig
```

##### PanelManager.GetModeKeyManager

GetModeKeyManager returns the mode-specific key manager


```go
func (pm *PanelManager) GetModeKeyManager() *ModeSpecificKeyManager
```

##### PanelManager.GetPanel

GetPanel returns a panel by ID


```go
func (pm *PanelManager) GetPanel(id PanelID) *Panel
```

##### PanelManager.GetViewMode

GetViewMode returns the current view mode


```go
func (pm *PanelManager) GetViewMode() ViewMode
```

##### PanelManager.HandleContextualKey

HandleContextualKey processes a key input through the contextual system


```go
func (pm *PanelManager) HandleContextualKey(keypress string) tea.Cmd
```

##### PanelManager.Init

Init initializes the panel manager (required for tea.Model interface)


```go
func (pm *PanelManager) Init() tea.Cmd
```

##### PanelManager.MovePanel

MovePanel moves a panel to a new position


```go
func (pm *PanelManager) MovePanel(id PanelID, newPosition Position) error
```

##### PanelManager.ResizePanel

ResizePanel resizes a panel to new dimensions


```go
func (pm *PanelManager) ResizePanel(id PanelID, newSize Size) error
```

##### PanelManager.SetActivePanel

SetActivePanel sets the active panel


```go
func (pm *PanelManager) SetActivePanel(id PanelID) error
```

##### PanelManager.SetLayout

SetLayout updates the layout configuration


```go
func (pm *PanelManager) SetLayout(layout LayoutConfig)
```

##### PanelManager.SetViewMode

SetViewMode changes the current view mode and updates key bindings


```go
func (pm *PanelManager) SetViewMode(mode ViewMode) error
```

##### PanelManager.Update

Update implements tea.Model interface


```go
func (pm *PanelManager) Update(msg tea.Msg) (tea.Model, tea.Cmd)
```

##### PanelManager.UpdateShortcutContext

UpdateShortcutContext updates the current context for dynamic shortcuts


```go
func (pm *PanelManager) UpdateShortcutContext()
```

##### PanelManager.View

View renders the panel manager


```go
func (pm *PanelManager) View() string
```

### PanelMinimizer

PanelMinimizer manages panel minimization and restoration


#### Methods

##### PanelMinimizer.AutoMinimizeInactive

AutoMinimizeInactive automatically minimizes panels that haven't been active


```go
func (pm *PanelMinimizer) AutoMinimizeInactive(panels map[PanelID]*Panel, inactiveThreshold time.Duration) error
```

##### PanelMinimizer.ClearMinimizedState

ClearMinimizedState clears all minimized state (useful for cleanup)


```go
func (pm *PanelMinimizer) ClearMinimizedState()
```

##### PanelMinimizer.GetMinimizedBarHeight

GetMinimizedBarHeight returns the height of the minimized bar


```go
func (pm *PanelMinimizer) GetMinimizedBarHeight() int
```

##### PanelMinimizer.GetMinimizedCount

GetMinimizedCount returns the number of minimized panels


```go
func (pm *PanelMinimizer) GetMinimizedCount() int
```

##### PanelMinimizer.GetMinimizedInfo

GetMinimizedInfo returns information about a minimized panel


```go
func (pm *PanelMinimizer) GetMinimizedInfo(id PanelID) (*MinimizedState, error)
```

##### PanelMinimizer.GetMinimizedPanels

GetMinimizedPanels returns all minimized panels


```go
func (pm *PanelMinimizer) GetMinimizedPanels() map[PanelID]*MinimizedState
```

##### PanelMinimizer.GetQuickRestoreKeys

GetQuickRestoreKeys returns the hotkey mapping


```go
func (pm *PanelMinimizer) GetQuickRestoreKeys() map[string]PanelID
```

##### PanelMinimizer.IsMinimized

IsMinimized checks if a panel is minimized


```go
func (pm *PanelMinimizer) IsMinimized(id PanelID) bool
```

##### PanelMinimizer.MinimizeAll

MinimizeAll minimizes all visible panels


```go
func (pm *PanelMinimizer) MinimizeAll(panels map[PanelID]*Panel) error
```

##### PanelMinimizer.MinimizePanel

MinimizePanel minimizes a panel to the taskbar


```go
func (pm *PanelMinimizer) MinimizePanel(panel *Panel, reason string) error
```

##### PanelMinimizer.RenderMinimizedBar

RenderMinimizedBar renders the minimized panels bar


```go
func (pm *PanelMinimizer) RenderMinimizedBar(termWidth, termHeight int) string
```

##### PanelMinimizer.RestoreAll

RestoreAll restores all minimized panels


```go
func (pm *PanelMinimizer) RestoreAll() error
```

##### PanelMinimizer.RestoreByHotkey

RestoreByHotkey restores a panel using its hotkey


```go
func (pm *PanelMinimizer) RestoreByHotkey(hotkey string) error
```

##### PanelMinimizer.RestorePanel

RestorePanel restores a minimized panel


```go
func (pm *PanelMinimizer) RestorePanel(id PanelID) error
```

##### PanelMinimizer.SetAutoMinimize

SetAutoMinimize enables or disables automatic minimization


```go
func (pm *PanelMinimizer) SetAutoMinimize(enabled bool)
```

##### PanelMinimizer.SetMinimizedBarAutoHide

SetMinimizedBarAutoHide enables or disables auto-hide for the minimized bar


```go
func (pm *PanelMinimizer) SetMinimizedBarAutoHide(autoHide bool)
```

##### PanelMinimizer.SetMinimizedBarPosition

SetMinimizedBarPosition sets the position of the minimized bar


```go
func (pm *PanelMinimizer) SetMinimizedBarPosition(pos Position)
```

##### PanelMinimizer.TogglePanel

TogglePanel toggles a panel between minimized and restored states


```go
func (pm *PanelMinimizer) TogglePanel(panel *Panel) error
```

##### PanelMinimizer.Update

Update handles key events and updates for the minimizer


```go
func (pm *PanelMinimizer) Update(msg tea.Msg) tea.Cmd
```

### PanelResizer

PanelResizer handles panel resizing operations


#### Methods

##### PanelResizer.AdjustSize

AdjustSize adjusts the size of a panel


```go
func (pr *PanelResizer) AdjustSize(panelID PanelID, deltaWidth, deltaHeight int) error
```

##### PanelResizer.CanResize

CanResize checks if a panel can be resized


```go
func (pr *PanelResizer) CanResize(panelID PanelID) bool
```

##### PanelResizer.EndResize

EndResize ends a resize operation


```go
func (pr *PanelResizer) EndResize()
```

##### PanelResizer.GetResizeMode

GetResizeMode returns the current resize mode


```go
func (pr *PanelResizer) GetResizeMode() ResizeMode
```

##### PanelResizer.HandleKeyboardResize

HandleKeyboardResize handles keyboard-based resizing


```go
func (pr *PanelResizer) HandleKeyboardResize(msg tea.KeyMsg) error
```

##### PanelResizer.IsResizing

IsResizing returns whether a resize operation is in progress


```go
func (pr *PanelResizer) IsResizing() bool
```

##### PanelResizer.StartResize

StartResize begins a resize operation


```go
func (pr *PanelResizer) StartResize(panelID PanelID, mode ResizeMode, startPos Position) error
```

##### PanelResizer.UpdateResize

UpdateResize updates an ongoing resize operation


```go
func (pr *PanelResizer) UpdateResize(currentPos Position) error
```

### PanelSplitter

PanelSplitter handles panel splitting operations


#### Methods

##### PanelSplitter.Horizontal

Horizontal splits panels horizontally with given ratios


```go
func (ps *PanelSplitter) Horizontal(ratios ...float64) error
```

##### PanelSplitter.Vertical

Vertical splits panels vertically with given ratios


```go
func (ps *PanelSplitter) Vertical(ratios ...float64) error
```

### Position

Position represents the position of a panel


### PrevPanelMsg

### RecoveryOptions

RecoveryOptions represents options for session recovery


### RecoveryResult

RecoveryResult represents the result of a recovery attempt


### RecoveryStrategy

RecoveryStrategy represents different recovery strategies


### RedoMsg

### ReferenceIntegrityRule

ReferenceIntegrityRule validates reference integrity


#### Methods

##### ReferenceIntegrityRule.AutoRepair

```go
func (r *ReferenceIntegrityRule) AutoRepair() bool
```

##### ReferenceIntegrityRule.Description

```go
func (r *ReferenceIntegrityRule) Description() string
```

##### ReferenceIntegrityRule.Name

```go
func (r *ReferenceIntegrityRule) Name() string
```

##### ReferenceIntegrityRule.Severity

```go
func (r *ReferenceIntegrityRule) Severity() ValidationSeverity
```

##### ReferenceIntegrityRule.Validate

```go
func (r *ReferenceIntegrityRule) Validate(state *ContextState) *ValidationError
```

### RefreshMsg

### ReplaceMsg

### ResizeMode

ResizeMode represents different resize modes


### ResizePanelMsg

### SaveMsg

### SelectQuadrantMsg

### SessionRestore

SessionRestore provides session restoration functionality


#### Methods

##### SessionRestore.AutoRecover

AutoRecover continuously monitors and recovers from crashes


```go
func (sr *SessionRestore) AutoRecover(pm *PanelManager, options *RecoveryOptions)
```

##### SessionRestore.EnableAutoRecovery

EnableAutoRecovery enables or disables automatic recovery


```go
func (sr *SessionRestore) EnableAutoRecovery(enabled bool)
```

##### SessionRestore.GetLastRestoreTime

GetLastRestoreTime returns the time of the last successful restore


```go
func (sr *SessionRestore) GetLastRestoreTime() time.Time
```

##### SessionRestore.GetRecoveryAttempts

GetRecoveryAttempts returns the current number of recovery attempts


```go
func (sr *SessionRestore) GetRecoveryAttempts() int
```

##### SessionRestore.GetRecoveryChannel

GetRecoveryChannel returns the channel for recovery results


```go
func (sr *SessionRestore) GetRecoveryChannel() <-chan RecoveryResult
```

##### SessionRestore.LoadLast

LoadLast attempts to load the most recent session state


```go
func (sr *SessionRestore) LoadLast(options *RecoveryOptions) (*ContextState, error)
```

##### SessionRestore.LoadLastAsync

LoadLastAsync loads the last session asynchronously


```go
func (sr *SessionRestore) LoadLastAsync(options *RecoveryOptions) <-chan RecoveryResult
```

##### SessionRestore.ResetRecoveryAttempts

ResetRecoveryAttempts resets the recovery attempt counter


```go
func (sr *SessionRestore) ResetRecoveryAttempts()
```

##### SessionRestore.RestoreFromBackup

RestoreFromBackup restores from a specific backup timestamp


```go
func (sr *SessionRestore) RestoreFromBackup(timestamp time.Time, options *RecoveryOptions) (*ContextState, error)
```

##### SessionRestore.SetRestoreCallback

SetRestoreCallback sets a callback function to be called after successful restore


```go
func (sr *SessionRestore) SetRestoreCallback(callback func(*ContextState) error)
```

### SetDueDateMsg

### SetImportanceMsg

### SetPriorityMsg

### SetSwimlaneMsg

### SetUrgencyMsg

### SetWIPLimitMsg

### ShortcutContext

ShortcutContext represents the current context for shortcuts


### Size

Size represents the size of a panel


### SizeValidationRule

SizeValidationRule validates size values


#### Methods

##### SizeValidationRule.AutoRepair

```go
func (r *SizeValidationRule) AutoRepair() bool
```

##### SizeValidationRule.Description

```go
func (r *SizeValidationRule) Description() string
```

##### SizeValidationRule.Name

```go
func (r *SizeValidationRule) Name() string
```

##### SizeValidationRule.Severity

```go
func (r *SizeValidationRule) Severity() ValidationSeverity
```

##### SizeValidationRule.Validate

```go
func (r *SizeValidationRule) Validate(state *ContextState) *ValidationError
```

### SortListMsg

### SplitPanelMsg

### StateCompression

StateCompression provides state compression and optimization functionality


#### Methods

##### StateCompression.ClearCache

ClearCache clears the compression cache


```go
func (sc *StateCompression) ClearCache()
```

##### StateCompression.Compress

Compress compresses data using the configured algorithm


```go
func (sc *StateCompression) Compress(data []byte) (*CompressionResult, error)
```

##### StateCompression.CompressState

CompressState compresses an entire context state


```go
func (sc *StateCompression) CompressState(state *ContextState) (*CompressionResult, []byte, error)
```

##### StateCompression.Decompress

Decompress decompresses data using the specified algorithm


```go
func (sc *StateCompression) Decompress(data []byte, algorithm CompressionAlgorithm) ([]byte, error)
```

##### StateCompression.DecompressState

DecompressState decompresses and deserializes a context state


```go
func (sc *StateCompression) DecompressState(data []byte, algorithm CompressionAlgorithm) (*ContextState, error)
```

##### StateCompression.GetBestAlgorithm

GetBestAlgorithm returns the best compression algorithm for the given data


```go
func (sc *StateCompression) GetBestAlgorithm(data []byte) (CompressionAlgorithm, int, error)
```

##### StateCompression.GetStatistics

GetStatistics returns compression statistics


```go
func (sc *StateCompression) GetStatistics() *CompressionStats
```

##### StateCompression.Optimize

Optimize optimizes a context state for storage efficiency


```go
func (sc *StateCompression) Optimize(state *ContextState, strategy OptimizationStrategy) (*OptimizationResult, error)
```

##### StateCompression.SetAlgorithm

SetAlgorithm sets the compression algorithm


```go
func (sc *StateCompression) SetAlgorithm(algorithm CompressionAlgorithm)
```

##### StateCompression.SetLevel

SetLevel sets the compression level


```go
func (sc *StateCompression) SetLevel(level int)
```

##### StateCompression.SetThreshold

SetThreshold sets the compression threshold


```go
func (sc *StateCompression) SetThreshold(threshold int64)
```

### StateSerializer

StateSerializer provides state serialization and export functionality


#### Methods

##### StateSerializer.Export

Export exports the current state to a file


```go
func (ss *StateSerializer) Export(state *ContextState, filepath string, options *ExportOptions) (*ExportResult, error)
```

##### StateSerializer.ExportArchive

ExportArchive exports multiple states to a single archive file


```go
func (ss *StateSerializer) ExportArchive(states []*ContextState, archivePath string, options *ExportOptions) (*ExportResult, error)
```

##### StateSerializer.ExportMultiple

ExportMultiple exports multiple states to separate files


```go
func (ss *StateSerializer) ExportMultiple(states []*ContextState, baseDir string, options *ExportOptions) ([]*ExportResult, error)
```

##### StateSerializer.GetSupportedFormats

GetSupportedFormats returns the list of supported export/import formats


```go
func (ss *StateSerializer) GetSupportedFormats() []ExportFormat
```

##### StateSerializer.Import

Import imports a state from a file


```go
func (ss *StateSerializer) Import(filepath string, options *ImportOptions) (*ImportResult, error)
```

##### StateSerializer.ImportArchive

ImportArchive imports states from an archive file


```go
func (ss *StateSerializer) ImportArchive(archivePath string, options *ImportOptions) ([]*ImportResult, error)
```

##### StateSerializer.RegisterExportHandler

RegisterExportHandler registers a custom export handler


```go
func (ss *StateSerializer) RegisterExportHandler(format string, handler ExportHandler)
```

##### StateSerializer.RegisterImportHandler

RegisterImportHandler registers a custom import handler


```go
func (ss *StateSerializer) RegisterImportHandler(format string, handler ImportHandler)
```

##### StateSerializer.SetCompression

SetCompression configures compression settings


```go
func (ss *StateSerializer) SetCompression(config CompressionConfig)
```

##### StateSerializer.SetEncryption

SetEncryption configures encryption settings


```go
func (ss *StateSerializer) SetEncryption(config EncryptionConfig)
```

### SwitchPanelMsg

Message types for panel actions


### TimestampValidationRule

TimestampValidationRule validates timestamps


#### Methods

##### TimestampValidationRule.AutoRepair

```go
func (r *TimestampValidationRule) AutoRepair() bool
```

##### TimestampValidationRule.Description

```go
func (r *TimestampValidationRule) Description() string
```

##### TimestampValidationRule.Name

```go
func (r *TimestampValidationRule) Name() string
```

##### TimestampValidationRule.Severity

```go
func (r *TimestampValidationRule) Severity() ValidationSeverity
```

##### TimestampValidationRule.Validate

```go
func (r *TimestampValidationRule) Validate(state *ContextState) *ValidationError
```

### ToggleBlockedMsg

### ToggleCompleteMsg

### UndoMsg

### ValidationError

ValidationError represents a validation error


### ValidationOptions

ValidationOptions represents options for validation


### ValidationResult

ValidationResult represents the result of a validation operation


### ValidationRule

ValidationRule represents a validation rule


### ValidationSeverity

ValidationSeverity represents the severity of a validation error


### ViewMode

ViewMode represents different view modes


### ZoomMsg

## Variables

### ErrPanelNotFound, ErrMaxPanelsReached, ErrManagerNotInitialized, ErrInvalidLayout, ErrPanelExists, ErrMinSizeViolation, ErrInvalidOperation, ErrStateNotFound, ErrCorruptedState, ErrResizeNotAllowed, ErrSizeTooSmall

Panel management errors


```go
var (
	ErrPanelNotFound		= errors.New("panel not found")
	ErrMaxPanelsReached		= errors.New("maximum number of panels reached")
	ErrManagerNotInitialized	= errors.New("manager not initialized")
	ErrInvalidLayout		= errors.New("invalid layout configuration")
	ErrPanelExists			= errors.New("panel with this ID already exists")
	ErrMinSizeViolation		= errors.New("panel size below minimum allowed")
	ErrInvalidOperation		= errors.New("invalid operation for current panel state")
	ErrStateNotFound		= errors.New("state file not found")
	ErrCorruptedState		= errors.New("corrupted state file")
	ErrResizeNotAllowed		= errors.New("panel is not resizable")
	ErrSizeTooSmall			= errors.New("panel size is too small")
)
```

