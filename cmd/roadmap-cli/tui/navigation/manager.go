package navigation

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"sync"
	"time"

	tea "github.com/charmbracelet/bubbletea"
)

// NavigationManager manages navigation state and operations
type NavigationManager struct {
	state           *NavigationState
	configDir       string
	eventListeners  []func(NavigationEvent)
	commands        chan NavigationCommand
	mutex           sync.RWMutex
	ctx             context.Context
	cancel          context.CancelFunc
	isInitialized   bool
	analytics       *NavigationAnalytics
	transitions     map[string]ViewTransition
	keyMappings     map[string][]KeyMappingRule
}

// NavigationAnalytics tracks navigation usage patterns
type NavigationAnalytics struct {
	ViewUsage          map[ViewMode]int       `json:"view_usage"`
	NavigationPatterns map[string]int         `json:"navigation_patterns"`
	AverageSessionTime time.Duration          `json:"average_session_time"`
	MostUsedBookmarks  []string               `json:"most_used_bookmarks"`
	KeyboardShortcuts  map[string]int         `json:"keyboard_shortcuts"`
	ErrorFrequency     map[string]int         `json:"error_frequency"`
	LastAnalysis       time.Time              `json:"last_analysis"`
	TotalSessions      int                    `json:"total_sessions"`
	TotalCommands      int                    `json:"total_commands"`
}

// NewNavigationManager creates a new navigation manager
func NewNavigationManager(configDir string) *NavigationManager {
	ctx, cancel := context.WithCancel(context.Background())
	
	return &NavigationManager{
		state:          NewNavigationState(),
		configDir:      configDir,
		eventListeners: make([]func(NavigationEvent), 0),
		commands:       make(chan NavigationCommand, 100),
		ctx:            ctx,
		cancel:         cancel,
		isInitialized:  false,
		analytics:      NewNavigationAnalytics(),
		transitions:    make(map[string]ViewTransition),
		keyMappings:    make(map[string][]KeyMappingRule),
	}
}

// Initialize initializes the navigation manager
func (nm *NavigationManager) Initialize() error {
	nm.mutex.Lock()
	defer nm.mutex.Unlock()

	if nm.isInitialized {
		return nil
	}

	// Ensure config directory exists
	if err := os.MkdirAll(nm.configDir, 0755); err != nil {
		return fmt.Errorf("failed to create config directory: %w", err)
	}

	// Load saved state
	if err := nm.loadState(); err != nil {
		// Create default state if loading fails
		nm.state = NewNavigationState()
	}

	// Load transitions
	if err := nm.loadTransitions(); err != nil {
		nm.setDefaultTransitions()
	}

	// Load key mappings
	if err := nm.loadKeyMappings(); err != nil {
		nm.setDefaultKeyMappings()
	}

	// Start command processor
	go nm.processCommands()

	nm.isInitialized = true
	return nil
}

// Shutdown gracefully shuts down the navigation manager
func (nm *NavigationManager) Shutdown() error {
	nm.mutex.Lock()
	defer nm.mutex.Unlock()

	if !nm.isInitialized {
		return nil
	}

	// Cancel context to stop command processor
	nm.cancel()

	// Save current state
	if err := nm.saveState(); err != nil {
		return fmt.Errorf("failed to save navigation state: %w", err)
	}

	// Save analytics
	if err := nm.saveAnalytics(); err != nil {
		return fmt.Errorf("failed to save analytics: %w", err)
	}

	nm.isInitialized = false
	return nil
}

// GetState returns the current navigation state (thread-safe)
func (nm *NavigationManager) GetState() NavigationState {
	nm.mutex.RLock()
	defer nm.mutex.RUnlock()
	return *nm.state
}

