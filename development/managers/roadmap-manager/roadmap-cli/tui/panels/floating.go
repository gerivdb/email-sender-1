// Package panels - Floating panels management system
package panels

import (
	"sort"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// FloatingPanel represents a panel that can float above others
type FloatingPanel struct {
	*Panel
	ZIndex    int
	Dragging  bool
	StartPos  Position
	DragStart Position
	Shadow    bool
	Modal     bool
	Resizing  bool
}

// FloatingManager manages floating panels with z-order and focus
type FloatingManager struct {
	floatingPanels map[PanelID]*FloatingPanel
	zOrderStack    []PanelID
	maxZIndex      int
	dragThreshold  int
	shadowStyle    lipgloss.Style
	modalOverlay   lipgloss.Style
}

// NewFloatingManager creates a new floating panel manager
func NewFloatingManager() *FloatingManager {
	return &FloatingManager{
		floatingPanels: make(map[PanelID]*FloatingPanel),
		zOrderStack:    make([]PanelID, 0),
		maxZIndex:      1000,
		dragThreshold:  5,
		shadowStyle: lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(lipgloss.Color("240")).
			Padding(1),
		modalOverlay: lipgloss.NewStyle().
			Background(lipgloss.Color("235")).
			Foreground(lipgloss.Color("255")),
	}
}

// CreateFloatingPanel creates a new floating panel from a regular panel
func (fm *FloatingManager) CreateFloatingPanel(panel *Panel, modal bool) *FloatingPanel {
	floatingPanel := &FloatingPanel{
		Panel:    panel,
		ZIndex:   fm.getNextZIndex(),
		Shadow:   true,
		Modal:    modal,
		Dragging: false,
		Resizing: false,
	}

	fm.floatingPanels[panel.ID] = floatingPanel
	fm.bringToFront(panel.ID)

	return floatingPanel
}

// getNextZIndex returns the next available z-index
func (fm *FloatingManager) getNextZIndex() int {
	if len(fm.zOrderStack) == 0 {
		return 1
	}

	// Find highest z-index and increment
	highest := 0
	for _, panel := range fm.floatingPanels {
		if panel.ZIndex > highest {
			highest = panel.ZIndex
		}
	}

	return highest + 1
}

// BringToFront brings a floating panel to the front
func (fm *FloatingManager) BringToFront(id PanelID) error {
	if _, exists := fm.floatingPanels[id]; !exists {
		return ErrPanelNotFound
	}

	fm.bringToFront(id)
	return nil
}

// bringToFront internal implementation
func (fm *FloatingManager) bringToFront(id PanelID) {
	// Remove from current position
	for i, panelID := range fm.zOrderStack {
		if panelID == id {
			fm.zOrderStack = append(fm.zOrderStack[:i], fm.zOrderStack[i+1:]...)
			break
		}
	}

	// Add to front (end of slice)
	fm.zOrderStack = append(fm.zOrderStack, id)

	// Update z-index
	if panel, exists := fm.floatingPanels[id]; exists {
		panel.ZIndex = fm.getNextZIndex()
		panel.LastActive = time.Now()
	}
}

// SendToBack sends a floating panel to the back
func (fm *FloatingManager) SendToBack(id PanelID) error {
	if _, exists := fm.floatingPanels[id]; !exists {
		return ErrPanelNotFound
	}

	// Remove from current position
	for i, panelID := range fm.zOrderStack {
		if panelID == id {
			fm.zOrderStack = append(fm.zOrderStack[:i], fm.zOrderStack[i+1:]...)
			break
		}
	}

	// Add to back (beginning of slice)
	fm.zOrderStack = append([]PanelID{id}, fm.zOrderStack...)

	// Update z-index
	if panel, exists := fm.floatingPanels[id]; exists {
		panel.ZIndex = 1
		// Increment all other z-indices
		for _, otherPanel := range fm.floatingPanels {
			if otherPanel.Panel.ID != id {
				otherPanel.ZIndex++
			}
		}
	}

	return nil
}

// StartDrag starts dragging a floating panel
func (fm *FloatingManager) StartDrag(id PanelID, startPos Position) error {
	panel, exists := fm.floatingPanels[id]
	if !exists {
		return ErrPanelNotFound
	}

	panel.Dragging = true
	panel.StartPos = panel.Position
	panel.DragStart = startPos
	fm.bringToFront(id)

	return nil
}

// UpdateDrag updates the position during drag
func (fm *FloatingManager) UpdateDrag(id PanelID, currentPos Position) error {
	panel, exists := fm.floatingPanels[id]
	if !exists {
		return ErrPanelNotFound
	}

	if !panel.Dragging {
		return ErrInvalidOperation
	}

	// Calculate new position
	deltaX := currentPos.X - panel.DragStart.X
	deltaY := currentPos.Y - panel.DragStart.Y

	newX := panel.StartPos.X + deltaX
	newY := panel.StartPos.Y + deltaY

	// Ensure panel stays within bounds
	if newX < 0 {
		newX = 0
	}
	if newY < 0 {
		newY = 0
	}

	panel.Position = Position{X: newX, Y: newY}
	return nil
}

// EndDrag ends dragging a floating panel
func (fm *FloatingManager) EndDrag(id PanelID) error {
	panel, exists := fm.floatingPanels[id]
	if !exists {
		return ErrPanelNotFound
	}

	panel.Dragging = false
	return nil
}

// StartResize starts resizing a floating panel
func (fm *FloatingManager) StartResize(id PanelID, startPos Position) error {
	panel, exists := fm.floatingPanels[id]
	if !exists {
		return ErrPanelNotFound
	}

	if !panel.Resizable {
		return ErrInvalidOperation
	}

	panel.Resizing = true
	panel.DragStart = startPos
	fm.bringToFront(id)

	return nil
}

// UpdateResize updates the size during resize
func (fm *FloatingManager) UpdateResize(id PanelID, currentPos Position) error {
	panel, exists := fm.floatingPanels[id]
	if !exists {
		return ErrPanelNotFound
	}

	if !panel.Resizing {
		return ErrInvalidOperation
	}

	// Calculate new size
	deltaX := currentPos.X - panel.DragStart.X
	deltaY := currentPos.Y - panel.DragStart.Y

	newWidth := panel.Size.Width + deltaX
	newHeight := panel.Size.Height + deltaY

	// Enforce minimum size
	minSize := Size{Width: 20, Height: 10}
	if newWidth < minSize.Width {
		newWidth = minSize.Width
	}
	if newHeight < minSize.Height {
		newHeight = minSize.Height
	}

	panel.Size = Size{Width: newWidth, Height: newHeight}
	return nil
}

// EndResize ends resizing a floating panel
func (fm *FloatingManager) EndResize(id PanelID) error {
	panel, exists := fm.floatingPanels[id]
	if !exists {
		return ErrPanelNotFound
	}

	panel.Resizing = false
	return nil
}

// GetFloatingPanel returns a floating panel by ID
func (fm *FloatingManager) GetFloatingPanel(id PanelID) (*FloatingPanel, error) {
	panel, exists := fm.floatingPanels[id]
	if !exists {
		return nil, ErrPanelNotFound
	}
	return panel, nil
}

// GetTopPanel returns the topmost floating panel
func (fm *FloatingManager) GetTopPanel() *FloatingPanel {
	if len(fm.zOrderStack) == 0 {
		return nil
	}

	topID := fm.zOrderStack[len(fm.zOrderStack)-1]
	return fm.floatingPanels[topID]
}

// GetZOrderedPanels returns panels sorted by z-order (back to front)
func (fm *FloatingManager) GetZOrderedPanels() []*FloatingPanel {
	panels := make([]*FloatingPanel, 0, len(fm.zOrderStack))

	for _, id := range fm.zOrderStack {
		if panel, exists := fm.floatingPanels[id]; exists {
			panels = append(panels, panel)
		}
	}

	return panels
}

// CloseFloatingPanel closes and removes a floating panel
func (fm *FloatingManager) CloseFloatingPanel(id PanelID) error {
	if _, exists := fm.floatingPanels[id]; !exists {
		return ErrPanelNotFound
	}

	// Remove from z-order stack
	for i, panelID := range fm.zOrderStack {
		if panelID == id {
			fm.zOrderStack = append(fm.zOrderStack[:i], fm.zOrderStack[i+1:]...)
			break
		}
	}

	// Remove from floating panels
	delete(fm.floatingPanels, id)

	return nil
}

// GetModalPanels returns all modal floating panels
func (fm *FloatingManager) GetModalPanels() []*FloatingPanel {
	modalPanels := make([]*FloatingPanel, 0)

	for _, panel := range fm.floatingPanels {
		if panel.Modal {
			modalPanels = append(modalPanels, panel)
		}
	}

	// Sort by z-index
	sort.Slice(modalPanels, func(i, j int) bool {
		return modalPanels[i].ZIndex < modalPanels[j].ZIndex
	})

	return modalPanels
}

// HasModalPanels returns true if there are any modal panels
func (fm *FloatingManager) HasModalPanels() bool {
	for _, panel := range fm.floatingPanels {
		if panel.Modal {
			return true
		}
	}
	return false
}

// Update handles updates for floating panels
func (fm *FloatingManager) Update(msg tea.Msg) tea.Cmd {
	var cmds []tea.Cmd

	// Update each floating panel
	for _, panel := range fm.floatingPanels {
		if panel.Content != nil {
			var cmd tea.Cmd
			panel.Content, cmd = panel.Content.Update(msg)
			if cmd != nil {
				cmds = append(cmds, cmd)
			}
		}
	}

	if len(cmds) > 0 {
		return tea.Batch(cmds...)
	}

	return nil
}

// View renders all floating panels
func (fm *FloatingManager) View(termWidth, termHeight int) string {
	if len(fm.floatingPanels) == 0 {
		return ""
	}

	// Create canvas
	canvas := make([][]rune, termHeight)
	for i := range canvas {
		canvas[i] = make([]rune, termWidth)
		for j := range canvas[i] {
			canvas[i][j] = ' '
		}
	}

	// Render panels in z-order
	orderedPanels := fm.GetZOrderedPanels()

	for _, floatingPanel := range orderedPanels {
		panel := floatingPanel.Panel

		if !panel.Visible {
			continue
		}

		// Render panel content
		content := ""
		if panel.Content != nil {
			content = panel.Content.View()
		}

		// Apply styling
		style := panel.Style
		if floatingPanel.Shadow {
			style = style.Copy().Inherit(fm.shadowStyle)
		}
		if floatingPanel.Modal {
			style = style.Copy().Inherit(fm.modalOverlay)
		}
		if floatingPanel.Dragging {
			style = style.Copy().BorderForeground(lipgloss.Color("6"))
		}

		styledContent := style.
			Width(panel.Size.Width).
			Height(panel.Size.Height).
			Render(content)

		// Draw on canvas (simplified - would need proper text rendering)
		fm.drawOnCanvas(canvas, styledContent, panel.Position, termWidth, termHeight)
	}

	// Convert canvas to string
	return fm.canvasToString(canvas)
}

// drawOnCanvas draws content on the canvas at the given position
func (fm *FloatingManager) drawOnCanvas(canvas [][]rune, content string, pos Position, termWidth, termHeight int) {
	lines := lipgloss.NewStyle().Render(content)
	contentLines := []string{lines} // Simplified - would split by newlines

	for i, line := range contentLines {
		y := pos.Y + i
		if y >= 0 && y < termHeight {
			x := pos.X
			for _, char := range line {
				if x >= 0 && x < termWidth {
					canvas[y][x] = char
				}
				x++
			}
		}
	}
}

// canvasToString converts the canvas to a string
func (fm *FloatingManager) canvasToString(canvas [][]rune) string {
	result := ""
	for _, row := range canvas {
		result += string(row) + "\n"
	}
	return result
}
