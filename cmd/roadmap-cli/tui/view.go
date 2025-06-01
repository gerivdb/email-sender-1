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
	help := m.renderHelp()

	return lipgloss.JoinVertical(
		lipgloss.Left,
		header,
		"",
		content,
		"",
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
	}

	return HeaderStyle.Render(fmt.Sprintf("%s - %s", title, viewName))
}

func (m *RoadmapModel) renderContent() string {
	switch m.currentView {
	case ViewModeList:
		return m.renderListView()
	case ViewModeTimeline:
		return m.renderTimelineView()
	case ViewModeKanban:
		return m.renderKanbanView()
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

	line := fmt.Sprintf("%s %s %s (%d%%)",
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

func (m *RoadmapModel) renderHelp() string {
	help := "j/k: navigate • v: switch view • enter/space: toggle details • r: refresh • q: quit"
	return HelpStyle.Render(help)
}
