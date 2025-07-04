package models

import (
	"fmt"
	"math"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/gerivdb/email-sender-1/cmd/roadmap-cli/priority"
	"github.com/gerivdb/email-sender-1/cmd/roadmap-cli/types"
)

// PriorityVisualization provides ASCII graphics for priority data
type PriorityVisualization struct {
	engine     *priority.Engine
	items      []types.RoadmapItem
	priorities map[string]priority.TaskPriority
	width      int
	height     int
	active     bool
	viewType   VisualizationType
	animated   bool
	animFrame  int
}

// VisualizationType represents different visualization types
type VisualizationType int

const (
	VisTypeBarChart VisualizationType = iota
	VisTypeScatterPlot
	VisTypeHeatmap
	VisTypeTimeline
	VisTypeRadarChart
)

// NewPriorityVisualization creates a new priority visualization component
func NewPriorityVisualization(engine *priority.Engine, items []types.RoadmapItem) *PriorityVisualization {
	pv := &PriorityVisualization{
		engine:     engine,
		items:      items,
		priorities: make(map[string]priority.TaskPriority),
		viewType:   VisTypeBarChart,
		animated:   false,
		animFrame:  0,
	}

	pv.calculatePriorities()
	return pv
}

// Init implements tea.Model
func (pv *PriorityVisualization) Init() tea.Cmd {
	return nil
}

// Update implements tea.Model
func (pv *PriorityVisualization) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	if !pv.active {
		return pv, nil
	}

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "1":
			pv.viewType = VisTypeBarChart
		case "2":
			pv.viewType = VisTypeScatterPlot
		case "3":
			pv.viewType = VisTypeHeatmap
		case "4":
			pv.viewType = VisTypeTimeline
		case "5":
			pv.viewType = VisTypeRadarChart
		case "a":
			pv.animated = !pv.animated
		case "r":
			pv.calculatePriorities()
		}

	case tea.WindowSizeMsg:
		pv.width = msg.Width
		pv.height = msg.Height

	case PriorityRefreshMsg:
		pv.calculatePriorities()

	case AnimationTickMsg:
		if pv.animated {
			pv.animFrame = (pv.animFrame + 1) % 60
			return pv, tea.Tick(100*1000*1000, func(t time.Time) tea.Msg { // 100ms
				return AnimationTickMsg{}
			})
		}
	}

	return pv, nil
}

// View implements tea.Model
func (pv *PriorityVisualization) View() string {
	if !pv.active {
		return ""
	}

	switch pv.viewType {
	case VisTypeBarChart:
		return pv.renderBarChart()
	case VisTypeScatterPlot:
		return pv.renderScatterPlot()
	case VisTypeHeatmap:
		return pv.renderHeatmap()
	case VisTypeTimeline:
		return pv.renderTimeline()
	case VisTypeRadarChart:
		return pv.renderRadarChart()
	default:
		return pv.renderBarChart()
	}
}

// SetActive sets the active state
func (pv *PriorityVisualization) SetActive(active bool) {
	pv.active = active
}

// IsActive returns whether the visualization is active
func (pv *PriorityVisualization) IsActive() bool {
	return pv.active
}

// calculatePriorities calculates priorities for all items
func (pv *PriorityVisualization) calculatePriorities() {
	for _, item := range pv.items {
		if priority, err := pv.engine.Calculate(item); err == nil {
			pv.priorities[item.ID] = priority
		}
	}
}

