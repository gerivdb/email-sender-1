package navigation

import (
	"fmt"
	"sync"
	"time"

	tea "github.com/charmbracelet/bubbletea"
)

// ModeManager handles navigation mode switching and state preservation
type ModeManager struct {
	currentMode      NavigationMode
	modes           map[NavigationMode]*ModeConfig
	stateHistory    map[NavigationMode]*ModeState
	transitionQueue []ModeTransition
	mutex           sync.RWMutex
	eventHandlers   map[NavigationMode][]ModeEventHandler
	preferences     *ModePreferences
}

// ModeConfig represents configuration for a navigation mode
type ModeConfig struct {
	Mode            NavigationMode            `json:"mode"`
	Name            string                    `json:"name"`
	Description     string                    `json:"description"`
	KeyMappings     map[string]string         `json:"key_mappings"`
	LayoutConfig    LayoutConfig              `json:"layout_config"`
	Behaviors       map[string]interface{}    `json:"behaviors"`
	Transitions     map[NavigationMode]string `json:"transitions"`
	Enabled         bool                      `json:"enabled"`
	AutoActivate    bool                      `json:"auto_activate"`
	Priority        int                       `json:"priority"`
}

// ModeState represents the preserved state for a navigation mode
type ModeState struct {
	Mode              NavigationMode         `json:"mode"`
	Position          Position               `json:"position"`
	ViewMode          ViewMode               `json:"view_mode"`
	FocusedElements   []string               `json:"focused_elements"`
	SelectionState    SelectionState         `json:"selection_state"`
	FilterState       FilterState            `json:"filter_state"`
	ScrollPosition    ScrollPosition         `json:"scroll_position"`
	LayoutState       LayoutState            `json:"layout_state"`
	CustomData        map[string]interface{} `json:"custom_data"`
	LastActivated     time.Time              `json:"last_activated"`
	ActivationCount   int                    `json:"activation_count"`
	SessionDuration   time.Duration          `json:"session_duration"`
}

// ModeTransition represents a mode transition
type ModeTransition struct {
	FromMode       NavigationMode    `json:"from_mode"`
	ToMode         NavigationMode    `json:"to_mode"`
	TriggerType    TransitionTrigger `json:"trigger_type"`
	PreserveState  bool              `json:"preserve_state"`
	AnimationType  string            `json:"animation_type"`
	Duration       time.Duration     `json:"duration"`
	BeforeCallback string            `json:"before_callback"`
	AfterCallback  string            `json:"after_callback"`
	Timestamp      time.Time         `json:"timestamp"`
}

// ModeEventHandler handles events for a specific mode
type ModeEventHandler func(event ModeEvent) tea.Cmd

// ModeEvent represents an event in a navigation mode
type ModeEvent struct {
	Type       ModeEventType              `json:"type"`
	Mode       NavigationMode             `json:"mode"`
	Data       map[string]interface{}     `json:"data"`
	Timestamp  time.Time                  `json:"timestamp"`
	Source     string                     `json:"source"`
}

// ModePreferences represents user preferences for navigation modes
type ModePreferences struct {
	DefaultMode         NavigationMode                `json:"default_mode"`
	AutoSwitchModes     bool                          `json:"auto_switch_modes"`
	PreserveStateAcrossModes bool                     `json:"preserve_state_across_modes"`
	ModeTransitionSpeed time.Duration                 `json:"mode_transition_speed"`
	EnabledModes        map[NavigationMode]bool       `json:"enabled_modes"`
	CustomModeSettings  map[NavigationMode]ModeConfig `json:"custom_mode_settings"`
	KeyboardShortcuts   map[string]NavigationMode     `json:"keyboard_shortcuts"`
}

// LayoutConfig represents layout configuration for a mode
type LayoutConfig struct {
	PanelLayout     string                 `json:"panel_layout"`
	ShowSidebar     bool                   `json:"show_sidebar"`
	ShowStatusBar   bool                   `json:"show_status_bar"`
	ShowToolbar     bool                   `json:"show_toolbar"`
	GridColumns     int                    `json:"grid_columns"`
	GridRows        int                    `json:"grid_rows"`
	PanelSizes      map[string]float64     `json:"panel_sizes"`
	CustomLayout    map[string]interface{} `json:"custom_layout"`
}

