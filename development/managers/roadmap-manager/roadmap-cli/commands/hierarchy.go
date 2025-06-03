package commands

import (
	"fmt"
	"strings"

	"email_sender/cmd/roadmap-cli/storage"
	"email_sender/cmd/roadmap-cli/tui"
	"email_sender/cmd/roadmap-cli/types"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/spf13/cobra"
)

// HierarchyCmd represents the hierarchy navigation command
var HierarchyCmd = &cobra.Command{
	Use:   "hierarchy [roadmap_name]",
	Short: "Launch hierarchical navigation TUI",
	Long: `Launch an interactive terminal user interface for navigating
roadmap hierarchies with advanced features:

- Navigate up to 5 levels deep in the roadmap hierarchy
- View detailed technical specifications
- Filter by complexity levels
- Browse implementation steps and dependencies
- Export views and generate reports

Use arrow keys or vi-style navigation (j/k) to move around.
Press 'enter' to drill down, 'backspace' to go back.
Press '?' for help.`,
	Args: cobra.MaximumNArgs(1),
	RunE: runHierarchyNavigator,
}

var (
	startAtLevel   int
	startAtPath    string
	enableFilters  bool
	enableExport   bool
	hierarchyTheme string
)

func init() {
	HierarchyCmd.Flags().IntVar(&startAtLevel, "start-level", 1, "Starting hierarchy level")
	HierarchyCmd.Flags().StringVar(&startAtPath, "start-path", "", "Starting hierarchy path (comma-separated)")
	HierarchyCmd.Flags().BoolVar(&enableFilters, "enable-filters", true, "Enable complexity and other filters")
	HierarchyCmd.Flags().BoolVar(&enableExport, "enable-export", true, "Enable export functionality")
	HierarchyCmd.Flags().StringVar(&hierarchyTheme, "theme", "default", "UI theme (default, dark, light)")
}

func runHierarchyNavigator(cmd *cobra.Command, args []string) error {
	// Load roadmap
	storageManager := storage.NewStorageManager()
	basicRoadmap, err := storageManager.LoadRoadmap()
	if err != nil {
		return fmt.Errorf("failed to load roadmap: %v", err)
	}

	// Convert to advanced roadmap (simplified conversion for now)
	advancedRoadmap := convertToAdvancedRoadmap(basicRoadmap)

	if advancedRoadmap.TotalItems == 0 {
		return fmt.Errorf("no items found in roadmap. Use 'ingest-advanced' to import roadmap data first")
	}

	// Create and run the TUI
	model := tui.NewHierarchyModel(advancedRoadmap)

	// Apply command line options
	if startAtLevel > 1 && startAtLevel <= advancedRoadmap.MaxDepth {
		// TODO: Set starting level and path
	}

	program := tea.NewProgram(model, tea.WithAltScreen())

	fmt.Printf("Launching hierarchy navigator for roadmap: %s\n", advancedRoadmap.Name)
	fmt.Printf("Total items: %d | Max depth: %d\n", advancedRoadmap.TotalItems, advancedRoadmap.MaxDepth)
	fmt.Printf("Press '?' for help once the interface loads.\n\n")

	_, err = program.Run()
	if err != nil {
		return fmt.Errorf("error running TUI: %v", err)
	}

	return nil
}

// convertToAdvancedRoadmap converts a basic roadmap to advanced format
// This is a simplified conversion - in a real implementation, you'd want
// to persist the advanced format directly
func convertToAdvancedRoadmap(basic *types.Roadmap) *types.AdvancedRoadmap {
	advanced := &types.AdvancedRoadmap{
		Version:     basic.Version,
		Name:        "Converted Roadmap",
		Description: "Converted from basic roadmap format",
		CreatedAt:   basic.CreatedAt,
		UpdatedAt:   basic.UpdatedAt,
		Items:       []types.AdvancedRoadmapItem{},
		Hierarchy:   make(map[string][]string),
		MaxDepth:    5, // Default max depth
	}

	// Convert basic items to advanced items
	for _, basicItem := range basic.Items {
		advancedItem := types.AdvancedRoadmapItem{
			ID:          basicItem.ID,
			Title:       basicItem.Title,
			Description: basicItem.Description,
			Status:      string(basicItem.Status),
			Priority:    string(basicItem.Priority),
			CreatedAt:   basicItem.CreatedAt,
			UpdatedAt:   basicItem.UpdatedAt,

			// Set default hierarchy (all items at level 1 for basic conversion)
			Hierarchy: types.HierarchyLevel{
				Level:    1,
				Path:     []string{basicItem.Title},
				Position: len(advanced.Items),
				MaxDepth: 5,
			},
			HierarchyPath: []string{basicItem.Title},

			// Initialize empty technical specs
			TechnicalSpec:         types.TechnicalSpec{},
			ImplementationSteps:   []types.ImplementationStep{},
			ComplexityMetrics:     types.ComplexityMetrics{},
			TechnicalDependencies: []types.TechnicalDependency{},
		}

		// Try to extract complexity from description
		extractComplexityFromDescription(&advancedItem)

		advanced.Items = append(advanced.Items, advancedItem)
	}

	advanced.TotalItems = len(advanced.Items)

	// Build hierarchy map
	buildHierarchyMap(advanced)

	return advanced
}

// extractComplexityFromDescription attempts to extract complexity info from description text
func extractComplexityFromDescription(item *types.AdvancedRoadmapItem) {
	// Look for complexity indicators in description
	description := item.Description

	// Simple heuristics for complexity
	complexityScore := 3 // default

	if containsAny(description, []string{"simple", "basic", "trivial", "easy"}) {
		complexityScore = 2
	} else if containsAny(description, []string{"complex", "advanced", "difficult", "challenging"}) {
		complexityScore = 7
	} else if containsAny(description, []string{"expert", "critical", "intricate", "sophisticated"}) {
		complexityScore = 9
	}

	item.ComplexityMetrics.Overall = types.ComplexityLevel{
		Score: complexityScore,
		Level: scoreToLevel(complexityScore),
	}

	// Set technical complexity as well
	item.ComplexityMetrics.Technical = item.ComplexityMetrics.Overall
}

// containsAny checks if text contains any of the given keywords
func containsAny(text string, keywords []string) bool {
	lowerText := strings.ToLower(text)
	for _, keyword := range keywords {
		if strings.Contains(lowerText, strings.ToLower(keyword)) {
			return true
		}
	}
	return false
}

// scoreToLevel converts numeric score to complexity level
func scoreToLevel(score int) string {
	switch {
	case score <= 2:
		return "trivial"
	case score <= 4:
		return "simple"
	case score <= 6:
		return "moderate"
	case score <= 8:
		return "complex"
	default:
		return "expert"
	}
}

// buildHierarchyMap builds the hierarchy mapping for the roadmap
func buildHierarchyMap(roadmap *types.AdvancedRoadmap) {
	for _, item := range roadmap.Items {
		levelKey := fmt.Sprintf("level_%d", item.Hierarchy.Level)
		roadmap.Hierarchy[levelKey] = append(roadmap.Hierarchy[levelKey], item.ID)
	}
}
