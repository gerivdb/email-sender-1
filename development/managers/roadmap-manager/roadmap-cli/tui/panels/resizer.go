package panels

import (
	tea "github.com/charmbracelet/bubbletea"
)

// ResizeMode represents different resize modes
type ResizeMode int

const (
	ResizeModeNone ResizeMode = iota
	ResizeModeWidth
	ResizeModeHeight
	ResizeModeBoth
)

// PanelResizer handles panel resizing operations
type PanelResizer struct {
	manager      *PanelManager
	resizing     bool
	resizeMode   ResizeMode
	targetPanel  PanelID
	startPos     Position
	originalSize Size
}

// NewPanelResizer creates a new panel resizer
func NewPanelResizer(manager *PanelManager) *PanelResizer {
	return &PanelResizer{
		manager:    manager,
		resizing:   false,
		resizeMode: ResizeModeNone,
	}
}

// AdjustSize adjusts the size of a panel
func (pr *PanelResizer) AdjustSize(panelID PanelID, deltaWidth, deltaHeight int) error {
	panel, exists := pr.manager.panels[panelID]
	if !exists {
		return ErrPanelNotFound
	}

	if !panel.Resizable {
		return ErrInvalidLayout
	}

	// Calculate new size
	newWidth := panel.Size.Width + deltaWidth
	newHeight := panel.Size.Height + deltaHeight

	// Enforce minimum size constraints
	if newWidth < pr.manager.minPanelSize.Width {
		newWidth = pr.manager.minPanelSize.Width
	}
	if newHeight < pr.manager.minPanelSize.Height {
		newHeight = pr.manager.minPanelSize.Height
	}

	// Enforce maximum size constraints (terminal bounds)
	maxWidth := pr.manager.width - panel.Position.X
	maxHeight := pr.manager.height - panel.Position.Y

	if newWidth > maxWidth {
		newWidth = maxWidth
	}
	if newHeight > maxHeight {
		newHeight = maxHeight
	}

	// Apply new size
	panel.Size.Width = newWidth
	panel.Size.Height = newHeight

	// If panel is part of a split layout, adjust neighboring panels
	if pr.manager.layout.Type == LayoutHorizontal || pr.manager.layout.Type == LayoutVertical {
		return pr.adjustNeighboringSplitPanels(panelID, deltaWidth, deltaHeight)
	}

	return nil
}

// StartResize begins a resize operation
func (pr *PanelResizer) StartResize(panelID PanelID, mode ResizeMode, startPos Position) error {
	panel, exists := pr.manager.panels[panelID]
	if !exists {
		return ErrPanelNotFound
	}

	if !panel.Resizable {
		return ErrInvalidLayout
	}

	pr.resizing = true
	pr.resizeMode = mode
	pr.targetPanel = panelID
	pr.startPos = startPos
	pr.originalSize = panel.Size

	return nil
}

// UpdateResize updates an ongoing resize operation
func (pr *PanelResizer) UpdateResize(currentPos Position) error {
	if !pr.resizing {
		return nil
	}

	deltaX := currentPos.X - pr.startPos.X
	deltaY := currentPos.Y - pr.startPos.Y

	var deltaWidth, deltaHeight int

	switch pr.resizeMode {
	case ResizeModeWidth:
		deltaWidth = deltaX
		deltaHeight = 0
	case ResizeModeHeight:
		deltaWidth = 0
		deltaHeight = deltaY
	case ResizeModeBoth:
		deltaWidth = deltaX
		deltaHeight = deltaY
	}

	return pr.AdjustSize(pr.targetPanel, deltaWidth, deltaHeight)
}

// EndResize ends a resize operation
func (pr *PanelResizer) EndResize() {
	pr.resizing = false
	pr.resizeMode = ResizeModeNone
	pr.targetPanel = ""
}

// HandleKeyboardResize handles keyboard-based resizing
func (pr *PanelResizer) HandleKeyboardResize(msg tea.KeyMsg) error {
	activePanel := pr.manager.GetActivePanel()
	if activePanel == nil || !activePanel.Resizable {
		return nil
	}

	const resizeStep = 2
	var deltaWidth, deltaHeight int

	switch msg.String() {
	case "ctrl+shift+right":
		deltaWidth = resizeStep
	case "ctrl+shift+left":
		deltaWidth = -resizeStep
	case "ctrl+shift+down":
		deltaHeight = resizeStep
	case "ctrl+shift+up":
		deltaHeight = -resizeStep
	case "ctrl+shift+plus", "ctrl+shift+=":
		// Grow both dimensions
		deltaWidth = resizeStep
		deltaHeight = resizeStep
	case "ctrl+shift+minus":
		// Shrink both dimensions
		deltaWidth = -resizeStep
		deltaHeight = -resizeStep
	default:
		return nil
	}

	return pr.AdjustSize(activePanel.ID, deltaWidth, deltaHeight)
}

