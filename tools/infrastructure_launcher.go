package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"
)

// Structure pour stocker le résultat du démarrage des conteneurs
type StartupResult struct {
	ServicesStarted []string
	TotalTime      time.Duration
	Warnings       []string
}

func main() {
	fmt.Println("🚀 Infrastructure Orchestrator pour EMAIL_SENDER_1")
	fmt.Println("📋 Phase 1.1.3: Ajout de l'InfrastructureOrchestrator")
	fmt.Println("=======================================================")

	// Trouver le chemin du répertoire contenant ce fichier exécutable
	exePath, err := os.Executable()
	if err != nil {
		fmt.Printf("❌ Erreur: Impossible de déterminer le chemin de l'exécutable: %v\n", err)
		os.Exit(1)
	}

	// Remonter au répertoire racine du projet (où se trouve docker-compose.yml)
	projectDir := filepath.Dir(exePath)
	fmt.Printf("📂 Répertoire du projet: %s\n", projectDir)

	// Vérifier la présence du fichier docker-compose.yml
	dockerComposeFile := filepath.Join(projectDir, "docker-compose.yml")
	if _, err := os.Stat(dockerComposeFile); os.IsNotExist(err) {
		fmt.Printf("❌ Erreur: Fichier docker-compose.yml introuvable à %s\n", dockerComposeFile)
		fmt.Println("Recherche du fichier docker-compose.yml dans le répertoire courant...")
		
		// Essayer le répertoire courant
		currentDir, _ := os.Getwd()
		dockerComposeFile = filepath.Join(currentDir, "docker-compose.yml")
		if _, err := os.Stat(dockerComposeFile); os.IsNotExist(err) {
			fmt.Printf("❌ Erreur: Fichier docker-compose.yml introuvable dans %s\n", currentDir)
			os.Exit(1)
		} else {
			projectDir = currentDir
			fmt.Printf("📂 Utilisation du répertoire courant: %s\n", projectDir)
		}
	}

	// Afficher l'ordre de démarrage
	fmt.Println("📊 Séquence de démarrage des services:")
	fmt.Println("   QDrant → Redis → PostgreSQL → Prometheus → Grafana → Applications")
	fmt.Println()

	// Démarrer les conteneurs avec Docker Compose
	fmt.Println("🔄 Démarrage des conteneurs...")
	startTime := time.Now()
	
	cmd := exec.Command("docker-compose", "-f", dockerComposeFile, "up", "-d")
	cmd.Dir = projectDir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	
	err = cmd.Run()
	if err != nil {
		fmt.Printf("❌ Erreur lors du démarrage des conteneurs: %v\n", err)
		os.Exit(1)
	}

	// Calculer le temps écoulé
	elapsedTime := time.Since(startTime)

	// Attendre que les conteneurs soient prêts
	fmt.Println("⏱️ Attente de démarrage des conteneurs (5 secondes)...")
	time.Sleep(5 * time.Second)

	// Afficher l'état des conteneurs
	fmt.Println("📋 État des conteneurs:")
	cmdPs := exec.Command("docker-compose", "-f", dockerComposeFile, "ps")
	cmdPs.Dir = projectDir
	cmdPs.Stdout = os.Stdout
	cmdPs.Stderr = os.Stderr
	cmdPs.Run()

	// Afficher un résumé
	fmt.Printf("\n✅ Infrastructure démarrée avec succès!\n")
	fmt.Printf("⏱️ Temps total: %v\n", elapsedTime)
	fmt.Println("📝 Phase 1.1.3 du Plan-dev-v54 complétée.")
	
	// Afficher des instructions pour vérifier les logs
	fmt.Println("\n📋 Pour vérifier les logs, exécutez:")
	fmt.Printf("   cd %s && docker-compose logs --follow\n", projectDir)
}
