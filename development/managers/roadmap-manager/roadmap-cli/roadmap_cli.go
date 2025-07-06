package roadmap_cli

import (
	"fmt"
	"os"

	"github.com/gerivdb/email-sender-1/cmd/roadmap-cli/commands"
)

var (
	Version		= "1.0.0"
	BuildDate	= "2025-05-31"
)

func main() {
	rootCmd := commands.NewRootCommand()

	// Add version information
	rootCmd.Version = fmt.Sprintf("%s (built %s)", Version, BuildDate)

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