// adjustNeighboringSplitPanels adjusts neighboring panels in split layouts
func (pr *PanelResizer) adjustNeighboringSplitPanels(panelID PanelID, deltaWidth, deltaHeight int) error {
	visiblePanels := pr.manager.getVisiblePanels()
	if len(visiblePanels) <= 1 {
		return nil
	}

	// Find the index of the panel being resized
	var panelIndex = -1
	for i, panel := range visiblePanels {
		if panel.ID == panelID {
			panelIndex = i
			break
		}
	}

	if panelIndex == -1 {
		return ErrPanelNotFound
	}

	switch pr.manager.layout.Type {
	case LayoutHorizontal:
		return pr.adjustHorizontalSplitNeighbors(visiblePanels, panelIndex, deltaWidth)
	case LayoutVertical:
		return pr.adjustVerticalSplitNeighbors(visiblePanels, panelIndex, deltaHeight)
	}

	return nil
}

// adjustHorizontalSplitNeighbors adjusts neighbors in horizontal split
func (pr *PanelResizer) adjustHorizontalSplitNeighbors(panels []*Panel, panelIndex, deltaWidth int) error {
	if panelIndex >= len(panels)-1 {
		return nil // No right neighbor
	}

	rightPanel := panels[panelIndex+1]

	// Ensure the adjustment doesn't violate minimum sizes
	newRightWidth := rightPanel.Size.Width - deltaWidth
	if newRightWidth < pr.manager.minPanelSize.Width {
		deltaWidth = rightPanel.Size.Width - pr.manager.minPanelSize.Width
	}

	// Apply adjustments
	rightPanel.Size.Width = newRightWidth
	rightPanel.Position.X += deltaWidth

	// Recalculate ratios
	pr.recalculateHorizontalRatios(panels)

	return nil
}

// adjustVerticalSplitNeighbors adjusts neighbors in vertical split
func (pr *PanelResizer) adjustVerticalSplitNeighbors(panels []*Panel, panelIndex, deltaHeight int) error {
	if panelIndex >= len(panels)-1 {
		return nil // No bottom neighbor
	}

	bottomPanel := panels[panelIndex+1]

	// Ensure the adjustment doesn't violate minimum sizes
	newBottomHeight := bottomPanel.Size.Height - deltaHeight
	if newBottomHeight < pr.manager.minPanelSize.Height {
		deltaHeight = bottomPanel.Size.Height - pr.manager.minPanelSize.Height
	}

	// Apply adjustments
	bottomPanel.Size.Height = newBottomHeight
	bottomPanel.Position.Y += deltaHeight

	// Recalculate ratios
	pr.recalculateVerticalRatios(panels)

	return nil
}

// recalculateHorizontalRatios recalculates ratios after horizontal resize
func (pr *PanelResizer) recalculateHorizontalRatios(panels []*Panel) {
	totalWidth := 0
	for _, panel := range panels {
		totalWidth += panel.Size.Width
	}

	if totalWidth == 0 {
		return
	}

	newRatios := make([]float64, len(panels))
	for i, panel := range panels {
		newRatios[i] = float64(panel.Size.Width) / float64(totalWidth)
	}

	pr.manager.layout.Ratio = newRatios
}

// recalculateVerticalRatios recalculates ratios after vertical resize
func (pr *PanelResizer) recalculateVerticalRatios(panels []*Panel) {
	totalHeight := 0
	for _, panel := range panels {
		totalHeight += panel.Size.Height
	}

	if totalHeight == 0 {
		return
	}

	newRatios := make([]float64, len(panels))
	for i, panel := range panels {
		newRatios[i] = float64(panel.Size.Height) / float64(totalHeight)
	}

	pr.manager.layout.Ratio = newRatios
}

// IsResizing returns whether a resize operation is in progress
func (pr *PanelResizer) IsResizing() bool {
	return pr.resizing
}

// GetResizeMode returns the current resize mode
func (pr *PanelResizer) GetResizeMode() ResizeMode {
	return pr.resizeMode
}

// CanResize checks if a panel can be resized
func (pr *PanelResizer) CanResize(panelID PanelID) bool {
	panel, exists := pr.manager.panels[panelID]
	return exists && panel.Resizable
}
