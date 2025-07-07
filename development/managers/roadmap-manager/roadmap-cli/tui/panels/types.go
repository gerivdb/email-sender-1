// Package panels provides multi-panel management functionality for the TUI
package panels

import (
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// PanelID represents a unique identifier for panels
type PanelID string

// Panel represents a single panel in the TUI
type Panel struct {
	ID         PanelID
	Title      string
	Content    tea.Model
	Position   Position
	Size       Size
	Visible    bool
	Minimized  bool
	ZOrder     int
	Resizable  bool
	Movable    bool
	CreatedAt  time.Time
	LastActive time.Time
	Style      lipgloss.Style
}

// Position represents the position of a panel
type Position struct {
	X int
	Y int
}

// Size represents the size of a panel
type Size struct {
	Width  int
	Height int
}

// LayoutType represents different layout types
type LayoutType int

const (
	LayoutHorizontal LayoutType = iota
	LayoutVertical
	LayoutGrid
	LayoutFloating
	LayoutTabs
)

// LayoutConfig represents the configuration for panel layout
type LayoutConfig struct {
	Type        LayoutType
	Ratio       []float64 // Ratios for splits
	Padding     int
	Margin      int
	BorderStyle lipgloss.Border
	Adaptive    bool // Adapt to terminal size changes
}

// PanelManager manages multiple panels with layouts
type PanelManager struct {
	panels       map[PanelID]*Panel
	activePanel  PanelID
	layout       LayoutConfig
	width        int
	height       int
	minPanelSize Size
	maxPanels    int
	panelOrder   []PanelID
	history      []PanelID // Navigation history
	shortcuts    map[string]PanelID

	// New contextual and mode-aware managers
	contextualManager *ContextualShortcutManager
	modeKeyManager    *ModeSpecificKeyManager
	currentViewMode   ViewMode
}

// NewPanelManager creates a new panel manager
func NewPanelManager(width, height int, layout LayoutConfig) *PanelManager {
	pm := &PanelManager{
		panels:          make(map[PanelID]*Panel),
		layout:          layout,
		width:           width,
		height:          height,
		minPanelSize:    Size{Width: 20, Height: 10},
		maxPanels:       8,
		panelOrder:      make([]PanelID, 0),
		history:         make([]PanelID, 0, 50),
		shortcuts:       make(map[string]PanelID),
		currentViewMode: ViewModeList, // Default view mode
	}

	// Initialize contextual and mode managers
	pm.contextualManager = NewContextualShortcutManager(pm)
	pm.modeKeyManager = NewModeSpecificKeyManager(pm, pm.contextualManager)

	return pm
}

// AddPanel adds a new panel to the manager
func (pm *PanelManager) AddPanel(panel *Panel) error {
	if len(pm.panels) >= pm.maxPanels {
		return ErrMaxPanelsReached
	}

	panel.CreatedAt = time.Now()
	panel.LastActive = time.Now()
	pm.panels[panel.ID] = panel
	pm.panelOrder = append(pm.panelOrder, panel.ID)

	if pm.activePanel == "" {
		pm.activePanel = panel.ID
	}

	return nil
}

// GetActivePanel returns the currently active panel
func (pm *PanelManager) GetActivePanel() *Panel {
	if pm.activePanel == "" {
		return nil
	}
	return pm.panels[pm.activePanel]
}

// GetPanel returns a panel by ID
func (pm *PanelManager) GetPanel(id PanelID) *Panel {
	return pm.panels[id]
}

// GetActivePanelID returns the ID of the currently active panel
func (pm *PanelManager) GetActivePanelID() PanelID {
	return pm.activePanel
}

// SetActivePanel sets the active panel
func (pm *PanelManager) SetActivePanel(id PanelID) error {
	if panel, exists := pm.panels[id]; !exists {
		return ErrPanelNotFound
	} else {
		pm.activePanel = id
		panel.LastActive = time.Now()
		pm.addToHistory(id)
		return nil
	}
}

// MovePanel moves a panel to a new position
func (pm *PanelManager) MovePanel(id PanelID, newPosition Position) error {
	panel, exists := pm.panels[id]
	if !exists {
		return ErrPanelNotFound
	}

	panel.Position = newPosition
	return nil
}

// ResizePanel resizes a panel to new dimensions
func (pm *PanelManager) ResizePanel(id PanelID, newSize Size) error {
	panel, exists := pm.panels[id]
	if !exists {
		return ErrPanelNotFound
	}

	if !panel.Resizable {
		return ErrResizeNotAllowed
	}

	// Validate minimum size
	if newSize.Width < pm.minPanelSize.Width || newSize.Height < pm.minPanelSize.Height {
		return ErrSizeTooSmall
	}

	panel.Size = newSize
	return nil
}

// addToHistory adds a panel to navigation history
func (pm *PanelManager) addToHistory(id PanelID) {
	// Remove if already exists to avoid duplicates
	for i, historyID := range pm.history {
		if historyID == id {
			pm.history = append(pm.history[:i], pm.history[i+1:]...)
			break
		}
	}

	// Add to end
	pm.history = append(pm.history, id)

	// Keep only last 50 entries
	if len(pm.history) > 50 {
		pm.history = pm.history[1:]
	}
}

// GetLayout returns the current layout configuration
func (pm *PanelManager) GetLayout() LayoutConfig {
	return pm.layout
}

// SetLayout updates the layout configuration
func (pm *PanelManager) SetLayout(layout LayoutConfig) {
	pm.layout = layout
	pm.recalculatePanelPositions()
}

// recalculatePanelPositions recalculates panel positions based on layout
func (pm *PanelManager) recalculatePanelPositions() {
	switch pm.layout.Type {
	case LayoutHorizontal:
		pm.arrangeHorizontal()
	case LayoutVertical:
		pm.arrangeVertical()
	case LayoutGrid:
		pm.arrangeGrid()
	case LayoutFloating:
		pm.arrangeFloating()
	case LayoutTabs:
		pm.arrangeTabs()
	}
}

// Init initializes the panel manager (required for tea.Model interface)
func (pm *PanelManager) Init() tea.Cmd {
	return nil
}

// Update implements tea.Model interface
func (pm *PanelManager) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmds []tea.Cmd

	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		pm.width = msg.Width
		pm.height = msg.Height
		pm.recalculatePanelPositions()

	case tea.KeyMsg:
		cmd := pm.handleKeyPress(msg)
		if cmd != nil {
			cmds = append(cmds, cmd)
		}
	}

	// Update active panel
	if activePanel := pm.GetActivePanel(); activePanel != nil {
		updatedModel, cmd := activePanel.Content.Update(msg)
		activePanel.Content = updatedModel
		if cmd != nil {
			cmds = append(cmds, cmd)
		}
	}

	return pm, tea.Batch(cmds...)
}