// SelectionState represents current selection state
type SelectionState struct {
	SelectedItems    []string               `json:"selected_items"`
	MultiSelection   bool                   `json:"multi_selection"`
	SelectionMode    string                 `json:"selection_mode"`
	LastSelected     string                 `json:"last_selected"`
	SelectionData    map[string]interface{} `json:"selection_data"`
}

// FilterState represents current filter state
type FilterState struct {
	ActiveFilters   map[string]interface{} `json:"active_filters"`
	SearchTerm      string                 `json:"search_term"`
	SortOrder       string                 `json:"sort_order"`
	SortField       string                 `json:"sort_field"`
	GroupBy         string                 `json:"group_by"`
	ShowHidden      bool                   `json:"show_hidden"`
}

// ScrollPosition represents scroll position
type ScrollPosition struct {
	X           int `json:"x"`
	Y           int `json:"y"`
	ViewportX   int `json:"viewport_x"`
	ViewportY   int `json:"viewport_y"`
	MaxX        int `json:"max_x"`
	MaxY        int `json:"max_y"`
}

// LayoutState represents layout state
type LayoutState struct {
	PanelSizes     map[string]float64     `json:"panel_sizes"`
	PanelStates    map[string]string      `json:"panel_states"`
	WindowSize     Position               `json:"window_size"`
	SplitRatios    []float64              `json:"split_ratios"`
	HiddenPanels   []string               `json:"hidden_panels"`
	CustomLayouts  map[string]interface{} `json:"custom_layouts"`
}

// Utilisation du TransitionTrigger depuis types.go

// ModeEventType represents the type of mode event
type ModeEventType int

const (
	ModeEventActivated ModeEventType = iota
	ModeEventDeactivated
	ModeEventStateChanged
	ModeEventError
	ModeEventTransition
)

// Bubble Tea Messages for mode management
type ModeActivatedMsg struct {
	Mode        NavigationMode
	PreviousMode NavigationMode
	PreservedState *ModeState
}

type ModeDeactivatedMsg struct {
	Mode NavigationMode
	NextMode NavigationMode
	SavedState *ModeState
}

type ModeStateUpdatedMsg struct {
	Mode  NavigationMode
	State *ModeState
}

type ModeTransitionStartedMsg struct {
	Transition ModeTransition
}

type ModeTransitionCompletedMsg struct {
	Transition ModeTransition
	Duration   time.Duration
}

type ModeErrorMsg struct {
	Mode  NavigationMode
	Error error
}

// NewModeManager creates a new mode manager
func NewModeManager() *ModeManager {
	mm := &ModeManager{
		currentMode:     NavigationModeNormal,
		modes:          make(map[NavigationMode]*ModeConfig),
		stateHistory:   make(map[NavigationMode]*ModeState),
		transitionQueue: make([]ModeTransition, 0),
		eventHandlers:  make(map[NavigationMode][]ModeEventHandler),
		preferences:    DefaultModePreferences(),
	}

	mm.initializeDefaultModes()
	return mm
}

