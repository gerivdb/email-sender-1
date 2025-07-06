# Package navigation

## Types

### AccessibilityInfo

AccessibilityInfo contains accessibility information


### AccessibilityRenderer

AccessibilityRenderer handles accessibility-specific rendering


### Animation

Animation represents an active animation


### AnimationManager

AnimationManager handles animations and transitions


### AnimationPreferences

AnimationPreferences contains animation preferences


### AnimationTickMsg

Bubble Tea Messages for rendering


### Bookmark

Bookmark represents a navigation bookmark


### BookmarkAccessedMsg

### BookmarkCreatedMsg

### CircuitBreaker

CircuitBreaker interface for local use


### ErrorEntry

ErrorEntry represents an error entry for cataloging (simplified local version)


### ErrorHooks

ErrorHooks defines callbacks for error handling in Mode Manager


### ErrorManager

ErrorManager encapsulates error management functionality for Mode Manager


#### Methods

##### ErrorManager.ProcessError

ProcessError handles and catalogs errors with ErrorManager integration


```go
func (em *ErrorManager) ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error
```

### FilterState

FilterState represents current filter state


### HeadingInfo

HeadingInfo represents heading information for accessibility


### HistoryUpdatedMsg

### KeyMappingRule

KeyMappingRule represents a rule for key mapping


### LayoutChangedMsg

### LayoutConfig

LayoutConfig represents layout configuration for a mode


### LayoutManager

LayoutManager handles layout adaptation for different modes


### LayoutState

LayoutState represents layout state


### ModeActivatedMsg

Bubble Tea Messages for mode management


### ModeConfig

ModeConfig represents configuration for a navigation mode


### ModeDeactivatedMsg

### ModeErrorMsg

### ModeEvent

ModeEvent represents an event in a navigation mode


### ModeEventHandler

ModeEventHandler handles events for a specific mode


### ModeEventType

ModeEventType represents the type of mode event


### ModeManager

ModeManager handles navigation mode switching and state preservation


#### Methods

##### ModeManager.AddEventHandler

AddEventHandler adds an event handler for a specific mode with ErrorManager integration


```go
func (mm *ModeManager) AddEventHandler(mode NavigationMode, handler ModeEventHandler) error
```

##### ModeManager.GetAvailableModes

GetAvailableModes returns all available modes


```go
func (mm *ModeManager) GetAvailableModes() []NavigationMode
```

##### ModeManager.GetCurrentMode

GetCurrentMode returns the current navigation mode


```go
func (mm *ModeManager) GetCurrentMode() NavigationMode
```

##### ModeManager.GetMetrics

GetMetrics returns current metrics for the mode manager


```go
func (mm *ModeManager) GetMetrics() *ModeMetrics
```

##### ModeManager.GetModeConfig

GetModeConfig returns the configuration for a specific mode


```go
func (mm *ModeManager) GetModeConfig(mode NavigationMode) (*ModeConfig, error)
```

##### ModeManager.GetModeState

GetModeState returns the current state for a mode with ErrorManager integration


```go
func (mm *ModeManager) GetModeState(mode NavigationMode) (*ModeState, error)
```

##### ModeManager.GetPreferences

GetPreferences returns current mode preferences


```go
func (mm *ModeManager) GetPreferences() *ModePreferences
```

##### ModeManager.GetTransitionHistory

GetTransitionHistory returns the transition history


```go
func (mm *ModeManager) GetTransitionHistory() []ModeTransition
```

##### ModeManager.ResetMetrics

ResetMetrics resets all metrics counters


```go
func (mm *ModeManager) ResetMetrics()
```

##### ModeManager.RestoreState

RestoreState restores a saved state for the current mode with ErrorManager integration


```go
func (mm *ModeManager) RestoreState(state *ModeState) tea.Cmd
```

##### ModeManager.SetPreferences

SetPreferences updates mode preferences


```go
func (mm *ModeManager) SetPreferences(prefs *ModePreferences)
```

##### ModeManager.SwitchMode

SwitchMode switches to a new navigation mode with ErrorManager integration


```go
func (mm *ModeManager) SwitchMode(targetMode NavigationMode) tea.Cmd
```

##### ModeManager.SwitchModeAdvanced