// View renders the panel manager
func (pm *PanelManager) View() string {
	if len(pm.panels) == 0 {
		return "No panels available"
	}

	switch pm.layout.Type {
	case LayoutHorizontal:
		return pm.renderHorizontal()
	case LayoutVertical:
		return pm.renderVertical()
	case LayoutGrid:
		return pm.renderGrid()
	case LayoutFloating:
		return pm.renderFloating()
	case LayoutTabs:
		return pm.renderTabs()
	default:
		return pm.renderHorizontal()
	}
}

// renderHorizontal renders panels in horizontal layout
func (pm *PanelManager) renderHorizontal() string {
	// Basic horizontal rendering implementation
	activePanel := pm.GetActivePanel()
	if activePanel != nil && activePanel.Content != nil {
		return activePanel.Content.View()
	}
	return "Active panel not found"
}

// renderVertical renders panels in vertical layout
func (pm *PanelManager) renderVertical() string {
	// Basic vertical rendering implementation
	activePanel := pm.GetActivePanel()
	if activePanel != nil && activePanel.Content != nil {
		return activePanel.Content.View()
	}
	return "Active panel not found"
}

// renderGrid renders panels in grid layout
func (pm *PanelManager) renderGrid() string {
	// Basic grid rendering implementation
	activePanel := pm.GetActivePanel()
	if activePanel != nil && activePanel.Content != nil {
		return activePanel.Content.View()
	}
	return "Active panel not found"
}

// renderFloating renders panels in floating layout
func (pm *PanelManager) renderFloating() string {
	// Basic floating rendering implementation
	activePanel := pm.GetActivePanel()
	if activePanel != nil && activePanel.Content != nil {
		return activePanel.Content.View()
	}
	return "Active panel not found"
}

// renderTabs renders panels in tabs layout
func (pm *PanelManager) renderTabs() string {
	// Basic tabs rendering implementation
	activePanel := pm.GetActivePanel()
	if activePanel != nil && activePanel.Content != nil {
		return activePanel.Content.View()
	}
	return "Active panel not found"
}

