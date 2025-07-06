package models

import (
	"fmt"
	"strconv"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/gerivdb/email-sender-1/cmd/roadmap-cli/priority"
	"github.com/gerivdb/email-sender-1/cmd/roadmap-cli/types"
)

// InteractivePriorityWidget provides real-time priority adjustment
type InteractivePriorityWidget struct {
	engine        *priority.Engine
	item          *types.RoadmapItem
	config        priority.WeightingConfig
	selectedField int
	editing       bool
	editValue     string
	width         int
	height        int
	active        bool
}

// WeightField represents a configurable weight field
type WeightField struct {
	Name        string
	Key         string
	Value       *float64
	Description string
}

// NewInteractivePriorityWidget creates a new interactive priority widget
func NewInteractivePriorityWidget(engine *priority.Engine) *InteractivePriorityWidget {
	return &InteractivePriorityWidget{
		engine:        engine,
		config:        engine.GetWeightingConfig(),
		selectedField: 0,
		editing:       false,
		active:        false,
	}
}

// Init implements tea.Model
func (ipw *InteractivePriorityWidget) Init() tea.Cmd {
	return nil
}

// Update implements tea.Model
func (ipw *InteractivePriorityWidget) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	if !ipw.active {
		return ipw, nil
	}

	switch msg := msg.(type) {
	case tea.KeyMsg:
		if ipw.editing {
			return ipw.handleEditingKeys(msg)
		}
		return ipw.handleNavigationKeys(msg)

	case tea.WindowSizeMsg:
		ipw.width = msg.Width
		ipw.height = msg.Height

	case PriorityItemSelectedMsg:
		ipw.item = &msg.Item
		ipw.config = ipw.engine.GetWeightingConfig()
	}

	return ipw, nil
}

// View implements tea.Model
func (ipw *InteractivePriorityWidget) View() string {
	if !ipw.active || ipw.item == nil {
		return ""
	}

	var sections []string

	// Header
	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("39")).
		Border(lipgloss.NormalBorder(), false, false, true, false).
		Padding(0, 1)

	sections = append(sections, headerStyle.Render("Priority Configuration"))
	sections = append(sections, "")

	// Item info
	itemStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("245")).
		Italic(true)

	sections = append(sections, itemStyle.Render(fmt.Sprintf("Item: %s", ipw.item.Title)))
	sections = append(sections, "")

	// Weight fields
	fields := ipw.getWeightFields()
	for i, field := range fields {
		sections = append(sections, ipw.renderWeightField(field, i == ipw.selectedField))
	}

	sections = append(sections, "")

	// Current priority calculation
	if priority, err := ipw.engine.Calculate(*ipw.item); err == nil {
		sections = append(sections, ipw.renderCurrentPriority(priority))
	}

	sections = append(sections, "")

	// Instructions
	instructionsStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("241")).
		Italic(true)

	if ipw.editing {
		sections = append(sections, instructionsStyle.Render("Type value • Enter: Save • Esc: Cancel"))
	} else {
		sections = append(sections, instructionsStyle.Render("↑/↓: Navigate • Enter: Edit • S: Save config • R: Reset to defaults"))
	}

	return strings.Join(sections, "\n")
}

// SetActive sets the active state
func (ipw *InteractivePriorityWidget) SetActive(active bool) {
	ipw.active = active
}

// IsActive returns whether the widget is active
func (ipw *InteractivePriorityWidget) IsActive() bool {
	return ipw.active
}

// SetItem sets the current item for priority adjustment
func (ipw *InteractivePriorityWidget) SetItem(item types.RoadmapItem) {
	ipw.item = &item
}

// handleNavigationKeys handles navigation key presses
func (ipw *InteractivePriorityWidget) handleNavigationKeys(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	fields := ipw.getWeightFields()

	switch msg.String() {
	case "up", "k":
		if ipw.selectedField > 0 {
			ipw.selectedField--
		}

	case "down", "j":
		if ipw.selectedField < len(fields)-1 {
			ipw.selectedField++
		}

	case "enter":
		ipw.startEditing()

	case "s":
		return ipw, ipw.saveConfiguration()

	case "r":
		ipw.resetToDefaults()
		return ipw, ipw.updateEngine()

	case "q":
		ipw.active = false
	}

	return ipw, nil
}

// handleEditingKeys handles key presses while editing a value
func (ipw *InteractivePriorityWidget) handleEditingKeys(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "enter":
		return ipw, ipw.saveEdit()

	case "esc":
		ipw.cancelEdit()

	case "backspace":
		if len(ipw.editValue) > 0 {
			ipw.editValue = ipw.editValue[:len(ipw.editValue)-1]
		}

	default:
		// Allow typing numbers and decimal point
		if len(msg.String()) == 1 {
			char := msg.String()
			if (char >= "0" && char <= "9") || char == "." {
				if len(ipw.editValue) < 5 { // Limit length
					ipw.editValue += char
				}
			}
		}
	}

	return ipw, nil
}

