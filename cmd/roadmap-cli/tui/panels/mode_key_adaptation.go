// Package panels - Mode-specific key binding adaptation system
package panels

import (
	"fmt"
	"time"

	"github.com/charmbracelet/bubbles/key"
	tea "github.com/charmbracelet/bubbletea"
)

// ViewMode represents different view modes
type ViewMode string

const (
	ViewModeKanban    ViewMode = "kanban"
	ViewModeList      ViewMode = "list"
	ViewModeCalendar  ViewMode = "calendar"
	ViewModeMatrix    ViewMode = "matrix"
	ViewModeTimeline  ViewMode = "timeline"
	ViewModeHierarchy ViewMode = "hierarchy"
	ViewModeDashboard ViewMode = "dashboard"
)

// ModeKeyBinding represents a key binding for a specific mode
type ModeKeyBinding struct {
	Mode        ViewMode
	Key         string
	Description string
	Action      string
	Handler     func() tea.Cmd
	Enabled     bool
	Priority    int
}

// ModeSpecificKeyManager manages key bindings that adapt to different view modes
type ModeSpecificKeyManager struct {
	currentMode    ViewMode
	modeBindings   map[ViewMode]map[string]*ModeKeyBinding
	globalBindings map[string]*ModeKeyBinding
	activeBindings map[string]key.Binding
	panelManager   *PanelManager
	contextManager *ContextualShortcutManager
	lastModeChange time.Time
	transitionTime time.Duration
}

// NewModeSpecificKeyManager creates a new mode-specific key manager
func NewModeSpecificKeyManager(pm *PanelManager, csm *ContextualShortcutManager) *ModeSpecificKeyManager {
	mskm := &ModeSpecificKeyManager{
		modeBindings:   make(map[ViewMode]map[string]*ModeKeyBinding),
		globalBindings: make(map[string]*ModeKeyBinding),
		activeBindings: make(map[string]key.Binding),
		panelManager:   pm,
		contextManager: csm,
		transitionTime: time.Millisecond * 300,
	}

	// Initialize mode-specific bindings
	mskm.initializeModeBindings()
	return mskm
}

