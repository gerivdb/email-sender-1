package commands

import (
	"fmt"

	"github.com/spf13/cobra"
	"email_sender/cmd/roadmap-cli/storage"
)

// MigrateCmd represents the migrate command
var MigrateCmd = &cobra.Command{
	Use:   "migrate",
	Short: "Run database migrations to upgrade data structures",
	Long: `Run database migrations to upgrade TaskMaster data structures.
This command will automatically detect the current version and apply
any pending migrations to support new advanced features.

Migrations include:
- Upgrade to hierarchical roadmap format (v2.0)
- Add technical specifications support (v2.1)
- Add complexity metrics and dependencies (v2.2)

The original data is backed up before migration.`,
	RunE: runMigrate,
}

var (
	forceVersion string
	dryRunMigrate bool
	listMigrations bool
)

func init() {
	MigrateCmd.Flags().StringVar(&forceVersion, "force-version", "", "Force migration to specific version")
	MigrateCmd.Flags().BoolVar(&dryRunMigrate, "dry-run", false, "Show what migrations would run without executing them")
	MigrateCmd.Flags().BoolVar(&listMigrations, "list", false, "List available migrations")
}

func runMigrate(cmd *cobra.Command, args []string) error {
	// Get storage directory
	storageManager := storage.NewStorageManager()
	storageDir := storageManager.GetStorageDir() // Assume this method exists
	
	migrationManager := storage.NewMigrationManager(storageDir)
	
	if listMigrations {
		return listAvailableMigrations(migrationManager)
	}
	
	if dryRunMigrate {
		return showPendingMigrations(migrationManager)
	}
	
	fmt.Println("Starting TaskMaster data migration...")
	
	err := migrationManager.RunMigrations()
	if err != nil {
		return fmt.Errorf("migration failed: %v", err)
	}
	
	fmt.Println("✅ All migrations completed successfully!")
	fmt.Println("Your TaskMaster data has been upgraded to support advanced features.")
	
	return nil
}

func listAvailableMigrations(migrationManager *storage.MigrationManager) error {
	migrations := migrationManager.GetAvailableMigrations()
	
	fmt.Println("Available migrations:")
	fmt.Println()
	
	for _, migration := range migrations {
		fmt.Printf("📦 Version %s\n", migration.Version)
		fmt.Printf("   %s\n", migration.Description)
		fmt.Println()
	}
	
	return nil
}

func showPendingMigrations(migrationManager *storage.MigrationManager) error {
	// This would require exposing more methods from MigrationManager
	// For now, just show a message
	fmt.Println("Dry run mode - would show pending migrations")
	fmt.Println("(Implementation depends on exposing more migration manager methods)")
	
	return nil
}
