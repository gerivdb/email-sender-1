package models

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/gerivdb/email-sender-1/cmd/roadmap-cli/priority"
	"github.com/gerivdb/email-sender-1/cmd/roadmap-cli/types"
)

// PriorityViewMode represents different priority view modes
type PriorityViewMode int

const (
	PriorityViewList PriorityViewMode = iota
	PriorityViewGraph
	PriorityViewMatrix
	PriorityViewFactors
)

// PriorityView implements tea.Model for priority visualization
type PriorityView struct {
	engine     *priority.Engine
	items      []types.RoadmapItem
	priorities map[string]priority.TaskPriority
	viewMode   PriorityViewMode
	width      int
	height     int
	selected   int
	active     bool
}

// NewPriorityView creates a new priority view component
func NewPriorityView(engine *priority.Engine, items []types.RoadmapItem) *PriorityView {
	pv := &PriorityView{
		engine:     engine,
		items:      items,
		priorities: make(map[string]priority.TaskPriority),
		viewMode:   PriorityViewList,
		selected:   0,
		active:     false,
	}

	// Calculate priorities for all items
	pv.calculatePriorities()

	return pv
}

// Init implements tea.Model
func (pv *PriorityView) Init() tea.Cmd {
	return nil
}

// Update implements tea.Model
func (pv *PriorityView) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		if !pv.active {
			return pv, nil
		}

		switch msg.String() {
		case "up", "k":
			if pv.selected > 0 {
				pv.selected--
			}
		case "down", "j":
			if pv.selected < len(pv.items)-1 {
				pv.selected++
			}
		case "tab":
			pv.cycleViewMode()
		case "r":
			pv.refreshPriorities()
		case "enter":
			// Toggle detailed view for selected item
			return pv, tea.Cmd(func() tea.Msg {
				return PriorityDetailMsg{ItemID: pv.items[pv.selected].ID}
			})
		}

	case tea.WindowSizeMsg:
		pv.width = msg.Width
		pv.height = msg.Height

	case PriorityRefreshMsg:
		pv.calculatePriorities()
	}

	return pv, nil
}

// View implements tea.Model
func (pv *PriorityView) View() string {
	if !pv.active {
		return ""
	}

	switch pv.viewMode {
	case PriorityViewList:
		return pv.renderListView()
	case PriorityViewGraph:
		return pv.renderGraphView()
	case PriorityViewMatrix:
		return pv.renderMatrixView()
	case PriorityViewFactors:
		return pv.renderFactorsView()
	default:
		return pv.renderListView()
	}
}

// SetActive sets the active state of the priority view
func (pv *PriorityView) SetActive(active bool) {
	pv.active = active
}

// IsActive returns whether the priority view is active
func (pv *PriorityView) IsActive() bool {
	return pv.active
}

// calculatePriorities calculates priorities for all items
func (pv *PriorityView) calculatePriorities() {
	for _, item := range pv.items {
		if priority, err := pv.engine.Calculate(item); err == nil {
			pv.priorities[item.ID] = priority
		}
	}
}

// refreshPriorities forces recalculation of all priorities
func (pv *PriorityView) refreshPriorities() {
	// Clear cache
	pv.priorities = make(map[string]priority.TaskPriority)
	pv.calculatePriorities()
}

// cycleViewMode cycles through different view modes
func (pv *PriorityView) cycleViewMode() {
	pv.viewMode = (pv.viewMode + 1) % 4
}

// renderListView renders the priority list view
func (pv *PriorityView) renderListView() string {
	var lines []string

	// Header
	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("39")).
		Border(lipgloss.NormalBorder(), false, false, true, false).
		Padding(0, 1)

	lines = append(lines, headerStyle.Render("Priority Rankings"))
	lines = append(lines, "")

	// Sort items by priority
	sortedItems := pv.getSortedItemsByPriority()

	for i, item := range sortedItems {
		priority := pv.priorities[item.ID]

		// Style based on selection
		style := lipgloss.NewStyle()
		if i == pv.selected {
			style = style.Background(lipgloss.Color("240"))
		}

		// Priority score color
		scoreColor := pv.getScoreColor(priority.Score)
		scoreStyle := lipgloss.NewStyle().Foreground(lipgloss.Color(scoreColor))

		line := fmt.Sprintf("%s %s %s",
			scoreStyle.Render(fmt.Sprintf("%.2f", priority.Score)),
			pv.getPriorityBar(priority.Score),
			item.Title)

		lines = append(lines, style.Render(line))
	}

	// Instructions
	lines = append(lines, "")
	instructionsStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("241")).
		Italic(true)

	lines = append(lines, instructionsStyle.Render("↑/↓: Navigate • Tab: Change view • R: Refresh • Enter: Details"))

	return strings.Join(lines, "\n")
}

// renderGraphView renders ASCII bar chart of priorities
func (pv *PriorityView) renderGraphView() string {
	var lines []string

	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("39")).
		Border(lipgloss.NormalBorder(), false, false, true, false).
		Padding(0, 1)

	lines = append(lines, headerStyle.Render("Priority Graph"))
	lines = append(lines, "")

	sortedItems := pv.getSortedItemsByPriority()
	maxWidth := pv.width - 20 // Reserve space for labels and scores

	for i, item := range sortedItems {
		if i >= 10 { // Show top 10 only
			break
		}

		priority := pv.priorities[item.ID]
		barWidth := int(priority.Score * float64(maxWidth) / 10.0) // Assuming max score is 10

		style := lipgloss.NewStyle()
		if i == pv.selected {
			style = style.Background(lipgloss.Color("240"))
		}

		scoreColor := pv.getScoreColor(priority.Score)
		bar := strings.Repeat("█", barWidth)
		coloredBar := lipgloss.NewStyle().Foreground(lipgloss.Color(scoreColor)).Render(bar)

		line := fmt.Sprintf("%-25s %s %.2f",
			pv.truncateTitle(item.Title, 25),
			coloredBar,
			priority.Score)

		lines = append(lines, style.Render(line))
	}

	return strings.Join(lines, "\n")
}