// renderBarChart renders an ASCII bar chart of priorities
func (pv *PriorityVisualization) renderBarChart() string {
	var lines []string

	// Header
	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("39")).
		Border(lipgloss.NormalBorder(), false, false, true, false).
		Padding(0, 1)

	lines = append(lines, headerStyle.Render("Priority Bar Chart"))
	lines = append(lines, "")
	// Get sorted items
	sortedItems := pv.getSortedItemsByPriority()
	chartWidth := pv.width - 30 // Reserve space for labels
	if chartWidth < 20 {
		chartWidth = 20
	}

	// Handle empty items case
	if len(sortedItems) == 0 {
		lines = append(lines, "No items to display")
		return strings.Join(lines, "\n")
	}

	// Find max score for scaling
	maxScore := 0.0
	for _, item := range sortedItems {
		if score := pv.priorities[item.ID].Score; score > maxScore {
			maxScore = score
		}
	}

	// Y-axis scale
	yAxisLines := []string{}
	for i := 10; i >= 0; i-- {
		value := maxScore * float64(i) / 10.0
		yAxisLines = append(yAxisLines, fmt.Sprintf("%6.1f │", value))
	}

	// Chart area
	chartHeight := len(yAxisLines)
	chart := make([][]rune, chartHeight)
	for i := range chart {
		chart[i] = make([]rune, chartWidth)
		for j := range chart[i] {
			chart[i][j] = ' '
		}
	}

	// Plot bars
	barWidth := chartWidth / len(sortedItems)
	if barWidth < 1 {
		barWidth = 1
	}

	for i, item := range sortedItems {
		if i*barWidth >= chartWidth {
			break
		}

		score := pv.priorities[item.ID].Score
		barHeight := int(score * float64(chartHeight-1) / maxScore)

		// Animation effect
		if pv.animated {
			animOffset := float64(pv.animFrame) / 60.0
			barHeight = int(float64(barHeight) * (0.5 + 0.5*math.Sin(animOffset*2*math.Pi)))
		}

		// Draw bar
		for y := 0; y < barHeight && y < chartHeight; y++ {
			for x := i * barWidth; x < (i+1)*barWidth && x < chartWidth; x++ {
				chart[chartHeight-1-y][x] = '█'
			}
		}
	}

	// Combine Y-axis with chart
	for i, yLine := range yAxisLines {
		if i < len(chart) {
			chartLine := string(chart[i])
			lines = append(lines, yLine+chartLine)
		}
	}

	// X-axis labels
	lines = append(lines, strings.Repeat(" ", 7)+strings.Repeat("─", chartWidth))

	// Item labels (truncated)
	labelLine := strings.Repeat(" ", 7)
	for i, item := range sortedItems {
		if i*barWidth >= chartWidth {
			break
		}

		label := pv.truncateString(item.Title, barWidth-1)
		labelLine += fmt.Sprintf("%-*s", barWidth, label)
	}
	lines = append(lines, labelLine)

	// Instructions
	lines = append(lines, "")
	instructionsStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("241")).
		Italic(true)
	lines = append(lines, instructionsStyle.Render("1-5: Switch views • A: Toggle animation • R: Refresh"))

	return strings.Join(lines, "\n")
}