// initializeModeBindings initializes the default mode-specific key bindings
func (mskm *ModeSpecificKeyManager) initializeModeBindings() {
	// Kanban mode bindings
	mskm.registerModeBindings(ViewModeKanban, []*ModeKeyBinding{
		{
			Key:         "c",
			Description: "Create new card",
			Action:      "create_card",
			Handler:     mskm.createCardHandler,
			Priority:    100,
		},
		{
			Key:         "shift+left",
			Description: "Move card left",
			Action:      "move_card_left",
			Handler:     mskm.moveCardLeftHandler,
			Priority:    90,
		},
		{
			Key:         "shift+right",
			Description: "Move card right",
			Action:      "move_card_right",
			Handler:     mskm.moveCardRightHandler,
			Priority:    90,
		},
		{
			Key:         "shift+up",
			Description: "Move card up",
			Action:      "move_card_up",
			Handler:     mskm.moveCardUpHandler,
			Priority:    90,
		},
		{
			Key:         "shift+down",
			Description: "Move card down",
			Action:      "move_card_down",
			Handler:     mskm.moveCardDownHandler,
			Priority:    90,
		},
		{
			Key:         "s",
			Description: "Set swim lane",
			Action:      "set_swimlane",
			Handler:     mskm.setSwimlaneHandler,
			Priority:    80,
		},
		{
			Key:         "l",
			Description: "Set WIP limit",
			Action:      "set_wip_limit",
			Handler:     mskm.setWIPLimitHandler,
			Priority:    70,
		},
		{
			Key:         "b",
			Description: "Toggle blocked",
			Action:      "toggle_blocked",
			Handler:     mskm.toggleBlockedHandler,
			Priority:    80,
		},
	})

	// List mode bindings
	mskm.registerModeBindings(ViewModeList, []*ModeKeyBinding{
		{
			Key:         "a",
			Description: "Add new item",
			Action:      "add_item",
			Handler:     mskm.addItemHandler,
			Priority:    100,
		},
		{
			Key:         "space",
			Description: "Toggle completion",
			Action:      "toggle_complete",
			Handler:     mskm.toggleCompleteHandler,
			Priority:    100,
		},
		{
			Key:         "p",
			Description: "Set priority",
			Action:      "set_priority",
			Handler:     mskm.setPriorityHandler,
			Priority:    90,
		},
		{
			Key:         "d",
			Description: "Set due date",
			Action:      "set_due_date",
			Handler:     mskm.setDueDateHandler,
			Priority:    80,
		},
		{
			Key:         "t",
			Description: "Add tag",
			Action:      "add_tag",
			Handler:     mskm.addTagHandler,
			Priority:    70,
		},
		{
			Key:         "s",
			Description: "Sort list",
			Action:      "sort_list",
			Handler:     mskm.sortListHandler,
			Priority:    60,
		},
		{
			Key:         "f",
			Description: "Filter list",
			Action:      "filter_list",
			Handler:     mskm.filterListHandler,
			Priority:    60,
		},
	})

	// Calendar mode bindings
	mskm.registerModeBindings(ViewModeCalendar, []*ModeKeyBinding{
		{
			Key:         "n",
			Description: "New event",
			Action:      "new_event",
			Handler:     mskm.newEventHandler,
			Priority:    100,
		},
		{
			Key:         "w",
			Description: "Week view",
			Action:      "week_view",
			Handler:     mskm.weekViewHandler,
			Priority:    90,
		},
		{
			Key:         "m",
			Description: "Month view",
			Action:      "month_view",
			Handler:     mskm.monthViewHandler,
			Priority:    90,
		},
		{
			Key:         "y",
			Description: "Year view",
			Action:      "year_view",
			Handler:     mskm.yearViewHandler,
			Priority:    90,
		},
		{
			Key:         "shift+left",
			Description: "Previous period",
			Action:      "prev_period",
			Handler:     mskm.prevPeriodHandler,
			Priority:    80,
		},
		{
			Key:         "shift+right",
			Description: "Next period",
			Action:      "next_period",
			Handler:     mskm.nextPeriodHandler,
			Priority:    80,
		},
		{
			Key:         "t",
			Description: "Go to today",
			Action:      "go_today",
			Handler:     mskm.goTodayHandler,
			Priority:    70,
		},
	})

	// Matrix mode bindings
	mskm.registerModeBindings(ViewModeMatrix, []*ModeKeyBinding{
		{
			Key:         "q",
			Description: "Quadrant 1 (Urgent/Important)",
			Action:      "select_q1",
			Handler:     mskm.selectQuadrant1Handler,
			Priority:    100,
		},
		{
			Key:         "w",
			Description: "Quadrant 2 (Not Urgent/Important)",
			Action:      "select_q2",
			Handler:     mskm.selectQuadrant2Handler,
			Priority:    100,
		},
		{
			Key:         "e",
			Description: "Quadrant 3 (Urgent/Not Important)",
			Action:      "select_q3",
			Handler:     mskm.selectQuadrant3Handler,
			Priority:    100,
		},
		{
			Key:         "r",
			Description: "Quadrant 4 (Not Urgent/Not Important)",
			Action:      "select_q4",
			Handler:     mskm.selectQuadrant4Handler,
			Priority:    100,
		},
		{
			Key:         "shift+m",
			Description: "Move between quadrants",
			Action:      "move_quadrant",
			Handler:     mskm.moveQuadrantHandler,
			Priority:    90,
		},
		{
			Key:         "u",
			Description: "Set urgency",
			Action:      "set_urgency",
			Handler:     mskm.setUrgencyHandler,
			Priority:    80,
		},
		{
			Key:         "i",
			Description: "Set importance",
			Action:      "set_importance",
			Handler:     mskm.setImportanceHandler,
			Priority:    80,
		},
	})

	// Timeline mode bindings
	mskm.registerModeBindings(ViewModeTimeline, []*ModeKeyBinding{
		{
			Key:         "z",
			Description: "Zoom in",
			Action:      "zoom_in",
			Handler:     mskm.zoomInHandler,
			Priority:    90,
		},
		{
			Key:         "shift+z",
			Description: "Zoom out",
			Action:      "zoom_out",
			Handler:     mskm.zoomOutHandler,
			Priority:    90,
		},
		{
			Key:         "ctrl+left",
			Description: "Pan left",
			Action:      "pan_left",
			Handler:     mskm.panLeftHandler,
			Priority:    80,
		},
		{
			Key:         "ctrl+right",
			Description: "Pan right",
			Action:      "pan_right",
			Handler:     mskm.panRightHandler,
			Priority:    80,
		},
		{
			Key:         "g",
			Description: "Go to date",
			Action:      "go_to_date",
			Handler:     mskm.goToDateHandler,
			Priority:    70,
		},
		{
			Key:         "m",
			Description: "Add milestone",
			Action:      "add_milestone",
			Handler:     mskm.addMilestoneHandler,
			Priority:    80,
		},
	})

	// Global bindings (available in all modes)
	mskm.registerGlobalBindings([]*ModeKeyBinding{
		{
			Key:         "ctrl+r",
			Description: "Refresh view",
			Action:      "refresh",
			Handler:     mskm.refreshHandler,
			Priority:    50,
		},
		{
			Key:         "ctrl+s",
			Description: "Save",
			Action:      "save",
			Handler:     mskm.saveHandler,
			Priority:    100,
		},
		{
			Key:         "ctrl+z",
			Description: "Undo",
			Action:      "undo",
			Handler:     mskm.undoHandler,
			Priority:    90,
		},
		{
			Key:         "ctrl+y",
			Description: "Redo",
			Action:      "redo",
			Handler:     mskm.redoHandler,
			Priority:    90,
		},
		{
			Key:         "ctrl+f",
			Description: "Find",
			Action:      "find",
			Handler:     mskm.findHandler,
			Priority:    80,
		},
		{
			Key:         "ctrl+h",
			Description: "Replace",
			Action:      "replace",
			Handler:     mskm.replaceHandler,
			Priority:    70,
		},
		{
			Key:         "escape",
			Description: "Cancel/Exit mode",
			Action:      "cancel",
			Handler:     mskm.cancelHandler,
			Priority:    100,
		},
	})
}