// renderMatrixView renders Eisenhower matrix view
func (pv *PriorityView) renderMatrixView() string {
	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("39")).
		Border(lipgloss.NormalBorder(), false, false, true, false).
		Padding(0, 1)

	lines := []string{headerStyle.Render("Eisenhower Matrix")}
	lines = append(lines, "")

	// Create 2x2 matrix
	quadrants := pv.categorizeByUrgencyImportance()

	// High Importance
	lines = append(lines, "                High Importance")
	lines = append(lines, "    ┌─────────────────┬─────────────────┐")
	lines = append(lines, fmt.Sprintf("H   │ DO (Urgent)     │ DECIDE (Plan)   │"))
	lines = append(lines, fmt.Sprintf("i   │ %d items        │ %d items        │",
		len(quadrants["urgent-important"]), len(quadrants["not-urgent-important"])))
	lines = append(lines, "g   ├─────────────────┼─────────────────┤")
	lines = append(lines, fmt.Sprintf("h   │ DELEGATE        │ DELETE          │"))
	lines = append(lines, fmt.Sprintf("    │ %d items        │ %d items        │",
		len(quadrants["urgent-not-important"]), len(quadrants["not-urgent-not-important"])))
	lines = append(lines, "    └─────────────────┴─────────────────┘")
	lines = append(lines, "    Low               High")
	lines = append(lines, "          Urgency")

	return strings.Join(lines, "\n")
}

// renderFactorsView renders detailed factor breakdown
func (pv *PriorityView) renderFactorsView() string {
	if pv.selected >= len(pv.items) {
		return "No item selected"
	}

	item := pv.items[pv.selected]
	priority := pv.priorities[item.ID]

	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("39")).
		Border(lipgloss.NormalBorder(), false, false, true, false).
		Padding(0, 1)

	lines := []string{headerStyle.Render(fmt.Sprintf("Priority Factors: %s", item.Title))}
	lines = append(lines, "")

	// Display factors
	for factor, value := range priority.Factors {
		bar := pv.getFactorBar(value)
		line := fmt.Sprintf("%-15s %s %.2f", string(factor), bar, value)
		lines = append(lines, line)
	}

	lines = append(lines, "")
	lines = append(lines, fmt.Sprintf("Overall Score: %.2f", priority.Score))
	lines = append(lines, fmt.Sprintf("Algorithm: %s", priority.Algorithm))
	lines = append(lines, fmt.Sprintf("Last Calculated: %s", priority.LastCalculated.Format("15:04:05")))

	return strings.Join(lines, "\n")
}

// Helper functions

func (pv *PriorityView) getSortedItemsByPriority() []types.RoadmapItem {
	// Sort items by priority score (descending)
	sortedItems := make([]types.RoadmapItem, len(pv.items))
	copy(sortedItems, pv.items)

	// Simple bubble sort for now
	for i := 0; i < len(sortedItems)-1; i++ {
		for j := 0; j < len(sortedItems)-i-1; j++ {
			score1 := pv.priorities[sortedItems[j].ID].Score
			score2 := pv.priorities[sortedItems[j+1].ID].Score
			if score1 < score2 {
				sortedItems[j], sortedItems[j+1] = sortedItems[j+1], sortedItems[j]
			}
		}
	}

	return sortedItems
}

func (pv *PriorityView) getScoreColor(score float64) string {
	switch {
	case score >= 8.0:
		return "196" // Red - Critical
	case score >= 6.0:
		return "208" // Orange - High
	case score >= 4.0:
		return "226" // Yellow - Medium
	default:
		return "46" // Green - Low
	}
}

func (pv *PriorityView) getPriorityBar(score float64) string {
	barLength := int(score * 10 / 10) // Normalize to 10 chars max
	if barLength > 10 {
		barLength = 10
	}
	return fmt.Sprintf("[%s%s]",
		strings.Repeat("█", barLength),
		strings.Repeat("░", 10-barLength))
}

func (pv *PriorityView) getFactorBar(value float64) string {
	barLength := int(value * 20) // 20 chars max
	if barLength > 20 {
		barLength = 20
	}
	return fmt.Sprintf("[%s%s]",
		strings.Repeat("█", barLength),
		strings.Repeat("░", 20-barLength))
}

func (pv *PriorityView) truncateTitle(title string, maxLen int) string {
	if len(title) <= maxLen {
		return title
	}
	return title[:maxLen-3] + "..."
}

func (pv *PriorityView) categorizeByUrgencyImportance() map[string][]types.RoadmapItem {
	quadrants := map[string][]types.RoadmapItem{
		"urgent-important":         {},
		"urgent-not-important":     {},
		"not-urgent-important":     {},
		"not-urgent-not-important": {},
	}
	for _, item := range pv.items {
		priority := pv.priorities[item.ID]
		urgency := priority.Factors["urgency"]
		importance := priority.Factors["impact"]

		key := ""
		if urgency > 0.5 && importance > 0.5 {
			key = "urgent-important"
		} else if urgency > 0.5 && importance <= 0.5 {
			key = "urgent-not-important"
		} else if urgency <= 0.5 && importance > 0.5 {
			key = "not-urgent-important"
		} else {
			key = "not-urgent-not-important"
		}

		quadrants[key] = append(quadrants[key], item)
	}

	return quadrants
}

// Message types for priority view communication
type (
	PriorityRefreshMsg struct{}
	PriorityDetailMsg  struct {
		ItemID string
	}
)
