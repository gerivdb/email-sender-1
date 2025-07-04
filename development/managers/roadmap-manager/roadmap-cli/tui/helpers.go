package tui

import (
	"fmt"
	"strings"

	"github.com/gerivdb/email-sender-1/cmd/roadmap-cli/types"

	"github.com/charmbracelet/lipgloss"
)

// getStatusIcon returns an icon for the given status
func (m *RoadmapModel) getStatusIcon(status types.Status) string {
	switch status {
	case types.StatusCompleted:
		return "✅"
	case types.StatusInProgress:
		return "🚧"
	case types.StatusInReview:
		return "👀"
	case types.StatusBlocked:
		return "🚫"
	case types.StatusPlanned:
		return "📋"
	default:
		return "❓"
	}
}

// renderProgressBar creates a visual progress bar
func (m *RoadmapModel) renderProgressBar(progress int) string {
	const width = 10
	filled := progress / 10
	if filled > width {
		filled = width
	}
	empty := width - filled

	filledStyle := lipgloss.NewStyle().Foreground(lipgloss.Color("10")) // Green
	emptyStyle := lipgloss.NewStyle().Foreground(lipgloss.Color("8"))   // Gray

	return filledStyle.Render(strings.Repeat("█", filled)) +
		emptyStyle.Render(strings.Repeat("░", empty))
}

// renderTimelineView creates ASCII timeline view
func (m *RoadmapModel) renderTimelineView() string {
	if len(m.items) == 0 {
		return "No items in timeline"
	}

	lines := []string{"📅 Timeline View:", ""}

	for i, item := range m.items {
		icon := m.getStatusIcon(item.Status)
		timelineBar := m.renderProgressBar(item.Progress)
		// Date formatting and metadata
		dateStr := item.TargetDate.Format("2006-01-02")

		// Enhanced timeline metadata
		metaInfo := []string{dateStr}
		if item.Priority == types.PriorityHigh || item.Priority == types.PriorityCritical {
			metaInfo = append(metaInfo, fmt.Sprintf("P:%s", item.Priority))
		}
		if item.Complexity != "" {
			metaInfo = append(metaInfo, fmt.Sprintf("C:%s", item.Complexity))
		}
		if item.Effort > 0 {
			metaInfo = append(metaInfo, fmt.Sprintf("%dh", item.Effort))
		}

		metaDisplay := strings.Join(metaInfo, " | ")

		// Create timeline entry with selection highlighting
		style := NormalStyle
		if i == m.selectedIndex {
			style = SelectedStyle
		}
		line := style.Render(
			lipgloss.JoinHorizontal(
				lipgloss.Left,
				icon+" ",
				timelineBar+" ",
				item.Title+" ",
				MetaStyle.Render("["+metaDisplay+"]"),
			),
		)
		lines = append(lines, line)

		// Add details if this item is selected and detail mode is on
		if i == m.selectedIndex && m.showDetails {
			details := m.renderCompactDetails(item)
			if details != "" {
				lines = append(lines, "  "+details)
			}
		}

		// Add a connecting line for timeline effect
		if i < len(m.items)-1 {
			lines = append(lines, MetaStyle.Render("│"))
		}
	}

	return strings.Join(lines, "\n")
}

// renderKanbanView creates ASCII kanban board
func (m *RoadmapModel) renderKanbanView() string {
	columns := map[types.Status][]types.RoadmapItem{
		types.StatusPlanned:    {},
		types.StatusInProgress: {},
		types.StatusInReview:   {},
		types.StatusCompleted:  {},
		types.StatusBlocked:    {},
	}

	// Group items by status
	for _, item := range m.items {
		columns[item.Status] = append(columns[item.Status], item)
	}

	// Column headers
	headers := []string{
		"📋 Planned",
		"🚧 In Progress",
		"👀 In Review",
		"✅ Completed",
		"🚫 Blocked",
	}
	statuses := []types.Status{
		types.StatusPlanned,
		types.StatusInProgress,
		types.StatusInReview,
		types.StatusCompleted,
		types.StatusBlocked,
	}
	// Build kanban columns
	var columnContents []string
	maxHeight := 0
	itemIndex := 0 // Track global item index across columns

	for i, status := range statuses {
		column := []string{HeaderStyle.Render(headers[i]), ""}
		for _, item := range columns[status] {
			style := NormalStyle
			isSelected := itemIndex == m.selectedIndex
			if isSelected {
				style = SelectedStyle
			}

			// Enhanced kanban item display
			itemText := fmt.Sprintf("• %s", item.Title) // Add metadata indicators
			metaIndicators := []string{}
			if item.Priority == types.PriorityHigh || item.Priority == types.PriorityCritical {
				metaIndicators = append(metaIndicators, "🔥")
			}
			if item.Complexity == types.BasicComplexityHigh {
				metaIndicators = append(metaIndicators, "⚡")
			}
			if item.RiskLevel == types.RiskHigh {
				metaIndicators = append(metaIndicators, "⚠️")
			}
			if item.Effort > 0 {
				metaIndicators = append(metaIndicators, fmt.Sprintf("%dh", item.Effort))
			}

			if len(metaIndicators) > 0 {
				itemText += " " + strings.Join(metaIndicators, " ")
			}

			// Add details if this item is selected and detail mode is on
			itemDisplay := style.Render(itemText)
			if isSelected && m.showDetails {
				details := m.renderItemDetails(item)
				if details != "" {
					// For kanban, show a compact version of details
					compactDetails := m.renderCompactDetails(item)
					itemDisplay += "\n" + compactDetails
				}
			}

			column = append(column, itemDisplay)
			itemIndex++
		}

		if len(column) > maxHeight {
			maxHeight = len(column)
		}

		columnContents = append(columnContents, strings.Join(column, "\n"))
	}

	// Pad columns to same height
	for i := range columnContents {
		lines := strings.Split(columnContents[i], "\n")
		for len(lines) < maxHeight {
			lines = append(lines, "")
		}
		columnContents[i] = strings.Join(lines, "\n")
	}
	return lipgloss.JoinHorizontal(lipgloss.Top, columnContents...)
}

