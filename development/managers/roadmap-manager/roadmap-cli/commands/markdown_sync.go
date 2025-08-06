package commands

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gerivdb/email-sender-1/cmd/roadmap-cli/storage"
	"github.com/gerivdb/email-sender-1/cmd/roadmap-cli/types"

	"github.com/spf13/cobra"
)

// markdownSyncCmd provides bidirectional synchronization with Markdown plans
var markdownSyncCmd = &cobra.Command{
	Use:   "markdown",
	Short: "🔄 Bidirectional synchronization with Markdown plans",
	Long: `Synchronize roadmap data bidirectionally between TaskMaster-CLI dynamic system 
and Markdown plan files from EMAIL_SENDER_1 ecosystem.

Features:
• Parse existing Markdown plans and import to dynamic system
• Export dynamic roadmap items back to Markdown format
• Detect and resolve conflicts between formats
• Maintain consistency between planning approaches
• Preserve Markdown formatting and structure

This bridges the gap between current Markdown-based planning workflow
and the new dynamic TaskMaster-CLI system during the transition period.`,
	Example: `  # Import all consolidated plans to dynamic system
  roadmap-cli sync markdown --import --source projet/roadmaps/plans/consolidated
  
  # Export current dynamic items to Markdown format
  roadmap-cli sync markdown --export --target exported-plans/
  
  # Bidirectional sync with conflict detection
  roadmap-cli sync markdown --bidirectional --resolve-conflicts
  
  # Dry run to preview changes
  roadmap-cli sync markdown --import --dry-run`,
	RunE: runMarkdownSync,
}

var (
	markdownImport           bool
	markdownExport           bool
	markdownBidirectional    bool
	markdownSource           string
	markdownTarget           string
	markdownDryRun           bool
	markdownResolveConflicts bool
	markdownPreserveFormat   bool
)

func init() {
	markdownSyncCmd.Flags().BoolVar(&markdownImport, "import", false, "import Markdown plans to dynamic system")
	markdownSyncCmd.Flags().BoolVar(&markdownExport, "export", false, "export dynamic items to Markdown format")
	markdownSyncCmd.Flags().BoolVar(&markdownBidirectional, "bidirectional", false, "perform two-way synchronization")
	markdownSyncCmd.Flags().StringVar(&markdownSource, "source", "", "source directory for Markdown plans")
	markdownSyncCmd.Flags().StringVar(&markdownTarget, "target", "", "target directory for exported plans")
	markdownSyncCmd.Flags().BoolVar(&markdownDryRun, "dry-run", false, "preview changes without applying them")
	markdownSyncCmd.Flags().BoolVar(&markdownResolveConflicts, "resolve-conflicts", false, "automatically resolve conflicts when possible")
	markdownSyncCmd.Flags().BoolVar(&markdownPreserveFormat, "preserve-format", true, "maintain original Markdown formatting")
}

func runMarkdownSync(cmd *cobra.Command, args []string) error {
	fmt.Println("🔄 TaskMaster-CLI ↔ Markdown Synchronization")
	fmt.Println("===========================================")
	fmt.Println()

	// Initialize storage
	jsonStorage, err := storage.NewJSONStorage("roadmap.json")
	if err != nil {
		return fmt.Errorf("failed to initialize storage: %w", err)
	}
	defer jsonStorage.Close()

	// Determine operation mode
	if markdownBidirectional {
		return runBidirectionalSync(jsonStorage)
	} else if markdownImport {
		return runMarkdownImport(jsonStorage)
	} else if markdownExport {
		return runMarkdownExport(jsonStorage)
	} else {
		return fmt.Errorf("specify operation: --import, --export, or --bidirectional")
	}
}

