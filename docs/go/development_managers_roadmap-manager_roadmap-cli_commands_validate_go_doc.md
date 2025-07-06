# Package commands

Package commands provides CLI commands for plan ingestion functionality


## Types

### ConsistencyIssue

### ConsistencyReport

## Functions

### NewIngestCommand

NewIngestCommand returns the ingest command


```go
func NewIngestCommand() *cobra.Command
```

### NewRootCommand

```go
func NewRootCommand() *cobra.Command
```

## Variables

### AdvancedIngestCmd

AdvancedIngestCmd represents the advanced ingest command


```go
var AdvancedIngestCmd = &cobra.Command{
	Use:	"ingest-advanced [file_or_directory]",
	Short:	"Advanced ingestion with deep technical analysis", Long: `Advanced ingestion command that supports:
- Deep hierarchical parsing up to 12 levels of hierarchy
- Technical specification extraction (database schemas, APIs, code references)
- Complex dependency analysis
- Implementation step extraction
- Complexity metrics calculation
- Performance target analysis`,
	Args:	cobra.ExactArgs(1),
	RunE:	runAdvancedIngest,
}
```

### HierarchyCmd

HierarchyCmd represents the hierarchy navigation command


```go
var HierarchyCmd = &cobra.Command{
	Use:	"hierarchy [roadmap_name]",
	Short:	"Launch hierarchical navigation TUI",
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
	Args:	cobra.MaximumNArgs(1),
	RunE:	runHierarchyNavigator,
}
```

### MigrateCmd

MigrateCmd represents the migrate command


```go
var MigrateCmd = &cobra.Command{
	Use:	"migrate",
	Short:	"Run database migrations to upgrade data structures",
	Long: `Run database migrations to upgrade TaskMaster data structures.
This command will automatically detect the current version and apply
any pending migrations to support new advanced features.

Migrations include:
- Upgrade to hierarchical roadmap format (v2.0)
- Add technical specifications support (v2.1)
- Add complexity metrics and dependencies (v2.2)

The original data is backed up before migration.`,
	RunE:	runMigrate,
}
```

