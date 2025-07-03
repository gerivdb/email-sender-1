package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

func runCommand(name string, arg ...string) error {
	cmd := exec.Command(name, arg...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	fmt.Printf("Exécution de la commande: %s %s\n", name, strings.Join(arg, " "))
	return cmd.Run()
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: orchestrator [task] [args...]")
		fmt.Println("Tasks: docgen, visualizer, metrics, docmanager")
		os.Exit(1)
	}

	task := os.Args[1]
	taskArgs := os.Args[2:]

	var err error

	switch task {
	case "docgen":
		// Example: orchestrator docgen --scan
		err = runCommand("python", append([]string{"scripts/docgen.py"}, taskArgs...)...)
	case "visualizer":
		// Example: orchestrator visualizer --format mermaid --output graph.mmd
		err = runCommand("integration/cmd/visualizer/visualizer.exe", taskArgs...)
	case "metrics":
		// Example: orchestrator metrics --report
		err = runCommand("python", append([]string{"scripts/metrics.py"}, taskArgs...)...)
	case "docmanager":
		// Example: orchestrator docmanager sync --source-path docs/
		err = runCommand("integration/cmd/docmanager/docmanager.exe", taskArgs...)
	case "all":
		fmt.Println("Exécution de toutes les tâches...")
		if err = runCommand("python", "scripts/docgen.py", "--scan"); err != nil {
			fmt.Println("Erreur lors de la génération de la documentation:", err)
			os.Exit(1)
		}
		if err = runCommand("python", "scripts/validate_docs.py"); err != nil {
			fmt.Println("Erreur lors de la validation de la documentation:", err)
			os.Exit(1)
		}
		if err = runCommand("python", "scripts/metrics.py", "--report"); err != nil {
			fmt.Println("Erreur lors du rapport des métriques:", err)
			os.Exit(1)
		}
		fmt.Println("Toutes les tâches d'orchestration ont été exécutées avec succès.")
	default:
		fmt.Printf("Tâche inconnue: %s\n", task)
		os.Exit(1)
	}

	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lors de l'exécution de la tâche %s: %v\n", task, err)
		os.Exit(1)
	}
}