// SwitchMode switches to a new navigation mode
func (mm *ModeManager) SwitchMode(targetMode NavigationMode) tea.Cmd {
	mm.mutex.Lock()
	defer mm.mutex.Unlock()

	if targetMode == mm.currentMode {
		return nil
	}

	currentConfig, exists := mm.modes[mm.currentMode]
	if !exists {
		return func() tea.Msg {
			return ModeErrorMsg{
				Mode:  mm.currentMode,
				Error: fmt.Errorf("current mode configuration not found"),
			}
		}
	}

	targetConfig, exists := mm.modes[targetMode]
	if !exists || !targetConfig.Enabled {
		return func() tea.Msg {
			return ModeErrorMsg{
				Mode:  targetMode,
				Error: fmt.Errorf("target mode not available or disabled"),
			}
		}
	}

	// Save current mode state
	currentState := mm.captureCurrentState()
	mm.stateHistory[mm.currentMode] = currentState

	// Create transition
	transition := ModeTransition{
		FromMode:      mm.currentMode,
		ToMode:        targetMode,
		TriggerType:   TransitionTriggerManual,
		PreserveState: mm.preferences.PreserveStateAcrossModes,
		AnimationType: mm.getTransitionAnimation(mm.currentMode, targetMode),
		Duration:      mm.preferences.ModeTransitionSpeed,
		Timestamp:     time.Now(),
	}

	// Add to queue
	mm.transitionQueue = append(mm.transitionQueue, transition)

	previousMode := mm.currentMode
	mm.currentMode = targetMode

	// Get preserved state if available
	var preservedState *ModeState
	if savedState, exists := mm.stateHistory[targetMode]; exists && transition.PreserveState {
		preservedState = savedState
		preservedState.LastActivated = time.Now()
		preservedState.ActivationCount++
	}

	return tea.Batch(
		func() tea.Msg {
			return ModeTransitionStartedMsg{Transition: transition}
		},
		func() tea.Msg {
			return ModeDeactivatedMsg{
				Mode:       previousMode,
				NextMode:   targetMode,
				SavedState: currentState,
			}
		},
		func() tea.Msg {
			return ModeActivatedMsg{
				Mode:           targetMode,
				PreviousMode:   previousMode,
				PreservedState: preservedState,
			}
		},
	)
}

// SwitchModeAdvanced provides enhanced mode switching with advanced state preservation
func (mm *ModeManager) SwitchModeAdvanced(targetMode NavigationMode, options *TransitionOptions) tea.Cmd {
	mm.mutex.Lock()
	defer mm.mutex.Unlock()

	if mm.currentMode == targetMode {
		return nil
	}

	// Validate target mode
	if _, exists := mm.modes[targetMode]; !exists {
		return func() tea.Msg {
			return ModeErrorMsg{
				Mode:  targetMode,
				Error: fmt.Errorf("target mode not configured: %s", targetMode.String()),
			}
		}
	}

	// Capture current state with enhanced preservation
	currentState := mm.captureAdvancedModeState(mm.currentMode)
	if currentState != nil {
		mm.stateHistory[mm.currentMode] = currentState
	}

	// Create enhanced transition
	transition := ModeTransition{
		FromMode:       mm.currentMode,
		ToMode:         targetMode,
		TriggerType:    options.Trigger,
		PreserveState:  options.PreserveState,
		AnimationType:  options.AnimationType,
		Duration:       options.Duration,
		BeforeCallback: options.BeforeCallback,
		AfterCallback:  options.AfterCallback,
		Timestamp:      time.Now(),
	}

	// Add to queue
	mm.transitionQueue = append(mm.transitionQueue, transition)

	previousMode := mm.currentMode
	mm.currentMode = targetMode

	// Get preserved state with advanced restoration
	var preservedState *ModeState
	if savedState, exists := mm.stateHistory[targetMode]; exists && transition.PreserveState {
		preservedState = mm.enhanceStateRestoration(savedState, targetMode)
	}

	return tea.Batch(
		func() tea.Msg {
			return ModeTransitionStartedMsg{Transition: transition}
		},
		func() tea.Msg {
			return ModeDeactivatedMsg{
				Mode:       previousMode,
				NextMode:   targetMode,
				SavedState: currentState,
			}
		},
		func() tea.Msg {
			return ModeActivatedMsg{
				Mode:           targetMode,
				PreviousMode:   previousMode,
				PreservedState: preservedState,
			}
		},
		func() tea.Msg {
			return ModeTransitionCompletedMsg{
				Transition: transition,
				Duration:   time.Since(transition.Timestamp),
			}
		},
	)
}

// GetCurrentMode returns the current navigation mode
func (mm *ModeManager) GetCurrentMode() NavigationMode {
	mm.mutex.RLock()
	defer mm.mutex.RUnlock()
	return mm.currentMode
}