// registerModeBindings registers key bindings for a specific mode
func (mskm *ModeSpecificKeyManager) registerModeBindings(mode ViewMode, bindings []*ModeKeyBinding) {
	if mskm.modeBindings[mode] == nil {
		mskm.modeBindings[mode] = make(map[string]*ModeKeyBinding)
	}

	for _, binding := range bindings {
		binding.Mode = mode
		binding.Enabled = true
		mskm.modeBindings[mode][binding.Key] = binding
	}
}

// registerGlobalBindings registers global key bindings
func (mskm *ModeSpecificKeyManager) registerGlobalBindings(bindings []*ModeKeyBinding) {
	for _, binding := range bindings {
		binding.Enabled = true
		mskm.globalBindings[binding.Key] = binding
	}
}

// SwitchMode switches to a new view mode and adapts key bindings
func (mskm *ModeSpecificKeyManager) SwitchMode(newMode ViewMode) {
	if mskm.currentMode == newMode {
		return
	}

	oldMode := mskm.currentMode
	mskm.currentMode = newMode
	mskm.lastModeChange = time.Now()

	// Rebuild active bindings for new mode
	mskm.rebuildActiveBindings()

	// Notify context manager of mode change
	if mskm.contextManager != nil {
		mskm.contextManager.UpdateContext(ShortcutContext{
			ViewMode: string(newMode),
		})
	}
	// Log mode change
	fmt.Printf("Key bindings adapted: %s -> %s\n", oldMode, newMode)
}

// SetMode changes the current view mode and rebuilds bindings
func (mskm *ModeSpecificKeyManager) SetMode(mode ViewMode) error {
	if mskm.currentMode == mode {
		return nil // No change needed
	}

	oldMode := mskm.currentMode
	mskm.currentMode = mode
	mskm.lastModeChange = time.Now()

	// Rebuild active bindings for new mode
	mskm.rebuildActiveBindings()

	// Update context manager if available
	if mskm.contextManager != nil {
		mskm.contextManager.UpdateContext(ShortcutContext{
			ViewMode: string(mode),
		})
	}

	// Log mode change
	fmt.Printf("Mode changed: %s -> %s\n", oldMode, mode)
	return nil
}