// renderScatterPlot renders a scatter plot of Urgency vs Impact
func (pv *PriorityVisualization) renderScatterPlot() string {
	var lines []string

	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("39")).
		Border(lipgloss.NormalBorder(), false, false, true, false).
		Padding(0, 1)

	lines = append(lines, headerStyle.Render("Priority Scatter Plot (Urgency vs Impact)"))
	lines = append(lines, "")

	plotWidth := pv.width - 10
	plotHeight := pv.height - 10
	if plotWidth < 40 {
		plotWidth = 40
	}
	if plotHeight < 20 {
		plotHeight = 20
	}

	// Create plot grid
	plot := make([][]rune, plotHeight)
	for i := range plot {
		plot[i] = make([]rune, plotWidth)
		for j := range plot[i] {
			plot[i][j] = '·'
		}
	}
	// Plot points
	for _, item := range pv.items {
		priority := pv.priorities[item.ID]
		urgency := priority.Factors["urgency"]
		impact := priority.Factors["impact"]

		x := int(urgency * float64(plotWidth-1))
		y := int((1.0 - impact) * float64(plotHeight-1)) // Invert Y for display

		if x >= 0 && x < plotWidth && y >= 0 && y < plotHeight {
			// Color based on priority score
			score := priority.Score
			var symbol rune
			switch {
			case score >= 8.0:
				symbol = '●' // High priority
			case score >= 6.0:
				symbol = '◆' // Medium-high priority
			case score >= 4.0:
				symbol = '▲' // Medium priority
			default:
				symbol = '○' // Low priority
			}
			plot[y][x] = symbol
		}
	}

	// Add axes
	for y := 0; y < plotHeight; y++ {
		plot[y][0] = '│' // Y-axis
	}
	for x := 0; x < plotWidth; x++ {
		plot[plotHeight-1][x] = '─' // X-axis
	}
	plot[plotHeight-1][0] = '└' // Corner

	// Render plot
	for _, row := range plot {
		lines = append(lines, "  "+string(row))
	}

	// Labels
	lines = append(lines, "")
	lines = append(lines, "  Urgency →")
	lines = append(lines, "Impact ↑")
	lines = append(lines, "")
	lines = append(lines, "Legend: ● High(8+) ◆ Med-High(6+) ▲ Medium(4+) ○ Low(<4)")

	return strings.Join(lines, "\n")
}

// renderHeatmap renders a priority heatmap
func (pv *PriorityVisualization) renderHeatmap() string {
	var lines []string

	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("39")).
		Border(lipgloss.NormalBorder(), false, false, true, false).
		Padding(0, 1)

	lines = append(lines, headerStyle.Render("Priority Heatmap"))
	lines = append(lines, "")

	// Create grid for heatmap
	gridSize := 10
	heatmap := make([][]float64, gridSize)
	counts := make([][]int, gridSize)
	for i := range heatmap {
		heatmap[i] = make([]float64, gridSize)
		counts[i] = make([]int, gridSize)
	}
	// Populate heatmap
	for _, item := range pv.items {
		priority := pv.priorities[item.ID]
		urgency := priority.Factors["urgency"]
		impact := priority.Factors["impact"]

		x := int(urgency * float64(gridSize-1))
		y := int(impact * float64(gridSize-1))

		if x >= 0 && x < gridSize && y >= 0 && y < gridSize {
			heatmap[y][x] += priority.Score
			counts[y][x]++
		}
	}

	// Average the values
	for i := 0; i < gridSize; i++ {
		for j := 0; j < gridSize; j++ {
			if counts[i][j] > 0 {
				heatmap[i][j] /= float64(counts[i][j])
			}
		}
	}

	// Render heatmap
	heatSymbols := []string{" ", "░", "▒", "▓", "█"}
	for i := gridSize - 1; i >= 0; i-- { // Flip Y for display
		line := ""
		for j := 0; j < gridSize; j++ {
			intensity := int(heatmap[i][j] / 10.0 * float64(len(heatSymbols)-1))
			if intensity >= len(heatSymbols) {
				intensity = len(heatSymbols) - 1
			}
			line += heatSymbols[intensity] + heatSymbols[intensity] // Double width
		}
		lines = append(lines, "  "+line)
	}

	// Labels
	lines = append(lines, "")
	lines = append(lines, "  "+strings.Repeat("─", gridSize*2))
	lines = append(lines, "  Urgency →")
	lines = append(lines, "Impact ↑")

	return strings.Join(lines, "\n")
}