// getWeightFields returns the list of configurable weight fields
func (ipw *InteractivePriorityWidget) getWeightFields() []WeightField {
	return []WeightField{
		{
			Name:        "Urgency",
			Key:         "urgency",
			Value:       &ipw.config.Urgency,
			Description: "How urgent is this task (time-sensitive)",
		},
		{
			Name:        "Impact",
			Key:         "impact",
			Value:       &ipw.config.Impact,
			Description: "Business/project impact",
		},
		{
			Name:        "Effort",
			Key:         "effort",
			Value:       &ipw.config.Effort,
			Description: "Required effort and complexity",
		},
		{
			Name:        "Dependencies",
			Key:         "dependencies",
			Value:       &ipw.config.Dependencies,
			Description: "Dependency blocking factor",
		},
		{
			Name:        "Business Value",
			Key:         "business_value",
			Value:       &ipw.config.BusinessValue,
			Description: "Expected business value",
		},
		{
			Name:        "Risk",
			Key:         "risk",
			Value:       &ipw.config.Risk,
			Description: "Associated risks",
		},
	}
}

// renderWeightField renders a single weight configuration field
func (ipw *InteractivePriorityWidget) renderWeightField(field WeightField, selected bool) string {
	style := lipgloss.NewStyle().Padding(0, 1)

	if selected {
		style = style.Background(lipgloss.Color("240"))
	}

	var valueStr string
	if ipw.editing && selected {
		valueStr = fmt.Sprintf("%.3f [%s]", *field.Value, ipw.editValue)
	} else {
		valueStr = fmt.Sprintf("%.3f", *field.Value)
	}

	// Create progress bar for visual representation
	bar := ipw.createWeightBar(*field.Value)

	line := fmt.Sprintf("%-15s %s %s %s",
		field.Name,
		valueStr,
		bar,
		field.Description)

	return style.Render(line)
}

// renderCurrentPriority renders the current priority calculation
func (ipw *InteractivePriorityWidget) renderCurrentPriority(priority priority.TaskPriority) string {
	var lines []string

	priorityStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(ipw.getScoreColor(priority.Score))

	lines = append(lines, priorityStyle.Render(fmt.Sprintf("Current Priority Score: %.2f", priority.Score)))

	// Show factor breakdown
	for factor, value := range priority.Factors {
		bar := ipw.createFactorBar(value)
		line := fmt.Sprintf("  %-12s %.2f %s", string(factor), value, bar)
		lines = append(lines, line)
	}

	return strings.Join(lines, "\n")
}

// createWeightBar creates a visual bar for weight values (0.0-1.0)
func (ipw *InteractivePriorityWidget) createWeightBar(value float64) string {
	barLength := int(value * 20) // 20 chars max
	if barLength > 20 {
		barLength = 20
	}
	return fmt.Sprintf("[%s%s]",
		strings.Repeat("█", barLength),
		strings.Repeat("░", 20-barLength))
}

// createFactorBar creates a visual bar for factor values
func (ipw *InteractivePriorityWidget) createFactorBar(value float64) string {
	barLength := int(value * 15) // 15 chars max
	if barLength > 15 {
		barLength = 15
	}
	return fmt.Sprintf("[%s%s]",
		strings.Repeat("█", barLength),
		strings.Repeat("░", 15-barLength))
}

// getScoreColor returns color based on priority score
func (ipw *InteractivePriorityWidget) getScoreColor(score float64) lipgloss.Color {
	switch {
	case score >= 8.0:
		return lipgloss.Color("196") // Red - Critical
	case score >= 6.0:
		return lipgloss.Color("208") // Orange - High
	case score >= 4.0:
		return lipgloss.Color("226") // Yellow - Medium
	default:
		return lipgloss.Color("46") // Green - Low
	}
}

// startEditing begins editing the selected field
func (ipw *InteractivePriorityWidget) startEditing() {
	fields := ipw.getWeightFields()
	if ipw.selectedField < len(fields) {
		field := fields[ipw.selectedField]
		ipw.editValue = fmt.Sprintf("%.3f", *field.Value)
		ipw.editing = true
	}
}

// saveEdit saves the edited value
func (ipw *InteractivePriorityWidget) saveEdit() tea.Cmd {
	fields := ipw.getWeightFields()
	if ipw.selectedField < len(fields) {
		if value, err := strconv.ParseFloat(ipw.editValue, 64); err == nil {
			// Clamp value between 0.0 and 1.0
			if value < 0.0 {
				value = 0.0
			} else if value > 1.0 {
				value = 1.0
			}

			field := fields[ipw.selectedField]
			*field.Value = value
		}
	}

	ipw.editing = false
	ipw.editValue = ""

	return ipw.updateEngine()
}

// cancelEdit cancels the current edit
func (ipw *InteractivePriorityWidget) cancelEdit() {
	ipw.editing = false
	ipw.editValue = ""
}

// saveConfiguration saves the current configuration
func (ipw *InteractivePriorityWidget) saveConfiguration() tea.Cmd {
	return ipw.updateEngine()
}

// resetToDefaults resets all weights to default values
func (ipw *InteractivePriorityWidget) resetToDefaults() {
	ipw.config = priority.DefaultWeightingConfig()
}

// updateEngine updates the engine with the current configuration
func (ipw *InteractivePriorityWidget) updateEngine() tea.Cmd {
	ipw.engine.SetWeightingConfig(ipw.config)
	return tea.Cmd(func() tea.Msg {
		return PriorityConfigUpdatedMsg{Config: ipw.config}
	})
}

// Message types
type PriorityItemSelectedMsg struct {
	Item types.RoadmapItem
}

type PriorityConfigUpdatedMsg struct {
	Config priority.WeightingConfig
}
