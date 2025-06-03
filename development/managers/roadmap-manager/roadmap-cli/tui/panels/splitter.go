package panels

import (
	"math"
)

// PanelSplitter handles panel splitting operations
type PanelSplitter struct {
	manager *PanelManager
}

// NewPanelSplitter creates a new panel splitter
func NewPanelSplitter(manager *PanelManager) *PanelSplitter {
	return &PanelSplitter{
		manager: manager,
	}
}

// Horizontal splits panels horizontally with given ratios
func (ps *PanelSplitter) Horizontal(ratios ...float64) error {
	if len(ratios) == 0 {
		ratios = []float64{0.5, 0.5}
	}

	// Normalize ratios to sum to 1.0
	ratios = ps.normalizeRatios(ratios)

	// Validate ratios
	if err := ps.validateRatios(ratios); err != nil {
		return err
	}

	// Apply horizontal layout
	return ps.applyHorizontalLayout(ratios)
}

// Vertical splits panels vertically with given ratios
func (ps *PanelSplitter) Vertical(ratios ...float64) error {
	if len(ratios) == 0 {
		ratios = []float64{0.5, 0.5}
	}

	// Normalize ratios to sum to 1.0
	ratios = ps.normalizeRatios(ratios)

	// Validate ratios
	if err := ps.validateRatios(ratios); err != nil {
		return err
	}

	// Apply vertical layout
	return ps.applyVerticalLayout(ratios)
}

// normalizeRatios ensures ratios sum to 1.0
func (ps *PanelSplitter) normalizeRatios(ratios []float64) []float64 {
	sum := 0.0
	for _, ratio := range ratios {
		sum += ratio
	}

	if sum == 0 {
		return ratios
	}

	normalized := make([]float64, len(ratios))
	for i, ratio := range ratios {
		normalized[i] = ratio / sum
	}

	return normalized
}

// validateRatios validates that ratios are valid
func (ps *PanelSplitter) validateRatios(ratios []float64) error {
	if len(ratios) > ps.manager.maxPanels {
		return ErrMaxPanelsReached
	}

	for _, ratio := range ratios {
		if ratio < 0.1 { // Minimum 10% width/height
			return ErrMinSizeViolation
		}
	}

	return nil
}

// applyHorizontalLayout applies horizontal split layout
func (ps *PanelSplitter) applyHorizontalLayout(ratios []float64) error {
	visiblePanels := ps.getVisiblePanels()
	if len(visiblePanels) == 0 {
		return nil
	}

	// Calculate panel widths
	totalWidth := ps.manager.width - (len(ratios)-1)*ps.manager.layout.Padding
	currentX := 0

	for i, panel := range visiblePanels {
		if i >= len(ratios) {
			break
		}

		width := int(float64(totalWidth) * ratios[i])

		// Ensure minimum width
		if width < ps.manager.minPanelSize.Width {
			width = ps.manager.minPanelSize.Width
		}

		panel.Position.X = currentX
		panel.Position.Y = 0
		panel.Size.Width = width
		panel.Size.Height = ps.manager.height

		currentX += width + ps.manager.layout.Padding
	}

	ps.manager.layout.Type = LayoutHorizontal
	ps.manager.layout.Ratio = ratios

	return nil
}

// applyVerticalLayout applies vertical split layout
func (ps *PanelSplitter) applyVerticalLayout(ratios []float64) error {
	visiblePanels := ps.getVisiblePanels()
	if len(visiblePanels) == 0 {
		return nil
	}

	// Calculate panel heights
	totalHeight := ps.manager.height - (len(ratios)-1)*ps.manager.layout.Padding
	currentY := 0

	for i, panel := range visiblePanels {
		if i >= len(ratios) {
			break
		}

		height := int(float64(totalHeight) * ratios[i])

		// Ensure minimum height
		if height < ps.manager.minPanelSize.Height {
			height = ps.manager.minPanelSize.Height
		}

		panel.Position.X = 0
		panel.Position.Y = currentY
		panel.Size.Width = ps.manager.width
		panel.Size.Height = height

		currentY += height + ps.manager.layout.Padding
	}

	ps.manager.layout.Type = LayoutVertical
	ps.manager.layout.Ratio = ratios

	return nil
}

// getVisiblePanels returns all visible panels in order
func (ps *PanelSplitter) getVisiblePanels() []*Panel {
	var visible []*Panel

	for _, id := range ps.manager.panelOrder {
		if panel, exists := ps.manager.panels[id]; exists && panel.Visible && !panel.Minimized {
			visible = append(visible, panel)
		}
	}

	return visible
}

// arrangeHorizontal arranges panels horizontally (called by PanelManager)
func (pm *PanelManager) arrangeHorizontal() {
	splitter := NewPanelSplitter(pm)
	if len(pm.layout.Ratio) > 0 {
		splitter.Horizontal(pm.layout.Ratio...)
	} else {
		splitter.Horizontal()
	}
}

// arrangeVertical arranges panels vertically (called by PanelManager)
func (pm *PanelManager) arrangeVertical() {
	splitter := NewPanelSplitter(pm)
	if len(pm.layout.Ratio) > 0 {
		splitter.Vertical(pm.layout.Ratio...)
	} else {
		splitter.Vertical()
	}
}

// arrangeGrid arranges panels in a grid layout
func (pm *PanelManager) arrangeGrid() {
	visiblePanels := pm.getVisiblePanels()
	if len(visiblePanels) == 0 {
		return
	}

	// Calculate grid dimensions
	cols := int(math.Ceil(math.Sqrt(float64(len(visiblePanels)))))
	rows := int(math.Ceil(float64(len(visiblePanels)) / float64(cols)))

	panelWidth := pm.width / cols
	panelHeight := pm.height / rows

	for i, panel := range visiblePanels {
		col := i % cols
		row := i / cols

		panel.Position.X = col * panelWidth
		panel.Position.Y = row * panelHeight
		panel.Size.Width = panelWidth - pm.layout.Padding
		panel.Size.Height = panelHeight - pm.layout.Padding
	}

	pm.layout.Type = LayoutGrid
}

// arrangeFloating maintains floating positions
func (pm *PanelManager) arrangeFloating() {
	pm.layout.Type = LayoutFloating
	// Floating panels maintain their current positions
}

// arrangeTabs arranges panels as tabs (only active panel visible)
func (pm *PanelManager) arrangeTabs() {
	for id, panel := range pm.panels {
		if id == pm.activePanel {
			panel.Position.X = 0
			panel.Position.Y = 0
			panel.Size.Width = pm.width
			panel.Size.Height = pm.height - 3 // Leave space for tab bar
			panel.Visible = true
		} else {
			panel.Visible = false
		}
	}

	pm.layout.Type = LayoutTabs
}

// getVisiblePanels helper for PanelManager
func (pm *PanelManager) getVisiblePanels() []*Panel {
	var visible []*Panel

	for _, id := range pm.panelOrder {
		if panel, exists := pm.panels[id]; exists && panel.Visible && !panel.Minimized {
			visible = append(visible, panel)
		}
	}

	return visible
}
