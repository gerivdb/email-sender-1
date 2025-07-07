package navigation

import (
	"context"
	"fmt"
	"sync"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

// ErrorEntry represents an error entry for cataloging (simplified local version)
type ErrorEntry struct {
	ID             string    `json:"id"`
	Timestamp      time.Time `json:"timestamp"`
	Message        string    `json:"message"`
	StackTrace     string    `json:"stack_trace"`
	Module         string    `json:"module"`
	ErrorCode      string    `json:"error_code"`
	ManagerContext string    `json:"manager_context"`
	Severity       string    `json:"severity"`
}

// CircuitBreaker interface for local use
type CircuitBreaker interface {
	Call(fn func() error) error
}

// Simple circuit breaker implementation for local use
type SimpleCircuitBreaker struct {
	name         string
	failureCount int
	maxFailures  int
	resetTimeout time.Duration
	lastFailure  time.Time
	state        string // "closed", "open", "half-open"
	mutex        sync.RWMutex
}

// NewCircuitBreaker creates a new simple circuit breaker
func NewCircuitBreaker(name string, maxFailures int, resetTimeout time.Duration) *SimpleCircuitBreaker {
	return &SimpleCircuitBreaker{
		name:         name,
		maxFailures:  maxFailures,
		resetTimeout: resetTimeout,
		state:        "closed",
	}
}

// Call executes the function with circuit breaker protection
func (cb *SimpleCircuitBreaker) Call(fn func() error) error {
	cb.mutex.Lock()
	defer cb.mutex.Unlock()

	// Check if circuit should be reset
	if cb.state == "open" && time.Since(cb.lastFailure) > cb.resetTimeout {
		cb.state = "half-open"
		cb.failureCount = 0
	}

	// If circuit is open, fail fast
	if cb.state == "open" {
		return fmt.Errorf("circuit breaker %s is open", cb.name)
	}

	// Execute function
	err := fn()
	if err != nil {
		cb.failureCount++
		cb.lastFailure = time.Now()

		if cb.failureCount >= cb.maxFailures {
			cb.state = "open"
		}
		return err
	}

	// Success - reset if we were half-open
	if cb.state == "half-open" {
		cb.state = "closed"
		cb.failureCount = 0
	}

	return nil
}

// ModeManager handles navigation mode switching and state preservation
type ModeManager struct {
	currentMode     NavigationMode
	modes           map[NavigationMode]*ModeConfig
	stateHistory    map[NavigationMode]*ModeState
	transitionQueue []ModeTransition
	mutex           sync.RWMutex
	eventHandlers   map[NavigationMode][]ModeEventHandler
	preferences     *ModePreferences
	logger          *zap.Logger
	errorManager    *ErrorManager
	circuitBreaker  CircuitBreaker
	metrics         *ModeMetrics
}

// ErrorManager encapsulates error management functionality for Mode Manager
type ErrorManager struct {
	logger *zap.Logger
}

// ErrorHooks defines callbacks for error handling in Mode Manager
type ErrorHooks struct {
	OnError func(err error)
	OnRetry func(attempt int, err error)
}

// ModeMetrics tracks metrics for mode switching and state management
type ModeMetrics struct {
	TotalTransitions   int                    `json:"total_transitions"`
	TransitionCounts   map[NavigationMode]int `json:"transition_counts"`
	ErrorCounts        map[string]int         `json:"error_counts"`
	AverageTransition  time.Duration          `json:"average_transition_time"`
	StatePreservations int                    `json:"state_preservations"`
	FailedTransitions  int                    `json:"failed_transitions"`
	LastMetricsReset   time.Time              `json:"last_metrics_reset"`
	mu                 sync.RWMutex
}

// ModeConfig represents configuration for a navigation mode
type ModeConfig struct {
	Mode         NavigationMode            `json:"mode"`
	Name         string                    `json:"name"`
	Description  string                    `json:"description"`
	KeyMappings  map[string]string         `json:"key_mappings"`
	LayoutConfig LayoutConfig              `json:"layout_config"`
	Behaviors    map[string]interface{}    `json:"behaviors"`
	Transitions  map[NavigationMode]string `json:"transitions"`
	Enabled      bool                      `json:"enabled"`
	AutoActivate bool                      `json:"auto_activate"`
	Priority     int                       `json:"priority"`
}

// ModeState represents the preserved state for a navigation mode
type ModeState struct {
	Mode            NavigationMode         `json:"mode"`
	Position        Position               `json:"position"`
	ViewMode        ViewMode               `json:"view_mode"`
	FocusedElements []string               `json:"focused_elements"`
	SelectionState  SelectionState         `json:"selection_state"`
	FilterState     FilterState            `json:"filter_state"`
	ScrollPosition  ScrollPosition         `json:"scroll_position"`
	LayoutState     LayoutState            `json:"layout_state"`
	CustomData      map[string]interface{} `json:"custom_data"`
	LastActivated   time.Time              `json:"last_activated"`
	ActivationCount int                    `json:"activation_count"`
	SessionDuration time.Duration          `json:"session_duration"`
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
	Type      ModeEventType          `json:"type"`
	Mode      NavigationMode         `json:"mode"`
	Data      map[string]interface{} `json:"data"`
	Timestamp time.Time              `json:"timestamp"`
	Source    string                 `json:"source"`
}

// ModePreferences represents user preferences for navigation modes
type ModePreferences struct {
	DefaultMode              NavigationMode                `json:"default_mode"`
	AutoSwitchModes          bool                          `json:"auto_switch_modes"`
	PreserveStateAcrossModes bool                          `json:"preserve_state_across_modes"`
	ModeTransitionSpeed      time.Duration                 `json:"mode_transition_speed"`
	EnabledModes             map[NavigationMode]bool       `json:"enabled_modes"`
	CustomModeSettings       map[NavigationMode]ModeConfig `json:"custom_mode_settings"`
	KeyboardShortcuts        map[string]NavigationMode     `json:"keyboard_shortcuts"`
}

// LayoutConfig represents layout configuration for a mode
type LayoutConfig struct {
	PanelLayout   string                 `json:"panel_layout"`
	ShowSidebar   bool                   `json:"show_sidebar"`
	ShowStatusBar bool                   `json:"show_status_bar"`
	ShowToolbar   bool                   `json:"show_toolbar"`
	GridColumns   int                    `json:"grid_columns"`
	GridRows      int                    `json:"grid_rows"`
	PanelSizes    map[string]float64     `json:"panel_sizes"`
	CustomLayout  map[string]interface{} `json:"custom_layout"`
}

// SelectionState represents current selection state
type SelectionState struct {
	SelectedItems  []string               `json:"selected_items"`
	MultiSelection bool                   `json:"multi_selection"`
	SelectionMode  string                 `json:"selection_mode"`
	LastSelected   string                 `json:"last_selected"`
	SelectionData  map[string]interface{} `json:"selection_data"`
}

// FilterState represents current filter state
type FilterState struct {
	ActiveFilters map[string]interface{} `json:"active_filters"`
	SearchTerm    string                 `json:"search_term"`
	SortOrder     string                 `json:"sort_order"`
	SortField     string                 `json:"sort_field"`
	GroupBy       string                 `json:"group_by"`
	ShowHidden    bool                   `json:"show_hidden"`
}

// ScrollPosition represents scroll position
type ScrollPosition struct {
	X         int `json:"x"`
	Y         int `json:"y"`
	ViewportX int `json:"viewport_x"`
	ViewportY int `json:"viewport_y"`
	MaxX      int `json:"max_x"`
	MaxY      int `json:"max_y"`
}

// LayoutState represents layout state
type LayoutState struct {
	PanelSizes    map[string]float64     `json:"panel_sizes"`
	PanelStates   map[string]string      `json:"panel_states"`
	WindowSize    Position               `json:"window_size"`
	SplitRatios   []float64              `json:"split_ratios"`
	HiddenPanels  []string               `json:"hidden_panels"`
	CustomLayouts map[string]interface{} `json:"custom_layouts"`
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
	Mode           NavigationMode
	PreviousMode   NavigationMode
	PreservedState *ModeState
}

type ModeDeactivatedMsg struct {
	Mode       NavigationMode
	NextMode   NavigationMode
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

// NewModeManager creates a new mode manager with ErrorManager integration
func NewModeManager() *ModeManager {
	logger, _ := zap.NewProduction()

	errorManager := &ErrorManager{
		logger: logger,
	}
	// Initialize circuit breaker for mode operations
	circuitBreaker := NewCircuitBreaker("mode-manager", 5, 30*time.Second)

	metrics := &ModeMetrics{
		TransitionCounts: make(map[NavigationMode]int),
		ErrorCounts:      make(map[string]int),
		LastMetricsReset: time.Now(),
	}

	mm := &ModeManager{
		currentMode:     NavigationModeNormal,
		modes:           make(map[NavigationMode]*ModeConfig),
		stateHistory:    make(map[NavigationMode]*ModeState),
		transitionQueue: make([]ModeTransition, 0),
		eventHandlers:   make(map[NavigationMode][]ModeEventHandler),
		preferences:     DefaultModePreferences(),
		logger:          logger,
		errorManager:    errorManager,
		circuitBreaker:  circuitBreaker,
		metrics:         metrics,
	}

	mm.initializeDefaultModes()

	mm.logger.Info("Mode Manager initialized with ErrorManager integration",
		zap.String("component", "mode-manager"),
		zap.String("initial_mode", mm.currentMode.String()))

	return mm
}

// SwitchMode switches to a new navigation mode with ErrorManager integration
func (mm *ModeManager) SwitchMode(targetMode NavigationMode) tea.Cmd {
	ctx := context.Background()

	mm.mutex.Lock()
	defer mm.mutex.Unlock()

	// Log mode switch attempt
	mm.logger.Info("Attempting mode switch",
		zap.String("from_mode", mm.currentMode.String()),
		zap.String("to_mode", targetMode.String()),
		zap.String("operation", "mode_switch"))

	if targetMode == mm.currentMode {
		mm.logger.Debug("Mode switch skipped - already in target mode",
			zap.String("mode", targetMode.String()))
		return nil
	}

	// Update metrics
	mm.updateMetrics("transition_attempt", targetMode)

	// Check if circuit breaker allows the operation
	if err := mm.circuitBreaker.Call(func() error {
		return mm.validateModeTransition(targetMode)
	}); err != nil {
		mm.errorManager.ProcessError(ctx, err, "mode_switch", "circuit_breaker_check", &ErrorHooks{
			OnError: func(err error) {
				mm.logger.Error("Circuit breaker blocked mode transition",
					zap.Error(err),
					zap.String("target_mode", targetMode.String()))
				mm.updateMetrics("circuit_breaker_block", targetMode)
			},
		})

		return func() tea.Msg {
			return ModeErrorMsg{
				Mode:  targetMode,
				Error: fmt.Errorf("circuit breaker blocked mode transition: %w", err),
			}
		}
	}

	_, exists := mm.modes[mm.currentMode]
	if !exists {
		err := fmt.Errorf("current mode configuration not found: %s", mm.currentMode.String())
		mm.errorManager.ProcessError(ctx, err, "mode_switch", "current_mode_validation", &ErrorHooks{
			OnError: func(err error) {
				mm.updateMetrics("validation_error", mm.currentMode)
			},
		})

		return func() tea.Msg {
			return ModeErrorMsg{
				Mode:  mm.currentMode,
				Error: err,
			}
		}
	}
	targetConfig, exists := mm.modes[targetMode]
	if !exists || !targetConfig.Enabled {
		err := fmt.Errorf("target mode not available or disabled: %s", targetMode.String())
		mm.errorManager.ProcessError(ctx, err, "mode_switch", "target_mode_validation", &ErrorHooks{
			OnError: func(err error) {
				mm.updateMetrics("validation_error", targetMode)
			},
		})

		return func() tea.Msg {
			return ModeErrorMsg{
				Mode:  targetMode,
				Error: err,
			}
		}
	}

	// Save current mode state with error handling
	currentState, err := mm.captureCurrentStateWithError()
	if err != nil {
		mm.errorManager.ProcessError(ctx, err, "mode_switch", "state_capture", &ErrorHooks{
			OnError: func(err error) {
				mm.logger.Warn("Failed to capture current state, proceeding with transition",
					zap.Error(err),
					zap.String("current_mode", mm.currentMode.String()))
			},
		})
	} else {
		mm.stateHistory[mm.currentMode] = currentState
		mm.updateMetrics("state_preserved", mm.currentMode)
	}

	// Create transition
	transition := ModeTransition{
		FromMode:      mm.currentMode,
		ToMode:        targetMode,
		TriggerType:   TransitionTriggerUser,
		PreserveState: mm.preferences.PreserveStateAcrossModes,
		AnimationType: mm.getTransitionAnimation(mm.currentMode, targetMode),
		Duration:      mm.preferences.ModeTransitionSpeed,
		Timestamp:     time.Now(),
	}

	// Add to queue
	mm.transitionQueue = append(mm.transitionQueue, transition)

	previousMode := mm.currentMode
	mm.currentMode = targetMode

	// Log successful mode switch
	mm.logger.Info("Mode switch completed successfully",
		zap.String("from_mode", previousMode.String()),
		zap.String("to_mode", targetMode.String()),
		zap.Bool("state_preserved", transition.PreserveState))

	// Update metrics
	mm.updateMetrics("transition_success", targetMode)

	// Get preserved state if available
	var preservedState *ModeState
	if savedState, exists := mm.stateHistory[targetMode]; exists && transition.PreserveState {
		preservedState = savedState
		preservedState.LastActivated = time.Now()
		preservedState.ActivationCount++
		mm.logger.Debug("Restored preserved state for target mode",
			zap.String("mode", targetMode.String()),
			zap.Int("activation_count", preservedState.ActivationCount))
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

// SwitchModeAdvanced provides enhanced mode switching with advanced state preservation and ErrorManager integration
func (mm *ModeManager) SwitchModeAdvanced(targetMode NavigationMode, options *TransitionOptions) tea.Cmd {
	ctx := context.Background()

	mm.mutex.Lock()
	defer mm.mutex.Unlock()

	// Log advanced mode switch attempt
	mm.logger.Info("Attempting advanced mode switch",
		zap.String("from_mode", mm.currentMode.String()),
		zap.String("to_mode", targetMode.String()),
		zap.String("trigger", string(options.Trigger)),
		zap.Bool("preserve_state", options.PreserveState),
		zap.String("operation", "advanced_mode_switch"))

	if mm.currentMode == targetMode {
		mm.logger.Debug("Advanced mode switch skipped - already in target mode",
			zap.String("mode", targetMode.String()))
		return nil
	}

	// Update metrics
	mm.updateMetrics("transition_attempt", targetMode)

	// Check if circuit breaker allows the operation
	if err := mm.circuitBreaker.Call(func() error {
		return mm.validateModeTransition(targetMode)
	}); err != nil {
		mm.errorManager.ProcessError(ctx, err, "advanced_mode_switch", "circuit_breaker_check", &ErrorHooks{
			OnError: func(err error) {
				mm.logger.Error("Circuit breaker blocked advanced mode transition",
					zap.Error(err),
					zap.String("target_mode", targetMode.String()))
				mm.updateMetrics("circuit_breaker_block", targetMode)
			},
		})

		return func() tea.Msg {
			return ModeErrorMsg{
				Mode:  targetMode,
				Error: fmt.Errorf("circuit breaker blocked advanced mode transition: %w", err),
			}
		}
	}

	// Validate target mode
	if _, exists := mm.modes[targetMode]; !exists {
		err := fmt.Errorf("target mode not configured: %s", targetMode.String())
		mm.errorManager.ProcessError(ctx, err, "advanced_mode_switch", "target_mode_validation", &ErrorHooks{
			OnError: func(err error) {
				mm.updateMetrics("validation_error", targetMode)
			},
		})

		return func() tea.Msg {
			return ModeErrorMsg{
				Mode:  targetMode,
				Error: err,
			}
		}
	}

	// Capture current state with enhanced preservation and error handling
	currentState, err := mm.captureAdvancedModeStateWithError(mm.currentMode)
	if err != nil {
		mm.errorManager.ProcessError(ctx, err, "advanced_mode_switch", "advanced_state_capture", &ErrorHooks{
			OnError: func(err error) {
				mm.logger.Warn("Failed to capture advanced state, using basic capture",
					zap.Error(err),
					zap.String("current_mode", mm.currentMode.String()))
			},
		})
		// Fallback to basic state capture
		if fallbackState, fallbackErr := mm.captureCurrentStateWithError(); fallbackErr == nil {
			currentState = fallbackState
		}
	}

	if currentState != nil {
		mm.stateHistory[mm.currentMode] = currentState
		mm.updateMetrics("state_preserved", mm.currentMode)
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

	// Log successful advanced mode switch
	mm.logger.Info("Advanced mode switch completed successfully",
		zap.String("from_mode", previousMode.String()),
		zap.String("to_mode", targetMode.String()),
		zap.Bool("state_preserved", transition.PreserveState),
		zap.String("animation", transition.AnimationType))

	// Update metrics
	mm.updateMetrics("transition_success", targetMode)

	// Get preserved state with advanced restoration
	var preservedState *ModeState
	if savedState, exists := mm.stateHistory[targetMode]; exists && transition.PreserveState {
		preservedState = mm.enhanceStateRestoration(savedState, targetMode)
		if preservedState != nil {
			mm.logger.Debug("Enhanced state restoration completed",
				zap.String("mode", targetMode.String()),
				zap.Int("activation_count", preservedState.ActivationCount))
		}
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

// GetModeState returns the current state for a mode with ErrorManager integration
func (mm *ModeManager) GetModeState(mode NavigationMode) (*ModeState, error) {
	ctx := context.Background()

	mm.mutex.RLock()
	defer mm.mutex.RUnlock()

	mm.logger.Debug("Getting mode state",
		zap.String("requested_mode", mode.String()),
		zap.String("current_mode", mm.currentMode.String()),
		zap.String("operation", "get_mode_state"))

	if mode == mm.currentMode {
		// Return current state with error handling
		state, err := mm.captureCurrentStateWithError()
		if err != nil {
			mm.errorManager.ProcessError(ctx, err, "get_mode_state", "current_state_capture", &ErrorHooks{
				OnError: func(err error) {
					mm.logger.Error("Failed to capture current state",
						zap.Error(err),
						zap.String("mode", mode.String()))
				},
			})
			return nil, fmt.Errorf("failed to capture current state for mode %s: %w", mode.String(), err)
		}

		mm.logger.Debug("Current mode state captured successfully",
			zap.String("mode", mode.String()))
		return state, nil
	}

	// Return saved state
	state, exists := mm.stateHistory[mode]
	if !exists {
		err := fmt.Errorf("no saved state for mode: %s", mode.String())
		mm.errorManager.ProcessError(ctx, err, "get_mode_state", "saved_state_lookup", &ErrorHooks{
			OnError: func(err error) {
				mm.logger.Warn("No saved state found for mode",
					zap.String("mode", mode.String()))
			},
		})
		return nil, err
	}

	mm.logger.Debug("Saved mode state retrieved successfully",
		zap.String("mode", mode.String()),
		zap.Time("last_activated", state.LastActivated),
		zap.Int("activation_count", state.ActivationCount))

	return state, nil
}

// RestoreState restores a saved state for the current mode with ErrorManager integration
func (mm *ModeManager) RestoreState(state *ModeState) tea.Cmd {
	ctx := context.Background()

	mm.mutex.Lock()
	defer mm.mutex.Unlock()

	mm.logger.Debug("Restoring mode state",
		zap.String("current_mode", mm.currentMode.String()),
		zap.String("operation", "restore_state"))

	if state == nil {
		err := fmt.Errorf("cannot restore nil state")
		mm.errorManager.ProcessError(ctx, err, "restore_state", "state_validation", &ErrorHooks{
			OnError: func(err error) {
				mm.logger.Error("Attempted to restore nil state",
					zap.String("current_mode", mm.currentMode.String()))
			},
		})
		return nil
	}

	// Validate state integrity
	if state.Mode.String() == "" {
		err := fmt.Errorf("invalid state: empty mode")
		mm.errorManager.ProcessError(ctx, err, "restore_state", "state_integrity_check", &ErrorHooks{
			OnError: func(err error) {
				mm.logger.Error("State integrity check failed",
					zap.Error(err),
					zap.String("current_mode", mm.currentMode.String()))
			},
		})
		return func() tea.Msg {
			return ModeErrorMsg{
				Mode:  mm.currentMode,
				Error: err,
			}
		}
	}

	// Check circuit breaker before restoration
	if err := mm.circuitBreaker.Call(func() error {
		return nil // State restoration is generally safe
	}); err != nil {
		mm.errorManager.ProcessError(ctx, err, "restore_state", "circuit_breaker_check", &ErrorHooks{
			OnError: func(err error) {
				mm.logger.Error("Circuit breaker blocked state restoration",
					zap.Error(err),
					zap.String("current_mode", mm.currentMode.String()))
			},
		})
		return func() tea.Msg {
			return ModeErrorMsg{
				Mode:  mm.currentMode,
				Error: fmt.Errorf("circuit breaker blocked state restoration: %w", err),
			}
		}
	}

	// Update current mode state
	mm.stateHistory[mm.currentMode] = state

	// Update metrics
	mm.updateMetrics("state_restored", mm.currentMode)

	mm.logger.Info("Mode state restored successfully",
		zap.String("mode", mm.currentMode.String()),
		zap.String("restored_mode", state.Mode.String()),
		zap.Time("last_activated", state.LastActivated))

	return func() tea.Msg {
		return ModeStateUpdatedMsg{
			Mode:  mm.currentMode,
			State: state,
		}
	}
}

// AddEventHandler adds an event handler for a specific mode with ErrorManager integration
func (mm *ModeManager) AddEventHandler(mode NavigationMode, handler ModeEventHandler) error {
	ctx := context.Background()

	mm.mutex.Lock()
	defer mm.mutex.Unlock()

	mm.logger.Debug("Adding event handler",
		zap.String("mode", mode.String()),
		zap.String("operation", "add_event_handler"))

	if handler == nil {
		err := fmt.Errorf("cannot add nil event handler for mode: %s", mode.String())
		mm.errorManager.ProcessError(ctx, err, "add_event_handler", "handler_validation", &ErrorHooks{
			OnError: func(err error) {
				mm.logger.Error("Attempted to add nil event handler",
					zap.String("mode", mode.String()))
			},
		})
		return err
	}

	// Validate that the mode exists
	if _, exists := mm.modes[mode]; !exists {
		err := fmt.Errorf("cannot add event handler for non-existent mode: %s", mode.String())
		mm.errorManager.ProcessError(ctx, err, "add_event_handler", "mode_validation", &ErrorHooks{
			OnError: func(err error) {
				mm.logger.Error("Attempted to add handler for non-existent mode",
					zap.String("mode", mode.String()))
			},
		})
		return err
	}

	// Initialize handlers slice if needed
	if mm.eventHandlers[mode] == nil {
		mm.eventHandlers[mode] = make([]ModeEventHandler, 0)
	}

	// Add the handler
	mm.eventHandlers[mode] = append(mm.eventHandlers[mode], handler)

	mm.logger.Info("Event handler added successfully",
		zap.String("mode", mode.String()),
		zap.Int("total_handlers", len(mm.eventHandlers[mode])))

	return nil
}

// TriggerEvent triggers an event for the current mode with ErrorManager integration
func (mm *ModeManager) TriggerEvent(eventType ModeEventType, data map[string]interface{}) []tea.Cmd {
	ctx := context.Background()

	mm.mutex.RLock()
	defer mm.mutex.RUnlock()

	mm.logger.Debug("Triggering mode event",
		zap.String("current_mode", mm.currentMode.String()),
		zap.Int("event_type", int(eventType)),
		zap.String("operation", "trigger_event"))

	// Check circuit breaker before processing events
	if err := mm.circuitBreaker.Call(func() error {
		return nil // Event triggering is generally safe
	}); err != nil {
		mm.errorManager.ProcessError(ctx, err, "trigger_event", "circuit_breaker_check", &ErrorHooks{
			OnError: func(err error) {
				mm.logger.Error("Circuit breaker blocked event triggering",
					zap.Error(err),
					zap.String("current_mode", mm.currentMode.String()),
					zap.Int("event_type", int(eventType)))
			},
		})
		return nil
	}

	// Create event
	event := ModeEvent{
		Type:      eventType,
		Mode:      mm.currentMode,
		Data:      data,
		Timestamp: time.Now(),
		Source:    "mode_manager",
	}

	var commands []tea.Cmd
	handlers := mm.eventHandlers[mm.currentMode]

	if len(handlers) == 0 {
		mm.logger.Debug("No event handlers registered for current mode",
			zap.String("mode", mm.currentMode.String()),
			zap.Int("event_type", int(eventType)))
		return commands
	}

	// Execute handlers with error recovery
	handlersExecuted := 0
	handlersFailed := 0

	for i, handler := range handlers {
		func() {
			defer func() {
				if r := recover(); r != nil {
					handlersFailed++
					err := fmt.Errorf("event handler panic: %v", r)
					mm.errorManager.ProcessError(ctx, err, "trigger_event", "handler_execution", &ErrorHooks{
						OnError: func(err error) {
							mm.logger.Error("Event handler panicked",
								zap.Error(err),
								zap.String("mode", mm.currentMode.String()),
								zap.Int("handler_index", i),
								zap.Int("event_type", int(eventType)))
						},
					})
				}
			}()

			if cmd := handler(event); cmd != nil {
				commands = append(commands, cmd)
				handlersExecuted++
			}
		}()
	}

	// Log execution results
	if handlersFailed > 0 {
		mm.logger.Warn("Some event handlers failed during execution",
			zap.String("mode", mm.currentMode.String()),
			zap.Int("event_type", int(eventType)),
			zap.Int("handlers_executed", handlersExecuted),
			zap.Int("handlers_failed", handlersFailed),
			zap.Int("total_handlers", len(handlers)))
	} else {
		mm.logger.Debug("Event handlers executed successfully",
			zap.String("mode", mm.currentMode.String()),
			zap.Int("event_type", int(eventType)),
			zap.Int("handlers_executed", handlersExecuted),
			zap.Int("commands_generated", len(commands)))
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
			"j":      "navigate_down",
			"k":      "navigate_up",
			"h":      "navigate_left",
			"l":      "navigate_right",
			"gg":     "go_to_top",
			"G":      "go_to_bottom",
			"ctrl+d": "page_down",
			"ctrl+u": "page_up",
			"w":      "next_word",
			"b":      "previous_word",
			"0":      "line_start",
			"$":      "line_end",
			"/":      "search",
			"n":      "next_search",
			"N":      "previous_search",
			"i":      "insert_mode",
			"a":      "append_mode",
			"v":      "visual_mode",
			"dd":     "delete_line",
			"yy":     "yank_line",
			"p":      "paste",
			"u":      "undo",
			"ctrl+r": "redo",
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
			"high_contrast":    true,
			"screen_reader":    true,
			"keyboard_only":    true,
			"reduced_motion":   true,
			"focus_indicators": true,
			"audio_feedback":   true,
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
		Position:        Position{},   // Will be filled by actual position
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
		DefaultMode:              NavigationModeNormal,
		AutoSwitchModes:          false,
		PreserveStateAcrossModes: true,
		ModeTransitionSpeed:      300 * time.Millisecond,
		EnabledModes: map[NavigationMode]bool{
			NavigationModeNormal:        true,
			NavigationModeVim:           true,
			NavigationModeAccessibility: true,
			NavigationModeCustom:        false,
		},
		CustomModeSettings: make(map[NavigationMode]ModeConfig),
		KeyboardShortcuts: map[string]NavigationMode{
			"F1": NavigationModeNormal,
			"F2": NavigationModeVim,
			"F3": NavigationModeAccessibility,
			"F4": NavigationModeCustom,
		},
	}
}

// captureAdvancedModeState captures detailed state information for advanced preservation
func (mm *ModeManager) captureAdvancedModeState(mode NavigationMode) *ModeState {
	_, exists := mm.modes[mode]
	if !exists {
		return nil
	}

	state := &ModeState{
		Mode:            mode,
		Position:        Position{},   // Will be populated by caller
		ViewMode:        ViewModeList, // Will be populated by caller
		FocusedElements: make([]string, 0),
		SelectionState:  SelectionState{},
		FilterState:     FilterState{},
		ScrollPosition:  ScrollPosition{},
		LayoutState:     LayoutState{},
		CustomData:      make(map[string]interface{}),
		LastActivated:   time.Now(),
		ActivationCount: 1,
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
func (mm *ModeManager) getKanbanColumns() interface{}         { return nil }
func (mm *ModeManager) getKanbanCardPositions() interface{}   { return nil }
func (mm *ModeManager) getKanbanColumnWidths() interface{}    { return nil }
func (mm *ModeManager) getMatrixDimensions() interface{}      { return nil }
func (mm *ModeManager) getMatrixFocusedCell() interface{}     { return nil }
func (mm *ModeManager) getMatrixZoomLevel() interface{}       { return nil }
func (mm *ModeManager) getExpandedNodes() interface{}         { return nil }
func (mm *ModeManager) getCurrentTreeDepth() interface{}      { return nil }
func (mm *ModeManager) getCollapsedBranches() interface{}     { return nil }
func (mm *ModeManager) getCurrentSearchQuery() interface{}    { return nil }
func (mm *ModeManager) getActiveSearchFilters() interface{}   { return nil }
func (mm *ModeManager) getSearchResultsMetadata() interface{} { return nil }
func (mm *ModeManager) getFocusTarget() interface{}           { return nil }
func (mm *ModeManager) getFocusZoomLevel() interface{}        { return nil }
func (mm *ModeManager) getFocusContextItems() interface{}     { return nil }
func (mm *ModeManager) getGenericLayoutState() interface{}    { return nil }
func (mm *ModeManager) getSearchFilters() interface{}         { return nil }
func (mm *ModeManager) getSearchResultsCount() interface{}    { return nil }
func (mm *ModeManager) getFocusedItem() interface{}           { return nil }
func (mm *ModeManager) getFocusLevel() interface{}            { return nil }
func (mm *ModeManager) getFocusContext() interface{}          { return nil }
func (mm *ModeManager) getGenericContext() interface{}        { return nil }

func (mm *ModeManager) validateAndRestoreKanbanColumns(columns interface{})       {}
func (mm *ModeManager) validateAndRestoreMatrixDimensions(dimensions interface{}) {}
func (mm *ModeManager) validateAndRestoreExpandedNodes(nodes interface{})         {}
func (mm *ModeManager) validateAndRestoreSearchQuery(query interface{})           {}
func (mm *ModeManager) validateAndRestoreFocusTarget(target interface{})          {}

// ProcessError handles and catalogs errors with ErrorManager integration
func (em *ErrorManager) ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error {
	if err == nil {
		return nil
	}

	// Generate unique error ID
	errorID := uuid.New().String()

	// Determine error severity
	severity := determineSeverity(err)
	// Create error entry for cataloging
	errorEntry := ErrorEntry{
		ID:             errorID,
		Timestamp:      time.Now(),
		Message:        err.Error(),
		StackTrace:     fmt.Sprintf("%+v", err),
		Module:         "mode-manager",
		ErrorCode:      generateErrorCode(component, operation),
		ManagerContext: fmt.Sprintf("component=%s, operation=%s", component, operation),
		Severity:       severity,
	}

	// Validate error entry
	if validationErr := ValidateErrorEntry(errorEntry); validationErr != nil {
		em.logger.Error("Error entry validation failed",
			zap.Error(validationErr),
			zap.String("error_id", errorID))
		return validationErr
	}

	// Catalog the error
	if catalogErr := CatalogError(errorEntry); catalogErr != nil {
		em.logger.Error("Failed to catalog error",
			zap.Error(catalogErr),
			zap.String("error_id", errorID))
	}

	// Execute error hooks if provided
	if hooks != nil && hooks.OnError != nil {
		hooks.OnError(err)
	}

	// Log structured error information
	em.logger.Error("Mode Manager error processed",
		zap.String("error_id", errorID),
		zap.String("component", component),
		zap.String("operation", operation),
		zap.String("severity", severity),
		zap.Error(err))

	return err
}

// determineSeverity analyzes the error to determine its severity level
func determineSeverity(err error) string {
	errorMsg := err.Error()

	// Critical errors
	if contains(errorMsg, []string{"panic", "fatal", "critical", "system", "memory"}) {
		return "CRITICAL"
	}

	// High severity errors
	if contains(errorMsg, []string{"failed", "timeout", "connection", "invalid", "corrupted"}) {
		return "HIGH"
	}

	// Medium severity errors
	if contains(errorMsg, []string{"warning", "deprecated", "retry", "temporary"}) {
		return "MEDIUM"
	}

	// Default to low for other errors
	return "LOW"
}

// generateErrorCode creates a structured error code for the mode manager
func generateErrorCode(component, operation string) string {
	timestamp := time.Now().Format("060102150405")
	return fmt.Sprintf("MODE_%s_%s_%s", component, operation, timestamp)
}

// contains checks if any of the keywords exist in the string
func contains(str string, keywords []string) bool {
	for _, keyword := range keywords {
		if len(str) >= len(keyword) {
			for i := 0; i <= len(str)-len(keyword); i++ {
				if str[i:i+len(keyword)] == keyword {
					return true
				}
			}
		}
	}
	return false
}

// validateModeTransition validates if a mode transition is allowed
func (mm *ModeManager) validateModeTransition(targetMode NavigationMode) error {
	// Check if target mode exists
	targetConfig, exists := mm.modes[targetMode]
	if !exists {
		return fmt.Errorf("target mode does not exist: %s", targetMode.String())
	}

	// Check if target mode is enabled
	if !targetConfig.Enabled {
		return fmt.Errorf("target mode is disabled: %s", targetMode.String())
	}

	// Check if current mode allows transitions to target mode
	currentConfig, exists := mm.modes[mm.currentMode]
	if exists && currentConfig.Transitions != nil {
		if transitionType, allowed := currentConfig.Transitions[targetMode]; !allowed {
			return fmt.Errorf("transition not allowed from %s to %s", mm.currentMode.String(), targetMode.String())
		} else if transitionType == "blocked" {
			return fmt.Errorf("transition blocked from %s to %s", mm.currentMode.String(), targetMode.String())
		}
	}

	return nil
}

// captureCurrentStateWithError captures current state with error handling
func (mm *ModeManager) captureCurrentStateWithError() (*ModeState, error) {
	defer func() {
		if r := recover(); r != nil {
			mm.logger.Error("Panic during state capture",
				zap.Any("panic", r),
				zap.String("mode", mm.currentMode.String()))
		}
	}()

	state := &ModeState{
		Mode:            mm.currentMode,
		Position:        Position{},   // Will be filled by actual position
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

	// Validate captured state
	if state.Mode.String() == "" {
		return nil, fmt.Errorf("invalid mode in captured state")
	}

	return state, nil
}

// updateMetrics updates internal metrics for the mode manager
func (mm *ModeManager) updateMetrics(operation string, mode NavigationMode) {
	mm.metrics.mu.Lock()
	defer mm.metrics.mu.Unlock()

	switch operation {
	case "transition_attempt":
		mm.metrics.TotalTransitions++
		mm.metrics.TransitionCounts[mode]++
	case "transition_success":
		// Update average transition time (simplified calculation)
		mm.metrics.AverageTransition = time.Millisecond * 100 // Placeholder
	case "state_preserved", "state_restored":
		mm.metrics.StatePreservations++
	case "validation_error", "circuit_breaker_block":
		mm.metrics.FailedTransitions++
		mm.metrics.ErrorCounts[operation]++
	default:
		// Handle other operation types
		mm.metrics.ErrorCounts[operation]++
	}
}

// GetMetrics returns current metrics for the mode manager
func (mm *ModeManager) GetMetrics() *ModeMetrics {
	mm.metrics.mu.RLock()
	defer mm.metrics.mu.RUnlock()

	// Create a copy to avoid race conditions
	metricsCopy := &ModeMetrics{
		TotalTransitions:   mm.metrics.TotalTransitions,
		TransitionCounts:   make(map[NavigationMode]int),
		ErrorCounts:        make(map[string]int),
		AverageTransition:  mm.metrics.AverageTransition,
		StatePreservations: mm.metrics.StatePreservations,
		FailedTransitions:  mm.metrics.FailedTransitions,
		LastMetricsReset:   mm.metrics.LastMetricsReset,
	}

	// Copy maps to avoid race conditions
	for mode, count := range mm.metrics.TransitionCounts {
		metricsCopy.TransitionCounts[mode] = count
	}
	for errorType, count := range mm.metrics.ErrorCounts {
		metricsCopy.ErrorCounts[errorType] = count
	}

	return metricsCopy
}

// ResetMetrics resets all metrics counters
func (mm *ModeManager) ResetMetrics() {
	mm.metrics.mu.Lock()
	defer mm.metrics.mu.Unlock()

	mm.metrics.TotalTransitions = 0
	mm.metrics.TransitionCounts = make(map[NavigationMode]int)
	mm.metrics.ErrorCounts = make(map[string]int)
	mm.metrics.AverageTransition = 0
	mm.metrics.StatePreservations = 0
	mm.metrics.FailedTransitions = 0
	mm.metrics.LastMetricsReset = time.Now()

	mm.logger.Info("Mode Manager metrics reset",
		zap.String("component", "mode-manager"),
		zap.Time("reset_time", mm.metrics.LastMetricsReset))
}

// captureAdvancedModeStateWithError captures detailed state information with error handling
func (mm *ModeManager) captureAdvancedModeStateWithError(mode NavigationMode) (*ModeState, error) {
	defer func() {
		if r := recover(); r != nil {
			mm.logger.Error("Panic during advanced state capture",
				zap.Any("panic", r),
				zap.String("mode", mode.String()))
		}
	}()

	_, exists := mm.modes[mode]
	if !exists {
		return nil, fmt.Errorf("mode configuration not found for advanced state capture: %s", mode.String())
	}

	state := &ModeState{
		Mode:            mode,
		Position:        Position{},   // Will be populated by caller
		ViewMode:        ViewModeList, // Will be populated by caller
		FocusedElements: make([]string, 0),
		SelectionState:  SelectionState{},
		FilterState:     FilterState{},
		ScrollPosition:  ScrollPosition{},
		LayoutState:     LayoutState{},
		CustomData:      make(map[string]interface{}),
		LastActivated:   time.Now(),
		ActivationCount: 1,
	}

	// Enhanced state capture based on mode type with error handling
	switch mode {
	case NavigationModeKanban:
		if err := mm.captureKanbanStateWithError(state); err != nil {
			mm.logger.Warn("Failed to capture Kanban-specific state",
				zap.Error(err),
				zap.String("mode", mode.String()))
		}
	case NavigationModeMatrix:
		if err := mm.captureMatrixStateWithError(state); err != nil {
			mm.logger.Warn("Failed to capture Matrix-specific state",
				zap.Error(err),
				zap.String("mode", mode.String()))
		}
	case NavigationModeHierarchical:
		if err := mm.captureHierarchicalStateWithError(state); err != nil {
			mm.logger.Warn("Failed to capture Hierarchical-specific state",
				zap.Error(err),
				zap.String("mode", mode.String()))
		}
	case NavigationModeSearch:
		if err := mm.captureSearchStateWithError(state); err != nil {
			mm.logger.Warn("Failed to capture Search-specific state",
				zap.Error(err),
				zap.String("mode", mode.String()))
		}
	case NavigationModeFocus:
		if err := mm.captureFocusStateWithError(state); err != nil {
			mm.logger.Warn("Failed to capture Focus-specific state",
				zap.Error(err),
				zap.String("mode", mode.String()))
		}
	default:
		if err := mm.captureGenericStateWithError(state); err != nil {
			mm.logger.Warn("Failed to capture generic state",
				zap.Error(err),
				zap.String("mode", mode.String()))
		}
	}

	// Validate captured state
	if state.Mode.String() == "" {
		return nil, fmt.Errorf("invalid mode in captured advanced state")
	}

	mm.logger.Debug("Advanced state captured successfully",
		zap.String("mode", mode.String()),
		zap.Time("timestamp", state.LastActivated))

	return state, nil
}

// Mode-specific state capture methods with error handling
func (mm *ModeManager) captureKanbanStateWithError(state *ModeState) error {
	defer func() {
		if r := recover(); r != nil {
			mm.logger.Error("Panic in Kanban state capture", zap.Any("panic", r))
		}
	}()

	// Kanban-specific state capture logic with error handling
	state.CustomData["kanban_columns"] = mm.getKanbanColumns()
	state.CustomData["kanban_card_positions"] = mm.getKanbanCardPositions()
	state.CustomData["kanban_column_widths"] = mm.getKanbanColumnWidths()

	return nil
}

func (mm *ModeManager) captureMatrixStateWithError(state *ModeState) error {
	defer func() {
		if r := recover(); r != nil {
			mm.logger.Error("Panic in Matrix state capture", zap.Any("panic", r))
		}
	}()

	// Matrix-specific state capture logic with error handling
	state.CustomData["matrix_dimensions"] = mm.getMatrixDimensions()
	state.CustomData["matrix_focused_cell"] = mm.getMatrixFocusedCell()
	state.CustomData["matrix_zoom_level"] = mm.getMatrixZoomLevel()

	return nil
}

func (mm *ModeManager) captureHierarchicalStateWithError(state *ModeState) error {
	defer func() {
		if r := recover(); r != nil {
			mm.logger.Error("Panic in Hierarchical state capture", zap.Any("panic", r))
		}
	}()

	// Hierarchical-specific state capture logic with error handling
	state.CustomData["expanded_nodes"] = mm.getExpandedNodes()
	state.CustomData["current_tree_depth"] = mm.getCurrentTreeDepth()
	state.CustomData["collapsed_branches"] = mm.getCollapsedBranches()

	return nil
}

func (mm *ModeManager) captureSearchStateWithError(state *ModeState) error {
	defer func() {
		if r := recover(); r != nil {
			mm.logger.Error("Panic in Search state capture", zap.Any("panic", r))
		}
	}()

	// Search-specific state capture logic with error handling
	state.CustomData["current_search_query"] = mm.getCurrentSearchQuery()
	state.CustomData["search_filters"] = mm.getSearchFilters()
	state.CustomData["search_results_count"] = mm.getSearchResultsCount()

	return nil
}

func (mm *ModeManager) captureFocusStateWithError(state *ModeState) error {
	defer func() {
		if r := recover(); r != nil {
			mm.logger.Error("Panic in Focus state capture", zap.Any("panic", r))
		}
	}()

	// Focus-specific state capture logic with error handling
	state.CustomData["focused_item"] = mm.getFocusedItem()
	state.CustomData["focus_level"] = mm.getFocusLevel()
	state.CustomData["focus_context"] = mm.getFocusContext()

	return nil
}

func (mm *ModeManager) captureGenericStateWithError(state *ModeState) error {
	defer func() {
		if r := recover(); r != nil {
			mm.logger.Error("Panic in Generic state capture", zap.Any("panic", r))
		}
	}()

	// Generic state capture logic with error handling
	state.CustomData["generic_context"] = mm.getGenericContext()

	return nil
}
