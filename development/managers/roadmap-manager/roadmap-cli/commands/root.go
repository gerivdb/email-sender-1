package commands

import (
	"github.com/spf13/cobra"
)

func NewRootCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "roadmap-cli",
		Short: "Go native roadmap management CLI with RAG intelligence",
		Long: `A native Go CLI for roadmap management integrated with EMAIL_SENDER_1 ecosystem.
Features include:
- Interactive TUI with bubbletea
- RAG-powered insights and recommendations
- Multiple view modes (list, timeline, kanban)
- Integration with n8n workflows
- QDrant vector storage for intelligent analysis`,
		SilenceUsage: true,
	}

	// Global flags
	cmd.PersistentFlags().String("config", "", "config file path")
	cmd.PersistentFlags().Bool("verbose", false, "verbose output")
	// Add subcommands
	cmd.AddCommand(newViewCommand())
	cmd.AddCommand(newCreateCommand())
	cmd.AddCommand(newSyncCommand())
	cmd.AddCommand(intelligenceCmd)
	cmd.AddCommand(NewIngestCommand())
	cmd.AddCommand(AdvancedIngestCmd)
	cmd.AddCommand(HierarchyCmd)
	cmd.AddCommand(MigrateCmd)
	cmd.AddCommand(validateCmd)  // New validation commands

	return cmd
}
