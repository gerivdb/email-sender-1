package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"
)

func runCommand(name string, arg ...string) error {
	cmd := exec.Command(name, arg...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	fmt.Printf("Running command: %s %s\n", name, strings.Join(arg, " "))
	return cmd.Run()
}

func main() {
	startTime := time.Now()
	fmt.Println("Starting auto-roadmap-runner...")

	// 1. Recensement & Analyse d’écart
	fmt.Println("\n--- Phase 1: Recensement & Analyse d’écart ---")
	// Using powershell for grep and redirection for Windows compatibility.
	// For cross-platform, a Go native file search would be more robust.
	if err := runCommand("pwsh", "-Command", "Get-ChildItem -Recurse projet/roadmaps/plans/consolidated/ | Select-String -Pattern 'AgentZero|CrewAI|multi-agent|multi-LLM' | Select-Object -ExpandProperty Path | ForEach-Object { $_ } > plans_impactes_jan.md"); err != nil {
		fmt.Printf("Error during plan scanning: %v\n", err)
		os.Exit(1)
	}
	if err := runCommand("go", "run", "cmd/ecart-analyzer/main.go"); err != nil {
		fmt.Printf("Error during écart analysis: %v\n", err)
		os.Exit(1)
	}

	// 2. Recueil des besoins & Spécification
	fmt.Println("\n--- Phase 2: Recueil des besoins & Spécification ---")
	if err := runCommand("go", "run", "cmd/recueil-besoins/main.go"); err != nil {
		fmt.Printf("Error during needs gathering: %v\n", err)
		os.Exit(1)
	}
	if err := runCommand("go", "run", "cmd/spec-contextmanager/main.go"); err != nil {
		fmt.Printf("Error during ContextManager spec generation: %v\n", err)
		os.Exit(1)
	}

	// 3. Développement & Adaptation des plans
	fmt.Println("\n--- Phase 3: Développement & Adaptation des plans ---")
	if err := runCommand("go", "run", "cmd/ajout-section-jan/main.go"); err != nil {
		fmt.Printf("Error during adding Jan section to plans: %v\n", err)
		os.Exit(1)
	}
	if err := runCommand("go", "run", "cmd/refactor-interfaces/main.go"); err != nil {
		fmt.Printf("Error during interface refactoring: %v\n", err)
		os.Exit(1)
	}
	// Assuming core/contextmanager/contextmanager.go is already created and tested
	// No direct command to "develop/extend" it here, as it's a code modification task.
	if err := runCommand("go", "run", "cmd/gen-mermaid/main.go"); err != nil {
		fmt.Printf("Error during Mermaid diagram generation: %v\n", err)
		os.Exit(1)
	}

	// 4. Tests, Reporting & Validation
	fmt.Println("\n--- Phase 4: Tests, Reporting & Validation ---")
	if err := runCommand("go", "test", "./core/contextmanager/...", "-cover"); err != nil {
		fmt.Printf("Error during ContextManager tests: %v\n", err)
		os.Exit(1)
	}
	if err := runCommand("go", "run", "cmd/reporting-jan/main.go"); err != nil {
		fmt.Printf("Error during report generation: %v\n", err)
		os.Exit(1)
	}

	// Note: Rollback & Versioning, CI/CD, Documentation & Traceability, Robustness & Adaptation LLM
	// are largely conceptual or involve external systems (git, GitHub Actions)
	// and are not directly executable as Go commands within this runner.
	// The runner focuses on the automated generation/modification steps.

	fmt.Println("\nAuto-roadmap-runner finished successfully.")
	fmt.Printf("Total execution time: %s\n", time.Since(startTime).String())
}