// SetNavigationMode sets the navigation mode
func (nm *NavigationManager) SetNavigationMode(mode NavigationMode) tea.Cmd {
	nm.mutex.Lock()
	defer nm.mutex.Unlock()

	oldMode := nm.state.CurrentMode
	nm.state.CurrentMode = mode
	nm.state.LastUpdated = time.Now()

	nm.trackAnalytics("navigation_mode_change", map[string]interface{}{
		"old_mode": oldMode.String(),
		"new_mode": mode.String(),
	})

	return func() tea.Msg {
		return NavigationModeChangedMsg{
			OldMode: oldMode,
			NewMode: mode,
		}
	}
}

// SetViewMode sets the view mode with transition
func (nm *NavigationManager) SetViewMode(viewMode ViewMode) tea.Cmd {
	nm.mutex.Lock()
	defer nm.mutex.Unlock()

	oldView := nm.state.CurrentView
	if oldView == viewMode {
		return nil
	}

	// Check if transition is allowed
	transitionKey := fmt.Sprintf("%s_to_%s", oldView.String(), viewMode.String())
	transition, exists := nm.transitions[transitionKey]

	if !exists {
		// Use default transition
		transition = ViewTransition{
			FromView:       oldView,
			ToView:         viewMode,
			AnimationType:  "fade",
			Duration:       300 * time.Millisecond,
			Easing:         "ease-in-out",
			PreserveState:  true,
		}
	}

	// Start transition
	nm.state.TransitionState = TransitionState{
		IsTransitioning: true,
		FromView:        oldView,
		ToView:          viewMode,
		Progress:        0.0,
		StartTime:       time.Now(),
		Duration:        transition.Duration,
		AnimationType:   transition.AnimationType,
	}

	// Add to history
	nm.addToHistory(NavigationHistoryItem{
		ID:          fmt.Sprintf("view_%d", time.Now().Unix()),
		ViewMode:    viewMode,
		Position:    nm.state.Position,
		Description: fmt.Sprintf("Switched to %s view", viewMode.String()),
		Timestamp:   time.Now(),
		Context:     "view_switch",
	})

	nm.trackAnalytics("view_mode_change", map[string]interface{}{
		"old_view": oldView.String(),
		"new_view": viewMode.String(),
		"transition": transition.AnimationType,
	})

	return func() tea.Msg {
		return TransitionStartedMsg{
			FromView: oldView,
			ToView:   viewMode,
		}
	}
}

// CompleteTransition completes the current view transition
func (nm *NavigationManager) CompleteTransition() tea.Cmd {
	nm.mutex.Lock()
	defer nm.mutex.Unlock()

	if !nm.state.TransitionState.IsTransitioning {
		return nil
	}

	fromView := nm.state.TransitionState.FromView
	toView := nm.state.TransitionState.ToView
	duration := time.Since(nm.state.TransitionState.StartTime)

	// Complete transition
	nm.state.CurrentView = toView
	nm.state.TransitionState = TransitionState{}
	nm.state.LastUpdated = time.Now()

	return func() tea.Msg {
		return TransitionCompletedMsg{
			FromView: fromView,
			ToView:   toView,
			Duration: duration,
		}
	}
}

// Navigate handles navigation in a specific direction
func (nm *NavigationManager) Navigate(direction NavigationDirection) tea.Cmd {
	nm.mutex.Lock()
	defer nm.mutex.Unlock()

	oldPosition := nm.state.Position
	newPosition := nm.calculateNewPosition(oldPosition, direction)

	if newPosition == oldPosition {
		return nil // No movement
	}

	nm.state.Position = newPosition
	nm.state.LastUpdated = time.Now()

	nm.trackAnalytics("navigation", map[string]interface{}{
		"direction": direction.String(),
		"view_mode": nm.state.CurrentView.String(),
		"x_delta": newPosition.X - oldPosition.X,
		"y_delta": newPosition.Y - oldPosition.Y,
	})

	return func() tea.Msg {
		return PositionChangedMsg{
			OldPosition: oldPosition,
			NewPosition: newPosition,
		}
	}
}

