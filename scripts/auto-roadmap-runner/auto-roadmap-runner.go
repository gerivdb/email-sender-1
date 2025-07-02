// scripts/auto-roadmap-runner.go
// Orchestrateur global : exécute tous les scripts d’audit, correction, tests, reporting, sauvegardes, notifications.
// Usage : go run scripts/auto-roadmap-runner.go

package main

import (
	"fmt"
	"os"
	"os/exec"
)

type Step struct {
	Name string
	Cmd  []string
}

func runStep(step Step) error {
	fmt.Printf("==> %s\n", step.Name)
	cmd := exec.Command(step.Cmd[0], step.Cmd[1:]...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func main() {
	steps := []Step{
		{"Lister go.mod/go.work", []string{"go", "run", "scripts/list-go-mods.go"}},
		{"Analyser go.mod/go.work", []string{"go", "run", "scripts/analyze-go-mods.go"}},
		{"Corriger go.mod/go.work", []string{"go", "run", "scripts/fix-go-mods.go"}},
		{"Lister YAML", []string{"go", "run", "scripts/list-yaml-files.go"}},
		{"Lint YAML", []string{"go", "run", "scripts/lint-yaml.go"}},
		{"Corriger YAML", []string{"go", "run", "scripts/fix-yaml.go"}},
		{"Agrégation diagnostics", []string{"go", "run", "scripts/aggregate-diagnostics.go"}},
	}

	for _, step := range steps {
		if err := runStep(step); err != nil {
			fmt.Fprintf(os.Stderr, "[ERREUR] %s : %v\n", step.Name, err)
			os.Exit(1)
		}
	}
	fmt.Println("Orchestration terminée avec succès.")
}