SwitchModeAdvanced provides enhanced mode switching with advanced state preservation and ErrorManager integration


```go
func (mm *ModeManager) SwitchModeAdvanced(targetMode NavigationMode, options *TransitionOptions) tea.Cmd
```

##### ModeManager.TriggerEvent

TriggerEvent triggers an event for the current mode with ErrorManager integration


```go
func (mm *ModeManager) TriggerEvent(eventType ModeEventType, data map[string]interface{}) []tea.Cmd
```

##### ModeManager.UpdateModeConfig

UpdateModeConfig updates the configuration for a specific mode


```go
func (mm *ModeManager) UpdateModeConfig(mode NavigationMode, config *ModeConfig) error
```

### ModeMemory

#### Methods

##### ModeMemory.RestoreState

RestoreState restores the state for a given mode


```go
func (mm *ModeMemory) RestoreState(mode NavigationMode) error
```

### ModeMetrics

ModeMetrics tracks metrics for mode switching and state management


### ModePreferences

ModePreferences represents user preferences for navigation modes


### ModeState

ModeState represents the preserved state for a navigation mode


### ModeStateUpdatedMsg

### ModeStyles

ModeStyles contains styles for a specific navigation mode


### ModeTransition

ModeTransition represents a mode transition


### ModeTransitionCompletedMsg

### ModeTransitionStartedMsg

### NavigationAnalytics

NavigationAnalytics tracks navigation usage patterns


### NavigationCommand

NavigationCommand represents a navigation command


### NavigationDirection

NavigationDirection represents movement directions


#### Methods

##### NavigationDirection.String

String returns the string representation of the navigation direction


```go
func (nd NavigationDirection) String() string
```

### NavigationErrorMsg

### NavigationEvent

NavigationEvent represents a navigation event


### NavigationEventType

NavigationEventType represents the type of navigation event


#### Methods

##### NavigationEventType.String

String returns the string representation of the navigation event type


```go
func (net NavigationEventType) String() string
```

### NavigationHistoryEntry

NavigationHistoryEntry représente une entrée dans l'historique de navigation


### NavigationHistoryItem

NavigationHistoryItem represents an item in navigation history


### NavigationManager

NavigationManager manages navigation state and operations


#### Methods

##### NavigationManager.AddEventListener

AddEventListener adds an event listener


```go
func (nm *NavigationManager) AddEventListener(listener func(NavigationEvent))
```

##### NavigationManager.CompleteTransition

CompleteTransition completes the current view transition


```go
func (nm *NavigationManager) CompleteTransition() tea.Cmd
```

##### NavigationManager.CreateBookmark

CreateBookmark creates a new bookmark at the current position


```go
func (nm *NavigationManager) CreateBookmark(name, description string, tags []string) tea.Cmd
```

##### NavigationManager.GetAnalytics

GetAnalytics returns navigation analytics


```go
func (nm *NavigationManager) GetAnalytics() NavigationAnalytics
```

##### NavigationManager.GetBookmarks

GetBookmarks returns all bookmarks sorted by access count


```go
func (nm *NavigationManager) GetBookmarks() []Bookmark
```

##### NavigationManager.GetHistory

GetHistory returns the navigation history


```go
func (nm *NavigationManager) GetHistory() []NavigationHistoryItem
```

##### NavigationManager.GetPreferences

GetPreferences returns current navigation preferences


```go
func (nm *NavigationManager) GetPreferences() NavigationPreferences
```

##### NavigationManager.GetState

GetState returns the current navigation state (thread-safe)


```go
func (nm *NavigationManager) GetState() NavigationState
```

##### NavigationManager.GoBack

GoBack navigates back in history


```go
func (nm *NavigationManager) GoBack() tea.Cmd
```

##### NavigationManager.Initialize

Initialize initializes the navigation manager


```go
func (nm *NavigationManager) Initialize() error
```

##### NavigationManager.JumpToBookmark

JumpToBookmark jumps to a specific bookmark


```go
func (nm *NavigationManager) JumpToBookmark(bookmarkID string) tea.Cmd
```

##### NavigationManager.Navigate

Navigate handles navigation in a specific direction


```go
func (nm *NavigationManager) Navigate(direction NavigationDirection) tea.Cmd
```

