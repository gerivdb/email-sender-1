package tui

import (
	"github.com/gerivdb/email-sender-1/cmd/roadmap-cli/tui/models"

	tea "github.com/charmbracelet/bubbletea"
)

// Init initializes the model
func (m *RoadmapModel) Init() tea.Cmd {
	return nil
}

// Update handles messages and updates the model
func (m *RoadmapModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmds []tea.Cmd

	// Handle window size changes
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height

		// Update priority components
		if m.priorityView != nil {
			m.priorityView.Update(msg)
		}
		if m.priorityWidget != nil {
			m.priorityWidget.Update(msg)
		}
		if m.priorityViz != nil {
			m.priorityViz.Update(msg)
		}

		return m, nil
	}

	// Handle priority-specific messages
	switch msg := msg.(type) {
	case models.PriorityRefreshMsg:
		// Refresh priority calculations
		if m.priorityView != nil {
			_, cmd := m.priorityView.Update(msg)
			cmds = append(cmds, cmd)
		}
		if m.priorityViz != nil {
			_, cmd := m.priorityViz.Update(msg)
			cmds = append(cmds, cmd)
		}

	case models.PriorityDetailMsg:
		// Handle priority detail view
		return m, nil

	case models.PriorityItemSelectedMsg:
		// Update priority widget with selected item
		if m.priorityWidget != nil {
			_, cmd := m.priorityWidget.Update(msg)
			cmds = append(cmds, cmd)
		}

	case models.PriorityConfigUpdatedMsg:
		// Priority configuration was updated
		return m, tea.Cmd(func() tea.Msg {
			return models.PriorityRefreshMsg{}
		})
	}

	// Handle keyboard input
	switch msg := msg.(type) {
	case tea.KeyMsg:
		// Priority mode handling
		if m.currentView == ViewModePriority {
			return m.handlePriorityModeKeys(msg)
		}

		// Global key bindings
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

		case "p", "P":
			// Toggle priority mode or cycle priority views
			if m.currentView == ViewModePriority {
				m.cyclePriorityMode()
			} else {
				m.currentView = ViewModePriority
			}
			return m, nil

		case "s":
			// Toggle priority scores display
			m.showPriorityScores = !m.showPriorityScores
			return m, nil

		case "enter", " ":
			// Select item for priority analysis
			if m.selectedIndex < len(m.items) {
				selectedItem := m.items[m.selectedIndex]
				cmd := tea.Cmd(func() tea.Msg {
					return models.PriorityItemSelectedMsg{Item: selectedItem}
				})
				return m.toggleDetails(), cmd
			}
			return m.toggleDetails(), nil

		case "r":
			// Refresh priority data
			return m, tea.Cmd(func() tea.Msg {
				return models.PriorityRefreshMsg{}
			})

		case "?":
			// Show help
			return m, nil
		}
	}

	return m, tea.Batch(cmds...)
}

// handlePriorityModeKeys handles key presses in priority mode
func (m *RoadmapModel) handlePriorityModeKeys(msg tea.KeyMsg) (*RoadmapModel, tea.Cmd) {
	var cmds []tea.Cmd

	// Set active component based on current priority mode
	m.updatePriorityComponentStates()

	// Pass key events to active priority component
	switch m.priorityMode {
	case PriorityModeList:
		if m.priorityView != nil {
			_, cmd := m.priorityView.Update(msg)
			cmds = append(cmds, cmd)
		}

	case PriorityModeConfig:
		if m.priorityWidget != nil {
			_, cmd := m.priorityWidget.Update(msg)
			cmds = append(cmds, cmd)
		}

	case PriorityModeVisualization:
		if m.priorityViz != nil {
			_, cmd := m.priorityViz.Update(msg)
			cmds = append(cmds, cmd)
		}
	}

	// Handle priority mode specific keys
	switch msg.String() {
	case "tab":
		m.cyclePriorityMode()

	case "esc":
		// Exit priority mode
		m.currentView = ViewModeList
	}

	return m, tea.Batch(cmds...)
}

// updatePriorityComponentStates sets the active state of priority components
func (m *RoadmapModel) updatePriorityComponentStates() {
	if m.priorityView != nil {
		m.priorityView.SetActive(m.priorityMode == PriorityModeList)
	}
	if m.priorityWidget != nil {
		m.priorityWidget.SetActive(m.priorityMode == PriorityModeConfig)
	}
	if m.priorityViz != nil {
		m.priorityViz.SetActive(m.priorityMode == PriorityModeVisualization)
	}
}

// cyclePriorityMode cycles through different priority view modes
func (m *RoadmapModel) cyclePriorityMode() {
	m.priorityMode = (m.priorityMode + 1) % 3
	m.updatePriorityComponentStates()
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
		m.currentView = ViewModePriority
	case ViewModePriority:
		m.currentView = ViewModeList
	}

	// Update component states when switching views
	if m.currentView == ViewModePriority {
		m.updatePriorityComponentStates()
	}

	return m
}

func (m *RoadmapModel) toggleDetails() *RoadmapModel {
	m.showDetails = !m.showDetails
	return m
}
