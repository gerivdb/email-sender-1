package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

func runCommand(command string, args ...string) error {
	cmd := exec.Command(command, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	fmt.Printf("Exécution de : %s %s\n", command, strings.Join(args, " "))
	return cmd.Run()
}

func main() {
	fmt.Println("Démarrage de l'orchestrateur global de la feuille de route...")

	// 1. Exécuter les tests unitaires et d'intégration
	fmt.Println("\n--- Exécution des tests unitaires et d'intégration ---")
	if err := runCommand("go", "test", "-v", "-cover", "./development/managers/gateway-manager/..."); err != nil {
		fmt.Printf("Erreur lors de l'exécution des tests unitaires du Gateway-Manager: %v\n", err)
		// Continuer même en cas d'erreur pour générer le rapport
	}
	if err := runCommand("go", "test", "-v", "-cover", "./tests/integration/..."); err != nil {
		fmt.Printf("Erreur lors de l'exécution des tests d'intégration: %v\n", err)
		// Continuer même en cas d'erreur pour générer le rapport
	}

	// 2. Générer le rapport
	fmt.Println("\n--- Génération du rapport ---")
	if err := runCommand("go", "run", "cmd/generate-gateway-report/main.go"); err != nil {
		fmt.Printf("Erreur lors de la génération du rapport: %v\n", err)
		os.Exit(1)
	}

	// 3. Effectuer la sauvegarde
	fmt.Println("\n--- Exécution de la sauvegarde ---")
	if err := runCommand("go", "run", "cmd/backup-modified-files/main.go"); err != nil {
		fmt.Printf("Erreur lors de l'exécution de la sauvegarde: %v\n", err)
		os.Exit(1)
	}

	// 4. (Simulation) Envoyer des notifications / feedback
	fmt.Println("\n--- Simulation d'envoi de notifications/feedback ---")
	fmt.Println("Notification: Rapport de migration prêt.")
	fmt.Println("Feedback: Demande de revue du code envoyée.")

	fmt.Println("\nOrchestrateur global terminé avec succès.")
}
