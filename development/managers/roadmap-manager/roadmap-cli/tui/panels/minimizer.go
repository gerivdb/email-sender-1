// Package panels - Panel minimization system with quick restoration
package panels

import (
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// MinimizedState represents the state of a minimized panel
type MinimizedState struct {
	OriginalPosition Position
	OriginalSize     Size
	MinimizedAt      time.Time
	MinimizedBy      string // User action, auto-minimize, etc.
	RestoreHotkey    string
}

// PanelMinimizer manages panel minimization and restoration
type PanelMinimizer struct {
	minimizedPanels   map[PanelID]*MinimizedState
	minimizedBar      MinimizedBar
	autoMinimize      bool
	quickRestoreKeys  map[string]PanelID
	animationDuration time.Duration
	minimizedStyle    lipgloss.Style
}

// MinimizedBar represents the minimized panels bar
type MinimizedBar struct {
	Position    Position
	Height      int
	MaxWidth    int
	Visible     bool
	AutoHide    bool
	Style       lipgloss.Style
	ButtonStyle lipgloss.Style
}

// NewPanelMinimizer creates a new panel minimizer
func NewPanelMinimizer() *PanelMinimizer {
	return &PanelMinimizer{
		minimizedPanels:   make(map[PanelID]*MinimizedState),
		quickRestoreKeys:  make(map[string]PanelID),
		animationDuration: time.Millisecond * 200,
		autoMinimize:      false,
		minimizedBar: MinimizedBar{
			Position: Position{X: 0, Y: 0}, // Bottom of screen
			Height:   3,
			MaxWidth: 100,
			Visible:  true,
			AutoHide: false,
			Style: lipgloss.NewStyle().
				Background(lipgloss.Color("235")).
				Border(lipgloss.NormalBorder()).
				BorderTop(true),
			ButtonStyle: lipgloss.NewStyle().
				Background(lipgloss.Color("240")).
				Foreground(lipgloss.Color("255")).
				Padding(0, 1).
				Margin(0, 1),
		},
		minimizedStyle: lipgloss.NewStyle().
			Background(lipgloss.Color("235")).
			Foreground(lipgloss.Color("245")).
			Faint(true),
	}
}

// MinimizePanel minimizes a panel to the taskbar
func (pm *PanelMinimizer) MinimizePanel(panel *Panel, reason string) error {
	if panel.Minimized {
		return ErrInvalidOperation
	}

	// Save current state
	state := &MinimizedState{
		OriginalPosition: panel.Position,
		OriginalSize:     panel.Size,
		MinimizedAt:      time.Now(),
		MinimizedBy:      reason,
		RestoreHotkey:    pm.generateRestoreHotkey(panel.ID),
	}

	pm.minimizedPanels[panel.ID] = state
	pm.quickRestoreKeys[state.RestoreHotkey] = panel.ID

	// Update panel state
	panel.Minimized = true
	panel.Visible = false

	return nil
}

// RestorePanel restores a minimized panel
func (pm *PanelMinimizer) RestorePanel(id PanelID) error {
	state, exists := pm.minimizedPanels[id]
	if !exists {
		return ErrPanelNotFound
	}

	// Find the panel in the panel manager (would need reference)
	panel, err := pm.findPanel(id)
	if err != nil {
		return err
	}

	// Restore original state
	panel.Position = state.OriginalPosition
	panel.Size = state.OriginalSize
	panel.Minimized = false
	panel.Visible = true
	panel.LastActive = time.Now()

	// Clean up minimizer state
	delete(pm.minimizedPanels, id)
	delete(pm.quickRestoreKeys, state.RestoreHotkey)

	return nil
}

// TogglePanel toggles a panel between minimized and restored states
func (pm *PanelMinimizer) TogglePanel(panel *Panel) error {
	if panel.Minimized {
		return pm.RestorePanel(panel.ID)
	} else {
		return pm.MinimizePanel(panel, "user_toggle")
	}
}

// RestoreByHotkey restores a panel using its hotkey
func (pm *PanelMinimizer) RestoreByHotkey(hotkey string) error {
	panelID, exists := pm.quickRestoreKeys[hotkey]
	if !exists {
		return ErrPanelNotFound
	}

	return pm.RestorePanel(panelID)
}

// generateRestoreHotkey generates a unique hotkey for quick restoration
func (pm *PanelMinimizer) generateRestoreHotkey(id PanelID) string {
	// Try F1-F12 first
	for i := 1; i <= 12; i++ {
		hotkey := formatFunctionKey(i)
		if _, exists := pm.quickRestoreKeys[hotkey]; !exists {
			return hotkey
		}
	}

	// Fall back to Alt+Number
	for i := 1; i <= 9; i++ {
		hotkey := formatAltNumber(i)
		if _, exists := pm.quickRestoreKeys[hotkey]; !exists {
			return hotkey
		}
	}

	// Fall back to panel ID as string
	return string(id)
}

// formatFunctionKey formats a function key string
func formatFunctionKey(num int) string {
	return "F" + string(rune('0'+num))
}

// formatAltNumber formats an Alt+Number key combination
func formatAltNumber(num int) string {
	return "Alt+" + string(rune('0'+num))
}

// GetMinimizedPanels returns all minimized panels
func (pm *PanelMinimizer) GetMinimizedPanels() map[PanelID]*MinimizedState {
	return pm.minimizedPanels
}

// GetQuickRestoreKeys returns the hotkey mapping
func (pm *PanelMinimizer) GetQuickRestoreKeys() map[string]PanelID {
	return pm.quickRestoreKeys
}

// IsMinimized checks if a panel is minimized
func (pm *PanelMinimizer) IsMinimized(id PanelID) bool {
	_, exists := pm.minimizedPanels[id]
	return exists
}

// MinimizeAll minimizes all visible panels
func (pm *PanelMinimizer) MinimizeAll(panels map[PanelID]*Panel) error {
	for _, panel := range panels {
		if !panel.Minimized && panel.Visible {
			if err := pm.MinimizePanel(panel, "minimize_all"); err != nil {
				return err
			}
		}
	}
	return nil
}

// RestoreAll restores all minimized panels
func (pm *PanelMinimizer) RestoreAll() error {
	for panelID := range pm.minimizedPanels {
		if err := pm.RestorePanel(panelID); err != nil {
			return err
		}
	}
	return nil
}

// AutoMinimizeInactive automatically minimizes panels that haven't been active
func (pm *PanelMinimizer) AutoMinimizeInactive(panels map[PanelID]*Panel, inactiveThreshold time.Duration) error {
	if !pm.autoMinimize {
		return nil
	}

	now := time.Now()
	for _, panel := range panels {
		if !panel.Minimized && panel.Visible {
			if now.Sub(panel.LastActive) > inactiveThreshold {
				if err := pm.MinimizePanel(panel, "auto_minimize_inactive"); err != nil {
					return err
				}
			}
		}
	}

	return nil
}

// SetAutoMinimize enables or disables automatic minimization
func (pm *PanelMinimizer) SetAutoMinimize(enabled bool) {
	pm.autoMinimize = enabled
}

// Update handles key events and updates for the minimizer
func (pm *PanelMinimizer) Update(msg tea.Msg) tea.Cmd {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		return pm.handleKeyEvent(msg)
	}
	return nil
}

