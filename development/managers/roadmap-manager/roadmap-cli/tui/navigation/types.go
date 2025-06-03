package navigation

import (
	"time"

	tea "github.com/charmbracelet/bubbletea"
)

// NavigationMode represents different navigation modes
type NavigationMode int

const (
	NavigationModeNormal NavigationMode = iota
	NavigationModeVim
	NavigationModeAccessibility
	NavigationModeCustom
	// Enhanced modes for section 1.2.1.1.5
	NavigationModeKanban
	NavigationModeMatrix
	NavigationModeHierarchical
	NavigationModeSearch
	NavigationModeFocus
)

// String returns the string representation of the navigation mode
func (nm NavigationMode) String() string {
	switch nm {
	case NavigationModeNormal:
		return "normal"
	case NavigationModeVim:
		return "vim"
	case NavigationModeAccessibility:
		return "accessibility"
	case NavigationModeCustom:
		return "custom"
	case NavigationModeKanban:
		return "kanban"
	case NavigationModeMatrix:
		return "matrix"
	case NavigationModeHierarchical:
		return "hierarchical"
	case NavigationModeSearch:
		return "search"
	case NavigationModeFocus:
		return "focus"
	default:
		return "unknown"
	}
}

// ViewMode represents different view modes
type ViewMode int

const (
	ViewModeList ViewMode = iota
	ViewModeKanban
	ViewModeCalendar
	ViewModeMatrix
	ViewModeGantt
	ViewModeTimeline
	// Enhanced view modes for section 1.2.1.1.5
	ViewModeTree
	ViewModeGrid
	ViewModeCard
	ViewModeFocus
	ViewModeSearch
	ViewModeComparison
)

// String returns the string representation of the view mode
func (vm ViewMode) String() string {
	switch vm {
	case ViewModeList:
		return "list"
	case ViewModeKanban:
		return "kanban"
	case ViewModeCalendar:
		return "calendar"
	case ViewModeMatrix:
		return "matrix"
	case ViewModeGantt:
		return "gantt"
	case ViewModeTimeline:
		return "timeline"
	case ViewModeTree:
		return "tree"
	case ViewModeGrid:
		return "grid"
	case ViewModeCard:
		return "card"
	case ViewModeFocus:
		return "focus"
	case ViewModeSearch:
		return "search"
	case ViewModeComparison:
		return "comparison"
	default:
		return "unknown"
	}
}

// TransitionTrigger represents what triggered a transition
type TransitionTrigger int

const (
	TransitionTriggerUser TransitionTrigger = iota
	TransitionTriggerAutomatic
	TransitionTriggerKeyboard
	TransitionTriggerMouse
	TransitionTriggerContext
	TransitionTriggerSystem
)

// String returns the string representation of the transition trigger
func (tt TransitionTrigger) String() string {
	switch tt {
	case TransitionTriggerUser:
		return "user"
	case TransitionTriggerAutomatic:
		return "automatic"
	case TransitionTriggerKeyboard:
		return "keyboard"
	case TransitionTriggerMouse:
		return "mouse"
	case TransitionTriggerContext:
		return "context"
	case TransitionTriggerSystem:
		return "system"
	default:
		return "unknown"
	}
}

// TransitionOptions contient les options pour les transitions entre modes
type TransitionOptions struct {
	Duration     time.Duration
	Easing       string
	AnimationType string
	Trigger      TransitionTrigger
	Params       map[string]interface{}
}

// NavigationState represents the current navigation state
type NavigationState struct {
	CurrentMode         NavigationMode           `json:"current_mode"`
	CurrentView         ViewMode                 `json:"current_view"`
	FocusedElement      string                   `json:"focused_element"`
	Position            Position                 `json:"position"`
	History             []NavigationHistoryItem  `json:"history"`
	Bookmarks           []Bookmark               `json:"bookmarks"`
	Breadcrumbs         []string                 `json:"breadcrumbs"`
	TransitionState     TransitionState          `json:"transition_state"`
	AccessibilityMode   bool                     `json:"accessibility_mode"`
	KeyRepeatRate       time.Duration            `json:"key_repeat_rate"`
	ScrollSensitivity   float64                  `json:"scroll_sensitivity"`
	Preferences         NavigationPreferences    `json:"preferences"`
	LastUpdated         time.Time                `json:"last_updated"`
}

