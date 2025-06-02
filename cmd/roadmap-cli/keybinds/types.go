// Package keybinds provides configurable key binding management for TaskMaster CLI
package keybinds

import (
	"fmt"
	"time"
)

// KeyBinding represents a single key binding configuration
type KeyBinding struct {
	ID          string `json:"id"`
	Key         string `json:"key"`
	Action      string `json:"action"`
	Context     string `json:"context"`
	Description string `json:"description"`
	Enabled     bool   `json:"enabled"`
}

// KeyMap represents a collection of key bindings
type KeyMap struct {
	Name        string       `json:"name"`
	Version     string       `json:"version"`
	Description string       `json:"description"`
	Bindings    []KeyBinding `json:"bindings"`
	CreatedAt   time.Time    `json:"created_at"`
	UpdatedAt   time.Time    `json:"updated_at"`
}

// KeyProfile represents a user's complete key binding configuration
type KeyProfile struct {
	ID          string            `json:"id"`
	Name        string            `json:"name"`
	Description string            `json:"description"`
	UserID      string            `json:"user_id"`
	IsDefault   bool              `json:"is_default"`
	KeyMaps     map[string]KeyMap `json:"keymaps"`
	Metadata    ProfileMetadata   `json:"metadata"`
	CreatedAt   time.Time         `json:"created_at"`
	UpdatedAt   time.Time         `json:"updated_at"`
}

// ProfileMetadata contains additional profile information
type ProfileMetadata struct {
	Version     string            `json:"version"`
	Author      string            `json:"author"`
	Tags        []string          `json:"tags"`
	Preferences map[string]string `json:"preferences"`
}

// KeyAction represents the different types of actions that can be bound to keys
type KeyAction string

const (
	// Navigation actions
	ActionNavigateUp     KeyAction = "navigate_up"
	ActionNavigateDown   KeyAction = "navigate_down"
	ActionNavigateLeft   KeyAction = "navigate_left"
	ActionNavigateRight  KeyAction = "navigate_right"
	ActionNavigateHome   KeyAction = "navigate_home"
	ActionNavigateEnd    KeyAction = "navigate_end"
	
	// Panel actions
	ActionSwitchPanel    KeyAction = "switch_panel"
	ActionClosePanel     KeyAction = "close_panel"
	ActionMinimizePanel  KeyAction = "minimize_panel"
	ActionMaximizePanel  KeyAction = "maximize_panel"
	ActionSplitHorizontal KeyAction = "split_horizontal"
	ActionSplitVertical   KeyAction = "split_vertical"
	
	// View mode actions
	ActionSwitchToKanban   KeyAction = "switch_to_kanban"
	ActionSwitchToList     KeyAction = "switch_to_list"
	ActionSwitchToCalendar KeyAction = "switch_to_calendar"
	ActionSwitchToMatrix   KeyAction = "switch_to_matrix"
	ActionSwitchToTimeline KeyAction = "switch_to_timeline"
	
	// Task actions
	ActionCreateTask     KeyAction = "create_task"
	ActionEditTask       KeyAction = "edit_task"
	ActionDeleteTask     KeyAction = "delete_task"
	ActionCompleteTask   KeyAction = "complete_task"
	ActionAssignTask     KeyAction = "assign_task"
	
	// Application actions
	ActionSave          KeyAction = "save"
	ActionUndo          KeyAction = "undo"
	ActionRedo          KeyAction = "redo"
	ActionSearch        KeyAction = "search"
	ActionHelp          KeyAction = "help"
	ActionQuit          KeyAction = "quit"
)

// KeyContext represents the context where a key binding is applicable
type KeyContext string

const (
	ContextGlobal     KeyContext = "global"
	ContextNavigation KeyContext = "navigation"
	ContextPanels     KeyContext = "panels"
	ContextKanban     KeyContext = "kanban"
	ContextList       KeyContext = "list"
	ContextCalendar   KeyContext = "calendar"
	ContextMatrix     KeyContext = "matrix"
	ContextTimeline   KeyContext = "timeline"
	ContextTask       KeyContext = "task"
	ContextDialog     KeyContext = "dialog"
	ContextEdit       KeyContext = "edit"
)

// KeyConflict represents a key binding conflict
type KeyConflict struct {
	Key         string     `json:"key"`
	Context     string     `json:"context"`
	Binding1    KeyBinding `json:"binding1"`
	Binding2    KeyBinding `json:"binding2"`
	Severity    string     `json:"severity"` // "error", "warning", "info"
	Resolution  string     `json:"resolution"`
	ResolvedAt  *time.Time `json:"resolved_at,omitempty"`
}

// ValidationResult represents the result of key binding validation
type ValidationResult struct {
	IsValid     bool          `json:"is_valid"`
	Conflicts   []KeyConflict `json:"conflicts"`
	Warnings    []string      `json:"warnings"`
	Suggestions []string      `json:"suggestions"`
	ValidatedAt time.Time     `json:"validated_at"`
}

// ConfigEvent represents a key binding configuration change event
type ConfigEvent struct {
	Type        string    `json:"type"`
	ProfileID   string    `json:"profile_id"`
	KeyMapName  string    `json:"keymap_name"`
	BindingID   string    `json:"binding_id"`
	OldValue    string    `json:"old_value,omitempty"`
	NewValue    string    `json:"new_value,omitempty"`
	Timestamp   time.Time `json:"timestamp"`
	UserID      string    `json:"user_id,omitempty"`
	Description string    `json:"description,omitempty"`
}