func runMarkdownImport(storage *storage.JSONStorage) error {
	fmt.Println("📥 Importing Markdown plans to dynamic system...")

	// Determine source directory
	sourceDir := markdownSource
	if sourceDir == "" {
		sourceDir = "projet/roadmaps/plans/consolidated"
	}

	// Check if source exists
	if _, err := os.Stat(sourceDir); os.IsNotExist(err) {
		return fmt.Errorf("source directory not found: %s", sourceDir)
	}

	fmt.Printf("📁 Source: %s\n", sourceDir)
	fmt.Printf("🔍 Dry run: %v\n", markdownDryRun)

	// Find all Markdown files
	markdownFiles, err := findMarkdownFiles(sourceDir)
	if err != nil {
		return fmt.Errorf("failed to scan for Markdown files: %w", err)
	}

	fmt.Printf("📋 Found %d Markdown files to process\n\n", len(markdownFiles))

	// Process each file
	totalImported := 0
	for _, file := range markdownFiles {
		fmt.Printf("🔄 Processing: %s\n", filepath.Base(file))

		items, err := parseMarkdownPlan(file)
		if err != nil {
			fmt.Printf("  ❌ Error: %v\n", err)
			continue
		}

		fmt.Printf("  📋 Found %d items\n", len(items))
		if !markdownDryRun {
			for _, item := range items {
				_, err := storage.CreateItem(item.Title, item.Description, string(item.Priority), item.TargetDate)
				if err != nil {
					fmt.Printf("  ⚠️  Failed to import item '%s': %v\n", item.Title, err)
					continue
				}
			}
		}

		totalImported += len(items)
		fmt.Printf("  ✅ Processed successfully\n\n")
	}

	if markdownDryRun {
		fmt.Printf("🔍 Dry run complete. Would import %d items.\n", totalImported)
	} else {
		fmt.Printf("✅ Import complete. Imported %d items to dynamic system.\n", totalImported)
	}

	return nil
}

func runMarkdownExport(storage *storage.JSONStorage) error {
	fmt.Println("📤 Exporting dynamic items to Markdown format...")

	// Determine target directory
	targetDir := markdownTarget
	if targetDir == "" {
		targetDir = "exported-plans"
	}

	// Create target directory
	if err := os.MkdirAll(targetDir, 0o755); err != nil {
		return fmt.Errorf("failed to create target directory: %w", err)
	}

	fmt.Printf("📁 Target: %s\n", targetDir)
	fmt.Printf("🔍 Dry run: %v\n", markdownDryRun)

	// Get all items from storage
	items, err := storage.GetAllItems()
	if err != nil {
		return fmt.Errorf("failed to get items from storage: %w", err)
	}

	milestones, err := storage.GetAllMilestones()
	if err != nil {
		return fmt.Errorf("failed to get milestones from storage: %w", err)
	}

	fmt.Printf("📋 Exporting %d items and %d milestones\n\n", len(items), len(milestones))

	// Generate Markdown content
	markdownContent := generateMarkdownFromItems(items, milestones)

	// Write to file
	filename := fmt.Sprintf("taskmaster-export-%s.md", time.Now().Format("2006-01-02"))
	filepath := filepath.Join(targetDir, filename)

	if !markdownDryRun {
		if err := os.WriteFile(filepath, []byte(markdownContent), 0o644); err != nil {
			return fmt.Errorf("failed to write Markdown file: %w", err)
		}
	}

	if markdownDryRun {
		fmt.Printf("🔍 Dry run complete. Would export to: %s\n", filepath)
		fmt.Printf("📄 Content preview:\n%s\n", markdownContent[:min(500, len(markdownContent))]+"...")
	} else {
		fmt.Printf("✅ Export complete. Written to: %s\n", filepath)
	}

	return nil
}

func runBidirectionalSync(storage *storage.JSONStorage) error {
	fmt.Println("🔄 Bidirectional synchronization...")
	fmt.Println("This will compare Markdown plans with dynamic system and resolve differences.")
	fmt.Println()

	// TODO: Implement bidirectional synchronization with conflict detection
	fmt.Println("⚠️  Bidirectional sync not yet implemented.")
	fmt.Println("    Use --import or --export for one-way synchronization.")

	return nil
}