// Position represents a position in the UI
type Position struct {
	X           int `json:"x"`
	Y           int `json:"y"`
	Column      int `json:"column"`
	Row         int `json:"row"`
	Depth       int `json:"depth"`
	PanelID     string `json:"panel_id"`
	ElementID   string `json:"element_id"`
	ScrollX     int `json:"scroll_x"`
	ScrollY     int `json:"scroll_y"`
}

// NavigationHistoryItem represents an item in navigation history
type NavigationHistoryItem struct {
	ID          string    `json:"id"`
	ViewMode    ViewMode  `json:"view_mode"`
	Position    Position  `json:"position"`
	Description string    `json:"description"`
	Timestamp   time.Time `json:"timestamp"`
	Context     string    `json:"context"`
	Duration    time.Duration `json:"duration"`
}

// NavigationHistoryEntry représente une entrée dans l'historique de navigation
type NavigationHistoryEntry struct {
	Position Position
	View     ViewMode
	Time     time.Time
}

// Bookmark represents a navigation bookmark
type Bookmark struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	ViewMode    ViewMode  `json:"view_mode"`
	Position    Position  `json:"position"`
	Tags        []string  `json:"tags"`
	Hotkey      string    `json:"hotkey"`
	CreatedAt   time.Time `json:"created_at"`
	AccessCount int       `json:"access_count"`
	LastAccessed time.Time `json:"last_accessed"`
}

// TransitionState represents the state during view transitions
type TransitionState struct {
	IsTransitioning    bool          `json:"is_transitioning"`
	FromView          ViewMode      `json:"from_view"`
	ToView            ViewMode      `json:"to_view"`
	Progress          float64       `json:"progress"`
	StartTime         time.Time     `json:"start_time"`
	Duration          time.Duration `json:"duration"`
	AnimationType     string        `json:"animation_type"`
	PreservedState    interface{}   `json:"preserved_state"`
}

// NavigationPreferences contient les préférences de navigation
type NavigationPreferences struct {
	PreferredMode         NavigationMode    `json:"preferred_mode"`
	DefaultView           ViewMode          `json:"default_view"`
	AnimationsEnabled     bool              `json:"animations_enabled"`
	SmoothScrolling       bool              `json:"smooth_scrolling"`
	AutoSavePosition      bool              `json:"auto_save_position"`
	RestoreLastSession    bool              `json:"restore_last_session"`
	HighContrastMode      bool              `json:"high_contrast_mode"`
	ReducedMotion         bool              `json:"reduced_motion"`
	KeyboardNavOnly       bool              `json:"keyboard_nav_only"`
	VoiceNavigation       bool              `json:"voice_navigation"`
	HistoryLimit          int               `json:"history_limit"`
	BookmarkLimit         int               `json:"bookmark_limit"`
	TransitionDuration    time.Duration     `json:"transition_duration"`
	CustomKeybindings     map[string]string `json:"custom_keybindings"`
}

// NavigationEvent represents a navigation event
type NavigationEvent struct {
	Type        NavigationEventType `json:"type"`
	Source      string              `json:"source"`
	Target      string              `json:"target"`
	ViewMode    ViewMode            `json:"view_mode"`
	Position    Position            `json:"position"`
	Metadata    map[string]interface{} `json:"metadata"`
	Timestamp   time.Time           `json:"timestamp"`
	UserID      string              `json:"user_id"`
}

// NavigationEventType represents the type of navigation event
type NavigationEventType int

const (
	NavigationEventMove NavigationEventType = iota
	NavigationEventViewSwitch
	NavigationEventBookmark
	NavigationEventJump
	NavigationEventScroll
	NavigationEventFocus
	NavigationEventTransition
	NavigationEventHistory
)

// String returns the string representation of the navigation event type
func (net NavigationEventType) String() string {
	switch net {
	case NavigationEventMove:
		return "move"
	case NavigationEventViewSwitch:
		return "view_switch"
	case NavigationEventBookmark:
		return "bookmark"
	case NavigationEventJump:
		return "jump"
	case NavigationEventScroll:
		return "scroll"
	case NavigationEventFocus:
		return "focus"
	case NavigationEventTransition:
		return "transition"
	case NavigationEventHistory:
		return "history"
	default:
		return "unknown"
	}
}