// GetModeConfig returns the configuration for a specific mode
func (mm *ModeManager) GetModeConfig(mode NavigationMode) (*ModeConfig, error) {
	mm.mutex.RLock()
	defer mm.mutex.RUnlock()

	config, exists := mm.modes[mode]
	if !exists {
		return nil, fmt.Errorf("mode configuration not found: %s", mode.String())
	}

	return config, nil
}

// UpdateModeConfig updates the configuration for a specific mode
func (mm *ModeManager) UpdateModeConfig(mode NavigationMode, config *ModeConfig) error {
	mm.mutex.Lock()
	defer mm.mutex.Unlock()

	if config == nil {
		return fmt.Errorf("config cannot be nil")
	}

	config.Mode = mode
	mm.modes[mode] = config

	return nil
}

// GetModeState returns the current state for a mode
func (mm *ModeManager) GetModeState(mode NavigationMode) (*ModeState, error) {
	mm.mutex.RLock()
	defer mm.mutex.RUnlock()

	if mode == mm.currentMode {
		// Return current state
		return mm.captureCurrentState(), nil
	}

	// Return saved state
	state, exists := mm.stateHistory[mode]
	if !exists {
		return nil, fmt.Errorf("no saved state for mode: %s", mode.String())
	}

	return state, nil
}

// RestoreState restores a saved state for the current mode
func (mm *ModeManager) RestoreState(state *ModeState) tea.Cmd {
	mm.mutex.Lock()
	defer mm.mutex.Unlock()

	if state == nil {
		return nil
	}

	// Update current mode state
	mm.stateHistory[mm.currentMode] = state

	return func() tea.Msg {
		return ModeStateUpdatedMsg{
			Mode:  mm.currentMode,
			State: state,
		}
	}
}

// AddEventHandler adds an event handler for a specific mode
func (mm *ModeManager) AddEventHandler(mode NavigationMode, handler ModeEventHandler) {
	mm.mutex.Lock()
	defer mm.mutex.Unlock()

	if mm.eventHandlers[mode] == nil {
		mm.eventHandlers[mode] = make([]ModeEventHandler, 0)
	}

	mm.eventHandlers[mode] = append(mm.eventHandlers[mode], handler)
}

// TriggerEvent triggers an event for the current mode
func (mm *ModeManager) TriggerEvent(eventType ModeEventType, data map[string]interface{}) []tea.Cmd {
	mm.mutex.RLock()
	defer mm.mutex.RUnlock()

	event := ModeEvent{
		Type:      eventType,
		Mode:      mm.currentMode,
		Data:      data,
		Timestamp: time.Now(),
		Source:    "mode_manager",
	}

	var commands []tea.Cmd
	handlers := mm.eventHandlers[mm.currentMode]

	for _, handler := range handlers {
		if cmd := handler(event); cmd != nil {
			commands = append(commands, cmd)
		}
	}

	return commands
}

// GetAvailableModes returns all available modes
func (mm *ModeManager) GetAvailableModes() []NavigationMode {
	mm.mutex.RLock()
	defer mm.mutex.RUnlock()

	modes := make([]NavigationMode, 0, len(mm.modes))
	for mode, config := range mm.modes {
		if config.Enabled {
			modes = append(modes, mode)
		}
	}

	return modes
}

// GetTransitionHistory returns the transition history
func (mm *ModeManager) GetTransitionHistory() []ModeTransition {
	mm.mutex.RLock()
	defer mm.mutex.RUnlock()

	history := make([]ModeTransition, len(mm.transitionQueue))
	copy(history, mm.transitionQueue)
	return history
}

// SetPreferences updates mode preferences
func (mm *ModeManager) SetPreferences(prefs *ModePreferences) {
	mm.mutex.Lock()
	defer mm.mutex.Unlock()
	mm.preferences = prefs
}

// GetPreferences returns current mode preferences
func (mm *ModeManager) GetPreferences() *ModePreferences {
	mm.mutex.RLock()
	defer mm.mutex.RUnlock()
	return mm.preferences
}