// renderTimeline renders a priority timeline
func (pv *PriorityVisualization) renderTimeline() string {
	var lines []string

	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("39")).
		Border(lipgloss.NormalBorder(), false, false, true, false).
		Padding(0, 1)

	lines = append(lines, headerStyle.Render("Priority Timeline"))
	lines = append(lines, "")

	// Sort items by target date
	sortedItems := make([]types.RoadmapItem, len(pv.items))
	copy(sortedItems, pv.items)

	// Simple sort by target date
	for i := 0; i < len(sortedItems)-1; i++ {
		for j := 0; j < len(sortedItems)-i-1; j++ {
			if sortedItems[j].TargetDate.After(sortedItems[j+1].TargetDate) {
				sortedItems[j], sortedItems[j+1] = sortedItems[j+1], sortedItems[j]
			}
		}
	}

	// Render timeline
	timelineWidth := pv.width - 20
	if timelineWidth < 40 {
		timelineWidth = 40
	}

	for i, item := range sortedItems {
		if i >= 15 { // Limit display
			break
		}

		priority := pv.priorities[item.ID]

		// Priority indicator
		priorityChar := pv.getPriorityChar(priority.Score)

		// Timeline bar
		barLength := int(priority.Score * float64(timelineWidth) / 10.0)
		bar := strings.Repeat("█", barLength)

		// Color based on priority
		color := pv.getScoreColor(priority.Score)
		coloredBar := lipgloss.NewStyle().Foreground(lipgloss.Color(color)).Render(bar)

		// Date
		dateStr := item.TargetDate.Format("01/02")

		line := fmt.Sprintf("%s %s %-*s %s %.1f",
			priorityChar,
			dateStr,
			timelineWidth,
			coloredBar,
			pv.truncateString(item.Title, 30),
			priority.Score)

		lines = append(lines, line)
	}

	return strings.Join(lines, "\n")
}

// renderRadarChart renders a simplified radar chart for priority factors
func (pv *PriorityVisualization) renderRadarChart() string {
	var lines []string

	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("39")).
		Border(lipgloss.NormalBorder(), false, false, true, false).
		Padding(0, 1)

	lines = append(lines, headerStyle.Render("Priority Factors Radar (Selected Item)"))
	lines = append(lines, "")

	// For simplicity, show average of all items
	if len(pv.items) == 0 {
		return "No items to display"
	}
	// Calculate average factors
	avgFactors := make(map[string]float64)
	factorNames := []string{
		"urgency",
		"impact",
		"effort",
		"dependencies",
		"business_value",
		"risk",
	}
	for _, factor := range factorNames {
		total := 0.0
		count := 0
		for _, item := range pv.items {
			if p, exists := pv.priorities[item.ID]; exists {
				if value, exists := p.Factors[priority.PriorityFactor(factor)]; exists {
					total += value
					count++
				}
			}
		}
		if count > 0 {
			avgFactors[factor] = total / float64(count)
		}
	}
	// Simplified radar display
	for _, factor := range factorNames {
		value := avgFactors[factor]
		bar := pv.createRadarBar(value)
		line := fmt.Sprintf("%-15s %s %.2f", factor, bar, value)
		lines = append(lines, line)
	}

	return strings.Join(lines, "\n")
}

// Helper functions

func (pv *PriorityVisualization) getSortedItemsByPriority() []types.RoadmapItem {
	sortedItems := make([]types.RoadmapItem, len(pv.items))
	copy(sortedItems, pv.items)

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

func (pv *PriorityVisualization) getScoreColor(score float64) string {
	switch {
	case score >= 8.0:
		return "196" // Red
	case score >= 6.0:
		return "208" // Orange
	case score >= 4.0:
		return "226" // Yellow
	default:
		return "46" // Green
	}
}

func (pv *PriorityVisualization) getPriorityChar(score float64) string {
	switch {
	case score >= 8.0:
		return "🔴"
	case score >= 6.0:
		return "🟠"
	case score >= 4.0:
		return "🟡"
	default:
		return "🟢"
	}
}

func (pv *PriorityVisualization) createRadarBar(value float64) string {
	barLength := int(value * 20)
	if barLength > 20 {
		barLength = 20
	}
	return fmt.Sprintf("[%s%s]",
		strings.Repeat("█", barLength),
		strings.Repeat("░", 20-barLength))
}

func (pv *PriorityVisualization) truncateString(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen-3] + "..."
}

// Message types
type AnimationTickMsg struct{}