// renderItemDetails creates a detailed view of enriched item metadata
func (m *RoadmapModel) renderItemDetails(item types.RoadmapItem) string {
	var details []string

	// Basic info
	if item.Description != "" {
		details = append(details, fmt.Sprintf("  📄 %s", item.Description))
	}

	// Target date
	if !item.TargetDate.IsZero() {
		details = append(details, fmt.Sprintf("  📅 Target: %s", item.TargetDate.Format("2006-01-02")))
	}

	// Inputs
	if len(item.Inputs) > 0 {
		inputNames := make([]string, len(item.Inputs))
		for i, input := range item.Inputs {
			inputNames[i] = input.Name
		}
		details = append(details, fmt.Sprintf("  📥 Inputs: %s", strings.Join(inputNames, ", ")))
	}

	// Outputs
	if len(item.Outputs) > 0 {
		outputNames := make([]string, len(item.Outputs))
		for i, output := range item.Outputs {
			outputNames[i] = output.Name
		}
		details = append(details, fmt.Sprintf("  📤 Outputs: %s", strings.Join(outputNames, ", ")))
	}

	// Tools and frameworks
	if len(item.Tools) > 0 {
		details = append(details, fmt.Sprintf("  🔧 Tools: %s", strings.Join(item.Tools, ", ")))
	}
	if len(item.Frameworks) > 0 {
		details = append(details, fmt.Sprintf("  🏗️ Frameworks: %s", strings.Join(item.Frameworks, ", ")))
	}

	// Prerequisites
	if len(item.Prerequisites) > 0 {
		details = append(details, fmt.Sprintf("  ⚠️ Prerequisites: %s", strings.Join(item.Prerequisites, ", ")))
	}

	// Assessment metrics
	assessments := []string{}
	if item.TechnicalDebt > 0 {
		assessments = append(assessments, fmt.Sprintf("Technical Debt: %d/10", item.TechnicalDebt))
	}
	if len(assessments) > 0 {
		details = append(details, fmt.Sprintf("  📊 %s", strings.Join(assessments, " | ")))
	}

	// Tags
	if len(item.Tags) > 0 {
		details = append(details, fmt.Sprintf("  🏷️ Tags: %s", strings.Join(item.Tags, ", ")))
	}

	if len(details) == 0 {
		return ""
	}

	// Style the details with a subtle background
	detailStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("245")).
		MarginLeft(2).
		PaddingLeft(1)
	return detailStyle.Render(strings.Join(details, "\n"))
}

// renderCompactDetails creates a compact version of enriched metadata for kanban view
func (m *RoadmapModel) renderCompactDetails(item types.RoadmapItem) string {
	var details []string

	// Only show most critical details in compact mode
	if len(item.Tools) > 0 {
		details = append(details, fmt.Sprintf("🔧 %s", strings.Join(item.Tools[:min(2, len(item.Tools))], ", ")))
	}
	if len(item.Prerequisites) > 0 {
		details = append(details, fmt.Sprintf("⚠️ %d prereqs", len(item.Prerequisites)))
	}
	if item.TechnicalDebt > 0 {
		details = append(details, fmt.Sprintf("📊 TD:%d/10", item.TechnicalDebt))
	}

	if len(details) == 0 {
		return ""
	}

	// Use a more compact style for kanban
	compactStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("246")).
		MarginLeft(1).
		PaddingLeft(1)

	return compactStyle.Render(strings.Join(details, " • "))
}

// Helper function for min
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
