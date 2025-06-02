package tui

import (
	"email_sender/cmd/roadmap-cli/priority"
	"email_sender/cmd/roadmap-cli/tui/models"
	"email_sender/cmd/roadmap-cli/types"
)

// ViewMode represents different TUI view modes
type ViewMode int

const (
	ViewModeList ViewMode = iota
	ViewModeTimeline
	ViewModeKanban
	ViewModePriority
)

// PriorityMode represents different priority view modes
type PriorityMode int

const (
	PriorityModeList PriorityMode = iota
	PriorityModeConfig
	PriorityModeVisualization
)

// RoadmapModel is the main bubbletea model
type RoadmapModel struct {
	items              []types.RoadmapItem
	selectedIndex      int
	currentView        ViewMode
	priorityMode       PriorityMode
	width              int
	height             int
	quitting           bool
	showDetails        bool // Toggle for showing detailed information
	
	// Priority engine and components
	priorityEngine     *priority.Engine
	priorityView       *models.PriorityView
	priorityWidget     *models.InteractivePriorityWidget
	priorityViz        *models.PriorityVisualization
	showPriorityScores bool
}