// rebuildActiveBindings rebuilds the active key bindings based on current mode
func (mskm *ModeSpecificKeyManager) rebuildActiveBindings() {
	mskm.activeBindings = make(map[string]key.Binding)
	// Add global bindings first
	for keyStr, binding := range mskm.globalBindings {
		if binding.Enabled {
			mskm.activeBindings[keyStr] = key.NewBinding(
				key.WithKeys(binding.Key),
				key.WithHelp(binding.Key, binding.Description),
			)
		}
	}

	// Add mode-specific bindings (these can override global ones)
	if modeBindings, exists := mskm.modeBindings[mskm.currentMode]; exists {
		for keyStr, binding := range modeBindings {
			if binding.Enabled {
				mskm.activeBindings[keyStr] = key.NewBinding(
					key.WithKeys(binding.Key),
					key.WithHelp(binding.Key, binding.Description),
				)
			}
		}
	}
}

// HandleKeyPress handles a key press with mode-specific logic
func (mskm *ModeSpecificKeyManager) HandleKeyPress(keyStr string) tea.Cmd {
	// Check mode-specific bindings first
	if modeBindings, exists := mskm.modeBindings[mskm.currentMode]; exists {
		if binding, found := modeBindings[keyStr]; found && binding.Enabled {
			return binding.Handler()
		}
	}

	// Check global bindings
	if binding, found := mskm.globalBindings[keyStr]; found && binding.Enabled {
		return binding.Handler()
	}

	return nil
}

// GetActiveBindings returns the currently active key bindings
func (mskm *ModeSpecificKeyManager) GetActiveBindings() map[string]key.Binding {
	return mskm.activeBindings
}

// GetModeHelp returns help text for the current mode
func (mskm *ModeSpecificKeyManager) GetModeHelp() []string {
	var help []string

	// Add mode-specific help
	if modeBindings, exists := mskm.modeBindings[mskm.currentMode]; exists {
		help = append(help, fmt.Sprintf("=== %s Mode ===", mskm.currentMode))
		for _, binding := range modeBindings {
			if binding.Enabled {
				help = append(help, fmt.Sprintf("%s: %s", binding.Key, binding.Description))
			}
		}
	}

	// Add global help
	help = append(help, "=== Global ===")
	for _, binding := range mskm.globalBindings {
		if binding.Enabled {
			help = append(help, fmt.Sprintf("%s: %s", binding.Key, binding.Description))
		}
	}

	return help
}

// EnableBinding enables a specific key binding
func (mskm *ModeSpecificKeyManager) EnableBinding(mode ViewMode, key string) {
	if mode == "" {
		// Global binding
		if binding, exists := mskm.globalBindings[key]; exists {
			binding.Enabled = true
		}
	} else {
		// Mode-specific binding
		if modeBindings, exists := mskm.modeBindings[mode]; exists {
			if binding, found := modeBindings[key]; found {
				binding.Enabled = true
			}
		}
	}
	mskm.rebuildActiveBindings()
}

// DisableBinding disables a specific key binding
func (mskm *ModeSpecificKeyManager) DisableBinding(mode ViewMode, key string) {
	if mode == "" {
		// Global binding
		if binding, exists := mskm.globalBindings[key]; exists {
			binding.Enabled = false
		}
	} else {
		// Mode-specific binding
		if modeBindings, exists := mskm.modeBindings[mode]; exists {
			if binding, found := modeBindings[key]; found {
				binding.Enabled = false
			}
		}
	}
	mskm.rebuildActiveBindings()
}

// GetCurrentMode returns the current view mode
func (mskm *ModeSpecificKeyManager) GetCurrentMode() ViewMode {
	return mskm.currentMode
}