// Private helper methods

func (mm *ModeManager) initializeDefaultModes() {
	// Normal mode
	mm.modes[NavigationModeNormal] = &ModeConfig{
		Mode:        NavigationModeNormal,
		Name:        "Normal",
		Description: "Standard navigation mode with basic controls",
		KeyMappings: map[string]string{
			"j":     "navigate_down",
			"k":     "navigate_up",
			"h":     "navigate_left",
			"l":     "navigate_right",
			"enter": "select",
			"esc":   "cancel",
		},
		LayoutConfig: LayoutConfig{
			PanelLayout:   "standard",
			ShowSidebar:   true,
			ShowStatusBar: true,
			ShowToolbar:   true,
		},
		Enabled:      true,
		AutoActivate: false,
		Priority:     1,
	}

	// Vim mode
	mm.modes[NavigationModeVim] = &ModeConfig{
		Mode:        NavigationModeVim,
		Name:        "Vim",
		Description: "Vim-style navigation with modal editing",
		KeyMappings: map[string]string{
			"j":       "navigate_down",
			"k":       "navigate_up",
			"h":       "navigate_left",
			"l":       "navigate_right",
			"gg":      "go_to_top",
			"G":       "go_to_bottom",
			"ctrl+d":  "page_down",
			"ctrl+u":  "page_up",
			"w":       "next_word",
			"b":       "previous_word",
			"0":       "line_start",
			"$":       "line_end",
			"/":       "search",
			"n":       "next_search",
			"N":       "previous_search",
			"i":       "insert_mode",
			"a":       "append_mode",
			"v":       "visual_mode",
			"dd":      "delete_line",
			"yy":      "yank_line",
			"p":       "paste",
			"u":       "undo",
			"ctrl+r":  "redo",
		},
		LayoutConfig: LayoutConfig{
			PanelLayout:   "minimal",
			ShowSidebar:   false,
			ShowStatusBar: true,
			ShowToolbar:   false,
		},
		Enabled:      true,
		AutoActivate: false,
		Priority:     2,
	}

	// Accessibility mode
	mm.modes[NavigationModeAccessibility] = &ModeConfig{
		Mode:        NavigationModeAccessibility,
		Name:        "Accessibility",
		Description: "Enhanced navigation for accessibility users",
		KeyMappings: map[string]string{
			"tab":       "next_element",
			"shift+tab": "previous_element",
			"enter":     "activate",
			"space":     "select",
			"f1":        "help",
			"f2":        "context_menu",
			"f3":        "search",
			"f4":        "navigate_landmarks",
			"ctrl+home": "go_to_main",
			"alt+1":     "heading_level_1",
			"alt+2":     "heading_level_2",
			"alt+3":     "heading_level_3",
		},
		LayoutConfig: LayoutConfig{
			PanelLayout:   "accessible",
			ShowSidebar:   true,
			ShowStatusBar: true,
			ShowToolbar:   true,
			GridColumns:   1,
			GridRows:      1,
		},
		Behaviors: map[string]interface{}{
			"high_contrast":     true,
			"screen_reader":     true,
			"keyboard_only":     true,
			"reduced_motion":    true,
			"focus_indicators":  true,
			"audio_feedback":    true,
		},
		Enabled:      true,
		AutoActivate: false,
		Priority:     3,
	}

	// Custom mode (user-defined)
	mm.modes[NavigationModeCustom] = &ModeConfig{
		Mode:        NavigationModeCustom,
		Name:        "Custom",
		Description: "User-defined navigation mode",
		KeyMappings: make(map[string]string),
		LayoutConfig: LayoutConfig{
			PanelLayout:   "custom",
			ShowSidebar:   true,
			ShowStatusBar: true,
			ShowToolbar:   true,
		},
		Enabled:      false,
		AutoActivate: false,
		Priority:     4,
	}
}