// CreateBookmark creates a new bookmark at the current position
func (nm *NavigationManager) CreateBookmark(name, description string, tags []string) tea.Cmd {
	nm.mutex.Lock()
	defer nm.mutex.Unlock()

	bookmark := Bookmark{
		ID:          fmt.Sprintf("bookmark_%d", time.Now().Unix()),
		Name:        name,
		Description: description,
		ViewMode:    nm.state.CurrentView,
		Position:    nm.state.Position,
		Tags:        tags,
		CreatedAt:   time.Now(),
		AccessCount: 0,
	}

	nm.state.Bookmarks = append(nm.state.Bookmarks, bookmark)

	// Limit number of bookmarks
	if len(nm.state.Bookmarks) > nm.state.Preferences.BookmarkLimit {
		// Remove oldest bookmark
		nm.state.Bookmarks = nm.state.Bookmarks[1:]
	}

	nm.trackAnalytics("bookmark_created", map[string]interface{}{
		"name": name,
		"view_mode": nm.state.CurrentView.String(),
		"tags_count": len(tags),
	})

	return func() tea.Msg {
		return BookmarkCreatedMsg{Bookmark: bookmark}
	}
}

// JumpToBookmark jumps to a specific bookmark
func (nm *NavigationManager) JumpToBookmark(bookmarkID string) tea.Cmd {
	nm.mutex.Lock()
	defer nm.mutex.Unlock()

	for i, bookmark := range nm.state.Bookmarks {
		if bookmark.ID == bookmarkID {
			oldPosition := nm.state.Position
			oldView := nm.state.CurrentView

			// Update position and view
			nm.state.Position = bookmark.Position
			nm.state.CurrentView = bookmark.ViewMode

			// Update bookmark access stats
			nm.state.Bookmarks[i].AccessCount++
			nm.state.Bookmarks[i].LastAccessed = time.Now()

			nm.trackAnalytics("bookmark_accessed", map[string]interface{}{
				"bookmark_id": bookmarkID,
				"bookmark_name": bookmark.Name,
				"access_count": nm.state.Bookmarks[i].AccessCount,
			})

			return func() tea.Msg {
				return BookmarkAccessedMsg{
					BookmarkID: bookmarkID,
					Position:   bookmark.Position,
				}
			}
		}
	}

	return func() tea.Msg {
		return NavigationErrorMsg{
			Error:   fmt.Errorf("bookmark not found: %s", bookmarkID),
			Context: "jump_to_bookmark",
		}
	}
}

// GetBookmarks returns all bookmarks sorted by access count
func (nm *NavigationManager) GetBookmarks() []Bookmark {
	nm.mutex.RLock()
	defer nm.mutex.RUnlock()

	bookmarks := make([]Bookmark, len(nm.state.Bookmarks))
	copy(bookmarks, nm.state.Bookmarks)

	sort.Slice(bookmarks, func(i, j int) bool {
		return bookmarks[i].AccessCount > bookmarks[j].AccessCount
	})

	return bookmarks
}

// GetHistory returns the navigation history
func (nm *NavigationManager) GetHistory() []NavigationHistoryItem {
	nm.mutex.RLock()
	defer nm.mutex.RUnlock()

	history := make([]NavigationHistoryItem, len(nm.state.History))
	copy(history, nm.state.History)
	return history
}

// GoBack navigates back in history
func (nm *NavigationManager) GoBack() tea.Cmd {
	nm.mutex.Lock()
	defer nm.mutex.Unlock()

	if len(nm.state.History) < 2 {
		return nil
	}

	// Get previous item (skip current position)
	prevItem := nm.state.History[len(nm.state.History)-2]

	oldPosition := nm.state.Position
	oldView := nm.state.CurrentView

	nm.state.Position = prevItem.Position
	nm.state.CurrentView = prevItem.ViewMode

	// Remove current position from history
	nm.state.History = nm.state.History[:len(nm.state.History)-1]

	nm.trackAnalytics("history_back", map[string]interface{}{
		"from_view": oldView.String(),
		"to_view": prevItem.ViewMode.String(),
	})

	return func() tea.Msg {
		return PositionChangedMsg{
			OldPosition: oldPosition,
			NewPosition: prevItem.Position,
		}
	}
}