// NavigationCommand represents a navigation command
type NavigationCommand struct {
	Action      string                 `json:"action"`
	Parameters  map[string]interface{} `json:"parameters"`
	Source      string                 `json:"source"`
	Priority    int                    `json:"priority"`
	Timestamp   time.Time              `json:"timestamp"`
}

// Bubble Tea Messages for navigation
type NavigationModeChangedMsg struct {
	OldMode NavigationMode
	NewMode NavigationMode
}

type ViewModeChangedMsg struct {
	OldView ViewMode
	NewView ViewMode
}

type PositionChangedMsg struct {
	OldPosition Position
	NewPosition Position
}

type BookmarkCreatedMsg struct {
	Bookmark Bookmark
}

type BookmarkAccessedMsg struct {
	BookmarkID string
	Position   Position
}

type TransitionStartedMsg struct {
	FromView ViewMode
	ToView   ViewMode
}

type TransitionCompletedMsg struct {
	FromView ViewMode
	ToView   ViewMode
	Duration time.Duration
}

type HistoryUpdatedMsg struct {
	Item NavigationHistoryItem
}

type NavigationErrorMsg struct {
	Error   error
	Context string
}

// NavigationDirection represents movement directions
type NavigationDirection int

const (
	DirectionUp NavigationDirection = iota
	DirectionDown
	DirectionLeft
	DirectionRight
	DirectionPageUp
	DirectionPageDown
	DirectionHome
	DirectionEnd
	DirectionTab
	DirectionShiftTab
)

// String returns the string representation of the navigation direction
func (nd NavigationDirection) String() string {
	switch nd {
	case DirectionUp:
		return "up"
	case DirectionDown:
		return "down"
	case DirectionLeft:
		return "left"
	case DirectionRight:
		return "right"
	case DirectionPageUp:
		return "page_up"
	case DirectionPageDown:
		return "page_down"
	case DirectionHome:
		return "home"
	case DirectionEnd:
		return "end"
	case DirectionTab:
		return "tab"
	case DirectionShiftTab:
		return "shift_tab"
	default:
		return "unknown"
	}
}

// KeyMappingRule represents a rule for key mapping
type KeyMappingRule struct {
	Key         string              `json:"key"`
	Action      string              `json:"action"`
	Context     string              `json:"context"`
	Condition   string              `json:"condition"`
	Priority    int                 `json:"priority"`
	Modifiers   []string            `json:"modifiers"`
	Repeatable  bool                `json:"repeatable"`
	Enabled     bool                `json:"enabled"`
}

// ViewTransition represents a view transition configuration
type ViewTransition struct {
	FromView       ViewMode      `json:"from_view"`
	ToView         ViewMode      `json:"to_view"`
	AnimationType  string        `json:"animation_type"`
	Duration       time.Duration `json:"duration"`
	Easing         string        `json:"easing"`
	PreserveState  bool          `json:"preserve_state"`
	BeforeHook     string        `json:"before_hook"`
	AfterHook      string        `json:"after_hook"`
}

// DefaultNavigationPreferences returns default navigation preferences
func DefaultNavigationPreferences() NavigationPreferences {
	return NavigationPreferences{
		PreferredMode:      NavigationModeNormal,
		DefaultView:        ViewModeList,
		AnimationsEnabled:  true,
		SmoothScrolling:    true,
		AutoSavePosition:   true,
		RestoreLastSession: true,
		HighContrastMode:   false,
		ReducedMotion:      false,
		KeyboardNavOnly:    false,
		VoiceNavigation:    false,
		HistoryLimit:       100,
		BookmarkLimit:      50,
		TransitionDuration: 300 * time.Millisecond,
		CustomKeybindings:  make(map[string]string),
	}
}

// NewNavigationState creates a new navigation state with defaults
func NewNavigationState() *NavigationState {
	return &NavigationState{
		CurrentMode:       NavigationModeNormal,
		CurrentView:       ViewModeList,
		FocusedElement:    "",
		Position:          Position{},
		History:           make([]NavigationHistoryItem, 0),
		Bookmarks:         make([]Bookmark, 0),
		Breadcrumbs:       make([]string, 0),
		TransitionState:   TransitionState{},
		AccessibilityMode: false,
		KeyRepeatRate:     500 * time.Millisecond,
		ScrollSensitivity: 1.0,
		Preferences:       DefaultNavigationPreferences(),
		LastUpdated:       time.Now(),
	}
}
