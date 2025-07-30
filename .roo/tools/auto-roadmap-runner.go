package main

import (
	"fmt"
	"os/exec"
)

func runStep(name string, args ...string) error {
	fmt.Printf("=== %s ===\n", name)
	cmd := exec.Command("go", args...)
	out, err := cmd.CombinedOutput()
	fmt.Printf("%s\n", out)
	return err
}

func main() {
	steps := []struct {
		name string
		args []string
	}{
		{"Scan", []string{"run", "refs_sync.go", "--scan"}},
		{"Injection", []string{"run", "refs_sync.go", "--inject"}},
		{"Vérification des verrous", []string{"run", "refs_sync.go", "--check-locks"}},
		{"Dry-run", []string{"run", "refs_sync.go", "--dry-run"}},
	}

	for _, step := range steps {
		if err := runStep(step.name, step.args...); err != nil {
			fmt.Printf("Erreur %s: %v\n", step.name, err)
		}
	}
	fmt.Println("Orchestration terminée.")
}