// handleKeyEvent processes keyboard events for quick restore
func (pm *PanelMinimizer) handleKeyEvent(msg tea.KeyMsg) tea.Cmd {
	key := msg.String()

	// Check for quick restore hotkeys
	if panelID, exists := pm.quickRestoreKeys[key]; exists {
		if err := pm.RestorePanel(panelID); err != nil {
			// Could return an error command here
			return nil
		}
	}

	// Handle special key combinations
	switch key {
	case "ctrl+m":
		// Could minimize active panel
		return nil
	case "ctrl+shift+m":
		// Could restore all panels
		return tea.Cmd(func() tea.Msg {
			pm.RestoreAll()
			return nil
		})
	}

	return nil
}

// RenderMinimizedBar renders the minimized panels bar
func (pm *PanelMinimizer) RenderMinimizedBar(termWidth, termHeight int) string {
	if !pm.minimizedBar.Visible || len(pm.minimizedPanels) == 0 {
		return ""
	}

	// Create buttons for each minimized panel
	buttons := make([]string, 0, len(pm.minimizedPanels))

	for id, state := range pm.minimizedPanels {
		// Find panel to get title (would need reference to panel manager)
		title := string(id) // Fallback to ID
		if panel, err := pm.findPanel(id); err == nil {
			title = panel.Title
		}

		// Truncate title if too long
		if len(title) > 15 {
			title = title[:12] + "..."
		}

		// Add restore hotkey hint
		buttonText := title + " (" + state.RestoreHotkey + ")"

		button := pm.minimizedBar.ButtonStyle.Render(buttonText)
		buttons = append(buttons, button)
	}

	// Join buttons
	content := lipgloss.JoinHorizontal(lipgloss.Left, buttons...)

	// Apply bar styling
	bar := pm.minimizedBar.Style.
		Width(termWidth).
		Height(pm.minimizedBar.Height).
		Render(content)

	return bar
}

// GetMinimizedBarHeight returns the height of the minimized bar
func (pm *PanelMinimizer) GetMinimizedBarHeight() int {
	if !pm.minimizedBar.Visible || len(pm.minimizedPanels) == 0 {
		return 0
	}
	return pm.minimizedBar.Height
}

// SetMinimizedBarPosition sets the position of the minimized bar
func (pm *PanelMinimizer) SetMinimizedBarPosition(pos Position) {
	pm.minimizedBar.Position = pos
}

// SetMinimizedBarAutoHide enables or disables auto-hide for the minimized bar
func (pm *PanelMinimizer) SetMinimizedBarAutoHide(autoHide bool) {
	pm.minimizedBar.AutoHide = autoHide
}

// findPanel is a helper to find a panel by ID (would need reference to panel manager)
func (pm *PanelMinimizer) findPanel(id PanelID) (*Panel, error) {
	// This would need to be implemented with a reference to the panel manager
	// For now, return an error
	return nil, ErrPanelNotFound
}

// GetMinimizedInfo returns information about a minimized panel
func (pm *PanelMinimizer) GetMinimizedInfo(id PanelID) (*MinimizedState, error) {
	state, exists := pm.minimizedPanels[id]
	if !exists {
		return nil, ErrPanelNotFound
	}
	return state, nil
}

// GetMinimizedCount returns the number of minimized panels
func (pm *PanelMinimizer) GetMinimizedCount() int {
	return len(pm.minimizedPanels)
}

// ClearMinimizedState clears all minimized state (useful for cleanup)
func (pm *PanelMinimizer) ClearMinimizedState() {
	pm.minimizedPanels = make(map[PanelID]*MinimizedState)
	pm.quickRestoreKeys = make(map[string]PanelID)
}