// handleKeyPress handles key presses for panel management
func (pm *PanelManager) handleKeyPress(msg tea.KeyMsg) tea.Cmd {
	switch msg.String() {
	case "ctrl+1", "ctrl+2", "ctrl+3", "ctrl+4", "ctrl+5", "ctrl+6", "ctrl+7", "ctrl+8":
		// Quick panel switching
		index := int(msg.String()[4] - '1')
		if index < len(pm.panelOrder) {
			pm.SetActivePanel(pm.panelOrder[index])
		}
	case "ctrl+tab":
		pm.nextPanel()
	case "ctrl+shift+tab":
		pm.prevPanel()
	case "ctrl+h":
		pm.SetLayout(LayoutConfig{Type: LayoutHorizontal, Ratio: []float64{0.5, 0.5}})
	case "ctrl+v":
		pm.SetLayout(LayoutConfig{Type: LayoutVertical, Ratio: []float64{0.5, 0.5}})
	case "ctrl+g":
		pm.SetLayout(LayoutConfig{Type: LayoutGrid})
	case "ctrl+f":
		pm.SetLayout(LayoutConfig{Type: LayoutFloating})
	}
	return nil
}

// nextPanel switches to the next panel
func (pm *PanelManager) nextPanel() {
	if len(pm.panelOrder) <= 1 {
		return
	}

	currentIndex := -1
	for i, id := range pm.panelOrder {
		if id == pm.activePanel {
			currentIndex = i
			break
		}
	}

	if currentIndex >= 0 {
		nextIndex := (currentIndex + 1) % len(pm.panelOrder)
		pm.SetActivePanel(pm.panelOrder[nextIndex])
	}
}

// prevPanel switches to the previous panel
func (pm *PanelManager) prevPanel() {
	if len(pm.panelOrder) <= 1 {
		return
	}

	currentIndex := -1
	for i, id := range pm.panelOrder {
		if id == pm.activePanel {
			currentIndex = i
			break
		}
	}

	if currentIndex >= 0 {
		prevIndex := (currentIndex - 1 + len(pm.panelOrder)) % len(pm.panelOrder)
		pm.SetActivePanel(pm.panelOrder[prevIndex])
	}
}

// GetContextualManager returns the contextual shortcut manager
func (pm *PanelManager) GetContextualManager() *ContextualShortcutManager {
	return pm.contextualManager
}

// GetModeKeyManager returns the mode-specific key manager
func (pm *PanelManager) GetModeKeyManager() *ModeSpecificKeyManager {
	return pm.modeKeyManager
}

// SetViewMode changes the current view mode and updates key bindings
func (pm *PanelManager) SetViewMode(mode ViewMode) error {
	if pm.modeKeyManager == nil {
		return ErrManagerNotInitialized
	}

	pm.currentViewMode = mode
	return pm.modeKeyManager.SetMode(mode)
}

// GetViewMode returns the current view mode
func (pm *PanelManager) GetViewMode() ViewMode {
	return pm.currentViewMode
}

// HandleContextualKey processes a key input through the contextual system
func (pm *PanelManager) HandleContextualKey(keypress string) tea.Cmd {
	if pm.contextualManager == nil {
		return nil
	}

	return pm.contextualManager.HandleKey(keypress, pm.activePanel)
}

// UpdateShortcutContext updates the current context for dynamic shortcuts
func (pm *PanelManager) UpdateShortcutContext() {
	if pm.contextualManager == nil {
		return
	}

	activePanel := pm.GetActivePanel()
	if activePanel == nil {
		return
	}

	context := ShortcutContext{
		ActivePanel:   pm.activePanel,
		PanelType:     string(activePanel.ID), // Could be more sophisticated
		ViewMode:      string(pm.currentViewMode),
		SelectedItems: []string{}, // Would be populated based on panel content
		EditMode:      false,      // Would be determined by panel state
		FilterActive:  false,      // Would be determined by panel state
	}

	pm.contextualManager.UpdateContext(context)
}

// GetAvailableShortcuts returns all available shortcuts for the current context
func (pm *PanelManager) GetAvailableShortcuts() map[string]string {
	if pm.contextualManager == nil {
		return make(map[string]string)
	}

	shortcuts := pm.contextualManager.GetAvailableShortcuts(pm.activePanel)
	modeShortcuts := pm.modeKeyManager.GetActiveBindings()

	// Merge both sets of shortcuts
	result := make(map[string]string)
	for key, desc := range shortcuts {
		result[key] = desc
	}
	for key, binding := range modeShortcuts {
		if result[key] == "" { // Don't override contextual shortcuts
			result[key] = binding.Help().Desc
		}
	}

	return result
}