func (mm *ModeManager) captureCurrentState() *ModeState {
	return &ModeState{
		Mode:            mm.currentMode,
		Position:        Position{}, // Will be filled by actual position
		ViewMode:        ViewModeList, // Will be filled by actual view
		FocusedElements: make([]string, 0),
		SelectionState: SelectionState{
			SelectedItems:  make([]string, 0),
			MultiSelection: false,
			SelectionMode:  "single",
		},
		FilterState: FilterState{
			ActiveFilters: make(map[string]interface{}),
			SearchTerm:    "",
			SortOrder:     "asc",
		},
		ScrollPosition: ScrollPosition{},
		LayoutState: LayoutState{
			PanelSizes:  make(map[string]float64),
			PanelStates: make(map[string]string),
		},
		CustomData:      make(map[string]interface{}),
		LastActivated:   time.Now(),
		ActivationCount: 1,
	}
}

func (mm *ModeManager) getTransitionAnimation(from, to NavigationMode) string {
	// Define mode transition animations
	transitions := map[string]string{
		fmt.Sprintf("%s_to_%s", NavigationModeNormal, NavigationModeVim):           "fade",
		fmt.Sprintf("%s_to_%s", NavigationModeVim, NavigationModeNormal):           "fade",
		fmt.Sprintf("%s_to_%s", NavigationModeNormal, NavigationModeAccessibility): "slide_up",
		fmt.Sprintf("%s_to_%s", NavigationModeAccessibility, NavigationModeNormal): "slide_down",
		fmt.Sprintf("%s_to_%s", NavigationModeVim, NavigationModeAccessibility):    "cross_fade",
		fmt.Sprintf("%s_to_%s", NavigationModeAccessibility, NavigationModeVim):    "cross_fade",
	}

	key := fmt.Sprintf("%s_to_%s", from.String(), to.String())
	if animation, exists := transitions[key]; exists {
		return animation
	}

	return "fade" // Default animation
}

// DefaultModePreferences returns default mode preferences
func DefaultModePreferences() *ModePreferences {
	return &ModePreferences{
		DefaultMode:                  NavigationModeNormal,
		AutoSwitchModes:             false,
		PreserveStateAcrossModes:    true,
		ModeTransitionSpeed:         300 * time.Millisecond,
		EnabledModes: map[NavigationMode]bool{
			NavigationModeNormal:        true,
			NavigationModeVim:           true,
			NavigationModeAccessibility: true,
			NavigationModeCustom:        false,
		},
		CustomModeSettings:  make(map[NavigationMode]ModeConfig),
		KeyboardShortcuts: map[string]NavigationMode{
			"F1": NavigationModeNormal,
			"F2": NavigationModeVim,
			"F3": NavigationModeAccessibility,
			"F4": NavigationModeCustom,
		},
	}
}

// SwitchModeAdvanced provides enhanced mode switching with advanced state preservation
func (mm *ModeManager) SwitchModeAdvanced(targetMode NavigationMode, options *TransitionOptions) tea.Cmd {
	mm.mutex.Lock()
	defer mm.mutex.Unlock()

	if mm.currentMode == targetMode {
		return nil
	}

	// Validate target mode
	if _, exists := mm.modes[targetMode]; !exists {
		return func() tea.Msg {
			return ModeErrorMsg{
				Mode:  targetMode,
				Error: fmt.Errorf("target mode not configured: %s", targetMode.String()),
			}
		}
	}

	// Capture current state with enhanced preservation
	currentState := mm.captureAdvancedModeState(mm.currentMode)
	if currentState != nil {
		mm.stateHistory[mm.currentMode] = currentState
	}

	// Create enhanced transition
	transition := ModeTransition{
		FromMode:       mm.currentMode,
		ToMode:         targetMode,
		TriggerType:    options.Trigger,
		PreserveState:  options.PreserveState,
		AnimationType:  options.AnimationType,
		Duration:       options.Duration,
		BeforeCallback: options.BeforeCallback,
		AfterCallback:  options.AfterCallback,
		Timestamp:      time.Now(),
	}

	// Add to queue
	mm.transitionQueue = append(mm.transitionQueue, transition)

	previousMode := mm.currentMode
	mm.currentMode = targetMode

	// Get preserved state with advanced restoration
	var preservedState *ModeState
	if savedState, exists := mm.stateHistory[targetMode]; exists && transition.PreserveState {
		preservedState = mm.enhanceStateRestoration(savedState, targetMode)
	}

	return tea.Batch(
		func() tea.Msg {
			return ModeTransitionStartedMsg{Transition: transition}
		},
		func() tea.Msg {
			return ModeDeactivatedMsg{
				Mode:       previousMode,
				NextMode:   targetMode,
				SavedState: currentState,
			}
		},
		func() tea.Msg {
			return ModeActivatedMsg{
				Mode:           targetMode,
				PreviousMode:   previousMode,
				PreservedState: preservedState,
			}
		},
		func() tea.Msg {
			return ModeTransitionCompletedMsg{
				Transition: transition,
				Duration:   time.Since(transition.Timestamp),
			}
		},
	)
}

