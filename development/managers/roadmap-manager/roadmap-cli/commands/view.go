package commands

import (
	"fmt"

	"email_sender/cmd/roadmap-cli/tui"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/spf13/cobra"
)

func newViewCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "view",
		Short: "Launch interactive TUI for roadmap management",
		Long:  "Start the bubbletea-powered TUI interface for managing roadmaps",
		RunE:  runView,
	}

	cmd.Flags().String("mode", "list", "initial view mode (list, timeline, kanban)")

	return cmd
}

func runView(cmd *cobra.Command, args []string) error {
	// Get flags
	mode, _ := cmd.Flags().GetString("mode")
	verbose, _ := cmd.Flags().GetBool("verbose")

	if verbose {
		fmt.Println("Starting roadmap TUI...")
	}

	// Initialize TUI model
	model := tui.NewRoadmapModel(mode)

	// Start bubbletea program
	p := tea.NewProgram(model, tea.WithAltScreen())

	if _, err := p.Run(); err != nil {
		return fmt.Errorf("failed to start TUI: %w", err)
	}

	return nil
}