// SetPreferences updates navigation preferences
func (nm *NavigationManager) SetPreferences(prefs NavigationPreferences) error {
	nm.mutex.Lock()
	defer nm.mutex.Unlock()

	nm.state.Preferences = prefs
	nm.state.LastUpdated = time.Now()

	return nm.saveState()
}

// GetPreferences returns current navigation preferences
func (nm *NavigationManager) GetPreferences() NavigationPreferences {
	nm.mutex.RLock()
	defer nm.mutex.RUnlock()
	return nm.state.Preferences
}

// AddEventListener adds an event listener
func (nm *NavigationManager) AddEventListener(listener func(NavigationEvent)) {
	nm.mutex.Lock()
	defer nm.mutex.Unlock()
	nm.eventListeners = append(nm.eventListeners, listener)
}

// GetAnalytics returns navigation analytics
func (nm *NavigationManager) GetAnalytics() NavigationAnalytics {
	nm.mutex.RLock()
	defer nm.mutex.RUnlock()
	return *nm.analytics
}

// Private helper methods

func (nm *NavigationManager) calculateNewPosition(current Position, direction NavigationDirection) Position {
	newPos := current

	switch direction {
	case DirectionUp:
		if newPos.Y > 0 {
			newPos.Y--
		}
	case DirectionDown:
		newPos.Y++
	case DirectionLeft:
		if newPos.X > 0 {
			newPos.X--
		}
	case DirectionRight:
		newPos.X++
	case DirectionPageUp:
		newPos.Y = max(0, newPos.Y-10)
	case DirectionPageDown:
		newPos.Y += 10
	case DirectionHome:
		newPos.X = 0
	case DirectionEnd:
		newPos.X = 999 // Will be adjusted by view bounds
	}

	return newPos
}

func (nm *NavigationManager) addToHistory(item NavigationHistoryItem) {
	nm.state.History = append(nm.state.History, item)

	// Limit history size
	if len(nm.state.History) > nm.state.Preferences.HistoryLimit {
		nm.state.History = nm.state.History[1:]
	}
}

func (nm *NavigationManager) trackAnalytics(eventType string, data map[string]interface{}) {
	nm.analytics.TotalCommands++
	
	if nm.analytics.NavigationPatterns == nil {
		nm.analytics.NavigationPatterns = make(map[string]int)
	}
	
	nm.analytics.NavigationPatterns[eventType]++
}

func (nm *NavigationManager) processCommands() {
	for {
		select {
		case cmd := <-nm.commands:
			nm.handleCommand(cmd)
		case <-nm.ctx.Done():
			return
		}
	}
}

func (nm *NavigationManager) handleCommand(cmd NavigationCommand) {
	nm.mutex.Lock()
	defer nm.mutex.Unlock()

	switch cmd.Action {
	case "navigate":
		if dir, ok := cmd.Parameters["direction"].(NavigationDirection); ok {
			nm.calculateNewPosition(nm.state.Position, dir)
		}
	case "set_view":
		if view, ok := cmd.Parameters["view"].(ViewMode); ok {
			nm.state.CurrentView = view
		}
	case "create_bookmark":
		if name, ok := cmd.Parameters["name"].(string); ok {
			description := ""
			if desc, ok := cmd.Parameters["description"].(string); ok {
				description = desc
			}
			var tags []string
			if t, ok := cmd.Parameters["tags"].([]string); ok {
				tags = t
			}
			
			bookmark := Bookmark{
				ID:          fmt.Sprintf("bookmark_%d", time.Now().Unix()),
				Name:        name,
				Description: description,
				ViewMode:    nm.state.CurrentView,
				Position:    nm.state.Position,
				Tags:        tags,
				CreatedAt:   time.Now(),
				AccessCount: 0,
			}
			
			nm.state.Bookmarks = append(nm.state.Bookmarks, bookmark)
		}
	}
}

