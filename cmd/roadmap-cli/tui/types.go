package tui

import (
	"email_sender/cmd/roadmap-cli/types"
)

// ViewMode represents different TUI view modes
type ViewMode int

const (
	ViewModeList ViewMode = iota
	ViewModeTimeline
	ViewModeKanban
)

// RoadmapModel is the main bubbletea model
type RoadmapModel struct {
	items         []types.RoadmapItem
	selectedIndex int
	currentView   ViewMode
	width         int
	height        int
	quitting      bool
	showDetails   bool // Toggle for showing detailed information
}
