package tui

import (
	tea "github.com/charmbracelet/bubbletea"
)

// Init initializes the model
func (m *RoadmapModel) Init() tea.Cmd {
	return nil
}

// Update handles messages and updates the model
func (m *RoadmapModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			m.quitting = true
			return m, tea.Quit

		case "up", "k":
			return m.navigateUp(), nil

		case "down", "j":
			return m.navigateDown(), nil

		case "v":
			return m.switchView(), nil

		case "enter", " ":
			return m.toggleDetails(), nil

		case "r":
			// Refresh data
			return m, nil

		case "?":
			// Show help
			return m, nil
		}
	}

	return m, nil
}

func (m *RoadmapModel) navigateUp() *RoadmapModel {
	if m.selectedIndex > 0 {
		m.selectedIndex--
	}
	return m
}

func (m *RoadmapModel) navigateDown() *RoadmapModel {
	if m.selectedIndex < len(m.items)-1 {
		m.selectedIndex++
	}
	return m
}

func (m *RoadmapModel) switchView() *RoadmapModel {
	switch m.currentView {
	case ViewModeList:
		m.currentView = ViewModeTimeline
	case ViewModeTimeline:
		m.currentView = ViewModeKanban
	case ViewModeKanban:
		m.currentView = ViewModeList
	}
	return m
}

func (m *RoadmapModel) toggleDetails() *RoadmapModel {
	m.showDetails = !m.showDetails
	return m
}