func findMarkdownFiles(dir string) ([]string, error) {
	var files []string

	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() && strings.HasSuffix(strings.ToLower(info.Name()), ".md") {
			files = append(files, path)
		}

		return nil
	})

	return files, err
}

func parseMarkdownPlan(filePath string) ([]*types.RoadmapItem, error) {
	// Use simplified parsing approach
	content, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read file: %w", err)
	}

	var items []*types.RoadmapItem
	lines := strings.Split(string(content), "\n")

	for _, line := range lines {
		line = strings.TrimSpace(line)

		// Look for task items with checkboxes
		if strings.HasPrefix(line, "- [ ]") || strings.HasPrefix(line, "- [x]") {
			title := strings.TrimSpace(line[5:]) // Remove "- [ ]" or "- [x]"
			if title != "" {
				status := types.StatusPlanned
				if strings.HasPrefix(line, "- [x]") {
					status = types.StatusCompleted
				}

				item := &types.RoadmapItem{
					Title:       title,
					Description: fmt.Sprintf("Imported from %s", filepath.Base(filePath)),
					Priority:    types.PriorityMedium,
					Status:      status,
					CreatedAt:   time.Now(),
					TargetDate:  time.Now().AddDate(0, 1, 0), // Default to 1 month from now
				}
				items = append(items, item)
			}
		}
	}

	return items, nil
}

func generateMarkdownFromItems(items []types.RoadmapItem, milestones []types.Milestone) string {
	var content strings.Builder

	content.WriteString("# TaskMaster CLI Export\n\n")
	content.WriteString(fmt.Sprintf("**Exported:** %s\n", time.Now().Format("2006-01-02 15:04:05")))
	content.WriteString(fmt.Sprintf("**Items:** %d\n", len(items)))
	content.WriteString(fmt.Sprintf("**Milestones:** %d\n\n", len(milestones)))

	// Export milestones
	if len(milestones) > 0 {
		content.WriteString("## 🎯 Milestones\n\n")
		for _, milestone := range milestones {
			content.WriteString(fmt.Sprintf("### %s\n", milestone.Title))
			if milestone.Description != "" {
				content.WriteString(fmt.Sprintf("%s\n", milestone.Description))
			}
			content.WriteString(fmt.Sprintf("**Target Date:** %s\n\n", milestone.TargetDate.Format("2006-01-02")))
		}
	}

	// Export items by status
	statusGroups := map[types.Status]string{
		types.StatusPlanned:    "📋 Planned",
		types.StatusInProgress: "🔄 In Progress",
		types.StatusCompleted:  "✅ Completed",
		types.StatusBlocked:    "🚫 Blocked",
	}

	for status, title := range statusGroups {
		statusItems := filterItemsByStatus(items, status)
		if len(statusItems) > 0 {
			content.WriteString(fmt.Sprintf("## %s\n\n", title))
			fmt.Printf("[LOG] Génération section Markdown: %s (%d items)\n", title, len(statusItems))
			for _, item := range statusItems {
				checkbox := "- [ ]"
				if status == types.StatusCompleted {
					checkbox = "- [x]"
				}
				content.WriteString(fmt.Sprintf("%s %s\n", checkbox, item.Title))
				fmt.Printf("[LOG]   Item: %s | Priority: %s | Created: %s\n", item.Title, item.Priority, item.CreatedAt.Format("2006-01-02"))
				if item.Description != "" {
					content.WriteString(fmt.Sprintf("  *%s*\n", item.Description))
					fmt.Printf("[LOG]     Description: %s\n", item.Description)
				}
				content.WriteString(fmt.Sprintf("  **Priority:** %s | **Created:** %s\n\n",
					item.Priority, item.CreatedAt.Format("2006-01-02")))
			}
		}
	}

	return content.String()
}

func filterItemsByStatus(items []types.RoadmapItem, status types.Status) []types.RoadmapItem {
	var filtered []types.RoadmapItem
	for _, item := range items {
		if item.Status == status {
			filtered = append(filtered, item)
		}
	}
	return filtered
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
