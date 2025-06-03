package tui

import (
	"fmt"
	"strings"

	"email_sender/cmd/roadmap-cli/types"

	"github.com/charmbracelet/lipgloss"
)

// View renders the TUI based on current view mode
func (m *RoadmapModel) View() string {
	if m.quitting {
		return "Thanks for using roadmap-cli! 👋\n"
	}

	header := m.renderHeader()
	content := m.renderContent()
	statusBar := m.renderStatusBar()
	help := m.renderHelp()

	return lipgloss.JoinVertical(
		lipgloss.Left,
		header,
		"",
		content,
		"",
		statusBar,
		help,
	)
}

func (m *RoadmapModel) renderHeader() string {
	title := "🗺️  Roadmap CLI"

	viewName := ""
	switch m.currentView {
	case ViewModeList:
		viewName = "List View"
	case ViewModeTimeline:
		viewName = "Timeline View"
	case ViewModeKanban:
		viewName = "Kanban View"
	case ViewModePriority:
		switch m.priorityMode {
		case PriorityModeList:
			viewName = "Priority List"
		case PriorityModeConfig:
			viewName = "Priority Config"
		case PriorityModeVisualization:
			viewName = "Priority Visualization"
		}
	}

	header := fmt.Sprintf("%s - %s", title, viewName)

	// Add priority indicator if enabled
	if m.showPriorityScores && m.selectedIndex < len(m.items) {
		selectedItem := m.items[m.selectedIndex]
		if priority, err := m.priorityEngine.Calculate(selectedItem); err == nil {
			header += fmt.Sprintf(" | Priority: %.2f", priority.Score)
		}
	}

	return HeaderStyle.Render(header)
}

func (m *RoadmapModel) renderContent() string {
	switch m.currentView {
	case ViewModeList:
		return m.renderListView()
	case ViewModeTimeline:
		return m.renderTimelineView()
	case ViewModeKanban:
		return m.renderKanbanView()
	case ViewModePriority:
		return m.renderPriorityView()
	default:
		return m.renderListView()
	}
}

func (m *RoadmapModel) renderListView() string {
	if len(m.items) == 0 {
		return "No roadmap items found. Create some with 'roadmap-cli create item'"
	}

	var lines []string
	for i, item := range m.items {
		line := m.renderListItem(item, i == m.selectedIndex)
		lines = append(lines, line)
	}

	return strings.Join(lines, "\n")
}

func (m *RoadmapModel) renderListItem(item types.RoadmapItem, selected bool) string {
	icon := m.getStatusIcon(item.Status)
	progressBar := m.renderProgressBar(item.Progress)

	style := NormalStyle
	if selected {
		style = SelectedStyle
	}

	// Priority score prefix if enabled
	priorityPrefix := ""
	if m.showPriorityScores {
		if priority, err := m.priorityEngine.Calculate(item); err == nil {
			priorityColor := ""
			switch {
			case priority.Score >= 8.0:
				priorityColor = "🔴"
			case priority.Score >= 6.0:
				priorityColor = "🟠"
			case priority.Score >= 4.0:
				priorityColor = "🟡"
			default:
				priorityColor = "🟢"
			}
			priorityPrefix = fmt.Sprintf("%s%.1f ", priorityColor, priority.Score)
		}
	}

	line := fmt.Sprintf("%s%s %s %s (%d%%)",
		priorityPrefix,
		icon,
		item.Title,
		progressBar,
		item.Progress,
	)

	// Enhanced metadata display
	metaParts := []string{string(item.Priority)}

	// Add complexity and risk if available
	if item.Complexity != "" {
		metaParts = append(metaParts, fmt.Sprintf("C:%s", item.Complexity))
	}
	if item.RiskLevel != "" {
		metaParts = append(metaParts, fmt.Sprintf("R:%s", item.RiskLevel))
	}

	// Add effort estimate if available
	if item.Effort > 0 {
		metaParts = append(metaParts, fmt.Sprintf("%dh", item.Effort))
	}

	// Add business value if available
	if item.BusinessValue > 0 {
		metaParts = append(metaParts, fmt.Sprintf("BV:%d", item.BusinessValue))
	}

	meta := fmt.Sprintf(" [%s]", strings.Join(metaParts, " | "))
	line += MetaStyle.Render(meta)

	// If details mode is enabled and this item is selected, add detailed information below
	if selected && m.showDetails {
		details := m.renderItemDetails(item)
		if details != "" {
			line += "\n" + details
		}
	}

	return style.Render(line)
}

// renderPriorityView renders the priority management interface
func (m *RoadmapModel) renderPriorityView() string {
	switch m.priorityMode {
	case PriorityModeList:
		if m.priorityView != nil {
			return m.priorityView.View()
		}
		return "Priority view not initialized"

	case PriorityModeConfig:
		if m.priorityWidget != nil {
			return m.priorityWidget.View()
		}
		return "Priority widget not initialized"

	case PriorityModeVisualization:
		if m.priorityViz != nil {
			return m.priorityViz.View()
		}
		return "Priority visualization not initialized"

	default:
		return "Unknown priority mode"
	}
}

func (m *RoadmapModel) renderStatusBar() string {
	var parts []string

	// Current item info
	if m.selectedIndex < len(m.items) {
		selectedItem := m.items[m.selectedIndex]
		parts = append(parts, fmt.Sprintf("Item %d/%d: %s",
			m.selectedIndex+1, len(m.items), selectedItem.Title))

		// Priority score if enabled
		if m.showPriorityScores {
			if priority, err := m.priorityEngine.Calculate(selectedItem); err == nil {
				priorityColor := ""
				switch {
				case priority.Score >= 8.0:
					priorityColor = "🔴"
				case priority.Score >= 6.0:
					priorityColor = "🟠"
				case priority.Score >= 4.0:
					priorityColor = "🟡"
				default:
					priorityColor = "🟢"
				}
				parts = append(parts, fmt.Sprintf("%s Priority: %.2f", priorityColor, priority.Score))
			}
		}
	}

	// Engine info
	if m.priorityEngine != nil {
		config := m.priorityEngine.GetWeightingConfig()
		parts = append(parts, fmt.Sprintf("Engine: U:%.2f I:%.2f E:%.2f",
			config.Urgency, config.Impact, config.Effort))
	}

	if len(parts) == 0 {
		return ""
	}

	statusStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("241")).
		Background(lipgloss.Color("235")).
		Padding(0, 1)

	return statusStyle.Render(strings.Join(parts, " | "))
}

func (m *RoadmapModel) renderHelp() string {
	var helpItems []string

	// Global commands
	helpItems = append(helpItems, "j/k: navigate", "v: switch view", "q: quit")

	// Priority-specific commands
	if m.currentView == ViewModePriority {
		switch m.priorityMode {
		case PriorityModeList:
			helpItems = append(helpItems, "tab: change view", "r: refresh", "enter: details")
		case PriorityModeConfig:
			helpItems = append(helpItems, "enter: edit", "s: save", "r: reset", "esc: exit")
		case PriorityModeVisualization:
			helpItems = append(helpItems, "1-5: chart types", "a: animation", "r: refresh")
		}
	} else {
		// General commands
		helpItems = append(helpItems, "p: priority mode", "s: toggle scores", "enter: details", "r: refresh")
	}

	help := strings.Join(helpItems, " • ")
	return HelpStyle.Render(help)
}