func (nm *NavigationManager) loadState() error {
	filename := filepath.Join(nm.configDir, "navigation_state.json")
	data, err := os.ReadFile(filename)
	if err != nil {
		return err
	}

	return json.Unmarshal(data, nm.state)
}

func (nm *NavigationManager) saveState() error {
	filename := filepath.Join(nm.configDir, "navigation_state.json")
	data, err := json.MarshalIndent(nm.state, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(filename, data, 0644)
}

func (nm *NavigationManager) loadTransitions() error {
	filename := filepath.Join(nm.configDir, "view_transitions.json")
	data, err := os.ReadFile(filename)
	if err != nil {
		return err
	}

	return json.Unmarshal(data, &nm.transitions)
}

func (nm *NavigationManager) loadKeyMappings() error {
	filename := filepath.Join(nm.configDir, "key_mappings.json")
	data, err := os.ReadFile(filename)
	if err != nil {
		return err
	}

	return json.Unmarshal(data, &nm.keyMappings)
}

func (nm *NavigationManager) saveAnalytics() error {
	filename := filepath.Join(nm.configDir, "navigation_analytics.json")
	data, err := json.MarshalIndent(nm.analytics, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(filename, data, 0644)
}

func (nm *NavigationManager) setDefaultTransitions() {
	nm.transitions = map[string]ViewTransition{
		"list_to_kanban": {
			FromView:       ViewModeList,
			ToView:         ViewModeKanban,
			AnimationType:  "slide_left",
			Duration:       300 * time.Millisecond,
			Easing:         "ease-in-out",
			PreserveState:  true,
		},
		"kanban_to_list": {
			FromView:       ViewModeKanban,
			ToView:         ViewModeList,
			AnimationType:  "slide_right",
			Duration:       300 * time.Millisecond,
			Easing:         "ease-in-out",
			PreserveState:  true,
		},
		"list_to_calendar": {
			FromView:       ViewModeList,
			ToView:         ViewModeCalendar,
			AnimationType:  "fade",
			Duration:       400 * time.Millisecond,
			Easing:         "ease-in-out",
			PreserveState:  false,
		},
	}
}

func (nm *NavigationManager) setDefaultKeyMappings() {
	nm.keyMappings = map[string][]KeyMappingRule{
		"global": {
			{Key: "j", Action: "navigate_down", Context: "global", Priority: 1, Enabled: true},
			{Key: "k", Action: "navigate_up", Context: "global", Priority: 1, Enabled: true},
			{Key: "h", Action: "navigate_left", Context: "global", Priority: 1, Enabled: true},
			{Key: "l", Action: "navigate_right", Context: "global", Priority: 1, Enabled: true},
			{Key: "1", Action: "switch_to_list", Context: "global", Priority: 2, Enabled: true},
			{Key: "2", Action: "switch_to_kanban", Context: "global", Priority: 2, Enabled: true},
			{Key: "3", Action: "switch_to_calendar", Context: "global", Priority: 2, Enabled: true},
		},
		"list": {
			{Key: "enter", Action: "select_item", Context: "list", Priority: 1, Enabled: true},
			{Key: "space", Action: "toggle_item", Context: "list", Priority: 1, Enabled: true},
		},
		"kanban": {
			{Key: "enter", Action: "edit_card", Context: "kanban", Priority: 1, Enabled: true},
			{Key: "space", Action: "move_card", Context: "kanban", Priority: 1, Enabled: true},
		},
	}
}

// NewNavigationAnalytics creates a new navigation analytics instance
func NewNavigationAnalytics() *NavigationAnalytics {
	return &NavigationAnalytics{
		ViewUsage:          make(map[ViewMode]int),
		NavigationPatterns: make(map[string]int),
		KeyboardShortcuts:  make(map[string]int),
		ErrorFrequency:     make(map[string]int),
		LastAnalysis:       time.Now(),
		TotalSessions:      0,
		TotalCommands:      0,
	}
}

// Helper function for max
func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