// captureAdvancedModeState captures detailed state information for advanced preservation
func (mm *ModeManager) captureAdvancedModeState(mode NavigationMode) *ModeState {
	config, exists := mm.modes[mode]
	if !exists {
		return nil
	}

	state := &ModeState{
		Mode:              mode,
		Position:          Position{}, // Will be populated by caller
		ViewMode:          ViewModeList, // Will be populated by caller
		FocusedElements:   make([]string, 0),
		SelectionState:    SelectionState{},
		FilterState:       FilterState{},
		ScrollPosition:    ScrollPosition{},
		LayoutState:       LayoutState{},
		CustomData:        make(map[string]interface{}),
		LastActivated:     time.Now(),
		ActivationCount:   1,
		SessionDuration:   time.Duration(0),
	}

	// Enhanced state capture based on mode type
	switch mode {
	case NavigationModeKanban:
		mm.captureKanbanState(state)
	case NavigationModeMatrix:
		mm.captureMatrixState(state)
	case NavigationModeHierarchical:
		mm.captureHierarchicalState(state)
	case NavigationModeSearch:
		mm.captureSearchState(state)
	case NavigationModeFocus:
		mm.captureFocusState(state)
	default:
		mm.captureGenericState(state)
	}

	return state
}

// enhanceStateRestoration provides enhanced state restoration with mode-specific logic
func (mm *ModeManager) enhanceStateRestoration(state *ModeState, mode NavigationMode) *ModeState {
	enhanced := *state
	enhanced.LastActivated = time.Now()
	enhanced.ActivationCount++

	// Mode-specific state enhancement
	switch mode {
	case NavigationModeKanban:
		mm.enhanceKanbanRestoration(&enhanced)
	case NavigationModeMatrix:
		mm.enhanceMatrixRestoration(&enhanced)
	case NavigationModeHierarchical:
		mm.enhanceHierarchicalRestoration(&enhanced)
	case NavigationModeSearch:
		mm.enhanceSearchRestoration(&enhanced)
	case NavigationModeFocus:
		mm.enhanceFocusRestoration(&enhanced)
	}

	return &enhanced
}

// Mode-specific state capture methods
func (mm *ModeManager) captureKanbanState(state *ModeState) {
	state.CustomData["columns"] = mm.getKanbanColumns()
	state.CustomData["cardPositions"] = mm.getKanbanCardPositions()
	state.CustomData["columnWidths"] = mm.getKanbanColumnWidths()
}

func (mm *ModeManager) captureMatrixState(state *ModeState) {
	state.CustomData["matrix_dimensions"] = mm.getMatrixDimensions()
	state.CustomData["cell_focus"] = mm.getMatrixFocusedCell()
	state.CustomData["zoom_level"] = mm.getMatrixZoomLevel()
}

func (mm *ModeManager) captureHierarchicalState(state *ModeState) {
	state.CustomData["expanded_nodes"] = mm.getExpandedNodes()
	state.CustomData["tree_depth"] = mm.getCurrentTreeDepth()
	state.CustomData["collapsed_branches"] = mm.getCollapsedBranches()
}

