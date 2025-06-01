package tui

import (
	"time"

	"email_sender/cmd/roadmap-cli/storage"
	"email_sender/cmd/roadmap-cli/types"
)

// NewRoadmapModel creates a new roadmap TUI model
func NewRoadmapModel(mode string) *RoadmapModel {
	viewMode := ViewModeList
	switch mode {
	case "timeline":
		viewMode = ViewModeTimeline
	case "kanban":
		viewMode = ViewModeKanban
	}

	// Load items from database
	items := loadItemsFromDB()

	return &RoadmapModel{
		items:       items,
		currentView: viewMode,
	}
}

// loadItemsFromDB loads roadmap items from the JSON storage
func loadItemsFromDB() []types.RoadmapItem {
	storagePath := storage.GetDefaultStoragePath()
	store, err := storage.NewJSONStorage(storagePath)
	if err != nil {
		// Fallback to demo data if storage connection fails
		return getDemoItems()
	}
	defer store.Close()

	dbItems, err := store.GetAllItems()
	if err != nil {
		// Fallback to demo data if query fails
		return getDemoItems()
	}

	// Items are already in the correct type
	return dbItems
}

func getDemoItems() []types.RoadmapItem {
	return []types.RoadmapItem{
		{
			ID:          "demo-1",
			Title:       "Implement RAG Integration",
			Description: "Connect roadmap CLI to EMAIL_SENDER_1 RAG engine",
			Status:      types.StatusInProgress,
			Progress:    65,
			Priority:    types.PriorityHigh,
			TargetDate:  time.Now().AddDate(0, 0, 7),
			CreatedAt:   time.Now().AddDate(0, 0, -3),
		},
		{
			ID:          "demo-2",
			Title:       "Build Timeline View",
			Description: "ASCII timeline visualization with bubbletea",
			Status:      types.StatusPlanned,
			Progress:    20,
			Priority:    types.PriorityMedium,
			TargetDate:  time.Now().AddDate(0, 0, 14),
			CreatedAt:   time.Now().AddDate(0, 0, -1),
		},
	}
}