// Handler functions for mode-specific actions
func (mskm *ModeSpecificKeyManager) createCardHandler() tea.Cmd {
	return func() tea.Msg { return CreateCardMsg{} }
}

func (mskm *ModeSpecificKeyManager) moveCardLeftHandler() tea.Cmd {
	return func() tea.Msg { return MoveCardDirectionMsg{Direction: "left"} }
}

func (mskm *ModeSpecificKeyManager) moveCardRightHandler() tea.Cmd {
	return func() tea.Msg { return MoveCardDirectionMsg{Direction: "right"} }
}

func (mskm *ModeSpecificKeyManager) moveCardUpHandler() tea.Cmd {
	return func() tea.Msg { return MoveCardDirectionMsg{Direction: "up"} }
}

func (mskm *ModeSpecificKeyManager) moveCardDownHandler() tea.Cmd {
	return func() tea.Msg { return MoveCardDirectionMsg{Direction: "down"} }
}

func (mskm *ModeSpecificKeyManager) setSwimlaneHandler() tea.Cmd {
	return func() tea.Msg { return SetSwimlaneMsg{} }
}

func (mskm *ModeSpecificKeyManager) setWIPLimitHandler() tea.Cmd {
	return func() tea.Msg { return SetWIPLimitMsg{} }
}

func (mskm *ModeSpecificKeyManager) toggleBlockedHandler() tea.Cmd {
	return func() tea.Msg { return ToggleBlockedMsg{} }
}

func (mskm *ModeSpecificKeyManager) addItemHandler() tea.Cmd {
	return func() tea.Msg { return AddItemMsg{} }
}

func (mskm *ModeSpecificKeyManager) toggleCompleteHandler() tea.Cmd {
	return func() tea.Msg { return ToggleCompleteMsg{} }
}

func (mskm *ModeSpecificKeyManager) setPriorityHandler() tea.Cmd {
	return func() tea.Msg { return SetPriorityMsg{} }
}

func (mskm *ModeSpecificKeyManager) setDueDateHandler() tea.Cmd {
	return func() tea.Msg { return SetDueDateMsg{} }
}

func (mskm *ModeSpecificKeyManager) addTagHandler() tea.Cmd {
	return func() tea.Msg { return AddTagMsg{} }
}

func (mskm *ModeSpecificKeyManager) sortListHandler() tea.Cmd {
	return func() tea.Msg { return SortListMsg{} }
}

func (mskm *ModeSpecificKeyManager) filterListHandler() tea.Cmd {
	return func() tea.Msg { return FilterListMsg{} }
}

func (mskm *ModeSpecificKeyManager) newEventHandler() tea.Cmd {
	return func() tea.Msg { return NewEventMsg{} }
}

func (mskm *ModeSpecificKeyManager) weekViewHandler() tea.Cmd {
	return func() tea.Msg { return ChangeCalendarViewMsg{View: "week"} }
}

func (mskm *ModeSpecificKeyManager) monthViewHandler() tea.Cmd {
	return func() tea.Msg { return ChangeCalendarViewMsg{View: "month"} }
}

func (mskm *ModeSpecificKeyManager) yearViewHandler() tea.Cmd {
	return func() tea.Msg { return ChangeCalendarViewMsg{View: "year"} }
}

func (mskm *ModeSpecificKeyManager) prevPeriodHandler() tea.Cmd {
	return func() tea.Msg { return NavigatePeriodMsg{Direction: "prev"} }
}

func (mskm *ModeSpecificKeyManager) nextPeriodHandler() tea.Cmd {
	return func() tea.Msg { return NavigatePeriodMsg{Direction: "next"} }
}

func (mskm *ModeSpecificKeyManager) goTodayHandler() tea.Cmd {
	return func() tea.Msg { return GoToTodayMsg{} }
}

func (mskm *ModeSpecificKeyManager) selectQuadrant1Handler() tea.Cmd {
	return func() tea.Msg { return SelectQuadrantMsg{Quadrant: 1} }
}

func (mskm *ModeSpecificKeyManager) selectQuadrant2Handler() tea.Cmd {
	return func() tea.Msg { return SelectQuadrantMsg{Quadrant: 2} }
}