func (mm *ModeManager) captureSearchState(state *ModeState) {
	state.CustomData["search_query"] = mm.getCurrentSearchQuery()
	state.CustomData["search_filters"] = mm.getActiveSearchFilters()
	state.CustomData["search_results"] = mm.getSearchResultsMetadata()
}

func (mm *ModeManager) captureFocusState(state *ModeState) {
	state.CustomData["focus_target"] = mm.getFocusTarget()
	state.CustomData["zoom_level"] = mm.getFocusZoomLevel()
	state.CustomData["context_items"] = mm.getFocusContextItems()
}

func (mm *ModeManager) captureGenericState(state *ModeState) {
	state.CustomData["generic_layout"] = mm.getGenericLayoutState()
}

// Mode-specific state restoration enhancement methods
func (mm *ModeManager) enhanceKanbanRestoration(state *ModeState) {
	// Restore kanban-specific state with validation
	if columns, ok := state.CustomData["columns"]; ok {
		mm.validateAndRestoreKanbanColumns(columns)
	}
}

func (mm *ModeManager) enhanceMatrixRestoration(state *ModeState) {
	// Restore matrix-specific state with validation
	if dimensions, ok := state.CustomData["matrix_dimensions"]; ok {
		mm.validateAndRestoreMatrixDimensions(dimensions)
	}
}

func (mm *ModeManager) enhanceHierarchicalRestoration(state *ModeState) {
	// Restore hierarchical-specific state with validation
	if expandedNodes, ok := state.CustomData["expanded_nodes"]; ok {
		mm.validateAndRestoreExpandedNodes(expandedNodes)
	}
}

func (mm *ModeManager) enhanceSearchRestoration(state *ModeState) {
	// Restore search-specific state with validation
	if query, ok := state.CustomData["search_query"]; ok {
		mm.validateAndRestoreSearchQuery(query)
	}
}

func (mm *ModeManager) enhanceFocusRestoration(state *ModeState) {
	// Restore focus-specific state with validation
	if target, ok := state.CustomData["focus_target"]; ok {
		mm.validateAndRestoreFocusTarget(target)
	}
}

// Placeholder methods for state capture/restoration (to be implemented by specific view components)
func (mm *ModeManager) getKanbanColumns() interface{} { return nil }
func (mm *ModeManager) getKanbanCardPositions() interface{} { return nil }
func (mm *ModeManager) getKanbanColumnWidths() interface{} { return nil }
func (mm *ModeManager) getMatrixDimensions() interface{} { return nil }
func (mm *ModeManager) getMatrixFocusedCell() interface{} { return nil }
func (mm *ModeManager) getMatrixZoomLevel() interface{} { return nil }
func (mm *ModeManager) getExpandedNodes() interface{} { return nil }
func (mm *ModeManager) getCurrentTreeDepth() interface{} { return nil }
func (mm *ModeManager) getCollapsedBranches() interface{} { return nil }
func (mm *ModeManager) getCurrentSearchQuery() interface{} { return nil }
func (mm *ModeManager) getActiveSearchFilters() interface{} { return nil }
func (mm *ModeManager) getSearchResultsMetadata() interface{} { return nil }
func (mm *ModeManager) getFocusTarget() interface{} { return nil }
func (mm *ModeManager) getFocusZoomLevel() interface{} { return nil }
func (mm *ModeManager) getFocusContextItems() interface{} { return nil }
func (mm *ModeManager) getGenericLayoutState() interface{} { return nil }

func (mm *ModeManager) validateAndRestoreKanbanColumns(columns interface{}) {}
func (mm *ModeManager) validateAndRestoreMatrixDimensions(dimensions interface{}) {}
func (mm *ModeManager) validateAndRestoreExpandedNodes(nodes interface{}) {}
func (mm *ModeManager) validateAndRestoreSearchQuery(query interface{}) {}
func (mm *ModeManager) validateAndRestoreFocusTarget(target interface{}) {}