// DefaultKeyMap returns the default key bindings for TaskMaster CLI
func DefaultKeyMap() KeyMap {
	return KeyMap{
		Name:        "default",
		Version:     "1.0.0",
		Description: "Default key bindings for TaskMaster CLI",
		Bindings: []KeyBinding{
			// Navigation
			{ID: "nav_up", Key: "k", Action: string(ActionNavigateUp), Context: string(ContextGlobal), Description: "Navigate up", Enabled: true},
			{ID: "nav_down", Key: "j", Action: string(ActionNavigateDown), Context: string(ContextGlobal), Description: "Navigate down", Enabled: true},
			{ID: "nav_left", Key: "h", Action: string(ActionNavigateLeft), Context: string(ContextGlobal), Description: "Navigate left", Enabled: true},
			{ID: "nav_right", Key: "l", Action: string(ActionNavigateRight), Context: string(ContextGlobal), Description: "Navigate right", Enabled: true},
			
			// Panels
			{ID: "panel_1", Key: "ctrl+1", Action: string(ActionSwitchPanel), Context: string(ContextPanels), Description: "Switch to panel 1", Enabled: true},
			{ID: "panel_2", Key: "ctrl+2", Action: string(ActionSwitchPanel), Context: string(ContextPanels), Description: "Switch to panel 2", Enabled: true},
			{ID: "panel_3", Key: "ctrl+3", Action: string(ActionSwitchPanel), Context: string(ContextPanels), Description: "Switch to panel 3", Enabled: true},
			{ID: "panel_4", Key: "ctrl+4", Action: string(ActionSwitchPanel), Context: string(ContextPanels), Description: "Switch to panel 4", Enabled: true},
			
			// View modes
			{ID: "view_kanban", Key: "1", Action: string(ActionSwitchToKanban), Context: string(ContextGlobal), Description: "Switch to Kanban view", Enabled: true},
			{ID: "view_list", Key: "2", Action: string(ActionSwitchToList), Context: string(ContextGlobal), Description: "Switch to List view", Enabled: true},
			{ID: "view_calendar", Key: "3", Action: string(ActionSwitchToCalendar), Context: string(ContextGlobal), Description: "Switch to Calendar view", Enabled: true},
			
			// Application
			{ID: "save", Key: "ctrl+s", Action: string(ActionSave), Context: string(ContextGlobal), Description: "Save", Enabled: true},
			{ID: "undo", Key: "ctrl+z", Action: string(ActionUndo), Context: string(ContextGlobal), Description: "Undo", Enabled: true},
			{ID: "redo", Key: "ctrl+y", Action: string(ActionRedo), Context: string(ContextGlobal), Description: "Redo", Enabled: true},
			{ID: "search", Key: "ctrl+f", Action: string(ActionSearch), Context: string(ContextGlobal), Description: "Search", Enabled: true},
			{ID: "help", Key: "F1", Action: string(ActionHelp), Context: string(ContextGlobal), Description: "Help", Enabled: true},
			{ID: "quit", Key: "ctrl+q", Action: string(ActionQuit), Context: string(ContextGlobal), Description: "Quit", Enabled: true},
		},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
}

// GetActionDescription returns a human-readable description for a key action
func GetActionDescription(action KeyAction) string {
	descriptions := map[KeyAction]string{
		ActionNavigateUp:     "Navigate to the previous item",
		ActionNavigateDown:   "Navigate to the next item",
		ActionNavigateLeft:   "Navigate to the left",
		ActionNavigateRight:  "Navigate to the right",
		ActionNavigateHome:   "Navigate to the beginning",
		ActionNavigateEnd:    "Navigate to the end",
		
		ActionSwitchPanel:     "Switch to a specific panel",
		ActionClosePanel:      "Close the current panel",
		ActionMinimizePanel:   "Minimize the current panel",
		ActionMaximizePanel:   "Maximize the current panel",
		ActionSplitHorizontal: "Split panel horizontally",
		ActionSplitVertical:   "Split panel vertically",
		
		ActionSwitchToKanban:   "Switch to Kanban view mode",
		ActionSwitchToList:     "Switch to List view mode",
		ActionSwitchToCalendar: "Switch to Calendar view mode",
		ActionSwitchToMatrix:   "Switch to Matrix view mode",
		ActionSwitchToTimeline: "Switch to Timeline view mode",
		
		ActionCreateTask:   "Create a new task",
		ActionEditTask:     "Edit the selected task",
		ActionDeleteTask:   "Delete the selected task",
		ActionCompleteTask: "Mark task as complete",
		ActionAssignTask:   "Assign task to user",
		
		ActionSave:   "Save current changes",
		ActionUndo:   "Undo last action",
		ActionRedo:   "Redo last undone action",
		ActionSearch: "Open search dialog",
		ActionHelp:   "Show help information",
		ActionQuit:   "Quit the application",
	}
	
	if desc, exists := descriptions[action]; exists {
		return desc
	}
	return fmt.Sprintf("Execute action: %s", string(action))
}

// ValidateKeyBinding validates a single key binding
func (kb KeyBinding) Validate() error {
	if kb.ID == "" {
		return fmt.Errorf("key binding ID cannot be empty")
	}
	if kb.Key == "" {
		return fmt.Errorf("key binding key cannot be empty")
	}
	if kb.Action == "" {
		return fmt.Errorf("key binding action cannot be empty")
	}
	if kb.Context == "" {
		return fmt.Errorf("key binding context cannot be empty")
	}
	return nil
}

// String returns a string representation of the key binding
func (kb KeyBinding) String() string {
	status := "enabled"
	if !kb.Enabled {
		status = "disabled"
	}
	return fmt.Sprintf("%s: %s -> %s (%s) [%s]", kb.ID, kb.Key, kb.Action, kb.Context, status)
}