##### NavigationManager.SetNavigationMode

SetNavigationMode sets the navigation mode


```go
func (nm *NavigationManager) SetNavigationMode(mode NavigationMode) tea.Cmd
```

##### NavigationManager.SetPreferences

SetPreferences updates navigation preferences


```go
func (nm *NavigationManager) SetPreferences(prefs NavigationPreferences) error
```

##### NavigationManager.SetViewMode

SetViewMode sets the view mode with transition


```go
func (nm *NavigationManager) SetViewMode(viewMode ViewMode) tea.Cmd
```

##### NavigationManager.Shutdown

Shutdown gracefully shuts down the navigation manager


```go
func (nm *NavigationManager) Shutdown() error
```

### NavigationMode

NavigationMode represents different navigation modes


#### Methods

##### NavigationMode.String

String returns the string representation of the navigation mode


```go
func (nm NavigationMode) String() string
```

### NavigationModeChangedMsg

Bubble Tea Messages for navigation


### NavigationPreferences

NavigationPreferences contient les préférences de navigation


### NavigationState

NavigationState represents the current navigation state


### PanelState

PanelState represents the state of a UI panel


### Position

Position represents a position in the UI


### PositionChangedMsg

### RenderCompleteMsg

### RenderConfig

RenderConfig represents rendering configuration


### RenderPerformance

RenderPerformance contains performance metrics


### RenderResult

RenderResult represents the result of a render operation


### RenderStyles

RenderStyles contains styling for different modes and views


### ScrollPosition

ScrollPosition represents scroll position


### SelectionState

SelectionState represents current selection state


### SimpleCircuitBreaker

Simple circuit breaker implementation for local use


#### Methods

##### SimpleCircuitBreaker.Call

Call executes the function with circuit breaker protection


```go
func (cb *SimpleCircuitBreaker) Call(fn func() error) error
```

### TransitionCompletedMsg

### TransitionEffects

#### Methods

##### TransitionEffects.Configure

Configure sets up transition effects based on user preferences


```go
func (te *TransitionEffects) Configure(preferences map[string]interface{}) error
```

### TransitionOptions

TransitionOptions defines parameters for advanced mode switching.


### TransitionStartedMsg

### TransitionState

TransitionState represents the state during view transitions


### TransitionTrigger

TransitionTrigger represents what triggered a transition


#### Methods

##### TransitionTrigger.String

String returns the string representation of the transition trigger


```go
func (tt TransitionTrigger) String() string
```

### ViewMode

ViewMode represents different view modes


#### Methods

##### ViewMode.String

String returns the string representation of the view mode


```go
func (vm ViewMode) String() string
```

### ViewModeChangedMsg

### ViewRenderer

ViewRenderer handles rendering for different navigation modes and views


#### Methods

##### ViewRenderer.AdaptLayout

AdaptLayout adapts the layout for the current mode and view


```go
func (vr *ViewRenderer) AdaptLayout(config RenderConfig) (*RenderResult, error)
```

##### ViewRenderer.GetAccessibilityInfo

GetAccessibilityInfo returns accessibility information


```go
func (vr *ViewRenderer) GetAccessibilityInfo() AccessibilityInfo
```

##### ViewRenderer.RenderModeIndicator

RenderModeIndicator renders a mode indicator


```go
func (vr *ViewRenderer) RenderModeIndicator(mode NavigationMode) string
```

##### ViewRenderer.RenderTransition

RenderTransition renders a view transition


```go
func (vr *ViewRenderer) RenderTransition(transition ModeTransition) tea.Cmd
```

##### ViewRenderer.RenderViewHeader

RenderViewHeader renders a view header


```go
func (vr *ViewRenderer) RenderViewHeader(view ViewMode, title string) string
```

##### ViewRenderer.SetMode

SetMode sets the current rendering mode


```go
func (vr *ViewRenderer) SetMode(mode NavigationMode)
```

##### ViewRenderer.SetView

SetView sets the current view


```go
func (vr *ViewRenderer) SetView(view ViewMode)
```

##### ViewRenderer.UpdateAnimation

UpdateAnimation updates an active animation


```go
func (vr *ViewRenderer) UpdateAnimation(animationID string)
```

### ViewTransition

ViewTransition represents a view transition configuration