func (mskm *ModeSpecificKeyManager) selectQuadrant3Handler() tea.Cmd {
	return func() tea.Msg { return SelectQuadrantMsg{Quadrant: 3} }
}

func (mskm *ModeSpecificKeyManager) selectQuadrant4Handler() tea.Cmd {
	return func() tea.Msg { return SelectQuadrantMsg{Quadrant: 4} }
}

func (mskm *ModeSpecificKeyManager) moveQuadrantHandler() tea.Cmd {
	return func() tea.Msg { return MoveQuadrantMsg{} }
}

func (mskm *ModeSpecificKeyManager) setUrgencyHandler() tea.Cmd {
	return func() tea.Msg { return SetUrgencyMsg{} }
}

func (mskm *ModeSpecificKeyManager) setImportanceHandler() tea.Cmd {
	return func() tea.Msg { return SetImportanceMsg{} }
}

func (mskm *ModeSpecificKeyManager) zoomInHandler() tea.Cmd {
	return func() tea.Msg { return ZoomMsg{Direction: "in"} }
}

func (mskm *ModeSpecificKeyManager) zoomOutHandler() tea.Cmd {
	return func() tea.Msg { return ZoomMsg{Direction: "out"} }
}

func (mskm *ModeSpecificKeyManager) panLeftHandler() tea.Cmd {
	return func() tea.Msg { return PanMsg{Direction: "left"} }
}

func (mskm *ModeSpecificKeyManager) panRightHandler() tea.Cmd {
	return func() tea.Msg { return PanMsg{Direction: "right"} }
}

func (mskm *ModeSpecificKeyManager) goToDateHandler() tea.Cmd {
	return func() tea.Msg { return GoToDateMsg{} }
}

func (mskm *ModeSpecificKeyManager) addMilestoneHandler() tea.Cmd {
	return func() tea.Msg { return AddMilestoneMsg{} }
}

func (mskm *ModeSpecificKeyManager) refreshHandler() tea.Cmd {
	return func() tea.Msg { return RefreshMsg{} }
}

func (mskm *ModeSpecificKeyManager) saveHandler() tea.Cmd {
	return func() tea.Msg { return SaveMsg{} }
}

func (mskm *ModeSpecificKeyManager) undoHandler() tea.Cmd {
	return func() tea.Msg { return UndoMsg{} }
}

func (mskm *ModeSpecificKeyManager) redoHandler() tea.Cmd {
	return func() tea.Msg { return RedoMsg{} }
}

func (mskm *ModeSpecificKeyManager) findHandler() tea.Cmd {
	return func() tea.Msg { return FindMsg{} }
}

func (mskm *ModeSpecificKeyManager) replaceHandler() tea.Cmd {
	return func() tea.Msg { return ReplaceMsg{} }
}

func (mskm *ModeSpecificKeyManager) cancelHandler() tea.Cmd {
	return func() tea.Msg { return CancelMsg{} }
}

// Additional message types for mode-specific actions
type CreateCardMsg struct{}
type MoveCardDirectionMsg struct{ Direction string }
type SetSwimlaneMsg struct{}
type SetWIPLimitMsg struct{}
type ToggleBlockedMsg struct{}
type AddItemMsg struct{}
type SetDueDateMsg struct{}
type AddTagMsg struct{}
type SortListMsg struct{}
type FilterListMsg struct{}
type NewEventMsg struct{}
type ChangeCalendarViewMsg struct{ View string }
type NavigatePeriodMsg struct{ Direction string }
type GoToTodayMsg struct{}
type SelectQuadrantMsg struct{ Quadrant int }
type MoveQuadrantMsg struct{}
type SetUrgencyMsg struct{}
type SetImportanceMsg struct{}
type ZoomMsg struct{ Direction string }
type PanMsg struct{ Direction string }
type GoToDateMsg struct{}
type AddMilestoneMsg struct{}
type RefreshMsg struct{}
type SaveMsg struct{}
type UndoMsg struct{}
type RedoMsg struct{}
type FindMsg struct{}
type ReplaceMsg struct{}
type CancelMsg struct{}
